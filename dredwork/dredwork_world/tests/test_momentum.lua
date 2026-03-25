-- Dark Legacy — Momentum System Tests

local Momentum = require("dredwork_world.momentum")

describe("Momentum System", function()

    it("should create fresh momentum data with all categories neutral", function()
        local m = Momentum.new()
        assert_not_nil(m.physical, "Should have physical")
        assert_not_nil(m.mental, "Should have mental")
        assert_not_nil(m.social, "Should have social")
        assert_not_nil(m.creative, "Should have creative")
        assert_equal(0, m.physical.streak, "Streak should start at 0")
        assert_equal("neutral", m.physical.direction, "Direction should start neutral")
    end)

    it("should increment streak on consecutive rising generations", function()
        local m = Momentum.new()
        local old = { physical = 50, mental = 50, social = 50, creative = 50 }
        local new1 = { physical = 52, mental = 50, social = 50, creative = 50 }

        Momentum.update(m, old, new1)
        assert_equal(1, m.physical.streak, "Streak should be 1 after first rise")
        assert_equal("rising", m.physical.direction, "Direction should be rising")

        local new2 = { physical = 55, mental = 50, social = 50, creative = 50 }
        Momentum.update(m, new1, new2)
        assert_equal(2, m.physical.streak, "Streak should be 2 after second rise")
    end)

    it("should fire ASCENDING event at streak 3", function()
        local m = Momentum.new()
        m.physical = { streak = 2, direction = "rising" }

        local old = { physical = 55, mental = 50, social = 50, creative = 50 }
        local new_vals = { physical = 58, mental = 50, social = 50, creative = 50 }

        local result = Momentum.update(m, old, new_vals)
        assert_equal(3, m.physical.streak, "Streak should be 3")

        local found_ascending = false
        for _, ch in ipairs(result.changes) do
            if ch.category == "physical" and ch.label == "ASCENDING" then
                found_ascending = true
            end
        end
        assert_true(found_ascending, "Should fire ASCENDING event at streak 3")
    end)

    it("should fire COOLING event when breaking a 3+ streak", function()
        local m = Momentum.new()
        m.physical = { streak = 4, direction = "rising" }

        local old = { physical = 60, mental = 50, social = 50, creative = 50 }
        local new_vals = { physical = 57, mental = 50, social = 50, creative = 50 }

        local result = Momentum.update(m, old, new_vals)

        local found_cooling = false
        for _, ch in ipairs(result.changes) do
            if ch.category == "physical" and ch.label == "COOLING" then
                found_cooling = true
            end
        end
        assert_true(found_cooling, "Should fire COOLING event when breaking 3+ streak")
        assert_equal(1, m.physical.streak, "Streak should reset to 1 in new direction")
        assert_equal("falling", m.physical.direction, "Direction should be falling")
    end)

    it("should not fire COOLING for streaks under 3", function()
        local m = Momentum.new()
        m.physical = { streak = 2, direction = "rising" }

        local old = { physical = 55, mental = 50, social = 50, creative = 50 }
        local new_vals = { physical = 52, mental = 50, social = 50, creative = 50 }

        local result = Momentum.update(m, old, new_vals)
        assert_equal(0, #result.changes, "Should not fire events for sub-3 streak break")
    end)

    it("should return ascending categories correctly", function()
        local m = Momentum.new()
        m.physical = { streak = 5, direction = "rising" }
        m.mental = { streak = 3, direction = "rising" }
        m.social = { streak = 2, direction = "rising" }

        local ascending = Momentum.get_ascending(m)
        assert_equal(2, #ascending, "Should return 2 ascending categories")
    end)

    it("should return display labels for ascending categories", function()
        local m = Momentum.new()
        m.physical = { streak = 5, direction = "rising" }

        local labels = Momentum.get_labels(m)
        assert_not_nil(labels.physical, "Physical should have a label")
        assert_nil(labels.mental, "Mental should not have a label")
    end)

    it("should not change streak on neutral delta", function()
        local m = Momentum.new()
        m.physical = { streak = 3, direction = "rising" }

        local old = { physical = 55, mental = 50, social = 50, creative = 50 }
        local new_vals = { physical = 55.2, mental = 50, social = 50, creative = 50 }

        Momentum.update(m, old, new_vals)
        assert_equal(3, m.physical.streak, "Streak should not change on neutral delta")
        assert_equal("rising", m.physical.direction, "Direction should remain rising")
    end)

    it("should round-trip serialize/deserialize", function()
        local m = Momentum.new()
        m.physical = { streak = 5, direction = "rising" }
        m.mental = { streak = 2, direction = "falling" }

        local t = Momentum.to_table(m)
        local restored = Momentum.from_table(t)

        assert_equal(5, restored.physical.streak, "Physical streak should survive round-trip")
        assert_equal("rising", restored.physical.direction, "Physical direction should survive")
        assert_equal(2, restored.mental.streak, "Mental streak should survive round-trip")
        assert_equal("falling", restored.mental.direction, "Mental direction should survive")
    end)
end)
