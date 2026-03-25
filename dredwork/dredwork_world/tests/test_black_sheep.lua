-- Dark Legacy — Black Sheep Detection Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local BlackSheep = require("dredwork_world.black_sheep")
local rng = require("dredwork_core.rng")

describe("Black Sheep Detection", function()
    rng.seed(42)

    it("should return nil for average heir in average family", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()

        local result = BlackSheep.detect(genome, pers, cm)
        assert_nil(result, "Average heir should not be black sheep")
    end)

    it("should detect creative genius in warrior family", function()
        -- Build a warrior family — need to populate trait_priorities directly
        local cm = CulturalMemory.new()
        local trait_defs = require("dredwork_genetics.config.trait_definitions")
        -- Set all physical priorities high, creative low
        for _, def in ipairs(trait_defs) do
            if def.category == "physical" then
                cm.trait_priorities[def.id] = 80
            elseif def.category == "creative" then
                cm.trait_priorities[def.id] = 20
            elseif def.category == "mental" then
                cm.trait_priorities[def.id] = 50
            elseif def.category == "social" then
                cm.trait_priorities[def.id] = 50
            end
        end
        cm.reputation = { primary = "warriors", secondary = "tyrants" }

        -- Create a creative heir — set ALL creative traits high, physical low
        local genome = Genome.new()
        for _, def in ipairs(trait_defs) do
            if def.category == "creative" then
                genome:set_value(def.id, 90)
            elseif def.category == "physical" then
                genome:set_value(def.id, 25)
            end
        end

        local pers = Personality.new()
        local result = BlackSheep.detect(genome, pers, cm)
        assert_not_nil(result, "Should detect creative heir in warrior family")
        assert_true(result.is_black_sheep, "Should be marked as black sheep")
        assert_true(result.magnitude > 0.6, "Magnitude should be above threshold, got " .. tostring(result.magnitude))
        assert_not_nil(result.narrative, "Should have narrative text")
        assert_true(#result.narrative > 0, "Narrative should not be empty")
    end)

    it("should detect cruel heir in merciful family", function()
        local cm = CulturalMemory.new()
        cm.reputation = { primary = "healers", secondary = "scholars" }

        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 90,  -- very cruel
            PER_BLD = 50,
            PER_OBS = 50,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_VOL = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })

        local result = BlackSheep.detect(genome, pers, cm)
        assert_not_nil(result, "Should detect cruel heir in merciful family")
        assert_true(result.is_black_sheep)
        assert_equal("cruel_in_merciful_family", result.contrast)
    end)

    it("should detect merciful heir in cruel family", function()
        local cm = CulturalMemory.new()
        cm.reputation = { primary = "tyrants", secondary = "warriors" }

        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 10,  -- very merciful
            PER_BLD = 50,
            PER_OBS = 50,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_VOL = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })

        local result = BlackSheep.detect(genome, pers, cm)
        assert_not_nil(result, "Should detect merciful heir in cruel family")
        assert_true(result.is_black_sheep)
        assert_equal("merciful_in_cruel_family", result.contrast)
    end)

    it("should not trigger below magnitude threshold 0.6", function()
        local cm = CulturalMemory.new()
        -- Slight priority difference — not enough to trigger
        for id, _ in pairs(cm.trait_priorities) do
            local prefix = id:sub(1, 3)
            if prefix == "PHY" then
                cm.trait_priorities[id] = 55
            elseif prefix == "CRE" then
                cm.trait_priorities[id] = 45
            end
        end

        local genome = Genome.new()
        -- Only slightly creative
        genome:set_value("CRE_ING", 60)
        local pers = Personality.new()

        local result = BlackSheep.detect(genome, pers, cm)
        assert_nil(result, "Slight contrast should not trigger black sheep")
    end)

    it("should return correct shift multiplier", function()
        local bs_data = { is_black_sheep = true, magnitude = 0.8 }
        assert_equal(2.0, BlackSheep.get_shift_multiplier(bs_data))

        assert_equal(1.0, BlackSheep.get_shift_multiplier(nil))
        assert_equal(1.0, BlackSheep.get_shift_multiplier({}))
    end)

    it("should handle nil inputs gracefully", function()
        local result = BlackSheep.detect(nil, nil, nil)
        assert_nil(result, "Should return nil for nil inputs")
    end)

    it("should have narrative from correct pool", function()
        local cm = CulturalMemory.new()
        cm.reputation = { primary = "tyrants", secondary = "warriors" }

        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 5,
            PER_BLD = 50,
            PER_OBS = 50,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_VOL = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })

        local result = BlackSheep.detect(genome, pers, cm)
        if result then
            assert_true(#result.narrative > 10, "Narrative should be meaningful text")
        end
    end)
end)
