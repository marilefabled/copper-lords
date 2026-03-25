local ShadowMortality = require("dredwork_bonds.mortality")
local ShadowYear = require("dredwork_bonds.year")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowBody = require("dredwork_bonds.body")
local ShadowCareer = require("dredwork_bonds.career")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowSetup = require("dredwork_bonds.setup")
local Genome = require("dredwork_genetics.genome")
local Personality = require("dredwork_genetics.personality")

describe("ShadowMortality", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        local setup_state = ShadowSetup.new(overrides.seed or 12345)
        local run = ShadowSetup.build_run_options(setup_state)
        local gs = {
            generation = overrides.generation or 1,
            heir_name = run.heir_name,
            rng_seed = overrides.seed or 12345,
            start_era = "ancient",
            shadow_setup = run.shadow_setup,
            current_heir = Genome.new(run.traits),
            heir_personality = Personality.new(run.personality),
        }
        -- Must ensure_state BEFORE overriding shadow_state so initialization runs
        ShadowYear.ensure_state(gs)
        -- Now override with test-specific values
        if overrides.shadow_state then
            for key, value in pairs(overrides.shadow_state) do
                gs.shadow_state[key] = value
            end
        end
        ShadowBonds.ensure_state(gs)
        ShadowBody.ensure_state(gs)
        ShadowCareer.ensure_state(gs)
        ShadowClaim.ensure_state(gs)
        return gs
    end

    it("returns nil when no ending conditions met", function()
        local gs = make_game_state()
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_nil(ending)
    end)

    it("returns nil for nil game_state", function()
        assert_nil(ShadowMortality.evaluate(nil, nil))
    end)

    it("returns nil without shadow_setup", function()
        assert_nil(ShadowMortality.evaluate({}, nil))
    end)

    it("triggers collapse at low health + high stress", function()
        local gs = make_game_state({
            shadow_state = { health = 5, stress = 90, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("collapse", ending.cause)
        assert_not_nil(ending.title)
        assert_not_nil(ending.summary)
    end)

    it("triggers illness at high illness load + low health", function()
        local gs = make_game_state({
            shadow_state = { health = 15, stress = 40, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        ShadowBody.apply(gs, { illness = { id = "plague", label = "Plague", severity = 60 } })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("illness", ending.cause)
    end)

    it("triggers wounds ending at high wound load + low health", function()
        local gs = make_game_state({
            shadow_state = { health = 20, stress = 40, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        ShadowBody.apply(gs, { wound = { id = "gash", label = "Gash", severity = 60 } })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("wounds", ending.cause)
    end)

    it("triggers ruinous_habit at high compulsion + high stress", function()
        local gs = make_game_state({
            shadow_state = { health = 50, stress = 78, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        ShadowBody.apply(gs, { compulsion = { id = "drink", label = "Drink", severity = 72 } })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("ruinous_habit", ending.cause)
    end)

    it("triggers mind_breaks at extreme stress", function()
        local gs = make_game_state({
            shadow_state = { health = 30, stress = 98, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        -- Could be collapse or mind_breaks depending on health
        assert_true(ending.cause == "mind_breaks" or ending.cause == "collapse")
    end)

    it("triggers natural_frailty at age 68+", function()
        local gs = make_game_state({
            generation = 53,  -- 16 + 52 = 68
            shadow_state = { health = 50, stress = 50, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("natural_frailty", ending.cause)
    end)

    it("ending includes paragraphs", function()
        local gs = make_game_state({
            shadow_state = { health = 5, stress = 90, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending.paragraphs)
        assert_true(#ending.paragraphs >= 3, "should have at least 3 paragraphs")
    end)

    it("ending includes record_lines", function()
        local gs = make_game_state({
            shadow_state = { health = 5, stress = 90, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending.record_lines)
        assert_equal(4, #ending.record_lines)
    end)

    it("ending includes age", function()
        local gs = make_game_state({
            generation = 10,
            shadow_state = { health = 5, stress = 90, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_equal(25, ending.age, "age should be start_age + generation - 1")
    end)

    it("prison triggers for wanted burden at high notoriety", function()
        local gs = make_game_state({
            shadow_state = { health = 50, stress = 50, bonds = 50, standing = 50, notoriety = 78, craft = 50 },
        })
        gs.shadow_setup.burden = "wanted"
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("prison", ending.cause)
    end)

    it("vanished triggers at low bonds + high stress", function()
        local gs = make_game_state({
            shadow_state = { health = 50, stress = 82, bonds = 4, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("vanished", ending.cause)
    end)

    it("wasting triggers at moderate age + low health", function()
        local gs = make_game_state({
            generation = 42,  -- age 57
            shadow_state = { health = 18, stress = 50, bonds = 50, standing = 50, notoriety = 20, craft = 50 },
        })
        local ending = ShadowMortality.evaluate(gs, nil)
        assert_not_nil(ending)
        assert_equal("wasting", ending.cause)
    end)
end)
