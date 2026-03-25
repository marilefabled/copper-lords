-- Dark Legacy — Doctrines Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local Doctrines = require("dredwork_world.doctrines")
local CulturalMemory = require("dredwork_genetics.cultural_memory")

describe("Doctrines", function()

    it("returns empty array for non-milestone generations", function()
        local result = Doctrines.check_available(5, {}, CulturalMemory.new())
        assert_equal(0, #result, "gen 5 should have no doctrines")
    end)

    it("returns options at generation 7", function()
        local memory = CulturalMemory.new()
        memory.reputation = { primary = "warriors", secondary = "tyrants" }
        local result = Doctrines.check_available(7, {}, memory)
        assert_true(#result > 0, "gen 7 should offer doctrines")
        assert_true(#result <= 3, "should offer at most 3 doctrines")
    end)

    it("returns options at generation 15", function()
        local memory = CulturalMemory.new()
        memory.reputation = { primary = "scholars", secondary = "seekers" }
        local result = Doctrines.check_available(15, {}, memory)
        assert_true(#result > 0, "gen 15 should offer doctrines")
    end)

    it("returns options at generation 30", function()
        local memory = CulturalMemory.new()
        memory.reputation = { primary = "diplomats", secondary = "warriors" }
        local result = Doctrines.check_available(30, {}, memory)
        assert_true(#result > 0, "gen 30 should offer doctrines")
    end)

    it("filters out already adopted doctrines", function()
        local memory = CulturalMemory.new()
        memory.reputation = { primary = "warriors" }
        local existing = { { id = "blood_of_iron", generation_adopted = 7, title = "Blood of Iron" } }
        local result = Doctrines.check_available(15, existing, memory)
        for _, d in ipairs(result) do
            assert_true(d.id ~= "blood_of_iron", "should not offer already adopted doctrine")
        end
    end)

    it("does not offer doctrines twice at same milestone", function()
        local memory = CulturalMemory.new()
        local existing = { { id = "endurance_doctrine", generation_adopted = 7 } }
        local result = Doctrines.check_available(7, existing, memory)
        assert_equal(0, #result, "should not re-offer at same milestone")
    end)

    it("adopt adds doctrine to gameState", function()
        local state = { generation = 10, doctrines = {} }
        Doctrines.adopt("endurance_doctrine", state)
        assert_equal(1, #state.doctrines, "should have 1 adopted doctrine")
        assert_equal("endurance_doctrine", state.doctrines[1].id, "id should match")
        assert_equal(10, state.doctrines[1].generation_adopted, "generation should be set")
    end)

    it("get_modifier returns summed modifier values", function()
        local state = {
            generation = 10,
            doctrines = {
                { id = "endurance_doctrine", modifiers = { viability_bonus = 0.05 } },
                { id = "blood_of_iron", modifiers = { physical_inheritance_bias = 10, viability_bonus = 0 } },
            },
        }
        local bonus = Doctrines.get_modifier(state, "viability_bonus")
        assert_equal(0.05, bonus, "should sum viability bonus")
        local bias = Doctrines.get_modifier(state, "physical_inheritance_bias")
        assert_equal(10, bias, "should return physical bias")
    end)

    it("get_modifier returns 0 when no doctrines", function()
        local state = { doctrines = {} }
        assert_equal(0, Doctrines.get_modifier(state, "viability_bonus"), "empty should return 0")
    end)

    it("has_modifier returns true when boolean modifier exists", function()
        local state = {
            doctrines = {
                { id = "fortress_bloodline", modifiers = { condition_immunity = true } },
            },
        }
        assert_true(Doctrines.has_modifier(state, "condition_immunity"), "should find boolean modifier")
        assert_true(not Doctrines.has_modifier(state, "nonexistent"), "should not find missing modifier")
    end)

    it("get_active returns adopted doctrines", function()
        local state = {
            doctrines = {
                { id = "a", title = "A" },
                { id = "b", title = "B" },
            },
        }
        local active = Doctrines.get_active(state)
        assert_equal(2, #active, "should return 2 active doctrines")
    end)
end)
