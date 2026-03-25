-- dredwork — Politics Integration Test
-- Demonstrates how enacting laws affects the economy.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 404,
    modules = {
        politics = "dredwork_politics",
        economy  = "dredwork_economy"
    }
})

print("=== POLITICS INTERCONNECTION TEST ===")

-- 2. Check baseline economy
print("\n[Economy] Gaining 100 gold (Baseline)...")
engine.economy:change_wealth(100)
print("Gold: " .. engine.game_state.resources.gold)

-- 3. Enact "Heavy Tithes" Law
print("\n[Politics] Enacting 'Heavy Tithes' (+50% revenue modifier)...")
engine.politics:enact_law("high_taxation")

-- 4. Check economy with political modifier
print("\n[Economy] Gaining another 100 gold (with Political Law)...")
engine.economy:change_wealth(100) -- Should be 100 * 1.5 = 150
print("Total Gold: " .. engine.game_state.resources.gold)

-- 5. Switch System to Meritocracy
print("\n[Politics] Shifting to Meritocracy...")
engine.politics:set_system("meritocracy")
print("New System: " .. engine.politics.systems[engine.game_state.politics.active_system_id].label)

print("\n=== TEST COMPLETE ===")
