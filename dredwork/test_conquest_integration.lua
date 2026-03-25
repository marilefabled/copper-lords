-- dredwork — Conquest Integration Test
-- Demonstrates empire building, tribute extraction, and political consequences.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1313,
    modules = {
        geography = "dredwork_geography",
        economy   = "dredwork_economy",
        politics  = "dredwork_politics",
        military  = "dredwork_military",
        conquest  = "dredwork_conquest"
    }
})

print("=== CONQUEST INTERCONNECTION TEST ===")

-- 2. Setup World
engine.geography:add_region("west", "The Western Plains", "temperate")
engine.military:recruit("legion", "general_01")
engine.military:deploy(1, "west")

-- 3. Conquer the region
print("\n[Action] Conquering 'The Western Plains' (Occupation status)...")
engine.conquest:conquer("west", "empire_01", "occupation")

-- 4. Initial check
local treasury = engine.game_state.resources.gold
print("Initial Treasury: " .. treasury)

-- 5. Advance Generation (Tribute and Politics)
print("\n[Action] Advancing generation...")
engine:advance_generation()

print("\n[Empire] Treasury after tribute: " .. engine.game_state.resources.gold)
local territory = engine.game_state.empire.territories[1]
print("Region Resistance: " .. string.format("%.2f", territory.resistance))

-- 6. Check Political Unrest (High resistance fuels it)
local req = { unrest_delta = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("\n[Politics] Imperial-driven unrest delta: %.2f", req.unrest_delta or 0))

print("\n=== TEST COMPLETE ===")
