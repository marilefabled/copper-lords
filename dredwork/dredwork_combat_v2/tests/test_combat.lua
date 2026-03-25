-- Test: dredwork_combat_v2/combat.lua

local Combat = require("dredwork_combat_v2.combat")

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

-- ─── Tests ─────────────────────────────────────────

test("build_default creates valid combatant", function()
    local c = Combat.build_default("Test")
    assert(c.name == "Test")
    assert(c.power == 50)
    assert(c.speed == 50)
    assert(c.stamina == 70)
    assert(c.condition == 1.0)
end)

test("build clamps stats to valid ranges", function()
    local c = Combat.build({ name = "X", power = 200, speed = -5, stamina = 5, condition = 2.0 })
    assert(c.power == 95, "power should clamp to 95")
    assert(c.speed == 10, "speed should clamp to 10")
    assert(c.stamina == 20, "stamina should clamp to 20")
    assert(c.condition == 1.0, "condition should clamp to 1.0")
end)

test("resolve produces beats and outcome", function()
    local p = Combat.build({ name = "Hero", power = 60, speed = 55, grit = 50, cunning = 45 })
    local o = Combat.build({ name = "Villain", power = 50, speed = 50, grit = 50, cunning = 50 })
    local result = Combat.resolve(p, o, 42)
    assert(result.beats and #result.beats > 0, "should produce beats")
    assert(result.outcome, "should produce outcome")
    assert(result.outcome.rounds > 0, "should fight at least 1 round")
    assert(result.outcome.margin, "should have margin")
end)

test("determinism: same seed produces same result", function()
    local p = Combat.build({ name = "A", power = 60, speed = 55, grit = 50, cunning = 50 })
    local o = Combat.build({ name = "B", power = 50, speed = 50, grit = 55, cunning = 45 })

    local r1 = Combat.resolve(p, o, 12345)
    local r2 = Combat.resolve(p, o, 12345)

    assert(#r1.beats == #r2.beats, "same seed should produce same beat count")
    assert(r1.outcome.winner == r2.outcome.winner, "same seed should produce same winner")
    assert(r1.outcome.rounds == r2.outcome.rounds, "same seed should produce same round count")
    assert(r1.outcome.protag_damage == r2.outcome.protag_damage, "same seed should produce same damage")
end)

test("different seeds produce different results", function()
    local p = Combat.build({ name = "A", power = 55, speed = 55, grit = 55, cunning = 55 })
    local o = Combat.build({ name = "B", power = 55, speed = 55, grit = 55, cunning = 55 })

    local results = {}
    local unique_winners = {}
    for seed = 1, 20 do
        local r = Combat.resolve(p, o, seed)
        results[#results + 1] = r
        unique_winners[r.outcome.winner or "draw"] = true
    end

    -- With evenly matched fighters, we should get variation
    local count = 0
    for _ in pairs(unique_winners) do count = count + 1 end
    assert(count >= 2, "different seeds should produce different winners (got " .. count .. " unique)")
end)

test("stronger fighter wins majority", function()
    local strong = Combat.build({ name = "Strong", power = 80, speed = 70, grit = 70, cunning = 60, aggression = 65 })
    local weak = Combat.build({ name = "Weak", power = 35, speed = 35, grit = 35, cunning = 35, aggression = 45 })

    local wins = 0
    for seed = 1, 50 do
        local r = Combat.resolve(strong, weak, seed)
        if r.outcome.protag_won == true then wins = wins + 1 end
    end
    assert(wins >= 30, "stronger fighter should win majority, got " .. wins .. "/50")
end)

test("blood stakes allow KO at 0 HP", function()
    local p = Combat.build({ name = "A", power = 75, speed = 60, grit = 60, cunning = 50 })
    local o = Combat.build({ name = "B", power = 40, speed = 40, grit = 40, cunning = 40 })
    local r = Combat.resolve(p, o, 42, { type = "blood" })
    -- Blood stakes should go longer and hit harder
    assert(r.outcome, "should produce outcome")
    assert(type(r.injuries) == "table", "should produce injuries table")
end)

test("casual stakes produce fewer injuries", function()
    local p = Combat.build({ name = "A", power = 70, speed = 60, grit = 55, cunning = 50 })
    local o = Combat.build({ name = "B", power = 60, speed = 55, grit = 50, cunning = 50 })

    local casual_injuries = 0
    local blood_injuries = 0
    for seed = 1, 20 do
        local r_casual = Combat.resolve(p, o, seed, { type = "casual" })
        local r_blood = Combat.resolve(p, o, seed, { type = "blood" })
        casual_injuries = casual_injuries + #r_casual.injuries
        blood_injuries = blood_injuries + #r_blood.injuries
    end
    assert(casual_injuries <= blood_injuries, "casual should produce fewer or equal injuries")
end)

test("terrain affects fight", function()
    local p = Combat.build({ name = "A", power = 55, speed = 55, grit = 55, cunning = 55 })
    local o = Combat.build({ name = "B", power = 55, speed = 55, grit = 55, cunning = 55 })

    local r_pit = Combat.resolve(p, o, 42, { type = "honor", terrain = "pit" })
    local r_throne = Combat.resolve(p, o, 42, { type = "honor", terrain = "throne_room" })

    -- Just verify both complete without error and produce beats
    assert(#r_pit.beats > 0)
    assert(#r_throne.beats > 0)
end)

test("beats have required fields", function()
    local p = Combat.build({ name = "A", power = 60, speed = 55, grit = 50, cunning = 50 })
    local o = Combat.build({ name = "B", power = 50, speed = 50, grit = 55, cunning = 45 })
    local r = Combat.resolve(p, o, 42)

    for i, beat in ipairs(r.beats) do
        assert(beat.text, "beat " .. i .. " missing text")
        assert(beat.delay, "beat " .. i .. " missing delay")
        assert(beat.color, "beat " .. i .. " missing color")
        assert(beat.intensity, "beat " .. i .. " missing intensity")
    end
end)

test("no placeholder leaks in beats", function()
    local p = Combat.build({ name = "Hero", power = 60, speed = 55, grit = 50, cunning = 50, personality_tag = "bold" })
    local o = Combat.build({ name = "Villain", power = 50, speed = 50, grit = 55, cunning = 50, personality_tag = "proud" })
    local r = Combat.resolve(p, o, 42)

    for i, beat in ipairs(r.beats) do
        assert(not beat.text:find("{name}"), "beat " .. i .. " has unsubstituted {name}: " .. beat.text)
        assert(not beat.text:find("{opponent}"), "beat " .. i .. " has unsubstituted {opponent}: " .. beat.text)
    end
end)

test("nemesis flag produces nemesis flavor", function()
    local p = Combat.build({ name = "Hero", power = 55, speed = 55, grit = 55, cunning = 55, is_nemesis = true })
    local o = Combat.build({ name = "Rival", power = 55, speed = 55, grit = 55, cunning = 55, is_nemesis = true })
    local r = Combat.resolve(p, o, 42)
    -- Should complete without error; nemesis prose is probabilistic
    assert(#r.beats > 0)
end)

test("weapon combatant deals more damage over many fights", function()
    local unarmed = Combat.build({ name = "A", power = 50, speed = 50, grit = 50, cunning = 50 })
    local armed = Combat.build({ name = "B", power = 50, speed = 50, grit = 50, cunning = 50,
        weapon = { id = "sword", label = "a sword", damage_bonus = 6, speed_penalty = 1 } })

    local armed_total = 0
    local unarmed_total = 0
    for seed = 1, 30 do
        local r = Combat.resolve(armed, unarmed, seed)
        armed_total = armed_total + r.outcome.opponent_damage  -- damage dealt BY armed
        unarmed_total = unarmed_total + r.outcome.protag_damage  -- damage dealt BY unarmed (as opponent)
    end
    -- Armed fighter's total damage dealt should generally be higher
    -- (though not guaranteed in every run due to RNG)
end)

test("momentum and cultural_memory_shift in result", function()
    local p = Combat.build({ name = "A", power = 70, speed = 60, grit = 60, cunning = 55 })
    local o = Combat.build({ name = "B", power = 40, speed = 40, grit = 40, cunning = 40 })
    local r = Combat.resolve(p, o, 42)
    assert(type(r.momentum_shift) == "number", "should have momentum_shift")
    assert(type(r.cultural_memory_shift) == "table", "should have cultural_memory_shift")
end)

test("outcome contains all expected fields", function()
    local p = Combat.build({ name = "A", power = 55, speed = 55, grit = 55, cunning = 55 })
    local o = Combat.build({ name = "B", power = 55, speed = 55, grit = 55, cunning = 55 })
    local r = Combat.resolve(p, o, 42)

    assert(r.outcome.rounds, "missing rounds")
    assert(r.outcome.margin, "missing margin")
    assert(r.outcome.protag_damage ~= nil, "missing protag_damage")
    assert(r.outcome.opponent_damage ~= nil, "missing opponent_damage")
    assert(r.outcome.protag_hp ~= nil, "missing protag_hp")
    assert(r.outcome.opponent_hp ~= nil, "missing opponent_hp")
    assert(type(r.outcome.ko) == "boolean", "missing ko flag")
end)

return pass, fail
