-- Dark Legacy — Marriage Type Tests

local rng = require("dredwork_core.rng")
rng.seed(42)

local Marriage = require("dredwork_world.marriage")
local Personality = require("dredwork_genetics.personality")
local CulturalMemory = require("dredwork_genetics.cultural_memory")

describe("Marriage", function()

    it("resolves free marriage type by default", function()
        local heir_pers = Personality.new({ PER_LOY = 50, PER_VOL = 40 })
        local mate = { personality = Personality.new(), compatibility = 55 }
        local cm = CulturalMemory.new()
        local result = Marriage.resolve_type(heir_pers, mate, cm, nil, "ancient", 5)
        assert_equal("free", result.type, "default should be free")
        assert_true(result.player_chooses, "player should choose in free marriage")
    end)

    it("resolves forced marriage when faction hostile and powerful", function()
        local heir_pers = Personality.new()
        local faction = { disposition = -30, power = 80 }
        local mate = { personality = Personality.new(), compatibility = 40, faction_id = "house_mordthen" }
        local cm = CulturalMemory.new()
        local result = Marriage.resolve_type(heir_pers, mate, cm, faction, "iron", 10)
        assert_equal("forced", result.type, "should be forced")
        assert_true(not result.player_chooses, "player should not choose in forced marriage")
    end)

    it("resolves love marriage with high compatibility and loyal volatile heir", function()
        local heir_pers = Personality.new({ PER_LOY = 75, PER_VOL = 60 })
        local mate = { personality = Personality.new(), compatibility = 85 }
        local cm = CulturalMemory.new()
        local result = Marriage.resolve_type(heir_pers, mate, cm, nil, "ancient", 5)
        assert_equal("love", result.type, "should be love")
        assert_true(not result.player_chooses, "heir chooses in love marriage")
    end)

    it("resolves forbidden marriage when compatibility is very low", function()
        local heir_pers = Personality.new({ PER_LOY = 30, PER_VOL = 30 })
        local mate = { personality = Personality.new(), compatibility = 20, faction_id = "house_test" }
        local cm = CulturalMemory.new()
        local result = Marriage.resolve_type(heir_pers, mate, cm, nil, "dark", 15)
        assert_equal("forbidden", result.type, "should be forbidden with low compatibility")
        assert_true(result.player_chooses, "player can still choose forbidden")
    end)

    it("resolves forbidden marriage when taboo exists against faction", function()
        local heir_pers = Personality.new()
        local mate = { personality = Personality.new(), compatibility = 55, faction_id = "house_enemy" }
        local cm = CulturalMemory.new()
        cm:add_taboo("betrayal", 3, "will_never_ally_with_house_enemy", 80)
        local result = Marriage.resolve_type(heir_pers, mate, cm, nil, "ancient", 10)
        assert_equal("forbidden", result.type, "should be forbidden with taboo")
    end)

    it("resolves arranged marriage when relationship exists with faction", function()
        local heir_pers = Personality.new({ PER_LOY = 40, PER_VOL = 40 })
        local mate = { personality = Personality.new(), compatibility = 55, faction_id = "house_ally" }
        local cm = CulturalMemory.new()
        cm:add_relationship("house_ally", "ally", 2, 60, "trade_pact")
        local result = Marriage.resolve_type(heir_pers, mate, cm, nil, "ancient", 8)
        assert_equal("arranged", result.type, "should be arranged with existing alliance")
    end)

    it("get_transition_quote returns a string", function()
        local quote = Marriage.get_transition_quote("love")
        assert_not_nil(quote, "should return a quote")
        assert_true(type(quote) == "string", "quote should be a string")
    end)

    it("get_offspring_header returns a string", function()
        local header = Marriage.get_offspring_header("forced")
        assert_not_nil(header, "should return a header")
        assert_true(type(header) == "string", "header should be a string")
    end)

    it("returns narrative text for all marriage types", function()
        for _, mt in ipairs({"forced", "love", "arranged", "forbidden", "free"}) do
            local quote = Marriage.get_transition_quote(mt)
            assert_true(#quote > 0, mt .. " transition quote should not be empty")
            local header = Marriage.get_offspring_header(mt)
            assert_true(#header > 0, mt .. " offspring header should not be empty")
        end
    end)
end)
