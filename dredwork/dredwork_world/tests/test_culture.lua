-- Dark Legacy — Culture Tests

local Culture = require("dredwork_world.culture")

-- Mock cultural memory with trait priorities
local function mock_cultural_memory(priorities)
    return { trait_priorities = priorities or {} }
end

describe("Culture", function()
    it("creates empty culture tracker", function()
        local c = Culture.new()
        assert_equal(0, #c.values)
        assert_equal(0, #c.customs)
        assert_equal(30, c.rigidity)
        assert_equal(0, c.last_recalc_gen)
    end)

    it("recalculates values from cultural memory", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
            MEN_INT = 60, MEN_WIL = 55,
            SOC_CHA = 40, CRE_ING = 30,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        assert_true(#c.values > 0, "should have at least one value")
        assert_true(#c.values <= 3, "should have at most 3 values")
        -- Physical should be top value ("strength")
        assert_equal("strength", c.values[1])
        assert_equal(5, c.last_recalc_gen)
    end)

    it("adopts customs when thresholds met", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 70, PHY_VIT = 75,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        -- Physical avg = 75, exceeds trial_by_combat (65) and blood_oaths (60)
        local has_trial = c:has_custom("trial_by_combat")
        local has_blood = c:has_custom("blood_oaths")
        assert_true(has_trial, "should adopt trial_by_combat with high physical avg")
        assert_true(has_blood, "should adopt blood_oaths with high physical avg")
    end)

    it("does not adopt customs when thresholds not met", function()
        local cm = mock_cultural_memory({
            PHY_STR = 40, PHY_END = 35,
            MEN_INT = 40, SOC_CHA = 40, CRE_ING = 40,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        assert_true(not c:has_custom("trial_by_combat"),
            "should NOT adopt trial_by_combat with low physical avg")
    end)

    it("ancestor_worship requires generation 10+", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, MEN_INT = 70, SOC_CHA = 60, CRE_ING = 50,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        assert_true(not c:has_custom("ancestor_worship"),
            "should NOT adopt ancestor_worship before gen 10")

        c:recalculate(cm, 12)
        assert_true(c:has_custom("ancestor_worship"),
            "should adopt ancestor_worship at gen 12")
    end)

    it("tick recalculates every 5 generations", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
        })
        local c = Culture.new()
        c:tick(cm, 3)
        -- Should not recalc at gen 3 (only 3 gens since last recalc at 0)
        assert_equal(0, c.last_recalc_gen)

        c:tick(cm, 5)
        -- Should recalc at gen 5 (5 gens since last recalc at 0)
        assert_equal(5, c.last_recalc_gen)
        assert_true(#c.values > 0, "should have values after tick at gen 5")
    end)

    it("tick does not recalculate before 5 gen interval", function()
        local cm = mock_cultural_memory({ PHY_STR = 70 })
        local c = Culture.new()
        c.last_recalc_gen = 5
        c:tick(cm, 8)
        -- 8 - 5 = 3, less than 5
        assert_equal(5, c.last_recalc_gen)
    end)

    it("rigidity increases with custom age", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        local early_rigidity = c.rigidity

        -- Recalculate much later — customs have aged
        c:recalculate(cm, 50)
        assert_true(c.rigidity > early_rigidity,
            "rigidity should increase as customs age")
    end)

    it("rigidity is capped at 80", function()
        local c = Culture.new()
        c.customs = {
            { id = "test1", generation_adopted = 0 },
            { id = "test2", generation_adopted = 0 },
            { id = "test3", generation_adopted = 0 },
        }
        -- Force recalculate to update rigidity at a very high generation
        local cm = mock_cultural_memory({ PHY_STR = 80 })
        c:recalculate(cm, 500)
        assert_true(c.rigidity <= 80, "rigidity should be capped at 80, got " .. c.rigidity)
    end)

    it("does not duplicate customs on repeated recalculation", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
        })
        local c = Culture.new()
        c:recalculate(cm, 5)
        local count1 = #c.customs
        -- Recalculate at same generation range (before gen 10 to avoid ancestor_worship)
        c:recalculate(cm, 7)
        local count2 = #c.customs
        assert_equal(count1, count2, "customs should not duplicate on re-recalculate")
    end)

    it("get_display returns expected fields", function()
        local c = Culture.new()
        c.values = { "strength", "knowledge" }
        c.rigidity = 45
        local d = c:get_display()
        assert_equal(2, #d.values)
        assert_equal(45, d.rigidity)
        assert_not_nil(d.customs)
    end)

    it("serializes and deserializes correctly", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, MEN_INT = 70,
        })
        local c = Culture.new()
        c:recalculate(cm, 10)

        local data = c:to_table()
        local restored = Culture.from_table(data)
        assert_equal(#c.values, #restored.values)
        assert_equal(#c.customs, #restored.customs)
        assert_equal(c.rigidity, restored.rigidity)
        assert_equal(c.last_recalc_gen, restored.last_recalc_gen)
    end)

    it("from_table handles nil data gracefully", function()
        local c = Culture.from_table(nil)
        assert_equal(0, #c.values)
        assert_equal(30, c.rigidity)
    end)

    it("has_custom returns false for unknown custom", function()
        local c = Culture.new()
        assert_true(not c:has_custom("nonexistent"), "should return false for unknown custom")
    end)
end)
