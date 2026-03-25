-- dredwork — Culture Integration Test
-- Demonstrates how cultural values bias character personality generation.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 606,
    modules = {
        culture  = "dredwork_culture",
        genetics = "dredwork_genetics"
    }
})

print("=== CULTURE INTERCONNECTION TEST ===")

-- 2. Establish a Pacifist Culture
print("\n[Culture] Setting values to PACIFIST (Martial = 10)...")
engine.culture:get_axes().CUL_MAR = 10

-- 3. Generate a character in Pacifist culture
local genome = engine.genetics:create_genome()
local p1 = engine.genetics.personality.derive(genome, engine.genetics.personality.new(), engine.genetics.personality.new(), engine)
print("Character 1 (Pacifist society) Boldness: " .. p1:get_axis("PER_BLD"))

-- 4. Shift to Warrior Culture
print("\n[Culture] Shifting to WARRIOR culture (Martial = 90)...")
engine.culture:get_axes().CUL_MAR = 90

-- 5. Generate a character in Warrior culture
local p2 = engine.genetics.personality.derive(genome, engine.genetics.personality.new(), engine.genetics.personality.new(), engine)
print("Character 2 (Warrior society) Boldness: " .. p2:get_axis("PER_BLD"))

print("\n[Action] Advancing generation (Simulating Cultural Drift)...")
engine:advance_generation()
print("Cultural Martial value after drift: " .. string.format("%.2f", engine.culture:get_axes().CUL_MAR))

print("\n=== TEST COMPLETE ===")
