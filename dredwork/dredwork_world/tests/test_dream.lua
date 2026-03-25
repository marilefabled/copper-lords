-- Dark Legacy — Bloodline Dream Tests

local Genome = require("dredwork_genetics.genome")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local BloodlineDream = require("dredwork_world.bloodline_dream")
local rng = require("dredwork_core.rng")

describe("Bloodline Dream System", function()
    rng.seed(42)

    local function make_memory_with_priority(trait_id, value)
        local cm = CulturalMemory.new()
        cm.trait_priorities[trait_id] = value
        return cm
    end

    it("should generate a dream from cultural memory", function()
        local cm = CulturalMemory.new()
        -- Set physical traits as highest priority
        cm.trait_priorities.PHY_STR = 75
        cm.trait_priorities.PHY_VIT = 70

        local dream = BloodlineDream.generate(cm, 3)
        assert_not_nil(dream, "Should generate a dream")
        assert_not_nil(dream.trait_id, "Dream should have trait_id")
        assert_not_nil(dream.category, "Dream should have category")
        assert_equal("active", dream.status, "Dream should be active")
        assert_equal(3, dream.start_generation, "Start generation should be 3")
        assert_equal(8, dream.deadline_generation, "Deadline should be start + 5")
    end)

    it("should set target_value to priority + 15, clamped to 100", function()
        local cm = CulturalMemory.new()
        cm.trait_priorities.PHY_STR = 90

        local dream = BloodlineDream.generate(cm, 5)
        assert_not_nil(dream, "Should generate a dream")
        assert_true(dream.target_value <= 100, "Target should not exceed 100")
    end)

    it("should detect fulfillment when heir meets target", function()
        local dream = {
            trait_id = "PHY_STR",
            trait_name = "Strength",
            category = "physical",
            target_value = 80,
            status = "active",
        }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 85)

        local fulfilled, narrative = BloodlineDream.check_fulfillment(dream, genome)
        assert_true(fulfilled, "Should detect fulfillment")
        assert_true(#narrative > 0, "Should return narrative")
    end)

    it("should not fulfill when heir is below target", function()
        local dream = {
            trait_id = "PHY_STR",
            trait_name = "Strength",
            category = "physical",
            target_value = 80,
            status = "active",
        }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 60)

        local fulfilled, _ = BloodlineDream.check_fulfillment(dream, genome)
        assert_true(not fulfilled, "Should not fulfill below target")
    end)

    it("should mutate dream to different category on expiry", function()
        local expired_dream = {
            trait_id = "PHY_STR",
            category = "physical",
            status = "active",
        }
        local cm = CulturalMemory.new()
        cm.trait_priorities.MEN_INT = 65
        cm.trait_priorities.SOC_CHA = 60

        local new_dream = BloodlineDream.mutate(expired_dream, cm, 10)
        assert_not_nil(new_dream, "Should generate new dream")
        assert_true(new_dream.category ~= "physical", "New dream should be different category")
        assert_equal(10, new_dream.start_generation, "New dream should start at current gen")
    end)

    it("should return fulfillment consequences", function()
        local dream = { trait_id = "PHY_STR", category = "physical" }
        local consequences = BloodlineDream.get_fulfillment_consequences(dream)
        assert_not_nil(consequences.cultural_memory_shift, "Should have cultural memory shift")
        assert_equal(-10, consequences.mutation_pressure_delta, "Should reduce mutation pressure")
    end)

    it("should return display info for active dream", function()
        local dream = {
            trait_id = "PHY_STR",
            trait_name = "Strength",
            category = "physical",
            target_value = 80,
            description = "The blood dreams of legendary Strength.",
            start_generation = 5,
            deadline_generation = 10,
            status = "active",
        }
        local genome = Genome.new()
        genome:set_value("PHY_STR", 60)

        local display_data = BloodlineDream.get_display(dream, genome, 7)
        assert_not_nil(display_data, "Should return display data")
        assert_equal(3, display_data.gens_remaining, "Should have 3 gens remaining")
        assert_true(display_data.progress_pct > 0, "Progress should be positive")
    end)

    it("should return nil display for non-active dream", function()
        local dream = { status = "fulfilled" }
        local display_data = BloodlineDream.get_display(dream, Genome.new(), 5)
        assert_nil(display_data, "Should return nil for non-active dream")
    end)

    it("should handle nil cultural memory gracefully", function()
        local dream = BloodlineDream.generate(nil, 5)
        assert_nil(dream, "Should return nil for nil cultural memory")
    end)
end)
