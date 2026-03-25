-- dredwork Combat — Module Entry
-- Tactical, logic-only combat engine (v2). Pure Lua.

local Combat = {}
Combat.__index = Combat

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Combat.init(engine)
    local self = setmetatable({}, Combat)
    self.engine = engine
    
    -- Sub-components
    self.logic     = require("dredwork_combat_v2.combat")
    self.bridge    = require("dredwork_combat_v2.bridge")
    self.fight_pit = require("dredwork_combat_v2.fight_pit")
    self.moves     = require("dredwork_combat_v2.moves")
    self.templates = require("dredwork_combat_v2.templates")

    return self
end

--- Start a tactical combat session.
function Combat:start_combat(protagonist, rival, arena_type)
    return self.logic.new(protagonist, rival, arena_type)
end

--- Map world data into combat-ready data.
function Combat:map_to_combat(gameState, worldContext)
    return self.bridge.map(gameState, worldContext)
end

--- Standard module serialization.
function Combat:serialize()
    -- Combat is usually transient state, but active battles could be saved.
    return {
        -- active_combat = self.active_combat:to_table()
    }
end

--- Standard module deserialization.
function Combat:deserialize(data)
    -- if data.active_combat then self.active_combat = self.logic.from_table(data.active_combat) end
end

return Combat
