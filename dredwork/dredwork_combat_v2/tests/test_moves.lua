-- Test: dredwork_combat_v2/moves.lua

local Moves = require("dredwork_combat_v2.moves")

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

test("get returns move definition", function()
    local m = Moves.get("strike")
    assert(m, "strike should exist")
    assert(m.base_damage == 12)
    assert(m.power_stat == "power")
end)

test("get returns nil for unknown move", function()
    assert(Moves.get("nonexistent") == nil)
end)

test("all_ids returns 14 moves", function()
    local ids = Moves.all_ids()
    assert(#ids == 14, "expected 14 moves, got " .. #ids)
end)

test("core triangle counter relationships", function()
    assert(Moves.check_counter("strike", "feint") == "counters")
    assert(Moves.check_counter("counter", "strike") == "counters")
    assert(Moves.check_counter("feint", "counter") == "counters")
    assert(Moves.check_counter("strike", "counter") == "countered")
end)

test("grapple triangle counter relationships", function()
    assert(Moves.check_counter("grab", "dodge") == "counters")
    assert(Moves.check_counter("dodge", "shove") == "counters")
    assert(Moves.check_counter("shove", "grab") == "counters")
end)

test("v2 move counter relationships", function()
    assert(Moves.check_counter("lunge", "dodge") == "counters")
    assert(Moves.check_counter("brace", "lunge") == "counters")
    assert(Moves.check_counter("gouge", "clinch") == "counters")
    assert(Moves.check_counter("headbutt", "clinch") == "counters")
    assert(Moves.check_counter("taunt", "brace") == "counters")
    assert(Moves.check_counter("disarm", "strike") == "counters")
end)

test("neutral matchup returns neutral", function()
    assert(Moves.check_counter("strike", "grab") == "neutral")
    assert(Moves.check_counter("taunt", "dodge") == "neutral")
end)

test("dirty gate blocks dirty for non-dirty fighters", function()
    local rng = make_rng(42)
    local clean = { power = 50, speed = 50, grit = 50, cunning = 50, aggression = 50, volatility = 50, dirty = false, stamina = 70 }
    -- Run many selections — dirty should never appear
    for _ = 1, 100 do
        local move = Moves.select(clean, rng, 1, nil, nil, nil)
        assert(move ~= "dirty", "dirty should be gated for clean fighters")
    end
end)

test("gouge gate blocks for non-cruel fighters", function()
    local rng = make_rng(42)
    local nice = { power = 50, speed = 50, grit = 50, cunning = 50, aggression = 50, volatility = 50, cruel = false, stamina = 70 }
    for _ = 1, 100 do
        local move = Moves.select(nice, rng, 1, nil, nil, nil)
        assert(move ~= "gouge", "gouge should be gated for non-cruel fighters")
    end
end)

test("lunge gate blocks low-aggression fighters", function()
    local rng = make_rng(42)
    local passive = { power = 50, speed = 50, grit = 50, cunning = 50, aggression = 30, volatility = 30, stamina = 70 }
    for _ = 1, 100 do
        local move = Moves.select(passive, rng, 1, nil, nil, nil)
        assert(move ~= "lunge", "lunge should be gated for low-aggression fighters")
    end
end)

test("aggressive fighters favor strike/lunge", function()
    local rng = make_rng(42)
    local aggressive = { power = 70, speed = 50, grit = 50, cunning = 30, aggression = 85, volatility = 40, stamina = 70, dirty = false, cruel = false }
    local counts = {}
    for _ = 1, 200 do
        local move = Moves.select(aggressive, rng, 1, nil, nil, nil)
        counts[move] = (counts[move] or 0) + 1
    end
    local attack_moves = (counts.strike or 0) + (counts.lunge or 0) + (counts.shove or 0)
    assert(attack_moves >= 60, "aggressive fighters should favor attack moves, got " .. attack_moves .. "/200")
end)

test("terrain modifiers affect selection", function()
    local rng = make_rng(42)
    local fighter = { power = 50, speed = 50, grit = 50, cunning = 60, aggression = 50, volatility = 50, dirty = true, cruel = true, stamina = 70 }
    local pit_dirty = 0
    local open_dirty = 0
    for _ = 1, 200 do
        local m1 = Moves.select(fighter, make_rng(_ * 7), 1, nil, "pit", nil)
        local m2 = Moves.select(fighter, make_rng(_ * 7), 1, nil, nil, nil)
        if m1 == "dirty" or m1 == "gouge" then pit_dirty = pit_dirty + 1 end
        if m2 == "dirty" or m2 == "gouge" then open_dirty = open_dirty + 1 end
    end
    assert(pit_dirty >= open_dirty, "pit terrain should increase dirty/gouge frequency")
end)

test("calc_damage factors in condition", function()
    local healthy = { power = 70, condition = 1.0 }
    local wounded = { power = 70, condition = 0.5 }
    local d1 = Moves.calc_damage("strike", healthy, {})
    local d2 = Moves.calc_damage("strike", wounded, {})
    assert(d2 < d1, "wounded fighter should deal less damage")
end)

test("calc_damage includes weapon bonus", function()
    local unarmed = { power = 50, condition = 1.0 }
    local armed = { power = 50, condition = 1.0, weapon = { damage_bonus = 6 } }
    local d1 = Moves.calc_damage("strike", unarmed, {})
    local d2 = Moves.calc_damage("strike", armed, {})
    assert(d2 > d1, "armed fighter should deal more damage")
    assert(d2 - d1 >= 5, "weapon bonus should add ~6 damage")
end)

test("stamina_cost returns correct values", function()
    assert(Moves.stamina_cost("strike") == 8)
    assert(Moves.stamina_cost("lunge") == 14)
    assert(Moves.stamina_cost("clinch") == 3)
    assert(Moves.stamina_cost("brace") == 4)
end)

return pass, fail
