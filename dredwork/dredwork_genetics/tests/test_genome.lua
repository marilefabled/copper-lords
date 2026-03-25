-- Dark Legacy — Genome Tests
-- Verifies genome creation, trait access, cloning.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local trait_definitions = require("dredwork_genetics.config.trait_definitions")

describe("Genome", function()

    -- Seed for reproducibility in tests
    rng.seed(12345)

    it("creates a genome with all 75 traits", function()
        local g = Genome.new()
        assert_equal(75, g:trait_count())
    end)

    it("all trait values are in 0-100 range", function()
        local g = Genome.new()
        for _, def in ipairs(trait_definitions) do
            local val = g:get_value(def.id)
            assert_not_nil(val, "trait " .. def.id .. " should exist")
            assert_in_range(val, 0, 100, "trait " .. def.id)
        end
    end)

    it("get_trait returns trait object", function()
        local g = Genome.new()
        local t = g:get_trait("PHY_STR")
        assert_not_nil(t)
        assert_equal("PHY_STR", t.id)
        assert_equal("physical", t.category)
    end)

    it("get_trait returns nil for nonexistent trait", function()
        local g = Genome.new()
        assert_nil(g:get_trait("FAKE_ID"))
    end)

    it("set_value modifies trait value", function()
        local g = Genome.new()
        g:set_value("PHY_STR", 99)
        assert_equal(99, g:get_value("PHY_STR"))
    end)

    it("respects overrides on creation", function()
        local g = Genome.new({ PHY_STR = 90, MEN_INT = 10 })
        assert_equal(90, g:get_value("PHY_STR"))
        assert_equal(10, g:get_value("MEN_INT"))
    end)

    it("clone is independent", function()
        local g = Genome.new({ PHY_STR = 75 })
        local c = g:clone()

        assert_equal(75, c:get_value("PHY_STR"))
        c:set_value("PHY_STR", 25)
        assert_equal(75, g:get_value("PHY_STR"), "original should be unchanged")
        assert_equal(25, c:get_value("PHY_STR"))
    end)

    it("get_category returns correct number of traits", function()
        local g = Genome.new()
        assert_equal(23, #g:get_category("physical"))
        assert_equal(18, #g:get_category("mental"))
        assert_equal(18, #g:get_category("social"))
        assert_equal(16, #g:get_category("creative"))
    end)

    it("population baseline values cluster around 50", function()
        rng.seed(42)
        local sum = 0
        local count = 0
        -- Generate several genomes and average all trait values
        for _ = 1, 20 do
            local g = Genome.new()
            for _, def in ipairs(trait_definitions) do
                sum = sum + g:get_value(def.id)
                count = count + 1
            end
        end
        local avg = sum / count
        -- Average should be roughly 50 (with stddev 12, across many samples)
        assert_in_range(avg, 40, 60, "population average")
    end)

end)
