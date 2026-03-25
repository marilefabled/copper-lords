local ShadowCollusion = require("dredwork_bonds.collusion")

describe("ShadowCollusion", function()

    local function make_bond(id, category, heat, autonomy)
        return {
            id = id,
            name = "Bond" .. id,
            category = category or "work",
            closeness = 40,
            strain = 30,
            visibility = 50,
            volatility = 40,
        }, heat or 50, autonomy or 50
    end

    local function make_game_state(bond_specs)
        local bonds = {}
        local threads = {}
        for _, spec in ipairs(bond_specs) do
            local bond = {
                id = spec.id,
                name = "Bond" .. spec.id,
                category = spec.category,
                closeness = 40,
                strain = 30,
                visibility = 50,
                volatility = 40,
            }
            bonds[#bonds + 1] = bond
            threads[spec.id] = {
                kind = "entanglement",
                stage = 2,
                heat = spec.heat or 50,
                autonomy = spec.autonomy or 50,
                last_generation = 0,
            }
        end
        return {
            generation = 5,
            shadow_bonds = {
                bonds = bonds,
                threads = threads,
                initialized = true,
                collusion_cooldowns = {},
            },
        }
    end

    it("detects rival+power pair", function()
        local gs = make_game_state({
            { id = "a", category = "rival", heat = 55, autonomy = 50 },
            { id = "b", category = "power", heat = 55, autonomy = 50 },
        })
        local events = ShadowCollusion.generate(gs, 5)
        assert_equal(1, #events, "should generate collusion event for rival+power")
        assert_true(events[1].id:find("leverage_conspiracy"), "should be leverage conspiracy")
    end)

    it("requires heat threshold", function()
        local gs = make_game_state({
            { id = "a", category = "rival", heat = 30, autonomy = 20 },
            { id = "b", category = "power", heat = 30, autonomy = 20 },
        })
        local events = ShadowCollusion.generate(gs, 5)
        assert_equal(0, #events, "below threshold should not generate")
    end)

    it("meets threshold via combined autonomy", function()
        local gs = make_game_state({
            { id = "a", category = "rival", heat = 30, autonomy = 45 },
            { id = "b", category = "power", heat = 30, autonomy = 45 },
        })
        local events = ShadowCollusion.generate(gs, 5)
        assert_equal(1, #events, "combined autonomy >= 80 should pass threshold")
    end)

    it("respects cooldown of 3 years", function()
        local gs = make_game_state({
            { id = "a", category = "rival", heat = 55, autonomy = 50 },
            { id = "b", category = "power", heat = 55, autonomy = 50 },
        })
        ShadowCollusion.generate(gs, 5)
        local events2 = ShadowCollusion.generate(gs, 6)
        assert_equal(0, #events2, "cooldown should prevent event")
        local events3 = ShadowCollusion.generate(gs, 8)
        assert_equal(1, #events3, "after cooldown should allow event again")
    end)

    it("events have proper structure", function()
        local gs = make_game_state({
            { id = "a", category = "intimate", heat = 55, autonomy = 50 },
            { id = "b", category = "dependent", heat = 55, autonomy = 50 },
        })
        local events = ShadowCollusion.generate(gs, 5)
        assert_true(#events >= 1)
        local event = events[1]
        assert_not_nil(event.id)
        assert_not_nil(event.options)
        assert_equal(2, #event.options)
        assert_not_nil(event.bond_ids)
        assert_equal(2, #event.bond_ids)
    end)

    it("returns empty for nil game_state", function()
        local events = ShadowCollusion.generate(nil, 1)
        assert_equal(0, #events)
    end)
end)
