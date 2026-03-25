-- Test: Serializer — JSON round-trip, edge cases, from_json safety

local Serializer = require("dredwork_genetics.serializer")

describe("Serializer", function()
    it("round-trips simple table", function()
        local data = { name = "test", value = 42, flag = true }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_equal("test", result.name, "name preserved")
        assert_equal(42, result.value, "number preserved")
        assert_equal(true, result.flag, "boolean preserved")
    end)

    it("round-trips nested table", function()
        local data = {
            outer = { inner = "deep", num = 3.14 },
            arr = { 1, 2, 3 },
        }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_equal("deep", result.outer.inner, "nested string")
        assert_equal(3, #result.arr, "array length")
        assert_equal(2, result.arr[2], "array element")
    end)

    it("round-trips empty table as object", function()
        local data = { items = {} }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_not_nil(result.items, "empty table preserved")
    end)

    it("handles string escapes", function()
        local data = { text = 'line1\nline2\ttab"quote' }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_true(result.text:find("\n") ~= nil, "newline preserved")
        assert_true(result.text:find("\t") ~= nil, "tab preserved")
        assert_true(result.text:find('"') ~= nil, "quote preserved")
    end)

    it("handles null/nil values", function()
        local json = '{"a":null,"b":1}'
        local result = Serializer.from_json(json)
        assert_nil(result.a, "null becomes nil")
        assert_equal(1, result.b, "non-null preserved")
    end)

    it("handles boolean false", function()
        local data = { active = false }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_equal(false, result.active, "false preserved (not nil)")
    end)

    it("from_json returns nil on empty string", function()
        local result = Serializer.from_json("")
        assert_nil(result, "empty string returns nil")
    end)

    it("from_json returns nil on nil input", function()
        local result = Serializer.from_json(nil)
        assert_nil(result, "nil input returns nil")
    end)

    it("from_json returns nil on malformed JSON", function()
        local result = Serializer.from_json("{invalid json!!!}")
        assert_nil(result, "malformed JSON returns nil instead of crash")
    end)

    it("from_json returns nil on truncated JSON", function()
        local result = Serializer.from_json('{"key": "value')
        assert_nil(result, "truncated JSON returns nil")
    end)

    it("round-trips genome-like structure", function()
        local data = {
            traits = {
                PHY_STR = { id = "PHY_STR", value = 75, category = "physical" },
                MEN_INT = { id = "MEN_INT", value = 60, category = "mental" },
            },
            mastery_tags = { "warrior", "scholar" },
        }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_equal(75, result.traits.PHY_STR.value, "trait value preserved")
        assert_equal("mental", result.traits.MEN_INT.category, "category preserved")
        assert_equal(2, #result.mastery_tags, "mastery tags preserved")
    end)

    it("round-trips save-like structure with version", function()
        local data = {
            version = 2,
            timestamp = 1709769600,
            game = {
                generation = 15,
                lineage_name = "House Blackthorn",
                heir_name = "Aldric",
                era = "Medieval",
            },
        }
        local json = Serializer.to_json(data)
        local result = Serializer.from_json(json)
        assert_equal(2, result.version, "version preserved")
        assert_equal(15, result.game.generation, "generation preserved")
        assert_equal("House Blackthorn", result.game.lineage_name, "name preserved")
    end)
end)
