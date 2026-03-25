-- Dark Legacy — Event Chains (Multi-Gen Story Arcs)
-- Sequences of 2-4 linked events spanning multiple generations.
-- A chain starts with an inciting event; subsequent stages fire in later
-- generations based on previous choices.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local chain_defs = require("dredwork_world.config.event_chains")

local EventChains = {}

local MAX_ACTIVE_CHAINS = 2
local CHAIN_EXPIRY_GENS = 15  -- chains stall-killed after 15 generations without advancing

--- Remove chains that have stalled beyond CHAIN_EXPIRY_GENS.
--- Modifies active_chains in-place, returns IDs of expired chains.
---@param active_chains table array of chain_state objects
---@param generation number current generation
---@return table array of expired chain_id strings
function EventChains.prune_expired(active_chains, generation)
    if not active_chains then return {} end
    local expired = {}
    local i = 1
    while i <= #active_chains do
        local chain = active_chains[i]
        local age = generation - (chain.last_gen or chain.started_gen or 0)
        if age >= CHAIN_EXPIRY_GENS then
            expired[#expired + 1] = chain.chain_id
            table.remove(active_chains, i)
        else
            i = i + 1
        end
    end
    return expired
end

--- Check if any pending chain stages are ready to fire this generation.
---@param active_chains table array of chain_state objects
---@param generation number current generation
---@return table array of { chain_index, event } ready to fire
function EventChains.check_pending(active_chains, generation)
    if not active_chains then return {} end

    -- Prune stale chains before checking
    EventChains.prune_expired(active_chains, generation)

    local ready = {}
    for i, chain in ipairs(active_chains) do
        if chain.next_fire_gen and generation >= chain.next_fire_gen then
            -- Find the chain definition
            local def = EventChains._get_def(chain.chain_id)
            if def then
                local next_stage = chain.stage + 1
                local stage_event = EventChains._get_stage_event(def, next_stage, chain.choices)
                if stage_event then
                    ready[#ready + 1] = {
                        chain_index = i,
                        event = stage_event,
                        chain_id = chain.chain_id,
                        stage = next_stage,
                    }
                end
            end
        end
    end

    return ready
end

--- Start a new chain. Returns the chain state to store in gameState.
---@param chain_id string
---@param generation number
---@param choice_key string player's choice at stage 1
---@return table chain_state
function EventChains.start_chain(chain_id, generation, choice_key)
    local def = EventChains._get_def(chain_id)
    if not def then return nil end

    local delay_min = def.stage_delay and def.stage_delay[1] or 1
    local delay_max = def.stage_delay and def.stage_delay[2] or 2
    local delay = rng.range(delay_min, delay_max)

    return {
        chain_id = chain_id,
        stage = 1,
        started_gen = generation,
        last_gen = generation,
        next_fire_gen = generation + delay,
        choices = { choice_key },
        data = {},
    }
end

--- Advance a chain after a stage is resolved.
---@param chain_state table
---@param choice_key string player's choice at current stage
---@param generation number current generation
---@return table|nil updated chain_state, or nil if chain is complete
function EventChains.advance_chain(chain_state, choice_key, generation)
    if not chain_state then return nil end

    local def = EventChains._get_def(chain_state.chain_id)
    if not def then return nil end

    chain_state.stage = chain_state.stage + 1
    chain_state.last_gen = generation
    chain_state.choices[#chain_state.choices + 1] = choice_key

    -- Check if chain is complete
    if chain_state.stage >= def.stages then
        return nil -- chain complete
    end

    -- Set next fire generation
    local delay_min = def.stage_delay and def.stage_delay[1] or 1
    local delay_max = def.stage_delay and def.stage_delay[2] or 2
    local delay = rng.range(delay_min, delay_max)
    chain_state.next_fire_gen = generation + delay

    return chain_state
end

--- Check if a new chain should trigger based on context.
---@param active_chains table current active chains
---@param context table { world_state, factions, heir_personality, heir_genome, cultural_memory, generation }
---@return table|nil { chain_id, event } if a chain triggers, nil otherwise
function EventChains.check_new_triggers(active_chains, context)
    active_chains = active_chains or {}

    -- Max active chains check
    if #active_chains >= MAX_ACTIVE_CHAINS then return nil end

    -- Build set of active chain IDs
    local active_ids = {}
    for _, chain in ipairs(active_chains) do
        active_ids[chain.chain_id] = true
    end

    -- Check used chains from world_state
    local used_chains = {}
    if context.world_state then
        used_chains = context.world_state.used_chains or {}
    end

    local generation = context.generation or 1

    for _, def in ipairs(chain_defs) do
        -- Skip if already active or already completed
        if not active_ids[def.id] and not used_chains[def.id] then
            -- Check trigger conditions
            if EventChains._check_trigger(def.trigger, context) then
                -- Chance-based (30% per eligible generation)
                if rng.chance(0.3) then
                    -- Get stage 1 event
                    local stage_event = EventChains._get_stage_event(def, 1, {})
                    if stage_event then
                        return {
                            chain_id = def.id,
                            event = stage_event,
                        }
                    end
                end
            end
        end
    end

    return nil
end

--- Get a chain event formatted for the event engine display.
---@param chain_id string
---@param stage number
---@param choices table array of previous choice_keys
---@param vars table|nil { heir_name, etc. }
---@return table|nil event compatible with event engine display
function EventChains.get_chain_event(chain_id, stage, choices, vars)
    local def = EventChains._get_def(chain_id)
    if not def then return nil end
    return EventChains._get_stage_event(def, stage, choices, vars)
end

--- Get the definition for a chain by ID.
---@param chain_id string
---@return table|nil chain definition
function EventChains._get_def(chain_id)
    for _, def in ipairs(chain_defs) do
        if def.id == chain_id then return def end
    end
    return nil
end

--- Check if a trigger condition is met.
---@param trigger table trigger definition
---@param context table game context
---@return boolean
function EventChains._check_trigger(trigger, context)
    if not trigger then return false end

    local generation = context.generation or 1

    -- Generation minimum
    if trigger.min_generation and generation < trigger.min_generation then
        return false
    end

    -- Condition-based trigger
    if trigger.type == "condition" then
        local ws = context.world_state
        if not ws then return false end
        if not ws:has_condition(trigger.condition) then return false end
        -- Optional minimum duration gate (condition must have lasted N+ gens)
        if trigger.min_duration then
            local cond = ws:get_condition(trigger.condition)
            -- We don't track how long a condition has been active, only remaining_gens.
            -- Approximate: if remaining_gens is low, it's been active a while.
            -- Better: check if world has had this condition continuously.
            -- For now, use a heuristic: active campaign duration_gens
            if context.campaign and context.campaign.duration_gens then
                if context.campaign.duration_gens < trigger.min_duration then return false end
            end
        end
        return true
    end

    -- Faction-based trigger
    if trigger.type == "faction" then
        local factions = context.factions
        if not factions then return false end
        if trigger.faction_hostile then
            local active = factions:get_active()
            for _, f in ipairs(active) do
                if f:is_hostile() then
                    -- Optional grudge intensity gate
                    if trigger.faction_grudge_intensity_min then
                        if f.has_grudge and f:has_grudge("player") then
                            local grudge = f:has_grudge("player")
                            if grudge.intensity >= trigger.faction_grudge_intensity_min then
                                return true
                            end
                        end
                    else
                        return true
                    end
                end
            end
            return false
        end
        return true
    end

    -- Trait-based trigger
    if trigger.type == "trait" then
        local genome = context.heir_genome
        if not genome then return false end
        local cat = trigger.category
        if cat then
            local traits = genome:get_category(cat)
            if #traits == 0 then return false end
            local sum = 0
            for _, t in ipairs(traits) do sum = sum + (t:get_value() or 50) end
            local avg = sum / #traits
            if trigger.min_average and avg < trigger.min_average then return false end
        end
        return true
    end

    -- Personality-based trigger
    if trigger.type == "personality" then
        local pers = context.heir_personality
        if not pers then return false end
        local val = pers:get_axis(trigger.axis) or 50
        if trigger.min_value and val < trigger.min_value then return false end
        if trigger.max_value and val > trigger.max_value then return false end
        return true
    end

    -- Cultural memory trigger
    if trigger.type == "cultural_memory" then
        local cm = context.cultural_memory
        if not cm then return false end
        if trigger.requires == "old_relationship_ally" then
            for _, rel in ipairs(cm.relationships or {}) do
                if rel.type == "ally" and (generation - (rel.origin_gen or 0)) >= 5 then
                    return true
                end
            end
            return false
        end
        return true
    end

    -- Special triggers (checked externally or always eligible)
    if trigger.type == "special" then
        -- "multiple_heirs" — check via context flag
        if trigger.condition == "multiple_heirs" then
            return (context.children_count or 0) >= 3
        end
        -- "trait_fossil" — check via context flag
        if trigger.condition == "trait_fossil" then
            return context.has_trait_fossil or false
        end
        return false
    end

    return false
end

--- Build a stage event from the definition.
---@param def table chain definition
---@param stage number
---@param choices table array of previous choice_keys
---@param vars table|nil variable substitutions
---@return table|nil event object for display
function EventChains._get_stage_event(def, stage, choices, vars)
    choices = choices or {}

    -- Find the stage event definition
    local stage_def = nil
    for _, evt in ipairs(def.events) do
        if evt.stage == stage then
            stage_def = evt
            break
        end
    end
    if not stage_def then return nil end

    -- Determine narrative (may depend on previous choice)
    local narrative = stage_def.narrative
    if stage_def.narrative_by_choice and #choices > 0 then
        local last_choice = choices[#choices]
        narrative = stage_def.narrative_by_choice[last_choice]
            or stage_def.narrative_by_choice.default
            or narrative
            or ""
    end

    -- Determine options (may depend on previous choice)
    local options = stage_def.options
    if stage_def.options_by_choice and #choices > 0 then
        local last_choice = choices[#choices]
        options = stage_def.options_by_choice[last_choice]
            or stage_def.options_by_choice.default
            or options
            or {}
    end
    options = options or {}

    -- Build event object compatible with event engine display
    local event_options = {}
    for _, opt in ipairs(options) do
        event_options[#event_options + 1] = {
            label = opt.label,
            description = opt.description or "",
            consequences = opt.consequences,
            requires = opt.requires,
            available = true, -- gating handled by event engine
            choice_key = opt.choice_key,
        }
    end

    return {
        type = "chain",
        id = def.id .. "_stage_" .. stage,
        chain_id = def.id,
        chain_stage = stage,
        chain_total_stages = def.stages,
        title = stage_def.title or def.title,
        narrative = narrative or "",
        options = event_options,
        auto_resolve = false,
    }
end

return EventChains
