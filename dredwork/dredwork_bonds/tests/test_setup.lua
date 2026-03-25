local rng = require("dredwork_core.rng")
local ShadowSetup = require("dredwork_bonds.setup")

rng.seed(42042)

describe("ShadowSetup", function()

    it("creates a new setup state with defaults", function()
        local state = ShadowSetup.new(12345)
        assert_not_nil(state)
        assert_equal(12345, state.seed)
        assert_not_nil(state.selections)
        assert_not_nil(state.core_bonds)
        assert_equal(5, #state.core_bonds)
        assert_not_nil(state.heir_name)
        assert_not_nil(state.lineage_name)
    end)

    it("initializes all 7 selection axes to 1", function()
        local state = ShadowSetup.new(100)
        local order = ShadowSetup.get_option_order()
        assert_equal(7, #order)
        for _, key in ipairs(order) do
            assert_equal(1, state.selections[key], "default selection for " .. key)
        end
    end)

    it("cycles options forward and backward", function()
        local state = ShadowSetup.new(200)
        local first = ShadowSetup.get_choice(state, "birthplace")
        assert_equal("holdfast", first.id)
        ShadowSetup.cycle(state, "birthplace", 1)
        local second = ShadowSetup.get_choice(state, "birthplace")
        assert_equal("market", second.id)
        ShadowSetup.cycle(state, "birthplace", -1)
        local back = ShadowSetup.get_choice(state, "birthplace")
        assert_equal("holdfast", back.id)
    end)

    it("cycles wraps around", function()
        local state = ShadowSetup.new(300)
        local def = ShadowSetup.get_definition("birthplace")
        local total = #def.items
        for _ = 1, total do
            ShadowSetup.cycle(state, "birthplace", 1)
        end
        local choice = ShadowSetup.get_choice(state, "birthplace")
        assert_equal("holdfast", choice.id, "should wrap back to first")
    end)

    it("builds a profile with traits clamped 18-92", function()
        local state = ShadowSetup.new(400)
        local profile = ShadowSetup.build_profile(state)
        assert_not_nil(profile.traits)
        for key, value in pairs(profile.traits) do
            assert_in_range(value, 18, 92, "trait " .. key)
        end
    end)

    it("builds a profile with personality clamped 15-85", function()
        local state = ShadowSetup.new(500)
        local profile = ShadowSetup.build_profile(state)
        assert_not_nil(profile.personality)
        for key, value in pairs(profile.personality) do
            assert_in_range(value, 15, 85, "axis " .. key)
        end
    end)

    it("produces different profiles from different seeds", function()
        local a = ShadowSetup.build_profile(ShadowSetup.new(1))
        local b = ShadowSetup.build_profile(ShadowSetup.new(999))
        local same_count = 0
        for key, _ in pairs(a.traits) do
            if a.traits[key] == b.traits[key] then
                same_count = same_count + 1
            end
        end
        assert_true(same_count < 5, "different seeds should produce different trait distributions")
    end)

    it("includes 5 core bonds in profile", function()
        local state = ShadowSetup.new(600)
        local profile = ShadowSetup.build_profile(state)
        assert_equal(5, #profile.core_bonds)
        for _, bond in ipairs(profile.core_bonds) do
            assert_not_nil(bond.name)
            assert_not_nil(bond.role)
            assert_not_nil(bond.category)
            assert_not_nil(bond.temperament)
        end
    end)

    it("rerolls identity deterministically", function()
        local state = ShadowSetup.new(700)
        local name1 = state.heir_name
        ShadowSetup.reroll_identity(state)
        local name2 = state.heir_name
        assert_true(name1 ~= name2, "reroll should change the name")
    end)

    it("randomizes all selections", function()
        local state = ShadowSetup.new(800)
        ShadowSetup.randomize(state)
        local all_one = true
        for key, value in pairs(state.selections) do
            if value ~= 1 then
                all_one = false
                break
            end
        end
        assert_true(not all_one, "randomize should change at least one selection")
    end)

    it("cycles core bond tones", function()
        local state = ShadowSetup.new(900)
        local initial_tone = state.core_bonds[1].tone_index
        ShadowSetup.cycle_core_bond_tone(state, 1, 1)
        assert_true(state.core_bonds[1].tone_index ~= initial_tone, "tone should change")
    end)

    it("rerolls core bond names", function()
        local state = ShadowSetup.new(1000)
        local initial_name = state.core_bonds[1].name
        ShadowSetup.reroll_core_bond_name(state, 1)
        assert_true(state.core_bonds[1].name ~= initial_name, "bond name should change on reroll")
    end)

    it("builds run options with shadow_setup block", function()
        local state = ShadowSetup.new(1100)
        local run = ShadowSetup.build_run_options(state)
        assert_not_nil(run.shadow_setup)
        assert_equal(16, run.shadow_setup.start_age)
        assert_not_nil(run.shadow_setup.occupation)
        assert_not_nil(run.shadow_setup.burden)
        assert_not_nil(run.shadow_setup.creed)
        assert_not_nil(run.shadow_setup.core_bonds)
        assert_equal(5, #run.shadow_setup.core_bonds)
    end)

    it("builds setup rows for UI", function()
        local state = ShadowSetup.new(1200)
        local rows = ShadowSetup.build_rows(state)
        assert_true(#rows >= 7, "should have at least 7 setup rows (one per axis)")
        for _, row in ipairs(rows) do
            assert_not_nil(row.key)
            assert_not_nil(row.label)
            assert_not_nil(row.value)
        end
    end)

    it("includes burden creed in profile", function()
        local state = ShadowSetup.new(1300)
        local profile = ShadowSetup.build_profile(state)
        assert_not_nil(profile.creed)
        assert_true(#profile.creed > 0, "creed should be non-empty")
    end)

    it("applies trait deltas from all 7 axes", function()
        local state = ShadowSetup.new(1400)
        -- Set all selections to options with known deltas
        state.selections.birthplace = 1  -- holdfast: PHY_VIT +4, MEN_WIL +4, SOC_LEA +2
        state.selections.occupation = 3  -- soldier: PHY_STR +4, PHY_VIT +4, SOC_LEA +3
        local profile = ShadowSetup.build_profile(state)
        -- PHY_VIT should be well above baseline (51) with +4 from birthplace and +4 from occupation
        assert_true(profile.traits.PHY_VIT > 51, "PHY_VIT should be elevated by holdfast + soldier")
    end)

    it("produces summary lines", function()
        local state = ShadowSetup.new(1500)
        local profile = ShadowSetup.build_profile(state)
        assert_true(#profile.summary_lines >= 3, "should have multiple summary lines")
        assert_true(#profile.notes >= 2, "should have opening notes")
    end)
end)
