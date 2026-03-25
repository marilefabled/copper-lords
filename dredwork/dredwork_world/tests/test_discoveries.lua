-- Dark Legacy — Discoveries Tests

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Discoveries = require("dredwork_world.discoveries")

describe("Discoveries", function()
    it("creates empty tracker", function()
        local d = Discoveries.new()
        assert_equal(0, d:count())
    end)

    it("finds available discoveries matching era and traits", function()
        local g = Genome.new({ CRE_CRA = 70 })
        local d = Discoveries.new()
        local avail = d:get_available(g, "ancient")
        local found = false
        for _, def in ipairs(avail) do
            if def.id == "fire_mastery" then found = true end
        end
        assert_true(found, "fire_mastery should be available with CRE_CRA=70 in ancient")
    end)

    it("does not show discoveries from wrong era", function()
        local g = Genome.new({ CRE_CRA = 70 })
        local d = Discoveries.new()
        local avail = d:get_available(g, "iron")
        local found = false
        for _, def in ipairs(avail) do
            if def.id == "fire_mastery" then found = true end
        end
        assert_true(not found, "fire_mastery should not be available in iron era")
    end)

    it("does not show already-unlocked discoveries", function()
        local g = Genome.new({ CRE_CRA = 70 })
        local d = Discoveries.new()
        d:unlock("fire_mastery", 5, "Kael")
        local avail = d:get_available(g, "ancient")
        for _, def in ipairs(avail) do
            assert_true(def.id ~= "fire_mastery", "unlocked discovery should not appear")
        end
    end)

    it("unlock stores generation and heir name", function()
        local d = Discoveries.new()
        d:unlock("ironworking", 15, "Thane")
        assert_equal(1, d:count())
        local unlocked = d:get_unlocked()
        assert_equal(1, #unlocked)
        assert_equal("ironworking", unlocked[1].definition.id)
        assert_equal(15, unlocked[1].unlock_data.generation)
    end)

    it("get_effects aggregates trait bonuses", function()
        local d = Discoveries.new()
        d:unlock("ironworking", 10)
        d:unlock("fire_mastery", 5)
        local effects = d:get_effects()
        assert_true(effects.trait_bonuses["PHY_STR"] ~= nil, "should have PHY_STR bonus")
        assert_true(effects.trait_bonuses["PHY_STR"] >= 5, "PHY_STR bonus should be >= 5")
        assert_true(effects.trait_bonuses["PHY_END"] ~= nil, "should have PHY_END bonus")
    end)

    it("get_effects aggregates mutation_pressure_reduction", function()
        local d = Discoveries.new()
        d:unlock("stargazing", 5)
        d:unlock("arcane_theory", 20)
        local effects = d:get_effects()
        assert_true(effects.mutation_pressure_reduction >= 8,
            "should combine pressure reductions")
    end)

    it("serializes and deserializes correctly", function()
        local d = Discoveries.new()
        d:unlock("ironworking", 10, "Kael")
        d:unlock("banking", 30, "Thane")
        local data = d:to_table()
        local restored = Discoveries.from_table(data)
        assert_equal(2, restored:count())
        local unlocked = restored:get_unlocked()
        assert_equal(2, #unlocked)
    end)

    it("does not find discoveries when traits too low", function()
        local g = Genome.new({ CRE_CRA = 30 })
        local d = Discoveries.new()
        local avail = d:get_available(g, "ancient")
        for _, def in ipairs(avail) do
            assert_true(def.id ~= "fire_mastery",
                "fire_mastery should not be available with low CRE_CRA")
        end
    end)

    it("has definitions for all 6 eras", function()
        local eras_covered = {}
        for _, def in ipairs(Discoveries.definitions) do
            eras_covered[def.era] = true
        end
        assert_true(eras_covered["ancient"], "should have ancient discoveries")
        assert_true(eras_covered["iron"], "should have iron discoveries")
        assert_true(eras_covered["dark"], "should have dark discoveries")
        assert_true(eras_covered["arcane"], "should have arcane discoveries")
        assert_true(eras_covered["gilded"], "should have gilded discoveries")
        assert_true(eras_covered["twilight"], "should have twilight discoveries")
    end)
end)
