-- dredwork — Crime Integration Test
-- Demonstrates underworld operations, corruption, and interconnection.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 808,
    modules = {
        military  = "dredwork_military",
        rumor     = "dredwork_rumor",
        politics  = "dredwork_politics",
        crime     = "dredwork_crime"
    }
})

print("=== CRIME INTERCONNECTION TEST ===")

-- 2. Setup Underworld
print("\n[Underworld] Spawning a Thieves Guild in 'Capital'...")
local guild = engine.crime:spawn_syndicate("thieves_guild", "capital")
print("Org: " .. guild.label .. " | Subtlety: " .. guild.attributes.subtlety)

-- 3. Execute Operation: Smuggling
print("\n[Action] Executing 'Smuggling' operation...")
local res = engine.crime:execute_op(1, "smuggling")
print("Success: " .. (res.success and "YES" or "NO"))
print("Reward: " .. (res.reward or 0))
print("Heat Gained: " .. res.heat_gain)

-- 4. Execute Operation: Corruption (Requires wealth and influence)
guild.wealth = 100
guild.attributes.influence = 70
print("\n[Action] Executing 'Buying Influence' operation...")
local res2 = engine.crime:execute_op(1, "political_corruption")
print("Success: " .. (res2.success and "YES" or "NO"))
print("Global Corruption: " .. engine.game_state.underworld.global_corruption)

-- 5. Check Politics: Does corruption affect unrest?
local req = { unrest_delta = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("\n[Politics] Corruption-driven unrest delta: %.2f", req.unrest_delta or 0))

-- 6. Check Rumors
print("\n[Rumor] Checking for underworld news...")
local h = engine.rumor:get_reputation(engine.game_state, guild.label)
print("Underworld Heat/Rep: " .. (h and h.score or 0))

print("\n=== TEST COMPLETE ===")
