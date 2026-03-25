-- dredwork — Animals Integration Test
-- Demonstrates pets boosting comfort and pests damaging home condition.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 111,
    modules = {
        geography = "dredwork_geography",
        home      = "dredwork_home",
        rumor     = "dredwork_rumor",
        animals   = "dredwork_animals"
    }
})

print("=== ANIMALS INTERCONNECTION TEST ===")

-- 2. Setup World
engine.geography:add_region("capital", "The Capital", "urban")
engine.home:establish("manor") -- 70 comfort, 100 condition
engine.game_state.resources = { gold = 100 } -- Maintain the manor

-- 3. Adopt a Pet
print("\n[Action] Adopting a Loyal Hound named 'Buster'...")
engine.animals:adopt_pet("hound", "Buster")

-- 4. Seed Pests
print("[Action] Infesting region with Rats...")
engine.animals:seed_region("capital", "rats", 60) -- High density

-- 5. Advance Generation
print("\n[Action] Advancing generation...")
engine:advance_generation()

print("\n[Home] Attributes after animals impact:")
local home = engine.game_state.home
print("Comfort: " .. home.attributes.comfort .. " (was 70, +5 from Buster)")
print("Condition: " .. home.attributes.condition .. " (was 100, -6 from Rats, +2 from upkeep)")

-- 6. Check Rumors (Wildlife danger)
print("\n[Action] Seeding dangerous Wolves...")
engine.animals:seed_region("capital", "wolves", 50)
engine:advance_generation()

print("\n[Rumor] Checking for wildlife alerts...")
local h = engine.rumor:get_reputation(engine.game_state, "capital")
-- Search for wildlife rumors
local rumors = engine.game_state.rumor_network.rumors
for _, r in pairs(rumors) do
    if r.origin_type == "wildlife" then
        print("Alert: " .. r.current_text)
    end
end

print("\n=== TEST COMPLETE ===")
