-- Dark Legacy — Morality System Tests

local Morality = require("dredwork_world.morality")

describe("Morality", function()

    it("creates with default neutral state", function()
        local m = Morality.new()
        assert(m.score == 0, "neutral score")
        assert(m.virtues == 0, "no virtues")
        assert(m.sins == 0, "no sins")
    end)

    it("creates with inherited reputation", function()
        local m = Morality.new(-30)
        assert(m.score == -30, "inherited -30")
    end)

    it("record_act adjusts score positively", function()
        local m = Morality.new()
        Morality.record_act(m, "mercy", 1, "Spared the prisoner")
        assert(m.score > 0, "mercy increases score: " .. m.score)
        assert(m.virtues == 1, "one virtue")
        assert(#m.acts == 1, "one act recorded")
    end)

    it("record_act adjusts score negatively", function()
        local m = Morality.new()
        Morality.record_act(m, "betrayal", 1, "Broke the alliance")
        assert(m.score < 0, "betrayal decreases score: " .. m.score)
        assert(m.sins == 1, "one sin")
    end)

    it("score clamps to -100..100", function()
        local m = Morality.new()
        for i = 1, 20 do
            Morality.record_act(m, "assassination", 1)
        end
        assert(m.score == -100, "clamped to -100")
        m.score = 0
        for i = 1, 20 do
            Morality.record_act(m, "sacrifice", 1)
        end
        assert(m.score == 100, "clamped to 100")
    end)

    it("get_standing returns correct tier", function()
        local saint = Morality.new(90)
        assert(Morality.get_standing(saint).label == "Saintly", "saintly at 90")
        local villain = Morality.new(-55)
        assert(Morality.get_standing(villain).label == "Monstrous", "monstrous at -55")
        local neutral = Morality.new(0)
        assert(Morality.get_standing(neutral).label == "Compromised", "compromised at 0")
    end)

    it("decay regresses toward 0", function()
        local m = Morality.new()
        m.score = 50
        Morality.decay(m)
        assert(m.score < 50 and m.score > 0, "decayed toward 0: " .. m.score)
        local m2 = Morality.new()
        m2.score = -50
        Morality.decay(m2)
        assert(m2.score > -50 and m2.score < 0, "decayed up toward 0: " .. m2.score)
    end)

    it("update_lineage_reputation blends old and new", function()
        local m = Morality.new()
        m.score = 80
        local new_rep = Morality.update_lineage_reputation(m, 0)
        assert(new_rep > 0, "reputation increased: " .. new_rep)
        assert(new_rep < 80, "blended with old: " .. new_rep)
    end)

    it("check_trouble identifies criminal heirs", function()
        local good = Morality.new(30)
        local trouble, severity = Morality.check_trouble(good)
        assert(not trouble, "good heir not in trouble")

        local bad = Morality.new(-25)
        trouble, severity = Morality.check_trouble(bad)
        assert(trouble, "bad heir in trouble")
        assert(severity == "minor", "minor trouble")

        local awful = Morality.new(-65)
        trouble, severity = Morality.check_trouble(awful)
        assert(trouble, "awful heir in trouble")
        assert(severity == "notorious", "notorious")
    end)

    it("acts_for_generation filters correctly", function()
        local m = Morality.new()
        Morality.record_act(m, "mercy", 5)
        Morality.record_act(m, "betrayal", 6)
        Morality.record_act(m, "charity", 5)
        local gen5 = Morality.acts_for_generation(m, 5)
        assert(#gen5 == 2, "two acts in gen 5")
    end)

    it("describe returns non-empty narrative", function()
        local m = Morality.new()
        Morality.record_act(m, "mercy", 1)
        Morality.record_act(m, "betrayal", 1)
        local desc = Morality.describe(m)
        assert(#desc > 0, "non-empty description")
    end)

    it("disposition_modifier reflects morality", function()
        local good = Morality.new(70)
        local bad = Morality.new(-50)
        assert(Morality.disposition_modifier(good) > 0, "good = positive disposition")
        assert(Morality.disposition_modifier(bad) < 0, "bad = negative disposition")
    end)

    it("gray acts are tracked separately", function()
        local m = Morality.new()
        Morality.record_act(m, "pragmatism", 1)
        Morality.record_act(m, "necessary_evil", 1)
        assert(m.gray_acts == 2, "two gray acts")
        assert(m.virtues == 0, "no virtues")
        assert(m.sins == 0, "no sins")
    end)
end)
