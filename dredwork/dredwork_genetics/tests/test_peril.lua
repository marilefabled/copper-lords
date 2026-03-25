-- Dark Legacy — Peril Assessment Tests
-- Tests danger level assessment for active conditions.

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local Peril = require("dredwork_genetics.peril")

describe("Peril - assess", function()
    it("should return nil with no conditions", function()
        local genome = Genome.new({ PHY_VIT = 50, PHY_IMM = 50, PHY_END = 50 })
        local result = Peril.assess(genome, nil, {}, 5)
        assert_nil(result, "Expected nil peril with no conditions")
    end)

    it("should return nil for mild conditions with strong heir", function()
        local genome = Genome.new({ PHY_VIT = 80, PHY_IMM = 80, PHY_END = 70, PHY_LON = 70 })
        local conditions = { { type = "war", intensity = 0.3, remaining_gens = 2 } }
        local result = Peril.assess(genome, nil, conditions, 10)
        -- Mild war with strong heir should be nil or elevated at most
        if result then
            assert_true(result.level == "elevated",
                "Expected nil or elevated, got " .. result.level)
        end
    end)

    it("should detect severe peril during plague for weak heir", function()
        local genome = Genome.new({ PHY_VIT = 25, PHY_IMM = 15, PHY_END = 30, PHY_LON = 25 })
        local conditions = { { type = "plague", intensity = 0.8, remaining_gens = 3 } }
        local result = Peril.assess(genome, nil, conditions, 10)
        assert_not_nil(result, "Expected peril result during plague")
        assert_true(result.level == "severe" or result.level == "dire",
            "Expected severe/dire, got " .. result.level)
    end)

    it("should detect dire peril during plague + famine", function()
        local genome = Genome.new({ PHY_VIT = 20, PHY_IMM = 15, PHY_END = 20, PHY_LON = 20 })
        local conditions = {
            { type = "plague", intensity = 0.8, remaining_gens = 3 },
            { type = "famine", intensity = 0.7, remaining_gens = 2 },
        }
        local result = Peril.assess(genome, nil, conditions, 10)
        assert_not_nil(result, "Expected peril result during plague+famine")
        assert_equal("dire", result.level, "Expected dire peril")
    end)

    it("should return narrative lines", function()
        local genome = Genome.new({ PHY_VIT = 20, PHY_IMM = 15, PHY_END = 20, PHY_LON = 20 })
        local conditions = { { type = "plague", intensity = 0.8, remaining_gens = 3 } }
        local result = Peril.assess(genome, nil, conditions, 10)
        assert_not_nil(result, "Expected peril result")
        assert_true(#result.lines > 0, "Expected at least one warning line")
        assert_true(type(result.lines[1]) == "string", "Warning lines should be strings")
    end)

    it("should reduce peril for early generations (gen shield)", function()
        local genome = Genome.new({ PHY_VIT = 30, PHY_IMM = 25, PHY_END = 30, PHY_LON = 30 })
        local conditions = { { type = "plague", intensity = 0.6, remaining_gens = 3 } }

        local result_gen1 = Peril.assess(genome, nil, conditions, 1)
        local result_gen10 = Peril.assess(genome, nil, conditions, 10)

        -- Gen 1 should be safer (nil or lower level)
        if result_gen1 and result_gen10 then
            local level_order = { elevated = 1, severe = 2, dire = 3 }
            local l1 = level_order[result_gen1.level] or 0
            local l10 = level_order[result_gen10.level] or 0
            assert_true(l1 <= l10,
                "Gen 1 should be safer: gen1=" .. result_gen1.level .. " gen10=" .. result_gen10.level)
        end
    end)

    it("should cap warning lines at 3", function()
        local genome = Genome.new({ PHY_VIT = 10, PHY_IMM = 10, PHY_END = 10, PHY_LON = 10, PHY_FER = 10 })
        local conditions = {
            { type = "plague", intensity = 1.0, remaining_gens = 5 },
            { type = "famine", intensity = 1.0, remaining_gens = 5 },
            { type = "war", intensity = 1.0, remaining_gens = 5 },
        }
        local result = Peril.assess(genome, nil, conditions, 10)
        assert_not_nil(result, "Expected peril result")
        assert_true(#result.lines <= 3, "Expected max 3 lines, got " .. #result.lines)
    end)

    it("should handle nil genome gracefully", function()
        local result = Peril.assess(nil, nil, {}, 5)
        assert_nil(result, "Expected nil for nil genome")
    end)

    it("should handle nil conditions gracefully", function()
        local genome = Genome.new({ PHY_VIT = 50 })
        local result = Peril.assess(genome, nil, nil, 5)
        assert_nil(result, "Expected nil for nil conditions")
    end)
end)
