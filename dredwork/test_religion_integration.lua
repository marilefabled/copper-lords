-- dredwork — Religion Integration Test
-- Demonstrates how low-tolerance faiths increase political unrest in diverse worlds.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 707,
    modules = {
        politics = "dredwork_politics",
        religion = "dredwork_religion"
    }
})

print("=== RELIGION INTERCONNECTION TEST ===")

-- 2. Setup a Diverse World
print("\n[World] Setting religious diversity to 60%...")
engine.game_state.religion.diversity = 60

-- 3. Adopt a Low-Tolerance Faith (Theocracy)
print("[Religion] Adopting 'High Theocracy' (Tolerance = 20)...")
engine.religion:adopt_faith("theocracy")

-- 4. Check Political Unrest
local req = { unrest_mod = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("\n[Politics] Religion-driven unrest delta: %.2f", req.unrest_delta or 0))

-- 5. Adopt a High-Tolerance Faith (Cult of Reason)
print("\n[Religion] Adopting 'Cult of Reason' (Tolerance = 70)...")
engine.religion:adopt_faith("cult_of_reason")

req = { unrest_mod = 0 }
engine:emit("GET_POLITICAL_UNREST_MOD", req)
print(string.format("[Politics] Religion-driven unrest delta: %.2f", req.unrest_delta or 0))

print("\n=== TEST COMPLETE ===")
