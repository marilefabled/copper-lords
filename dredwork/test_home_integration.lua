-- dredwork — Home Integration Test
-- Demonstrates home establishment, upkeep decay, and environmental modifiers.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 101,
    modules = {
        home = "dredwork_home"
    }
})

print("=== HOME SIMULATION TEST ===")

-- 2. Establish a Castle
print("\n[Action] Establishing a Stone Keep...")
local castle = engine.home:establish("castle")
print("Home: " .. castle.label)
print("Initial Condition: " .. castle.attributes.condition)
print("Base Upkeep: " .. castle.upkeep_cost)

-- 3. Simulate generation without enough resources (Upkeep fails)
engine.game_state.resources = { gold = 10 } -- Less than 50 upkeep

print("\n[Action] Advancing generation (Low Resources)...")
engine:advance_generation()

print("Condition after decay: " .. castle.attributes.condition)
print("Comfort after decay: " .. castle.attributes.comfort)

-- 4. Check environmental modifier
local mod = engine.home:get_modifiers()
print(string.format("\n[Environment] Global stress modifier: %.2f", mod))

-- 5. Restore resources and fix upkeep
engine.game_state.resources.gold = 100
print("\n[Action] Advancing generation (Plenty of Gold)...")
engine:advance_generation()
print("Condition after maintenance: " .. castle.attributes.condition)

print("\n=== TEST COMPLETE ===")
