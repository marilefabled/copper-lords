-- dredwork — Geography Interconnection Test
-- Demonstrates spatial connectivity and its impact on Home upkeep.

local Engine = require("dredwork_engine")

-- 1. Setup Engine
local engine = Engine.new({
    seed = 202,
    modules = {
        geography = "dredwork_geography",
        home      = "dredwork_home"
    }
})

print("=== GEOGRAPHY INTERCONNECTION TEST ===")

-- 2. Setup Map
print("\n[Map] Forging the world...")
engine.geography:add_region("plains", "The Sunny Plains", "temperate")
engine.geography:add_region("tundra", "The Frozen North", "tundra")
engine.geography:link_regions("plains", "tundra", 5) -- 5 distance units apart

-- 3. Test 1: Upkeep in the Plains
engine.home:establish("castle") -- Standard 50 upkeep
engine.game_state.resources = { gold = 55 } -- Just enough for standard

print("\n[Location] Currently in: " .. engine.geography:get_current_region().label)
print("[Action] Advancing generation in the Plains...")
engine:advance_generation()

-- 4. Move to Tundra
print("\n[Action] Relocating to the Frozen North...")
engine.game_state.world_map.current_region_id = "tundra"
print("[Location] Currently in: " .. engine.geography:get_current_region().label)

print("[Action] Advancing generation in the Tundra (with 55 gold)...")
engine:advance_generation() -- This should fail because Tundra has 1.5x upkeep (50 * 1.5 = 75)

-- 5. Distance check
local travel = engine.geography:get_travel_time("plains", "tundra")
print(string.format("\n[Spatial] Travel time from Plains to Tundra: %d units", travel))

print("\n=== TEST COMPLETE ===")
