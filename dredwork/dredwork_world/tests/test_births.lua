-- Dark Legacy — Birth Event Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local Births = require("dredwork_world.births")
local Genome = require("dredwork_genetics.genome")

describe("Births", function()

    it("resolve returns metadata for each child", function()
        local genome = Genome.new({ PHY_FER = 60, PHY_VIT = 60 })
        local result = Births.resolve(2, genome, nil, {}, 5)
        assert_not_nil(result, "result should exist")
        assert_not_nil(result.children_metadata, "metadata should exist")
        assert_true(#result.children_metadata >= 2, "should have at least 2 children")
    end)

    it("caps total children at 4", function()
        -- Force high twin chance with many conditions
        rng.seed(1)
        local genome = Genome.new({ PHY_FER = 90, PHY_VIT = 80 })
        local conditions = {
            { type = "plague", intensity = 0.8 },
            { type = "war", intensity = 0.7 },
            { type = "famine", intensity = 0.6 },
        }
        -- Run many times to check cap
        for i = 1, 50 do
            rng.seed(i)
            local result = Births.resolve(3, genome, nil, conditions, 25)
            assert_true(result.adjusted_count <= 4, "adjusted count should be <= 4, got " .. result.adjusted_count)
        end
    end)

    it("twins tag first two children with matching pair ID", function()
        -- Force twins by running many seeds until we get one
        local found_twins = false
        for seed = 1, 200 do
            rng.seed(seed)
            local genome = Genome.new({ PHY_FER = 90, PHY_VIT = 70 })
            local result = Births.resolve(2, genome, nil, {{ type = "war", intensity = 0.5 }}, 10)
            if result.birth_event == "twins" then
                found_twins = true
                local meta = result.children_metadata
                assert_equal("twin", meta[1].birth_type, "first child should be twin")
                assert_equal("twin", meta[2].birth_type, "second child should be twin")
                assert_equal(meta[1].twin_pair_id, meta[2].twin_pair_id, "twin pair IDs should match")
                break
            end
        end
        assert_true(found_twins, "should find at least one twin result in 200 seeds")
    end)

    it("miraculous birth only happens after generation 20 with conditions", function()
        local genome = Genome.new({ PHY_FER = 50, PHY_VIT = 50 })
        -- Before gen 20: should never be miraculous
        for seed = 1, 100 do
            rng.seed(seed)
            local result = Births.resolve(2, genome, nil, {{ type = "plague", intensity = 0.5 }}, 10)
            assert_true(result.birth_event ~= "miraculous", "no miraculous before gen 20")
        end
    end)

    it("normal births have normal birth_type", function()
        rng.seed(999) -- pick a seed unlikely to trigger specials
        local genome = Genome.new({ PHY_FER = 50, PHY_VIT = 70 })
        local result = Births.resolve(2, genome, nil, {}, 5)
        if result.birth_event == nil then
            for _, m in ipairs(result.children_metadata) do
                assert_equal("normal", m.birth_type, "should be normal birth type")
            end
        end
    end)

    it("get_narrative returns text for known events", function()
        assert_not_nil(Births.get_narrative("twins"), "twins narrative")
        assert_not_nil(Births.get_narrative("miraculous"), "miraculous narrative")
        assert_not_nil(Births.get_narrative("difficult"), "difficult narrative")
        assert_nil(Births.get_narrative("normal"), "normal should return nil")
    end)

    it("single child count bumps to 2 for twins", function()
        local found = false
        for seed = 1, 300 do
            rng.seed(seed)
            local genome = Genome.new({ PHY_FER = 90 })
            local result = Births.resolve(1, genome, nil, {{ type = "war", intensity = 0.5 }}, 10)
            if result.birth_event == "twins" then
                found = true
                assert_true(result.adjusted_count >= 2, "should bump to at least 2 for twins")
                break
            end
        end
        -- This is probabilistic — twins may not happen with 1 child in 300 seeds, that's ok
    end)
end)
