-- dredwork — Punishment Integration Test
-- Demonstrates the Crime-to-Justice pipeline and its political fallout.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 1515,
    modules = {
        politics   = "dredwork_politics",
        crime      = "dredwork_crime",
        punishment = "dredwork_punishment"
    }
})

print("=== PUNISHMENT INTERCONNECTION TEST ===")

-- 2. Setup Crime Org
print("\n[Underworld] Spawning a Street Gang...")
local gang = engine.crime:spawn_syndicate("street_gang", "capital")

-- 3. Force a Failure (High Security)
print("[Action] Attempting a high-risk heist...")
-- We'll manually trigger a failure by checking the logic flow
local res = engine.crime:execute_op(1, "extortion")
print("Operation Success: " .. (res.success and "YES" or "NO"))

-- 4. Check Justice System
print("\n[Justice] Checking the prison population...")
local prisoners = engine.game_state.justice.prisoners
print("Total Prisoners: " .. #prisoners)
if #prisoners > 0 then
    print("Newest Prisoner ID: " .. prisoners[1].person_id)
end

-- 5. Advance Generation (Simulate systemic terror)
print("\n[Action] Advancing generation...")
engine:advance_generation()

print("\n[Justice] Systemic Terror Score: " .. engine.game_state.justice.terror_score)

-- 6. Check Politics (Does terror suppress unrest but drain legitimacy?)
local req = { unrest_delta = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("\n[Politics] Justice-driven unrest delta: %.2f", req.unrest_delta or 0))
print("Current Legitimacy: " .. engine.game_state.politics.legitimacy)

print("\n=== TEST COMPLETE ===")
