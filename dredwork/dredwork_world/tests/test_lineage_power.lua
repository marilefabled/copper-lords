-- Tests for lineage_power.lua (framework-compatible version)

local LineagePower = require("dredwork_world.lineage_power")

describe("LineagePower", function()
    it("creates with default value 45", function()
        local lp = LineagePower.new()
        assert_equal(45, lp.value)
        assert_equal(45, lp.peak)
        assert_equal(45, lp.nadir)
        assert_true(type(lp.history) == "table")
    end)

    it("creates with custom initial value", function()
        local lp = LineagePower.new(70)
        assert_equal(70, lp.value)
    end)

    it("get_tier returns Dominant for 90", function()
        local lp = LineagePower.new(90)
        assert_equal("Dominant", LineagePower.get_tier(lp).label)
    end)

    it("get_tier returns Ascendant for 75", function()
        local lp = LineagePower.new(75)
        assert_equal("Ascendant", LineagePower.get_tier(lp).label)
    end)

    it("get_tier returns Established for 55", function()
        local lp = LineagePower.new(55)
        assert_equal("Established", LineagePower.get_tier(lp).label)
    end)

    it("get_tier returns Fading for 35", function()
        local lp = LineagePower.new(35)
        assert_equal("Fading", LineagePower.get_tier(lp).label)
    end)

    it("get_tier returns Diminished for 20", function()
        local lp = LineagePower.new(20)
        assert_equal("Diminished", LineagePower.get_tier(lp).label)
    end)

    it("get_tier returns Forgotten for 5", function()
        local lp = LineagePower.new(5)
        assert_equal("Forgotten", LineagePower.get_tier(lp).label)
    end)

    it("shift modifies value correctly", function()
        local lp = LineagePower.new(50)
        LineagePower.shift(lp, -10)
        assert_equal(40, lp.value)
        LineagePower.shift(lp, 30)
        assert_equal(70, lp.value)
        assert_equal(70, lp.peak)
    end)

    it("shift clamps to 0-100", function()
        local lp = LineagePower.new(95)
        LineagePower.shift(lp, 20)
        assert_equal(100, lp.value)
        LineagePower.shift(lp, -150)
        assert_equal(0, lp.value)
        assert_equal(0, lp.nadir)
    end)

    it("check_gate passes when power meets minimum", function()
        local lp = LineagePower.new(60)
        local ok, reason = LineagePower.check_gate(lp, 50, nil)
        assert_true(ok)
        assert_nil(reason)
    end)

    it("check_gate fails when power below minimum", function()
        local lp = LineagePower.new(60)
        local ok, reason = LineagePower.check_gate(lp, 75, nil)
        assert_true(not ok)
        assert_not_nil(reason)
    end)

    it("check_gate fails when power above maximum", function()
        local lp = LineagePower.new(60)
        local ok, reason = LineagePower.check_gate(lp, nil, 50)
        assert_true(not ok)
    end)

    it("check_gate passes when power within max", function()
        local lp = LineagePower.new(60)
        local ok, _ = LineagePower.check_gate(lp, nil, 80)
        assert_true(ok)
    end)

    it("compute returns value in 0-100 range", function()
        local lp = LineagePower.new(50)
        local context = {
            generation = 5,
            wealth = { value = 60 },
            morality = { score = 30 },
            cultural_memory = {
                reputation = { primary = "warriors", secondary = "tyrants" },
                relationships = {
                    { type = "ally", strength = 50 },
                    { type = "enemy", strength = 40 },
                },
            },
        }
        local result = LineagePower.compute(context, lp)
        assert_true(result >= 0 and result <= 100, "compute in range: " .. tostring(result))
        assert_equal(1, #lp.history)
    end)

    it("describe returns narrative text", function()
        local lp = LineagePower.new(90)
        local desc = LineagePower.describe(lp)
        assert_true(type(desc) == "string" and #desc > 10)
    end)

    it("serialization round-trip preserves state", function()
        local lp = LineagePower.new(72)
        LineagePower.shift(lp, 5)
        local saved = LineagePower.to_table(lp)
        local loaded = LineagePower.from_table(saved)
        assert_equal(lp.value, loaded.value)
        assert_equal(lp.peak, loaded.peak)
        assert_equal(lp.nadir, loaded.nadir)
    end)

    it("from_table handles nil data", function()
        local fallback = LineagePower.from_table(nil)
        assert_equal(45, fallback.value)
    end)
end)
