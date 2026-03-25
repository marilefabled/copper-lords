-- Dark Legacy — Faction Genetics Tests
-- Tests that factions get proper genetic profiles and evolve over time.

local rng = require("dredwork_core.rng")
rng.seed(42)

local FactionGenetics = require("dredwork_world.faction_genetics")
local faction_mod = require("dredwork_world.faction")
local Faction = faction_mod.Faction

describe("FactionGenetics", function()

    it("init produces trait averages for a faction", function()
        local f = Faction.new({
            id = "house_mordthen",
            name = "House Mordthen",
            category_scores = { physical = 72, mental = 45, social = 40, creative = 30 },
        })
        FactionGenetics.init(f)
        assert_not_nil(f.trait_averages, "trait_averages should exist")
        assert_not_nil(f.trait_averages.PHY_STR, "PHY_STR should have an average")
        assert_in_range(f.trait_averages.PHY_STR, 20, 85, "PHY_STR range")
    end)

    it("physical faction has higher PHY averages than CRE", function()
        local f = Faction.new({
            id = "house_mordthen",
            name = "House Mordthen",
            category_scores = { physical = 80, mental = 40, social = 40, creative = 25 },
        })
        FactionGenetics.init(f)
        -- Average physical traits should be higher than creative traits
        local phy_sum, phy_count = 0, 0
        local cre_sum, cre_count = 0, 0
        for id, val in pairs(f.trait_averages) do
            if id:sub(1, 3) == "PHY" then
                phy_sum = phy_sum + val
                phy_count = phy_count + 1
            elseif id:sub(1, 3) == "CRE" then
                cre_sum = cre_sum + val
                cre_count = cre_count + 1
            end
        end
        local phy_avg = phy_count > 0 and phy_sum / phy_count or 0
        local cre_avg = cre_count > 0 and cre_sum / cre_count or 0
        assert_true(phy_avg > cre_avg, "Physical avg (" .. phy_avg .. ") should exceed Creative avg (" .. cre_avg .. ")")
    end)

    it("evolve drifts dominant category upward", function()
        local f = Faction.new({
            id = "test_faction",
            name = "Test",
            category_scores = { physical = 80, mental = 30, social = 30, creative = 30 },
        })
        FactionGenetics.init(f)
        local original_phy = 0
        local count = 0
        for id, val in pairs(f.trait_averages) do
            if id:sub(1, 3) == "PHY" then
                original_phy = original_phy + val
                count = count + 1
            end
        end
        original_phy = original_phy / count

        -- Evolve 10 generations
        for i = 1, 10 do
            FactionGenetics.evolve(f, "iron", i)
        end

        local new_phy = 0
        count = 0
        for id, val in pairs(f.trait_averages) do
            if id:sub(1, 3) == "PHY" then
                new_phy = new_phy + val
                count = count + 1
            end
        end
        new_phy = new_phy / count
        assert_true(new_phy >= original_phy, "Physical traits should drift up for dominant category")
    end)

    it("get_mate_baseline returns trait averages", function()
        local f = Faction.new({
            id = "house_pallwick",
            name = "House Pallwick",
            category_scores = { physical = 35, mental = 75, social = 50, creative = 55 },
        })
        FactionGenetics.init(f)
        local baseline = FactionGenetics.get_mate_baseline(f)
        assert_not_nil(baseline, "baseline should not be nil")
        assert_not_nil(baseline.MEN_INT, "should have MEN_INT")
    end)

    it("get_mate_baseline returns empty table if no trait_averages", function()
        local f = Faction.new({
            id = "test_empty",
            name = "Test",
            category_scores = { physical = 50 },
        })
        local baseline = FactionGenetics.get_mate_baseline(f)
        assert_not_nil(baseline, "should return empty table, not nil")
    end)

    it("seed overrides apply for known factions", function()
        local f = Faction.new({
            id = "house_mordthen",
            name = "House Mordthen",
            category_scores = { physical = 72, mental = 45, social = 40, creative = 30 },
        })
        FactionGenetics.init(f)
        -- Varen should have boosted PHY_STR from seeds (68 base)
        assert_true(f.trait_averages.PHY_STR >= 60, "Varen PHY_STR should be high from seed")
    end)
end)
