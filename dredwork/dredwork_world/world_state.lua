-- Dark Legacy — World State
-- Tracks current era, generation count, active conditions, and chronicle.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local era_definitions = require("dredwork_world.config.era_definitions")

local WorldState = {}
WorldState.__index = WorldState

--- Create a new world state.
---@param era_key string|nil starting era key (default "ancient")
---@param custom_config table|nil optional overrides for worldbuilder mode
---@return table WorldState instance
function WorldState.new(era_key, custom_config)
    local self = setmetatable({}, WorldState)

    self.current_era_key = era_key or "ancient"
    self.start_era_key = self.current_era_key
    self.generations_in_era = 0
    self.conditions = {}         -- { type, intensity, remaining_gens }
    self.generation = 0
    self.year = 0                -- year tracking (~25 years per generation)
    self.years_per_generation = 25
    self.chronicle = {}          -- last 20 narrative entries
    self.used_events = {}        -- once_per_run event IDs
    self.used_chains = {}        -- completed chain IDs (don't re-trigger)
    self.last_crucible_gen = 0   -- generation of last crucible event

    -- Overrides from Worldbuilder
    if custom_config then
        if custom_config.world_name then
            self.world_name_override = custom_config.world_name
            -- Propagate to shared config so pure Lua modules see the custom name
            pcall(function()
                local wid = require("dredwork_world.config.world_identity")
                wid.world_name = custom_config.world_name
            end)
        end
        if custom_config.start_condition and custom_config.start_condition ~= "none" then
            self:add_condition(custom_config.start_condition,
                custom_config.start_condition_intensity or 0.5,
                custom_config.start_condition_duration or 3)
        end
    end

    return self
end

--- Get the current era definition.
---@return table era definition from config
function WorldState:get_era()
    return era_definitions.eras[self.current_era_key]
end

--- Get the current era name for display.
---@return string
function WorldState:get_era_name()
    local era = self:get_era()
    return era and era.name or "Unknown"
end

--- Get the current world name.
---@return string
function WorldState:get_world_name()
    if self.world_name_override then return self.world_name_override end
    local ok, world_id = pcall(require, "dredwork_world.config.world_identity")
    if ok and world_id and world_id.world_name then return world_id.world_name end
    return "Caldemyr"
end

--- Add a world condition (plague, war, famine, etc.).
---@param condition_type string type of condition
---@param intensity number 0.0-1.0
---@param duration number generations to persist
---@param metadata table|nil optional metadata (e.g. target_faction_id for wars)
function WorldState:add_condition(condition_type, intensity, duration, metadata)
    -- Check if condition already exists, stack by refreshing
    for _, cond in ipairs(self.conditions) do
        if cond.type == condition_type then
            cond.intensity = math.max(cond.intensity, intensity)
            cond.remaining_gens = math.max(cond.remaining_gens, duration)
            if metadata then
                cond.metadata = cond.metadata or {}
                for k, v in pairs(metadata) do cond.metadata[k] = v end
            end
            return
        end
    end
    self.conditions[#self.conditions + 1] = {
        type = condition_type,
        intensity = intensity,
        remaining_gens = duration,
        metadata = metadata,
    }
end

--- Remove a condition by type.
---@param condition_type string
function WorldState:remove_condition(condition_type)
    local live = {}
    for _, cond in ipairs(self.conditions) do
        if cond.type ~= condition_type then
            live[#live + 1] = cond
        end
    end
    self.conditions = live
end

--- Check if a condition is active.
---@param condition_type string
---@return boolean
function WorldState:has_condition(condition_type)
    for _, cond in ipairs(self.conditions) do
        if cond.type == condition_type and cond.remaining_gens > 0 then
            return true
        end
    end
    return false
end

--- Get a specific active condition.
---@param condition_type string
---@return table|nil condition or nil
function WorldState:get_condition(condition_type)
    for _, cond in ipairs(self.conditions) do
        if cond.type == condition_type and cond.remaining_gens > 0 then
            return cond
        end
    end
    return nil
end

--- Get metadata for a specific active condition.
---@param condition_type string
---@return table|nil metadata or nil
function WorldState:get_condition_metadata(condition_type)
    local cond = self:get_condition(condition_type)
    return cond and cond.metadata or nil
end

--- Get all active condition types as a list of strings.
---@return table array of condition type strings
function WorldState:get_active_condition_types()
    local types = {}
    for _, cond in ipairs(self.conditions) do
        if cond.remaining_gens > 0 then
            types[#types + 1] = cond.type
        end
    end
    return types
end

--- Advance the world by one generation. Ticks conditions, applies ambient pressure,
--- checks for era transition.
---@param context table world context from WorldController
---@return table results { era_shifted, new_era_key, expired_conditions, ambient_applied }
function WorldState:advance(context)
    local mutation_pressure = context.mutation_pressure
    -- Use authoritative generation from game_state context when available,
    -- fall back to self-increment for standalone/test usage.
    if context.generation then
        self.generation = context.generation
    else
        self.generation = self.generation + 1
    end
    self.generations_in_era = self.generations_in_era + 1
    self.year = (self.year or 0) + (self.years_per_generation or 25)

    local results = {
        era_shifted = false,
        new_era_key = nil,
        expired_conditions = {},
        ambient_applied = {},
    }

    -- 1. Tick down conditions, collect expired
    local live = {}
    for _, cond in ipairs(self.conditions) do
        cond.remaining_gens = cond.remaining_gens - 1
        if cond.remaining_gens > 0 then
            live[#live + 1] = cond
        else
            results.expired_conditions[#results.expired_conditions + 1] = cond.type
        end
    end
    self.conditions = live

    -- 2. Apply ambient era pressure to mutation system
    local era = self:get_era()
    if era and mutation_pressure then
        local Mutation = require("dredwork_genetics.mutation")
        for _, ap in ipairs(era.ambient_pressure) do
            Mutation.add_trigger(mutation_pressure, ap.type, ap.intensity)
            results.ambient_applied[#results.ambient_applied + 1] = ap.type
        end

        -- Also apply active condition pressure
        for _, cond in ipairs(self.conditions) do
            Mutation.add_trigger(mutation_pressure, cond.type, cond.intensity)
        end
    end

    -- 2. Wealth / Power passive shifts from conditions
    if context.wealth then
        local Wealth = require("dredwork_world.wealth")
        for _, cond in ipairs(self.conditions) do
            if cond.type == "plague" then
                Wealth.change(context.wealth, -3 * cond.intensity, "loss", self.generation, "Economic stagnation due to plague")
            elseif cond.type == "war" then
                Wealth.change(context.wealth, -5 * cond.intensity, "loss", self.generation, "War costs and logistics")
            elseif cond.type == "famine" then
                Wealth.change(context.wealth, -4 * cond.intensity, "loss", self.generation, "Crop failure and starvation")
            elseif cond.type == "prosperity" or cond.type == "golden_age" then
                Wealth.change(context.wealth, 8 * cond.intensity, "trade", self.generation, "Era of unparalleled prosperity")
            elseif cond.type == "exodus" then
                Wealth.change(context.wealth, -6 * cond.intensity, "loss", self.generation, "Cost of mass migration")
            end
        end
    end

    -- 2c. Holdings damage from active war/exodus conditions
    if context.holdings then
        for _, cond in ipairs(self.conditions) do
            if cond.type == "war" and rng.chance(0.35 * cond.intensity) then
                local dmg = context.holdings:damage_random_domain()
                if dmg then
                    self:add_chronicle(dmg, { origin = "war_condition", generation = self.generation })
                end
            elseif cond.type == "exodus" then
                -- Exodus strips holdings — you can't have ancestral homes while fleeing
                local lost = context.holdings:lose_domain()
                if lost then
                    self:add_chronicle("The " .. lost.name .. " was abandoned in the exodus.", {
                        origin = "exodus_condition", generation = self.generation,
                    })
                end
            end
        end
    end

    -- 2b. Escalation: condition overlap chance in late game
    local active_count = #self.conditions
    if self.generation >= 30 and active_count >= 1 and active_count < 3 then
        local overlap_chance = self.generation >= 60 and 0.20 or 0.12
        if rng.chance(overlap_chance) then
            local possible = { "plague", "war", "famine", "exodus", "mystical_blight", "religious_schism", "golden_age" }
            -- Remove already-active condition types
            local active_types = {}
            for _, cond in ipairs(self.conditions) do
                active_types[cond.type] = true
            end
            local available = {}
            for _, t in ipairs(possible) do
                if not active_types[t] then available[#available + 1] = t end
            end
            if #available > 0 then
                local new_cond = available[rng.range(1, #available)]
                local duration = rng.range(2, 5)
                -- Late-game intensity scaling: conditions hit harder as generations accumulate
                local base_lo, base_hi = 3, 7
                if self.generation >= 60 then
                    base_lo, base_hi = 5, 9
                elseif self.generation >= 40 then
                    base_lo, base_hi = 4, 8
                end
                local intensity = rng.range(base_lo, base_hi) / 10
                self:add_condition(new_cond, intensity, duration)
                results.overlap_condition = new_cond
            end
        end
    end

    -- 2c. Late-game condition persistence: conditions last longer as the world decays
    if self.generation >= 50 then
        for _, cond in ipairs(self.conditions) do
            -- 30% chance each condition resists ticking down (persists 1 extra gen)
            -- This makes late-game crises stickier without being deterministic
            if cond.remaining_gens and cond.remaining_gens <= 1 and cond.type ~= "golden_age" then
                if rng.chance(0.30) then
                    cond.remaining_gens = cond.remaining_gens + 1
                    results.condition_persisted = results.condition_persisted or {}
                    results.condition_persisted[#results.condition_persisted + 1] = cond.type
                end
            end
        end
    end

    -- 3. Check for era transition
    if era and #era.transitions > 0 then
        local past_min = self.generations_in_era >= era.min_generations
        local pressure_val = mutation_pressure and mutation_pressure.value or 0
        local above_threshold = pressure_val >= era.transition_pressure_threshold

        if past_min and above_threshold then
            -- Chance increases each generation past minimum
            local extra_gens = self.generations_in_era - era.min_generations
            local chance = extra_gens * era_definitions.transition_chance_per_gen
            -- Force transition at max generations
            if self.generations_in_era >= era.max_generations then
                chance = 1.0
            end

            if rng.chance(chance) then
                local new_era_key = era.transitions[rng.range(1, #era.transitions)]
                results.era_shifted = true
                results.new_era_key = new_era_key
                self:_transition_era(new_era_key, mutation_pressure)
            end
        end
    end

    return results
end

--- Add a chronicle entry.
---@param text string narrative text
---@param metadata table|nil optional { heir_name, era, reputation, event_ids, generation }
function WorldState:add_chronicle(text, metadata)
    self._next_chronicle_idx = (self._next_chronicle_idx or 0) + 1
    local entry = {
        text = text,
        generation = self.generation,
        era = self.current_era_key,  -- always stamp current era
        sort_index = self._next_chronicle_idx,
        origin = metadata and metadata.origin or nil, -- { type, heir_name, gen, detail }
    }
    if metadata then
        entry.heir_name = metadata.heir_name
        if metadata.era then entry.era = metadata.era end
        if metadata.generation then entry.generation = metadata.generation end
        entry.reputation = metadata.reputation
        entry.event_ids = metadata.event_ids
    end
    self.chronicle[#self.chronicle + 1] = entry

    -- Prune old entries to prevent save bloat (keep last 200)
    -- Fragments are compact one-liners; the Soul Teller on bloodweight.com
    -- uses them as raw material for the literary chronicle.
    if #self.chronicle > 200 then
        table.remove(self.chronicle, 1)
    end
end

--- Get recent chronicle entries.
---@param count number|nil how many (default all, max 20)
---@return table array of { text, generation }
function WorldState:get_chronicle(count)
    count = count or #self.chronicle
    local result = {}
    local start = math.max(1, #self.chronicle - count + 1)
    for i = start, #self.chronicle do
        result[#result + 1] = self.chronicle[i]
    end
    return result
end

--- Serialize to a plain table for saving.
---@return table
function WorldState:to_table()
    return {
        current_era_key = self.current_era_key,
        start_era_key = self.start_era_key,
        generations_in_era = self.generations_in_era,
        conditions = self.conditions,
        generation = self.generation,
        year = self.year,
        years_per_generation = self.years_per_generation,
        chronicle = self.chronicle,
        _next_chronicle_idx = self._next_chronicle_idx,
        used_events = self.used_events,
        used_chains = self.used_chains,
        last_crucible_gen = self.last_crucible_gen,
        world_name_override = self.world_name_override,
    }
end

--- Restore from a saved table.
---@param data table
---@return table WorldState
function WorldState.from_table(data)
    local self = setmetatable({}, WorldState)
    self.current_era_key = data.current_era_key or "ancient"
    self.start_era_key = data.start_era_key or self.current_era_key
    self.generations_in_era = data.generations_in_era or 0
    self.conditions = data.conditions or {}
    self.generation = data.generation or 0
    self.year = data.year or (data.generation or 0) * 25
    self.years_per_generation = data.years_per_generation or 25
    self.chronicle = data.chronicle or {}
    -- Recover sort_index from the highest existing entry to prevent collisions after pruning
    local max_idx = 0
    for _, entry in ipairs(self.chronicle) do
        if entry.sort_index and entry.sort_index > max_idx then
            max_idx = entry.sort_index
        end
    end
    self._next_chronicle_idx = data._next_chronicle_idx or max_idx
    -- Ensure we never go backwards (handles corrupted saves)
    if self._next_chronicle_idx < max_idx then
        self._next_chronicle_idx = max_idx
    end
    self.used_events = data.used_events or {}
    self.used_chains = data.used_chains or {}
    self.last_crucible_gen = data.last_crucible_gen or 0
    self.world_name_override = data.world_name_override
    -- Propagate to shared config so pure Lua modules see the custom name
    if self.world_name_override then
        pcall(function()
            local wid = require("dredwork_world.config.world_identity")
            wid.world_name = self.world_name_override
        end)
    end
    return self
end

-- Internal: perform era transition
function WorldState:_transition_era(new_era_key, mutation_pressure)
    self.current_era_key = new_era_key
    self.generations_in_era = 0

    -- Era shift triggers a one-time mutation pressure spike
    if mutation_pressure then
        local Mutation = require("dredwork_genetics.mutation")
        Mutation.add_trigger(mutation_pressure, "era_shift", 1.0)
    end
end

return WorldState
