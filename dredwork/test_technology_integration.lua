-- dredwork — Technology Integration Test
-- Demonstrates research breakthroughs and their impact on other systems.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 909,
    modules = {
        economy    = "dredwork_economy",
        military   = "dredwork_military",
        technology = "dredwork_technology"
    }
})

print("=== TECHNOLOGY INTERCONNECTION TEST ===")

-- 2. Baseline Check
print("\n[Action] Baseline gold gain (100 gold)...")
engine.economy:change_wealth(100)
print("Resulting Gold: " .. engine.game_state.resources.gold)

-- 3. Simulate several generations to trigger a breakthrough
print("\n[Action] Advancing 10 generations to simulate research...")
-- We'll manually boost it to force a breakthrough for the test
engine.technology:boost_field("industry", 150) -- This should push it to Level 2
engine.technology:boost_field("warfare", 150)  -- This should push it to Level 2

print("Industry Multiplier: " .. engine.game_state.technology.fields.industry.multiplier)

-- 4. Test Impact on Economy
print("\n[Economy] Gaining another 100 gold (with Industry Level 2)...")
engine.economy:change_wealth(100) -- Should be 100 * 1.1 = 110
print("Total Gold: " .. engine.game_state.resources.gold)

-- 5. Test Impact on Military
print("\n[Military] Recruiting a Legion...")
local unit = engine.military:recruit("legion", "commander_01")
engine:advance_generation() -- This will tick military and apply the Warfare tech multiplier
print("Total Military Power (with Warfare Level 2): " .. engine.game_state.military.total_power)

print("\n=== TEST COMPLETE ===")
