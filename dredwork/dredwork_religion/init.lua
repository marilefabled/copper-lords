-- dredwork Religion — Module Entry
-- High-level management of faith, zeal, and spiritual influence.

local Religion = {}
Religion.__index = Religion

function Religion.init(engine)
    local self = setmetatable({}, Religion)
    self.engine = engine

    self.logic = require("dredwork_religion.logic")

    -- Initialize state
    engine.game_state.religion = {
        active_faith = self.logic.create("animism"),
        diversity = 10 -- 0 to 100
    }

    -- Expose religion data via event bus
    engine:on("GET_RELIGION_DATA", function(req)
        local faith = self.engine.game_state.religion.active_faith
        if faith and faith.attributes then
            req.tolerance = faith.attributes.tolerance
            req.zeal = faith.attributes.zeal
            req.tradition = faith.attributes.tradition
            req.sacred_species = faith.sacred_species
        end
        req.diversity = self.engine.game_state.religion.diversity
    end)

    -- Politics queries for religious unrest
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local faith = self.engine.game_state.religion.active_faith
        local div = self.engine.game_state.religion.diversity
        local mod = self.logic.get_unrest_modifier(faith, div)
        req.unrest_delta = (req.unrest_delta or 0) + mod
    end)

    -- Culture values biased by religion
    engine:on("BIAS_CULTURAL_AXES", function(req)
        local faith = self.engine.game_state.religion.active_faith
        if req.axis_id == "CUL_TRD" then
            req.bias = (req.bias or 0) + (faith.attributes.tradition - 50) * 0.3
        end
    end)

    -- Tick religion per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Step religious evolution.
function Religion:tick(game_state)
    local results = self.logic.tick(game_state.religion.active_faith)
    for _, line in ipairs(results) do
        self.engine.log:info(line)
    end
end

--- Shift to a new faith.
function Religion:adopt_faith(type_key)
    self.engine.game_state.religion.active_faith = self.logic.create(type_key)
end

function Religion:serialize() return self.engine.game_state.religion end
function Religion:deserialize(data) self.engine.game_state.religion = data end

return Religion
