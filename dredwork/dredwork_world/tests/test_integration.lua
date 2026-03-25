-- Dark Legacy — Integration Tests
-- Full loop: world state + factions + events + cultural memory interacting

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local Mutation = require("dredwork_genetics.mutation")
local Inheritance = require("dredwork_genetics.inheritance")
local WorldController = require("dredwork_world.world_controller")
local Council = require("dredwork_world.council")
local Chronicle = require("dredwork_world.chronicle")

rng.seed(77777)

describe("World Integration", function()

    local function make_game_state()
        local heir = Genome.new()
        local pers = Personality.new({
            PER_BLD = 60, PER_CRM = 55, PER_VOL = 45,
            PER_OBS = 50, PER_LOY = 60, PER_CUR = 55,
            PER_PRI = 50, PER_ADA = 50,
        })
        local cm = CulturalMemory.new()
        cm:update(heir)

        return {
            current_heir = heir,
            heir_personality = pers,
            cultural_memory = cm,
            generation = 1,
            mutation_pressure = Mutation.new_pressure(),
            heir_name = "Kaelon",
            lineage_name = "Darkblood",
        }
    end

    it("initializes world without error", function()
        local world = WorldController.init("ancient")
        assert_not_nil(world.world_state)
        assert_not_nil(world.factions)
        assert_not_nil(world.event_engine)
        assert_equal("ancient", world.world_state.current_era_key)
        assert_equal(5, #world.factions:get_all())
    end)

    it("generates events without error", function()
        rng.seed(88888)
        local world = WorldController.init("iron")
        local gs = make_game_state()
        local events = WorldController.generate_events(world, gs)
        assert_not_nil(events)
        -- Events might be empty due to chance, that's ok
        assert_true(#events >= 0)
    end)

    it("resolves events without error", function()
        rng.seed(99999)
        local world = WorldController.init("iron")
        local gs = make_game_state()

        -- Generate events repeatedly until we get one with options
        local resolved = false
        for i = 1, 50 do
            rng.seed(99999 + i)
            local events = WorldController.generate_events(world, gs)
            for _, event in ipairs(events) do
                if not event.auto_resolve and event.options and #event.options > 0 then
                    local effects = WorldController.resolve_event(event, 1, world, gs)
                    assert_not_nil(effects)
                    resolved = true
                    break
                elseif event.auto_resolve then
                    local effects = WorldController.resolve_event(event, nil, world, gs)
                    assert_not_nil(effects)
                    resolved = true
                    break
                end
            end
            if resolved then break end
        end
        assert_true(resolved, "should resolve at least one event in 50 attempts")
    end)

    it("gets council actions", function()
        local world = WorldController.init("ancient")
        local gs = make_game_state()
        local actions = WorldController.get_council_actions(world, gs)
        assert_not_nil(actions)
        assert_true(#actions >= 3, "should have at least 3 council actions (always-available ones)")
    end)

    it("executes council action", function()
        local world = WorldController.init("ancient")
        local gs = make_game_state()
        local actions = WorldController.get_council_actions(world, gs)
        assert_true(#actions > 0)

        -- Execute first action
        local effects = WorldController.execute_council_action(actions[1], world, gs, "house_mordthen")
        assert_not_nil(effects)
    end)

    it("advances world generation", function()
        local world = WorldController.init("iron")
        local gs = make_game_state()

        local results = WorldController.advance_generation(world, gs)
        assert_not_nil(results.world_advance)
        assert_equal(1, world.world_state.generation)
    end)

    it("generates chronicle text", function()
        local world = WorldController.init("ancient")
        local gs = make_game_state()

        local chronicle = WorldController.generate_chronicle(world, gs, { "A test event occurred." })
        assert_not_nil(chronicle)
        assert_true(#chronicle > 0, "chronicle should not be empty")
    end)

    it("gets faction mate info", function()
        local world = WorldController.init("ancient")
        local gs = make_game_state()

        local mates = WorldController.get_faction_mate_info(world, gs, 4)
        assert_not_nil(mates)
        assert_true(#mates > 0, "should have at least one faction mate")
        assert_not_nil(mates[1].faction_id)
        assert_not_nil(mates[1].faction_name)
        assert_not_nil(mates[1].category_bias)
    end)

    it("serializes and deserializes world", function()
        local world = WorldController.init("arcane")
        world.world_state:add_condition("plague", 0.5, 3)
        world.factions:shift_all_disposition(10)

        local data = WorldController.to_table(world)
        local restored = WorldController.from_table(data)

        assert_equal("arcane", restored.world_state.current_era_key)
        assert_equal(5, #restored.factions:get_all())
    end)

    it("runs 10 generations without crashing", function()
        rng.seed(12345)
        local world = WorldController.init("ancient")
        local gs = make_game_state()

        for gen = 1, 10 do
            gs.generation = gen

            -- Generate and resolve events
            local events = WorldController.generate_events(world, gs)
            local event_narratives = {}
            for _, event in ipairs(events) do
                if event.auto_resolve then
                    local eff = WorldController.resolve_event(event, nil, world, gs)
                    event_narratives[#event_narratives + 1] = eff.narrative
                elseif event.options and #event.options > 0 then
                    local eff = WorldController.resolve_event(event, 1, world, gs)
                    event_narratives[#event_narratives + 1] = eff.narrative
                end
            end

            -- Council action
            local actions = WorldController.get_council_actions(world, gs)
            if #actions > 0 then
                WorldController.execute_council_action(actions[1], world, gs)
            end

            -- Chronicle
            WorldController.generate_chronicle(world, gs, event_narratives)

            -- Breed (simplified)
            local mate = Genome.new()
            local child = Inheritance.breed(gs.current_heir, mate)
            Mutation.apply(child, gs.mutation_pressure)
            local child_pers = Personality.derive(child, gs.heir_personality, Personality.new())

            -- Advance
            gs.current_heir = child
            gs.heir_personality = child_pers
            gs.cultural_memory:update(child)
            Mutation.decay(gs.mutation_pressure)

            WorldController.advance_generation(world, gs)
        end

        assert_equal(10, gs.generation)
        assert_true(#world.world_state.chronicle > 0, "chronicle should have entries")
        assert_true(#world.factions:get_active() >= 2, "should still have active factions")
    end)

    it("generates personality-tinted chronicle openings", function()
        local cruel_pers = Personality.new({ PER_CRM = 90 })
        local opening = Chronicle.generation_opening("Kael", 5, cruel_pers)
        assert_not_nil(opening)
        assert_true(#opening > 0)
        -- Should contain heir name
        assert_true(opening:find("Kael") ~= nil, "opening should contain heir name")
    end)

    it("generates reputation-tinted closings", function()
        local closing = Chronicle.generation_closing({ primary = "warriors" })
        assert_not_nil(closing)
        assert_true(#closing > 0)
    end)
end)
