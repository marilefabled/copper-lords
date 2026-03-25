-- dredwork Peril — Module Entry
-- High-level management of outbreaks and environmental catastrophes.

local Peril = {}
Peril.__index = Peril

function Peril.init(engine)
    local self = setmetatable({}, Peril)
    self.engine = engine
    
    self.logic = require("dredwork_peril.logic")
    self.archetypes = require("dredwork_peril.archetypes")

    -- Initialize state
    engine.game_state.perils = {
        active = {},
        history = {}
    }

    -- 1. Daily simulation
    engine:on("NEW_DAY", function(clock)
        self:tick_daily(clock)
    end)

    -- 2. Monthly impact calculation
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(clock)
    end)

    -- 3. Interconnection: Home module asks for environmental damage
    engine:on("GET_HOME_ENVIRONMENT_MOD", function(req)
        local impacts = self.logic.calculate_monthly_impact(self.engine.game_state.perils.active)
        req.decay_delta = (req.decay_delta or 0) + impacts.home_damage
    end)

    -- 4. Interconnection: Politics asks for unrest modifiers
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local impacts = self.logic.calculate_monthly_impact(self.engine.game_state.perils.active)
        req.unrest_delta = (req.unrest_delta or 0) + impacts.unrest_gain
    end)

    return self
end

--- Start a new disaster or disease outbreak.
function Peril:trigger(type_key, location_id)
    local peril = self.logic.start_peril(type_key, location_id)
    table.insert(self.engine.game_state.perils.active, peril)
    self.engine.log:warn("%s has struck %s!", peril.label, location_id or "the world")
    
    -- Inject Rumor
    local rumor = self.engine:get_module("rumor")
    if rumor then
        rumor:inject(self.engine.game_state, {
            origin_type = "peril",
            subject = location_id or "global",
            text = "Fear spreads as " .. peril.label .. " takes hold.",
            heat = 100,
            tags = { peril = true, fear = true }
        })
    end
    
    return peril
end

--- Daily tick for all active perils.
function Peril:tick_daily(clock)
    local state = self.engine.game_state.perils
    local context = { population_density = 1.0 } -- Could query geography/urbanization
    
    for i = #state.active, 1, -1 do
        local p = state.active[i]
        if p.category == "disease" then
            self.logic.tick_disease_daily(p, context)
        else
            self.logic.tick_disaster_daily(p)
        end
        
        if not p.is_active then
            self.engine.log:info("%s has subsided.", p.label)
            table.insert(state.history, p)
            table.remove(state.active, i)
        end
    end
end

--- Monthly tick for economic impacts.
function Peril:tick_monthly(clock)
    local impacts = self.logic.calculate_monthly_impact(self.engine.game_state.perils.active)
    
    -- Drain Economy
    local econ = self.engine:get_module("economy")
    if econ and impacts.gold_loss > 0 then
        econ:change_wealth(-impacts.gold_loss)
    end
    
    -- Scarcity: Affect local markets
    if impacts.food_scarcity > 0 then
        local req_geo = { current_region_id = nil }
        self.engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        local current_region = req_geo.current_region_id
        if current_region and econ then
            local market = econ:get_market(current_region)
            market.supply.food = math.max(0, market.supply.food - impacts.food_scarcity)
        end
    end
end

function Peril:serialize() return self.engine.game_state.perils end
function Peril:deserialize(data) self.engine.game_state.perils = data end

return Peril
