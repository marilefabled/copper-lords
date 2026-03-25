-- Dark Legacy — Stat Check Tests

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local StatCheck = require("dredwork_world.stat_check")
local HeirBiography = require("dredwork_world.heir_biography")

describe("StatCheck", function()
    local function make_genome(overrides)
        return Genome.new(overrides or {})
    end

    it("evaluates single primary trait check", function()
        local g = make_genome({ PHY_STR = 80 })
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            difficulty = 60,
        })
        assert_true(result.success, "80 PHY_STR should pass difficulty 60")
        assert_equal(80, result.score)
        assert_equal(20, result.margin)
    end)

    it("fails when trait below difficulty", function()
        local g = make_genome({ PHY_STR = 30 })
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            difficulty = 60,
        })
        assert_true(not result.success, "30 PHY_STR should fail difficulty 60")
        assert_true(result.margin < 0)
    end)

    it("multi-trait weighted check", function()
        local g = make_genome({ PHY_STR = 80, MEN_WIL = 60 })
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            secondary = { trait = "MEN_WIL", weight = 0.5 },
            difficulty = 65,
        })
        -- Score = (80*1.0 + 60*0.5) / 1.5 = 110/1.5 = 73.3
        assert_true(result.success, "weighted check should pass")
        assert_true(result.score >= 70 and result.score <= 75, "score should be ~73")
    end)

    it("personality bonus affects check", function()
        local g = make_genome({ PHY_STR = 55 })
        local p = Personality.new({ PER_BLD = 90 })
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            personality = { axis = "PER_BLD", weight = 0.3 },
            difficulty = 55,
        }, p)
        -- Personality bonus = (90-50) * 0.3 * 0.2 = 2.4
        assert_true(result.score > 55, "personality should boost score")
    end)

    it("cultural memory provides small bonus", function()
        local g = make_genome({ PHY_STR = 55 })
        local cm = { trait_priorities = { PHY_STR = 80 } }
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            difficulty = 55,
        }, nil, cm)
        assert_true(result.score > 55, "cultural memory should boost score")
        assert_true(result.score <= 60, "cultural memory bonus should be small")
    end)

    it("quick_check convenience works", function()
        local g = make_genome({ PHY_STR = 80 })
        assert_true(StatCheck.quick_check(g, "PHY_STR", 60))
        assert_true(not StatCheck.quick_check(g, "PHY_STR", 90))
    end)

    it("get_quality returns correct tiers", function()
        assert_equal("triumph", StatCheck.get_quality({ margin = 25 }))
        assert_equal("success", StatCheck.get_quality({ margin = 5 }))
        assert_equal("failure", StatCheck.get_quality({ margin = -10 }))
        assert_equal("disaster", StatCheck.get_quality({ margin = -20 }))
    end)

    it("handles nil genome gracefully", function()
        local result = StatCheck.evaluate(nil, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            difficulty = 50,
        })
        assert_true(not result.success)
    end)

    it("score clamps to 0-100", function()
        local g = make_genome({ PHY_STR = 100 })
        local result = StatCheck.evaluate(g, {
            primary = { trait = "PHY_STR", weight = 1.0 },
            difficulty = 10,
        }, nil, nil, { physical = 50 })
        assert_true(result.score <= 100, "score should clamp to 100")
    end)
end)

describe("HeirBiography", function()
    it("detects wild attributes", function()
        local g = Genome.new({ PHY_STR = 85, PHY_END = 70 })
        local p = Personality.new({ PER_VOL = 80 })
        local wilds = HeirBiography.get_wild_attributes(g, p)
        local found_berserker = false
        for _, w in ipairs(wilds) do
            if w.id == "berserker" then found_berserker = true end
        end
        assert_true(found_berserker, "should detect berserker")
    end)

    it("returns empty for average heir", function()
        local g = Genome.new({}) -- all ~50
        local p = Personality.new()
        local wilds = HeirBiography.get_wild_attributes(g, p)
        -- Average heir should have few or no wild attributes
        assert_true(#wilds <= 1, "average heir should have few wild attributes")
    end)

    it("generates biography text", function()
        local g = Genome.new({ PHY_STR = 85, PHY_HGT = 70 })
        local p = Personality.new({ PER_CRM = 80 })
        local bio = HeirBiography.generate(g, p, "The Iron Age", "Kael")
        assert_true(#bio > 0, "biography should not be empty")
        assert_true(bio:find("Kael") ~= nil, "biography should contain heir name")
    end)

    it("generates personality descriptions", function()
        local p = Personality.new({ PER_BLD = 90, PER_CRM = 10, PER_LOY = 75 })
        local descs = HeirBiography.get_personality_descriptions(p)
        assert_equal(8, #descs, "should have 8 axis descriptions")
        assert_true(#descs[1].description > 0, "description should not be empty")
    end)

    it("wild_bonuses aggregates correctly", function()
        local bonuses = HeirBiography.wild_bonuses({
            { effect = { physical = 10 } },
            { effect = { physical = 5, mental = 8 } },
        })
        assert_equal(15, bonuses.physical)
        assert_equal(8, bonuses.mental)
        assert_equal(0, bonuses.social)
    end)
end)
