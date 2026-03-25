-- dredwork_combat_v2 — Test Runner

-- Mock Solar2D system global for headless testing
if not system then
    system = { getInfo = function() return "test" end }
end

-- Set up package path
local base = debug.getinfo(1, "S").source:match("@(.*/)")
if base then
    base = base:gsub("dredwork_combat_v2/tests/", "")
    package.path = base .. "?.lua;" .. base .. "?/init.lua;" .. package.path
end

print("========================================")
print("  dredwork_combat_v2 — Test Suite")
print("========================================")

local total_pass, total_fail = 0, 0

local test_files = {
    { name = "Moves",     path = "dredwork_combat_v2/tests/test_moves.lua" },
    { name = "Combat",    path = "dredwork_combat_v2/tests/test_combat.lua" },
    { name = "Bridge",    path = "dredwork_combat_v2/tests/test_bridge.lua" },
    { name = "Fight Pit", path = "dredwork_combat_v2/tests/test_fight_pit.lua" },
}

for _, tf in ipairs(test_files) do
    print("\n── " .. tf.name .. " ──")
    local file_path = base and (base .. tf.path) or tf.path
    local ok, err = pcall(function()
        local chunk = loadfile(file_path)
        if not chunk then error("could not load " .. file_path) end
        local p, f = chunk()
        total_pass = total_pass + (p or 0)
        total_fail = total_fail + (f or 0)
    end)
    if not ok then
        print("  ERROR: " .. tostring(err))
        total_fail = total_fail + 1
    end
end

print("\n========================================")
print(string.format("  Results: %d passed, %d failed, %d total",
    total_pass, total_fail, total_pass + total_fail))
print("========================================")

if total_fail > 0 then os.exit(1) end
