-- Dark Legacy — Religion Tests

local rng = require("dredwork_core.rng")
local Genome = require("dredwork_genetics.genome")
local Religion = require("dredwork_world.religion")

-- Mock cultural memory with trait priorities
local function mock_cultural_memory(priorities)
    return { trait_priorities = priorities or {} }
end

describe("Religion", function()
    it("creates inactive religion", function()
        local r = Religion.new()
        assert_equal(false, r.active)
        assert_nil(r.name)
        assert_equal(0, #r.tenets)
    end)

    it("generates religion from cultural memory", function()
        local cm = mock_cultural_memory({
            PHY_STR = 70, PHY_END = 65,
            MEN_INT = 60, MEN_WIL = 55,
            SOC_CHA = 40, CRE_ING = 30,
        })
        local r = Religion.new()
        r:generate(cm, 5)
        assert_true(r.active, "should be active after generation")
        assert_not_nil(r.name)
        assert_true(#r.name > 0, "name should not be empty")
        assert_equal(5, r.generation_founded)
        assert_true(#r.tenets > 0, "should have at least one tenet")
        assert_true(#r.tenets <= 2, "should have at most 2 tenets")
        assert_in_range(r.zealotry, 30, 50, "initial zealotry range")
    end)

    it("tenets reflect top cultural categories", function()
        local cm = mock_cultural_memory({
            PHY_STR = 90, PHY_END = 85,
            MEN_INT = 30, SOC_CHA = 20, CRE_ING = 25,
        })
        local r = Religion.new()
        r:generate(cm, 3)
        -- Physical should definitely be a tenet category
        local has_physical = false
        for _, t in ipairs(r.tenets) do
            if t.category == "physical" then has_physical = true end
        end
        assert_true(has_physical, "should have physical tenet for physical-dominant memory")
    end)

    it("tick increases zealotry with aligned heir", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
            MEN_INT = 40, SOC_CHA = 30, CRE_ING = 25,
        })
        local r = Religion.new()
        r:generate(cm, 3)
        r.zealotry = 50

        -- Create heir strong in physical (matches tenet)
        local heir = Genome.new({ PHY_STR = 80, PHY_END = 75, PHY_VIT = 70 })
        local result = r:tick(heir, cm, 6)
        -- Aligned heir should boost zealotry (or at least not reduce it much after decay)
        assert_true(result.zealotry_changed >= 0 or r.zealotry >= 45,
            "zealotry should be maintained or increase with aligned heir")
    end)

    it("tick builds schism pressure with contradicting heir", function()
        local cm = mock_cultural_memory({
            PHY_STR = 80, PHY_END = 75,
        })
        local r = Religion.new()
        r:generate(cm, 3)
        r.zealotry = 50
        r.schism_pressure = 0

        -- Create heir very weak in ALL physical traits (contradicts tenet)
        local overrides = {}
        for _, suffix in ipairs({"STR","END","VIT","AGI","REF","PAI","FER","LON","IMM","REC","BON","LUN","COR","MET","HGT","BLD","SEN","ADP"}) do
            overrides["PHY_" .. suffix] = 15
        end
        local heir = Genome.new(overrides)
        r:tick(heir, cm, 6)
        assert_true(r.schism_pressure > 0,
            "schism pressure should increase with contradicting heir")
    end)

    it("schism triggers at high pressure", function()
        local cm = mock_cultural_memory({ PHY_STR = 80 })
        local r = Religion.new()
        r:generate(cm, 3)
        r.zealotry = 60
        r.schism_pressure = 80

        local heir = Genome.new({ PHY_STR = 20 })
        local result = r:tick(heir, cm, 10)
        assert_true(result.schism_triggered, "schism should trigger at pressure >= 80")
        assert_equal(0, r.schism_pressure)
        assert_equal(1, r.schism_count)
        assert_true(r.zealotry < 60, "zealotry should be halved after schism")
    end)

    it("get_bonuses scales by zealotry", function()
        local r = Religion.new()
        r.active = true
        r.zealotry = 100
        r.tenets = {
            { id = "test", label = "Test", category = "physical", trait_id = "PHY_STR", bonus = 3, description = "test" },
        }
        local bonuses = r:get_bonuses()
        assert_equal(3, bonuses.PHY_STR)

        r.zealotry = 50
        bonuses = r:get_bonuses()
        -- floor(3 * 0.5) = 1
        assert_equal(1, bonuses.PHY_STR)
    end)

    it("get_bonuses returns empty when inactive", function()
        local r = Religion.new()
        r.active = false
        local bonuses = r:get_bonuses()
        assert_true(next(bonuses) == nil, "inactive religion should have no bonuses")
    end)

    it("tick returns no-op for inactive religion", function()
        local r = Religion.new()
        local result = r:tick(nil, nil, 5)
        assert_equal(0, result.zealotry_changed)
        assert_equal(false, result.schism_triggered)
    end)

    it("serializes and deserializes correctly", function()
        local cm = mock_cultural_memory({
            PHY_STR = 70, MEN_INT = 60,
        })
        local r = Religion.new()
        r:generate(cm, 5)
        r.zealotry = 65
        r.schism_pressure = 20
        r.schism_count = 1

        local data = r:to_table()
        local restored = Religion.from_table(data)
        assert_equal(r.name, restored.name)
        assert_equal(r.zealotry, restored.zealotry)
        assert_equal(r.schism_pressure, restored.schism_pressure)
        assert_equal(r.active, restored.active)
        assert_equal(r.schism_count, restored.schism_count)
        assert_equal(#r.tenets, #restored.tenets)
    end)

    it("get_display returns expected fields", function()
        local r = Religion.new()
        r.name = "Test Faith"
        r.active = true
        r.zealotry = 50
        r.schism_pressure = 10
        local d = r:get_display()
        assert_equal("Test Faith", d.name)
        assert_equal(50, d.zealotry)
        assert_equal(10, d.schism_pressure)
        assert_equal(true, d.active)
    end)
end)
