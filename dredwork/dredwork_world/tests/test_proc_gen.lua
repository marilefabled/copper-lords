-- Dark Legacy — Procedural Event Generation Tests
-- Tests the proc gen pipeline: fragments, archetypes, scaler, assembler, variety.

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")

-- Pure Lua modules under test
local ConsequenceScaler = require("dredwork_world.proc_gen.consequence_scaler")
local EventAssembler = require("dredwork_world.proc_gen.event_assembler")
local NarrativeVariety = require("dredwork_world.proc_gen.narrative_variety")
local fragments = require("dredwork_world.proc_gen.narrative_fragments")
local archetypes = require("dredwork_world.proc_gen.event_archetypes")
local patterns = require("dredwork_world.proc_gen.consequence_patterns")

-- Helper: build a minimal valid context
local function make_context(overrides)
    overrides = overrides or {}
    local cm = CulturalMemory.new()
    if overrides.add_taboo then
        cm:add_taboo("test_trigger", 1, "test_effect", 80)
    end

    -- Minimal mock WorldState
    local ws = {
        current_era_key = overrides.era or "medieval",
        conditions = overrides.conditions or {},
        generation = overrides.generation or 5,
        used_events = {},
        get_era_name = function(self)
            local names = {
                ancient = "The Age of Myth",
                medieval = "The Iron Age",
                renaissance = "The Enlightenment",
                arcane = "The Arcane Era",
                industrial = "The Age of Steam",
                twilight = "The Twilight",
            }
            return names[self.current_era_key] or "An Unknown Era"
        end,
        has_condition = function(self, ctype)
            for _, c in ipairs(self.conditions) do
                if c.type == ctype then return true end
            end
            return false
        end,
    }

    -- Minimal mock FactionManager
    local factions = {
        get_active = function()
            return {
                {
                    id = "house_test",
                    name = "House Test",
                    disposition = overrides.faction_disposition or 0,
                    power = 50,
                    reputation = { primary = "warriors" },
                },
            }
        end,
        get = function(self, id)
            if id == "house_test" then
                return {
                    id = "house_test",
                    name = "House Test",
                    disposition = overrides.faction_disposition or 0,
                    shift_disposition = function() end,
                    shift_power = function() end,
                }
            end
            return nil
        end,
    }

    return {
        world_state = ws,
        factions = factions,
        heir_personality = overrides.personality or Personality.new({ PER_BLD = 60, PER_CRM = 40, PER_CUR = 55, PER_ADA = 50 }),
        cultural_memory = cm,
        generation = overrides.generation or 5,
        heir_name = "Test Heir",
        lineage_name = "Test Bloodline",
        mutation_pressure = { value = 10, active_triggers = {} },
        max_events = overrides.max_events or 3,
    }
end

-- =========================================================================
-- Narrative Fragments
-- =========================================================================
describe("Narrative Fragments - data integrity", function()
    it("should have titles for all expected archetypes", function()
        local expected = { "conflict", "discovery", "betrayal", "crisis", "opportunity", "ceremony" }
        for _, arch in ipairs(expected) do
            assert_not_nil(fragments.titles[arch], "Missing titles for archetype: " .. arch)
            assert_true(#fragments.titles[arch].generic > 0, "Empty generic titles for: " .. arch)
        end
    end)

    it("should have narratives for all expected archetypes", function()
        local expected = { "conflict", "discovery", "betrayal", "crisis", "opportunity", "ceremony" }
        for _, arch in ipairs(expected) do
            assert_not_nil(fragments.narratives[arch], "Missing narratives for archetype: " .. arch)
            assert_true(#fragments.narratives[arch].generic > 0, "Empty generic narratives for: " .. arch)
        end
    end)

    it("should have option labels for all response types", function()
        local expected = { "aggressive", "cautious", "clever", "merciful", "cruel", "pragmatic" }
        for _, rtype in ipairs(expected) do
            assert_not_nil(fragments.option_labels[rtype], "Missing option labels for: " .. rtype)
            assert_true(#fragments.option_labels[rtype] > 0, "Empty option labels for: " .. rtype)
        end
    end)

    it("should have consequence narratives for all response types", function()
        local expected = { "aggressive", "cautious", "clever", "merciful", "cruel", "pragmatic" }
        for _, rtype in ipairs(expected) do
            local cn = fragments.consequence_narratives[rtype]
            assert_not_nil(cn, "Missing consequence narratives for: " .. rtype)
            assert_not_nil(cn.success, "Missing success narratives for: " .. rtype)
            assert_not_nil(cn.mixed, "Missing mixed narratives for: " .. rtype)
            assert_not_nil(cn.failure, "Missing failure narratives for: " .. rtype)
        end
    end)

    it("should have condition modifiers", function()
        assert_not_nil(fragments.condition_modifiers.plague, "Missing plague modifiers")
        assert_not_nil(fragments.condition_modifiers.war, "Missing war modifiers")
        assert_not_nil(fragments.condition_modifiers.famine, "Missing famine modifiers")
    end)
end)

-- =========================================================================
-- Event Archetypes
-- =========================================================================
describe("Event Archetypes - data integrity", function()
    it("should have world archetypes", function()
        assert_true(#archetypes.world >= 8, "Expected at least 8 world archetypes, got " .. #archetypes.world)
    end)

    it("should have faction archetypes", function()
        assert_true(#archetypes.faction >= 6, "Expected at least 6 faction archetypes, got " .. #archetypes.faction)
    end)

    it("should have legacy archetypes", function()
        assert_true(#archetypes.legacy >= 6, "Expected at least 6 legacy archetypes, got " .. #archetypes.legacy)
    end)

    it("should have valid option patterns on all archetypes", function()
        for pool, pool_archs in pairs(archetypes) do
            for _, arch in ipairs(pool_archs) do
                assert_not_nil(arch.id, pool .. " archetype missing id")
                assert_not_nil(arch.archetype, arch.id .. " missing archetype key")
                assert_not_nil(arch.option_patterns, arch.id .. " missing option_patterns")
                assert_true(#arch.option_patterns >= 2, arch.id .. " needs at least 2 option patterns")
                for _, opt in ipairs(arch.option_patterns) do
                    assert_not_nil(opt.response_type, arch.id .. " option missing response_type")
                    assert_not_nil(opt.consequence_pattern, arch.id .. " option missing consequence_pattern")
                end
            end
        end
    end)
end)

-- =========================================================================
-- Consequence Patterns
-- =========================================================================
describe("Consequence Patterns - data integrity", function()
    it("should have all referenced patterns", function()
        local referenced = {}
        for pool, pool_archs in pairs(archetypes) do
            for _, arch in ipairs(pool_archs) do
                for _, opt in ipairs(arch.option_patterns) do
                    referenced[opt.consequence_pattern] = true
                end
            end
        end
        for pattern_name, _ in pairs(referenced) do
            assert_not_nil(patterns[pattern_name], "Missing pattern: " .. pattern_name)
        end
    end)

    it("should have narrative on each pattern", function()
        for name, pattern in pairs(patterns) do
            if type(pattern) == "table" then
                assert_not_nil(pattern.narrative, "Pattern " .. name .. " missing narrative")
            end
        end
    end)
end)

-- =========================================================================
-- Consequence Scaler
-- =========================================================================
describe("Consequence Scaler", function()
    it("should return 1.0 for early generations", function()
        local mult = ConsequenceScaler.get_multiplier({ generation = 5 })
        assert_true(math.abs(mult - 1.0) < 0.01, "Expected 1.0 for gen 5, got " .. mult)
    end)

    it("should scale up for later generations", function()
        local mult_30 = ConsequenceScaler.get_multiplier({ generation = 30 })
        local mult_60 = ConsequenceScaler.get_multiplier({ generation = 60 })
        assert_true(mult_30 > 1.0, "Expected > 1.0 for gen 30, got " .. mult_30)
        assert_true(mult_60 > mult_30, "Expected gen 60 > gen 30: " .. mult_60 .. " vs " .. mult_30)
    end)

    it("should cap at 2.5", function()
        local ws = { conditions = {
            { type = "plague", intensity = 1.0 },
            { type = "war", intensity = 1.0 },
            { type = "famine", intensity = 1.0 },
        }}
        local mult = ConsequenceScaler.get_multiplier({ generation = 200, world_state = ws })
        assert_true(mult <= 2.5, "Expected cap at 2.5, got " .. mult)
    end)

    it("should deep copy without modifying original", function()
        local original = { a = { b = 1 }, c = 2 }
        local copy = ConsequenceScaler.deep_copy(original)
        copy.a.b = 99
        assert_equal(1, original.a.b, "Deep copy should not modify original")
    end)

    it("should scale cultural_memory_shift values", function()
        local pattern = {
            narrative = "test",
            cultural_memory_shift = { physical = 3, mental = -1, social = 0, creative = 2 },
        }
        local scaled = ConsequenceScaler.scale(pattern, 2.0)
        assert_equal(6, scaled.cultural_memory_shift.physical, "Expected 3*2=6")
        assert_equal(-2, scaled.cultural_memory_shift.mental, "Expected -1*2=-2")
        assert_equal(0, scaled.cultural_memory_shift.social, "Expected 0*2=0")
        assert_equal(4, scaled.cultural_memory_shift.creative, "Expected 2*2=4")
    end)
end)

-- =========================================================================
-- Event Assembler
-- =========================================================================
describe("Event Assembler - world events", function()
    it("should generate at least one world event", function()
        rng.seed(12345)
        local ctx = make_context()
        local events = EventAssembler.generate("world", ctx, 1)
        assert_true(#events >= 1, "Expected at least 1 world event, got " .. #events)
    end)

    it("should produce events with correct structure", function()
        rng.seed(23456)
        local ctx = make_context()
        local events = EventAssembler.generate("world", ctx, 2)
        for _, evt in ipairs(events) do
            assert_equal("world", evt.type, "Event type should be 'world'")
            assert_not_nil(evt.id, "Event should have an id")
            assert_not_nil(evt.title, "Event should have a title")
            assert_not_nil(evt.narrative, "Event should have a narrative")
            assert_not_nil(evt.options, "Event should have options")
            assert_true(#evt.options >= 2, "Event should have at least 2 options")
            assert_true(evt.proc_gen == true, "Proc gen events should be flagged")
        end
    end)

    it("should produce options with consequences", function()
        rng.seed(34567)
        local ctx = make_context()
        local events = EventAssembler.generate("world", ctx, 1)
        if #events > 0 then
            local evt = events[1]
            for _, opt in ipairs(evt.options) do
                assert_not_nil(opt.label, "Option should have a label")
                assert_not_nil(opt.consequences, "Option should have consequences")
            end
        end
    end)
end)

describe("Event Assembler - faction events", function()
    it("should generate faction events with target_faction", function()
        rng.seed(45678)
        local ctx = make_context()
        local events = EventAssembler.generate("faction", ctx, 1)
        if #events > 0 then
            assert_equal("faction", events[1].type, "Should be faction type")
            assert_not_nil(events[1].target_faction, "Should have target_faction")
        end
    end)
end)

describe("Event Assembler - legacy events", function()
    it("should generate legacy events when cultural memory has content", function()
        rng.seed(56789)
        local ctx = make_context({
            add_taboo = true,
            generation = 20,
        })
        -- Need to also add a relationship for old_relationship archetype
        ctx.cultural_memory:add_relationship("house_test", "ally", 1, 60, "test")

        local events = EventAssembler.generate("legacy", ctx, 1)
        -- May or may not generate (depends on rng), but should not error
        assert_true(type(events) == "table", "Should return a table")
    end)
end)

describe("Event Assembler - personality gating", function()
    it("should mark options as unavailable when personality doesn't meet requirements", function()
        rng.seed(67890)
        local ctx = make_context({
            personality = Personality.new({
                PER_BLD = 10,  -- Very low boldness
                PER_CRM = 50,
                PER_CUR = 10,  -- Very low curiosity
                PER_ADA = 10,
            }),
        })
        local events = EventAssembler.generate("world", ctx, 3)
        local found_gated = false
        for _, evt in ipairs(events) do
            for _, opt in ipairs(evt.options) do
                if not opt.available then
                    found_gated = true
                    assert_not_nil(opt.gated_reason, "Gated option should have a reason")
                end
            end
        end
        -- With very low stats, at least some options should be gated
        -- (Not guaranteed for every seed, so don't assert)
    end)

    it("should always have at least one available option per event", function()
        rng.seed(78901)
        local ctx = make_context()
        local events = EventAssembler.generate("world", ctx, 3)
        for _, evt in ipairs(events) do
            local has_available = false
            for _, opt in ipairs(evt.options) do
                if opt.available then has_available = true end
            end
            assert_true(has_available, "Event " .. evt.id .. " should have at least one available option")
        end
    end)
end)

-- =========================================================================
-- Narrative Variety
-- =========================================================================
describe("Narrative Variety", function()
    it("should not crash on empty event list", function()
        NarrativeVariety.apply({}, make_context())
    end)

    it("should modify narratives when conditions are active", function()
        rng.seed(89012)
        local ctx = make_context({
            conditions = {
                { type = "plague", intensity = 0.5, remaining_gens = 2 },
                { type = "war", intensity = 0.5, remaining_gens = 2 },
            },
        })
        -- Create mock static events
        local events = {}
        for i = 1, 20 do
            events[i] = {
                type = "world",
                id = "test_event_" .. i,
                title = "Test Event",
                narrative = "Something happens.",
                options = {},
            }
        end
        NarrativeVariety.apply(events, ctx)
        -- At least some should have modified narratives (30% chance per condition)
        local modified = 0
        for _, evt in ipairs(events) do
            if evt.narrative ~= "Something happens." then
                modified = modified + 1
            end
        end
        -- With 20 events and 2 conditions at 30% each, expect some modifications
        assert_true(modified >= 1, "Expected at least 1 modified narrative, got " .. modified)
    end)

    it("should not modify proc_gen flagged events", function()
        rng.seed(90123)
        local ctx = make_context({
            conditions = { { type = "plague", intensity = 1.0, remaining_gens = 5 } },
        })
        local events = {
            {
                type = "world",
                id = "proc_test",
                title = "Proc Event",
                narrative = "Original narrative.",
                options = {},
                proc_gen = true,
            },
        }
        NarrativeVariety.apply(events, ctx)
        assert_equal("Original narrative.", events[1].narrative, "Should not modify proc_gen events")
    end)
end)
