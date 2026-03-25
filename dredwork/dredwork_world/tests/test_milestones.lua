-- Dark Legacy — Milestones System Tests

local Genome = require("dredwork_genetics.genome")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local Milestones = require("dredwork_world.milestones")
local rng = require("dredwork_core.rng")

describe("Milestones System", function()
    rng.seed(42)

    it("should have at least 25 milestone definitions", function()
        local count = Milestones.get_total_count()
        assert_true(count >= 25, "Expected 25+ milestones, got " .. count)
    end)

    it("should detect iron_bloodline at generation 10", function()
        local result = Milestones.check({
            generation = 10,
            heir_genome = Genome.new(),
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "iron_bloodline" then found = true end
        end
        assert_true(found, "Should detect iron_bloodline at gen 10")
    end)

    it("should detect legendary_trait for trait value 90+", function()
        local genome = Genome.new()
        genome:set_value("PHY_STR", 95)

        local result = Milestones.check({
            generation = 5,
            heir_genome = genome,
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "legendary_trait" then found = true end
        end
        assert_true(found, "Should detect legendary_trait for 95 STR")
    end)

    it("should detect endured_plague during plague", function()
        local result = Milestones.check({
            generation = 3,
            heir_genome = Genome.new(),
            conditions = { { type = "plague", intensity = 0.5, remaining_gens = 2 } },
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "endured_plague" then found = true end
        end
        assert_true(found, "Should detect endured_plague")
    end)

    it("should not re-trigger already achieved milestones", function()
        local achieved = { { id = "iron_bloodline", generation = 10, title = "Iron Bloodline" } }

        local result = Milestones.check({
            generation = 15,
            heir_genome = Genome.new(),
        }, achieved)

        local found = false
        for _, m in ipairs(result) do
            if m.id == "iron_bloodline" then found = true end
        end
        assert_true(not found, "Should not re-trigger achieved milestone")
    end)

    it("should detect back_from_brink with high death chance", function()
        local result = Milestones.check({
            generation = 5,
            heir_genome = Genome.new(),
            heir_death_chance = 0.35,
            heir_died = false,
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "back_from_brink" then found = true end
        end
        assert_true(found, "Should detect back_from_brink")
    end)

    it("should detect the_black_sheep", function()
        local result = Milestones.check({
            generation = 5,
            heir_genome = Genome.new(),
            is_black_sheep = true,
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "the_black_sheep" then found = true end
        end
        assert_true(found, "Should detect the_black_sheep")
    end)

    it("should detect first_legend when legend is earned", function()
        local result = Milestones.check({
            generation = 5,
            heir_genome = Genome.new(),
            has_legend = true,
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "first_legend" then found = true end
        end
        assert_true(found, "Should detect first_legend")
    end)

    it("should detect genetic_collapse for 3+ traits below 25", function()
        local genome = Genome.new()
        genome:set_value("PHY_STR", 15)
        genome:set_value("PHY_VIT", 10)
        genome:set_value("PHY_END", 20)

        local result = Milestones.check({
            generation = 5,
            heir_genome = genome,
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "genetic_collapse" then found = true end
        end
        assert_true(found, "Should detect genetic_collapse")
    end)

    it("should return milestone data with correct fields", function()
        local result = Milestones.check({
            generation = 10,
            heir_genome = Genome.new(),
        }, {})

        assert_true(#result >= 1, "Should have at least 1 milestone at gen 10")
        local m = result[1]
        assert_not_nil(m.id, "Milestone should have id")
        assert_not_nil(m.title, "Milestone should have title")
        assert_not_nil(m.description, "Milestone should have description")
    end)

    it("should detect triple_threat with all 3 conditions", function()
        local result = Milestones.check({
            generation = 5,
            heir_genome = Genome.new(),
            conditions = {
                { type = "plague", intensity = 0.5, remaining_gens = 2 },
                { type = "famine", intensity = 0.5, remaining_gens = 2 },
                { type = "war", intensity = 0.5, remaining_gens = 2 },
            },
        }, {})

        local found = false
        for _, m in ipairs(result) do
            if m.id == "triple_threat" then found = true end
        end
        assert_true(found, "Should detect triple_threat")
    end)
end)
