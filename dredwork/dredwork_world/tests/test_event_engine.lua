-- Dark Legacy — Event Engine Tests

local rng = require("dredwork_core.rng")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")
local Mutation = require("dredwork_genetics.mutation")
local WorldState = require("dredwork_world.world_state")
local faction_module = require("dredwork_world.faction")
local FactionManager = faction_module.FactionManager
local EventEngine = require("dredwork_world.event_engine")

rng.seed(11111)

describe("EventEngine", function()

    local function make_context(overrides)
        overrides = overrides or {}
        local ws = overrides.world_state or WorldState.new()
        local fm = overrides.factions or FactionManager.new()
        local pers = overrides.heir_personality or Personality.new()
        local cm = overrides.cultural_memory or CulturalMemory.new()
        local mp = overrides.mutation_pressure or Mutation.new_pressure()

        return {
            world_state = ws,
            factions = fm,
            heir_personality = pers,
            cultural_memory = cm,
            generation = overrides.generation or 5,
            heir_name = overrides.heir_name or "Kaelon",
            lineage_name = overrides.lineage_name or "Darkblood",
            mutation_pressure = mp,
        }
    end

    it("creates without error", function()
        local ee = EventEngine.new()
        assert_not_nil(ee)
    end)

    it("generates events for a generation", function()
        rng.seed(22222)
        local ee = EventEngine.new()
        local context = make_context()

        -- Run many times to get at least some events
        local got_events = false
        for i = 1, 20 do
            rng.seed(22222 + i)
            local events = ee:generate(context)
            if #events > 0 then
                got_events = true
                break
            end
        end
        assert_true(got_events, "should generate events in 20 attempts")
    end)

    it("caps at 3 events max", function()
        rng.seed(33333)
        local ee = EventEngine.new()
        -- Set up a context that triggers many events
        local pers = Personality.new({
            PER_VOL = 90, PER_OBS = 90, PER_BLD = 90,
            PER_CRM = 90, PER_PRI = 90, PER_CUR = 90,
        })
        local ws = WorldState.new("iron")
        ws:add_condition("plague", 0.5, 5)
        ws:add_condition("war", 0.5, 5)

        local context = make_context({
            heir_personality = pers,
            world_state = ws,
        })

        for i = 1, 50 do
            rng.seed(33333 + i)
            local events = ee:generate(context)
            assert_true(#events <= 3, "should not exceed 3 events, got " .. #events)
        end
    end)

    it("personality-gates options correctly", function()
        -- Cruel heir should see cruel options
        local cruel_pers = Personality.new({ PER_CRM = 80 })
        local merciful_pers = Personality.new({ PER_CRM = 20 })

        local cruel_option = {
            label = "Strike while they are weak",
            requires = { axis = "PER_CRM", min = 65 },
        }
        local mercy_option = {
            label = "Send healers",
            requires = { axis = "PER_CRM", max = 60 },
        }
        local neutral_option = {
            label = "Seal the borders",
            requires = nil,
        }

        local cruel_ctx = { heir_personality = cruel_pers }
        local merciful_ctx = { heir_personality = merciful_pers }

        -- Cruel heir
        assert_true(EventEngine.option_available(cruel_option, cruel_ctx))
        assert_true(not EventEngine.option_available(mercy_option, cruel_ctx))
        assert_true(EventEngine.option_available(neutral_option, cruel_ctx))

        -- Merciful heir
        assert_true(not EventEngine.option_available(cruel_option, merciful_ctx))
        assert_true(EventEngine.option_available(mercy_option, merciful_ctx))
        assert_true(EventEngine.option_available(neutral_option, merciful_ctx))
    end)

    it("filters options by personality", function()
        local pers = Personality.new({ PER_BLD = 30 }) -- not bold
        local options = {
            { label = "Fight", requires = { axis = "PER_BLD", min = 50 } },
            { label = "Hide", requires = nil },
            { label = "Run", requires = { axis = "PER_BLD", max = 40 } },
        }

        local available = EventEngine.filter_options(options, { heir_personality = pers })
        assert_equal(2, #available) -- Hide and Run
    end)

    it("substitutes template variables", function()
        local text = "{heir_name} of {lineage_name} in {era_name}"
        local result = EventEngine.substitute(text, {
            heir_name = "Kael",
            lineage_name = "Darkblood",
            era_name = "The Iron Age",
        })
        assert_equal("Kael of Darkblood in The Iron Age", result)
    end)

    it("strips unknown vars cleanly", function()
        local text = "{heir_name} saw {unknown_var}"
        local result = EventEngine.substitute(text, { heir_name = "Kael" })
        assert_equal("Kael saw ", result)
    end)

    it("applies consequences to world state", function()
        rng.seed(44444)
        local context = make_context()
        -- Initialize trait priorities so shift has something to modify
        context.cultural_memory.trait_priorities["PHY_STR"] = 50
        context.cultural_memory.trait_priorities["SOC_CHA"] = 50

        local consequences = {
            cultural_memory_shift = { physical = 5, social = -3 },
            disposition_changes = { { faction_id = "all", delta = -10 } },
            narrative = "Test narrative",
        }

        local effects = EventEngine.apply_consequences(consequences, context)
        assert_equal("Test narrative", effects.narrative)

        -- Check cultural memory shifted
        assert_true(context.cultural_memory.trait_priorities["PHY_STR"] > 50)
        assert_true(context.cultural_memory.trait_priorities["SOC_CHA"] < 50)
    end)

    it("applies taboo consequence with chance", function()
        rng.seed(44444)
        local context = make_context()

        local consequences = {
            taboo_chance = 1.0, -- guaranteed
            taboo_data = { trigger = "test_event", effect = "test_taboo", strength = 85 },
            narrative = "Taboo formed.",
        }

        local effects = EventEngine.apply_consequences(consequences, context)
        assert_equal("test_taboo", effects.taboo_formed)
        assert_true(context.cultural_memory:is_taboo("test_taboo"))
    end)

    it("applies condition consequence", function()
        local context = make_context()
        local consequences = {
            add_condition = { type = "war", intensity = 0.6, duration = 3 },
            narrative = "War!",
        }

        EventEngine.apply_consequences(consequences, context)
        assert_true(context.world_state:has_condition("war"))
    end)

    it("generates personal auto-resolve events for extreme personality", function()
        rng.seed(55555)
        local ee = EventEngine.new()

        -- Try many seeds - volatile heir should eventually trigger personal event
        local got_personal = false
        for i = 1, 50 do
            rng.seed(55555 + i)
            local pers = Personality.new({ PER_VOL = 90 })
            local context = make_context({ heir_personality = pers })
            local events = ee:generate(context)
            for _, e in ipairs(events) do
                if e.type == "personal" and e.auto_resolve then
                    got_personal = true
                    break
                end
            end
            if got_personal then break end
        end
        assert_true(got_personal, "volatile heir should trigger personal event")
    end)

    -- ─── HEIR RESISTANCE ───────────────────────────────────────────────────
    it("check_heir_resistance returns nil for neutral personality", function()
        local personality = Personality.new({ PER_CRM = 50, PER_BLD = 50, PER_PRI = 50 })
        local option = {
            consequences = {
                moral_act = { act_id = "cruelty", description = "test" },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_nil(result, "neutral personality should not resist")
    end)

    it("check_heir_resistance triggers for merciful heir vs cruelty", function()
        local personality = Personality.new({ PER_CRM = 10 })
        local option = {
            consequences = {
                moral_act = { act_id = "cruelty", description = "test" },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "merciful heir should resist cruelty")
        assert_equal("PER_CRM", result.axis)
        assert_true(result.resistance_strength > 0.3, "resistance should be significant")
        assert_true(result.narrative:len() > 0, "should have resistance narrative")
    end)

    it("check_heir_resistance triggers for cautious heir vs war", function()
        local personality = Personality.new({ PER_BLD = 5 })
        local option = {
            consequences = {
                add_condition = { type = "war", intensity = 0.8, duration = 3 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "cautious heir should resist war")
        assert_equal("PER_BLD", result.axis)
    end)

    it("check_heir_resistance triggers for proud heir vs diplomacy", function()
        local personality = Personality.new({ PER_PRI = 90 })
        local option = {
            consequences = {
                disposition_changes = { { faction_id = "_target", delta = 25 } },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "proud heir should resist submissive diplomacy")
        assert_equal("PER_PRI", result.axis)
    end)

    it("check_heir_resistance does not trigger for bold heir vs war", function()
        local personality = Personality.new({ PER_BLD = 80 })
        local option = {
            consequences = {
                add_condition = { type = "war", intensity = 0.8, duration = 3 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_nil(result, "bold heir should not resist war")
    end)

    it("check_heir_resistance returns nil for no consequences", function()
        local personality = Personality.new({ PER_CRM = 10 })
        local result = EventEngine.check_heir_resistance({}, personality)
        assert_nil(result)
    end)

    it("check_heir_resistance triggers for curious heir vs taboo formation", function()
        local personality = Personality.new({ PER_CUR = 85 })
        local option = {
            consequences = {
                taboo_chance = 0.7,
                taboo_data = { trigger = "test", effect = "no_test", strength = 90 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "curious heir should resist taboo formation")
        assert_equal("PER_CUR", result.axis)
    end)

    it("check_heir_resistance triggers for curious heir vs knowledge suppression", function()
        local personality = Personality.new({ PER_CUR = 80 })
        local option = {
            consequences = {
                cultural_memory_shift = { mental = -5 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "curious heir should resist knowledge suppression")
        assert_equal("PER_CUR", result.axis)
    end)

    it("check_heir_resistance triggers for volatile heir vs forced restraint", function()
        local personality = Personality.new({ PER_VOL = 85 })
        local option = {
            consequences = {
                disposition_changes = { { faction_id = "_target", delta = 20 } },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "volatile heir should resist diplomatic restraint")
        -- Could be PER_VOL or PER_PRI depending on which is stronger
        assert_true(result.axis == "PER_VOL" or result.axis == "PER_PRI",
            "should resist via volatility or pride")
    end)

    it("check_heir_resistance triggers for rigid heir vs major cultural shift", function()
        local personality = Personality.new({ PER_ADA = 10 })
        local option = {
            consequences = {
                cultural_memory_shift = { physical = 5, social = -5 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "rigid heir should resist major cultural upheaval")
        assert_equal("PER_ADA", result.axis)
    end)

    it("check_heir_resistance triggers for loyal heir vs enemy declaration", function()
        local personality = Personality.new({ PER_LOY = 85 })
        local option = {
            consequences = {
                add_relationship = { type = "enemy", strength = 80, reason = "betrayal" },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "loyal heir should resist declaring enemies")
        assert_equal("PER_LOY", result.axis)
    end)

    it("check_heir_resistance triggers for loyal heir vs espionage", function()
        local personality = Personality.new({ PER_LOY = 80 })
        local option = {
            consequences = {
                reveal_faction_info = true,
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "loyal heir should resist espionage")
        assert_equal("PER_LOY", result.axis)
    end)

    it("check_heir_resistance triggers for lower war intensity with threshold fix", function()
        local personality = Personality.new({ PER_BLD = 5 })
        local option = {
            consequences = {
                add_condition = { type = "war", intensity = 0.3, duration = 2 },
            },
        }
        local result = EventEngine.check_heir_resistance(option, personality)
        assert_not_nil(result, "cautious heir should resist even moderate war")
        assert_equal("PER_BLD", result.axis)
    end)
end)
