-- Dark Legacy — Great Works Tests

local Genome = require("dredwork_genetics.genome")
local GreatWorks = require("dredwork_world.great_works")

describe("GreatWorks", function()
    it("creates empty tracker", function()
        local gw = GreatWorks.new()
        assert_equal(0, gw:count())
        assert_true(not gw:is_building())
    end)

    it("finds available works matching era and traits", function()
        local g = Genome.new({ PHY_END = 70 })
        local gw = GreatWorks.new()
        local avail = gw:get_available(g, "iron")
        local found = false
        for _, tmpl in ipairs(avail) do
            if tmpl.id == "the_iron_wall" then found = true end
        end
        assert_true(found, "the_iron_wall should be available with PHY_END=70 in iron era")
    end)

    it("does not show works from wrong era", function()
        local g = Genome.new({ PHY_END = 70 })
        local gw = GreatWorks.new()
        local avail = gw:get_available(g, "ancient")
        for _, tmpl in ipairs(avail) do
            assert_true(tmpl.id ~= "the_iron_wall",
                "the_iron_wall should not be available in ancient era")
        end
    end)

    it("starts a great work", function()
        local gw = GreatWorks.new()
        local ok = gw:start("the_iron_wall", 10, "Kael")
        assert_true(ok, "should start successfully")
        assert_true(gw:is_building())
        assert_equal("The Iron Wall", gw.in_progress.label)
    end)

    it("cannot start when one is in progress", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        local ok = gw:start("the_great_library", 11, "Thane")
        assert_true(not ok, "should not start a second work")
    end)

    it("get_available returns empty when building", function()
        local g = Genome.new({ PHY_END = 70 })
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        local avail = gw:get_available(g, "iron")
        assert_equal(0, #avail)
    end)

    it("invests and completes over multiple generations", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        -- iron wall requires 3 gens of investment
        local r1 = gw:invest(11, "Kael")
        assert_nil(r1, "should not complete after 1 investment")
        assert_true(gw:is_building())

        local r2 = gw:invest(12, "Thane")
        assert_nil(r2, "should not complete after 2 investments")

        local r3 = gw:invest(13, "Thane")
        assert_not_nil(r3, "should complete after 3 investments")
        assert_equal("the_iron_wall", r3.id)
        assert_equal(1, gw:count())
        assert_true(not gw:is_building())
    end)

    it("abandons work in progress", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        local abandoned = gw:abandon()
        assert_not_nil(abandoned)
        assert_equal("the_iron_wall", abandoned.id)
        assert_true(not gw:is_building())
        assert_equal(0, gw:count())
    end)

    it("get_effects aggregates trait bonuses from completed works", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        gw:invest(11, "Kael")
        gw:invest(12, "Kael")
        gw:invest(13, "Kael") -- completes

        local effects = gw:get_effects()
        assert_true(effects.trait_bonuses["PHY_END"] ~= nil, "should have PHY_END bonus")
        assert_true(effects.trait_bonuses["PHY_END"] >= 3, "PHY_END bonus should be >= 3")
    end)

    it("does not show completed works as available", function()
        local g = Genome.new({ PHY_END = 70 })
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        gw:invest(11, "Kael")
        gw:invest(12, "Kael")
        gw:invest(13, "Kael") -- completes

        local avail = gw:get_available(g, "iron")
        for _, tmpl in ipairs(avail) do
            assert_true(tmpl.id ~= "the_iron_wall", "completed work should not appear")
        end
    end)

    it("serializes and deserializes correctly", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        gw:invest(11, "Kael")

        local data = gw:to_table()
        local restored = GreatWorks.from_table(data)
        assert_true(restored:is_building())
        assert_equal("the_iron_wall", restored.in_progress.id)
        assert_equal(2, restored.in_progress.investment_remaining) -- 3-1=2
    end)

    it("has templates for multiple eras", function()
        local eras = {}
        for _, tmpl in ipairs(GreatWorks.templates) do
            eras[tmpl.era] = true
        end
        assert_true(eras["ancient"], "should have ancient templates")
        assert_true(eras["iron"], "should have iron templates")
        assert_true(eras["dark"], "should have dark templates")
        assert_true(eras["arcane"], "should have arcane templates")
        assert_true(eras["gilded"], "should have gilded templates")
        assert_true(eras["twilight"], "should have twilight templates")
    end)

    it("get_display returns expected fields", function()
        local gw = GreatWorks.new()
        gw:start("the_iron_wall", 10, "Kael")
        local d = gw:get_display()
        assert_not_nil(d.completed)
        assert_not_nil(d.in_progress)
    end)
end)
