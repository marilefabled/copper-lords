-- Test: dredwork_combat_v2/fight_pit.lua

local FightPit = require("dredwork_combat_v2.fight_pit")

local pass, fail = 0, 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        pass = pass + 1
        print("  PASS: " .. name)
    else
        fail = fail + 1
        print("  FAIL: " .. name .. " — " .. tostring(err))
    end
end

local function make_rng(seed)
    local s = math.abs(seed or 1) % 2147483647
    if s == 0 then s = 1 end
    return function(max)
        s = (s * 1103515245 + 12345) % 2147483647
        if max and max > 0 then return (s % max) + 1 end
        return s
    end
end

-- ─── Tests ─────────────────────────────────────────

test("roll_fighter produces valid combatant", function()
    local rng = make_rng(42)
    local f = FightPit.roll_fighter(rng)
    assert(f.name and #f.name > 0, "should have name")
    assert(f.power >= 10 and f.power <= 95, "power out of range: " .. f.power)
    assert(f.speed >= 10 and f.speed <= 95, "speed out of range: " .. f.speed)
    assert(f.grit >= 10 and f.grit <= 95, "grit out of range: " .. f.grit)
    assert(f.cunning >= 10 and f.cunning <= 95, "cunning out of range: " .. f.cunning)
    assert(f.stamina >= 20 and f.stamina <= 100, "stamina out of range: " .. f.stamina)
end)

test("roll_fighter produces variety", function()
    local names = {}
    for seed = 1, 20 do
        local f = FightPit.roll_fighter(make_rng(seed))
        names[f.name] = true
    end
    local count = 0
    for _ in pairs(names) do count = count + 1 end
    assert(count >= 10, "should produce at least 10 unique names in 20 rolls, got " .. count)
end)

test("roll_fighter with era parameter", function()
    local rng = make_rng(42)
    local f = FightPit.roll_fighter(rng, "dark")
    assert(f.era == "dark")
end)

test("roll_fighter sometimes has weapons", function()
    local armed = 0
    for seed = 1, 50 do
        local f = FightPit.roll_fighter(make_rng(seed))
        if f.weapon then armed = armed + 1 end
    end
    assert(armed >= 5, "at least 5/50 fighters should be armed, got " .. armed)
    assert(armed <= 45, "not all fighters should be armed, got " .. armed)
end)

test("generate produces complete pit fight", function()
    local pit = FightPit.generate(42)
    assert(pit.fighter_a, "missing fighter_a")
    assert(pit.fighter_b, "missing fighter_b")
    assert(pit.beats and #pit.beats > 0, "missing beats")
    assert(pit.outcome, "missing outcome")
    assert(pit.seed == 42, "seed should be preserved")
end)

test("generate produces unique fighters", function()
    local pit = FightPit.generate(42)
    assert(pit.fighter_a.name ~= pit.fighter_b.name, "fighters should have different names")
end)

test("generate is deterministic", function()
    local p1 = FightPit.generate(12345)
    local p2 = FightPit.generate(12345)
    assert(p1.outcome.winner == p2.outcome.winner, "same seed should produce same winner")
    assert(#p1.beats == #p2.beats, "same seed should produce same beat count")
end)

test("fighter_card produces readable output", function()
    local rng = make_rng(42)
    local f = FightPit.roll_fighter(rng)
    local lines = FightPit.fighter_card(f)
    assert(#lines >= 3, "should produce at least 3 lines")
    assert(lines[1]:find(f.name), "first line should contain name")
    assert(lines[2]:find("POW"), "second line should contain stats")
end)

test("fighter_card shows weapon info", function()
    -- Keep rolling until we get an armed fighter
    local armed_fighter = nil
    for seed = 1, 100 do
        local f = FightPit.roll_fighter(make_rng(seed))
        if f.weapon then armed_fighter = f; break end
    end
    if armed_fighter then
        local lines = FightPit.fighter_card(armed_fighter)
        local found_weapon = false
        for _, line in ipairs(lines) do
            if line:find("Armed") then found_weapon = true end
        end
        assert(found_weapon, "armed fighter card should show weapon")
    end
end)

return pass, fail
