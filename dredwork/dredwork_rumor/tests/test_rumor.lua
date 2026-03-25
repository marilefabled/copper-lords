local Rumor = require("dredwork_rumor.rumor")

describe("Rumor Creation", function()

    it("creates a rumor from spec", function()
        local r = Rumor.create({
            origin_type = "combat",
            origin_id = "fight_1",
            generation = 3,
            subject = "Horg",
            text = "Horg lost a fight to a drunk.",
            tags = { "shame", "violence" },
            severity = 3,
        })
        assert_not_nil(r)
        assert_equal("Horg", r.subject)
        assert_equal("Horg lost a fight to a drunk.", r.original_text)
        assert_equal(r.original_text, r.current_text)
        assert_equal(90, r.truth_score)
        assert_equal(60, r.heat)
        assert_equal(0, r.reach)
        assert_equal(3, r.severity)
        assert_equal(false, r.confirmed)
        assert_equal(false, r.dead)
        assert_equal(false, r.calcified)
    end)

    it("returns nil without subject", function()
        assert_nil(Rumor.create({ text = "Something" }))
    end)

    it("returns nil for nil spec", function()
        assert_nil(Rumor.create(nil))
    end)

    it("clamps truth_score", function()
        local r = Rumor.create({ subject = "Test", truth_score = 150 })
        assert_equal(100, r.truth_score)
    end)

    it("clamps severity", function()
        local r = Rumor.create({ subject = "Test", severity = 10 })
        assert_equal(5, r.severity)
    end)

    it("generates deterministic id", function()
        local r = Rumor.create({
            origin_type = "combat",
            origin_id = "fight_1",
            generation = 3,
            subject = "Test",
        })
        assert_equal("combat:fight_1:3", r.id)
    end)

    it("defaults to sensible values", function()
        local r = Rumor.create({ subject = "Asha" })
        assert_equal("event", r.origin_type)
        assert_equal(90, r.truth_score)
        assert_equal(60, r.heat)
        assert_equal(2, r.severity)
        assert_equal("Something happened.", r.original_text)
    end)
end)
