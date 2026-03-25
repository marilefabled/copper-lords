local Collector = require("dredwork_dilemma.collector")

describe("Pressure Collector", function()

    it("creates an empty collector", function()
        local c = Collector.new()
        assert_not_nil(c)
        assert_not_nil(c.sources)
    end)

    it("registers and gathers from sources", function()
        local c = Collector.new()
        Collector.register(c, "test", function(gs)
            return {
                { id = "t:1", urgency = 80, label = "Fire", summary = "On fire." },
                { id = "t:2", urgency = 40, label = "Smoke", summary = "Smoky." },
            }
        end)
        local pressures = Collector.gather(c, {})
        assert_equal(2, #pressures)
        assert_equal("t:1", pressures[1].id, "should be sorted by urgency")
    end)

    it("gathers from multiple sources", function()
        local c = Collector.new()
        Collector.register(c, "a", function() return { { id = "a:1", urgency = 60 } } end)
        Collector.register(c, "b", function() return { { id = "b:1", urgency = 90 } } end)
        local pressures = Collector.gather(c, {})
        assert_equal(2, #pressures)
        assert_equal("b:1", pressures[1].id, "highest urgency first")
    end)

    it("handles source errors gracefully", function()
        local c = Collector.new()
        Collector.register(c, "bad", function() error("boom") end)
        Collector.register(c, "good", function() return { { id = "g:1", urgency = 50 } } end)
        local pressures = Collector.gather(c, {})
        assert_equal(1, #pressures, "bad source should be skipped")
    end)

    it("collects bond grievances", function()
        local gs = {
            shadow_bonds = {
                bonds = {
                    { id = "core:1", name = "Horg", expectation = { type = "loyalty", grievance = 45, violation_count = 2 } },
                    { id = "core:2", name = "Sev", expectation = { type = "honesty", grievance = 10, violation_count = 0 } },
                },
            },
        }
        local pressures = Collector.source_bond_grievances(gs)
        assert_equal(1, #pressures, "only Horg has grievance >= 20")
        assert_true(pressures[1].label:find("Horg"))
        assert_true(pressures[1].urgency >= 45)
    end)

    it("collects hot rumors", function()
        local gs = {
            rumor_network = {
                rumors = {
                    hot = { id = "hot", subject = "Asha", current_text = "Bad.", heat = 70, reach = 3, severity = 3, dead = false, calcified = false, tags = { "shame" } },
                    cold = { id = "cold", subject = "Asha", current_text = "Old.", heat = 10, reach = 1, severity = 1, dead = false, calcified = false, tags = {} },
                },
            },
        }
        local pressures = Collector.source_rumors(gs)
        assert_equal(1, #pressures, "only hot rumor should generate pressure")
    end)

    it("collects body pressures", function()
        local gs = {
            heir_name = "Asha",
            shadow_body = {
                wounds = { deep = { severity = 40 } },
                illnesses = {},
                compulsions = { drink = { severity = 35 } },
            },
        }
        local pressures = Collector.source_body(gs)
        assert_equal(2, #pressures, "wounds and compulsion both above threshold")
    end)

    it("collects claim pressures", function()
        local gs = {
            heir_name = "Asha",
            shadow_claim = { initialized = true, exposure = 60, usurper_risk = 55 },
        }
        local pressures = Collector.source_claim(gs)
        assert_equal(1, #pressures)
        assert_true(pressures[1].label:find("Bloodline"))
    end)

    it("returns empty for missing state", function()
        assert_equal(0, #Collector.source_bond_grievances({}))
        assert_equal(0, #Collector.source_rumors({}))
        assert_equal(0, #Collector.source_body({}))
        assert_equal(0, #Collector.source_claim({}))
    end)
end)
