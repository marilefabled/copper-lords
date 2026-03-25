local Network = require("dredwork_rumor.network")

describe("Rumor Network", function()

    local function make_gs(generation)
        return { generation = generation or 1, heir_name = "Asha" }
    end

    local function make_carriers(count)
        local carriers = {}
        for i = 1, (count or 4) do
            carriers[#carriers + 1] = {
                id = "bond:" .. i,
                name = "Bond" .. i,
                visibility = 40 + i * 8,
                volatility = 20 + i * 5,
                temperament = "steadfast",
            }
        end
        return carriers
    end

    it("ensures state on fresh game_state", function()
        local gs = make_gs()
        local state = Network.ensure_state(gs)
        assert_not_nil(state.rumors)
        assert_not_nil(state.reputation)
    end)

    it("injects a rumor", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            origin_type = "combat",
            origin_id = "fight_1",
            generation = 1,
            subject = "Horg",
            text = "Horg lost badly.",
            tags = { "shame" },
            severity = 3,
        })
        assert_not_nil(rumor)
        assert_equal("Horg", rumor.subject)
        assert_not_nil(gs.rumor_network.rumors[rumor.id])
    end)

    it("deduplicates by boosting heat", function()
        local gs = make_gs()
        local r1 = Network.inject(gs, {
            origin_type = "combat", origin_id = "f1", generation = 1,
            subject = "Asha", text = "Lost a fight.", severity = 2,
        })
        local heat_before = r1.heat
        local r2 = Network.inject(gs, {
            origin_type = "combat", origin_id = "f1", generation = 1,
            subject = "Asha", text = "Lost a fight.", severity = 3,
        })
        assert_equal(r1.id, r2.id)
        assert_true(r2.heat > heat_before, "heat should increase on duplicate")
        assert_equal(3, r2.severity, "severity should take the higher value")
    end)

    it("spreads to carriers", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Asha", text = "Did something.", severity = 3, heat = 70,
        })
        local carrier = { id = "bond:1", name = "Horg", visibility = 50, volatility = 30 }
        local heard = Network.spread_to(gs, rumor.id, carrier)
        assert_true(heard, "first spread should return true")
        assert_equal(1, rumor.reach)

        local heard2 = Network.spread_to(gs, rumor.id, carrier)
        assert_true(not heard2, "second spread to same carrier should return false")
        assert_equal(1, rumor.reach, "reach should not increase on re-hear")
    end)

    it("propagates through carrier list", function()
        local gs = make_gs()
        Network.inject(gs, {
            subject = "Asha", text = "Something happened.", severity = 3, heat = 70,
        })
        local carriers = make_carriers(5)
        local lines = Network.propagate(gs, carriers)
        -- Should have spread to some carriers
        local state = Network.ensure_state(gs)
        local rumor = nil
        for _, r in pairs(state.rumors) do rumor = r; break end
        assert_true(rumor.reach >= 2, "should spread to multiple carriers: " .. rumor.reach)
    end)

    it("mutations degrade truth score", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Original.", truth_score = 90, heat = 80, severity = 3,
        })
        -- Spread to high-volatility carriers to trigger mutations
        for i = 1, 6 do
            Network.spread_to(gs, rumor.id, {
                id = "c:" .. i, name = "C" .. i, visibility = 60, volatility = 80,
            })
        end
        assert_true(rumor.truth_score < 90, "mutations should degrade truth: " .. rumor.truth_score)
        assert_true(rumor.mutations >= 1, "should have at least one mutation")
    end)

    it("tick cools heat", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Something.", heat = 50, severity = 2,
        })
        Network.tick(gs, 2)
        assert_true(rumor.heat < 50, "heat should decrease: " .. rumor.heat)
    end)

    it("tick kills rumors at zero heat", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Fading.", heat = 10, severity = 1,
        })
        for gen = 2, 5 do
            Network.tick(gs, gen)
        end
        assert_true(rumor.dead, "low heat rumors should die")
    end)

    it("tick calcifies high-reach high-severity rumors", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Asha", text = "Did something terrible.", heat = 80, severity = 4,
            tags = { "shame" },
        })
        -- Spread to enough carriers
        for i = 1, 5 do
            Network.spread_to(gs, rumor.id, {
                id = "c:" .. i, name = "C" .. i, visibility = 60, volatility = 20,
            })
        end
        -- Tick forward enough generations
        Network.tick(gs, 3)
        assert_true(rumor.calcified, "high-reach high-severity rumor should calcify")
        local rep = Network.reputation(gs, "Asha")
        assert_true(rep.score < 0, "shameful rumor should lower reputation")
    end)

    it("confirm boosts heat and truth", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Truth.", heat = 40, truth_score = 70, severity = 2,
        })
        Network.confirm(gs, rumor.id)
        assert_true(rumor.confirmed)
        assert_true(rumor.heat > 40, "confirm should boost heat")
        assert_true(rumor.truth_score > 70, "confirm should boost truth")
    end)

    it("deny reduces heat for false rumors", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Lie.", heat = 50, truth_score = 30, severity = 2,
        })
        Network.deny(gs, rumor.id)
        assert_true(rumor.denied)
        assert_true(rumor.heat < 50, "denying a false rumor should cool it")
    end)

    it("deny backfires for true rumors", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Test", text = "Truth.", heat = 50, truth_score = 80, severity = 2,
        })
        Network.deny(gs, rumor.id)
        assert_true(rumor.heat > 50, "denying a true rumor should boost heat")
        assert_true(rumor.severity > 2, "denying a true rumor should increase severity")
    end)

    it("weaponize spreads to target carrier", function()
        local gs = make_gs()
        local rumor = Network.inject(gs, {
            subject = "Target", text = "Dirt.", heat = 40, severity = 3,
        })
        local target = { id = "target:1", name = "Victim", visibility = 60, volatility = 30 }
        local ok = Network.weaponize(gs, rumor.id, target)
        assert_true(ok, "weaponize should spread successfully")
        assert_true(rumor.heat > 40, "weaponize should boost heat")
    end)

    it("about returns rumors for subject", function()
        local gs = make_gs()
        Network.inject(gs, { subject = "Asha", text = "R1.", severity = 2, id = "r1" })
        Network.inject(gs, { subject = "Horg", text = "R2.", severity = 2, id = "r2" })
        Network.inject(gs, { subject = "Asha", text = "R3.", severity = 3, id = "r3" })
        local about = Network.about(gs, "Asha")
        assert_equal(2, #about, "should find 2 rumors about Asha")
    end)

    it("known_by returns rumors a carrier has heard", function()
        local gs = make_gs()
        local r = Network.inject(gs, { subject = "Test", text = "X.", heat = 70, severity = 3 })
        Network.spread_to(gs, r.id, { id = "b:1", name = "B1", visibility = 60, volatility = 20 })
        local known = Network.known_by(gs, "b:1")
        assert_equal(1, #known)
    end)

    it("hottest returns sorted by heat", function()
        local gs = make_gs()
        Network.inject(gs, { subject = "A", text = "Cold.", heat = 20, severity = 2, id = "cold" })
        Network.inject(gs, { subject = "B", text = "Hot.", heat = 80, severity = 3, id = "hot" })
        Network.inject(gs, { subject = "C", text = "Warm.", heat = 50, severity = 2, id = "warm" })
        local hot = Network.hottest(gs, 2)
        assert_equal(2, #hot)
        assert_equal("B", hot[1].subject, "hottest should be first")
    end)

    it("chronicle_fragments produces narrative", function()
        local gs = make_gs()
        local r = Network.inject(gs, {
            subject = "Asha", text = "Asha betrayed someone.", heat = 80, severity = 4,
            tags = { "betrayal" },
        })
        for i = 1, 5 do
            Network.spread_to(gs, r.id, { id = "c:" .. i, name = "C" .. i, visibility = 60, volatility = 20 })
        end
        Network.tick(gs, 3)
        local frags = Network.chronicle_fragments(gs)
        assert_true(#frags >= 1, "should produce fragments")
    end)

    it("returns empty for nil game_state", function()
        assert_equal(0, #Network.about(nil, "x"))
        assert_equal(0, #Network.known_by(nil, "x"))
        assert_equal(0, #Network.hottest(nil))
        assert_equal(0, Network.reputation(nil, "x").score)
    end)
end)
