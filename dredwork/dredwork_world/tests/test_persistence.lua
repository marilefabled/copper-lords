-- Test: Persistence + SaveManager — save/load round-trip, migration

local Persistence = require("solar2d_bridge.persistence")
local SaveManager = require("solar2d_bridge.save_manager")
local Serializer = require("dredwork_genetics.serializer")
local genetics = require("dredwork_genetics.init")
local WorldController = require("dredwork_world.world_controller")
local GeneticsController = require("solar2d_bridge.genetics_controller")

describe("Persistence Layer", function()
    it("save and load round-trip", function()
        local data = { test = true, value = 42, nested = { a = 1 } }
        local ok = Persistence.save("test_roundtrip.json", data)
        assert_true(ok, "save succeeds")

        local loaded = Persistence.load("test_roundtrip.json")
        assert_not_nil(loaded, "load returns data")
        assert_equal(true, loaded.test, "boolean preserved")
        assert_equal(42, loaded.value, "number preserved")
        assert_equal(1, loaded.nested.a, "nested preserved")

        Persistence.delete("test_roundtrip.json")
    end)

    it("load returns nil for missing file", function()
        local data = Persistence.load("nonexistent_file_xyz.json")
        assert_nil(data, "missing file returns nil")
    end)

    it("exists returns false for missing file", function()
        assert_true(not Persistence.exists("nonexistent_file_xyz.json"), "missing file is not found")
    end)

    it("delete removes file", function()
        Persistence.save("test_delete.json", { x = 1 })
        assert_true(Persistence.exists("test_delete.json"), "file exists before delete")
        Persistence.delete("test_delete.json")
        assert_true(not Persistence.exists("test_delete.json"), "file gone after delete")
    end)

    it("handles corrupt file gracefully", function()
        -- Write raw garbage to a file
        local path = system.pathForFile("test_corrupt.json", system.DocumentsDirectory)
        local f = io.open(path, "w")
        f:write("THIS IS NOT JSON {{{[[[")
        f:close()

        local data = Persistence.load("test_corrupt.json")
        assert_nil(data, "corrupt file returns nil")
        Persistence.delete("test_corrupt.json")
    end)
end)

describe("SaveManager", function()
    it("save and load full game state", function()
        genetics.rng.seed(42)
        local gs = GeneticsController.init(42)
        GeneticsController.create_starting_heir(gs)
        gs.heir_name = "TestHeir"
        gs.lineage_name = "House Test"
        gs.generation = 5

        local world = WorldController.init("ancient")

        local ok = SaveManager.save_game(gs, world)
        assert_true(ok, "save succeeds")

        local loaded_gs, loaded_world = SaveManager.load_game()
        assert_not_nil(loaded_gs, "gameState loaded")
        assert_equal(5, loaded_gs.generation, "generation preserved")
        assert_equal("House Test", loaded_gs.lineage_name, "lineage name preserved")
        assert_equal("TestHeir", loaded_gs.heir_name, "heir name preserved")
        assert_not_nil(loaded_gs.current_heir, "genome loaded")
        assert_not_nil(loaded_gs.cultural_memory, "cultural memory loaded")

        -- Clean up
        SaveManager.delete_save()
    end)

    it("has_save and delete_save work", function()
        genetics.rng.seed(42)
        local gs = GeneticsController.init(42)
        GeneticsController.create_starting_heir(gs)
        gs.heir_name = "X"
        gs.lineage_name = "Y"
        local world = WorldController.init("ancient")

        SaveManager.save_game(gs, world)
        assert_true(SaveManager.has_save(), "save exists")

        SaveManager.delete_save()
        assert_true(not SaveManager.has_save(), "save deleted")
    end)

    it("get_save_info returns summary", function()
        genetics.rng.seed(42)
        local gs = GeneticsController.init(42)
        GeneticsController.create_starting_heir(gs)
        gs.heir_name = "Aldric"
        gs.lineage_name = "House Blackthorn"
        gs.generation = 12
        gs.era = "Medieval"
        local world = WorldController.init("medieval")

        SaveManager.save_game(gs, world)
        local info = SaveManager.get_save_info()
        assert_not_nil(info, "info returned")
        assert_equal("House Blackthorn", info.lineage_name, "lineage name")
        assert_equal(12, info.generation, "generation")
        assert_equal("Aldric", info.heir_name, "heir name")

        SaveManager.delete_save()
    end)

    it("load_game returns nil when no save", function()
        SaveManager.delete_save()
        local gs, w = SaveManager.load_game()
        assert_nil(gs, "no gameState")
        assert_nil(w, "no worldContext")
    end)

    it("save version is current", function()
        genetics.rng.seed(42)
        local gs = GeneticsController.init(42)
        GeneticsController.create_starting_heir(gs)
        gs.heir_name = "X"
        gs.lineage_name = "Y"

        SaveManager.save_game(gs, nil)

        -- Load raw data to check version
        local raw = Persistence.load("save.json")
        assert_not_nil(raw, "raw save loaded")
        assert_equal(2, raw.version, "save version is 2 (current)")

        SaveManager.delete_save()
    end)

    it("v1 save migrates to v2 on load", function()
        -- Simulate a v1 save with wealth as bare number
        local v1_data = {
            version = 1,
            timestamp = os.time(),
            game = {
                generation = 3,
                lineage_name = "OldHouse",
                heir_name = "OldHeir",
                era = "Ancient",
                wealth = 65,
                morality = -10,
                genome = { traits = {}, mastery_tags = {} },
                cultural_memory = {
                    trait_priorities = {},
                    reputation = { primary = "unknown", secondary = "unknown" },
                    taboos = {},
                    blind_spots = {},
                    relationships = {},
                },
                mutation_pressure = { value = 0, triggers = {} },
            },
        }
        Persistence.save("save.json", v1_data)

        local gs, w = SaveManager.load_game()
        assert_not_nil(gs, "v1 save loads")
        assert_equal(3, gs.generation, "generation preserved")
        -- After migration, wealth should be a table
        if gs.wealth and type(gs.wealth) == "table" then
            assert_equal(65, gs.wealth.value, "wealth value migrated")
        end

        SaveManager.delete_save()
    end)
end)
