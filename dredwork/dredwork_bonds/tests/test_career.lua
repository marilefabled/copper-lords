local ShadowCareer = require("dredwork_bonds.career")

describe("ShadowCareer", function()

    local function make_game_state(occupation)
        return {
            generation = 1,
            shadow_setup = {
                start_age = 16,
                occupation = occupation or "laborer",
                occupation_label = "LABOR-CALLED",
                calling_label = "LABOR-CALLED",
            },
        }
    end

    it("initializes with correct defaults for laborer", function()
        local gs = make_game_state("laborer")
        local state = ShadowCareer.ensure_state(gs)
        assert_equal("laborer", state.occupation)
        assert_equal(11, state.rank)
        assert_equal(17, state.income)
        assert_equal(45, state.stability)
        assert_equal("UNFORMED", state.title)
    end)

    it("initializes with correct defaults for scribe", function()
        local gs = make_game_state("scribe")
        local state = ShadowCareer.ensure_state(gs)
        assert_equal(14, state.rank)
        assert_equal(19, state.income)
        assert_equal(47, state.stability)
    end)

    it("initializes with correct defaults for soldier", function()
        local gs = make_game_state("soldier")
        local state = ShadowCareer.ensure_state(gs)
        assert_equal(15, state.rank)
        assert_equal(36, state.stability)
    end)

    it("produces snapshot with all fields", function()
        local gs = make_game_state()
        local snap = ShadowCareer.snapshot(gs)
        assert_not_nil(snap.occupation)
        assert_not_nil(snap.title)
        assert_not_nil(snap.rank)
        assert_not_nil(snap.income)
        assert_not_nil(snap.stability)
    end)

    it("apply_focus promotes on triumph", function()
        local gs = make_game_state()
        ShadowCareer.ensure_state(gs)
        local before_rank = gs.shadow_career.rank
        ShadowCareer.apply_focus(gs, "occupation_labor", "triumph")
        assert_true(gs.shadow_career.rank > before_rank, "triumph should increase rank")
        assert_true(gs.shadow_career.income > 17, "triumph should increase income")
    end)

    it("apply_focus demotes on disaster", function()
        local gs = make_game_state()
        ShadowCareer.ensure_state(gs)
        gs.shadow_career.rank = 30
        gs.shadow_career.income = 30
        gs.shadow_career.stability = 30
        ShadowCareer.apply_focus(gs, "occupation_labor", "disaster")
        assert_true(gs.shadow_career.rank < 30, "disaster should decrease rank")
        assert_true(gs.shadow_career.income < 30, "disaster should decrease income")
        assert_true(gs.shadow_career.stability < 30, "disaster should decrease stability")
    end)

    it("title progresses with rank", function()
        local gs = make_game_state("laborer")
        ShadowCareer.ensure_state(gs)
        gs.shadow_career.rank = 20
        ShadowCareer.apply_focus(gs, "occupation_labor", "success")
        assert_equal("HAND", ShadowCareer.snapshot(gs).title)

        gs.shadow_career.rank = 50
        ShadowCareer.apply_focus(gs, "occupation_labor", "success")
        assert_equal("YARD BOSS", ShadowCareer.snapshot(gs).title)

        gs.shadow_career.rank = 82
        ShadowCareer.apply_focus(gs, "occupation_labor", "success")
        assert_equal("MASTER OF STONE", ShadowCareer.snapshot(gs).title)
    end)

    it("bond focus affects stability only", function()
        local gs = make_game_state()
        ShadowCareer.ensure_state(gs)
        local before_rank = gs.shadow_career.rank
        local before_income = gs.shadow_career.income
        ShadowCareer.apply_focus(gs, "bond_tend:core:1", "success")
        assert_equal(before_rank, gs.shadow_career.rank, "bond focus should not change rank")
        assert_equal(before_income, gs.shadow_career.income, "bond focus should not change income")
        assert_true(gs.shadow_career.stability > 44, "bond success should improve stability")
    end)

    it("burden focus on failure hurts income and stability", function()
        local gs = make_game_state()
        ShadowCareer.ensure_state(gs)
        gs.shadow_career.income = 30
        gs.shadow_career.stability = 30
        ShadowCareer.apply_focus(gs, "burden_debt", "disaster")
        assert_true(gs.shadow_career.income < 30, "burden disaster should hurt income")
        assert_true(gs.shadow_career.stability < 30, "burden disaster should hurt stability")
    end)

    it("clamps all values to 0-100", function()
        local gs = make_game_state()
        ShadowCareer.ensure_state(gs)
        gs.shadow_career.rank = 99
        gs.shadow_career.income = 99
        gs.shadow_career.stability = 99
        ShadowCareer.apply_focus(gs, "occupation_labor", "triumph")
        assert_true(gs.shadow_career.rank <= 100)
        assert_true(gs.shadow_career.income <= 100)
        assert_true(gs.shadow_career.stability <= 100)

        gs.shadow_career.rank = 1
        gs.shadow_career.income = 1
        gs.shadow_career.stability = 1
        ShadowCareer.apply_focus(gs, "occupation_labor", "disaster")
        assert_true(gs.shadow_career.rank >= 0)
        assert_true(gs.shadow_career.income >= 0)
        assert_true(gs.shadow_career.stability >= 0)
    end)

    it("reports title change in lines", function()
        local gs = make_game_state("laborer")
        ShadowCareer.ensure_state(gs)
        gs.shadow_career.rank = 19
        local lines = ShadowCareer.apply_focus(gs, "occupation_labor", "triumph")
        assert_true(#lines >= 2, "title change should produce extra line")
        local found_change = false
        for _, line in ipairs(lines) do
            if line:find("names you differently") then
                found_change = true
            end
        end
        assert_true(found_change, "should report the new title")
    end)

    it("each occupation has 5 unique titles", function()
        local occupations = { "laborer", "scribe", "soldier", "courtier", "tinker", "performer" }
        for _, occ in ipairs(occupations) do
            local gs = make_game_state(occ)
            ShadowCareer.ensure_state(gs)
            local titles_seen = {}
            for _, rank in ipairs({20, 34, 50, 66, 82}) do
                gs.shadow_career.rank = rank
                ShadowCareer.apply_focus(gs, "occupation_" .. occ, "success")
                local title = ShadowCareer.snapshot(gs).title
                assert_true(not titles_seen[title], "duplicate title for " .. occ .. " at rank " .. rank)
                titles_seen[title] = true
            end
        end
    end)
end)
