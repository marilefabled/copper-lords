-- Dark Legacy — Heir Ledger Tests

local HeirLedger = require("dredwork_world.heir_ledger")

describe("HeirLedger", function()

    it("record creates entry with impact score", function()
        local entry = HeirLedger.record({
            generation = 5,
            heir_name = "Kael",
            era = "iron",
            cultural_deltas = { physical = 3, social = 2 },
        })
        assert(entry.generation == 5, "generation")
        assert(entry.heir_name == "Kael", "name")
        assert(entry.impact_score, "impact_score must exist")
        assert(entry.impact_rating, "impact_rating must exist")
        assert(entry.impact_score >= 0 and entry.impact_score <= 100, "score in range")
    end)

    it("defaults to neutral for missing data", function()
        local entry = HeirLedger.record({ generation = 1 })
        assert(entry.impact_score == 50, "neutral score expected, got " .. tostring(entry.impact_score))
    end)

    it("high cultural shift raises score", function()
        local high = HeirLedger.record({
            generation = 1,
            cultural_deltas = { physical = 10, mental = 8, social = 5, creative = 5 },
        })
        local low = HeirLedger.record({
            generation = 2,
            cultural_deltas = { physical = 0, mental = 0 },
        })
        assert(high.impact_score >= low.impact_score,
            "high cultural shift should score higher: " .. high.impact_score .. " vs " .. low.impact_score)
    end)

    it("append and get work", function()
        local ledger = {}
        local entry1 = HeirLedger.record({ generation = 1, heir_name = "A" })
        local entry2 = HeirLedger.record({ generation = 2, heir_name = "B" })
        HeirLedger.append(ledger, entry1)
        HeirLedger.append(ledger, entry2)
        assert(#ledger == 2, "two entries")
        local found = HeirLedger.get(ledger, 2)
        assert(found and found.heir_name == "B", "found gen 2")
    end)

    it("summary computes correctly", function()
        local ledger = {}
        HeirLedger.append(ledger, HeirLedger.record({
            generation = 1, heir_name = "Best",
            cultural_deltas = { physical = 10, mental = 10, social = 10, creative = 10 },
        }))
        HeirLedger.append(ledger, HeirLedger.record({
            generation = 2, heir_name = "Worst",
        }))
        local stats = HeirLedger.summary(ledger)
        assert(stats.count == 2, "count")
        assert(stats.best.heir_name == "Best", "best heir")
        assert(stats.worst.heir_name == "Worst", "worst heir")
        assert(stats.avg_impact > 0, "avg > 0")
    end)

    it("top and bottom return correct ordering", function()
        local ledger = {}
        for i = 1, 5 do
            HeirLedger.append(ledger, HeirLedger.record({
                generation = i, heir_name = "Heir" .. i,
                cultural_deltas = { physical = i * 3 },
            }))
        end
        local top = HeirLedger.top(ledger, 2)
        assert(#top == 2, "top 2")
        assert(top[1].generation == 5, "highest gen is top")
        local bot = HeirLedger.bottom(ledger, 2)
        assert(#bot == 2, "bottom 2")
        assert(bot[1].generation == 1, "lowest gen is bottom")
    end)

    it("describe produces non-empty string", function()
        local entry = HeirLedger.record({ generation = 3, heir_name = "Zara" })
        local desc = HeirLedger.describe(entry)
        assert(#desc > 0, "non-empty description")
        assert(desc:find("Zara"), "contains name")
        assert(desc:find("Impact"), "contains impact")
    end)

    it("acts are preserved in entry", function()
        local entry = HeirLedger.record({
            generation = 1,
            acts = { "betrayed_ally", "invested_arts" },
        })
        assert(#entry.acts == 2, "acts preserved")
        assert(entry.acts[1] == "betrayed_ally", "first act")
    end)

    it("alliance scores respond to disposition deltas", function()
        local positive = HeirLedger.record({
            generation = 1,
            disposition_deltas = { { delta = 20 }, { delta = 15 } },
        })
        local negative = HeirLedger.record({
            generation = 2,
            disposition_deltas = { { delta = -20 }, { delta = -15 } },
        })
        assert(positive.alliances > negative.alliances,
            "positive alliances > negative: " .. positive.alliances .. " vs " .. negative.alliances)
    end)
end)
