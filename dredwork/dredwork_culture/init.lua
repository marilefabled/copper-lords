-- dredwork Culture — Module Entry
-- High-level management of societal norms, values, and cultural memory.

local Culture = {}
Culture.__index = Culture

function Culture.init(engine)
    local self = setmetatable({}, Culture)
    self.engine = engine

    self.logic = require("dredwork_culture.logic")

    -- Initialize state
    engine.game_state.culture = self.logic.create()

    -- Expose culture data via event bus
    engine:on("GET_CULTURE_DATA", function(req)
        local axes = self.engine.game_state.culture.axes
        req.tradition_value = axes.CUL_TRD
        req.axes = axes
    end)

    -- Bias new character personality axes based on culture
    engine:on("BIAS_PERSONALITY_GENERATION", function(req)
        local bias = self.logic.get_personality_bias(self.engine.game_state.culture, req.trait_id)
        req.bias = (req.bias or 0) + bias
    end)

    -- Influence rumor spread speed
    engine:on("GET_RUMOR_SPREAD_MOD", function(req)
        local trad = self.engine.game_state.culture.axes.CUL_TRD
        if req.tags and req.tags.radical then
            req.speed = (req.speed or 1.0) * (1 - (trad - 50) / 100)
        end
    end)

    -- Tick culture per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Get current cultural values.
function Culture:get_axes()
    return self.engine.game_state.culture.axes
end

--- Shift a cultural axis.
function Culture:shift(axis_id, delta)
    local axes = self.engine.game_state.culture.axes
    if axes[axis_id] then
        local Math = require("dredwork_core.math")
        axes[axis_id] = Math.clamp(axes[axis_id] + delta, 0, 100)
    end
end

--- Step cultural evolution.
function Culture:tick(game_state)
    -- Query religion influence via event bus (decoupled)
    local req_rel = { zeal = 50 }
    self.engine:emit("GET_RELIGION_DATA", req_rel)
    if (req_rel.zeal or 50) > 70 then
        self:shift("CUL_TRD", 2)
    end

    local results = self.logic.tick(game_state.culture)
    for _, line in ipairs(results) do
        self.engine.log:info(line)
    end
end

function Culture:serialize() return self.engine.game_state.culture end
function Culture:deserialize(data) self.engine.game_state.culture = data end

return Culture
