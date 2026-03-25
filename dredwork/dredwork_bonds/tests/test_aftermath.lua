local rng = require("dredwork_core.rng")
local Personality = require("dredwork_genetics.personality")
local Genome = require("dredwork_genetics.genome")
local ShadowAftermath = require("dredwork_bonds.aftermath")
local ShadowYear = require("dredwork_bonds.year")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowBody = require("dredwork_bonds.body")
local ShadowCareer = require("dredwork_bonds.career")
local ShadowClaim = require("dredwork_bonds.claim")
local ShadowPossessions = require("dredwork_bonds.possessions")
local ShadowSetup = require("dredwork_bonds.setup")
local Wealth = require("dredwork_world.wealth")
local Morality = require("dredwork_world.morality")

rng.seed(88888)

describe("ShadowAftermath", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        local setup_state = ShadowSetup.new(overrides.seed or 12345)
        local run = ShadowSetup.build_run_options(setup_state)
        local gs = {
            generation = overrides.generation or 10,
            heir_name = run.heir_name,
            lineage_name = run.lineage_name,
            rng_seed = overrides.seed or 12345,
            start_era = "ancient",
            shadow_setup = run.shadow_setup,
            current_heir = Genome.new(run.traits),
            heir_personality = Personality.new(run.personality),
            wealth = Wealth.new(50),
            morality = Morality.new(0),
            shadow_state = overrides.shadow_state or {
                health = 30, stress = 60, bonds = 40,
                standing = 45, notoriety = 35, craft = 50,
            },
        }
        ShadowYear.ensure_state(gs)
        ShadowBonds.ensure_state(gs)
        ShadowBody.ensure_state(gs)
        ShadowCareer.ensure_state(gs)
        ShadowClaim.ensure_state(gs)
        ShadowPossessions.ensure_state(gs)
        return gs
    end

    local function make_ending(cause)
        return {
            cause = cause or "collapse",
            title = "The Body Gives Its Final Answer",
            summary = "Test ending.",
        }
    end

    it("returns nil for nil game_state", function()
        assert_nil(ShadowAftermath.compile(nil, nil, nil))
    end)

    it("returns nil without shadow_setup", function()
        assert_nil(ShadowAftermath.compile({}, nil, nil))
    end)

    it("compiles a full aftermath record", function()
        local gs = make_game_state()
        local ending = make_ending("collapse")
        local aftermath = ShadowAftermath.compile(gs, nil, ending)
        assert_not_nil(aftermath)
        assert_not_nil(aftermath.heir_name)
        assert_not_nil(aftermath.age_at_death)
        assert_not_nil(aftermath.cause)
        assert_not_nil(aftermath.final_title)
        assert_not_nil(aftermath.claim_status)
        assert_not_nil(aftermath.ghost_weight)
        assert_not_nil(aftermath.legacy_lines)
    end)

    it("calculates age correctly", function()
        local gs = make_game_state({ generation = 20 })
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        assert_equal(35, aftermath.age_at_death, "16 + 19 = 35")
        assert_equal(19, aftermath.years_lived)
    end)

    it("includes surviving bonds", function()
        local gs = make_game_state()
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        assert_true(type(aftermath.surviving_bonds) == "table")
        assert_true(aftermath.surviving_bond_count >= 0)
    end)

    it("includes inheritable possessions", function()
        local gs = make_game_state()
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        assert_true(type(aftermath.inheritable_possessions) == "table")
    end)

    it("echo reflects claim status", function()
        local gs = make_game_state()
        ShadowClaim.apply(gs, { legitimacy = 40, proof = 40, exposure = 40 })
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        assert_equal("ASSERTED CLAIM", aftermath.echo.claim_status)
        assert_equal("heavy", aftermath.echo.weight)
    end)

    it("ghost_weight increases for betrayal", function()
        local gs = make_game_state()
        local normal = ShadowAftermath.compile(gs, nil, make_ending("collapse"))
        local betrayed = ShadowAftermath.compile(gs, nil, make_ending("betrayed"))
        assert_true(betrayed.ghost_weight > normal.ghost_weight, "betrayal should increase ghost weight")
    end)

    it("ghost_weight increases for young death", function()
        local young = make_game_state({ generation = 3 })
        local old = make_game_state({ generation = 50 })
        local young_aftermath = ShadowAftermath.compile(young, nil, make_ending())
        local old_aftermath = ShadowAftermath.compile(old, nil, make_ending())
        assert_true(young_aftermath.ghost_weight > old_aftermath.ghost_weight, "young death should weigh heavier")
    end)

    it("legacy_lines includes at least one line", function()
        local gs = make_game_state()
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        assert_true(#aftermath.legacy_lines >= 1)
    end)

    it("legacy_lines mentions claim for asserted", function()
        local gs = make_game_state()
        ShadowClaim.apply(gs, { legitimacy = 40, proof = 40, exposure = 40 })
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        local found = false
        for _, line in ipairs(aftermath.legacy_lines) do
            if line:find("claim") or line:find("public knowledge") then
                found = true
                break
            end
        end
        assert_true(found, "asserted claim should be mentioned in legacy lines")
    end)

    it("seed_next_life produces a seed", function()
        local gs = make_game_state()
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        local seed = ShadowAftermath.seed_next_life(aftermath)
        assert_not_nil(seed)
        assert_not_nil(seed.previous_name)
        assert_not_nil(seed.previous_house)
        assert_not_nil(seed.ghost_weight)
    end)

    it("seed_next_life returns nil for nil aftermath", function()
        assert_nil(ShadowAftermath.seed_next_life(nil))
    end)

    it("seed_next_life includes claim bonus for asserted claims", function()
        local gs = make_game_state()
        ShadowClaim.apply(gs, { legitimacy = 40, proof = 40, exposure = 40 })
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        local seed = ShadowAftermath.seed_next_life(aftermath)
        assert_not_nil(seed.claim_bonus, "asserted claim should pass bonus to next life")
        assert_true(seed.claim_bonus.legitimacy > 0)
    end)

    it("seed_next_life includes surviving bonds as memories", function()
        local gs = make_game_state()
        -- Boost a bond's closeness to ensure it survives
        ShadowBonds.apply_event(gs, { id = gs.shadow_bonds.bonds[1].id, closeness = 30 })
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending())
        local seed = ShadowAftermath.seed_next_life(aftermath)
        assert_true(#seed.surviving_bonds >= 1, "close bonds should persist as memories")
        assert_true(seed.surviving_bonds[1].role:find("MEMORY"), "surviving bonds should be reframed as memories")
    end)

    it("seed_next_life includes starting notoriety for heavy ghosts", function()
        local gs = make_game_state({
            shadow_state = { health = 30, stress = 60, bonds = 40, standing = 70, notoriety = 70, craft = 50 },
        })
        ShadowClaim.apply(gs, { legitimacy = 30, proof = 20 })
        gs.shadow_career.rank = 70
        local aftermath = ShadowAftermath.compile(gs, nil, make_ending("betrayed"))
        local seed = ShadowAftermath.seed_next_life(aftermath)
        if aftermath.ghost_weight >= 50 then
            assert_true(seed.starting_notoriety > 0, "heavy ghost should pass notoriety")
        end
    end)
end)
