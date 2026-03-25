-- Dark Legacy — Cultural Memory Tests
-- Verifies priority accumulation, taboo decay, blind spots, relationships.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local CulturalMemory = require("dredwork_genetics.cultural_memory")

describe("CulturalMemory", function()

    rng.seed(66666)

    it("starts with empty state", function()
        local cm = CulturalMemory.new()
        assert_equal(0, #cm.taboos)
        assert_equal(0, #cm.relationships)
        assert_equal(0, #cm.blind_spots)
        assert_equal("unknown", cm.reputation.primary)
    end)

    it("update populates trait priorities", function()
        local cm = CulturalMemory.new()
        local heir = Genome.new({ PHY_STR = 90 })
        cm:update(heir)

        -- PHY_STR priority should be above 50 after a high-STR heir
        assert_true(cm.trait_priorities["PHY_STR"] > 50,
            "PHY_STR priority should increase")
    end)

    it("priorities decay toward 50 over generations", function()
        local cm = CulturalMemory.new()
        -- First: a very strong heir
        local strong_heir = Genome.new({ PHY_STR = 100 })
        cm:update(strong_heir)
        local after_strong = cm.trait_priorities["PHY_STR"]

        -- Then: many average heirs
        for _ = 1, 20 do
            local avg_heir = Genome.new({ PHY_STR = 50 })
            cm:update(avg_heir)
        end
        local after_decay = cm.trait_priorities["PHY_STR"]

        assert_true(after_decay < after_strong,
            "priority should decay toward baseline over time")
    end)

    it("taboos decay and are removed", function()
        local cm = CulturalMemory.new()
        cm:add_taboo("heir_died_to_plague", 1, "no_plague_allies", 20)

        -- Decay many times
        for _ = 1, 200 do
            cm:decay()
        end

        -- Taboo should have been removed (strength < threshold)
        assert_equal(0, #cm.taboos, "taboo should be removed after sufficient decay")
    end)

    it("is_taboo returns true for active taboos", function()
        local cm = CulturalMemory.new()
        cm:add_taboo("betrayal", 1, "no_trust_outsiders", 85)

        assert_true(cm:is_taboo("no_trust_outsiders"))
        assert_true(not cm:is_taboo("something_else"))
    end)

    it("relationships decay and are removed", function()
        local cm = CulturalMemory.new()
        cm:add_relationship("house_mordthen", "enemy", 1, 15, "land_war")

        -- Decay many times
        for _ = 1, 200 do
            cm:decay()
        end

        assert_equal(0, #cm.relationships, "relationship should be removed after decay")
    end)

    it("reputation updates based on trait priorities", function()
        local cm = CulturalMemory.new()

        -- Feed several physically dominant heirs
        for _ = 1, 10 do
            local heir = Genome.new({
                PHY_STR = 95, PHY_END = 90, PHY_VIT = 90,
                MEN_INT = 20, CRE_ING = 20,
            })
            cm:update(heir)
        end

        assert_equal("warriors", cm.reputation.primary,
            "family of warriors should have warrior reputation")
    end)

    it("blind spots activate when one category dominates", function()
        local cm = CulturalMemory.new()

        -- Feed many heirs with extreme physical bias (all 18 physical traits high)
        for _ = 1, 30 do
            local heir = Genome.new({
                PHY_STR = 95, PHY_END = 95, PHY_VIT = 95,
                PHY_AGI = 95, PHY_REF = 95, PHY_HGT = 95,
                PHY_PAI = 95, PHY_FER = 95, PHY_LON = 95,
                PHY_IMM = 95, PHY_REC = 95, PHY_BON = 95,
                PHY_LUN = 95, PHY_COR = 95, PHY_MET = 95,
                PHY_BLD = 95, PHY_SEN = 95, PHY_ADP = 95,
                CRE_ING = 5, CRE_CRA = 5, CRE_EXP = 5,
                CRE_AES = 5, CRE_IMP = 5, CRE_VIS = 5,
                CRE_NAR = 5, CRE_MEC = 5, CRE_MUS = 5,
                CRE_ARC = 5, CRE_SYM = 5, CRE_RES = 5,
                CRE_INN = 5, CRE_FLV = 5, CRE_RIT = 5, CRE_TIN = 5,
            })
            cm:update(heir)
        end

        local spots = cm:get_blind_spots()
        assert_true(#spots > 0, "should have at least one blind spot")
    end)

end)
