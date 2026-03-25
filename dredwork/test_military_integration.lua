-- dredwork — Military Integration Test
-- Demonstrates force recruitment, deployment, and attrition.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 505,
    modules = {
        geography = "dredwork_geography",
        military  = "dredwork_military"
    }
})

print("=== MILITARY INTERCONNECTION TEST ===")

-- 2. Setup Map
engine.geography:add_region("front", "The War Front", "temperate")

-- 3. Recruit and Deploy
print("\n[Action] Recruiting a Heavy Legion...")
local unit = engine.military:recruit("legion", "hero_01")
print("Unit: " .. unit.label .. " | Upkeep: " .. unit.upkeep_cost)

print("[Action] Deploying to 'The War Front'...")
engine.military:deploy(1, "front")

-- 4. Check Regional Security
local req = { region_id = "front", security_score = 0 }
engine:emit("GET_REGIONAL_SECURITY", req)
print("Regional Security Score: " .. req.security_score)

-- 5. Tick with failed payroll
engine.game_state.resources = { gold = 5 } -- Legion needs 60
print("\n[Action] Advancing generation (Empty Treasury)...")
engine:advance_generation()

print("Legion Morale after failed pay: " .. unit.morale)
print("Legion Strength after desertions: " .. unit.strength)

print("\n=== TEST COMPLETE ===")
