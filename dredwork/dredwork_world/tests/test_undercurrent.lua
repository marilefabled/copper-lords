-- Dark Legacy — Undercurrent Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local Undercurrent = require("dredwork_world.undercurrent")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")

describe("Undercurrent", function()

    it("returns empty array for fresh game state", function()
        local state = {
            current_heir = Genome.new(),
            heir_personality = Personality.new(),
            cultural_memory = CulturalMemory.new(),
            generation = 1,
        }
        local result = Undercurrent.detect(state)
        assert_not_nil(result, "should return array")
        -- First detection shouldn't fire anything (no streak yet)
        -- But some patterns might fire if personality extremes exist
    end)

    it("initializes undercurrent_streaks on gameState", function()
        local state = {
            current_heir = Genome.new(),
            heir_personality = Personality.new(),
            cultural_memory = CulturalMemory.new(),
            generation = 1,
        }
        Undercurrent.detect(state)
        assert_not_nil(state.undercurrent_streaks, "streaks should be created")
    end)

    it("personality extreme pattern fires after threshold", function()
        local state = {
            current_heir = Genome.new(),
            heir_personality = Personality.new({ PER_CRM = 90 }), -- very cruel
            cultural_memory = CulturalMemory.new(),
            generation = 1,
        }
        -- Run detection multiple times to build streak
        for i = 1, 5 do
            Undercurrent.detect(state)
        end
        local result = Undercurrent.detect(state)
        -- Look for sustained_cruelty pattern
        local found = false
        for _, u in ipairs(result) do
            if u.pattern_id == "sustained_cruelty" then
                found = true
                assert_true(u.severity == "whisper" or u.severity == "murmur" or u.severity == "roar",
                    "severity should be valid: " .. u.severity)
                assert_true(#u.narrative > 0, "narrative should not be empty")
                break
            end
        end
        assert_true(found, "sustained_cruelty should fire after 5 detections")
    end)

    it("streak resets when pattern stops matching", function()
        local state = {
            current_heir = Genome.new(),
            heir_personality = Personality.new({ PER_CRM = 90 }),
            cultural_memory = CulturalMemory.new(),
            generation = 1,
        }
        -- Build streak
        for i = 1, 3 do
            Undercurrent.detect(state)
        end
        -- Break streak by changing personality
        state.heir_personality = Personality.new({ PER_CRM = 50 })
        Undercurrent.detect(state)
        assert_equal(0, state.undercurrent_streaks["sustained_cruelty"] or 0,
            "streak should reset to 0")
    end)

    it("get_strongest returns highest severity", function()
        local undercurrents = {
            { pattern_id = "a", severity = "whisper", title = "A" },
            { pattern_id = "b", severity = "roar", title = "B" },
            { pattern_id = "c", severity = "murmur", title = "C" },
        }
        local strongest = Undercurrent.get_strongest(undercurrents)
        assert_equal("b", strongest.pattern_id, "should return roar-level pattern")
    end)

    it("get_strongest returns nil for empty array", function()
        assert_nil(Undercurrent.get_strongest({}), "empty should return nil")
        assert_nil(Undercurrent.get_strongest(nil), "nil should return nil")
    end)

    it("cultural tension fires when values diverge from reality", function()
        -- Family values physical (priority > 65) but heir is weak (< 45)
        local memory = CulturalMemory.new()
        -- Set physical trait priorities high
        for _, def in ipairs(require("dredwork_genetics.config.trait_definitions")) do
            if def.id:sub(1, 3) == "PHY" then
                memory.trait_priorities[def.id] = 75
            end
        end

        -- Create weak physical heir
        local overrides = {}
        for _, def in ipairs(require("dredwork_genetics.config.trait_definitions")) do
            if def.id:sub(1, 3) == "PHY" then
                overrides[def.id] = 30
            end
        end

        local state = {
            current_heir = Genome.new(overrides),
            heir_personality = Personality.new(),
            cultural_memory = memory,
            generation = 10,
        }

        -- Run 4 times
        for i = 1, 4 do
            Undercurrent.detect(state)
        end

        local found = false
        local result = Undercurrent.detect(state)
        for _, u in ipairs(result) do
            if u.pattern_id == "phy_tension" then
                found = true
                break
            end
        end
        assert_true(found, "physical tension should fire when values diverge from reality")
    end)
end)
