local ShadowBody = require("dredwork_bonds.body")

describe("ShadowBody", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        return {
            generation = overrides.generation or 1,
            shadow_setup = overrides.shadow_setup or {
                start_age = 16,
                occupation = overrides.occupation or "scribe",
                burden = overrides.burden or "debt",
                vice = overrides.vice or "none",
            },
            shadow_state = overrides.shadow_state or {
                health = 50,
                stress = 50,
                bonds = 50,
                standing = 50,
                craft = 50,
                notoriety = 20,
            },
        }
    end

    it("initializes with clean state", function()
        local gs = make_game_state()
        local state = ShadowBody.ensure_state(gs)
        assert_not_nil(state)
        assert_true(state.initialized)
    end)

    it("applies burden-specific starting wounds", function()
        local gs = make_game_state({ burden = "scar" })
        ShadowBody.ensure_state(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.wound_load > 0, "scar burden should add starting wound")
        assert_equal("Bruised", snap.wound_label)
    end)

    it("applies vice-specific starting compulsions", function()
        local gs = make_game_state({ vice = "drink" })
        ShadowBody.ensure_state(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.compulsion_load > 0, "drink vice should add starting compulsion")
        assert_equal("Hooked", snap.compulsion_label)
    end)

    it("applies occupation-specific starting wounds for soldier", function()
        local gs = make_game_state({ occupation = "soldier" })
        ShadowBody.ensure_state(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.wound_load > 0, "soldier should start with campaign knots")
    end)

    it("applies occupation-specific starting wounds for laborer", function()
        local gs = make_game_state({ occupation = "laborer" })
        ShadowBody.ensure_state(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.wound_load > 0, "laborer should start with overworked back")
    end)

    it("returns clean snapshot for nil game_state", function()
        local snap = ShadowBody.snapshot(nil)
        assert_equal(0, snap.wound_load)
        assert_equal(0, snap.illness_load)
        assert_equal(0, snap.compulsion_load)
        assert_equal("Clear", snap.wound_label)
        assert_equal("Clear", snap.illness_label)
        assert_equal("Quiet", snap.compulsion_label)
    end)

    it("applies wound payloads", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "slash", label = "Slash", severity = 30 } })
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.wound_load >= 30, "wound should be applied")
    end)

    it("applies illness payloads", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { illness = { id = "fever", label = "Fever", severity = 35 } })
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.illness_load >= 35, "illness should be applied")
        assert_equal("Ailing", snap.illness_label)
    end)

    it("applies compulsion payloads", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { compulsion = { id = "dice", label = "Dice Hunger", severity = 40 } })
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.compulsion_load >= 40, "compulsion should be applied")
        assert_equal("Driven", snap.compulsion_label)
    end)

    it("relieves wounds", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "cut", label = "Cut", severity = 30 } })
        ShadowBody.apply(gs, { ease_wounds = 15 })
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.wound_load <= 15, "wounds should be relieved")
    end)

    it("relieves with preferred target", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wounds = {
            { id = "cut", label = "Cut", severity = 20 },
            { id = "bruise", label = "Bruise", severity = 10 },
        }})
        ShadowBody.apply(gs, { ease_wounds = 15, preferred_wound = "bruise" })
        local snap = ShadowBody.snapshot(gs)
        -- Bruise (10) should be fully healed, remaining 5 from cut
        assert_true(snap.wound_load <= 15, "preferred target should be healed first")
    end)

    it("removes entries at zero severity", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "scratch", label = "Scratch", severity = 5 } })
        ShadowBody.apply(gs, { ease_wounds = 10 })
        local snap = ShadowBody.snapshot(gs)
        assert_equal(0, #snap.wounds, "zero-severity entries should be removed")
    end)

    it("tick_year applies vice pressure", function()
        local gs = make_game_state({ vice = "drink" })
        gs.shadow_state.stress = 70
        ShadowBody.ensure_state(gs)
        local before = ShadowBody.snapshot(gs).compulsion_load
        ShadowBody.tick_year(gs)
        local after = ShadowBody.snapshot(gs).compulsion_load
        assert_true(after > before, "tick_year should increase vice compulsion under stress")
    end)

    it("tick_year relieves wounds when healthy", function()
        local gs = make_game_state()
        gs.shadow_state.health = 70
        gs.shadow_state.stress = 30
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "bruise", label = "Bruise", severity = 20 } })
        local before = ShadowBody.snapshot(gs).wound_load
        ShadowBody.tick_year(gs)
        local after = ShadowBody.snapshot(gs).wound_load
        assert_true(after < before, "healthy protagonist should heal wounds over time")
    end)

    it("tick_year adds illness under low health", function()
        local gs = make_game_state()
        gs.shadow_state.health = 20
        gs.shadow_state.stress = 50
        ShadowBody.ensure_state(gs)
        ShadowBody.tick_year(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.illness_load > 0, "low health should trigger illness")
    end)

    it("tick_year drains shadow health from body load", function()
        local gs = make_game_state()
        gs.shadow_state.health = 50
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "deep_cut", label = "Deep Cut", severity = 50 } })
        ShadowBody.tick_year(gs)
        assert_true(gs.shadow_state.health < 50, "body load should drain health")
    end)

    it("body_line formats correctly", function()
        local gs = make_game_state({ vice = "drink", burden = "scar" })
        ShadowBody.ensure_state(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.body_line:find("Wounds"), "body_line should mention wounds")
        assert_true(snap.body_line:find("Illness"), "body_line should mention illness")
        assert_true(snap.body_line:find("Habit"), "body_line should mention habit")
    end)

    it("severity thresholds are correct", function()
        local gs = make_game_state({ occupation = "courtier" })
        ShadowBody.ensure_state(gs)

        ShadowBody.apply(gs, { wound = { id = "w", label = "W", severity = 10 } })
        assert_equal("Clear", ShadowBody.snapshot(gs).wound_label)

        ShadowBody.apply(gs, { wound = { id = "w", label = "W", severity = 10 } })
        assert_equal("Bruised", ShadowBody.snapshot(gs).wound_label)

        ShadowBody.apply(gs, { wound = { id = "w", label = "W", severity = 20 } })
        assert_equal("Marked", ShadowBody.snapshot(gs).wound_label)

        ShadowBody.apply(gs, { wound = { id = "w", label = "W", severity = 30 } })
        assert_equal("Ravaged", ShadowBody.snapshot(gs).wound_label)
    end)

    it("handles multiple simultaneous wounds", function()
        local gs = make_game_state({ occupation = "courtier" })
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wounds = {
            { id = "a", label = "Cut A", severity = 15 },
            { id = "b", label = "Cut B", severity = 15 },
            { id = "c", label = "Cut C", severity = 15 },
        }})
        local snap = ShadowBody.snapshot(gs)
        assert_equal(3, #snap.wounds)
        assert_equal(45, snap.wound_load)
    end)

    it("scars persist from severe wounds", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "deep", label = "Deep Wound", severity = 55 } })
        local snap = ShadowBody.snapshot(gs)
        assert_true(#(snap.scars or {}) >= 1, "severe wounds should leave scars")
    end)

    it("scars never heal", function()
        local gs = make_game_state()
        gs.shadow_state.health = 90
        gs.shadow_state.stress = 10
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "deep", label = "Deep Wound", severity = 55 } })
        local before_scars = ShadowBody.snapshot(gs).scar_load or 0
        for _ = 1, 10 do
            ShadowBody.tick_year(gs)
        end
        local after_scars = ShadowBody.snapshot(gs).scar_load or 0
        assert_true(after_scars >= before_scars, "scars should never decrease")
    end)

    it("convalescence flag set under heavy load", function()
        local gs = make_game_state()
        ShadowBody.ensure_state(gs)
        ShadowBody.apply(gs, { wound = { id = "w", label = "W", severity = 40 } })
        ShadowBody.apply(gs, { illness = { id = "i", label = "I", severity = 30 } })
        ShadowBody.tick_year(gs)
        local snap = ShadowBody.snapshot(gs)
        assert_true(snap.convalescing, "heavy body load should trigger convalescence")
    end)

    it("relapse risk tracks suppressed compulsions", function()
        local gs = make_game_state({ vice = "drink" })
        ShadowBody.ensure_state(gs)
        -- Drive compulsion high then fully suppress it
        ShadowBody.apply(gs, { compulsion = { id = "drink_hunger", label = "Bottle Hunger", severity = 30 } })
        ShadowBody.apply(gs, { ease_compulsions = 200 })
        local snap = ShadowBody.snapshot(gs)
        assert_true(#(snap.relapse_risks or {}) >= 1, "suppressed high compulsion should leave relapse risk")
    end)
end)
