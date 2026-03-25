-- dredwork — Peril Integration Test
-- Demonstrates how diseases and disasters impact economy, politics, and homes.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1717,
    modules = {
        chronology = "dredwork_chronology",
        geography  = "dredwork_geography",
        economy    = "dredwork_economy",
        politics   = "dredwork_politics",
        home       = "dredwork_home",
        rumor      = "dredwork_rumor",
        peril      = "dredwork_peril"
    }
})

print("=== PERIL INTERCONNECTION TEST ===")

-- 2. Setup World
engine.geography:add_region("city", "The Great City", "urban")
engine.home:establish("manor")
engine.game_state.resources = { gold = 500 }

-- 3. Trigger a Plague
print("\n[Action] Triggering a 'Great Plague' in The Great City...")
engine.peril:trigger("plague", "city")

-- 4. Advance time and observe impacts
print("\n[Action] Advancing 30 days (1 month)...")
engine:advance_days(30)

print("\n[Economy] Gold after 1 month of plague: " .. engine.game_state.resources.gold)
print("[Politics] Unrest level: " .. string.format("%.2f", engine.game_state.politics.unrest))

-- 5. Trigger a Flood (Disaster)
print("\n[Action] A 'Great Flood' occurs!")
engine.peril:trigger("flood", "city")

print("\n[Action] Advancing another 30 days...")
engine:advance_days(30)

print("\n[Home] Manor condition: " .. engine.game_state.home.attributes.condition)
print("[Economy] Gold after flood damage: " .. engine.game_state.resources.gold)

print("\n=== TEST COMPLETE ===")
