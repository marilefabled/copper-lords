-- Dark Legacy — Epitaphs + Foreshadowing Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local WorldState = require("dredwork_world.world_state")
local Epitaphs = require("dredwork_world.epitaphs")
local rng = require("dredwork_core.rng")

describe("Epitaphs System", function()
    rng.seed(42)

    it("should generate an epitaph for any heir", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()

        local result = Epitaphs.generate(genome, pers, cm, {}, nil, "Kael", nil)
        assert_not_nil(result, "Epitaph should not be nil")
        assert_true(type(result) == "string", "Epitaph should be a string")
        assert_true(#result > 0, "Epitaph should not be empty")
    end)

    it("should include heir name in epitaph", function()
        local genome = Genome.new()
        local pers = Personality.new({
            PER_BLD = 90,
            PER_CRM = 50,
            PER_OBS = 50,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_VOL = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })
        local cm = CulturalMemory.new()

        local result = Epitaphs.generate(genome, pers, cm, {}, nil, "Aria", nil)
        assert_true(result:find("Aria") ~= nil, "Epitaph should contain heir name: " .. result)
    end)

    it("should generate death-cause epitaph when heir died", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()

        local result = Epitaphs.generate(genome, pers, cm, {}, nil, "Kael", "plague")
        assert_not_nil(result)
        assert_true(#result > 0, "Death epitaph should not be empty")
    end)

    it("should reference legend title if provided", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()

        -- Run multiple times to increase chance of hitting legend template
        local found_legend_ref = false
        for i = 1, 20 do
            rng.seed(42 + i)
            local result = Epitaphs.generate(genome, pers, cm, {}, "The Butcher", "Kael", nil)
            if result:find("Butcher") then
                found_legend_ref = true
                break
            end
        end
        -- At least sometimes the legend should be referenced
        assert_true(found_legend_ref, "Legend title should sometimes appear in epitaph")
    end)

    it("should generate event-based epitaph for plague survivor", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()

        local found_plague_ref = false
        for i = 1, 20 do
            rng.seed(42 + i)
            local result = Epitaphs.generate(genome, pers, cm, { survived_plague = true }, nil, "Kael", nil)
            if result:lower():find("plague") or result:lower():find("endured") or result:lower():find("sickness") then
                found_plague_ref = true
                break
            end
        end
        assert_true(found_plague_ref, "Plague survivor epitaph should sometimes reference plague")
    end)
end)

describe("Foreshadowing System", function()
    rng.seed(42)

    it("should return empty table when no conditions warrant foreshadowing", function()
        local ws = WorldState.new("ancient")
        local cm = CulturalMemory.new()
        local genome = Genome.new()

        local result = Epitaphs.foreshadow(ws, cm, genome, {})
        assert_not_nil(result)
        assert_true(type(result) == "table", "Should return a table")
    end)

    it("should foreshadow plague when plague is active with remaining gens", function()
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.7, 4)
        local cm = CulturalMemory.new()
        local genome = Genome.new()

        local result = Epitaphs.foreshadow(ws, cm, genome, {})
        assert_true(#result >= 1, "Should have at least one foreshadow line")
        local found = false
        for _, line in ipairs(result) do
            if line:lower():find("plague") then found = true end
        end
        assert_true(found, "Should mention plague in foreshadowing")
    end)

    it("should foreshadow low vitality", function()
        local ws = WorldState.new("ancient")
        local cm = CulturalMemory.new()
        local genome = Genome.new()
        genome:set_value("PHY_VIT", 15)

        local result = Epitaphs.foreshadow(ws, cm, genome, {})
        assert_true(#result >= 1, "Should foreshadow low vitality")
        local found = false
        for _, line in ipairs(result) do
            if line:lower():find("frail") or line:lower():find("constitution") then found = true end
        end
        assert_true(found, "Should mention frailty")
    end)

    it("should cap at 2 foreshadow lines", function()
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.7, 4)
        ws:add_condition("famine", 0.6, 3)
        ws:add_condition("war", 0.5, 3)
        local cm = CulturalMemory.new()
        -- Add taboos to trigger more lines
        cm:add_taboo("test1", 1, "taboo1", 80)
        cm:add_taboo("test2", 2, "taboo2", 80)
        cm:add_taboo("test3", 3, "taboo3", 80)
        local genome = Genome.new()
        genome:set_value("PHY_VIT", 10)
        genome:set_value("PHY_FER", 10)

        local result = Epitaphs.foreshadow(ws, cm, genome, {})
        assert_true(#result <= 2, "Should cap at 2 lines, got " .. #result)
    end)

    it("should handle nil world_state gracefully", function()
        local cm = CulturalMemory.new()
        local genome = Genome.new()

        local result = Epitaphs.foreshadow(nil, cm, genome, {})
        assert_not_nil(result)
        assert_true(type(result) == "table")
    end)
end)
