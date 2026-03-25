-- dredwork Claim — Module Entry
-- The player's secret birthright. A claim to a house that could save or kill them.
-- Hidden by default. Can be revealed to individuals — each becomes ally or threat.
-- The central tension of Shadow Lineage.
--
-- "Do they know who I am?"

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Claim = {}
Claim.__index = Claim

--- Claim types — what kind of connection to the ruling house.
local CLAIM_TYPES = {
    bastard = {
        id = "bastard",
        label = "Bastard Child",
        description = "Born outside the sanctioned bloodline. Legitimate enough to threaten. Illegitimate enough to deny.",
        strength = 30,  -- how strong the claim is (affects NPC reactions)
        danger = 60,    -- how dangerous it is to reveal
    },
    exiled_sibling = {
        id = "exiled_sibling",
        label = "Exiled Sibling",
        description = "Cast out but not forgotten. The blood remembers even if the court does not.",
        strength = 60,
        danger = 80,
    },
    disinherited = {
        id = "disinherited",
        label = "Disinherited Heir",
        description = "Once named successor. Stripped of title but not of blood.",
        strength = 75,
        danger = 90,
    },
    lost_child = {
        id = "lost_child",
        label = "Lost Child",
        description = "Taken as an infant. Raised far from court. The truth was kept from everyone — including you.",
        strength = 50,
        danger = 50,
    },
    pretender = {
        id = "pretender",
        label = "Pretender",
        description = "Your claim may or may not be real. You believe it. That might be enough.",
        strength = 15,
        danger = 40,
    },
}

function Claim.init(engine)
    local self = setmetatable({}, Claim)
    self.engine = engine

    engine.game_state.claim = {
        type = nil,              -- claim type id
        target_house = nil,      -- which house you have a claim to
        known_by = {},           -- entity_ids who know your secret
        revealed_to_ruler = false,
        status = "hidden",       -- hidden, whispered, known, challenged, recognized
        -- hidden: nobody knows
        -- whispered: a few know, rumors may spread
        -- known: it's public knowledge
        -- challenged: you've made your move
        -- recognized: the claim has been accepted (endgame)
        suspicion = 0,           -- 0-100 how much the ruling house suspects
        evidence = {},           -- { { type, bonus, text } } accumulated proof
        challenge_month = 0,     -- months since challenge was made
    }

    -- Monthly: suspicion drift, exposure risk, and challenge deliberation
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state, clock)
        self:tick_challenge(self.engine.game_state, clock)
    end)

    -- Query handler
    engine:on("GET_CLAIM_DATA", function(req)
        local c = self.engine.game_state.claim
        req.claim_type = c.type
        req.target_house = c.target_house
        req.status = c.status
        req.suspicion = c.suspicion
        req.known_by_count = #c.known_by
    end)

    return self
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

--- Initialize the player's claim.
---@param claim_type_id string
---@param target_house_name string which house you have a claim to
function Claim:setup(claim_type_id, target_house_name)
    local gs = self.engine.game_state
    local claim_def = CLAIM_TYPES[claim_type_id]
    if not claim_def then return end

    gs.claim.type = claim_type_id
    gs.claim.target_house = target_house_name
    gs.claim.known_by = {}
    gs.claim.revealed_to_ruler = false
    gs.claim.status = "hidden"
    gs.claim.suspicion = 0

    self.engine.log:info("Claim: %s established against %s", claim_def.label, target_house_name)
end

--------------------------------------------------------------------------------
-- Reveal — The Core Mechanic
--------------------------------------------------------------------------------

--- Reveal your claim to a specific person. This is the game's central risk.
---@param target_entity_id string who you're telling
---@return table { accepted, reaction, text }
function Claim:reveal_to(target_entity_id)
    local gs = self.engine.game_state
    local claim_def = CLAIM_TYPES[gs.claim.type]
    if not claim_def then return { accepted = false, text = "You have nothing to reveal." } end

    local entities = self.engine:get_module("entities")
    if not entities then return { accepted = false } end
    local target = entities:get(target_entity_id)
    if not target then return { accepted = false } end

    -- Already knows?
    for _, known_id in ipairs(gs.claim.known_by) do
        if known_id == target_entity_id then
            return { accepted = false, reaction = "already_knows", text = target.name .. " already knows. Their expression doesn't change." }
        end
    end

    -- Record that they know
    table.insert(gs.claim.known_by, target_entity_id)

    -- How do they react? Depends on their personality, relationship to you, relationship to the ruling house
    local target_p = target.components.personality or {}
    local loy = target_p.PER_LOY or 50; if type(loy) == "table" then loy = loy.value or 50 end
    local crm = target_p.PER_CRM or 50; if type(crm) == "table" then crm = crm.value or 50 end
    local obs = target_p.PER_OBS or 50; if type(obs) == "table" then obs = obs.value or 50 end
    local bld = target_p.PER_BLD or 50; if type(bld) == "table" then bld = bld.value or 50 end

    -- Relationship to you
    local rel_strength = 0
    local rels = entities:get_relationships(target_entity_id)
    local focal_id = gs.entities and gs.entities.focal_entity_id
    for _, rel in ipairs(rels) do
        if rel.a == focal_id or rel.b == focal_id then
            rel_strength = rel_strength + rel.strength
        end
    end

    -- Calculate reaction score
    local score = 0
    score = score + (rel_strength - 30) * 0.5   -- strong bond = supportive
    score = score + (loy - 50) * 0.3             -- loyal people support claims
    score = score - (crm - 50) * 0.3             -- cruel people see opportunity to exploit
    score = score + claim_def.strength * 0.2      -- stronger claims are more convincing
    score = score + RNG.range(-15, 15)            -- uncertainty

    local reaction, text

    if score > 40 then
        -- SUPPORTER: they believe you and want to help
        reaction = "supporter"
        entities:add_relationship(target_entity_id, focal_id, "claim_supporter", Math.clamp(score, 30, 90))

        -- Memory: debt of trust
        if target.components.memory then
            local MemLib = require("dredwork_agency.memory")
            MemLib.add_debt(target.components.memory, focal_id, "trusted me with their secret", 30)
        end

        local supporter_texts = {
            target.name .. " goes still. Then: \"I knew. I think I always knew.\" They kneel.",
            "A long silence. " .. target.name .. " meets your eyes. \"What do you need from me?\"",
            target.name .. " grips your hand. \"This changes everything. I'm with you.\"",
            "\"That explains...\" " .. target.name .. " trails off. \"Tell me what the plan is.\"",
        }
        text = RNG.pick(supporter_texts)

    elseif score > 10 then
        -- CAUTIOUS: they believe you but aren't sure what to do
        reaction = "cautious"

        local cautious_texts = {
            target.name .. " stares. \"That's... a dangerous thing to say out loud.\"",
            "\"I need time to think about this.\" " .. target.name .. " won't look at you.",
            target.name .. " whispers: \"Don't tell anyone else. Not yet. Promise me.\"",
            "\"If this is true...\" " .. target.name .. " shakes their head. \"If this is true, everything is different.\"",
        }
        text = RNG.pick(cautious_texts)

    elseif score > -20 then
        -- SKEPTIC: they don't believe you or don't care
        reaction = "skeptic"

        local skeptic_texts = {
            target.name .. " laughs. Short. Sharp. \"Everyone has a story about who they really are.\"",
            "\"Claims are cheap.\" " .. target.name .. " turns away. \"Proof isn't.\"",
            target.name .. " looks at you with something like pity. \"Let it go. That life isn't yours.\"",
        }
        text = RNG.pick(skeptic_texts)

    else
        -- HOSTILE: they see you as a threat or an opportunity to betray
        reaction = "hostile"

        -- They will report you — suspicion increases significantly
        gs.claim.suspicion = Math.clamp(gs.claim.suspicion + 25, 0, 100)

        -- Grudge: they see you as dangerous
        if target.components.memory then
            local MemLib = require("dredwork_agency.memory")
            MemLib.add_grudge(target.components.memory, focal_id, "claims to be heir", 30)
        end

        -- Might inject a rumor
        if RNG.chance(0.6) then
            local rumor = self.engine:get_module("rumor")
            if rumor then
                rumor:inject(gs, {
                    origin_type = "claim",
                    subject = "a stranger",
                    text = "Someone is making claims about royal blood. Probably nothing. Probably.",
                    heat = 40 + claim_def.danger * 0.3,
                    tags = { scandal = true, danger = true },
                })
            end
        end

        local hostile_texts = {
            target.name .. "'s expression hardens. \"You shouldn't have told me that.\"",
            "\"Do you know what they DO to pretenders?\" " .. target.name .. "'s voice is ice.",
            target.name .. " smiles. The wrong kind of smile. \"How much is that information worth, I wonder?\"",
            "\"I think you should leave.\" " .. target.name .. "'s hand moves to their belt. \"Now.\"",
        }
        text = RNG.pick(hostile_texts)
    end

    -- Update status based on how many know
    local known_count = #gs.claim.known_by
    if known_count >= 8 then
        gs.claim.status = "known"
    elseif known_count >= 3 then
        gs.claim.status = "whispered"
    end

    -- Emit
    self.engine:emit("CLAIM_REVEALED", {
        target_id = target_entity_id,
        target_name = target.name,
        reaction = reaction,
        text = text,
        known_count = known_count,
        status = gs.claim.status,
    })
    self.engine:push_ui_event("CLAIM_REVEALED", { text = text })

    return { accepted = reaction == "supporter", reaction = reaction, text = text }
end

--- Challenge for the throne — the endgame move.
function Claim:challenge()
    local gs = self.engine.game_state
    if gs.claim.status == "hidden" then
        return { success = false, text = "Nobody knows who you are. You can't challenge for what nobody knows you deserve." }
    end

    -- Count supporters
    local entities = self.engine:get_module("entities")
    local supporters = 0
    if entities then
        local focal_id = gs.entities and gs.entities.focal_entity_id
        for _, known_id in ipairs(gs.claim.known_by) do
            local rels = entities:get_relationships(known_id, "claim_supporter")
            for _, rel in ipairs(rels) do
                if rel.a == focal_id or rel.b == focal_id then
                    supporters = supporters + 1
                end
            end
        end
    end

    local claim_def = CLAIM_TYPES[gs.claim.type] or { strength = 30 }

    gs.claim.status = "challenged"

    self.engine:emit("CLAIM_CHALLENGED", {
        claim_type = gs.claim.type,
        target_house = gs.claim.target_house,
        supporters = supporters,
        claim_strength = claim_def.strength,
        text = "You step forward. You speak the words. The court falls silent. There is no taking this back.",
    })
    self.engine:push_ui_event("CLAIM_CHALLENGED", {
        text = "The claim has been made. The world holds its breath.",
    })

    return { success = true, supporters = supporters, text = "You have declared your claim. " .. supporters .. " stand with you. The rest... we'll see." }
end

--------------------------------------------------------------------------------
-- Monthly Tick: Suspicion, Exposure, Consequences
--------------------------------------------------------------------------------

function Claim:tick_monthly(gs, clock)
    if not gs.claim.type then return end
    if gs.claim.status == "recognized" then return end

    local day = clock and clock.total_days or 0
    local claim_def = CLAIM_TYPES[gs.claim.type] or { strength = 30, danger = 50 }

    -- Suspicion rises if rumors about claims are circulating
    if gs.rumor_network and gs.rumor_network.rumors then
        for _, r in pairs(gs.rumor_network.rumors) do
            if not r.dead and r.tags and r.tags.danger and r.origin_type == "claim" then
                gs.claim.suspicion = Math.clamp(gs.claim.suspicion + 2, 0, 100)
            end
        end
    end

    -- NATURAL SUSPICION CREEP: your face, your mannerisms, time itself
    -- The longer you exist, the more likely someone notices you don't belong
    local months_alive = math.floor(day / 30)
    if months_alive > 3 then
        -- Base creep: 1-3 per month depending on claim strength (stronger claim = more recognizable features)
        local creep = math.floor(claim_def.strength / 30)  -- 1 for bastard/pretender, 2 for exiled/lost, 2-3 for disinherited
        if gs.claim.status == "whispered" then creep = creep + 1 end
        if gs.claim.status == "known" then creep = creep + 2 end
        gs.claim.suspicion = Math.clamp(gs.claim.suspicion + creep, 0, 100)

        -- Occasional narrative about the creeping danger
        if RNG.chance(0.15) and gs.claim.status == "hidden" and gs.claim.suspicion > 10 then
            local creep_texts = {
                "An old woman stares at you in the market. Too long. She sees something in your face.",
                "A guard glances your way. Looks down at a notice. Looks back. Then moves on. This time.",
                "Someone at work mentions a family resemblance. They're joking. You don't laugh.",
                "A child points at you and whispers to their mother. The mother pulls them away quickly.",
            }
            self.engine:emit("NARRATIVE_BEAT", {
                channel = "whispers", priority = 55, display_hint = "signal",
                text = RNG.pick(creep_texts),
                tags = { "claim", "creep" }, timestamp = day,
            })
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers", text = RNG.pick(creep_texts),
                priority = 55, display_hint = "signal",
            })
        end
    end

    -- SUPPORTER FAITH DECAY: if you have supporters but haven't challenged, they lose patience
    if #gs.claim.known_by >= 5 and gs.claim.status ~= "challenged" then
        -- Every month past 5 supporters, there's a chance someone gets impatient
        if RNG.chance(0.12) then
            local impatient_texts = {
                "One of your supporters sends word: 'How much longer? People are asking why we wait.'",
                "An ally corners you. 'I put my neck out for you. When do you act?'",
                "Whispers reach you — your supporters are losing faith. Promises need deadlines.",
            }
            self.engine:emit("NARRATIVE_BEAT", {
                channel = "whispers", priority = 58, display_hint = "signal",
                text = RNG.pick(impatient_texts),
                tags = { "claim", "pressure" }, timestamp = day,
            })
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers", text = RNG.pick(impatient_texts),
                priority = 58, display_hint = "signal",
            })
        end
    end

    -- Reduced natural decay — suspicion fades slowly, but the creep outpaces it
    if gs.claim.status == "hidden" then
        gs.claim.suspicion = Math.clamp(gs.claim.suspicion - 1, 0, 100)
    end
    -- No decay when whispered/known — too many people talking

    -- If suspicion is high, the ruling house acts
    if gs.claim.suspicion > 70 and RNG.chance(0.15) then
        -- They send investigators or assassins
        local claim_def = CLAIM_TYPES[gs.claim.type] or { danger = 50 }

        if claim_def.danger > 70 and RNG.chance(0.3) then
            -- Assassination attempt!
            self.engine:emit("CLAIM_ASSASSINATION_ATTEMPT", {
                text = "A stranger watches you too carefully. A blade glints in the lamplight. They know. They've been sent.",
            })
            self.engine:push_ui_event("CLAIM_ASSASSINATION_ATTEMPT", {
                text = "Someone has been sent to end you.",
            })

            -- Player must deal with this through interactions/decisions
            local focal = self.engine:get_module("entities") and self.engine:get_module("entities"):get_focus()
            if focal and focal.components.needs then
                focal.components.needs.safety = Math.clamp((focal.components.needs.safety or 50) - 20, 0, 100)
            end
        else
            -- Investigation — suspicion signal
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = "Questions are being asked. About you. About where you came from. About your parents.",
                priority = 65,
                display_hint = "signal",
            })
        end
    end

    -- Supporters might waver if things go badly
    if gs.claim.suspicion > 50 then
        local entities = self.engine:get_module("entities")
        if entities then
            for _, known_id in ipairs(gs.claim.known_by) do
                local known = entities:get(known_id)
                if known and known.alive and RNG.chance(0.05) then
                    -- Wavering supporter might leak
                    local rumor = self.engine:get_module("rumor")
                    if rumor then
                        rumor:inject(gs, {
                            origin_type = "claim",
                            subject = "the claimant",
                            text = "Someone who knows too much has been talking too freely.",
                            heat = 35, tags = { scandal = true },
                        })
                    end
                    gs.claim.suspicion = Math.clamp(gs.claim.suspicion + 5, 0, 100)
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Evidence System
--------------------------------------------------------------------------------

--- Add evidence supporting your claim.
---@param spec table { type, bonus, text }
function Claim:add_evidence(spec)
    local gs = self.engine.game_state
    table.insert(gs.claim.evidence, {
        type = spec.type or "testimony",
        bonus = spec.bonus or 5,
        text = spec.text or "A piece of the puzzle.",
    })
    self.engine:emit("CLAIM_EVIDENCE_FOUND", spec)
end

--- Get total evidence bonus.
function Claim:get_evidence_score()
    local total = 0
    for _, e in ipairs(self.engine.game_state.claim.evidence) do
        total = total + (e.bonus or 0)
    end
    return total
end

--------------------------------------------------------------------------------
-- Challenge Deliberation & Resolution (3-month arc)
--------------------------------------------------------------------------------

function Claim:tick_challenge(gs, clock)
    if gs.claim.status ~= "challenged" then return end

    gs.claim.challenge_month = (gs.claim.challenge_month or 0) + 1
    local month = gs.claim.challenge_month

    -- Count supporters vs opposition
    local entities = self.engine:get_module("entities")
    local supporters, opposition = 0, 0
    if entities then
        local focal_id = gs.entities and gs.entities.focal_entity_id
        for _, known_id in ipairs(gs.claim.known_by) do
            local rels = entities:get_relationships(known_id, "claim_supporter")
            local is_supporter = false
            for _, rel in ipairs(rels) do
                if rel.a == focal_id or rel.b == focal_id then
                    is_supporter = true; break
                end
            end
            if is_supporter then
                supporters = supporters + 1
            else
                opposition = opposition + 1
            end
        end
    end

    -- Phases 1-2: Deliberation (months 1 and 2)
    if month <= 2 then
        self.engine:emit("CLAIM_DELIBERATION", {
            phase = month,
            supporters = supporters,
            opposition = opposition,
        })

        local delib_texts = {
            [1] = {
                "The council convenes. Whispers fill the chamber. Your name is on every tongue — some with hope, others with steel.",
                "Month one of deliberation. Allies make their case. Enemies sharpen theirs.",
            },
            [2] = {
                "The second month. Alliances solidify. Someone has been gathering testimony against you.",
                "Deliberation drags on. The tension is a living thing. People avoid your eyes in the corridors.",
            },
        }
        local text = RNG.pick(delib_texts[month])
        self.engine:emit("NARRATIVE_BEAT", {
            channel = "whispers", priority = 72, display_hint = "signal",
            text = text, tags = { "claim", "deliberation" },
            timestamp = clock.total_days,
        })
        self.engine:push_ui_event("NARRATIVE_BEAT", {
            channel = "whispers", text = text, priority = 72, display_hint = "signal",
        })
        return
    end

    -- Phase 3: Resolution (month 3)
    if month == 3 then
        local claim_def = CLAIM_TYPES[gs.claim.type] or { strength = 30 }
        local total_known = #gs.claim.known_by
        local supporter_ratio = total_known > 0 and (supporters / total_known * 100) or 0
        local evidence_score = self:get_evidence_score()

        local score = claim_def.strength * 0.3
                    + supporter_ratio * 0.4
                    + Math.clamp(100 - gs.claim.suspicion, 0, 100) * 0.15
                    + evidence_score * 0.5
                    + RNG.range(-15, 15)

        local outcome, text
        if score > 55 then
            outcome = "recognized"
            gs.claim.status = "recognized"
            text = "The chamber falls silent. Then: a single voice. Your name. Your real name. Spoken aloud for the first time. Others follow. The vote carries. You are recognized."
        elseif score > 25 then
            outcome = "exiled"
            text = "The vote fails. Not enough. They don't execute you — you have too many friends for that. But you cannot stay. The gates close behind you. Exile."
        else
            outcome = "destroyed"
            text = "The council turns. Guards step forward. The faces of those you trusted look away. It's over. They knew. They always knew. And now they've decided what to do about it."
        end

        self.engine:emit("CLAIM_RESOLVED", {
            outcome = outcome,
            score = score,
            supporters = supporters,
            opposition = opposition,
            text = text,
        })
        self.engine:push_ui_event("CLAIM_RESOLVED", {
            outcome = outcome, text = text,
        })

        -- Trigger fate or victory based on outcome
        if outcome == "recognized" then
            -- Victory: purpose and status surge
            local focal = entities and entities:get_focus()
            if focal and focal.components.needs then
                focal.components.needs.purpose = 100
                focal.components.needs.status = 100
            end
            self.engine:emit("NARRATIVE_BEAT", {
                channel = "whispers", priority = 90, display_hint = "pattern",
                text = "Your name is spoken aloud. For the first time. The real one.",
                tags = { "claim", "victory" }, timestamp = clock.total_days,
            })
            self.engine:push_ui_event("NARRATIVE_BEAT", {
                channel = "whispers",
                text = "Your name is spoken aloud. For the first time. The real one.",
                priority = 90, display_hint = "pattern",
            })
        elseif outcome == "exiled" then
            self.engine:emit("TRIGGER_FATE", {
                fate_id = "exile",
                text = text,
            })
        elseif outcome == "destroyed" then
            self.engine:emit("TRIGGER_FATE", {
                fate_id = "death_assassination",
                text = text,
            })
        end
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function Claim:get_status() return self.engine.game_state.claim.status end
function Claim:get_suspicion() return self.engine.game_state.claim.suspicion end
function Claim:get_known_count() return #self.engine.game_state.claim.known_by end
function Claim:get_claim_type()
    local type_id = self.engine.game_state.claim.type
    return type_id and CLAIM_TYPES[type_id] or nil
end
function Claim:get_types() return CLAIM_TYPES end

function Claim:serialize() return self.engine.game_state.claim end
function Claim:deserialize(data) self.engine.game_state.claim = data end

return Claim
