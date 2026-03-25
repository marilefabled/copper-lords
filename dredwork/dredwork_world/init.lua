-- dredwork World — Module Entry
-- High-level simulation of factions, eras, and the march of history.

local World = {}
World.__index = World

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function World.init(engine)
    local self = setmetatable({}, World)
    self.engine = engine
    
    -- Sub-components
    self.world_state      = require("dredwork_world.world_state")
    self.faction_module   = require("dredwork_world.faction")
    self.event_engine     = require("dredwork_world.event_engine")
    self.council          = require("dredwork_world.council")
    self.chronicle        = require("dredwork_world.chronicle")
    self.world_controller = require("dredwork_world.world_controller")

    -- Config data
    self.era_definitions     = require("dredwork_world.config.era_definitions")
    self.starting_factions   = require("dredwork_world.config.starting_factions")
    self.council_actions     = require("dredwork_world.config.council_actions")
    self.narrative_tables    = require("dredwork_world.config.narrative_tables")

    -- Register for engine events
    engine:on("ADVANCE_GENERATION", function(context)
        -- The world controller usually handles the sequence of events per generation
        -- In the unified engine, we can trigger world advancement here.
        if context.game_state.world_state then
            self:tick(context.game_state)
        end
    end)

    return self
end

--- Create a new world.
function World:create_new_world(era_key)
    local state = self.world_state.new(era_key)
    self.engine.game_state.world_state = state:to_table()
    
    -- Initialize factions
    self.engine.game_state.factions = {}
    if self.starting_factions and self.starting_factions.houses then
        for _, def in ipairs(self.starting_factions.houses) do
            table.insert(self.engine.game_state.factions, self.faction_module.Faction.new(def))
        end
    end
    
    return state
end

--- Advance the world by one generation.
function World:tick(game_state)
    -- This would call into world_controller logic
    -- For now, we'll delegate to the world_state advancement
    local state_obj = self.world_state.from_table(game_state.world_state)
    local results = state_obj:advance({
        generation = game_state.generation,
        -- wealth = self.engine.modules.wealth -- if we had it
    })
    game_state.world_state = state_obj:to_table()
    return results
end

--- Standard module serialization.
function World:serialize()
    return self.engine.game_state.world_state or {}
end

--- Standard module deserialization.
function World:deserialize(data)
    self.engine.game_state.world_state = data
end

return World
