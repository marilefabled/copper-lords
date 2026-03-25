local Pressure = require("dredwork_dilemma.pressure")

describe("Pressure", function()

    it("creates a pressure from spec", function()
        local p = Pressure.create({
            id = "test:1",
            source = "bonds",
            category = "relationship",
            urgency = 70,
            label = "Horg's Grievance",
            summary = "Horg is angry.",
            subject = "Horg",
            tags = { "grievance", "bond" },
        })
        assert_not_nil(p)
        assert_equal("test:1", p.id)
        assert_equal(70, p.urgency)
        assert_equal("relationship", p.category)
    end)

    it("returns nil without id", function()
        assert_nil(Pressure.create({ source = "bonds" }))
    end)

    it("returns nil for nil spec", function()
        assert_nil(Pressure.create(nil))
    end)

    it("clamps urgency", function()
        local p = Pressure.create({ id = "x", urgency = 150 })
        assert_equal(100, p.urgency)
        local p2 = Pressure.create({ id = "y", urgency = -20 })
        assert_equal(0, p2.urgency)
    end)

    it("has_tag checks correctly", function()
        local p = Pressure.create({ id = "x", tags = { "grievance", "bond" } })
        assert_true(Pressure.has_tag(p, "grievance"))
        assert_true(Pressure.has_tag(p, "bond"))
        assert_true(not Pressure.has_tag(p, "rumor"))
    end)

    it("defaults missing fields", function()
        local p = Pressure.create({ id = "x" })
        assert_equal("unknown", p.source)
        assert_equal("survival", p.category)
        assert_equal(50, p.urgency)
        assert_not_nil(p.address)
        assert_not_nil(p.neglect)
    end)
end)
