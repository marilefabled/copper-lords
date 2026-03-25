local ShadowClaim = require("dredwork_bonds.claim")

describe("ShadowClaim", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        return {
            generation = 1,
            shadow_setup = {
                start_age = 16,
                occupation = overrides.occupation or "laborer",
                burden = overrides.burden or "debt",
                vice = overrides.vice or "none",
                faith = overrides.faith or "skeptic",
                education = overrides.education or "self",
                claim_house_name = overrides.claim_house_name or "House Ashvein",
            },
            shadow_state = overrides.shadow_state or {
                health = 50, stress = 50, bonds = 50,
                standing = 50, notoriety = 20, craft = 50,
            },
        }
    end

    it("initializes with default values", function()
        local gs = make_game_state()
        local state = ShadowClaim.ensure_state(gs)
        assert_not_nil(state)
        assert_true(state.initialized)
        assert_equal("House Ashvein", state.house_name)
        assert_equal("blood", state.path)
    end)

    it("starts as BROKEN BRANCH by default", function()
        local gs = make_game_state()
        local snap = ShadowClaim.snapshot(gs)
        assert_equal("BROKEN BRANCH", snap.status)
    end)

    it("claim burden elevates starting values", function()
        local gs = make_game_state({ burden = "claim" })
        local snap = ShadowClaim.snapshot(gs)
        assert_true(snap.legitimacy > 34, "claim burden should raise legitimacy")
        assert_true(snap.proof > 24, "claim burden should raise proof")
        assert_true(snap.grievance > 58, "claim burden should raise grievance")
    end)

    it("courtier occupation elevates legitimacy and exposure", function()
        local gs = make_game_state({ occupation = "courtier" })
        local snap = ShadowClaim.snapshot(gs)
        assert_true(snap.legitimacy > 34, "courtier should raise legitimacy")
        assert_true(snap.exposure > 16, "courtier should raise exposure")
    end)

    it("scribe occupation elevates proof", function()
        local gs = make_game_state({ occupation = "scribe" })
        local snap = ShadowClaim.snapshot(gs)
        assert_true(snap.proof > 24, "scribe should raise proof")
    end)

    it("ancestor faith elevates proof and grievance", function()
        local gs = make_game_state({ faith = "ancestor" })
        local snap = ShadowClaim.snapshot(gs)
        assert_true(snap.proof > 24, "ancestor faith should raise proof")
    end)

    it("apply changes values", function()
        local gs = make_game_state()
        ShadowClaim.ensure_state(gs)
        ShadowClaim.apply(gs, { legitimacy = 10, proof = 5, exposure = -3 })
        local snap = ShadowClaim.snapshot(gs)
        assert_true(snap.legitimacy > 34, "apply should increase legitimacy")
        assert_true(snap.proof > 24, "apply should increase proof")
    end)

    it("apply changes path", function()
        local gs = make_game_state()
        ShadowClaim.ensure_state(gs)
        ShadowClaim.apply(gs, { path = "writ" })
        local snap = ShadowClaim.snapshot(gs)
        assert_equal("writ", snap.path)
    end)

    it("clamps all values to 0-100", function()
        local gs = make_game_state()
        ShadowClaim.ensure_state(gs)
        ShadowClaim.apply(gs, { legitimacy = 200 })
        assert_equal(100, gs.shadow_claim.legitimacy)
        ShadowClaim.apply(gs, { legitimacy = -300 })
        assert_equal(0, gs.shadow_claim.legitimacy)
    end)

    it("LIVING WHISPER at legitimacy >= 46 and proof >= 38", function()
        local gs = make_game_state()
        ShadowClaim.ensure_state(gs)
        ShadowClaim.apply(gs, { legitimacy = 20, proof = 20 })
        local snap = ShadowClaim.snapshot(gs)
        assert_equal("LIVING WHISPER", snap.status)
    end)

    it("ASSERTED CLAIM at high legitimacy, proof, and exposure", function()
        local gs = make_game_state()
        ShadowClaim.ensure_state(gs)
        ShadowClaim.apply(gs, { legitimacy = 40, proof = 40, exposure = 40 })
        local snap = ShadowClaim.snapshot(gs)
        assert_equal("ASSERTED CLAIM", snap.status)
    end)

    it("tick_year drifts exposure with notoriety", function()
        local gs = make_game_state()
        gs.shadow_state.notoriety = 70
        ShadowClaim.ensure_state(gs)
        local before = gs.shadow_claim.exposure
        ShadowClaim.tick_year(gs)
        assert_true(gs.shadow_claim.exposure > before, "high notoriety should increase exposure")
    end)

    it("tick_year drifts legitimacy with standing", function()
        local gs = make_game_state()
        gs.shadow_state.standing = 60
        ShadowClaim.ensure_state(gs)
        local before = gs.shadow_claim.legitimacy
        ShadowClaim.tick_year(gs)
        assert_true(gs.shadow_claim.legitimacy > before, "high standing should increase legitimacy")
    end)

    it("tick_year drifts usurper_risk with stress", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 80
        ShadowClaim.ensure_state(gs)
        local before = gs.shadow_claim.usurper_risk
        ShadowClaim.tick_year(gs)
        assert_true(gs.shadow_claim.usurper_risk > before, "high stress should increase usurper risk")
    end)

    it("snapshot includes all label fields", function()
        local gs = make_game_state()
        local snap = ShadowClaim.snapshot(gs)
        assert_not_nil(snap.legitimacy_label)
        assert_not_nil(snap.proof_label)
        assert_not_nil(snap.grievance_label)
        assert_not_nil(snap.ambition_label)
        assert_not_nil(snap.exposure_label)
        assert_not_nil(snap.usurper_label)
        assert_not_nil(snap.reclaim_line)
        assert_not_nil(snap.state_line)
        assert_not_nil(snap.danger_line)
    end)

    it("returns nil for nil game_state", function()
        assert_nil(ShadowClaim.snapshot(nil))
    end)
end)
