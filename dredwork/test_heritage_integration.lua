-- dredwork — Heritage Integration Test
-- Demonstrates legends and great works influencing dialogue and world state.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1212,
    modules = {
        culture  = "dredwork_culture",
        heritage = "dredwork_heritage",
        dialogue = "dredwork_dialogue"
    }
})

print("=== HERITAGE INTERCONNECTION TEST ===")

-- 2. Create a Legend
print("\n[Action] Recording the legend of 'Aris the Brave'...")
engine.heritage:record_legend({ id = "p1", name = "Aris the Brave" }, "slaying the mountain wurm", 100)

-- 3. Build a Great Work
print("[Action] Building the 'Spire of Ancestors' (Monument)...")
engine.heritage:build_work("monument", "Spire of Ancestors", "House Thorne")

-- 4. Test Dialogue Reference
local speaker = {
    name = "Vesper the Sly",
    personality = { axes = { PER_OBS = 85, PER_BLD = 40, PER_LOY = 30 } }
}

print("\n[Dialogue] Vesper greets you:")
print(">> " .. engine.dialogue:greet(speaker))

-- 5. Test Cultural Bias
print("\n[Culture] Current Tradition value: " .. engine.culture:get_axes().CUL_TRD)
print("[Action] Advancing generation...")
engine:advance_generation()

-- The monument should bias the culture toward tradition
print("Tradition after monument influence: " .. string.format("%.2f", engine.culture:get_axes().CUL_TRD))

-- 6. Test Decay
engine.game_state.resources = { gold = 0 } -- No maintenance
print("\n[Action] Advancing another generation (No upkeep)...")
engine:advance_generation()
print("Monument Condition: " .. engine.game_state.history.great_works[1].condition)

print("\n=== TEST COMPLETE ===")
