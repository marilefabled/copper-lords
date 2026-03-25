-- dredwork Politics — Module Entry
-- Foundation: Political Systems, Active Laws, and the Master Legitimacy System.

local Politics = {}
Politics.__index = Politics

function Politics.init(engine)
    local self = setmetatable({}, Politics)
    self.engine = engine

    self.systems = require("dredwork_politics.systems")
    self.laws_lib = require("dredwork_politics.laws")

    -- Initialize global politics state
    engine.game_state.politics = {
        active_system_id = "monarchy",
        active_laws = {},
        order = 50,
        progress = 50,
        unrest = 0,
        legitimacy = 70 -- Master variable: 0 to 100
    }

    -- INTERCONNECTION: Economy queries for tax/trade modifiers
    engine:on("GET_ECONOMIC_MODIFIER", function(req)
        local effects = self:get_active_effects()
        local legit_mod = self.engine.game_state.politics.legitimacy / 100
        req.gold_mod = (req.gold_mod or 1.0) * (effects.gold_mod or 1.0) * legit_mod
    end)

    -- INTERCONNECTION: Expose unrest and legitimacy to other modules via event bus
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        req.unrest = self.engine.game_state.politics.unrest
        req.legitimacy = self.engine.game_state.politics.legitimacy
    end)

    -- Expose political system type via event bus
    engine:on("GET_POLITICAL_SYSTEM", function(req)
        req.system_id = self.engine.game_state.politics.active_system_id
        req.active_laws = self.engine.game_state.politics.active_laws
    end)

    -- INTERCONNECTION: Rumor legitimacy impact (decoupled from Rumor module)
    engine:on("RUMOR_LEGITIMACY_IMPACT", function(ctx)
        local stats = self.engine.game_state.politics
        stats.legitimacy = math.max(0, math.min(100, stats.legitimacy + (ctx.delta or 0)))
    end)

    -- Bread and Circuses (Sports)
    engine:on("MATCH_COMPLETED", function(ctx)
        local stats = self.engine.game_state.politics
        stats.legitimacy = math.min(100, stats.legitimacy + 2)
        stats.unrest = math.max(0, stats.unrest - 5)
        self.engine.log:info("Public games have distracted the populace. Legitimacy increased.")
    end)

    -- Daily drift
    engine:on("NEW_DAY", function(clock)
        local stats = self.engine.game_state.politics
        local target_unrest = 100 - stats.legitimacy
        stats.unrest = stats.unrest + (target_unrest - stats.unrest) * 0.005
    end)

    -- Monthly tick
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state)
    end)

    -- Generational tick
    engine:on("ADVANCE_GENERATION", function(context)
        self:tick(context.game_state)
    end)

    return self
end

--- Step politics (process unrest and legitimacy monthly).
function Politics:tick_monthly(game_state)
    local stats = game_state.politics

    -- Economic Scarcity (Checked monthly)
    local econ = self.engine:get_module("economy")
    local req_geo = { current_region_id = nil }
    self.engine:emit("GET_GEOGRAPHY_DATA", req_geo)
    if econ and req_geo.current_region_id then
        local current_region = req_geo.current_region_id
        if current_region then
            local market = econ:get_market(current_region)
            if market and market.prices.food > 15 then
                local scarcity_unrest = math.floor((market.prices.food - 15) * 0.5)
                stats.unrest = stats.unrest + scarcity_unrest
                stats.legitimacy = math.max(0, stats.legitimacy - 0.2)
            end
        end
    end

    -- Calculate Legitimacy Shift (Monthly)
    local legit_delta = 0

    -- Heritage (Prestige from Monuments)
    local heritage_req = { prestige = 0 }
    self.engine:emit("GET_HERITAGE_MODIFIERS", heritage_req)
    legit_delta = legit_delta + (heritage_req.prestige or 0) / 100

    -- Military power provides legitimacy (via event bus)
    local req_mil = { total_power = 0 }
    self.engine:emit("GET_MILITARY_DATA", req_mil)
    if req_mil.total_power > 200 then
        legit_delta = legit_delta + 0.1
    end

    -- Crime/Corruption drains legitimacy (via event bus)
    local req_crime = { global_corruption = 0 }
    self.engine:emit("GET_CORRUPTION_DATA", req_crime)
    if req_crime.global_corruption > 0 then
        legit_delta = legit_delta - (req_crime.global_corruption / 100)
    end

    stats.legitimacy = math.max(0, math.min(100, stats.legitimacy + legit_delta))
end

--- Step politics (legacy generational trigger).
function Politics:tick(game_state)
    -- Generational summary or major shifts
end

--- Set the primary political system.
function Politics:set_system(system_id)
    if self.systems[system_id] then
        self.engine.game_state.politics.active_system_id = system_id
        return true
    end
    return false
end

--- Add a new law to the active roster.
function Politics:enact_law(law_id)
    if self.laws_lib[law_id] then
        table.insert(self.engine.game_state.politics.active_laws, law_id)
        return true
    end
    return false
end

--- Get all active laws and their current effects.
function Politics:get_active_effects()
    local total_effects = { gold_mod = 1.0, unrest_mod = 1.0 }
    for _, law_id in ipairs(self.engine.game_state.politics.active_laws) do
        local law = self.laws_lib[law_id]
        if law and law.effects then
            for effect_k, effect_v in pairs(law.effects) do
                total_effects[effect_k] = (total_effects[effect_k] or 0) + effect_v
            end
        end
    end
    return total_effects
end

--- Enact a law or take an action.
function Politics:run_propaganda(subject, message, truth_score)
    local econ = self.engine:get_module("economy")
    local rumor = self.engine:get_module("rumor")

    if econ and rumor and econ:change_wealth(-50) then -- Costs 50 gold
        self.engine.log:info("Launching state propaganda: %s", message)

        rumor:inject(self.engine.game_state, {
            origin_type = "politics",
            subject = subject,
            text = message,
            heat = 90,
            truth_score = truth_score or 50,
            tags = { prestige = true, propaganda = true }
        })

        self.engine.game_state.politics.legitimacy = math.min(100, self.engine.game_state.politics.legitimacy + 5)
        return true
    end
    return false
end

function Politics:serialize() return self.engine.game_state.politics end
function Politics:deserialize(data) self.engine.game_state.politics = data end

return Politics
