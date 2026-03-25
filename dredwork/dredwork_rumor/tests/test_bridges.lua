local Bridges = require("dredwork_rumor.bridges")
local Network = require("dredwork_rumor.network")

describe("Rumor Bridges", function()

    local function make_gs()
        return { generation = 3, heir_name = "Asha" }
    end

    it("creates rumor from dominant combat win", function()
        local gs = make_gs()
        local r = Bridges.from_combat(gs, {
            result = { winner = "Asha", loser = "Horg", margin = "dominant", rounds = 4 },
        })
        assert_not_nil(r)
        assert_equal("Asha", r.subject)
        assert_equal(4, r.severity)
        assert_true(r.current_text:find("destroyed"), "dominant win text should mention destruction")
    end)

    it("creates rumor from narrow combat win", function()
        local gs = make_gs()
        local r = Bridges.from_combat(gs, {
            result = { winner = "Asha", loser = "Horg", margin = "narrow", rounds = 5 },
        })
        assert_not_nil(r)
        assert_equal(3, r.severity)
    end)

    it("creates rumor from draw", function()
        local gs = make_gs()
        local r = Bridges.from_combat(gs, {
            result = { winner = nil, loser = nil, margin = "draw", rounds = 6 },
        })
        assert_not_nil(r)
        assert_equal(2, r.severity)
    end)

    it("creates rumor from hostile secret", function()
        local gs = make_gs()
        local r = Bridges.from_secret(gs, {
            id = "secret:sabotage:bond:1",
            bond_name = "Horg",
            hostile = true,
        })
        assert_not_nil(r)
        assert_equal("Asha", r.subject)
        assert_true(r.tags[1] == "betrayal")
    end)

    it("creates rumor from friendly secret", function()
        local gs = make_gs()
        local r = Bridges.from_secret(gs, {
            id = "secret:gift:bond:2",
            bond_name = "Sev",
            hostile = false,
        })
        assert_not_nil(r)
        assert_true(r.tags[1] == "loyalty")
        assert_true(r.heat < 50, "friendly secrets should be quieter")
    end)

    it("creates rumor from collusion", function()
        local gs = make_gs()
        local r = Bridges.from_collusion(gs, {
            id = "collusion:test",
            bond_names = { "Horg", "Sev" },
        })
        assert_not_nil(r)
        assert_true(r.current_text:find("Horg"))
        assert_true(r.current_text:find("Sev"))
    end)

    it("creates rumor from claim event", function()
        local gs = make_gs()
        local r = Bridges.from_claim(gs, { id = "claim:curious_stranger" })
        assert_not_nil(r)
        assert_true(r.current_text:find("bloodline"))
    end)

    it("creates rumor from triumph year result", function()
        local gs = make_gs()
        local r = Bridges.from_year_result(gs, {
            stat_check_quality = "triumph",
            title = "Sell the Sword Again",
        })
        assert_not_nil(r)
        assert_true(r.tags[1] == "skill" or r.tags[1] == "courage")
    end)

    it("creates rumor from disaster year result", function()
        local gs = make_gs()
        local r = Bridges.from_year_result(gs, {
            stat_check_quality = "disaster",
            title = "Keep the House Rite",
        })
        assert_not_nil(r)
        assert_true(r.tags[1] == "shame")
    end)

    it("skips normal year results", function()
        local gs = make_gs()
        local r = Bridges.from_year_result(gs, {
            stat_check_quality = "success",
            title = "Work",
        })
        assert_nil(r, "only triumphs and disasters should generate rumors")
    end)

    it("creates rumor from cruelty morality act", function()
        local gs = make_gs()
        local r = Bridges.from_morality(gs, "cruelty")
        assert_not_nil(r)
        assert_true(r.current_text:find("cruel"))
    end)

    it("creates rumor from sacrifice morality act", function()
        local gs = make_gs()
        local r = Bridges.from_morality(gs, "sacrifice")
        assert_not_nil(r)
        assert_true(r.tags[1] == "honor" or r.tags[2] == "generosity")
    end)

    it("returns nil for unknown morality act", function()
        local gs = make_gs()
        assert_nil(Bridges.from_morality(gs, "dancing"))
    end)

    it("returns nil for nil inputs", function()
        assert_nil(Bridges.from_combat(nil, nil))
        assert_nil(Bridges.from_secret(nil, nil))
        assert_nil(Bridges.from_collusion(nil, nil))
        assert_nil(Bridges.from_claim(nil, nil))
        assert_nil(Bridges.from_year_result(nil, nil))
        assert_nil(Bridges.from_morality(nil, nil))
    end)
end)
