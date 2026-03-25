-- Dark Legacy — Personality Tests
-- Verifies personality creation and trait-based derivation.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")

describe("Personality", function()

    rng.seed(88888)

    it("creates personality with 8 axes", function()
        local p = Personality.new()
        local count = 0
        for _ in pairs(p.axes) do count = count + 1 end
        assert_equal(8, count)
    end)

    it("default axes are 50", function()
        local p = Personality.new()
        for _, axis_id in ipairs(Personality.AXES) do
            assert_equal(50, p:get_axis(axis_id))
        end
    end)

    it("custom values are respected", function()
        local p = Personality.new({ PER_BLD = 90, PER_CRM = 10 })
        assert_equal(90, p:get_axis("PER_BLD"))
        assert_equal(10, p:get_axis("PER_CRM"))
    end)

    it("values are clamped to 0-100", function()
        local p = Personality.new({ PER_BLD = 150, PER_CRM = -20 })
        assert_equal(100, p:get_axis("PER_BLD"))
        assert_equal(0, p:get_axis("PER_CRM"))
    end)

    it("derive produces valid personality from genome and parents", function()
        local g = Genome.new()
        local pa = Personality.new({ PER_BLD = 80 })
        local pb = Personality.new({ PER_BLD = 20 })

        local child = Personality.derive(g, pa, pb)

        for _, axis_id in ipairs(Personality.AXES) do
            local val = child:get_axis(axis_id)
            assert_in_range(val, 0, 100, "derived " .. axis_id)
        end
    end)

    it("derive reflects parent influence (60% weight)", function()
        rng.seed(22222)
        -- Both parents have high boldness
        local pa = Personality.new({ PER_BLD = 95 })
        local pb = Personality.new({ PER_BLD = 95 })

        local sum = 0
        local n = 100
        for _ = 1, n do
            local g = Genome.new()
            local child = Personality.derive(g, pa, pb)
            sum = sum + child:get_axis("PER_BLD")
        end
        local avg = sum / n
        -- With 60% inheritance from parents at 95, should trend high
        assert_in_range(avg, 55, 95, "derived boldness from high parents")
    end)

    it("clone is independent", function()
        local orig = Personality.new({ PER_BLD = 80, PER_CRM = 30 })
        local copy = orig:clone()

        assert_equal(80, copy:get_axis("PER_BLD"))
        -- Modify via direct table access to test independence
        copy.axes["PER_BLD"] = 10
        assert_equal(80, orig:get_axis("PER_BLD"), "original unchanged")
    end)

end)
