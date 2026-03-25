-- Dark Legacy — Event Chains Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local WorldState = require("dredwork_world.world_state")
local EventChains = require("dredwork_world.event_chains")
local rng = require("dredwork_core.rng")

-- Minimal faction mock
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
        active_chains = {},
    }
    if overrides then
        for k, v in pairs(overrides) do ctx[k] = v end
    end
    return ctx
end

describe("Event Chains", function()
    rng.seed(42)

    it("should start a chain and return valid chain state", function()
        local state = EventChains.start_chain("plague_origin", 5, "investigate")
        assert_not_nil(state, "Chain state should not be nil")
        assert_equal("plague_origin", state.chain_id)
        assert_equal(1, state.stage)
        assert_equal(5, state.started_gen)
        assert_true(#state.choices == 1, "Should have 1 choice")
        assert_equal("investigate", state.choices[1])
        assert_true(state.next_fire_gen > 5, "Next fire gen should be after start")
    end)

    it("should advance a chain and return updated state", function()
        rng.seed(42)
        local state = EventChains.start_chain("plague_origin", 5, "investigate")
        local updated = EventChains.advance_chain(state, "purge", 7)
        assert_not_nil(updated, "Should return updated state (not yet complete)")
        assert_equal(2, updated.stage)
        assert_equal(7, updated.last_gen)
        assert_true(#updated.choices == 2, "Should have 2 choices")
        assert_equal("purge", updated.choices[2])
    end)

    it("should return nil when chain is complete", function()
        rng.seed(42)
        local state = EventChains.start_chain("plague_origin", 5, "investigate")
        state.stage = 2 -- manually set to stage 2
        state.choices = { "investigate", "purge" }
        -- Advancing from stage 2 → stage 3, plague_origin has 3 stages total
        local updated = EventChains.advance_chain(state, "remember", 10)
        assert_nil(updated, "Should return nil when chain is complete (3 stages, now at 3)")
    end)

    it("should check pending chains and return ready events", function()
        rng.seed(42)
        local chain = EventChains.start_chain("plague_origin", 5, "investigate")
        chain.next_fire_gen = 7

        local ready = EventChains.check_pending({ chain }, 7)
        assert_true(#ready >= 1, "Should have at least 1 ready chain event")
        assert_not_nil(ready[1].event, "Ready entry should have event")
        assert_equal(2, ready[1].stage, "Should be stage 2")
    end)

    it("should not return pending events before fire generation", function()
        rng.seed(42)
        local chain = EventChains.start_chain("plague_origin", 5, "investigate")
        chain.next_fire_gen = 9

        local ready = EventChains.check_pending({ chain }, 7)
        assert_true(#ready == 0, "Should have no ready events before fire gen")
    end)

    it("should trigger plague_origin chain when plague is active", function()
        rng.seed(42)
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.7, 5)

        -- Try multiple seeds to account for 30% chance
        local triggered = false
        for i = 1, 30 do
            rng.seed(42 + i)
            local ctx = make_context({ world_state = ws, generation = 5 })
            local result = EventChains.check_new_triggers({}, ctx)
            if result and result.chain_id == "plague_origin" then
                triggered = true
                break
            end
        end
        assert_true(triggered, "plague_origin should trigger when plague is active")
    end)

    it("should trigger rival_heir when hostile faction exists", function()
        local hostile = make_faction({ disposition = -60 })
        local fm = make_faction_manager({ hostile })

        local triggered = false
        for i = 1, 30 do
            rng.seed(42 + i)
            local ctx = make_context({ factions = fm, generation = 12 })
            local result = EventChains.check_new_triggers({}, ctx)
            if result and result.chain_id == "rival_heir" then
                triggered = true
                break
            end
        end
        assert_true(triggered, "rival_heir should trigger with hostile faction")
    end)

    it("should not trigger chains when at max active", function()
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.7, 5)
        local active = {
            { chain_id = "chain_a", stage = 1, next_fire_gen = 99 },
            { chain_id = "chain_b", stage = 1, next_fire_gen = 99 },
        }

        local any_triggered = false
        for i = 1, 20 do
            rng.seed(42 + i)
            local ctx = make_context({ world_state = ws, generation = 10 })
            local result = EventChains.check_new_triggers(active, ctx)
            if result then any_triggered = true; break end
        end
        assert_true(not any_triggered, "Should not trigger new chain when at max (2)")
    end)

    it("should not re-trigger a completed chain", function()
        local ws = WorldState.new("ancient")
        ws:add_condition("plague", 0.7, 5)
        ws.used_chains = { plague_origin = true }

        local any_triggered = false
        for i = 1, 20 do
            rng.seed(42 + i)
            local ctx = make_context({ world_state = ws, generation = 10 })
            local result = EventChains.check_new_triggers({}, ctx)
            if result and result.chain_id == "plague_origin" then
                any_triggered = true; break
            end
        end
        assert_true(not any_triggered, "Should not re-trigger completed chain")
    end)

    it("should produce event with title and narrative", function()
        rng.seed(42)
        local event = EventChains.get_chain_event("plague_origin", 1, {})
        assert_not_nil(event, "Should produce event for stage 1")
        assert_not_nil(event.title, "Event should have title")
        assert_not_nil(event.narrative, "Event should have narrative")
        assert_true(#event.title > 0, "Title should not be empty")
        assert_true(#event.narrative > 0, "Narrative should not be empty")
    end)

    it("should have options with choice_keys", function()
        local event = EventChains.get_chain_event("plague_origin", 1, {})
        assert_not_nil(event.options, "Event should have options")
        assert_true(#event.options >= 1, "Should have at least 1 option")
        for _, opt in ipairs(event.options) do
            assert_not_nil(opt.choice_key, "Option should have choice_key")
            assert_not_nil(opt.label, "Option should have label")
        end
    end)

    it("should vary stage 2 narrative based on stage 1 choice", function()
        local event_inv = EventChains.get_chain_event("plague_origin", 2, { "investigate" })
        local event_end = EventChains.get_chain_event("plague_origin", 2, { "endure" })
        assert_not_nil(event_inv)
        assert_not_nil(event_end)
        assert_true(event_inv.narrative ~= event_end.narrative,
            "Different choices should produce different narratives")
    end)

    it("should handle nil active_chains gracefully", function()
        local ready = EventChains.check_pending(nil, 10)
        assert_not_nil(ready)
        assert_true(#ready == 0, "Should return empty for nil active_chains")
    end)

    it("should mark event type as chain", function()
        local event = EventChains.get_chain_event("rival_heir", 1, {})
        assert_not_nil(event)
        assert_equal("chain", event.type, "Event type should be 'chain'")
    end)

    it("should include chain metadata in event", function()
        local event = EventChains.get_chain_event("ancient_artifact", 2, { "study" })
        assert_not_nil(event)
        assert_equal("ancient_artifact", event.chain_id)
        assert_equal(2, event.chain_stage)
        assert_equal(4, event.chain_total_stages)
    end)

    it("should not trigger before min_generation", function()
        -- rival_heir requires min_generation = 5
        local hostile = make_faction({ disposition = -60 })
        local fm = make_faction_manager({ hostile })

        local any_triggered = false
        for i = 1, 20 do
            rng.seed(42 + i)
            local ctx = make_context({ factions = fm, generation = 3 })
            local result = EventChains.check_new_triggers({}, ctx)
            if result and result.chain_id == "rival_heir" then
                any_triggered = true; break
            end
        end
        assert_true(not any_triggered, "Should not trigger before min_generation")
    end)
end)
