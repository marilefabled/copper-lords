local ShadowWitnesses = require("dredwork_bonds.witnesses")

describe("ShadowWitnesses", function()

    local function make_bond(id, visibility, closeness, strain)
        return {
            id = id or "test:1",
            name = "Bond" .. (id or "1"),
            visibility = visibility or 50,
            closeness = closeness or 40,
            strain = strain or 20,
            category = "work",
        }
    end

    local function make_game_state(bonds)
        return {
            generation = 3,
            shadow_bonds = {
                bonds = bonds or {},
                initialized = true,
                threads = {},
            },
        }
    end

    it("selects witnesses with visibility >= 44", function()
        local bonds = {
            make_bond("a", 50),
            make_bond("b", 30),
            make_bond("c", 60),
        }
        local gs = make_game_state(bonds)
        local selected = ShadowWitnesses.select_witnesses(gs, "test_act")
        assert_equal(2, #selected, "only bonds with visibility >= 44 should be selected")
    end)

    it("caps witnesses at max_count", function()
        local bonds = {
            make_bond("a", 80),
            make_bond("b", 70),
            make_bond("c", 60),
            make_bond("d", 55),
        }
        local gs = make_game_state(bonds)
        local selected = ShadowWitnesses.select_witnesses(gs, "test_act", 2)
        assert_equal(2, #selected, "should cap at max_count")
    end)

    it("records witness entries in ledger", function()
        local bonds = { make_bond("a", 50) }
        local gs = make_game_state(bonds)
        ShadowWitnesses.record(gs, "fought", "condemning", 3)
        local ledger = gs.shadow_bonds.witness_ledger
        assert_not_nil(ledger["a"], "should have ledger entry")
        assert_equal(1, #ledger["a"], "should have one entry")
        assert_equal(-1, ledger["a"][1].weight)
    end)

    it("reputation score sums weights", function()
        local bonds = { make_bond("a", 50) }
        local gs = make_game_state(bonds)
        ShadowWitnesses.record(gs, "act1", "approving", 1)
        ShadowWitnesses.record(gs, "act2", "condemning", 2)
        ShadowWitnesses.record(gs, "act3", "condemning", 3)
        local score = ShadowWitnesses.reputation_score(gs, "a")
        assert_equal(-1, score, "1 approve + 2 condemn = -1")
    end)

    it("chronicle fragments describe judgments", function()
        local bonds = { make_bond("a", 50) }
        local gs = make_game_state(bonds)
        ShadowWitnesses.record(gs, "act1", "condemning", 1)
        ShadowWitnesses.record(gs, "act2", "condemning", 2)
        ShadowWitnesses.record(gs, "act3", "condemning", 3)
        local fragments = ShadowWitnesses.chronicle_fragments(gs)
        assert_true(#fragments >= 1, "should produce fragments")
        assert_true(fragments[1]:find("harshly"), "should mention harsh judgment")
    end)

    it("returns empty fragments when no witnesses", function()
        local gs = make_game_state({})
        local fragments = ShadowWitnesses.chronicle_fragments(gs)
        assert_equal(0, #fragments)
    end)

    it("returns empty for nil game_state", function()
        local selected = ShadowWitnesses.select_witnesses(nil, "test")
        assert_equal(0, #selected)
        assert_equal(0, ShadowWitnesses.reputation_score(nil, "a"))
    end)
end)
