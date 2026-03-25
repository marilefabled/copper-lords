-- dredwork — Strife Integration Test
-- Demonstrates trait-based conflict and its impact on unrest.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1414,
    modules = {
        geography = "dredwork_geography",
        politics  = "dredwork_politics",
        genetics  = "dredwork_genetics",
        strife    = "dredwork_strife"
    }
})

print("=== STRIFE INTERCONNECTION TEST ===")

-- 2. Setup a Biased Region
print("\n[World] Setting up 'The Fair Valley' with a bias toward light skin (PHY_SKN = 20)...")
engine.geography:add_region("valley", "The Fair Valley", "temperate")
engine.strife:set_regional_bias("valley", "PHY_SKN", 20, 2.0) -- Mean 20, high weight

-- 3. Create a person who fits the bias
local person_a = engine.genetics:create_genome({ PHY_SKN = 25 })
local friction_a = engine.strife:get_person_friction(person_a, "valley")
print(string.format("Person A (SKN 25) friction in Valley: %.2f", friction_a))

-- 4. Create a person who differs from the bias
local person_b = engine.genetics:create_genome({ PHY_SKN = 80 })
local friction_b = engine.strife:get_person_friction(person_b, "valley")
print(string.format("Person B (SKN 80) friction in Valley: %.2f", friction_b))

-- 5. Check Politics: Does regional friction fuel unrest?
-- Note: get_regional_friction currently returns a placeholder 10 in Pass 1
local req = { unrest_delta = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("\n[Politics] Regional strife-driven unrest delta: %.2f", req.unrest_delta or 0))

-- 6. Advance generation (Biases soften over time)
print("\n[Action] Advancing generation (Softening biases)...")
engine:advance_generation()

-- Re-check friction for Person B
local friction_b_after = engine.strife:get_person_friction(person_b, "valley")
print(string.format("Person B friction after 1 generation: %.2f", friction_b_after))

print("\n=== TEST COMPLETE ===")
