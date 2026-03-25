-- Dark Legacy — Cross-Run Echoes Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local CrossRun = require("dredwork_world.cross_run")

describe("CrossRun", function()

    it("returns nil whisper on first run (no history)", function()
        CrossRun.init(nil, nil)
        local result = CrossRun.get_whisper("iron", 5)
        assert_nil(result, "should be nil with no past runs")
    end)

    it("returns nil faction memory on first run", function()
        CrossRun.init(nil, {})
        local result = CrossRun.get_faction_memory("varen")
        assert_nil(result, "should be nil with no past runs")
    end)

    it("returns nil ghost event on first run", function()
        CrossRun.init(nil, nil)
        local result = CrossRun.get_ghost_event(10, "iron")
        assert_nil(result, "should be nil with no past runs")
    end)

    it("generates whisper with past run data", function()
        CrossRun.init(nil, {
            { status = "complete", lineage_name = "House Ironblood", generations = 15,
              final_reputation = "warriors", final_era = "iron" },
        })
        CrossRun._reset()
        -- Try multiple times since templates are random
        local found = false
        for _ = 1, 20 do
            local result = CrossRun.get_whisper("iron", 100)
            if result then
                found = true
                assert_true(type(result) == "string", "whisper should be a string")
                break
            end
            CrossRun._reset()
        end
        assert_true(found, "should eventually generate a whisper")
    end)

    it("rate-limits whispers by generation gap", function()
        CrossRun.init(nil, {
            { status = "complete", lineage_name = "House Test", generations = 10,
              final_reputation = "scholars", final_era = "arcane" },
        })
        CrossRun._reset()
        -- Get a whisper at gen 10
        local first = nil
        for _ = 1, 20 do
            first = CrossRun.get_whisper("iron", 10)
            if first then break end
            CrossRun._reset()
        end
        -- Immediately try gen 11 (within MIN_GAP of 5)
        if first then
            local second = CrossRun.get_whisper("iron", 11)
            assert_nil(second, "should be rate-limited within MIN_GAP")
        end
    end)

    it("generates faction memory with past data", function()
        CrossRun.init(nil, {
            { status = "complete", lineage_name = "House Stormborn", generations = 20,
              final_reputation = "tyrants", final_era = "dark" },
        })
        local found = false
        for _ = 1, 20 do
            local result = CrossRun.get_faction_memory("varen")
            if result then
                found = true
                assert_true(type(result) == "string", "faction memory should be a string")
                break
            end
        end
        assert_true(found, "should eventually generate a faction memory")
    end)

    it("ghost event has correct structure", function()
        CrossRun.init(nil, {
            { status = "complete", lineage_name = "House Ashfall", generations = 25,
              final_reputation = "scholars", final_era = "arcane" },
        })
        CrossRun._reset()
        local event = nil
        for _ = 1, 50 do
            event = CrossRun.get_ghost_event(100, "iron")
            if event then break end
            CrossRun._reset()
        end
        if event then
            assert_not_nil(event.id, "event should have id")
            assert_not_nil(event.title, "event should have title")
            assert_not_nil(event.narrative, "event should have narrative")
            assert_equal("legacy", event.type, "event type should be legacy")
            assert_equal("legacy", event.pool, "event pool should be legacy")
            assert_not_nil(event.options, "event should have options")
            assert_true(#event.options >= 1, "event should have at least 1 option")
        end
    end)

    it("filters incomplete runs from history", function()
        CrossRun.init(nil, {
            { status = "abandoned", lineage_name = "House Abandoned", generations = 5 },
            { status = "complete", lineage_name = "House Valid", generations = 12,
              final_reputation = "warriors", final_era = "iron" },
            { status = "complete", lineage_name = nil, generations = 8 }, -- no name
        })
        CrossRun._reset()
        local found = false
        for _ = 1, 30 do
            local result = CrossRun.get_whisper("iron", 100)
            if result and result:find("Valid") then
                found = true
                break
            end
            CrossRun._reset()
        end
        assert_true(found, "should only reference complete runs with data")
    end)
end)
