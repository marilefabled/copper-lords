-- dredwork — Dialogue Integration Test
-- Demonstrates speaker personality + rumor interconnection.

local Engine = require("dredwork_engine")

-- 1. Setup Engine with necessary modules
local engine = Engine.new({
    seed = 777,
    modules = {
        genetics = "dredwork_genetics",
        rumor    = "dredwork_rumor",
        dialogue = "dredwork_dialogue"
    }
})

print("=== DIALOGUE INTERCONNECTION TEST ===")

-- 2. Create a "Cunning" Speaker
local speaker = {
    name = "Vesper the Sly",
    personality = {
        axes = {
            PER_OBS = 85, -- High Cunning/Obsession
            PER_BLD = 40,
            PER_LOY = 30
        }
    }
}

-- 3. Create a "Bold" Speaker
local warrior = {
    name = "Thorin Iron-Will",
    personality = {
        axes = {
            PER_BLD = 90, -- High Boldness
            PER_OBS = 20,
            PER_LOY = 50
        }
    }
}

-- 4. Test Personality Greeting
print(string.format("\n[Greet] %s says: ", speaker.name))
print(">> " .. engine.dialogue:greet(speaker))

print(string.format("\n[Greet] %s says: ", warrior.name))
print(">> " .. engine.dialogue:greet(warrior))

-- 5. Test Rumor Integration
-- First, inject a scandalous rumor about a third party
local subject = "The Merchant Prince"
engine.rumor:inject(engine.game_state, {
    origin_type = "event",
    subject = subject,
    text = "He sold watered-down wine to the garrison.",
    heat = 100,
    severity = 5
})

-- Force reputation calcification by advancing generations
for i = 1, 3 do engine:advance_generation() end

print(string.format("\n[Rumor] %s comments on '%s': ", speaker.name, subject))
print(">> " .. engine.dialogue:comment_on(subject))

print("\n=== TEST COMPLETE ===")
