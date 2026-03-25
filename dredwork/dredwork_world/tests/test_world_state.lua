-- Dark Legacy — World State Tests

local rng = require("dredwork_core.rng")
local WorldState = require("dredwork_world.world_state")
local Mutation = require("dredwork_genetics.mutation")

rng.seed(12345)

describe("WorldState", function()

    it("creates with default era", function()
        local ws = WorldState.new()
        assert_equal("ancient", ws.current_era_key)
        assert_equal(0, ws.generation)
        assert_equal(0, ws.generations_in_era)
        assert_equal(0, #ws.conditions)
    end)

    it("creates with specified era", function()
        local ws = WorldState.new("iron")
        assert_equal("iron", ws.current_era_key)
        assert_equal("The Red Tithe", ws:get_era_name())
    end)

    it("adds and tracks conditions", function()
        local ws = WorldState.new()
        ws:add_condition("plague", 0.5, 3)
        assert_true(ws:has_condition("plague"))
        assert_true(not ws:has_condition("war"))
        assert_equal(1, #ws:get_active_condition_types())
    end)

    it("stacks conditions by refreshing existing", function()
        local ws = WorldState.new()
        ws:add_condition("plague", 0.3, 2)
        ws:add_condition("plague", 0.6, 5)
        -- Should have 1 condition with max intensity and duration
        assert_equal(1, #ws.conditions)
        local cond = ws:get_condition("plague")
        assert_not_nil(cond)
        assert_equal(0.6, cond.intensity)
        assert_equal(5, cond.remaining_gens)
    end)

    it("removes conditions", function()
        local ws = WorldState.new()
        ws:add_condition("war", 0.5, 3)
        ws:remove_condition("war")
        assert_true(not ws:has_condition("war"))
    end)

    it("advances generation and ticks conditions down", function()
        local ws = WorldState.new()
        ws:add_condition("plague", 0.5, 2)
        local pressure = Mutation.new_pressure()
        ws:advance({ mutation_pressure = pressure })
        assert_equal(1, ws.generation)
        -- Plague should have 1 gen remaining
        local cond = ws:get_condition("plague")
        assert_not_nil(cond)
        assert_equal(1, cond.remaining_gens)
    end)

    it("expires conditions when duration reaches 0", function()
        local ws = WorldState.new()
        ws:add_condition("famine", 0.4, 1)
        local pressure = Mutation.new_pressure()
        local results = ws:advance({ mutation_pressure = pressure })
        -- Famine should be expired
        assert_true(not ws:has_condition("famine"))
        assert_equal(1, #results.expired_conditions)
        assert_equal("famine", results.expired_conditions[1])
    end)

    it("applies ambient era pressure", function()
        local ws = WorldState.new("iron") -- iron has war 0.4
        local pressure = Mutation.new_pressure()
        local results = ws:advance({ mutation_pressure = pressure })
        assert_true(pressure.value > 0, "pressure should increase from ambient")
        assert_true(#results.ambient_applied > 0)
    end)

    it("manages chronicle entries", function()
        local ws = WorldState.new()
        ws:add_chronicle("The plague came.")
        ws:add_chronicle("The wars ended.")
        local entries = ws:get_chronicle()
        assert_equal(2, #entries)
        assert_equal("The plague came.", entries[1].text)
    end)

    it("chronicle grows unbounded for storytelling", function()
        local ws = WorldState.new()
        for i = 1, 25 do
            ws:add_chronicle("Entry " .. i)
        end
        assert_equal(25, #ws.chronicle)
        -- All entries preserved
        assert_equal("Entry 1", ws.chronicle[1].text)
        assert_equal("Entry 25", ws.chronicle[25].text)
    end)

    it("serializes and deserializes", function()
        local ws = WorldState.new("arcane")
        ws:add_condition("plague", 0.5, 3)
        ws:add_chronicle("Test entry")
        ws.generation = 10
        ws.generations_in_era = 5

        local data = ws:to_table()
        local restored = WorldState.from_table(data)

        assert_equal("arcane", restored.current_era_key)
        assert_equal(10, restored.generation)
        assert_equal(5, restored.generations_in_era)
        assert_equal(1, #restored.conditions)
        assert_equal(1, #restored.chronicle)
    end)

    it("forces era transition at max generations", function()
        rng.seed(99999) -- consistent seed
        local ws = WorldState.new("ancient") -- max 20 gens
        local pressure = Mutation.new_pressure()
        pressure.value = 100 -- above threshold
        local ctx = { mutation_pressure = pressure }

        -- Advance past max generations
        local shifted = false
        for i = 1, 25 do
            ws.generations_in_era = ws.generations_in_era + 1
            local results = ws:advance(ctx)
            if results.era_shifted then
                shifted = true
                break
            end
        end
        -- Should have shifted by max_generations
        assert_true(shifted, "era should shift by max generations")
    end)
end)
