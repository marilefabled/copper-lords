-- dredwork Strife — Module Entry
-- High-level management of trait-based social friction and identity conflict.

local RNG = require("dredwork_core.rng")

local Strife = {}
Strife.__index = Strife

function Strife.init(engine)
    local self = setmetatable({}, Strife)
    self.engine = engine

    self.logic = require("dredwork_strife.logic")

    -- Initialize state
    engine.game_state.strife = {
        regional_biases = {},
        faction_biases = {},
        global_tension = 0
    }

    -- Influence Political Unrest based on local friction
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local req_geo = { current_region_id = nil }
        engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        if req_geo.current_region_id then
            local region_id = req_geo.current_region_id
            if region_id then
                local friction = self:get_regional_friction(region_id)
                if friction > 20 then
                    req.unrest_delta = (req.unrest_delta or 0) + (friction / 10)
                end
            end
        end
    end)

    -- Daily bias drift
    engine:on("NEW_DAY", function(clock)
        for _, biases in pairs(self.engine.game_state.strife.regional_biases) do
            self.logic.tick_biases(biases)
        end
    end)

    -- Monthly migration checks
    engine:on("NEW_MONTH", function(clock)
        self:tick_migration(self.engine.game_state)
    end)

    -- Generational summary
    engine:on("ADVANCE_GENERATION", function(context)
        -- Generational summary
    end)

    return self
end

--- Set a bias for a region.
function Strife:set_regional_bias(region_id, trait_id, mean, weight)
    self.engine.game_state.strife.regional_biases[region_id] = self.engine.game_state.strife.regional_biases[region_id] or {}
    self.engine.game_state.strife.regional_biases[region_id][trait_id] = { mean = mean, weight = weight or 1.0 }
end

--- Get total friction score for a region based on population diversity vs bias.
function Strife:get_regional_friction(region_id)
    local biases = self.engine.game_state.strife.regional_biases[region_id]
    if not biases then return 0 end
    return 10 -- Placeholder for Pass 1
end

--- Calculate friction between a person and their current location.
function Strife:get_person_friction(person, region_id)
    local biases = self.engine.game_state.strife.regional_biases[region_id]
    if not biases or not person.traits then return 0 end

    local traits = {}
    for id, t in pairs(person.traits) do traits[id] = t.value end

    return self.logic.calculate_bias_friction(traits, biases)
end

--- Step migration simulation (Monthly).
function Strife:tick_migration(game_state)
    local geo = self.engine:get_module("geography")
    local econ = self.engine:get_module("economy")
    local rumor = self.engine:get_module("rumor")

    local req_geo = { regions = {} }
    self.engine:emit("GET_GEOGRAPHY_DATA", req_geo)
    if geo and req_geo.regions then
        for region_id, region in pairs(req_geo.regions) do
            local friction = self:get_regional_friction(region_id)

            -- Query unrest via event bus (decoupled from Politics)
            local req_pol = { unrest = 0 }
            self.engine:emit("GET_POLITICAL_UNREST_MOD", req_pol)
            local unrest = req_pol.unrest or 0

            local market = econ and econ:get_market(region_id)
            local scarcity = market and (100 - market.supply.food) or 0

            local push_factor = self.logic.calculate_push_factor(friction, unrest, scarcity)

            if push_factor > 40 and RNG.chance(0.05) then
                local target = self.logic.choose_migration_target(region_id, req_geo.regions, self, econ)
                if target then
                    self.engine.log:info("Local crisis in %s is driving migrants toward %s.", region_id, target.id)
                    if rumor then
                        rumor:inject(game_state, {
                            origin_type = "migration",
                            subject = target.id,
                            text = "Groups of travelers from " .. region_id .. " have been seen on the roads.",
                            heat = 30,
                            tags = { migration = true }
                        })
                    end
                    self:set_regional_bias(target.id, "PHY_SKN", 50, 0.01)
                end
            end
        end
    end
end

function Strife:serialize() return self.engine.game_state.strife end
function Strife:deserialize(data) self.engine.game_state.strife = data end

return Strife
