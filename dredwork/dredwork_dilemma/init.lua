-- dredwork Dilemma — Module Entry
-- The trade-off engine. Manages pressures and forced choices.

local Dilemma = {}
Dilemma.__index = Dilemma

--- Initialize the module with the engine.
---@param engine table The central dredwork engine.
function Dilemma.init(engine)
    local self = setmetatable({}, Dilemma)
    self.engine = engine

    -- Sub-components
    self.logic     = require("dredwork_dilemma.dilemma")
    self.collector_mod = require("dredwork_dilemma.collector")
    self.pressure  = require("dredwork_dilemma.pressure")

    -- Instance of the collector
    self.collector = self.collector_mod.new()

    -- Register default sources if they exist in game_state
    self.collector_mod.register(self.collector, "rumor", self.collector_mod.source_rumor)
    self.collector_mod.register(self.collector, "body", self.collector_mod.source_body)
    self.collector_mod.register(self.collector, "claim", self.collector_mod.source_claim)

    -- Respond to dilemma generation requests from other modules
    engine:on("REQUEST_DILEMMA", function(req)
        local dilemma = self:generate(self.engine.game_state)
        if dilemma then
            req.dilemma = dilemma
        end
    end)

    -- Generate dilemmas from specific crisis events
    engine:on("PERIL_STRIKE", function(ctx)
        self.collector_mod.register(self.collector, "peril_" .. (ctx.type_key or "crisis"), function(game_state)
            return { source = "peril", severity = ctx.severity or 50, text = ctx.text or "A crisis demands your attention." }
        end)
    end)

    engine:on("REBELLION", function(ctx)
        self.collector_mod.register(self.collector, "rebellion_" .. (ctx.region_id or "global"), function(game_state)
            return { source = "rebellion", severity = 80, text = "The people rise against your rule." }
        end)
    end)

    -- Monthly: try to surface a dilemma as a happening
    engine:on("NEW_MONTH", function(clock)
        local dilemma = self:generate(self.engine.game_state)
        if dilemma then
            -- Format as a happening definition
            local happening_def = {
                id = "dilemma_" .. (dilemma.id or "generic"),
                title = dilemma.title or "A Difficult Choice",
                category = "dilemma",
                text = dilemma.text or "Pressures converge. A decision must be made.",
                options = dilemma.options or {},
            }
            engine:emit("HAPPENING_INJECT", { happening_def = happening_def })
        end
    end)

    return self
end

--- Register a custom pressure source.
function Dilemma:register_source(name, source_fn)
    self.collector_mod.register(self.collector, name, source_fn)
end

--- Generate a dilemma from current pressures.
function Dilemma:generate(game_state)
    local pressures = self.collector_mod.gather(self.collector, game_state)
    if #pressures < 2 then return nil end
    return self.logic.generate(pressures)
end

--- Standard module serialization.
function Dilemma:serialize()
    return {}
end

--- Standard module deserialization.
function Dilemma:deserialize(data)
end

return Dilemma
