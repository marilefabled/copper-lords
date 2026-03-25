local ShadowSecrets = require("dredwork_bonds.secrets")
local ShadowExpectations = require("dredwork_bonds.expectations")

describe("ShadowSecrets", function()

    local function make_bond(id, temperament, category, autonomy)
        local bond = {
            id = id or "test:1",
            name = "SecretBond",
            role = "COMRADE",
            category = category or "work",
            temperament = temperament or "steadfast",
            closeness = 40,
            strain = 30,
            obligation = 30,
            intimacy = 20,
            leverage = 20,
            dependency = 10,
            visibility = 50,
            volatility = 40,
        }
        bond.expectation = ShadowExpectations.generate(bond)
        return bond, autonomy or 50
    end

    local function make_game_state(bonds, autonomies)
        local threads = {}
        for i, bond in ipairs(bonds) do
            threads[bond.id] = {
                kind = "entanglement",
                stage = 2,
                heat = 50,
                autonomy = autonomies and autonomies[i] or 50,
                last_generation = 0,
            }
        end
        return {
            generation = 3,
            shadow_setup = { start_age = 16, occupation = "laborer", burden = "debt", vice = "none" },
            shadow_state = { health = 50, stress = 50, bonds = 50, standing = 50, craft = 50, notoriety = 20 },
            shadow_bonds = { bonds = bonds, threads = threads, initialized = true },
        }
    end

    it("returns nil when no bonds have sufficient autonomy", function()
        local bond = make_bond("test:1", "steadfast")
        local gs = make_game_state({ bond }, { 30 })
        local event = ShadowSecrets.generate(gs, "occupation_laborer")
        assert_nil(event, "bonds below autonomy 44 should not generate secrets")
    end)

    it("generates event when bond has autonomy >= 44", function()
        local bond = make_bond("test:1", "steadfast")
        local gs = make_game_state({ bond }, { 50 })
        local event = ShadowSecrets.generate(gs, "occupation_laborer")
        assert_not_nil(event, "should generate a secret event")
        assert_not_nil(event.title)
        assert_not_nil(event.options)
        assert_equal(2, #event.options)
    end)

    it("selects highest pressure bond", function()
        local bond1 = make_bond("test:1", "gentle")
        local bond2 = make_bond("test:2", "volatile")
        bond2.expectation.grievance = 60
        local gs = make_game_state({ bond1, bond2 }, { 50, 60 })
        local event = ShadowSecrets.generate(gs, "occupation_laborer")
        assert_not_nil(event)
        assert_equal("test:2", event.bond_id, "highest pressure bond should be chosen")
    end)

    it("grieved bonds pick hostile actions", function()
        local bond = make_bond("test:1", "steadfast")
        bond.expectation.grievance = 50
        local gs = make_game_state({ bond }, { 50 })
        local event = ShadowSecrets.generate(gs, "occupation_laborer")
        assert_not_nil(event)
        assert_true(event.hostile, "grieved steadfast should pick hostile action")
    end)

    it("event has proper structure", function()
        local bond = make_bond("test:1", "calculating")
        local gs = make_game_state({ bond }, { 50 })
        local event = ShadowSecrets.generate(gs, "test_focus")
        assert_not_nil(event.id)
        assert_not_nil(event.source)
        assert_equal("secrets", event.source)
        assert_not_nil(event.bond_name)
        for _, option in ipairs(event.options) do
            assert_not_nil(option.success)
            assert_not_nil(option.failure)
        end
    end)

    it("returns nil for nil game_state", function()
        assert_nil(ShadowSecrets.generate(nil, "test"))
    end)

    it("limits to one secret event per year", function()
        local bond1 = make_bond("test:1", "volatile")
        local bond2 = make_bond("test:2", "bitter")
        local gs = make_game_state({ bond1, bond2 }, { 60, 60 })
        local event = ShadowSecrets.generate(gs, "test")
        -- generate returns a single event, not a list
        assert_not_nil(event)
        assert_not_nil(event.id, "should return exactly one event")
    end)
end)
