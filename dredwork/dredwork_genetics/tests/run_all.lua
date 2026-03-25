#!/usr/bin/env lua
-- Dark Legacy — Test Runner
-- Run from project root: lua dredwork_genetics/tests/run_all.lua
-- Runs all test files and reports results.

-- Fix require paths: add project root to package.path
local script_path = arg[0] or "dredwork_genetics/tests/run_all.lua"
local project_root = script_path:match("(.*/)")
if project_root then
    -- Go up two directories from tests/ to project root
    project_root = project_root .. "../../"
else
    project_root = "./"
end
package.path = project_root .. "?.lua;" .. project_root .. "?/init.lua;" .. package.path

-- Minimal test framework
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

-- Make test functions global for test files
_G.describe = describe
_G.it = it
_G.assert_equal = assert_equal
_G.assert_true = assert_true
_G.assert_nil = assert_nil
_G.assert_not_nil = assert_not_nil
_G.assert_in_range = assert_in_range

-- Discover and run test files
local test_files = {
    "dredwork_genetics.tests.test_trait",
    "dredwork_genetics.tests.test_genome",
    "dredwork_genetics.tests.test_inheritance",
    "dredwork_genetics.tests.test_mutation",
    "dredwork_genetics.tests.test_personality",
    "dredwork_genetics.tests.test_cultural_memory",
    "dredwork_genetics.tests.test_viability",
    "dredwork_genetics.tests.test_peril",
    "dredwork_genetics.tests.test_portrait_data",
    "dredwork_genetics.tests.test_sigil_data",
}

print("========================================")
print("  DARK LEGACY — Test Suite")
print("========================================")

for _, mod_name in ipairs(test_files) do
    local ok, err = pcall(require, mod_name)
    if not ok then
        -- Only report error if the file exists but failed to load
        -- Skip gracefully if the test file just hasn't been written yet
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

-- Exit with non-zero code if any failures
if total_failed > 0 then
    os.exit(1)
end
