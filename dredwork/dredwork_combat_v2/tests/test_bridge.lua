-- Test: dredwork_combat_v2/bridge.lua

local Bridge = require("dredwork_combat_v2.bridge")
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

-- Mock Bloodweight objects
local function mock_genome(overrides)
    local traits = {
        PHY_STR = 60, PHY_VIT = 55, PHY_BLD = 50, PHY_END = 50,
        MEN_WIL = 50, MEN_INT = 55,
    }
    if overrides then
        for k, v in pairs(overrides) do traits[k] = v end
    end
    return {
        traits = traits,
        get = function(self, id) return self.traits[id] or 50 end,
    }
end

local function mock_personality(overrides)
    local axes = {
        PER_BLD = 55, PER_CRM = 50, PER_VOL = 45, PER_PRI = 50,
        PER_ADA = 50, PER_LOY = 50, PER_CUR = 50, PER_OBS = 50,
    }
    if overrides then
        for k, v in pairs(overrides) do axes[k] = v end
    end
    return { axes = axes }
end

-- ─── Tests ─────────────────────────────────────────

test("build_heir produces valid combatant", function()
    local gs = {
        current_heir = mock_genome(),
        heir_personality = mock_personality(),
        heir_name = "Kael",
        lineage_name = "Ashborne",
        era = "Iron",
    }
    local wc = {
        world_state = { conditions = {} },
    }
    local c = Bridge.build_heir(gs, wc)
    assert(c.name == "Kael")
    assert(c.power >= 10 and c.power <= 95)
    assert(c.speed >= 10 and c.speed <= 95)
    assert(c.era == "iron")
    assert(c.title == "of House Ashborne")
end)

test("build_heir maps strong heir to high power", function()
    local gs = {
        current_heir = mock_genome({ PHY_STR = 90 }),
        heir_personality = mock_personality({ PER_BLD = 80 }),
        heir_name = "Bram",
        era = "Ancient",
    }
    local c = Bridge.build_heir(gs, {})
    assert(c.power >= 60, "strong heir should have high power, got " .. c.power)
end)

test("build_heir maps cunning heir correctly", function()
    local gs = {
        current_heir = mock_genome({ MEN_INT = 85 }),
        heir_personality = mock_personality({ PER_ADA = 75, PER_CUR = 70 }),
        heir_name = "Myr",
        era = "Arcane",
    }
    local c = Bridge.build_heir(gs, {})
    assert(c.cunning >= 55, "cunning heir should have high cunning, got " .. c.cunning)
end)

test("build_heir war condition reduces stamina and adds traits", function()
    local gs = {
        current_heir = mock_genome(),
        heir_personality = mock_personality(),
        heir_name = "Test",
    }
    local wc_peace = { world_state = { conditions = {} } }
    local wc_war = { world_state = { conditions = { "war", "plague" } } }

    local c_peace = Bridge.build_heir(gs, wc_peace)
    local c_war = Bridge.build_heir(gs, wc_war)

    assert(c_war.stamina < c_peace.stamina, "war+plague should reduce stamina")
    assert(c_war.condition < c_peace.condition, "conditions should reduce condition")
end)

test("build_heir cruel personality enables dirty+cruel", function()
    local gs = {
        current_heir = mock_genome(),
        heir_personality = mock_personality({ PER_CRM = 20 }),  -- low mercy = cruel
        heir_name = "Vex",
    }
    local c = Bridge.build_heir(gs, {})
    assert(c.dirty == true, "low mercy should enable dirty fighting")
    assert(c.cruel == true, "low mercy should enable cruel moves")
    assert(c.personality_tag == "cruel", "should be tagged cruel, got " .. tostring(c.personality_tag))
end)

test("build_rival produces valid nemesis combatant", function()
    local rival = { name = "Drav", personality = { PER_BLD = 70, PER_CRM = 30 } }
    local faction = { name = "The Iron Covenant", archetype = "warriors", power = 60 }
    local c = Bridge.build_rival(rival, faction, nil)

    assert(c.name == "Drav")
    assert(c.is_nemesis == true)
    assert(c.title == "of The Iron Covenant")
    assert(c.power >= 10 and c.power <= 95)
end)

test("build_rival warriors archetype has high power", function()
    local rival = { name = "Gorn", personality = { PER_BLD = 60 } }
    local faction = { name = "House War", archetype = "warriors", power = 70 }
    local c = Bridge.build_rival(rival, faction, nil)
    assert(c.power >= 55, "warriors should have high power, got " .. c.power)
end)

test("build_rival scholars archetype has high cunning", function()
    local rival = { name = "Syl", personality = { PER_ADA = 60 } }
    local faction = { name = "House Scholar", archetype = "scholars", power = 60 }
    local c = Bridge.build_rival(rival, faction, nil)
    assert(c.cunning >= 55, "scholars should have high cunning, got " .. c.cunning)
end)

test("build_rival handles nil inputs gracefully", function()
    local c = Bridge.build_rival(nil, nil, nil)
    assert(c.name == "Unknown Rival")
    assert(c.power >= 10)
end)

test("build_stakes creates valid stakes", function()
    local s = Bridge.build_stakes("blood", "border_stones", 42)
    assert(s.type == "blood")
    assert(s.terrain == "border_stones")
    assert(s.seed_offset == 42)
end)

test("build_from_event creates combatant from spec", function()
    local c = Bridge.build_from_event({
        name = "Bounty Hunter", power = 65, speed = 60,
        grit = 55, cunning = 50, personality_tag = "adaptive",
    })
    assert(c.name == "Bounty Hunter")
    assert(c.power == 65)
    assert(c.personality_tag == "adaptive")
end)

test("aftermath produces consequences for victory", function()
    local result = {
        outcome = { protag_won = true, margin = "dominant", ko = true, loser = "Rival" },
        injuries = { { id = "bruised", label = "Bruised", severity = 1 } },
    }
    local cons = Bridge.aftermath(result, "blood")
    assert(cons.lineage_power_shift > 0, "victory should grant LP")
    assert(cons.moral_act, "blood kill should produce moral act")
    assert(cons.moral_act.act_id == "combat_kill")
    assert(cons.cultural_memory_shift.physical and cons.cultural_memory_shift.physical > 0)
end)

test("aftermath produces consequences for defeat", function()
    local result = {
        outcome = { protag_won = false, margin = "dominant", ko = true, loser = "Hero" },
        injuries = { { id = "cracked_rib", label = "Cracked Rib", severity = 2 } },
    }
    local cons = Bridge.aftermath(result, "honor")
    assert(cons.lineage_power_shift < 0, "defeat should lose LP")
    assert(cons.moral_act == nil, "honor defeat should not produce moral act")
end)

test("aftermath trial produces verdict narration", function()
    local result = {
        outcome = { protag_won = true, margin = "narrow", ko = false },
        injuries = {},
    }
    local cons = Bridge.aftermath(result, "trial")
    assert(cons.narration, "trial should produce narration")
    assert(cons.narration:find("vindicated"), "trial win should mention vindication")
end)

test("full integration: build_heir → resolve → aftermath", function()
    local gs = {
        current_heir = mock_genome({ PHY_STR = 65 }),
        heir_personality = mock_personality({ PER_BLD = 60 }),
        heir_name = "Kael",
        lineage_name = "Ashborne",
        era = "Iron",
    }
    local wc = { world_state = { conditions = {} } }

    local protagonist = Bridge.build_heir(gs, wc)
    local rival = { name = "Drav", personality = { PER_BLD = 55, PER_CRM = 40 } }
    local faction = { name = "The Iron Covenant", archetype = "warriors", power = 55 }
    local opponent = Bridge.build_rival(rival, faction, wc)
    local stakes = Bridge.build_stakes("honor", "border_stones")

    local result = Combat.resolve(protagonist, opponent, 42, stakes)
    assert(#result.beats > 0, "should produce beats")
    assert(result.outcome.rounds > 0, "should fight rounds")

    local cons = Bridge.aftermath(result, "honor")
    assert(type(cons.lineage_power_shift) == "number")
    assert(type(cons.injuries) == "table")
end)

return pass, fail
