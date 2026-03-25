-- dredwork Agency — Schemes
-- Player-initiated multi-step plans that change the world.
-- Not reactions. Not responses. DESIGNS.
--
-- A scheme is a campaign: 3-5 steps spread across days, locations, and people.
-- Each step requires being somewhere, doing something, or spending something.
-- Completion reshapes the world — visibly.
--
-- "You don't wait for the world to change. You change it.
--  Then you watch it pretend it was always that way."

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Schemes = {}

--------------------------------------------------------------------------------
-- SCHEME DEFINITIONS
-- Each scheme: { id, label, description, requirements, steps, on_complete }
-- Steps: { id, label, description, location, action, cost, check }
-- Requirements: what must be true to even START this scheme
--------------------------------------------------------------------------------

local SCHEME_DEFS = {
    --------------------------------------------------------------------------
    -- UNDERMINE: Destroy someone's reputation
    --------------------------------------------------------------------------
    {
        id = "undermine",
        label = "Undermine",
        description = "Dig up someone's secrets and let the world do the rest.",
        category = "espionage",
        requires = function(gs, focal)
            return (focal.components.signal_affinity or {}).espionage and
                   focal.components.signal_affinity.espionage >= 25
        end,
        requires_text = "Espionage affinity 25+",
        target_type = "person",  -- must pick a target NPC
        steps = {
            { id = "investigate", label = "Investigate the target",
              description = "Learn their routines. Find the cracks.",
              location = nil,  -- any location where target is present
              action = "investigate",  -- uses existing interaction
              on_step = function(gs, focal, target, engine)
                  return { text = "You watch. You listen. The cracks are there — they always are." }
              end },
            { id = "find_leverage", label = "Find leverage",
              description = "Every person has a secret. Find theirs.",
              location = "tavern",
              cost = { gold = 5 },
              on_step = function(gs, focal, target, engine)
                  return { text = "A few coins in the right hands. A name. A date. A place they shouldn't have been." }
              end },
            { id = "plant_rumor", label = "Spread the word",
              description = "Let the truth — or something like it — find its audience.",
              location = "market",
              on_step = function(gs, focal, target, engine)
                  local rumor = engine:get_module("rumor")
                  if rumor then
                      rumor:inject(gs, {
                          origin_type = "scheme", subject = target.name or "someone",
                          text = "Whispers about " .. (target.name or "someone") .. ". The kind that stick.",
                          heat = 55, tags = { scandal = true },
                      })
                  end
                  return { text = "The words are out. You can't take them back. You don't want to." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            -- Target loses standing
            if target.components.needs then
                target.components.needs.status = Math.clamp((target.components.needs.status or 50) - 20, 0, 100)
                target.components.needs.belonging = Math.clamp((target.components.needs.belonging or 50) - 15, 0, 100)
            end
            -- Shift relationship
            local entities = engine:get_module("entities")
            if entities then
                entities:shift_relationship(focal.id, target.id, "dominance", 15)
            end
            -- Suspicion reduction (attention diverted)
            if gs.claim then
                gs.claim.suspicion = Math.clamp((gs.claim.suspicion or 0) - 8, 0, 100)
            end
            return {
                text = (target.name or "They") .. " doesn't know it yet, but they're already falling. " ..
                       "The whispers are spreading. By next month, nobody will remember them the way they were.",
                world_change = "The court feels different. A power has shifted. People are recalculating.",
            }
        end,
    },

    --------------------------------------------------------------------------
    -- SAFE HOUSE: Create a hidden meeting place
    --------------------------------------------------------------------------
    {
        id = "safe_house",
        label = "Establish a Safe House",
        description = "A place where you can't be found. Where the walls don't have ears.",
        category = "survival",
        requires = function(gs, focal)
            local pw = focal.components.personal_wealth
            return pw and pw.gold >= 15
        end,
        requires_text = "15+ gold",
        target_type = nil,
        steps = {
            { id = "find_space", label = "Find a hidden space",
              description = "Somewhere forgotten. Somewhere nobody looks.",
              location = "wilds",
              on_step = function(gs, focal, target, engine)
                  return { text = "Behind the old mill. A cellar nobody remembers. The door is rotten but the walls are stone. This will do." }
              end },
            { id = "stock_it", label = "Stock supplies",
              description = "Water. Blankets. A blade under the floorboard.",
              cost = { gold = 10 },
              on_step = function(gs, focal, target, engine)
                  return { text = "You carry things in after dark. Slowly. Over three nights. Nobody sees. Nobody asks." }
              end },
            { id = "establish_route", label = "Map an escape route",
              description = "Two ways in. Three ways out.",
              location = "road",
              on_step = function(gs, focal, target, engine)
                  return { text = "You walk the paths at night. Count the steps. Memorize the turns. If you ever need this, you won't have time to think." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            -- Reduce suspicion permanently by having an escape
            gs._safe_house = true
            if focal.components.needs then
                focal.components.needs.safety = Math.clamp((focal.components.needs.safety or 50) + 15, 0, 100)
            end
            return {
                text = "It's ready. A place that doesn't exist on any map. Your safety net. Your last resort. "
                    .. "The knowledge that it's there — that changes how you stand.",
                world_change = "You carry yourself differently now. People notice. They don't know why.",
            }
        end,
    },

    --------------------------------------------------------------------------
    -- CULTIVATE INFORMANT: Turn an NPC into your eyes and ears
    --------------------------------------------------------------------------
    {
        id = "informant",
        label = "Cultivate an Informant",
        description = "Someone who tells you things before they happen.",
        category = "espionage",
        requires = function(gs, focal)
            return true  -- always available, but target must be found
        end,
        requires_text = "Pick someone you trust — or someone who owes you",
        target_type = "person",
        steps = {
            { id = "build_trust", label = "Build their trust",
              description = "Three conversations. Three real ones.",
              action = "talk",  -- must talk to this person 3 times (tracked)
              repeat_count = 3,
              on_step = function(gs, focal, target, engine)
                  return { text = "The conversations get easier. The silences get shorter. They're starting to tell you things unprompted." }
              end },
            { id = "make_offer", label = "Make the offer",
              description = "Not money. Something better. Protection.",
              cost = { gold = 5 },
              on_step = function(gs, focal, target, engine)
                  return { text = "'I can keep you safe. But I need to know things.' They look at you for a long time. Then nod." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            -- Mark this entity as informant
            if target.components.memory then
                local MemLib = require("dredwork_agency.memory")
                MemLib.add_debt(target.components.memory, focal.id, "protects me", 40)
            end
            -- Add to informant list
            gs._informants = gs._informants or {}
            table.insert(gs._informants, target.id)
            return {
                text = (target.name or "They") .. " is yours now. Not owned — connected. "
                    .. "When something moves in the shadows, you'll hear about it first.",
                world_change = "Fragments of information reach you from places you've never been. Useful fragments.",
            }
        end,
    },

    --------------------------------------------------------------------------
    -- WIN THE PEOPLE: Build popular support
    --------------------------------------------------------------------------
    {
        id = "win_people",
        label = "Win the People",
        description = "Make them love you before they know who you are.",
        category = "political",
        requires = function(gs, focal)
            return gs.claim and gs.claim.type
        end,
        requires_text = "Active claim",
        target_type = nil,
        steps = {
            { id = "help_three", label = "Help three people in need",
              description = "Not for show. Not for leverage. Help.",
              action = "help",
              repeat_count = 3,
              on_step = function(gs, focal, target, engine)
                  return { text = "Another debt of gratitude. Another person who will remember your face with warmth." }
              end },
            { id = "invest_market", label = "Invest in the market",
              description = "Put gold where it matters. The stalls. The vendors. The people who feed the city.",
              location = "market",
              cost = { gold = 15 },
              on_step = function(gs, focal, target, engine)
                  return { text = "Your gold flows into the market. New stalls. Better stock. People notice. They don't know where the coin came from. They know what it bought." }
              end },
            { id = "be_seen", label = "Be visible. Be present.",
              description = "Walk the streets. Eat at the tavern. Let them know your face.",
              location = "tavern",
              on_step = function(gs, focal, target, engine)
                  return { text = "You sit where people can see you. You buy a round. You listen to their stories. This isn't a performance. Or maybe it is. The line is blurry." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            -- Legitimacy boost
            if gs.politics then
                gs.politics.legitimacy = Math.clamp((gs.politics.legitimacy or 50) + 10, 0, 100)
            end
            -- Unrest reduction
            if gs.politics then
                gs.politics.unrest = Math.clamp((gs.politics.unrest or 0) - 8, 0, 100)
            end
            -- Claim strength boost
            if gs.claim then
                gs.claim.suspicion = Math.clamp((gs.claim.suspicion or 0) - 5, 0, 100)
            end
            -- Needs boost
            if focal.components.needs then
                focal.components.needs.belonging = Math.clamp((focal.components.needs.belonging or 50) + 10, 0, 100)
                focal.components.needs.status = Math.clamp((focal.components.needs.status or 50) + 8, 0, 100)
            end
            return {
                text = "The people don't know your name. But they know your face. They nod when you pass. "
                    .. "They save you the good bread. When the time comes — when you stand and speak — they will remember this.",
                world_change = "The market is brighter. The streets are calmer. Something has changed, and your name is at the center of it.",
            }
        end,
    },

    --------------------------------------------------------------------------
    -- COUNTER-RUMOR: Redirect suspicion
    --------------------------------------------------------------------------
    {
        id = "counter_rumor",
        label = "Spread a Counter-Rumor",
        description = "The best way to hide a truth is behind a bigger lie.",
        category = "espionage",
        requires = function(gs, focal)
            return gs.claim and gs.claim.suspicion > 20
        end,
        requires_text = "Suspicion above 20",
        target_type = nil,
        steps = {
            { id = "craft_story", label = "Craft the story",
              description = "A plausible alternative. Someone else to blame.",
              location = "home",
              on_step = function(gs, focal, target, engine)
                  return { text = "You write it out. Cross it out. Write it again. The lie has to be better than the truth. Simpler. More satisfying." }
              end },
            { id = "seed_tavern", label = "Seed it in the tavern",
              description = "Buy drinks. Tell stories. Let the rumor grow roots.",
              location = "tavern",
              cost = { gold = 5 },
              on_step = function(gs, focal, target, engine)
                  return { text = "'Have you heard? The real heir is in Sunvale. Saw them myself.' You say it like you believe it. Maybe you do." }
              end },
            { id = "seed_market", label = "Let it reach the market",
              description = "The market hears everything. Make sure it hears your version.",
              location = "market",
              on_step = function(gs, focal, target, engine)
                  local rumor = engine:get_module("rumor")
                  if rumor then
                      rumor:inject(gs, {
                          origin_type = "counter_rumor", subject = "a stranger in Sunvale",
                          text = "They say the real claimant is in the south. Has been for years.",
                          heat = 50, tags = { scandal = true },
                      })
                  end
                  return { text = "The lie takes on a life of its own. People add details you never invented. That's how you know it's working." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            if gs.claim then
                gs.claim.suspicion = Math.clamp(gs.claim.suspicion - 20, 0, 100)
            end
            return {
                text = "The investigation shifts. South. Away from you. You hear your false rumor repeated back to you by a stranger "
                    .. "who has no idea you invented it. The truth is buried under a better story.",
                world_change = "The whispers have changed direction. For now, the spotlight points elsewhere.",
            }
        end,
    },

    --------------------------------------------------------------------------
    -- GATHER EVIDENCE: Build your case for the claim
    --------------------------------------------------------------------------
    {
        id = "gather_evidence",
        label = "Gather Evidence for Your Claim",
        description = "Blood alone isn't enough. You need proof.",
        category = "claim",
        requires = function(gs, focal)
            return gs.claim and gs.claim.type and gs.claim.status ~= "recognized"
        end,
        requires_text = "Active claim",
        target_type = nil,
        steps = {
            { id = "search_records", label = "Search the records",
              description = "Birth records. Marriage contracts. Someone wrote the truth down once.",
              location = "court",
              on_step = function(gs, focal, target, engine)
                  return { text = "Hours in the archive. Dust and silence. Then — a ledger entry. A name. YOUR name. Written in ink that has faded but not disappeared." }
              end },
            { id = "find_witness", label = "Find a living witness",
              description = "Someone who was there. Someone who remembers.",
              location = "temple",
              on_step = function(gs, focal, target, engine)
                  return { text = "An old priest. Retired. He remembers a birth that wasn't recorded publicly. A child taken away at night. He prays you're not that child. You are." }
              end },
            { id = "secure_proof", label = "Secure physical proof",
              description = "A seal. A letter. A ring. Something they can't deny.",
              cost = { gold = 10 },
              on_step = function(gs, focal, target, engine)
                  local claim = engine:get_module("claim")
                  if claim then
                      claim:add_evidence({ type = "physical", bonus = 10, text = "Documented proof of lineage" })
                  end
                  return { text = "You hold it in your hands. The seal. Real. Unbroken. This changes everything. This is the weight that tips the scale." }
              end },
        },
        on_complete = function(gs, focal, target, engine)
            if focal.components.needs then
                focal.components.needs.purpose = Math.clamp((focal.components.needs.purpose or 50) + 15, 0, 100)
            end
            return {
                text = "The evidence is assembled. A ledger. A witness. A seal. Three threads that weave into one truth: "
                    .. "you are who you say you are. The question is no longer IF you have a claim. It's whether you'll survive making it.",
                world_change = "You carry something now that changes every conversation. Every glance. Every silence.",
            }
        end,
    },
}

--------------------------------------------------------------------------------
-- SCHEME STATE MANAGEMENT
--------------------------------------------------------------------------------

--- Create the schemes component for game state.
function Schemes.create()
    return {
        available = {},         -- schemes the player can start
        active = nil,           -- the current active scheme (one at a time)
        completed = {},         -- completed scheme ids
        step_progress = {},     -- tracking for repeat_count steps
    }
end

--- Get available schemes based on current game state.
function Schemes.get_available(gs, focal)
    local available = {}
    local completed = gs._schemes and gs._schemes.completed or {}

    for _, def in ipairs(SCHEME_DEFS) do
        -- Skip already completed
        local done = false
        for _, cid in ipairs(completed) do
            if cid == def.id then done = true; break end
        end
        if done then goto next_scheme end

        -- Check requirements
        if def.requires and not def.requires(gs, focal) then goto next_scheme end

        table.insert(available, {
            id = def.id,
            label = def.label,
            description = def.description,
            category = def.category,
            requires_text = def.requires_text,
            target_type = def.target_type,
            step_count = #def.steps,
        })

        ::next_scheme::
    end

    return available
end

--- Start a scheme.
function Schemes.start(gs, scheme_id, target_entity)
    local def = nil
    for _, d in ipairs(SCHEME_DEFS) do
        if d.id == scheme_id then def = d; break end
    end
    if not def then return nil end

    gs._schemes = gs._schemes or Schemes.create()
    gs._schemes.active = {
        id = def.id,
        label = def.label,
        target_id = target_entity and target_entity.id or nil,
        target_name = target_entity and target_entity.name or nil,
        current_step = 1,
        total_steps = #def.steps,
        step_progress = {},  -- for repeat_count tracking
        started_day = gs.clock and gs.clock.total_days or 0,
    }

    return gs._schemes.active
end

--- Get the current step definition.
function Schemes.get_current_step(gs)
    local active = gs._schemes and gs._schemes.active
    if not active then return nil, nil end

    local def = nil
    for _, d in ipairs(SCHEME_DEFS) do
        if d.id == active.id then def = d; break end
    end
    if not def then return nil, nil end

    return def.steps[active.current_step], def
end

--- Can the current step be completed right now?
function Schemes.can_advance(gs, focal, location_type)
    local step, def = Schemes.get_current_step(gs)
    if not step then return false, "No active scheme." end

    -- Location check
    if step.location and step.location ~= location_type then
        return false, "Go to the " .. step.location .. "."
    end

    -- Cost check
    if step.cost and step.cost.gold then
        local pw = focal.components.personal_wealth
        if not pw or pw.gold < step.cost.gold then
            return false, "Need " .. step.cost.gold .. " gold."
        end
    end

    return true, nil
end

--- Advance the current scheme by one step.
function Schemes.advance(gs, focal, engine)
    local step, def = Schemes.get_current_step(gs)
    if not step or not def then return nil end

    local active = gs._schemes.active

    -- Pay costs
    if step.cost and step.cost.gold then
        local WealthLib = require("dredwork_agency.wealth")
        WealthLib.change(focal.components.personal_wealth, -step.cost.gold, "scheme: " .. def.label)
    end

    -- Find target entity
    local target = nil
    if active.target_id then
        local entities = engine:get_module("entities")
        target = entities and entities:get(active.target_id)
    end

    -- Execute step
    local result = step.on_step(gs, focal, target, engine)

    -- Handle repeat_count steps
    if step.repeat_count then
        active.step_progress[step.id] = (active.step_progress[step.id] or 0) + 1
        if active.step_progress[step.id] < step.repeat_count then
            -- Step not complete yet
            result.remaining = step.repeat_count - active.step_progress[step.id]
            return result
        end
    end

    -- Advance to next step
    active.current_step = active.current_step + 1

    -- Check if scheme is complete
    if active.current_step > active.total_steps then
        local completion = def.on_complete(gs, focal, target, engine)
        active.completed = true

        -- Record completion
        gs._schemes.completed = gs._schemes.completed or {}
        table.insert(gs._schemes.completed, def.id)
        gs._schemes.active = nil

        return {
            text = completion.text,
            world_change = completion.world_change,
            completed = true,
        }
    end

    return result
end

--- Get scheme by id.
function Schemes.get_def(scheme_id)
    for _, d in ipairs(SCHEME_DEFS) do
        if d.id == scheme_id then return d end
    end
    return nil
end

--- Is a scheme active?
function Schemes.is_active(gs)
    return gs._schemes and gs._schemes.active and not gs._schemes.active.completed
end

--- Get the active scheme.
function Schemes.get_active(gs)
    return gs._schemes and gs._schemes.active
end

--- Abandon the current scheme.
function Schemes.abandon(gs)
    if gs._schemes then
        gs._schemes.active = nil
    end
end

--------------------------------------------------------------------------------
-- NPC CO-SCHEMERS
-- Recruit an NPC into your scheme. They work steps in parallel.
-- They send you letters with progress updates. They can succeed, fail, or betray.
--------------------------------------------------------------------------------

--- Assign an NPC as co-schemer on the active scheme.
function Schemes.assign_partner(gs, entity_id, entity_name)
    local active = gs._schemes and gs._schemes.active
    if not active then return false end

    active.partner_id = entity_id
    active.partner_name = entity_name
    active.partner_status = "working"   -- working, done, complicated, betrayed
    active.partner_step = nil           -- which step they're working on

    return true
end

--- Assign a specific step to the partner NPC.
function Schemes.assign_partner_step(gs, step_index)
    local active = gs._schemes and gs._schemes.active
    if not active or not active.partner_id then return false end
    active.partner_step = step_index
    active.partner_status = "working"
    return true
end

--- Monthly tick: NPC co-schemers make progress and send letters.
function Schemes.tick_partner(gs, engine)
    local active = gs._schemes and gs._schemes.active
    if not active or not active.partner_id then return end
    if active.partner_status ~= "working" then return end

    local Letters = require("dredwork_agency.letters")
    local day = gs.clock and gs.clock.total_days or 0

    -- Find partner entity for loyalty/personality check
    local entities = engine:get_module("entities")
    local partner = entities and entities:get(active.partner_id)

    -- Base success chance: 60% progress, 15% complication, 5% betrayal
    local roll = RNG.range(1, 100)

    -- Personality modifiers
    local loyalty_bonus = 0
    if partner and partner.components.personality then
        local loy = partner.components.personality.PER_LOY or 50
        if type(loy) == "table" then loy = loy.value or 50 end
        loyalty_bonus = (loy - 50) * 0.3
    end

    -- Suspicion makes betrayal more likely
    local suspicion_penalty = 0
    if gs.claim then
        suspicion_penalty = (gs.claim.suspicion or 0) * 0.15
    end

    local adjusted = roll + loyalty_bonus - suspicion_penalty

    if adjusted > 40 then
        -- Progress / success
        Letters.generate_scheme_update(gs, active.partner_name or "Your ally",
            active.label, "Their assigned task", "progress", day)

        -- 30% chance they complete their step this month
        if RNG.chance(0.30) then
            active.partner_status = "done"
            Letters.generate_scheme_update(gs, active.partner_name or "Your ally",
                active.label, "Their assigned task", "success", day)
        end
    elseif adjusted > 15 then
        -- Complication
        active.partner_status = "complicated"
        Letters.generate_scheme_update(gs, active.partner_name or "Your ally",
            active.label, "Their assigned task", "complication", day)
    else
        -- Betrayal
        active.partner_status = "betrayed"
        Letters.generate_scheme_update(gs, active.partner_name or "Your ally",
            active.label, "Their assigned task", "betrayal", day)

        -- Suspicion spike
        if gs.claim then
            gs.claim.suspicion = Math.clamp((gs.claim.suspicion or 0) + 15, 0, 100)
        end

        -- Partner becomes hostile
        if partner and partner.components.memory then
            local MemLib = require("dredwork_agency.memory")
            MemLib.add_grudge(partner.components.memory, gs.entities.focal_entity_id or "",
                "involved me in a dangerous scheme", 40)
        end
    end
end

return Schemes
