-- dredwork Heritage — Module Entry
-- High-level management of legends, monuments, and historical impact.

local Heritage = {}
Heritage.__index = Heritage

function Heritage.init(engine)
    local self = setmetatable({}, Heritage)
    self.engine = engine

    self.logic = require("dredwork_heritage.logic")

    -- Initialize state
    engine.game_state.history = {
        legends = {},
        great_works = {},
        current_generation = 0
    }

    -- Expose heritage data via event bus (queried by Politics, Technology, Culture)
    engine:on("GET_HERITAGE_MODIFIERS", function(req)
        local history = self.engine.game_state.history
        local prestige = 0
        local tradition_bias = 0
        local research_bonus = 0
        local unrest = 0

        -- Active great works contribute prestige and research
        for _, work in ipairs(history.great_works) do
            if work.is_active then
                local condition_factor = (work.condition or 100) / 100
                prestige = prestige + (work.prestige or 10) * condition_factor

                -- Monuments bias tradition; academies bias research
                if work.type == "monument" then
                    tradition_bias = tradition_bias + 2 * condition_factor
                elseif work.type == "academy" or work.type == "library" then
                    research_bonus = research_bonus + 5 * condition_factor
                end
            end
        end

        -- Remembered legends add prestige
        for _, legend in ipairs(history.legends) do
            if legend.is_remembered then
                prestige = prestige + (legend.significance or 5)
            end
        end

        req.prestige = (req.prestige or 0) + prestige
        req.research_bonus = (req.research_bonus or 0) + research_bonus
        req.CUL_TRD = (req.CUL_TRD or 0) + tradition_bias
        req.unrest = (req.unrest or 0) + unrest
    end)

    -- Bias Cultural Axes based on heritage
    engine:on("BIAS_CULTURAL_AXES", function(req)
        local heritage_req = { [req.axis_id] = 0 }
        engine:emit("GET_HERITAGE_MODIFIERS", heritage_req)
        if heritage_req[req.axis_id] and heritage_req[req.axis_id] ~= 0 then
            req.bias = (req.bias or 0) + heritage_req[req.axis_id]
        end
    end)

    -- Influence Politics via unrest
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local heritage_req = { unrest = 0 }
        engine:emit("GET_HERITAGE_MODIFIERS", heritage_req)
        if heritage_req.unrest ~= 0 then
            req.unrest_delta = (req.unrest_delta or 0) + heritage_req.unrest
        end
    end)

    -- Dialogue references
    engine:on("GET_DIALOGUE_CONTEXT", function(req)
        if #self.engine.game_state.history.legends > 0 then
            local RNG = require("dredwork_core.rng")
            local legend = RNG.pick(self.engine.game_state.history.legends)
            if legend and legend.is_remembered then
                req.historical_reference = string.format("as %s did in the age of %s", legend.deed, legend.name)
            end
        end
    end)

    -- Tick history per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self.engine.game_state.history.current_generation = context.generation
        self:tick(context.game_state)
    end)

    return self
end

--- Record a legendary figure.
function Heritage:record_legend(person, deed, significance)
    local figure = self.logic.create_figure(person, deed, significance)
    figure.generation = self.engine.game_state.history.current_generation
    table.insert(self.engine.game_state.history.legends, figure)
    return figure
end

--- Build a Great Work.
function Heritage:build_work(type_key, label, creator_name)
    local work = self.logic.create_work(type_key, label, creator_name)
    table.insert(self.engine.game_state.history.great_works, work)
    return work
end

--- Step historical evolution.
function Heritage:tick(game_state)
    -- Query economy for resource context via event bus
    local req_econ = { gold = 0 }
    self.engine:emit("GET_ECONOMIC_DATA", req_econ)

    local results = self.logic.tick(game_state.history, { gold = req_econ.gold })
    for _, line in ipairs(results) do
        self.engine.log:info(line)
    end
end

function Heritage:serialize() return self.engine.game_state.history end
function Heritage:deserialize(data) self.engine.game_state.history = data end

return Heritage
