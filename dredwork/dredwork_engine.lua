-- dredwork Engine — Central Orchestrator
-- This is the single entry point for any head/UI/renderer.
-- It manages module lifecycles, global state, and event coordination.

local Events = require("dredwork_core.events")
local RNG = require("dredwork_core.rng")
local Log = require("dredwork_core.log")

local Engine = {}
Engine.__index = Engine

--- Create a new instance of the dredwork engine.
---@param options table { seed, modules, log_level, log_sink }
---@return table Engine instance
function Engine.new(options)
    local self = setmetatable({}, Engine)

    options = options or {}

    -- Instance-based event bus (no shared state between engines)
    self.events = Events.new()

    -- Instance-based RNG (independent PRNG per engine)
    self.seed = options.seed or os.time()
    self.rng = RNG.new(self.seed)
    RNG.set_default(self.rng)

    -- Instance-based logger
    self.log = Log.new({
        level = options.log_level or Log.LEVELS.INFO,
        sink = options.log_sink,
    })

    self.modules = {}
    self.ui_event_queue = {} -- Buffer for the renderer to consume

    self.game_state = {
        seed = self.seed,
        generation = 0,
        year = 0,
        meta = {},

        -- Entity Lookups
        find_person = function(gs, id)
            if gs.bonds and gs.bonds.people then return gs.bonds.people[id] end
            if gs.current_heir and gs.current_heir.id == id then return gs.current_heir end
            -- Entity registry fallback
            if gs.entities and gs.entities.registry and gs.entities.registry[id] then
                return gs.entities.registry[id]
            end
            return nil
        end,

        find_faction = function(gs, id)
            if gs.factions then
                for _, f in ipairs(gs.factions) do if f.id == id then return f end end
            end
            return nil
        end,

        find_region = function(gs, id)
            if gs.world_map and gs.world_map.regions then return gs.world_map.regions[id] end
            return nil
        end
    }

    -- Keep top-level state in sync with the clock (single source of truth)
    self:on("NEW_YEAR", function(clock)
        self.game_state.year = clock.year
    end)
    self:on("NEW_GENERATION", function(clock)
        self.game_state.generation = clock.generation
    end)

    -- Auto-register requested modules
    if options.modules then
        for name, path in pairs(options.modules) do
            self:register_module(name, path)
        end
    end

    return self
end

--- Register a module with the engine.
---@param name string unique module identifier (e.g., "rumor", "genetics")
---@param path string require path to the module's init.lua
function Engine:register_module(name, path)
    local ModuleDef = require(path)
    if type(ModuleDef.init) ~= "function" then
        error(string.format("Module '%s' at path '%s' does not implement init(engine)", name, path))
    end

    -- Initialize the module and store it
    local instance = ModuleDef.init(self)
    self.modules[name] = instance

    -- Provide a shortcut: engine.rumor instead of engine:get_module("rumor")
    if not self[name] then
        self[name] = instance
    end

    return instance
end

--- Get a registered module by name.
---@param name string
---@return table|nil
function Engine:get_module(name)
    return self.modules[name]
end

--- Real-time update loop for engines like LOVE2D.
---@param dt number Delta time in seconds.
---@param days_per_second number|nil Scaling factor (default 1 day per real second).
function Engine:update(dt, days_per_second)
    days_per_second = days_per_second or 1.0
    self._day_accumulator = (self._day_accumulator or 0) + (dt * days_per_second)

    if self._day_accumulator >= 1.0 then
        local whole_days = math.floor(self._day_accumulator)
        self:advance_days(whole_days)
        self._day_accumulator = self._day_accumulator - whole_days
    end
end

--- UI Hook: Buffer an event for the renderer.
function Engine:push_ui_event(name, data)
    table.insert(self.ui_event_queue, { name = name, data = data, timestamp = os.time() })
end

--- UI Hook: Get and clear all buffered events (call this in LOVE update).
function Engine:pop_ui_events()
    local events = self.ui_event_queue
    self.ui_event_queue = {}
    return events
end

--- Global event subscription (proxy to instance event bus).
function Engine:on(event_name, callback)
    self.events:on(event_name, callback)
end

--- Global event emission (proxies to instance event bus + UI buffer).
function Engine:emit(event_name, ...)
    self.events:emit(event_name, ...)

    -- Automatically push major events to UI buffer
    local major_events = {
        ADVANCE_GENERATION = true, NEW_MONTH = true, NEW_YEAR = true,
        MATCH_COMPLETED = true, REBELLION = true, PERIL_STRIKE = true
    }
    if major_events[event_name] then
        self:push_ui_event(event_name, {...})
    end
end

--- Advance the entire simulation by one tick/step.
---@param context table|nil optional context overrides
function Engine:step(context)
    context = context or {}
    context.game_state = self.game_state

    self:emit("BEFORE_STEP", context)
    self:emit("STEP", context)
    self:emit("AFTER_STEP", context)
end

--- Advance the entire simulation by a specific number of days.
function Engine:advance_days(count)
    local chrono = self:get_module("chronology")
    if chrono then
        chrono:tick(count)
    else
        -- Fallback: legacy generational advance when no chronology module
        self.log:warn("No chronology module registered — falling back to generational advance")
        self:_legacy_advance_generation()
    end
end

--- Legacy generational advance (only used when chronology is not registered).
function Engine:_legacy_advance_generation()
    self.game_state.generation = self.game_state.generation + 1
    self.game_state.year = self.game_state.year + 25

    local context = {
        game_state = self.game_state,
        generation = self.game_state.generation,
        year = self.game_state.year,
    }

    self:emit("ADVANCE_GENERATION", context)
end

--- Serialize the entire engine state (all modules + core state).
---@return table
function Engine:serialize()
    local state = {
        core = self.game_state,
        modules = {}
    }

    for name, instance in pairs(self.modules) do
        if type(instance.serialize) == "function" then
            state.modules[name] = instance:serialize()
        end
    end

    return state
end

--- Restore the entire engine state.
---@param state table
function Engine:deserialize(state)
    if not state then return end

    self.game_state = state.core or self.game_state
    if self.game_state.seed then
        self.rng:seed(self.game_state.seed)
    end

    for name, data in pairs(state.modules or {}) do
        local instance = self.modules[name]
        if instance and type(instance.deserialize) == "function" then
            instance:deserialize(data)
        end
    end
end

return Engine
