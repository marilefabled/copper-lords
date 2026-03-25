-- Bloodweight — Nemesis System
-- Tracks the player's primary rival house across generations.
-- Adds personal feud escalation, rival expectations, secret actions,
-- and cross-generational grudge memory.
-- Inspired by dredwork_bonds: expectations, secrets, collusion patterns.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Nemesis = {}
Nemesis.__index = Nemesis

-- ═══════════════════════════════════════════════════════
-- FEUD STAGES (escalate over time, can de-escalate)
-- ═══════════════════════════════════════════════════════

local FEUD_STAGES = {
    { id = "cold_war",        threshold = 0,   label = "Cold War",         desc = "Tension simmers beneath courtesies." },
    { id = "open_hostility",  threshold = 25,  label = "Open Hostility",   desc = "The pretense of peace has been abandoned." },
    { id = "blood_feud",      threshold = 50,  label = "Blood Feud",       desc = "This is personal. Names are cursed across generations." },
    { id = "total_war",       threshold = 75,  label = "Total War",        desc = "One house will fall. There is no other ending." },
    { id = "exhaustion",      threshold = -1,  label = "Exhaustion",       desc = "Both sides are spent. The hatred remains, but the will does not." },
}

-- ═══════════════════════════════════════════════════════
-- RIVAL EXPECTATIONS (what the nemesis demands/wants)
-- Adapted from dredwork_bonds expectations pattern
-- ═══════════════════════════════════════════════════════

local RIVAL_EXPECTATIONS = {
    warriors = { type = "submission",   label = "They expect you to kneel or be broken." },
    scholars = { type = "recognition",  label = "They expect you to acknowledge their superiority." },
    diplomats = { type = "concession",  label = "They expect you to cede territory or influence." },
    artisans = { type = "tribute",      label = "They expect you to pay what you owe — in gold or blood." },
}

-- ═══════════════════════════════════════════════════════
-- SECRET ACTIONS (autonomous rival behavior by personality)
-- Adapted from dredwork_bonds secrets pattern
-- ═══════════════════════════════════════════════════════

local SECRET_ACTIONS = {
    bold_hostile    = { id = "direct_assault",  text = "%s marshals forces at the border.",           hostile = true },
    bold_neutral    = { id = "show_of_force",   text = "%s parades their army within sight of your walls.", hostile = false },
    cruel_hostile   = { id = "assassination",   text = "%s sent a poisoner into your court.",         hostile = true },
    cruel_neutral   = { id = "intimidation",    text = "%s left a warning nailed to your gate.",      hostile = true },
    proud_hostile   = { id = "public_challenge", text = "%s declared your bloodline unfit to rule.",  hostile = true },
    proud_neutral   = { id = "grand_display",   text = "%s hosted a feast and invited every house but yours.", hostile = true },
    cunning_hostile = { id = "sabotage",        text = "%s's agents were found in the grain stores.", hostile = true },
    cunning_neutral = { id = "intelligence",    text = "%s has been asking questions about your heir.", hostile = false },
    default         = { id = "watching",        text = "%s is watching. Waiting.",                    hostile = false },
}

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

-- ═══════════════════════════════════════════════════════
-- CONSTRUCTOR
-- ═══════════════════════════════════════════════════════

--- Create a new Nemesis tracker.
---@param faction_id string|nil ID of the marked rival faction
---@return table Nemesis instance
function Nemesis.new(faction_id)
    local self = setmetatable({}, Nemesis)
    self.faction_id = faction_id        -- Which faction is the nemesis
    self.feud_score = 0                 -- 0–100, drives stage progression
    self.feud_stage = "cold_war"        -- Current stage
    self.history = {}                   -- Array of { gen, text } — capped at 20
    self.grudge_memory = {}             -- Array of { gen, act, heir_name } — inherited wrongs
    self.expectation = nil              -- { type, label, violated, grievance }
    self.secret_cooldown = 0            -- Generation of last secret action
    self.peace_attempts = 0             -- How many times peace has been offered/rejected
    self.gens_active = 0                -- How many generations the feud has been active
    return self
end

-- ═══════════════════════════════════════════════════════
-- CORE API
-- ═══════════════════════════════════════════════════════

--- Set or change the nemesis faction.
---@param faction_id string
---@param faction_type string|nil "warriors", "scholars", "diplomats", "artisans"
function Nemesis:set_faction(faction_id, faction_type)
    self.faction_id = faction_id
    self.feud_score = math.max(self.feud_score, 15) -- Minimum hostility
    -- Set expectation based on faction type
    local exp_def = RIVAL_EXPECTATIONS[faction_type] or RIVAL_EXPECTATIONS.warriors
    self.expectation = {
        type = exp_def.type,
        label = exp_def.label,
        violated = false,
        grievance = 0,
    }
end

--- Tick the nemesis system each generation.
---@param faction table|nil The nemesis Faction instance
---@param rival_heir table|nil The rival heir for this faction
---@param generation number Current generation
---@param context table { resources, holdings, factions, lineage_power }
---@return table { events = {}, narration = string|nil, secret = table|nil }
function Nemesis:tick(faction, rival_heir, generation, context)
    if not self.faction_id or not faction then
        return { events = {}, narration = nil, secret = nil }
    end

    self.gens_active = self.gens_active + 1
    local results = { events = {}, narration = nil, secret = nil }

    -- Update feud score based on faction disposition
    local disp = faction.disposition or 0
    local hostility = math.abs(math.min(0, disp)) -- 0 for friendly, 0–100 for hostile
    local drift = 0
    if hostility >= 50 then
        drift = math.floor((hostility - 40) / 15) -- +1 to +4 per gen when hostile
    elseif hostility < 20 and self.feud_score > 0 then
        drift = -2 -- Slow de-escalation when relations warm
    end
    self.feud_score = clamp(self.feud_score + drift, 0, 100)

    -- Update feud stage
    local old_stage = self.feud_stage
    self:_update_stage()

    -- Stage transition narration
    if self.feud_stage ~= old_stage then
        local stage_def = self:_get_stage_def()
        if stage_def then
            local rival_name = rival_heir and rival_heir.name or faction.name
            results.narration = stage_def.desc
            self:_add_history(generation, "Feud escalated to " .. stage_def.label .. ".")
            results.events[#results.events + 1] = {
                type = "feud_escalation",
                text = "The feud with " .. faction.name .. " deepens: " .. stage_def.label .. ".",
                stage = self.feud_stage,
            }
        end
    end

    -- Expectation violation check (adapted from bonds)
    if self.expectation then
        local violated = self:_check_expectation(faction, context)
        if violated then
            self.expectation.violated = true
            self.expectation.grievance = clamp((self.expectation.grievance or 0) + 5, 0, 100)
            -- Grievance feeds feud score
            if self.expectation.grievance >= 30 then
                self.feud_score = clamp(self.feud_score + 2, 0, 100)
            end
        end
    end

    -- Secret action (autonomous rival behavior)
    if generation - self.secret_cooldown >= 3 and self.feud_score >= 20 then
        local secret = self:_generate_secret(faction, rival_heir, generation)
        if secret then
            results.secret = secret
            self.secret_cooldown = generation
            self:_add_history(generation, secret.text)
        end
    end

    -- Grudge memory inheritance: when rival heir changes, log it
    if rival_heir and rival_heir._just_succeeded then
        local inherits = self.feud_score >= 30
        if inherits then
            self:_add_history(generation, rival_heir.name .. " inherits the feud.")
        else
            -- Small chance new heir rejects the feud
            if rng.chance(0.25) then
                self.feud_score = clamp(self.feud_score - 15, 0, 100)
                self:_add_history(generation, rival_heir.name .. " distances themselves from the old grudge.")
                results.events[#results.events + 1] = {
                    type = "grudge_rejection",
                    text = rival_heir.name .. " of " .. faction.name .. " has renounced the blood feud. For now.",
                }
            end
        end
    end

    return results
end

--- Record a significant act in the feud.
---@param generation number
---@param act_type string "attack", "betrayal", "peace_rejected", "peace_accepted", "duel", etc.
---@param description string
---@param score_delta number Change to feud score
function Nemesis:record_act(generation, act_type, description, score_delta)
    self.feud_score = clamp(self.feud_score + (score_delta or 0), 0, 100)
    self:_add_history(generation, description)
    self.grudge_memory[#self.grudge_memory + 1] = {
        gen = generation,
        act = act_type,
        description = description,
    }
    -- Cap grudge memory at 10
    while #self.grudge_memory > 10 do table.remove(self.grudge_memory, 1) end
    self:_update_stage()
end

--- Get the current feud stage definition.
---@return table { id, threshold, label, desc }
function Nemesis:get_stage()
    return self:_get_stage_def()
end

--- Get a narration line about what the rival is doing this generation.
---@param faction table Faction instance
---@param rival_heir table|nil
---@return string|nil
function Nemesis:get_initiative_narration(faction, rival_heir)
    if not faction or self.feud_score < 10 then return nil end

    local name = rival_heir and rival_heir.alive and rival_heir.name or faction.name
    local stage = self.feud_stage

    local lines_by_stage = {
        cold_war = {
            name .. " strengthens their position in silence.",
            name .. " recruits quietly at the borders.",
            "Scouts report movement near " .. faction.name .. " territory.",
        },
        open_hostility = {
            name .. " fortifies against your expansion.",
            name .. " turns away your traders at the gate.",
            faction.name .. " patrols the disputed lands with increasing boldness.",
        },
        blood_feud = {
            name .. " swore a public oath against your bloodline.",
            "Children in " .. faction.name .. " lands are taught to hate your name.",
            name .. " burns effigies bearing your family crest.",
        },
        total_war = {
            name .. " has committed everything. There is no retreat for either side.",
            "The full might of " .. faction.name .. " marches.",
            name .. " offers gold to anyone who brings them your heir's head.",
        },
        exhaustion = {
            name .. " is quiet. The silence is heavier than the war.",
            "Both houses bleed. Neither can afford to stop.",
            faction.name .. " buries their dead without ceremony.",
        },
    }

    local pool = lines_by_stage[stage] or lines_by_stage.cold_war
    return pool[rng.range(1, #pool)]
end

-- ═══════════════════════════════════════════════════════
-- SERIALIZATION
-- ═══════════════════════════════════════════════════════

function Nemesis:to_table()
    return {
        faction_id = self.faction_id,
        feud_score = self.feud_score,
        feud_stage = self.feud_stage,
        history = self.history,
        grudge_memory = self.grudge_memory,
        expectation = self.expectation,
        secret_cooldown = self.secret_cooldown,
        peace_attempts = self.peace_attempts,
        gens_active = self.gens_active,
    }
end

function Nemesis.from_table(data)
    if not data then return Nemesis.new(nil) end
    local self = Nemesis.new(data.faction_id)
    self.feud_score = data.feud_score or 0
    self.feud_stage = data.feud_stage or "cold_war"
    self.history = data.history or {}
    self.grudge_memory = data.grudge_memory or {}
    self.expectation = data.expectation
    self.secret_cooldown = data.secret_cooldown or 0
    self.peace_attempts = data.peace_attempts or 0
    self.gens_active = data.gens_active or 0
    return self
end

-- ═══════════════════════════════════════════════════════
-- INTERNALS
-- ═══════════════════════════════════════════════════════

function Nemesis:_update_stage()
    if self.feud_score >= 75 then
        self.feud_stage = "total_war"
    elseif self.feud_score >= 50 then
        self.feud_stage = "blood_feud"
    elseif self.feud_score >= 25 then
        self.feud_stage = "open_hostility"
    elseif self.feud_score > 0 and self.gens_active >= 15 and self.feud_score < 20 then
        self.feud_stage = "exhaustion"
    else
        self.feud_stage = "cold_war"
    end
end

function Nemesis:_get_stage_def()
    for _, s in ipairs(FEUD_STAGES) do
        if s.id == self.feud_stage then return s end
    end
    return FEUD_STAGES[1]
end

function Nemesis:_add_history(generation, text)
    self.history[#self.history + 1] = { gen = generation, text = text }
    while #self.history > 20 do table.remove(self.history, 1) end
end

function Nemesis:_check_expectation(faction, context)
    if not self.expectation then return false end
    local etype = self.expectation.type

    if etype == "submission" then
        -- Warriors expect you to be militarily weak
        local lp = context and context.lineage_power
        if lp and (lp.value or 45) >= 60 then return true end -- You're too strong; they feel challenged
    elseif etype == "recognition" then
        -- Scholars expect lore superiority
        local res = context and context.resources
        if res then
            local all = res:get_all()
            if (all.lore or 0) >= 20 then return true end -- You have lore; they feel rivaled
        end
    elseif etype == "concession" then
        -- Diplomats expect territory/influence
        local holdings = context and context.holdings
        if holdings and #holdings.domains >= 3 then return true end -- You hold too much
    elseif etype == "tribute" then
        -- Artisans expect economic submission
        local res = context and context.resources
        if res then
            local all = res:get_all()
            if (all.gold or 0) >= 15 then return true end -- You're too wealthy
        end
    end

    return false
end

function Nemesis:_generate_secret(faction, rival_heir, generation)
    local p = faction.personality or {}
    local is_hostile = self.feud_score >= 40
    local name = rival_heir and rival_heir.alive and rival_heir.name or faction.name

    -- Pick action based on personality (adapted from bonds temperament matrix)
    local action_key = "default"
    local boldness = p.PER_BLD or 50
    local cruelty = p.PER_CRM or 50
    local pride = p.PER_PRI or 50
    local cunning = (100 - (p.PER_LOY or 50)) -- Low loyalty ≈ high cunning

    -- Find dominant personality trait
    local best_trait, best_val = "default", 0
    local traits = { bold = boldness, cruel = cruelty, proud = pride, cunning = cunning }
    for k, v in pairs(traits) do
        if v > best_val and v >= 55 then best_trait = k; best_val = v end
    end

    local suffix = is_hostile and "_hostile" or "_neutral"
    action_key = best_trait .. suffix
    local action = SECRET_ACTIONS[action_key] or SECRET_ACTIONS.default

    return {
        id = action.id,
        text = string.format(action.text, name),
        hostile = action.hostile,
        generation = generation,
    }
end

return Nemesis
