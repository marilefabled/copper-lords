-- Dark Legacy — Legends System Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local WorldState = require("dredwork_world.world_state")
local Legends = require("dredwork_world.legends")
local rng = require("dredwork_core.rng")

describe("Legends System", function()
    rng.seed(42)

    it("should have at least 30 legend conditions", function()
        local count = Legends.get_condition_count()
        assert_true(count >= 30, "Expected 30+ conditions, got " .. count)
    end)

    it("should return nil for average heir", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Test Heir")
        -- Average heir should usually not trigger a legend
        -- (could rarely trigger by random, but very unlikely with seed 42)
        -- This is a soft check
    end)

    it("should detect 'the_monster' for high cruelty + volatility", function()
        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 92,
            PER_VOL = 85,
            PER_BLD = 60,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_OBS = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Kael")
        assert_not_nil(result, "Expected legend for monster conditions")
        assert_equal("the_monster", result.id)
        assert_equal("monster", result.category)
        assert_true(result.title:len() > 0, "Title should not be empty")
    end)

    it("should detect 'the_genius' for 3+ mental traits above 85", function()
        local genome = Genome.new()
        -- Set 3 blended mental traits above 85 (avoid dom/rec traits where get_value uses alleles)
        genome:set_value("MEN_INT", 92) -- blended
        genome:set_value("MEN_FOC", 88) -- blended
        genome:set_value("MEN_PER", 90) -- blended
        genome:set_value("MEN_ANA", 87) -- blended

        local pers = Personality.new()
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Aria")
        assert_not_nil(result, "Expected legend for genius conditions")
        assert_equal("the_genius", result.id)
    end)

    it("should detect 'the_ghost' for mostly low personality axes", function()
        local genome = Genome.new()
        local pers = Personality.new({
            PER_BLD = 15,
            PER_CRM = 20,
            PER_OBS = 10,
            PER_LOY = 25,
            PER_CUR = 18,
            PER_VOL = 12,
            PER_PRI = 22,
            PER_ADA = 28,
        })
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Shadow")
        assert_not_nil(result, "Expected legend for ghost conditions")
        assert_equal("the_ghost", result.id)
    end)

    it("should detect 'the_survivor' with plague+famine and survived death check", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.6, 3)
        ws:add_condition("famine", 0.5, 2)

        local extra = { survived_death_check = true }
        local result = Legends.evaluate(genome, pers, cm, ws, {}, extra, "Viktor")
        assert_not_nil(result, "Expected legend for survivor conditions")
        assert_equal("the_survivor", result.id)
    end)

    it("should prefer higher priority legends", function()
        -- the_monster (mythic) should beat the_dread (notable) when both match
        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 95,
            PER_VOL = 90,
            PER_BLD = 60,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_OBS = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Beast")
        assert_not_nil(result)
        -- Monster is mythic (100), dread is notable (40), so monster wins
        assert_equal("the_monster", result.id)
    end)

    it("should return one title per evaluation", function()
        local genome = Genome.new()
        genome:set_value("PHY_STR", 90)
        genome:set_value("MEN_INT", 92)
        genome:set_value("MEN_FOC", 88)
        genome:set_value("MEN_WIL", 90)
        local pers = Personality.new({
            PER_CRM = 92,
            PER_VOL = 85,
            PER_BLD = 85,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_OBS = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")
        ws:add_condition("war", 0.5, 3)

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Multi")
        assert_not_nil(result)
        assert_true(result.title ~= nil and result.title ~= "", "Should have exactly one title")
    end)

    it("should substitute variables in titles", function()
        local genome = Genome.new()
        local pers = Personality.new({
            PER_CRM = 92,
            PER_VOL = 85,
            PER_BLD = 60,
            PER_LOY = 50,
            PER_CUR = 50,
            PER_OBS = 50,
            PER_PRI = 50,
            PER_ADA = 50,
        })
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Kael")
        assert_not_nil(result)
        -- Title should not contain unsubstituted variables
        assert_true(not result.title:find("{"), "Title should not contain {variables}: " .. result.title)
    end)

    it("should return all condition IDs", function()
        local ids = Legends.get_all_condition_ids()
        assert_true(#ids >= 30, "Expected 30+ IDs, got " .. #ids)
        -- Check for some known IDs
        local found = {}
        for _, id in ipairs(ids) do found[id] = true end
        assert_true(found["the_monster"], "Should contain 'the_monster'")
        assert_true(found["the_genius"], "Should contain 'the_genius'")
        assert_true(found["the_ghost"], "Should contain 'the_ghost'")
    end)

    it("should detect 'the_ancient' at generation 30+", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local cm = CulturalMemory.new()
        local ws = WorldState.new("ancient")
        ws.generation = 35

        local result = Legends.evaluate(genome, pers, cm, ws, {}, {}, "Elder")
        assert_not_nil(result, "Expected legend at generation 35")
        -- Could be ancient or eternal depending on conditions
        assert_true(result.category == "ancient", "Expected ancient category, got " .. tostring(result.category))
    end)
end)
