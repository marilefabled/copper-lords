-- dredwork Technology — Module Entry
-- High-level management of scientific progress and system-wide multipliers.

local Technology = {}
Technology.__index = Technology

function Technology.init(engine)
    local self = setmetatable({}, Technology)
    self.engine = engine

    self.logic = require("dredwork_technology.logic")

    -- Initialize state
    engine.game_state.technology = self.logic.create()

    -- Provide multipliers to other modules
    engine:on("GET_TECH_MULTIPLIER", function(req)
        local field = engine.game_state.technology.fields[req.field_id]
        if field then
            req.multiplier = (req.multiplier or 1.0) * field.multiplier
        end
    end)

    -- Tick technology per generation
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Step technology evolution.
function Technology:tick(game_state)
    local ctx = { is_high_progress = false, bonus_research = 0 }

    -- Query political system via event bus
    local req_pol = { unrest = 0, legitimacy = 0 }
    self.engine:emit("GET_POLITICAL_UNREST_MOD", req_pol)
    -- Query for political system type
    local req_sys = { system_id = "monarchy" }
    self.engine:emit("GET_POLITICAL_SYSTEM", req_sys)
    if req_sys.system_id == "meritocracy" then
        ctx.is_high_progress = true
    end

    -- Query cultural tradition/progress via event bus
    local req_culture = { tradition_value = 50 }
    self.engine:emit("GET_CULTURE_DATA", req_culture)
    local progress_factor = (50 - (req_culture.tradition_value or 50)) / 5
    ctx.bonus_research = ctx.bonus_research + progress_factor

    -- Query religious tolerance via event bus
    local req_rel = { tolerance = 50 }
    self.engine:emit("GET_RELIGION_DATA", req_rel)
    local tolerance = req_rel.tolerance or 50
    if tolerance > 70 then
        ctx.bonus_research = ctx.bonus_research + 5
    elseif tolerance < 30 then
        ctx.bonus_research = ctx.bonus_research - 5
    end

    -- Heritage Great Works (via module query — acceptable since Heritage owns this data)
    local heritage = self.engine:get_module("heritage")
    if heritage then
        local req_hw = { research_bonus = 0 }
        self.engine:emit("GET_HERITAGE_MODIFIERS", req_hw)
        ctx.bonus_research = ctx.bonus_research + (req_hw.research_bonus or 0)
    end

    local results = self.logic.tick(game_state.technology, ctx)
    for _, line in ipairs(results) do
        self.engine.log:info(line)
    end
end

--- Manually boost a field (e.g., from a special discovery event).
function Technology:boost_field(field_id, amount)
    local field = self.engine.game_state.technology.fields[field_id]
    if field then
        self.logic.add_progress(field, amount)
    end
end

function Technology:serialize() return self.engine.game_state.technology end
function Technology:deserialize(data) self.engine.game_state.technology = data end

return Technology
