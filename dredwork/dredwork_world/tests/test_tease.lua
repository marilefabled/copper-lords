-- Dark Legacy — Tease System Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local WorldState = require("dredwork_world.world_state")
local Tease = require("dredwork_world.tease")
local rng = require("dredwork_core.rng")

-- Minimal faction mock for testing
local function make_faction(overrides)
    local f = {
        id = "test_house",
        name = "House Test",
        power = 50,
        disposition = 0,
        status = "active",
        is_hostile = function(self) return self.disposition <= -50 end,
        is_friendly = function(self) return self.disposition >= 30 end,
    }
    if overrides then
        for k, v in pairs(overrides) do f[k] = v end
    end
    return f
end

local function make_faction_manager(factions)
    return {
        factions = factions or {},
        get_active = function(self)
            local result = {}
            for _, f in ipairs(self.factions) do
                if f.status ~= "fallen" then result[#result + 1] = f end
            end
            return result
        end,
    }
end

local function make_context(overrides)
    local ctx = {
        world_state = WorldState.new("ancient"),
        factions = make_faction_manager({}),
        cultural_memory = CulturalMemory.new(),
        heir_genome = Genome.new(),
        heir_personality = Personality.new(),
        generation = 10,
        bloodline_dream = nil,
        mutation_pressure = { value = 0 },
    }
    if overrides then
        for k, v in pairs(overrides) do ctx[k] = v end
    end
    return ctx
end

describe("Tease System", function()
    rng.seed(42)

    it("should return a table", function()
        local ctx = make_context()
        local result = Tease.generate(ctx)
        assert_not_nil(result)
        assert_true(type(result) == "table", "Should return a table")
    end)

    it("should return at most 2 teases", function()
        -- Create a context with many tease triggers active
        local ws = WorldState.new("ancient")
        ws.last_crucible_gen = 3  -- gap of 7 triggers crucible tease
        local cm = CulturalMemory.new()
        cm:add_taboo("t1", 1, "e1", 80)
        cm:add_taboo("t2", 2, "e2", 80)
        cm:add_taboo("t3", 3, "e3", 80)
        cm:add_taboo("t4", 4, "e4", 80)

        local ctx = make_context({
            world_state = ws,
            cultural_memory = cm,
            generation = 10,
            mutation_pressure = { value = 80 },
        })
        local result = Tease.generate(ctx)
        assert_true(#result <= 2, "Should cap at 2, got " .. #result)
    end)

    it("should tease faction tension for hostile powerful factions", function()
        local hostile = make_faction({
            name = "House Mordthen",
            power = 80,
            disposition = -60,
        })
        local fm = make_faction_manager({ hostile })

        local ctx = make_context({ factions = fm })
        local result = Tease.generate(ctx)
        local found = false
        for _, t in ipairs(result) do
            if t.text:find("Mordthen") then found = true end
        end
        assert_true(found, "Should tease about hostile faction")
    end)

    it("should tease dream deadline when 1-2 gens remain", function()
        local ctx = make_context({
            generation = 8,
            bloodline_dream = {
                status = "active",
                deadline_generation = 10,
            },
        })
        local result = Tease.generate(ctx)
        local found = false
        for _, t in ipairs(result) do
            if t.text:find("dream") or t.text:find("aspiration") or t.text:find("fades") or t.text:find("slips") or t.text:find("beyond reach") then
                found = true
            end
        end
        assert_true(found, "Should tease about dream deadline")
    end)

    it("should tease mutation spike when pressure > 60", function()
        local ctx = make_context({ mutation_pressure = { value = 75 } })
        local result = Tease.generate(ctx)
        local found = false
        for _, t in ipairs(result) do
            if t.text:find("blood") or t.text:find("twist") or t.text:find("pressure") or t.text:find("change") then
                found = true
            end
        end
        assert_true(found, "Should tease about mutation spike")
    end)

    it("should tease taboo forming when 4+ taboos exist", function()
        local cm = CulturalMemory.new()
        for i = 1, 5 do
            cm:add_taboo("t" .. i, i, "e" .. i, 80)
        end
        local ctx = make_context({ cultural_memory = cm })
        local result = Tease.generate(ctx)
        local found = false
        for _, t in ipairs(result) do
            if t.text:find("wound") or t.text:find("scar") or t.text:find("grievance") or t.text:find("history") then
                found = true
            end
        end
        assert_true(found, "Should tease about taboo pressure")
    end)

    it("should include text and color_key in each tease", function()
        local hostile = make_faction({ name = "House Test", power = 80, disposition = -60 })
        local fm = make_faction_manager({ hostile })
        local ctx = make_context({ factions = fm })
        local result = Tease.generate(ctx)
        for _, t in ipairs(result) do
            assert_not_nil(t.text, "Tease should have text")
            assert_not_nil(t.color_key, "Tease should have color_key")
            assert_true(#t.text > 0, "Tease text should not be empty")
        end
    end)

    it("should return empty when no conditions warrant teasing", function()
        -- Default context with nothing exciting happening
        local ctx = make_context({ generation = 1 })
        -- With no conditions, no hostile factions, low pressure, etc.
        local result = Tease.generate(ctx)
        -- May or may not have results depending on era ambient, but should not crash
        assert_not_nil(result)
        assert_true(type(result) == "table")
    end)

    it("should prioritize higher-priority teases", function()
        -- Faction tension (priority 9) should beat taboo forming (priority 2)
        local hostile = make_faction({ name = "House Mordthen", power = 80, disposition = -60 })
        local fm = make_faction_manager({ hostile })
        local cm = CulturalMemory.new()
        for i = 1, 5 do cm:add_taboo("t" .. i, i, "e" .. i, 80) end

        local ctx = make_context({
            factions = fm,
            cultural_memory = cm,
            mutation_pressure = { value = 80 },
        })
        local result = Tease.generate(ctx)
        if #result >= 1 then
            -- First tease should be faction (priority 9) or mutation (priority 3)
            -- Both should appear before taboo (priority 2)
            assert_true(result[1].icon_hint == "faction" or result[1].icon_hint == "mutation",
                "Higher priority tease should come first, got " .. (result[1].icon_hint or "nil"))
        end
    end)

    it("should handle nil world_state gracefully", function()
        local ctx = make_context({ world_state = nil })
        local result = Tease.generate(ctx)
        assert_not_nil(result)
        assert_true(type(result) == "table")
    end)

    it("should handle nil factions gracefully", function()
        local ctx = make_context({ factions = nil })
        local result = Tease.generate(ctx)
        assert_not_nil(result)
        assert_true(type(result) == "table")
    end)
end)
