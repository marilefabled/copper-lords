-- dredwork Bonds — Module Entry
-- Inter-generational social network: relationships, reputation, and life events.

local Bonds = {}
Bonds.__index = Bonds

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Bonds.init(engine)
    local self = setmetatable({}, Bonds)
    self.engine = engine
    -- Sub-components
    self.bonds        = require("dredwork_bonds.bonds")
    self.setup        = require("dredwork_bonds.setup")
    self.life         = require("dredwork_bonds.life")
    self.career       = require("dredwork_bonds.career")
    self.possessions  = require("dredwork_bonds.possessions")
    self.events       = require("dredwork_bonds.events")
    self.year         = require("dredwork_bonds.year")
    self.mortality    = require("dredwork_bonds.mortality")
    self.aftermath    = require("dredwork_bonds.aftermath")

    -- COMPLEX TEMPORAL INTEGRATION: Daily birthday check
    engine:on("NEW_DAY", function(clock)
        local heir = engine.game_state.current_heir
        if heir and heir.birth_month == clock.month and heir.birth_day == clock.day then
            heir.age = (heir.age or 0) + 1
            engine.log:info("Happy Birthday to %s! They are now %d.", engine.game_state.heir_name or "the heir", heir.age)

            -- Trigger character development (moved from bulk generation tick)
            local genetics = engine:get_module("genetics")
            if genetics then genetics:tick(engine.game_state) end
        end
    end)

    -- Generational life simulation
    engine:on("ADVANCE_GENERATION", function(context)
        -- Tick the life simulation for the generation
        if context.game_state.bonds then
            self:tick_generation(context.game_state)
        end
    end)

    return self
end

--- Create a new life/setup state.
function Bonds:new_setup(seed)
    return self.setup.new(seed)
end

--- Step the social network for a generation.
function Bonds:tick_generation(game_state)
    -- This module uses an aging/tick process that accumulates into generations.
    self.year.apply_aging(game_state)
end

--- Standard module serialization.
function Bonds:serialize()
    return self.engine.game_state.bonds or {}
end

--- Standard module deserialization.
function Bonds:deserialize(data)
    self.engine.game_state.bonds = data
end

return Bonds
