local ShadowPossessions = require("dredwork_bonds.possessions")

describe("ShadowPossessions", function()

    local function make_game_state(overrides)
        overrides = overrides or {}
        return {
            generation = 1,
            shadow_setup = {
                start_age = 16,
                occupation = overrides.occupation or "laborer",
                household = overrides.household or "martial",
                burden = overrides.burden or "debt",
            },
        }
    end

    it("initializes with starting items", function()
        local gs = make_game_state()
        local state = ShadowPossessions.ensure_state(gs)
        assert_true(state.initialized)
        assert_true(#state.entries >= 2, "should have at least occupation item + household place")
    end)

    it("seeds occupation-specific item", function()
        local gs = make_game_state({ occupation = "soldier" })
        ShadowPossessions.ensure_state(gs)
        local snap = ShadowPossessions.snapshot(gs)
        local found = false
        for _, item in ipairs(snap.items) do
            if item.id == "service_blade" then
                found = true
            end
        end
        assert_true(found, "soldier should start with Service Blade")
    end)

    it("seeds household-specific place", function()
        local gs = make_game_state({ household = "scholarly" })
        ShadowPossessions.ensure_state(gs)
        local snap = ShadowPossessions.snapshot(gs)
        local found = false
        for _, place in ipairs(snap.places) do
            if place.id == "copy_desk" then
                found = true
            end
        end
        assert_true(found, "scholarly household should provide Copy Desk")
    end)

    it("seeds burden-specific item", function()
        local gs = make_game_state({ burden = "claim" })
        ShadowPossessions.ensure_state(gs)
        local snap = ShadowPossessions.snapshot(gs)
        local found = false
        for _, item in ipairs(snap.items) do
            if item.id == "branch_token" then
                found = true
            end
        end
        assert_true(found, "claim burden should provide Branch Token")
    end)

    it("adds items without duplicating", function()
        local gs = make_game_state()
        ShadowPossessions.ensure_state(gs)
        ShadowPossessions.apply(gs, { add = { { id = "new_thing", label = "New Thing", kind = "item" } } })
        ShadowPossessions.apply(gs, { add = { { id = "new_thing", label = "New Thing", kind = "item" } } })
        local count = 0
        for _, entry in ipairs(gs.shadow_possessions.entries) do
            if entry.id == "new_thing" then
                count = count + 1
            end
        end
        assert_equal(1, count, "should not duplicate items")
    end)

    it("removes items", function()
        local gs = make_game_state()
        ShadowPossessions.ensure_state(gs)
        ShadowPossessions.apply(gs, { add = { { id = "temp", label = "Temp", kind = "item" } } })
        ShadowPossessions.apply(gs, { remove = { "temp" } })
        local snap = ShadowPossessions.snapshot(gs)
        local found = false
        for _, item in ipairs(snap.items) do
            if item.id == "temp" then
                found = true
            end
        end
        assert_true(not found, "removed item should be gone")
    end)

    it("adjusts item properties", function()
        local gs = make_game_state()
        ShadowPossessions.ensure_state(gs)
        ShadowPossessions.apply(gs, { adjust = { { id = "work_knife", status = "Rusted", upkeep = 1 } } })
        local snap = ShadowPossessions.snapshot(gs)
        for _, item in ipairs(snap.items) do
            if item.id == "work_knife" then
                assert_equal("Rusted", item.status)
                assert_equal(1, item.upkeep)
            end
        end
    end)

    it("computes upkeep, yield, and stain totals", function()
        local gs = make_game_state({ occupation = "soldier" })
        ShadowPossessions.ensure_state(gs)
        local snap = ShadowPossessions.snapshot(gs)
        assert_true(type(snap.upkeep) == "number")
        assert_true(type(snap.yield) == "number")
        assert_true(type(snap.stain) == "number")
    end)

    it("snapshot includes overview_line", function()
        local gs = make_game_state()
        local snap = ShadowPossessions.snapshot(gs)
        assert_not_nil(snap.overview_line)
        assert_true(snap.overview_line:find("items"), "overview should mention items")
    end)

    it("returns nil for nil game_state", function()
        assert_nil(ShadowPossessions.snapshot(nil))
    end)

    it("tick_year recomputes totals", function()
        local gs = make_game_state()
        ShadowPossessions.ensure_state(gs)
        ShadowPossessions.apply(gs, { add = { { id = "expensive", label = "Expensive", kind = "item", upkeep = 5, yield = 0 } } })
        local snap = ShadowPossessions.tick_year(gs)
        assert_true(snap.upkeep >= 5, "tick should reflect updated totals")
    end)

    it("clamps upkeep, yield, and stain adjustments to 0-10", function()
        local gs = make_game_state()
        ShadowPossessions.ensure_state(gs)
        ShadowPossessions.apply(gs, { adjust = { { id = "work_knife", upkeep = 20 } } })
        for _, entry in ipairs(gs.shadow_possessions.entries) do
            if entry.id == "work_knife" then
                assert_true(entry.upkeep <= 10, "upkeep should be clamped")
            end
        end
    end)
end)
