#!/usr/bin/env lua
local script_path = arg[0] or "dredwork_dilemma/tests/run_all.lua"
local project_root = script_path:match("(.*/)")
if project_root then
    project_root = project_root .. "../../"
else
    project_root = "./"
end
package.path = project_root .. "?.lua;" .. project_root .. "?/init.lua;" .. package.path

local total_tests = 0
local total_passed = 0
local total_failed = 0
local failures = {}

function describe(name, fn) print("\n--- " .. name .. " ---"); fn() end
function it(name, fn)
    total_tests = total_tests + 1
    local ok, err = pcall(fn)
    if ok then total_passed = total_passed + 1; print("  PASS: " .. name)
    else total_failed = total_failed + 1; print("  FAIL: " .. name); print("        " .. tostring(err)); failures[#failures + 1] = { name = name, err = tostring(err) } end
end
function assert_equal(e, a, m) if e ~= a then error((m or "assert_equal") .. ": expected " .. tostring(e) .. ", got " .. tostring(a), 2) end end
function assert_true(v, m) if not v then error((m or "assert_true") .. ": expected true, got " .. tostring(v), 2) end end
function assert_nil(v, m) if v ~= nil then error((m or "assert_nil") .. ": expected nil, got " .. tostring(v), 2) end end
function assert_not_nil(v, m) if v == nil then error((m or "assert_not_nil") .. ": expected non-nil", 2) end end

_G.describe = describe; _G.it = it; _G.assert_equal = assert_equal; _G.assert_true = assert_true; _G.assert_nil = assert_nil; _G.assert_not_nil = assert_not_nil
if not _G.system then _G.system = { pathForFile = function(f, b) return f end, DocumentsDirectory = "docs", CachesDirectory = "cache", TemporaryDirectory = "temp", ResourceDirectory = "res" } end

local test_files = {
    "dredwork_dilemma.tests.test_pressure",
    "dredwork_dilemma.tests.test_collector",
    "dredwork_dilemma.tests.test_dilemma",
}

print("========================================")
print("  DREDWORK DILEMMA — Module Test Suite")
print("========================================")

for _, mod_name in ipairs(test_files) do
    local ok, err = pcall(require, mod_name)
    if not ok then
        if err and not err:match("module .* not found") then
            print("\nERROR loading " .. mod_name .. ":"); print("  " .. tostring(err)); total_failed = total_failed + 1
        else print("\n--- " .. mod_name .. " (skipping) ---") end
    end
end

print("\n========================================")
print(string.format("  Results: %d passed, %d failed, %d total", total_passed, total_failed, total_tests))
print("========================================")
if #failures > 0 then print("\nFailures:"); for i, f in ipairs(failures) do print(string.format("  %d) %s\n     %s", i, f.name, f.err)) end end
if total_failed > 0 then os.exit(1) end
