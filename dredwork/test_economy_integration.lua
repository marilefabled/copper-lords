-- dredwork — Economy Integration Test
-- Demonstrates biome-aware markets and price fluctuations.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 303,
    modules = {
        geography = "dredwork_geography",
        economy   = "dredwork_economy"
    }
})

print("=== ECONOMY INTERCONNECTION TEST ===")

-- 2. Setup Map with different biomes
print("\n[Map] Forging diverse regions...")
engine.geography:add_region("tundra", "The Frozen North", "tundra")
engine.geography:add_region("urban", "The Iron Spire", "urban")

-- 3. Check Tundra Market (Food should be expensive)
print("\n[Market] Analyzing 'The Frozen North' (Tundra):")
local tundra_market = engine.economy:get_market("tundra")
print("Food Price: " .. string.format("%.2f", tundra_market.prices.food))
print("Food Supply: " .. tundra_market.supply.food)

-- 4. Check Urban Market (Luxury should be cheaper)
print("\n[Market] Analyzing 'The Iron Spire' (Urban):")
local urban_market = engine.economy:get_market("urban")
print("Luxury Price: " .. string.format("%.2f", urban_market.prices.luxury))
print("Luxury Supply: " .. urban_market.supply.luxury)

-- 5. Tick Economy
print("\n[Action] Advancing generation (Simulating Market Drift)...")
engine:advance_generation()

print("\n[Market] Tundra Prices after one generation:")
print("Food Price: " .. string.format("%.2f", tundra_market.prices.food))
print("Iron Price: " .. string.format("%.2f", tundra_market.prices.iron))

print("\n=== TEST COMPLETE ===")
