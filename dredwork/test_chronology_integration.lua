-- dredwork — Chronology Integration Test
-- Demonstrates the master clock driving multiple temporal scales.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1616,
    modules = {
        chronology = "dredwork_chronology",
        economy    = "dredwork_economy",
        home       = "dredwork_home"
    }
})

print("=== CHRONOLOGY INTERCONNECTION TEST ===")

-- 2. Initial Time
print("\n[Clock] Current Time: " .. engine.chronology:get_formatted_time())

-- 3. Advance by 15 Days
print("\n[Action] Advancing by 15 days...")
engine:advance_days(15)
print("[Clock] Time: " .. engine.chronology:get_formatted_time())

-- 4. Advance into the next month
print("\n[Action] Advancing another 20 days...")
engine:advance_days(20)
print("[Clock] Time: " .. engine.chronology:get_formatted_time())

-- 5. Full Year Simulation
print("\n[Action] Advancing by 360 days (1 full year)...")
engine:advance_days(360)
print("[Clock] Time: " .. engine.chronology:get_formatted_time())

-- 6. Check Year 25 (Generation Advancement)
print("\n[Action] Simulating 24 more years...")
engine:advance_days(360 * 24)
print("[Clock] Time: " .. engine.chronology:get_formatted_time())
print("Current Generation: " .. engine.game_state.clock.generation)

print("\n=== TEST COMPLETE ===")
