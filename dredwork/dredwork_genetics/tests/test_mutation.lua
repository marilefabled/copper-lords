-- Dark Legacy — Mutation Tests
-- Verifies mutation pressure, application, and decay.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Mutation = require("dredwork_genetics.mutation")

describe("Mutation", function()

    rng.seed(77777)

    it("new_pressure starts at zero", function()
        local p = Mutation.new_pressure()
        assert_equal(0, p.value)
        assert_equal(0, #p.active_triggers)
    end)

    it("add_trigger increases pressure value", function()
        local p = Mutation.new_pressure()
        Mutation.add_trigger(p, "war")
        assert_true(p.value > 0, "pressure should increase after war trigger")
        assert_equal(1, #p.active_triggers)
    end)

    it("inbreeding adds highest pressure", function()
        rng.seed(77777)
        local p1 = Mutation.new_pressure()
        Mutation.add_trigger(p1, "inbreeding")
        local inbreeding_val = p1.value

        rng.seed(77777)
        local p2 = Mutation.new_pressure()
        Mutation.add_trigger(p2, "famine")
        local famine_val = p2.value

        assert_true(inbreeding_val > famine_val, "inbreeding should add more pressure than famine")
    end)

    it("decay reduces pressure by 20%", function()
        local p = Mutation.new_pressure()
        p.value = 100
        Mutation.decay(p)
        assert_equal(80, p.value)
        Mutation.decay(p)
        -- 80 * 0.8 = 64
        assert_equal(64, p.value)
    end)

    it("apply mutates some traits under high pressure", function()
        rng.seed(33333)
        local g = Genome.new()
        local p = Mutation.new_pressure()
        p.value = 200  -- Very high pressure

        -- Record original values
        local originals = {}
        for id, trait in pairs(g.traits) do
            originals[id] = trait:get_value()
        end

        local _, mutations = Mutation.apply(g, p)

        -- With pressure 200, effective chance = 0.02 + 0.2 = 0.22 per trait
        -- We expect some mutations to have occurred
        assert_true(#mutations > 0, "should have at least one mutation at high pressure")
    end)

    it("apply produces no mutations at zero pressure (mostly)", function()
        rng.seed(44444)
        local g = Genome.new()
        local p = Mutation.new_pressure()
        p.value = 0  -- Zero additional pressure

        local _, mutations = Mutation.apply(g, p)
        -- Base 2% chance per trait, 70 traits = ~1.4 expected mutations
        -- Could be 0, but very unlikely to be many
        assert_true(#mutations < 10, "should have very few mutations at zero pressure")
    end)

    it("mutated trait values stay in 0-100 range", function()
        rng.seed(55555)
        local g = Genome.new()
        local p = Mutation.new_pressure()
        p.value = 300  -- Extreme pressure

        Mutation.apply(g, p)

        for id, trait in pairs(g.traits) do
            assert_in_range(trait:get_value(), 0, 100, "post-mutation " .. id)
        end
    end)

end)
