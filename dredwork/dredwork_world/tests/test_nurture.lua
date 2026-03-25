-- Dark Legacy — Nurture Tests

local Nurture = require("dredwork_world.nurture")
local Genome = require("dredwork_genetics.genome")

-- Mock world state with conditions
local function mock_world_state(conditions)
    return { conditions = conditions or {} }
end

-- Mock cultural memory with trait priorities
local function mock_cultural_memory(priorities)
    return { trait_priorities = priorities or {} }
end

describe("Nurture", function()
    it("returns empty modifiers with no world state", function()
        local mods = Nurture.compute(nil, nil, nil, nil)
        assert_equal(0, #mods)
    end)

    it("returns war modifiers during wartime", function()
        local ws = mock_world_state({
            { type = "war", remaining_gens = 3 },
        })
        local mods = Nurture.compute(ws, nil, nil, nil)
        local found_str = false
        local found_com = false
        for _, m in ipairs(mods) do
            if m.trait == "PHY_STR" and m.source == "war_era" then found_str = true end
            if m.trait == "MEN_COM" and m.source == "war_era" then found_com = true end
        end
        assert_true(found_str, "should have PHY_STR war bonus")
        assert_true(found_com, "should have MEN_COM war bonus")
    end)

    it("returns plague modifier during plague", function()
        local ws = mock_world_state({
            { type = "plague", remaining_gens = 2 },
        })
        local mods = Nurture.compute(ws, nil, nil, nil)
        local found = false
        for _, m in ipairs(mods) do
            if m.trait == "PHY_IMM" and m.source == "plague_survivor" then found = true end
        end
        assert_true(found, "should have PHY_IMM plague bonus")
    end)

    it("returns famine modifiers during famine", function()
        local ws = mock_world_state({
            { type = "famine", remaining_gens = 1 },
        })
        local mods = Nurture.compute(ws, nil, nil, nil)
        local found_met = false
        local found_res = false
        for _, m in ipairs(mods) do
            if m.trait == "PHY_MET" then found_met = true end
            if m.trait == "CRE_RES" then found_res = true end
        end
        assert_true(found_met, "should have PHY_MET famine bonus")
        assert_true(found_res, "should have CRE_RES famine bonus")
    end)

    it("returns era-based modifier for known era", function()
        local mods = Nurture.compute(nil, nil, "arcane", nil)
        local found = false
        for _, m in ipairs(mods) do
            if m.source == "era_influence" and m.trait == "MEN_ABS" then found = true end
        end
        assert_true(found, "should have arcane era modifier for MEN_ABS")
    end)

    it("returns cultural memory modifier for high-priority category", function()
        local cm = mock_cultural_memory({
            PHY_STR = 70, PHY_END = 68, PHY_VIT = 72,
            MEN_INT = 40, SOC_CHA = 45, CRE_ING = 35,
        })
        local mods = Nurture.compute(nil, cm, nil, nil)
        local found = false
        for _, m in ipairs(mods) do
            if m.source == "scholarly_lineage" then found = true end
        end
        assert_true(found, "should have scholarly_lineage modifier for high-priority category")
    end)

    it("does not return cultural memory modifier when priorities below 55", function()
        local cm = mock_cultural_memory({
            PHY_STR = 50, MEN_INT = 50, SOC_CHA = 50, CRE_ING = 50,
        })
        local mods = Nurture.compute(nil, cm, nil, nil)
        local found = false
        for _, m in ipairs(mods) do
            if m.source == "scholarly_lineage" then found = true end
        end
        assert_true(not found, "should NOT have scholarly_lineage modifier when priorities at 50")
    end)

    it("caps modifiers at 5", function()
        local ws = mock_world_state({
            { type = "war", remaining_gens = 3 },
            { type = "plague", remaining_gens = 2 },
            { type = "famine", remaining_gens = 1 },
        })
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75, PHY_VIT = 78,
        })
        local mods = Nurture.compute(ws, cm, "iron", nil)
        assert_true(#mods <= 5, "modifiers should be capped at 5, got " .. #mods)
    end)

    it("applies modifiers to genome", function()
        local g = Genome.new({ PHY_STR = 50 })
        local mods = {
            { source = "test", trait = "PHY_STR", bonus = 10, description = "test" },
        }
        Nurture.apply(g, mods)
        assert_equal(60, g:get_value("PHY_STR"))
    end)

    it("handles discovery bonuses", function()
        local mock_discoveries = {
            get_effects = function()
                return {
                    trait_bonuses = { PHY_STR = 5, MEN_INT = 3 },
                }
            end,
        }
        local mods = Nurture.compute(nil, nil, nil, mock_discoveries)
        local found_str = false
        local found_int = false
        for _, m in ipairs(mods) do
            if m.trait == "PHY_STR" and m.source == "discovery" then found_str = true end
            if m.trait == "MEN_INT" and m.source == "discovery" then found_int = true end
        end
        assert_true(found_str, "should have PHY_STR discovery bonus")
        assert_true(found_int, "should have MEN_INT discovery bonus")
    end)

    it("ignores expired conditions", function()
        local ws = mock_world_state({
            { type = "war", remaining_gens = 0 },
        })
        local mods = Nurture.compute(ws, nil, nil, nil)
        local found = false
        for _, m in ipairs(mods) do
            if m.source == "war_era" then found = true end
        end
        assert_true(not found, "should NOT have war modifiers when remaining_gens = 0")
    end)
end)
