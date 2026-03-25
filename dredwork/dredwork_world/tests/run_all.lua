#!/usr/bin/env lua
-- Dark Legacy — World Module Test Runner
-- Run from project root: lua dredwork_world/tests/run_all.lua

-- Fix require paths: add project root to package.path
local script_path = arg[0] or "dredwork_world/tests/run_all.lua"
local project_root = script_path:match("(.*/)")
if project_root then
    project_root = project_root .. "../../"
else
    project_root = "./"
end
package.path = project_root .. "?.lua;" .. project_root .. "?/init.lua;" .. package.path

-- Minimal test framework (same as genetics tests)
local total_tests = 0
local total_passed = 0
local total_failed = 0
local failures = {}

function describe(name, fn)
    print("\n--- " .. name .. " ---")
    fn()
end

function it(name, fn)
    total_tests = total_tests + 1
    local ok, err = pcall(fn)
    if ok then
        total_passed = total_passed + 1
        print("  PASS: " .. name)
    else
        total_failed = total_failed + 1
        print("  FAIL: " .. name)
        print("        " .. tostring(err))
        failures[#failures + 1] = { name = name, err = tostring(err) }
    end
end

function assert_equal(expected, actual, msg)
    if expected ~= actual then
        error((msg or "assert_equal") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual), 2)
    end
end

function assert_true(val, msg)
    if not val then
        error((msg or "assert_true") .. ": expected true, got " .. tostring(val), 2)
    end
end

function assert_nil(val, msg)
    if val ~= nil then
        error((msg or "assert_nil") .. ": expected nil, got " .. tostring(val), 2)
    end
end

function assert_not_nil(val, msg)
    if val == nil then
        error((msg or "assert_not_nil") .. ": expected non-nil value", 2)
    end
end

function assert_in_range(val, min, max, msg)
    if val < min or val > max then
        error((msg or "assert_in_range") .. ": " .. tostring(val) .. " not in [" .. min .. ", " .. max .. "]", 2)
    end
end

-- Make test functions global
_G.describe = describe
_G.it = it
_G.assert_equal = assert_equal
_G.assert_true = assert_true
_G.assert_nil = assert_nil
_G.assert_not_nil = assert_not_nil
_G.assert_in_range = assert_in_range

-- Mock Solar2D 'system' global for pure Lua tests
if not _G.system then
    _G.system = {
        pathForFile = function(filename, baseDir) return filename end,
        DocumentsDirectory = "docs",
        CachesDirectory = "cache",
        TemporaryDirectory = "temp",
        ResourceDirectory = "res",
    }
end

-- Test files
local test_files = {
    "dredwork_world.tests.test_world_state",
    "dredwork_world.tests.test_faction",
    "dredwork_world.tests.test_event_engine",
    "dredwork_world.tests.test_integration",
    "dredwork_world.tests.test_proc_gen",
    "dredwork_world.tests.test_legends",
    "dredwork_world.tests.test_epitaphs",
    "dredwork_world.tests.test_milestones",
    "dredwork_world.tests.test_black_sheep",
    "dredwork_world.tests.test_crucible",
    "dredwork_world.tests.test_momentum",
    "dredwork_world.tests.test_fossils",
    "dredwork_world.tests.test_dream",
    "dredwork_world.tests.test_echoes",
    "dredwork_world.tests.test_tease",
    "dredwork_world.tests.test_event_chains",
    "dredwork_world.tests.test_chronicle_code",
    "dredwork_world.tests.test_faction_genetics",
    "dredwork_world.tests.test_marriage",
    "dredwork_world.tests.test_births",
    "dredwork_world.tests.test_undercurrent",
    "dredwork_world.tests.test_doctrines",
    "dredwork_world.tests.test_epilogue",
    "dredwork_world.tests.test_cross_run",
    "dredwork_world.tests.test_faction_relations",
    "dredwork_world.tests.test_stat_check",
    "dredwork_world.tests.test_discoveries",
    "dredwork_world.tests.test_nurture",
    "dredwork_world.tests.test_religion",
    "dredwork_world.tests.test_culture",
    "dredwork_world.tests.test_great_works",
    "dredwork_world.tests.test_rival_heirs",
    "dredwork_world.tests.test_heir_ledger",
    "dredwork_world.tests.test_wealth",
    "dredwork_world.tests.test_morality",
    "dredwork_world.tests.test_lineage_power",
    "dredwork_world.tests.test_serializer",
    "dredwork_world.tests.test_council",
    "dredwork_world.tests.test_persistence",
    "dredwork_world.tests.test_personality_agendas",
}

print("========================================")
print("  DARK LEGACY — World Module Test Suite")
print("========================================")

for _, mod_name in ipairs(test_files) do
    local ok, err = pcall(require, mod_name)
    if not ok then
        if err and not err:match("module .* not found") then
            print("\nERROR loading " .. mod_name .. ":")
            print("  " .. tostring(err))
            total_failed = total_failed + 1
        else
            print("\n--- " .. mod_name .. " (not yet implemented, skipping) ---")
        end
    end
end

-- Summary
print("\n========================================")
print(string.format("  Results: %d passed, %d failed, %d total",
    total_passed, total_failed, total_tests))
print("========================================")

if #failures > 0 then
    print("\nFailures:")
    for i, f in ipairs(failures) do
        print(string.format("  %d) %s", i, f.name))
        print(string.format("     %s", f.err))
    end
end

if total_failed > 0 then
    os.exit(1)
end
