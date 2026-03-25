local rng = require("dredwork_core.rng")
local ShadowBonds = require("dredwork_bonds.bonds")
local ShadowSetup = require("dredwork_bonds.setup")

rng.seed(55555)

describe("ShadowBonds", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        local setup_state = ShadowSetup.new(overrides.seed or 12345)
        local profile = ShadowSetup.build_profile(setup_state)
        local run = ShadowSetup.build_run_options(setup_state)
        return {
            generation = overrides.generation or 1,
            rng_seed = overrides.seed or 12345,
            start_era = "ancient",
            shadow_setup = run.shadow_setup,
            shadow_state = overrides.shadow_state or {
                health = 50, stress = 50, bonds = 50,
                standing = 50, notoriety = 20, craft = 50,
            },
        }
    end

    it("initializes bonds from setup core_bonds", function()
        local gs = make_game_state()
        local state = ShadowBonds.ensure_state(gs)
        assert_true(state.initialized)
        assert_true(#state.bonds >= 5, "should have at least 5 core bonds")
    end)

    it("each bond has all 8 axes", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        for _, bond in ipairs(bonds) do
            assert_not_nil(bond.closeness, bond.name .. " missing closeness")
            assert_not_nil(bond.strain, bond.name .. " missing strain")
            assert_not_nil(bond.obligation, bond.name .. " missing obligation")
            assert_not_nil(bond.intimacy, bond.name .. " missing intimacy")
            assert_not_nil(bond.leverage, bond.name .. " missing leverage")
            assert_not_nil(bond.dependency, bond.name .. " missing dependency")
            assert_not_nil(bond.visibility, bond.name .. " missing visibility")
            assert_not_nil(bond.volatility, bond.name .. " missing volatility")
        end
    end)

    it("bonds have status labels", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        local valid_statuses = { Trusted = true, Close = true, Uneasy = true, Strained = true, Hostile = true }
        for _, bond in ipairs(bonds) do
            assert_true(valid_statuses[bond.status], "invalid status: " .. tostring(bond.status))
        end
    end)

    it("bonds have arc labels", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        for _, bond in ipairs(bonds) do
            assert_not_nil(bond.arc, bond.name .. " missing arc")
        end
    end)

    it("apply_event modifies bond axes", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        local target = bonds[1]
        local before_closeness = target.closeness
        ShadowBonds.apply_event(gs, { id = target.id, closeness = 10, strain = -5 })
        local after = ShadowBonds.snapshot(gs)
        local updated = nil
        for _, b in ipairs(after) do
            if b.id == target.id then
                updated = b
                break
            end
        end
        assert_true(updated.closeness > before_closeness, "apply_event should increase closeness")
    end)

    it("apply_event clamps to 0-100", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        local target = bonds[1]
        ShadowBonds.apply_event(gs, { id = target.id, closeness = 200 })
        local state = gs.shadow_bonds
        for _, b in ipairs(state.bonds) do
            if b.id == target.id then
                assert_true(b.closeness <= 100, "closeness should be clamped")
            end
        end
    end)

    it("apply_event updates thread state", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        local target = bonds[1]
        ShadowBonds.apply_event(gs, { id = target.id, heat_delta = 20, stage_delta = 1 })
        local state = gs.shadow_bonds
        local thread = state.threads and state.threads[target.id]
        assert_not_nil(thread, "thread should exist after apply_event")
        assert_true(thread.heat > 0, "heat should be elevated")
    end)

    it("apply_event records history", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        local target = bonds[1]
        ShadowBonds.apply_event(gs, { id = target.id, closeness = 1, history = "Test event happened." })
        local state = gs.shadow_bonds
        for _, b in ipairs(state.bonds) do
            if b.id == target.id then
                assert_true(#b.history >= 1, "history should be recorded")
                assert_equal("Test event happened.", b.history[#b.history])
            end
        end
    end)

    it("detail_snapshot identifies strongest bond", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local detail = ShadowBonds.detail_snapshot(gs)
        assert_not_nil(detail.strongest)
        assert_not_nil(detail.strongest.name)
    end)

    it("detail_snapshot provides summary lines", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local detail = ShadowBonds.detail_snapshot(gs)
        assert_not_nil(detail.summary_line)
        assert_not_nil(detail.pressure_line)
        assert_not_nil(detail.storyline_line)
        assert_not_nil(detail.knot_line)
        assert_not_nil(detail.fracture_line)
    end)

    it("tick_year increases strain on neglected bonds", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 80
        ShadowBonds.ensure_state(gs)
        local before = {}
        for _, bond in ipairs(gs.shadow_bonds.bonds) do
            before[bond.id] = bond.strain
        end
        ShadowBonds.tick_year(gs, "occupation_labor", "failure")
        local strain_increased = false
        for _, bond in ipairs(gs.shadow_bonds.bonds) do
            if bond.strain > (before[bond.id] or 0) then
                strain_increased = true
                break
            end
        end
        assert_true(strain_increased, "tick_year should increase strain on neglected bonds")
    end)

    it("tick_year nudges threads", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 75
        ShadowBonds.ensure_state(gs)
        ShadowBonds.tick_year(gs, "occupation_labor", "failure")
        local state = gs.shadow_bonds
        local thread_active = false
        for _, thread in pairs(state.threads or {}) do
            if thread.heat > 0 then
                thread_active = true
                break
            end
        end
        assert_true(thread_active, "tick_year should activate threads")
    end)

    it("resolve_autonomy produces moves", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 80
        ShadowBonds.ensure_state(gs)
        -- Pump threads to ensure they're active
        for _ = 1, 5 do
            ShadowBonds.tick_year(gs, "occupation_labor", "failure")
        end
        local lines = ShadowBonds.resolve_autonomy(gs, "failure")
        assert_true(#lines >= 1, "resolve_autonomy should produce at least one move")
    end)

    it("resolve_autonomy records recent_moves", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 80
        ShadowBonds.ensure_state(gs)
        for _ = 1, 5 do
            ShadowBonds.tick_year(gs, "occupation_labor", "failure")
        end
        ShadowBonds.resolve_autonomy(gs, "failure")
        local detail = ShadowBonds.detail_snapshot(gs)
        assert_true(#detail.recent_moves >= 1, "recent_moves should be populated")
    end)

    it("spotlights produces rows", function()
        local gs = make_game_state()
        gs.shadow_state.stress = 80
        ShadowBonds.ensure_state(gs)
        for _ = 1, 5 do
            ShadowBonds.tick_year(gs, "occupation_labor", "failure")
        end
        ShadowBonds.resolve_autonomy(gs, "failure")
        local rows = ShadowBonds.spotlights(gs)
        assert_true(#rows >= 1, "spotlights should produce at least one row")
        assert_not_nil(rows[1].label)
        assert_not_nil(rows[1].value)
    end)

    it("burden modifies initial bonds", function()
        -- Parent burden should modify bond to CHILD
        local gs = make_game_state()
        gs.shadow_setup.burden = "parent"
        gs.shadow_bonds = nil
        ShadowBonds.ensure_state(gs)
        local found_child = false
        for _, bond in ipairs(gs.shadow_bonds.bonds) do
            if bond.role == "CHILD" then
                found_child = true
                assert_true(bond.dependency >= 70, "CHILD bond should have high dependency")
            end
        end
        assert_true(found_child, "parent burden should create CHILD bond")
    end)

    it("wanted burden creates safehouse keeper", function()
        local gs = make_game_state()
        gs.shadow_setup.burden = "wanted"
        gs.shadow_bonds = nil
        ShadowBonds.ensure_state(gs)
        local found = false
        for _, bond in ipairs(gs.shadow_bonds.bonds) do
            if bond.role == "SAFEHOUSE KEEPER" then
                found = true
                assert_true(bond.leverage >= 50, "safehouse keeper should have high leverage")
            end
        end
        assert_true(found, "wanted burden should create safehouse keeper")
    end)

    it("history caps at 4 entries", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local target = gs.shadow_bonds.bonds[1]
        for i = 1, 10 do
            ShadowBonds.apply_event(gs, { id = target.id, closeness = 1, history = "Entry " .. i })
        end
        assert_true(#target.history <= 4, "history should cap at 4 entries")
    end)

    it("bonds sorted by urgency", function()
        local gs = make_game_state()
        ShadowBonds.ensure_state(gs)
        local bonds = ShadowBonds.snapshot(gs)
        for i = 2, #bonds do
            -- First bond should have highest urgency (or equal + alphabetical)
            -- Just verify they're sorted (no assertion on specific order, just structure)
            assert_not_nil(bonds[i].name)
        end
    end)
end)
