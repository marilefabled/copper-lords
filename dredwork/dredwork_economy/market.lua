-- dredwork Economy — Market Logic
-- Local economies, trade routes, resource prices, supply/demand, and market events.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Market = {}

local RESOURCE_TYPES = {
    food   = { base_price = 5,   volatility = 0.2,  decay_rate = 0.05 },
    iron   = { base_price = 25,  volatility = 0.4,  decay_rate = 0.01 },
    luxury = { base_price = 100, volatility = 0.6,  decay_rate = 0.0 },
    timber = { base_price = 15,  volatility = 0.3,  decay_rate = 0.02 },
    grain  = { base_price = 4,   volatility = 0.15, decay_rate = 0.08 },
}

--- Create a new local market state.
function Market.create(biome_type)
    local market = {
        prices = {},
        supply = {},
        demand = {},
        wealth_level = 50,
        tax_rate = 10,
        trade_routes = {},
        trade_balance = 0,
        seasonal_bias = 1.0,
    }

    for id, def in pairs(RESOURCE_TYPES) do
        market.prices[id] = def.base_price
        market.supply[id] = 50
        market.demand[id] = 50
    end

    if biome_type == "tundra" then
        market.prices.food = market.prices.food * 2; market.supply.food = 20; market.demand.food = 70
    elseif biome_type == "urban" then
        market.prices.luxury = market.prices.luxury * 0.7; market.supply.luxury = 80; market.supply.food = 25; market.demand.food = 80
    elseif biome_type == "tropical" then
        market.supply.food = 70; market.supply.timber = 70
    elseif biome_type == "desert" then
        market.supply.food = 15; market.supply.iron = 60; market.demand.food = 75
    elseif biome_type == "coastal" then
        market.supply.food = 55; market.trade_balance = 5
    elseif biome_type == "mountain" then
        market.supply.iron = 75; market.supply.food = 15; market.demand.food = 65
    elseif biome_type == "steppe" then
        market.supply.grain = 60
    elseif biome_type == "swamp" then
        market.supply.timber = 50
    end

    return market
end

--- Simulate market fluctuations for one tick.
function Market.tick(market, events)
    local lines = {}
    local drift_scale = events and events.drift_scale or 1.0
    local seasonal = market.seasonal_bias or 1.0

    for id, def in pairs(RESOURCE_TYPES) do
        local supply = market.supply[id] or 50
        local demand = market.demand[id] or 50

        local imbalance = (demand - supply) / 50
        local volatility_roll = (RNG.random() - 0.5) * def.volatility
        local price_change = (imbalance * 0.15 + volatility_roll) * drift_scale

        if id == "food" or id == "grain" then
            price_change = price_change + (seasonal - 1.0) * 0.3 * drift_scale
        end

        market.prices[id] = Math.clamp(market.prices[id] * (1 + price_change), 1, 500)

        local recovery = (50 - supply) * 0.05 * drift_scale
        market.supply[id] = Math.clamp(supply + recovery, 0, 100)

        if def.decay_rate > 0 then
            market.supply[id] = Math.clamp(market.supply[id] - def.decay_rate * drift_scale, 0, 100)
        end

        market.demand[id] = Math.clamp((market.demand[id] or 50) + (50 - (market.demand[id] or 50)) * 0.03 * drift_scale, 0, 100)
    end

    market.trade_balance = 0
    for _, route in ipairs(market.trade_routes) do
        market.trade_balance = market.trade_balance + (route.volume or 10) * 0.5
    end

    local avg_supply, count = 0, 0
    for _, v in pairs(market.supply) do avg_supply = avg_supply + v; count = count + 1 end
    avg_supply = count > 0 and avg_supply / count or 50
    market.wealth_level = Math.clamp(market.wealth_level + (avg_supply - 50) * 0.02 * drift_scale + market.trade_balance * 0.01, 0, 100)

    return lines
end

function Market.add_trade_route(market, target_region_id, goods, volume)
    table.insert(market.trade_routes, { target_region = target_region_id, goods = goods or "mixed", volume = Math.clamp(volume or 10, 1, 100) })
end

function Market.get_effective_price(market, good_id)
    local base = market.prices[good_id] or 10
    if (good_id == "food" or good_id == "grain") then return base * (market.seasonal_bias or 1.0) end
    return base
end

function Market.apply_shock(market, good_id, supply_delta, demand_delta)
    if good_id and market.supply[good_id] then market.supply[good_id] = Math.clamp(market.supply[good_id] + (supply_delta or 0), 0, 100) end
    if good_id and market.demand[good_id] then market.demand[good_id] = Math.clamp(market.demand[good_id] + (demand_delta or 0), 0, 100) end
end

return Market
