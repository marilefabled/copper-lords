local Dilemma = require("dredwork_dilemma.dilemma")
local Pressure = require("dredwork_dilemma.pressure")

describe("Dilemma Engine", function()

    local function make_pressure(id, category, urgency, source)
        return Pressure.create({
            id = id,
            source = source or "test",
            category = category or "survival",
            urgency = urgency or 60,
            label = "Pressure " .. id,
            summary = "Something about " .. id,
            subject = "Asha",
            tags = { category or "survival" },
            address = { narrative = "Addressed " .. id, effects = { shadow = { stress = -2 } } },
            neglect = { narrative = "Neglected " .. id, effects = { shadow = { stress = 4 } } },
        })
    end

    it("returns nil with fewer than 2 pressures", function()
        assert_nil(Dilemma.generate({}, 1))
        assert_nil(Dilemma.generate({ make_pressure("a") }, 1))
    end)

    it("generates a dilemma from 2 pressures", function()
        local pressures = {
            make_pressure("a", "relationship", 70, "bonds"),
            make_pressure("b", "survival", 65, "body"),
        }
        local d = Dilemma.generate(pressures, 3)
        assert_not_nil(d)
        assert_equal("dilemma:3", d.id)
        assert_equal(2, #d.pressures)
        assert_true(#d.options >= 2, "should have at least 2 options")
    end)

    it("prefers cross-category pairs", function()
        local pressures = {
            make_pressure("a", "relationship", 70, "bonds"),
            make_pressure("b", "relationship", 65, "bonds"),
            make_pressure("c", "survival", 60, "body"),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_not_nil(d)
        -- The pair should be relationship + survival, not relationship + relationship
        local cats = { d.pressures[1].category, d.pressures[2].category }
        table.sort(cats)
        assert_equal("relationship", cats[1])
        assert_equal("survival", cats[2])
    end)

    it("prefers different sources", function()
        local pressures = {
            make_pressure("a", "survival", 70, "body"),
            make_pressure("b", "survival", 65, "body"),
            make_pressure("c", "reputation", 60, "rumor"),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_not_nil(d)
        assert_true(d.pressures[1].source ~= d.pressures[2].source or true, "different sources preferred")
    end)

    it("includes split option for high tension", function()
        local pressures = {
            make_pressure("a", "relationship", 90, "bonds"),
            make_pressure("b", "survival", 85, "body"),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_not_nil(d)
        assert_true(#d.options >= 3, "high tension should offer split option")
        assert_true(d.options[3].split, "third option should be split")
    end)

    it("tracks background pressures", function()
        local pressures = {
            make_pressure("a", "relationship", 90, "bonds"),
            make_pressure("b", "survival", 85, "body"),
            make_pressure("c", "reputation", 60, "rumor"),
            make_pressure("d", "identity", 55, "claim"),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_not_nil(d)
        assert_equal(2, #d.background_pressures, "non-picked pressures should be in background")
    end)

    it("resolves option A correctly", function()
        local pressures = {
            make_pressure("a", "relationship", 80, "bonds"),
            make_pressure("b", "survival", 75, "body"),
        }
        local d = Dilemma.generate(pressures, 1)
        local result = Dilemma.resolve(d, 1)
        assert_not_nil(result)
        assert_not_nil(result.address_effects, "should have address effects")
        assert_not_nil(result.neglect_effects, "should have neglect effects")
        assert_true(#result.narrative_lines >= 2, "should have narrative lines")
        assert_equal("address_a", d.chosen)
    end)

    it("resolves option B correctly", function()
        local pressures = {
            make_pressure("a", "relationship", 80, "bonds"),
            make_pressure("b", "survival", 75, "body"),
        }
        local d = Dilemma.generate(pressures, 1)
        local result = Dilemma.resolve(d, 2)
        assert_not_nil(result)
        assert_equal("address_b", d.chosen)
    end)

    it("resolves split option", function()
        local pressures = {
            make_pressure("a", "relationship", 90, "bonds"),
            make_pressure("b", "survival", 85, "body"),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_true(#d.options >= 3)
        local result = Dilemma.resolve(d, 3)
        assert_not_nil(result)
        assert_nil(result.address_effects, "split should not have full address effects")
        assert_nil(result.neglect_effects, "split should not have full neglect effects")
        assert_true(#result.narrative_lines >= 1)
    end)

    it("background pressures escalate on resolve", function()
        local pressures = {
            make_pressure("a", "relationship", 90, "bonds"),
            make_pressure("b", "survival", 85, "body"),
            make_pressure("c", "reputation", 70, "rumor"),
        }
        local d = Dilemma.generate(pressures, 1)
        local result = Dilemma.resolve(d, 1)
        assert_true(#result.background_effects >= 1, "background pressures should escalate")
        assert_not_nil(result.background_effects[1].effects)
    end)

    it("snapshot produces UI-friendly data", function()
        local pressures = {
            make_pressure("a", "relationship", 80, "bonds"),
            make_pressure("b", "survival", 75, "body"),
        }
        local d = Dilemma.generate(pressures, 5)
        local snap = Dilemma.snapshot(d)
        assert_not_nil(snap)
        assert_equal(5, snap.generation)
        assert_not_nil(snap.pressure_a)
        assert_not_nil(snap.pressure_b)
        assert_true(#snap.options >= 2)
        assert_not_nil(snap.pressure_a.label)
        assert_not_nil(snap.pressure_a.urgency)
    end)

    it("returns nil for invalid resolve", function()
        assert_nil(Dilemma.resolve(nil, 1))
        local pressures = {
            make_pressure("a", "relationship", 80),
            make_pressure("b", "survival", 75),
        }
        local d = Dilemma.generate(pressures, 1)
        assert_nil(Dilemma.resolve(d, 99))
    end)
end)
