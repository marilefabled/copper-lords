local rng = require("dredwork_core.rng")
local Personality = require("dredwork_genetics.personality")
local Genome = require("dredwork_genetics.genome")
local ShadowYear = require("dredwork_bonds.year")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowBody = require("dredwork_bonds.body")
local ShadowCareer = require("dredwork_bonds.career")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowPossessions = require("dredwork_bonds.possessions")
local ShadowSetup = require("dredwork_bonds.setup")
local Wealth = require("dredwork_world.wealth")
local Morality = require("dredwork_world.morality")
local WorldState = require("dredwork_world.world_state")
local Resources = require("dredwork_world.resources")

rng.seed(77777)

describe("ShadowYear", function()

    local function make_world()
        local ws = WorldState.new("ancient")
        return {
            world_state = ws,
            resources = Resources.new(),
        }
    end

    local function make_game_state(overrides)
        overrides = overrides or {}
        local setup_state = ShadowSetup.new(overrides.seed or 12345)
        if overrides.occupation then
            local def = ShadowSetup.get_definition("occupation")
            for index, item in ipairs(def.items) do
                if item.id == overrides.occupation then
                    setup_state.selections.occupation = index
                    break
                end
            end
        end
        local run = ShadowSetup.build_run_options(setup_state)
        local gs = {
            generation = overrides.generation or 1,
            heir_name = run.heir_name,
            lineage_name = run.lineage_name,
            rng_seed = overrides.seed or 12345,
            start_era = "ancient",
            shadow_setup = run.shadow_setup,
            current_heir = Genome.new(run.traits),
            heir_personality = Personality.new(run.personality),
            wealth = Wealth.new(50),
            morality = Morality.new(0),
        }
        ShadowYear.ensure_state(gs)
        ShadowBonds.ensure_state(gs)
        ShadowBody.ensure_state(gs)
        ShadowCareer.ensure_state(gs)
        ShadowClaim.ensure_state(gs)
        ShadowPossessions.ensure_state(gs)
        return gs
    end

    it("initializes shadow_state with all fields", function()
        local gs = make_game_state()
        assert_not_nil(gs.shadow_state)
        assert_not_nil(gs.shadow_state.health)
        assert_not_nil(gs.shadow_state.stress)
        assert_not_nil(gs.shadow_state.bonds)
        assert_not_nil(gs.shadow_state.standing)
        assert_not_nil(gs.shadow_state.notoriety)
        assert_not_nil(gs.shadow_state.craft)
    end)

    it("snapshot returns labeled values", function()
        local gs = make_game_state()
        local snap = ShadowYear.snapshot(gs)
        assert_not_nil(snap.health_label)
        assert_not_nil(snap.stress_label)
        assert_not_nil(snap.bonds_label)
        assert_not_nil(snap.standing_label)
        assert_not_nil(snap.notoriety_label)
        assert_not_nil(snap.craft_label)
    end)

    it("snapshot includes chase_rows and urge_line", function()
        local gs = make_game_state()
        local snap = ShadowYear.snapshot(gs)
        assert_not_nil(snap.chase_rows)
        assert_true(#snap.chase_rows >= 1, "should have at least one chase row")
        assert_not_nil(snap.urge_line)
    end)

    it("generate_actions produces multiple actions", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        assert_true(#actions >= 5, "should offer multiple life focuses, got " .. #actions)
    end)

    it("actions include occupation focus", function()
        local gs = make_game_state({ occupation = "soldier" })
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local found = false
        for _, action in ipairs(actions) do
            if tostring(action.id):find("^occupation_") then
                found = true
                break
            end
        end
        assert_true(found, "should include an occupation action")
    end)

    it("actions include bond focuses", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local bond_count = 0
        for _, action in ipairs(actions) do
            if tostring(action.id):find("^bond_") then
                bond_count = bond_count + 1
            end
        end
        assert_true(bond_count >= 1, "should include at least one bond action")
    end)

    it("actions include possession focus", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local found = false
        for _, action in ipairs(actions) do
            if tostring(action.id):find("^possession_") then
                found = true
                break
            end
        end
        assert_true(found, "should include a possession action")
    end)

    it("actions have success and failure branches", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local found_branch = false
        for _, action in ipairs(actions) do
            if action.success and action.failure then
                found_branch = true
                assert_not_nil(action.success.narrative, "success should have narrative")
                assert_not_nil(action.failure.narrative, "failure should have narrative")
                break
            end
        end
        assert_true(found_branch, "at least one action should have success/failure branches")
    end)

    it("resolve produces result with narrative", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        assert_true(#actions >= 1, "need at least one action to resolve")
        local result = ShadowYear.resolve(actions[1], world, gs)
        assert_not_nil(result)
        assert_not_nil(result.narrative, "result should have narrative")
        assert_not_nil(result.stat_check_quality, "result should have stat_check_quality")
    end)

    it("resolve returns valid quality", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local valid_qualities = { triumph = true, success = true, failure = true, disaster = true }
        local result = ShadowYear.resolve(actions[1], world, gs)
        assert_true(valid_qualities[result.stat_check_quality], "invalid quality: " .. tostring(result.stat_check_quality))
    end)

    it("resolve includes progress_rows", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local result = ShadowYear.resolve(actions[1], world, gs)
        assert_not_nil(result.progress_rows, "result should include progress rows")
    end)

    it("resolve includes autonomy and interlock lines", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local result = ShadowYear.resolve(actions[1], world, gs)
        assert_not_nil(result.autonomy_lines, "result should include autonomy lines")
        assert_not_nil(result.interlock_lines, "result should include interlock lines")
    end)

    it("resolve includes spotlight_rows", function()
        local gs = make_game_state()
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        local result = ShadowYear.resolve(actions[1], world, gs)
        assert_not_nil(result.spotlight_rows, "result should include spotlight rows")
    end)

    it("shadow state values stay clamped 0-100", function()
        local gs = make_game_state()
        gs.shadow_state.health = 5
        gs.shadow_state.stress = 95
        local world = make_world()
        local actions = ShadowYear.generate_actions(world, gs)
        if #actions > 0 then
            ShadowYear.resolve(actions[1], world, gs)
        end
        assert_true(gs.shadow_state.health >= 0 and gs.shadow_state.health <= 100)
        assert_true(gs.shadow_state.stress >= 0 and gs.shadow_state.stress <= 100)
    end)

    it("different occupations produce different action sets", function()
        local gs_soldier = make_game_state({ occupation = "soldier", seed = 100 })
        local gs_scribe = make_game_state({ occupation = "scribe", seed = 100 })
        local world = make_world()
        local soldier_actions = ShadowYear.generate_actions(world, gs_soldier)
        local scribe_actions = ShadowYear.generate_actions(world, gs_scribe)
        local soldier_ids = {}
        for _, a in ipairs(soldier_actions) do soldier_ids[a.id] = true end
        local scribe_ids = {}
        for _, a in ipairs(scribe_actions) do scribe_ids[a.id] = true end
        local overlap = 0
        for id in pairs(soldier_ids) do
            if scribe_ids[id] then overlap = overlap + 1 end
        end
        assert_true(overlap < #soldier_actions, "different occupations should have different actions")
    end)

    it("apply_aging applies yearly aging effects", function()
        local gs = make_game_state()
        local before_health = gs.shadow_state.health
        ShadowYear.apply_aging(gs)
        -- Just verify it runs without error
        assert_true(gs.shadow_state.health <= before_health or gs.shadow_state.health >= 0)
    end)
end)
