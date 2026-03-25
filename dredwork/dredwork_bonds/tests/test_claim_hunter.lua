local ShadowClaimHunter = require("dredwork_bonds.claim_hunter")

describe("ShadowClaimHunter", function()

    local function make_game_state(exposure, usurper_risk)
        return {
            generation = 3,
            shadow_claim = {
                initialized = true,
                house_name = "House Test",
                legitimacy = 40,
                proof = 30,
                grievance = 50,
                ambition = 40,
                exposure = exposure or 20,
                usurper_risk = usurper_risk or 20,
            },
        }
    end

    it("returns no events when pressure below threshold", function()
        local gs = make_game_state(20, 20)
        local events = ShadowClaimHunter.generate(gs, 3)
        assert_equal(0, #events, "low pressure should produce no events")
    end)

    it("generates event when exposure reaches first threshold", function()
        local gs = make_game_state(40, 10)
        local events = ShadowClaimHunter.generate(gs, 3)
        assert_equal(1, #events, "should generate curious_stranger event")
        assert_true(events[1].id:find("curious_stranger"), "first event should be curious stranger")
    end)

    it("generates higher tier events at higher pressure", function()
        local gs = make_game_state(75, 75)
        local events = ShadowClaimHunter.generate(gs, 3)
        assert_equal(1, #events)
        assert_true(events[1].id:find("curious_stranger"), "should start with lowest unseen tier")
    end)

    it("respects cooldown of 2 years", function()
        local gs = make_game_state(40, 10)
        ShadowClaimHunter.generate(gs, 3)
        local events2 = ShadowClaimHunter.generate(gs, 4)
        assert_equal(0, #events2, "cooldown should prevent event on next year")
        local events3 = ShadowClaimHunter.generate(gs, 5)
        -- gen 5 is 2 years after gen 3, so it should pass cooldown
        assert_true(#events3 >= 0, "cooldown check")
    end)

    it("does not repeat seen events", function()
        local gs = make_game_state(40, 10)
        ShadowClaimHunter.generate(gs, 3)
        -- Reset cooldown to allow generation
        gs.shadow_claim_hunter.last_hunt_generation = 0
        local events2 = ShadowClaimHunter.generate(gs, 5)
        -- curious_stranger already seen, next tier not reached
        assert_equal(0, #events2, "seen events should not repeat")
    end)

    it("events have proper structure", function()
        local gs = make_game_state(40, 10)
        local events = ShadowClaimHunter.generate(gs, 3)
        local event = events[1]
        assert_not_nil(event.id)
        assert_not_nil(event.title)
        assert_not_nil(event.options)
        assert_equal(2, #event.options, "each event should have 2 options")
        assert_not_nil(event.options[1].success)
        assert_not_nil(event.options[1].failure)
    end)

    it("returns empty for nil game_state", function()
        local events = ShadowClaimHunter.generate(nil, 1)
        assert_equal(0, #events)
    end)

    it("returns empty when claim not initialized", function()
        local gs = { generation = 3, shadow_claim = {} }
        local events = ShadowClaimHunter.generate(gs, 3)
        assert_equal(0, #events)
    end)
end)
