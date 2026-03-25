-- Tests for rival_heirs.lua

local rng = require("dredwork_core.rng")
local rival_mod = require("dredwork_world.rival_heirs")
local RivalHeirs = rival_mod.RivalHeirs
local RivalHeirManager = rival_mod.RivalHeirManager
local faction_mod = require("dredwork_world.faction")
local FactionManager = faction_mod.FactionManager

describe("RivalHeirs", function()
    it("generates a rival heir from a faction", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local faction = factions:get_active()[1]
        local rival = RivalHeirs.generate(faction, 1)

        assert_not_nil(rival.name, "has name")
        assert_not_nil(rival.faction_id, "has faction_id")
        assert_equal(faction.id, rival.faction_id, "faction_id matches")
        assert_equal(1, rival.generation_born, "born at gen 1")
        assert_true(rival.alive, "alive at birth")
        assert_not_nil(rival.personality, "has personality")
        assert_not_nil(rival.genome, "has genome")
        assert_not_nil(rival.attitude, "has attitude")
        assert_not_nil(rival.dominant_category, "has dominant category")
    end)

    it("personality derives from faction personality with variance", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local faction = factions:get_active()[1]
        -- Set extreme faction personality
        faction.personality.PER_CRM = 90

        local rival = RivalHeirs.generate(faction, 1)
        -- Should be biased toward cruel but not identical (±15)
        assert_in_range(rival.personality.PER_CRM, 75, 100, "cruelty biased from faction")
    end)

    it("attitude reflects faction disposition", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local faction = factions:get_active()[1]

        faction.disposition = -70
        local hostile = RivalHeirs.generate(faction, 1)
        assert_equal("hostile", hostile.attitude, "hostile at -70 disposition")

        faction.disposition = 70
        local friendly = RivalHeirs.generate(faction, 1)
        assert_true(friendly.attitude == "respectful" or friendly.attitude == "devoted",
            "friendly at +70 disposition")
    end)

    it("records interactions and updates rivalry score", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local rival = RivalHeirs.generate(factions:get_active()[1], 1)
        assert_equal(0, rival.rivalry_score, "starts at 0")

        RivalHeirs.record_interaction(rival, 2, "insult", "They spat at your heir.", -20)
        assert_equal(-20, rival.rivalry_score, "rivalry decreased")
        assert_equal(1, #rival.history, "one history entry")

        RivalHeirs.record_interaction(rival, 3, "truce", "A tentative peace.", 15)
        assert_equal(-5, rival.rivalry_score, "rivalry partially restored")
        assert_equal(2, #rival.history, "two history entries")
    end)

    it("describe produces readable text", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local rival = RivalHeirs.generate(factions:get_active()[1], 1)
        local desc = RivalHeirs.describe(rival)
        assert_true(#desc > 20, "description has content")
        assert_true(desc:find(rival.name) ~= nil, "contains rival name")
    end)

    it("death check kills older rivals", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local faction = factions:get_active()[1]
        local rival = RivalHeirs.generate(faction, 1)

        -- At age 0, shouldn't die
        local died = RivalHeirs.check_death(rival, 1, faction)
        assert_true(not died, "doesn't die at birth")

        -- Try many seeds at age 4+ to ensure death is possible
        local any_died = false
        for s = 1, 50 do
            rng.seed(s)
            local r = RivalHeirs.generate(faction, 1)
            local d, cause = RivalHeirs.check_death(r, 5, faction)
            if d then any_died = true; break end
        end
        assert_true(any_died, "some rival dies by age 4")
    end)
end)

describe("RivalHeirManager", function()
    it("tick populates heirs for all active factions", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()

        local events = mgr:tick(factions, 1)
        local active = factions:get_active()
        assert_equal(#active, #events, "one event per faction")

        for _, faction in ipairs(active) do
            local rival = mgr:get(faction.id)
            assert_not_nil(rival, "rival exists for " .. faction.id)
            assert_true(rival.alive, "rival is alive")
        end
    end)

    it("get_all_living returns all alive rivals", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        local living = mgr:get_all_living()
        assert_equal(#factions:get_active(), #living, "all living")
    end)

    it("get_nemesis returns most hostile rival", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        -- Make one rival very hostile
        local active = factions:get_active()
        local rival = mgr:get(active[1].id)
        RivalHeirs.record_interaction(rival, 1, "war", "Total war.", -80)

        local nemesis = mgr:get_nemesis()
        assert_not_nil(nemesis, "nemesis exists")
        assert_equal(rival.name, nemesis.name, "nemesis is the hostile one")
    end)

    it("succession happens when rival dies", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        -- Run many generations to force at least one succession
        local any_succession = false
        for gen = 2, 20 do
            local events = mgr:tick(factions, gen)
            for _, evt in ipairs(events) do
                if evt.event == "succession" then
                    any_succession = true
                    assert_not_nil(evt.predecessor, "predecessor exists")
                    assert_not_nil(evt.rival, "successor exists")
                    assert_true(evt.rival.alive, "successor is alive")
                    assert_true(not evt.predecessor.alive, "predecessor is dead")
                end
            end
        end
        assert_true(any_succession, "at least one succession in 20 gens")
    end)

    it("successors inherit rivalry from predecessors", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        -- Build up rivalry with first faction's heir
        local active = factions:get_active()
        local rival = mgr:get(active[1].id)
        RivalHeirs.record_interaction(rival, 1, "war", "Total war.", -60)

        -- Force death
        rival.alive = false
        rival.generation_died = 2

        local events = mgr:tick(factions, 2)
        local successor = mgr:get(active[1].id)
        assert_not_nil(successor, "successor generated")
        -- Inherits 50% of rivalry: -60 * 0.5 = -30
        assert_equal(-30, successor.rivalry_score, "inherits 50% rivalry")
        assert_true(#successor.history > 0, "has inherited grudge entry")
    end)

    it("find filters rivals correctly", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        -- Make one hostile
        local active = factions:get_active()
        local rival = mgr:get(active[1].id)
        rival.rivalry_score = -80
        rival.attitude = "hostile"

        local hostiles = mgr:find({ attitude = "hostile" })
        assert_true(#hostiles >= 1, "found at least one hostile")
    end)

    it("serialization round-trip preserves state", function()
        rng.seed(42)
        local factions = FactionManager.new()
        local mgr = RivalHeirManager.new()
        mgr:tick(factions, 1)

        -- Add some history
        local active = factions:get_active()
        local rival = mgr:get(active[1].id)
        RivalHeirs.record_interaction(rival, 1, "duel", "A fierce duel.", -15)

        local data = mgr:to_table()
        local restored = RivalHeirManager.from_table(data)

        local restored_rival = restored:get(active[1].id)
        assert_not_nil(restored_rival, "rival restored")
        assert_equal(rival.name, restored_rival.name, "name preserved")
        assert_equal(rival.rivalry_score, restored_rival.rivalry_score, "rivalry preserved")
        assert_equal(1, #restored_rival.history, "history preserved")
    end)
end)
