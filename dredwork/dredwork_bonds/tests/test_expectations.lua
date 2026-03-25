local ShadowExpectations = require("dredwork_bonds.expectations")

describe("ShadowExpectations", function()

    local function make_bond(temperament, overrides)
        overrides = overrides or {}
        return {
            id = overrides.id or "test:1",
            name = overrides.name or "Testbond",
            role = "COMRADE",
            category = overrides.category or "work",
            temperament = temperament,
            closeness = overrides.closeness or 40,
            strain = overrides.strain or 20,
            obligation = overrides.obligation or 30,
            intimacy = overrides.intimacy or 20,
            leverage = overrides.leverage or 20,
            dependency = overrides.dependency or 10,
            visibility = overrides.visibility or 40,
            volatility = overrides.volatility or 30,
        }
    end

    local function make_game_state(bonds)
        return {
            generation = 3,
            shadow_setup = { start_age = 16, occupation = "laborer", burden = "debt", vice = "none" },
            shadow_state = { health = 50, stress = 50, bonds = 50, standing = 50, craft = 50, notoriety = 20 },
            shadow_body = { wounds = {}, illnesses = {}, compulsions = {}, scars = {}, initialized = true },
            shadow_bonds = { bonds = bonds, threads = {}, initialized = true },
        }
    end

    it("generates expectation for each temperament", function()
        local temperaments = { "steadfast", "hungry", "gentle", "volatile", "devout", "calculating", "curious", "bitter" }
        local expected_types = { "loyalty", "advancement", "protection", "attention", "piety", "usefulness", "honesty", "acknowledgment" }
        for i, t in ipairs(temperaments) do
            local bond = make_bond(t)
            local exp = ShadowExpectations.generate(bond)
            assert_not_nil(exp, "should generate expectation for " .. t)
            assert_equal(expected_types[i], exp.type, "wrong type for " .. t)
            assert_equal(0, exp.grievance, "should start with 0 grievance")
            assert_equal(false, exp.violated, "should not start violated")
        end
    end)

    it("falls back to steadfast for unknown temperament", function()
        local bond = make_bond("nonexistent")
        local exp = ShadowExpectations.generate(bond)
        assert_equal("loyalty", exp.type)
    end)

    it("detects loyalty violation when bonds are low", function()
        local bond = make_bond("steadfast")
        bond.expectation = ShadowExpectations.generate(bond)
        local gs = make_game_state({ bond })
        gs.shadow_state.bonds = 20
        local lines = ShadowExpectations.check_violations(gs)
        assert_true(bond.expectation.grievance > 0, "grievance should increase on violation")
        assert_true(bond.expectation.violation_count >= 1, "violation count should increase")
    end)

    it("does not violate when conditions are not met", function()
        local bond = make_bond("steadfast")
        bond.expectation = ShadowExpectations.generate(bond)
        local gs = make_game_state({ bond })
        gs.shadow_state.bonds = 60
        ShadowExpectations.check_violations(gs)
        assert_equal(0, bond.expectation.grievance, "no violation should mean no grievance")
    end)

    it("grievance persists and accumulates", function()
        local bond = make_bond("steadfast")
        bond.expectation = ShadowExpectations.generate(bond)
        local gs = make_game_state({ bond })
        gs.shadow_state.bonds = 20
        ShadowExpectations.check_violations(gs)
        local first = bond.expectation.grievance
        ShadowExpectations.check_violations(gs)
        assert_true(bond.expectation.grievance > first, "grievance should accumulate")
    end)

    it("reveals at grievance threshold 30", function()
        local bond = make_bond("steadfast")
        bond.expectation = ShadowExpectations.generate(bond)
        local gs = make_game_state({ bond })
        gs.shadow_state.bonds = 10
        -- Drive grievance up
        for _ = 1, 5 do
            ShadowExpectations.check_violations(gs)
        end
        assert_true(bond.expectation.revealed, "should reveal after crossing threshold")
    end)

    it("counts grievances above threshold", function()
        local bond1 = make_bond("steadfast", { id = "test:1" })
        bond1.expectation = ShadowExpectations.generate(bond1)
        bond1.expectation.grievance = 65
        local bond2 = make_bond("hungry", { id = "test:2" })
        bond2.expectation = ShadowExpectations.generate(bond2)
        bond2.expectation.grievance = 70
        local gs = make_game_state({ bond1, bond2 })
        assert_equal(2, ShadowExpectations.grievance_count(gs, 60))
        assert_equal(1, ShadowExpectations.grievance_count(gs, 68))
    end)

    it("apply adds strain from grievance", function()
        local bond = make_bond("steadfast")
        bond.expectation = ShadowExpectations.generate(bond)
        bond.expectation.grievance = 60
        local gs = make_game_state({ bond })
        local before_strain = bond.strain
        ShadowExpectations.apply(gs)
        assert_true(bond.strain > before_strain, "grievance should add strain")
    end)

    it("snapshot returns nil for bond without expectation", function()
        local bond = { id = "test:1" }
        assert_nil(ShadowExpectations.snapshot(bond))
    end)

    it("snapshot returns correct data", function()
        local bond = make_bond("bitter")
        bond.expectation = ShadowExpectations.generate(bond)
        bond.expectation.grievance = 42
        local snap = ShadowExpectations.snapshot(bond)
        assert_equal("acknowledgment", snap.type)
        assert_equal(42, snap.grievance)
    end)
end)
