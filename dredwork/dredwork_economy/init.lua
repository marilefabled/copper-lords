-- dredwork Economy — Module Entry
-- Handles global and local wealth, trade, and resource flow.

local Economy = {}
Economy.__index = Economy

function Economy.init(engine)
    local self = setmetatable({}, Economy)
    self.engine = engine

    self.market_logic = require("dredwork_economy.market")

    -- Global state
    engine.game_state.resources = engine.game_state.resources or {
        gold = 100,
        assets = {} -- Any stored physical items/stocks
    }

    -- Local Markets (linked to Geography regions)
    engine.game_state.markets = {}

    -- Expose economic data via event bus (queried by Heritage, Military, Animals, Home)
    engine:on("GET_ECONOMIC_DATA", function(req)
        req.gold = self.engine.game_state.resources.gold
        req.assets = self.engine.game_state.resources.assets
    end)

    -- Daily market drift with seasonal bias stored on the market
    engine:on("NEW_DAY", function(clock)
        local seasonal_bias = 1.0
        if clock.month == 6 then seasonal_bias = 0.5            -- Gold Harvest (Glut)
        elseif clock.month == 2 or clock.month == 12 then seasonal_bias = 2.0 -- Deep Frost / Final Cold (Scarcity)
        end

        for _, market in pairs(self.engine.game_state.markets) do
            market.seasonal_bias = seasonal_bias
            self.market_logic.tick(market, { drift_scale = 1/30 })
        end
    end)

    -- Generation advancement (Legacy support)
    engine:on("ADVANCE_GENERATION", function(context)
        -- No-op or summary logic
    end)

    return self
end

--- Step the economy.
function Economy:tick(game_state)
    -- Query sacred pest status via event bus (decoupled from Religion)
    local sacred_pest = false
    local req_rel = { sacred_species = nil }
    self.engine:emit("GET_RELIGION_DATA", req_rel)
    if req_rel.sacred_species == "rats" or req_rel.sacred_species == "locusts" then
        sacred_pest = true
    end

    -- Update all local markets
    for region_id, market in pairs(game_state.markets) do
        -- Factor in global rumors
        local rumor_mod = self:_get_economic_rumor_impact(region_id)

        -- Apply sacred pest penalty to supply
        if sacred_pest then
            market.supply.food = math.max(0, market.supply.food - 15)
            self.engine.log:info("Sacred pests are devouring food stores in %s!", region_id)
        end

        self.market_logic.tick(market, { rumor_mod = rumor_mod })
    end
end

function Economy:_get_economic_rumor_impact(region_id)
    local rumor_mod = 1.0
    local rumor_module = self.engine:get_module("rumor")
    if rumor_module then
        -- Find rumors with economic tags like "wealth", "scandal", "trade"
        -- This is a placeholder for a more complex query
    end
    return rumor_mod
end

--- Calculate tax revenue from a faction.
function Economy:get_faction_revenue(faction)
    local power = faction.power or 50
    return math.floor(power * 0.5)
end

--- Get a market for a specific region.
function Economy:get_market(region_id)
    if not self.engine.game_state.markets[region_id] then
        -- Tie-in: Get biome from geography if possible
        -- Query geography for biome via event bus
        local req_geo = { region_id = region_id, biome = "temperate" }
        self.engine:emit("GET_GEOGRAPHY_DATA", req_geo)
        local biome = req_geo.biome or "temperate"
        self.engine.game_state.markets[region_id] = self.market_logic.create(biome)
    end
    return self.engine.game_state.markets[region_id]
end

--- Change player/lineage wealth.
function Economy:change_wealth(delta)
    if delta > 0 then
        -- Political modifiers (e.g., Heavy Tithes)
        local req_pol = { gold_mod = 1.0 }
        self.engine:emit("GET_ECONOMIC_MODIFIER", req_pol)
        delta = delta * (req_pol.gold_mod or 1.0)

        -- Technology (Industry)
        local req_tech = { field_id = "industry", multiplier = 1.0 }
        self.engine:emit("GET_TECH_MULTIPLIER", req_tech)
        delta = delta * (req_tech.multiplier or 1.0)

        -- Corruption via event bus (decoupled from Crime module)
        local req_crime = { global_corruption = 0 }
        self.engine:emit("GET_CORRUPTION_DATA", req_crime)
        local corruption = req_crime.global_corruption
        if corruption > 10 then
            local theft_mod = 1.0 - (corruption / 200)
            delta = delta * math.max(0.5, theft_mod)
        end
    end

    self.engine.game_state.resources.gold = self.engine.game_state.resources.gold + delta
    return self.engine.game_state.resources.gold
end

function Economy:serialize()
    return {
        resources = self.engine.game_state.resources,
        markets = self.engine.game_state.markets
    }
end

function Economy:deserialize(data)
    self.engine.game_state.resources = data.resources
    self.engine.game_state.markets = data.markets
end

return Economy
