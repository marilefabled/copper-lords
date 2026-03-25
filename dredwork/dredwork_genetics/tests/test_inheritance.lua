-- Dark Legacy — Inheritance Tests
-- Verifies breeding produces valid children with expected statistical properties.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Inheritance = require("dredwork_genetics.inheritance")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

describe("Inheritance", function()

    rng.seed(54321)

    it("breed produces a genome with all 75 traits", function()
        local p1 = Genome.new()
        local p2 = Genome.new()
        local child = Inheritance.breed(p1, p2)
        assert_equal(75, child:trait_count())
    end)

    it("child trait values are in valid range", function()
        local a = Genome.new()
        local b = Genome.new()
        local child = Inheritance.breed(a, b)
        for _, def in ipairs(trait_definitions) do
            local val = child:get_value(def.id)
            assert_in_range(val, 0, 100, "child trait " .. def.id)
        end
    end)

    it("blended traits average between parents over many trials", function()
        rng.seed(99999)
        local a = Genome.new({ PHY_STR = 90 })
        local b = Genome.new({ PHY_STR = 10 })

        local sum = 0
        local n = 200
        for _ = 1, n do
            local child = Inheritance.breed(a, b)
            sum = sum + child:get_value("PHY_STR")
        end
        local avg = sum / n
        -- Should average roughly 50 (midpoint of 90 and 10), with noise
        assert_in_range(avg, 35, 65, "blended average of PHY_STR")
    end)

    it("dominant_recessive traits have alleles on child", function()
        local a = Genome.new()
        local b = Genome.new()
        local child = Inheritance.breed(a, b)
        -- PHY_REF is dominant_recessive
        local t = child:get_trait("PHY_REF")
        assert_not_nil(t.alleles, "PHY_REF should have alleles")
        assert_equal(2, #t.alleles)
    end)

    it("breeding two high-stat parents tends toward high children", function()
        rng.seed(11111)
        local a = Genome.new({ MEN_INT = 95 })
        local b = Genome.new({ MEN_INT = 90 })

        local sum = 0
        local n = 100
        for _ = 1, n do
            local child = Inheritance.breed(a, b)
            sum = sum + child:get_value("MEN_INT")
        end
        local avg = sum / n
        -- Should tend high (parents are 90-95)
        assert_in_range(avg, 75, 100, "high-stat parent average")
    end)

end)
