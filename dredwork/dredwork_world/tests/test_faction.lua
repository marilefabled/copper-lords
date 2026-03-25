-- Dark Legacy — Faction System Tests

local rng = require("dredwork_core.rng")
local faction_module = require("dredwork_world.faction")
local Faction = faction_module.Faction
local FactionManager = faction_module.FactionManager
local WorldState = require("dredwork_world.world_state")

rng.seed(54321)

describe("Faction", function()

    it("creates from definition", function()
        local f = Faction.new({
            id = "test_house",
            name = "House Test",
            motto = "Testing is power.",
            category_scores = { physical = 70, mental = 40, social = 50, creative = 30 },
            personality = { PER_BLD = 80 },
            reputation = { primary = "warriors", secondary = "unknown" },
            power = 60,
            status = "active",
            disposition = 10,
        })

        assert_equal("test_house", f.id)
        assert_equal("House Test", f.name)
        assert_equal(60, f.power)
        assert_equal(10, f.disposition)
        assert_equal("physical", f:get_dominant_category())
    end)

    it("shifts disposition", function()
        local f = Faction.new({
            id = "t", name = "T",
            category_scores = { physical = 50 },
            power = 50, disposition = 0,
        })
        f:shift_disposition(20)
        assert_equal(20, f.disposition)
        f:shift_disposition(-30)
        assert_equal(-10, f.disposition)
    end)

    it("clamps disposition to range", function()
        local f = Faction.new({
            id = "t", name = "T",
            category_scores = { physical = 50 },
            power = 50, disposition = 0,
        })
        f:shift_disposition(200)
        assert_equal(100, f.disposition)
        f:shift_disposition(-300)
        assert_equal(-100, f.disposition)
    end)

    it("detects hostile and friendly", function()
        local f = Faction.new({
            id = "t", name = "T",
            category_scores = { physical = 50 },
            power = 50, disposition = -60,
        })
        assert_true(f:is_hostile())
        assert_true(not f:is_friendly())

        f.disposition = 40
        assert_true(not f:is_hostile())
        assert_true(f:is_friendly())
    end)

    it("updates status based on power", function()
        local f = Faction.new({
            id = "t", name = "T",
            category_scores = { physical = 50 },
            power = 5, disposition = 0,
        })
        f:shift_power(0) -- triggers status update
        assert_equal("fallen", f.status)

        f.power = 25
        f:shift_power(0)
        assert_equal("declining", f.status)

        f.power = 80
        f:shift_power(0)
        assert_equal("rising", f.status)

        f.power = 50
        f:shift_power(0)
        assert_equal("active", f.status)
    end)

    it("evolves with disposition decay toward neutral", function()
        local ws = WorldState.new()
        local f = Faction.new({
            id = "t", name = "T",
            category_scores = { physical = 50, mental = 50, social = 50, creative = 50 },
            power = 50, disposition = 40,
        })
        f:evolve(ws)
        -- Disposition should drift toward 0
        assert_true(f.disposition < 40, "disposition should decay toward neutral")
    end)

    it("serializes and deserializes", function()
        local f = Faction.new({
            id = "test", name = "House Test",
            motto = "Test.",
            category_scores = { physical = 60, mental = 40, social = 50, creative = 30 },
            personality = { PER_BLD = 70 },
            reputation = { primary = "warriors", secondary = "unknown" },
            power = 55, status = "active", disposition = -20,
        })

        local data = f:to_table()
        local restored = Faction.from_table(data)
        assert_equal("test", restored.id)
        assert_equal("House Test", restored.name)
        assert_equal(55, restored.power)
        assert_equal(-20, restored.disposition)
    end)
end)

describe("FactionManager", function()

    it("creates with 5 starting factions", function()
        local fm = FactionManager.new()
        local all = fm:get_all()
        assert_equal(5, #all)
    end)

    it("gets faction by id", function()
        local fm = FactionManager.new()
        local varen = fm:get("house_mordthen")
        assert_not_nil(varen)
        assert_equal("House Mordthen", varen.name)
    end)

    it("gets active factions", function()
        local fm = FactionManager.new()
        local active = fm:get_active()
        assert_equal(5, #active) -- all start active
    end)

    it("shifts all dispositions", function()
        local fm = FactionManager.new()
        fm:shift_all_disposition(10)
        for _, f in ipairs(fm:get_all()) do
            -- Each should be 10 more than starting
            assert_true(f.disposition ~= nil)
        end
    end)

    it("evolves all factions", function()
        local fm = FactionManager.new()
        local ws = WorldState.new("iron")
        fm:evolve_all(ws)
        -- Should not crash, factions should still exist
        assert_equal(5, #fm:get_all())
    end)

    it("spawns emergent faction when active drops below 3", function()
        local fm = FactionManager.new()
        -- Kill off 3 factions
        for i = 1, 3 do
            fm.factions[i].power = 0
            fm.factions[i].status = "fallen"
        end

        local ws = WorldState.new()
        ws.generation = 10
        fm:evolve_all(ws)

        -- Should have spawned at least one new faction
        local active = fm:get_active()
        assert_true(#active >= 3, "should have at least 3 active factions after spawn")
    end)

    it("serializes and deserializes", function()
        local fm = FactionManager.new()
        local data = fm:to_table()
        local restored = FactionManager.from_table(data)
        assert_equal(5, #restored:get_all())
        assert_not_nil(restored:get("house_mordthen"))
    end)
end)
