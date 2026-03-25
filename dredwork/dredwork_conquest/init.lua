-- dredwork Conquest — Module Entry
-- High-level management of occupied territories, vassals, and empires.

local Conquest = {}
Conquest.__index = Conquest

function Conquest.init(engine)
    local self = setmetatable({}, Conquest)
    self.engine = engine

    self.logic = require("dredwork_conquest.logic")
    self.statuses = require("dredwork_conquest.status")

    -- Initialize state
    engine.game_state.empire = {
        territories = {}
    }

    -- Influence Politics Legitimacy
    engine:on("GET_POLITICAL_UNREST_MOD", function(req)
        local total_resistance = 0
        for _, t in ipairs(self.engine.game_state.empire.territories) do
            total_resistance = total_resistance + t.resistance
        end
        if total_resistance > 100 then
            req.unrest_delta = (req.unrest_delta or 0) + (total_resistance / 20)
        end
    end)

    -- Monthly tribute and resistance tick
    engine:on("NEW_MONTH", function(clock)
        self:tick_monthly(self.engine.game_state)
    end)

    -- Generational summary
    engine:on("ADVANCE_GENERATION", function(context)
        -- Generational summary or major integration shifts
    end)

    return self
end

--- Add a region to the empire.
function Conquest:conquer(region_id, faction_id, status_key)
    local record = self.logic.seize_region(region_id, faction_id, status_key)
    table.insert(self.engine.game_state.empire.territories, record)
    return record
end

--- Step empire simulation (Monthly).
function Conquest:tick_monthly(game_state)
    for _, record in ipairs(game_state.empire.territories) do
        local req_mil = { region_id = record.region_id, security_score = 0 }
        self.engine:emit("GET_REGIONAL_SECURITY", req_mil)

        -- Tick resistance (monthly scale)
        local results = self.logic.tick(record, { military_presence = req_mil.security_score })
        for _, line in ipairs(results) do
            self.engine.log:info(line)
        end

        -- Extract monthly tribute (interconnects with Economy)
        local econ = self.engine:get_module("economy")
        if econ then
            local market = econ:get_market(record.region_id)
            local tribute = self.logic.calculate_tribute(record, market.wealth_level or 50)
            econ:change_wealth(tribute / 12)
        end
    end
end

function Conquest:serialize() return self.engine.game_state.empire end
function Conquest:deserialize(data) self.engine.game_state.empire = data end

return Conquest
