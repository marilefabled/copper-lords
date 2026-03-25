-- Dark Legacy — Trait Tests
-- Verifies trait creation, value clamping, cloning, descriptors.

local Trait = require("dredwork_genetics.trait")

describe("Trait", function()

    it("creates a trait with required fields", function()
        local t = Trait.new({
            id = "PHY_STR",
            value = 75,
            category = "physical",
            visibility = "visible",
            inheritance_mode = "blended",
        })
        assert_equal("PHY_STR", t.id)
        assert_equal(75, t.value)
        assert_equal("physical", t.category)
        assert_equal("visible", t.visibility)
        assert_equal("blended", t.inheritance_mode)
    end)

    it("clamps value to 0-100 range", function()
        local t1 = Trait.new({ id = "TEST_HI", value = 150, category = "mental" })
        assert_equal(100, t1.value)

        local t2 = Trait.new({ id = "TEST_LO", value = -20, category = "mental" })
        assert_equal(0, t2.value)
    end)

    it("defaults to value 50 when not specified", function()
        local t = Trait.new({ id = "TEST_DEF", category = "social" })
        assert_equal(50, t.value)
    end)

    it("get_value returns base value for blended traits", function()
        local t = Trait.new({ id = "PHY_STR", value = 65, category = "physical", inheritance_mode = "blended" })
        assert_equal(65, t:get_value())
    end)

    it("set_value clamps to range", function()
        local t = Trait.new({ id = "PHY_STR", value = 50, category = "physical" })
        t:set_value(200)
        assert_equal(100, t:get_value())
        t:set_value(-10)
        assert_equal(0, t:get_value())
    end)

    it("clones are independent of the original", function()
        local orig = Trait.new({ id = "PHY_STR", value = 80, category = "physical", inheritance_mode = "blended" })
        local copy = orig:clone()

        assert_equal(80, copy:get_value())
        assert_equal("PHY_STR", copy.id)

        -- Modifying clone does not affect original
        copy:set_value(10)
        assert_equal(10, copy:get_value())
        assert_equal(80, orig:get_value())
    end)

    it("creates alleles for dominant_recessive traits", function()
        local t = Trait.new({
            id = "PHY_REF",
            value = 70,
            category = "physical",
            inheritance_mode = "dominant_recessive",
        })
        assert_not_nil(t.alleles)
        assert_equal(2, #t.alleles)
        assert_equal(70, t.alleles[1].value)
        assert_equal(true, t.alleles[1].dominant)
        assert_equal(false, t.alleles[2].dominant)
    end)

    it("clone preserves alleles independently", function()
        local orig = Trait.new({
            id = "PHY_REF",
            value = 70,
            category = "physical",
            inheritance_mode = "dominant_recessive",
        })
        local copy = orig:clone()

        copy.alleles[1].value = 99
        assert_equal(70, orig.alleles[1].value, "original allele should not change")
        assert_equal(99, copy.alleles[1].value)
    end)

    it("get_descriptor returns correct labels", function()
        local cases = {
            { value = 5,   expected = "Wretched" },
            { value = 15,  expected = "Wretched" },
            { value = 20,  expected = "Meager" },
            { value = 30,  expected = "Meager" },
            { value = 40,  expected = "Mediocre" },
            { value = 55,  expected = "Capable" },
            { value = 70,  expected = "Potent" },
            { value = 85,  expected = "Exalted" },
            { value = 95,  expected = "Legendary" },
        }
        for _, c in ipairs(cases) do
            local t = Trait.new({ id = "TEST", value = c.value, category = "mental" })
            assert_equal(c.expected, t:get_descriptor(),
                "value " .. c.value .. " should be " .. c.expected)
        end
    end)

    it("dominant_recessive get_value expresses dominant allele", function()
        local t = Trait.new({
            id = "PHY_REF",
            value = 50,
            category = "physical",
            inheritance_mode = "dominant_recessive",
            alleles = {
                { value = 80, dominant = true },
                { value = 30, dominant = false },
            },
        })
        -- Should express the dominant allele (80)
        assert_equal(80, t:get_value())
    end)

    it("both recessive alleles average their values", function()
        local t = Trait.new({
            id = "PHY_REF",
            value = 50,
            category = "physical",
            inheritance_mode = "dominant_recessive",
            alleles = {
                { value = 80, dominant = false },
                { value = 40, dominant = false },
            },
        })
        -- Both recessive: average = 60
        assert_equal(60, t:get_value())
    end)

end)
