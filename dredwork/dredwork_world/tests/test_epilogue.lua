-- Dark Legacy — Epilogue Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local Epilogue = require("dredwork_world.epilogue")

describe("Epilogue", function()

    it("generates paragraphs for a basic run", function()
        local result = Epilogue.generate({
            lineage_name = "House Ironblood",
            final_generation = 15,
            cause_of_death = "plague",
            final_era = "iron",
            final_reputation = "warriors",
        })
        assert_not_nil(result, "result should exist")
        assert_not_nil(result.paragraphs, "paragraphs should exist")
        assert_true(#result.paragraphs >= 2, "should have at least 2 paragraphs")
        assert_not_nil(result.tone, "tone should exist")
    end)

    it("determines tragic tone for short runs", function()
        local tone = Epilogue.determine_tone({ final_generation = 3, cause_of_death = "plague" })
        assert_equal("tragic", tone, "short run should be tragic")
    end)

    it("determines epic tone for long runs", function()
        local tone = Epilogue.determine_tone({ final_generation = 40, cause_of_death = "war" })
        assert_equal("epic", tone, "long run should be epic")
    end)

    it("determines ironic tone for madness death after 10+ gens", function()
        local tone = Epilogue.determine_tone({
            final_generation = 15,
            cause_of_death = "madness",
            final_reputation = "warriors",
        })
        assert_equal("ironic", tone, "madness death should be ironic")
    end)

    it("determines forgotten tone for unknown reputation", function()
        local tone = Epilogue.determine_tone({
            final_generation = 8,
            cause_of_death = "natural_frailty",
            final_reputation = "unknown",
        })
        assert_equal("forgotten", tone, "unknown reputation should be forgotten")
    end)

    it("substitutes lineage name in templates", function()
        local result = Epilogue.generate({
            lineage_name = "TestHouse",
            final_generation = 5,
            cause_of_death = "plague",
        })
        local found = false
        for _, p in ipairs(result.paragraphs) do
            if p:find("TestHouse") then found = true; break end
        end
        assert_true(found, "lineage name should appear in paragraphs")
    end)

    it("handles nil run data gracefully", function()
        local result = Epilogue.generate(nil)
        assert_not_nil(result, "should not error on nil")
        assert_not_nil(result.paragraphs, "should have paragraphs array")
    end)

    it("handles empty run data", function()
        local result = Epilogue.generate({})
        assert_not_nil(result, "should handle empty data")
        assert_not_nil(result.tone, "should determine a tone")
    end)

    it("includes closer based on cause of death", function()
        local result = Epilogue.generate({
            lineage_name = "House Test",
            final_generation = 20,
            cause_of_death = "no_children",
            final_era = "dark",
        })
        assert_true(#result.paragraphs >= 2, "should have closing paragraph")
    end)
end)
