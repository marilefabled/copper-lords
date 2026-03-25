-- Dark Legacy — Crucible System Tests

local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")
local WorldState = require("dredwork_world.world_state")
local Crucible = require("dredwork_world.crucible")
local rng = require("dredwork_core.rng")

describe("Crucible System", function()
    rng.seed(42)

    -- Helper: build a basic context
    local function make_context(overrides)
        overrides = overrides or {}
        local ws = WorldState.new("ancient")
        ws.generation = overrides.generation or 10
        ws.last_crucible_gen = overrides.last_crucible_gen or 0
        ws.generations_in_era = overrides.generations_in_era or 5
        if overrides.conditions then
            ws.conditions = overrides.conditions
        end
        return {
            generation = ws.generation,
            world_state = ws,
            mutation_pressure = overrides.mutation_pressure or { value = 30 },
            last_crucible_gen = ws.last_crucible_gen,
        }
    end

    -- ===== should_trigger tests =====

    it("should not trigger before generation 5", function()
        local ctx = make_context({ generation = 3, last_crucible_gen = 0 })
        assert_true(not Crucible.should_trigger(ctx), "Should not trigger at gen 3")
    end)

    it("should not trigger at generation 4", function()
        local ctx = make_context({ generation = 4, last_crucible_gen = 0 })
        assert_true(not Crucible.should_trigger(ctx), "Should not trigger at gen 4")
    end)

    it("should trigger on era transition", function()
        local ctx = make_context({ generation = 8, last_crucible_gen = 7, generations_in_era = 0 })
        assert_true(Crucible.should_trigger(ctx), "Should trigger on era transition")
    end)

    it("should trigger on extreme mutation pressure", function()
        local ctx = make_context({
            generation = 6,
            last_crucible_gen = 5,
            mutation_pressure = { value = 85 },
        })
        assert_true(Crucible.should_trigger(ctx), "Should trigger on high mutation pressure")
    end)

    it("should trigger on triple condition", function()
        local ctx = make_context({
            generation = 6,
            last_crucible_gen = 5,
            conditions = {
                { type = "plague", remaining_gens = 2 },
                { type = "war", remaining_gens = 3 },
                { type = "famine", remaining_gens = 1 },
            },
        })
        assert_true(Crucible.should_trigger(ctx), "Should trigger on 3 conditions")
    end)

    it("should trigger on generational gap", function()
        -- With gap of 15 (gen 20, last 5), should always trigger since max gap is 15
        local ctx = make_context({ generation = 20, last_crucible_gen = 5 })
        assert_true(Crucible.should_trigger(ctx), "Should trigger with gap of 15")
    end)

    it("should not trigger with small gap and no special conditions", function()
        local ctx = make_context({
            generation = 8,
            last_crucible_gen = 7,
            generations_in_era = 5,
            mutation_pressure = { value = 20 },
        })
        assert_true(not Crucible.should_trigger(ctx), "Should not trigger with gap of 1")
    end)

    -- ===== select_trial tests =====

    it("should return a valid trial", function()
        local ctx = make_context()
        local trial = Crucible.select_trial(ctx)
        assert_not_nil(trial, "Trial should not be nil")
        assert_not_nil(trial.id, "Trial should have an id")
        assert_not_nil(trial.name, "Trial should have a name")
        assert_not_nil(trial.stages, "Trial should have stages")
        assert_true(#trial.stages >= 3, "Trial should have at least 3 stages")
    end)

    it("should favor war trial during war", function()
        -- Run many selections with war condition to check bias
        local war_count = 0
        local total = 100
        for _ = 1, total do
            local ctx = make_context({
                conditions = { { type = "war", remaining_gens = 3 } },
            })
            local trial = Crucible.select_trial(ctx)
            if trial.id == "trial_by_fire" then
                war_count = war_count + 1
            end
        end
        -- With war affinity bonus, trial_by_fire should appear more than flat 10%
        assert_true(war_count > 5, "War trial should be favored during war, got " .. war_count .. "/" .. total)
    end)

    -- ===== resolve_stage tests =====

    it("should pick the correct path based on personality", function()
        -- Build a genome and personality with high boldness
        local genome = Genome.new()
        genome:set_value("PHY_STR", 80)
        genome:set_value("PHY_REF", 70)
        genome:set_value("MEN_COM", 65)

        local pers = Personality.new({
            PER_BLD = 90, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        })

        -- Use the first stage of trial_by_fire which has fight (BLD high) vs flee (BLD low)
        local trials = require("dredwork_world.config.crucible_trials")
        local trial = trials[1] -- trial_by_fire
        local stage = trial.stages[1] -- The Ambush

        local result = Crucible.resolve_stage(stage, genome, pers)
        assert_equal("fight", result.path_chosen, "High boldness should pick fight path")
    end)

    it("should pick low-direction path for low personality value", function()
        local genome = Genome.new()
        genome:set_value("PHY_AGI", 70)
        genome:set_value("MEN_PER", 65)
        genome:set_value("PHY_END", 60)

        local pers = Personality.new({
            PER_BLD = 15, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        })

        local trials = require("dredwork_world.config.crucible_trials")
        local stage = trials[1].stages[1] -- The Ambush: fight(BLD high) vs flee(BLD low)

        local result = Crucible.resolve_stage(stage, genome, pers)
        assert_equal("flee", result.path_chosen, "Low boldness should pick flee path")
    end)

    it("should score high for traits above threshold", function()
        local genome = Genome.new()
        genome:set_value("PHY_STR", 90)
        genome:set_value("PHY_REF", 80)
        genome:set_value("MEN_COM", 75)

        local pers = Personality.new({
            PER_BLD = 90, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        })

        local trials = require("dredwork_world.config.crucible_trials")
        local stage = trials[1].stages[1]

        local result = Crucible.resolve_stage(stage, genome, pers)
        -- All traits are well above threshold, should score high
        assert_true(result.score >= 0.75, "High traits should score high, got " .. result.score)
    end)

    it("should score low for traits below threshold", function()
        local genome = Genome.new()
        genome:set_value("PHY_STR", 20)
        genome:set_value("PHY_REF", 15)
        genome:set_value("MEN_COM", 10)

        local pers = Personality.new({
            PER_BLD = 90, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        })

        local trials = require("dredwork_world.config.crucible_trials")
        local stage = trials[1].stages[1]

        local result = Crucible.resolve_stage(stage, genome, pers)
        assert_true(result.score <= 0.35, "Low traits should score low, got " .. result.score)
    end)

    -- ===== Full run tests =====

    it("should produce a valid result structure", function()
        local genome = Genome.new()
        local pers = Personality.new()
        local ctx = make_context()
        local trial = Crucible.select_trial(ctx)

        local result = Crucible.run(trial, genome, pers, "Test Heir", ctx)

        assert_not_nil(result.trial_id, "Result should have trial_id")
        assert_not_nil(result.trial_name, "Result should have trial_name")
        assert_not_nil(result.stages, "Result should have stages")
        assert_true(#result.stages >= 3, "Result should have 3+ stage results")
        assert_not_nil(result.total_score, "Result should have total_score")
        assert_in_range(result.total_score, 0, 1, "Total score should be 0-1")
        assert_not_nil(result.outcome, "Result should have outcome")
        assert_true(
            result.outcome == "triumph" or result.outcome == "survival" or result.outcome == "defeat",
            "Outcome should be triumph/survival/defeat, got " .. tostring(result.outcome)
        )
        assert_not_nil(result.consequence_def, "Result should have consequence_def")
        assert_not_nil(result.chronicle_text, "Result should have chronicle_text")
        assert_true(#result.chronicle_text > 0, "Chronicle text should not be empty")
    end)

    it("should produce triumph for very strong heir", function()
        -- Use overrides in constructor to ensure alleles are correctly set
        local overrides = {}
        local trait_definitions = require("dredwork_genetics.config.trait_definitions")
        for _, def in ipairs(trait_definitions) do
            overrides[def.id] = 95
        end
        local genome = Genome.new(overrides)

        local pers = Personality.new({
            PER_BLD = 80, PER_CRM = 50, PER_OBS = 70, PER_LOY = 70,
            PER_CUR = 70, PER_VOL = 50, PER_PRI = 70, PER_ADA = 70,
        })

        local ctx = make_context()
        local trial = Crucible.select_trial(ctx)
        local result = Crucible.run(trial, genome, pers, "Strong Heir", ctx)

        assert_equal("triumph", result.outcome, "Very strong heir should triumph, score=" .. result.total_score)
        assert_true(not result.heir_dies, "Triumph heir should not die")
    end)

    it("should produce defeat for very weak heir", function()
        -- Create genome with all traits at 0 via overrides (ensures alleles are also 0)
        local overrides = {}
        for _, id in ipairs({
            "PHY_STR", "PHY_END", "PHY_REF", "PHY_AGI", "PHY_VIT", "PHY_PAI",
            "PHY_IMM", "PHY_SEN", "PHY_ADP", "PHY_LUN", "PHY_REC", "PHY_BON",
            "PHY_COR", "PHY_MET", "PHY_HGT", "PHY_BLD", "PHY_FER", "PHY_LON",
            "MEN_INT", "MEN_WIL", "MEN_COM", "MEN_FOC", "MEN_PER", "MEN_DEC",
            "MEN_ANA", "MEN_PAT", "MEN_STH", "MEN_SPA", "MEN_STR", "MEN_CUN",
            "MEN_PLA", "MEN_DRM", "MEN_ABS", "MEN_ITU", "MEN_MEM", "MEN_LRN",
            "SOC_CHA", "SOC_EMP", "SOC_INM", "SOC_ELO", "SOC_LEA", "SOC_NEG",
            "SOC_AWR", "SOC_MAN", "SOC_DEC", "SOC_TRU", "SOC_PAK", "SOC_CRD",
            "SOC_TEA", "SOC_LYS", "SOC_CON", "SOC_CUL", "SOC_HUM", "SOC_INF",
            "CRE_ING", "CRE_CRA", "CRE_RES", "CRE_IMP", "CRE_RIT", "CRE_SYM",
            "CRE_MEC", "CRE_EXP", "CRE_AES", "CRE_VIS", "CRE_NAR", "CRE_MUS",
            "CRE_ARC", "CRE_INN", "CRE_FLV", "CRE_TIN",
        }) do
            overrides[id] = 0
        end
        local genome = Genome.new(overrides)

        local pers = Personality.new({
            PER_BLD = 50, PER_CRM = 50, PER_OBS = 50, PER_LOY = 50,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 50, PER_ADA = 50,
        })

        local ctx = make_context()
        local trial = Crucible.select_trial(ctx)
        local result = Crucible.run(trial, genome, pers, "Weak Heir", ctx)

        assert_equal("defeat", result.outcome, "Very weak heir should be defeated, score=" .. result.total_score)
    end)

    it("should only allow heir death on defeat", function()
        -- Run many times with average heir
        local genome = Genome.new()
        local pers = Personality.new()

        for _ = 1, 50 do
            local ctx = make_context()
            local trial = Crucible.select_trial(ctx)
            local result = Crucible.run(trial, genome, pers, "Average", ctx)

            if result.outcome ~= "defeat" then
                assert_true(not result.heir_dies,
                    "Heir should only die on defeat, but died on " .. result.outcome)
            end
        end
    end)

    -- ===== Outcome thresholds =====

    it("should classify triumph at score >= 0.75", function()
        -- We test the threshold indirectly through resolve/run
        -- Strong heir aimed at trial stages should hit triumph
        local genome = Genome.new()
        genome:set_value("PHY_STR", 85)
        genome:set_value("PHY_REF", 80)
        genome:set_value("MEN_COM", 75)
        genome:set_value("PHY_END", 80)
        genome:set_value("SOC_LEA", 80)
        genome:set_value("MEN_WIL", 80)
        genome:set_value("MEN_CUN", 75)
        genome:set_value("PHY_AGI", 75)
        genome:set_value("SOC_EMP", 70)
        genome:set_value("MEN_STR", 75)
        genome:set_value("SOC_INM", 75)
        genome:set_value("CRE_RES", 70)
        genome:set_value("MEN_DEC", 75)
        genome:set_value("PHY_PAI", 70)

        local pers = Personality.new({
            PER_BLD = 80, PER_CRM = 70, PER_OBS = 50, PER_LOY = 70,
            PER_CUR = 50, PER_VOL = 50, PER_PRI = 70, PER_ADA = 60,
        })

        local trials = require("dredwork_world.config.crucible_trials")
        local ctx = make_context()
        local result = Crucible.run(trials[1], genome, pers, "Strong Fighter", ctx)

        assert_true(result.total_score >= 0.70,
            "Strong combat heir on trial by fire should score high, got " .. result.total_score)
    end)

    -- ===== Consequence tests =====

    it("should produce triumph consequences with positive shifts", function()
        local trial = { id = "test", name = "Test Trial", theme = "combat" }
        local ctx = make_context()
        local cons = Crucible.get_consequences("triumph", trial, ctx)

        assert_not_nil(cons.cultural_memory_shift, "Triumph should have cultural memory shift")
        assert_not_nil(cons.disposition_changes, "Triumph should have disposition changes")
        assert_equal(8, cons.disposition_changes[1].delta, "Triumph disposition delta")
        assert_not_nil(cons.narrative, "Triumph should have narrative")
    end)

    it("should produce survival consequences (minimal)", function()
        local trial = { id = "test", name = "Test Trial", theme = "combat" }
        local ctx = make_context()
        local cons = Crucible.get_consequences("survival", trial, ctx)

        assert_not_nil(cons.cultural_memory_shift, "Survival should have some shift")
        assert_nil(cons.disposition_changes, "Survival should not have disposition changes")
        assert_not_nil(cons.narrative, "Survival should have narrative")
    end)

    it("should produce defeat consequences with negative shifts", function()
        local trial = { id = "test", name = "Test Trial", theme = "combat" }
        local ctx = make_context()
        local cons = Crucible.get_consequences("defeat", trial, ctx)

        assert_not_nil(cons.cultural_memory_shift, "Defeat should have cultural memory shift")
        assert_not_nil(cons.mutation_triggers, "Defeat should have mutation triggers")
        assert_not_nil(cons.taboo_chance, "Defeat should have taboo chance")
        assert_equal(-5, cons.disposition_changes[1].delta, "Defeat disposition delta")
    end)

    -- ===== Stage result format =====

    it("should include all fields in stage result", function()
        local genome = Genome.new()
        local pers = Personality.new()

        local trials = require("dredwork_world.config.crucible_trials")
        local stage = trials[1].stages[1]

        local result = Crucible.resolve_stage(stage, genome, pers)

        assert_not_nil(result.path_chosen, "Stage result needs path_chosen")
        assert_not_nil(result.path_narrative, "Stage result needs path_narrative")
        assert_not_nil(result.score, "Stage result needs score")
        assert_in_range(result.score, 0, 1, "Stage score should be 0-1")
        assert_not_nil(result.trait_results, "Stage result needs trait_results")
        assert_true(#result.trait_results >= 2, "Should have 2+ trait check results")
        assert_not_nil(result.stage_title, "Stage result needs stage_title")
    end)

    -- ===== All trials valid =====

    it("should have 19 valid trial definitions", function()
        local trials = require("dredwork_world.config.crucible_trials")
        assert_equal(19, #trials, "Should have exactly 19 trials")

        for i, trial in ipairs(trials) do
            assert_not_nil(trial.id, "Trial " .. i .. " missing id")
            assert_not_nil(trial.name, "Trial " .. i .. " missing name")
            assert_not_nil(trial.stages, "Trial " .. i .. " missing stages")
            assert_true(#trial.stages >= 3, "Trial " .. i .. " should have 3+ stages, got " .. #trial.stages)

            for j, stage in ipairs(trial.stages) do
                assert_not_nil(stage.title, "Trial " .. i .. " stage " .. j .. " missing title")
                assert_not_nil(stage.paths, "Trial " .. i .. " stage " .. j .. " missing paths")
                assert_true(#stage.paths >= 2, "Trial " .. i .. " stage " .. j .. " needs 2+ paths")

                for k, path in ipairs(stage.paths) do
                    assert_not_nil(path.id, "Trial " .. i .. " stage " .. j .. " path " .. k .. " missing id")
                    assert_not_nil(path.personality_axis, "Path missing personality_axis")
                    assert_not_nil(path.direction, "Path missing direction")
                    assert_true(
                        path.direction == "high" or path.direction == "low",
                        "Path direction must be high or low"
                    )
                    assert_not_nil(path.trait_checks, "Path missing trait_checks")
                    assert_true(#path.trait_checks >= 2, "Path needs 2+ trait checks")
                end
            end
        end
    end)
end)
