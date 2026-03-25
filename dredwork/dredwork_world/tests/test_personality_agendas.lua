-- Tests for personality_agendas.lua

local rng = require("dredwork_core.rng")
local PersonalityAgendas = require("dredwork_world.personality_agendas")

describe("PersonalityAgendas — generation", function()
    it("returns empty for nil personality", function()
        local result = PersonalityAgendas.generate(nil, 1)
        assert_equal(0, #result)
    end)

    it("returns empty for neutral personality", function()
        local personality = { axes = {
            PER_BLD = 50, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        }}
        local result = PersonalityAgendas.generate(personality, 1)
        assert_equal(0, #result, "neutral personality should produce no agendas")
    end)

    it("returns agenda for extreme high axis", function()
        local personality = { axes = {
            PER_BLD = 80, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        }}
        local result = PersonalityAgendas.generate(personality, 1)
        assert_true(#result >= 1, "should produce at least 1 agenda")
        assert_equal("PER_BLD", result[1].axis)
    end)

    it("returns agenda for extreme low axis", function()
        local personality = { axes = {
            PER_BLD = 20, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        }}
        local result = PersonalityAgendas.generate(personality, 1)
        assert_true(#result >= 1)
        assert_equal("fortification", result[1].id)
    end)

    it("caps at 2 agendas", function()
        local personality = { axes = {
            PER_BLD = 90, PER_CRM = 10, PER_OBS = 85, PER_LOY = 15,
            PER_CUR = 80, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        }}
        local result = PersonalityAgendas.generate(personality, 1)
        assert_true(#result <= 2, "should cap at 2 agendas, got " .. #result)
    end)

    it("stores generation_set", function()
        local personality = { axes = {
            PER_BLD = 80, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        }}
        local result = PersonalityAgendas.generate(personality, 7)
        assert_equal(7, result[1].generation_set)
    end)
end)

describe("PersonalityAgendas — evaluation", function()
    it("fulfills via council action signal", function()
        local agendas = {{
            id = "conquest", axis = "PER_BLD", label = "The March",
            signals = { "launch_campaign", "scorched_earth" },
            lp_reward = 4, fulfilled = false,
        }}
        local result = PersonalityAgendas.evaluate(agendas, { "launch_campaign" }, {})
        assert_equal(1, #result.fulfilled)
        assert_equal(0, #result.neglected)
    end)

    it("marks neglect when no matching actions", function()
        local agendas = {{
            id = "conquest", axis = "PER_BLD", label = "The March",
            signals = { "launch_campaign" },
            lp_reward = 4, fulfilled = false,
        }}
        local result = PersonalityAgendas.evaluate(agendas, { "consolidate" }, {})
        assert_equal(0, #result.fulfilled)
        assert_equal(1, #result.neglected)
    end)

    it("handles _any_two_distinct signal", function()
        local agendas = {{
            id = "versatility", axis = "PER_ADA", label = "The Restructuring",
            signals = { "_any_two_distinct" },
            lp_reward = 2, fulfilled = false,
        }}
        local result = PersonalityAgendas.evaluate(agendas, {}, { diplomacy = true, warfare = true })
        assert_equal(1, #result.fulfilled)
    end)

    it("_any_two_distinct fails with only 1 category", function()
        local agendas = {{
            id = "versatility", axis = "PER_ADA", label = "The Restructuring",
            signals = { "_any_two_distinct" },
            lp_reward = 2, fulfilled = false,
        }}
        local result = PersonalityAgendas.evaluate(agendas, {}, { diplomacy = true })
        assert_equal(0, #result.fulfilled)
        assert_equal(1, #result.neglected)
    end)

    it("handles nil agendas", function()
        local result = PersonalityAgendas.evaluate(nil, {}, {})
        assert_equal(0, #result.fulfilled)
        assert_equal(0, #result.neglected)
    end)
end)

describe("PersonalityAgendas — serialization", function()
    it("roundtrips via to_table/from_table", function()
        local agendas = {{
            id = "conquest", axis = "PER_BLD", axis_value = 80,
            label = "The March", description = "test",
            signals = { "launch_campaign" }, lp_reward = 4,
            generation_set = 5, fulfilled = false,
        }}
        local serialized = PersonalityAgendas.to_table(agendas)
        local restored = PersonalityAgendas.from_table(serialized)
        assert_equal(1, #restored)
        assert_equal("conquest", restored[1].id)
        assert_equal(80, restored[1].axis_value)
    end)

    it("to_table returns nil for nil input", function()
        assert_nil(PersonalityAgendas.to_table(nil))
    end)
end)

describe("PersonalityAgendas — display", function()
    it("returns display-ready data", function()
        local agendas = {{
            id = "conquest", label = "The March", description = "test", fulfilled = true,
        }}
        local d = PersonalityAgendas.get_display(agendas)
        assert_equal(1, #d)
        assert_equal("The March", d[1].label)
        assert_equal(true, d[1].fulfilled)
    end)

    it("handles nil input", function()
        local d = PersonalityAgendas.get_display(nil)
        assert_equal(0, #d)
    end)
end)
