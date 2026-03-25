-- dredwork Rumor — Module Entry
-- Information propagation engine.

local Rumor = {}
Rumor.__index = Rumor

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Rumor.init(engine)
    local self = setmetatable({}, Rumor)
    self.engine = engine

    -- Sub-components
    self.logic = require("dredwork_rumor.rumor")
    self.network = require("dredwork_rumor.network")
    self.bridges = require("dredwork_rumor.bridges")

    -- Daily: age rumors and decay heat
    engine:on("NEW_DAY", function(clock)
        self:tick_daily(self.engine.game_state)
    end)

    -- Monthly: spatial propagation (geographic spread is a monthly cadence)
    engine:on("NEW_MONTH", function(clock)
        self:tick_propagation(self.engine.game_state)
    end)

    -- Generational: purge dead rumors, calculate legacy reputation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick_generational(context.game_state, context.generation)
    end)

    return self
end

--- Inject a new rumor into the world.
---@param game_state table
---@param spec table { origin_type, origin_id, subject, text, heat, severity, tags }
function Rumor:inject(game_state, spec)
    return self.network.inject(game_state, spec)
end

--- Daily tick: age rumors and decay heat.
function Rumor:tick_daily(game_state)
    if not game_state.rumor_network or not game_state.rumor_network.rumors then return end

    for _, rumor in pairs(game_state.rumor_network.rumors) do
        if not rumor.dead then
            rumor.total_days_active = (rumor.total_days_active or 0) + 1
            rumor.heat = math.max(0, (rumor.heat or 0) - 0.01)

            -- Expire after threshold (calcified rumors persist indefinitely)
            local expiry_days = rumor.calcified and math.huge or 300
            if rumor.total_days_active > expiry_days then
                rumor.dead = true
            end
        end
    end
end

--- Monthly tick: spatial propagation across regions.
function Rumor:tick_propagation(game_state)
    local geo = self.engine:get_module("geography")
    if not geo then return end
    if not game_state.rumor_network or not game_state.rumor_network.rumors then return end

    for _, rumor in pairs(game_state.rumor_network.rumors) do
        if not rumor.dead and rumor.origin_region then
            self:_propagate_spatially(rumor, geo)
        end
    end
end

--- Generational tick: cleanup and legacy reputation.
function Rumor:tick_generational(game_state, generation)
    -- Purge dead rumors
    if game_state.rumor_network and game_state.rumor_network.rumors then
        for id, rumor in pairs(game_state.rumor_network.rumors) do
            if rumor.dead then
                game_state.rumor_network.rumors[id] = nil
            end
        end
    end

    return self.network.tick(game_state, generation)
end

function Rumor:_propagate_spatially(rumor, geo)
    -- Query cultural spread modifier (tradition slows radical rumors)
    local req_spread = { speed = 1.0, tags = rumor.tags }
    self.engine:emit("GET_RUMOR_SPREAD_MOD", req_spread)
    local spread_speed = req_spread.speed or 1.0

    -- Query travel distance from origin to slow distant spread
    if rumor.origin_region then
        local req_dist = { from = rumor.origin_region, to = nil, distance = 1 }
        -- Distance attenuates heat bleed into neighboring regions
        -- (actual neighbor iteration would go here, using geo adjacency data)
        rumor.effective_reach = math.max(1, math.floor(rumor.heat * spread_speed / 10))
    end

    -- Impact legitimacy via event bus (decoupled from Politics)
    if rumor.heat > 70 then
        local delta = 0
        if rumor.tags.scandal or rumor.tags.shame then
            delta = -1
        elseif rumor.tags.praise or rumor.tags.prestige then
            delta = 1
        end

        if delta ~= 0 then
            self.engine:emit("RUMOR_LEGITIMACY_IMPACT", { delta = delta, rumor = rumor })
        end
    end
end

--- Get reputation data for a subject.
---@param game_state table
---@param subject string
function Rumor:get_reputation(game_state, subject)
    return self.network.reputation(game_state, subject)
end

--- Serialize the rumor network state.
function Rumor:serialize()
    return self.engine.game_state.rumor_network or {}
end

--- Restore the rumor network state.
function Rumor:deserialize(data)
    self.engine.game_state.rumor_network = data or {}
end

return Rumor
