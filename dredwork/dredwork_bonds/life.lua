local Math = require("dredwork_core.math")
local Wealth = require("dredwork_world.wealth")
local Morality = require("dredwork_world.morality")
local LineagePower = require("dredwork_world.lineage_power")
local ShadowBody = require("dredwork_bonds.body")
local ShadowClaim = require("dredwork_bonds.claim")

local ShadowLife = {}

local OCCUPATION_EFFECTS = {
    laborer = { resources = { grain = 4, steel = 1 }, wealth = -3, morality = 2, power = 1, reputation = { "warriors", "artisans" } },
    scribe = { resources = { lore = 5, gold = 1 }, wealth = 2, morality = 1, power = 1, reputation = { "scholars", "diplomats" } },
    soldier = { resources = { steel = 4, grain = 1 }, wealth = 0, morality = -2, power = 4, reputation = { "warriors", "diplomats" }, condition = { type = "war_weariness", intensity = 0.3, duration = 2 } },
    courtier = { resources = { gold = 6, lore = 2 }, wealth = 6, morality = -1, power = 3, reputation = { "diplomats", "artisans" }, condition = { type = "prosperity", intensity = 0.3, duration = 2 } },
    tinker = { resources = { lore = 4, steel = 2 }, wealth = 1, morality = 0, power = 1, reputation = { "artisans", "scholars" } },
    performer = { resources = { gold = 3, lore = 2 }, wealth = 2, morality = 0, power = 2, reputation = { "artisans", "diplomats" } },
}

local BURDEN_EFFECTS = {
    debt = { resources = { gold = -8 }, wealth = -10, morality = -2, power = -1, note = "Creditors already own part of the future." },
    oath = { resources = { steel = 1 }, wealth = 0, morality = 6, power = 2, note = "An oath narrows every easy road." },
    scar = { resources = { grain = -2 }, wealth = -1, morality = 0, power = 1, note = "Pain is already part of the daily arithmetic." },
    claim = { resources = { gold = -2, lore = 2 }, wealth = 1, morality = -1, power = 3, note = "A denied claim keeps ambition awake." },
    wanted = { resources = { gold = -4 }, wealth = -5, morality = -4, power = 2, condition = { type = "exodus", intensity = 0.4, duration = 2 }, note = "Flight and caution define the opening years." },
    parent = { resources = { grain = -3 }, wealth = -4, morality = 5, power = -1, note = "Duty is waiting at home before the first choice." },
}

local VICE_EFFECTS = {
    none = { morality = 2, power = 0 },
    drink = { resources = { grain = -1, gold = -3 }, wealth = -4, morality = -3, power = -1 },
    gaming = { resources = { gold = -5 }, wealth = -6, morality = -2, power = 0 },
    fervor = { resources = { lore = 1 }, wealth = 0, morality = -1, power = 1 },
    obsession = { resources = { lore = 2, grain = -1 }, wealth = -1, morality = -1, power = 1 },
    debt = { resources = { gold = -4 }, wealth = -5, morality = -2, power = -1 },
}

local FAITH_EFFECTS = {
    state = { resources = { gold = 2 }, wealth = 1, morality = 2, power = 1 },
    old = { resources = { lore = 2 }, wealth = 0, morality = 1, power = 1 },
    skeptic = { resources = { lore = 1 }, wealth = 0, morality = 0, power = 0 },
    cult = { resources = { gold = -1, lore = 2 }, wealth = -1, morality = -2, power = 2 },
    ancestor = { resources = { lore = 1 }, wealth = 0, morality = 2, power = 1 },
}

local HOUSEHOLD_EFFECTS = {
    devout = { resources = { lore = 1 }, wealth = 0, morality = 2, power = 0 },
    debtor = { resources = { gold = -3 }, wealth = -4, morality = -1, power = 0 },
    martial = { resources = { steel = 1, grain = 1 }, wealth = 0, morality = 0, power = 1 },
    scholarly = { resources = { lore = 3 }, wealth = 1, morality = 1, power = 0 },
    fractured = { resources = { grain = -1 }, wealth = -2, morality = -1, power = 0 },
    wandering = { resources = { grain = -1, steel = 1 }, wealth = -1, morality = 0, power = 0 },
}

local BIRTHPLACE_EFFECTS = {
    holdfast = { resources = { steel = 2, grain = 1 }, wealth = 0, power = 1 },
    market = { resources = { gold = 3 }, wealth = 3, power = 0 },
    abbey = { resources = { lore = 3 }, wealth = 0, power = 0 },
    frontier = { resources = { grain = 2, steel = 1 }, wealth = -1, power = 1 },
    ruin = { resources = { lore = 2, gold = 1 }, wealth = 0, power = 0 },
}


local function current_setup(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function apply_resource_changes(resources, changes, heir_name, generation)
    if not resources then
        return
    end
    for key, value in pairs(changes or {}) do
        if value ~= 0 then
            resources:change(key, value, "shadow_setup", heir_name, generation)
        end
    end
end

local function apply_condition(world_state, payload)
    if not world_state or not payload or not payload.type then
        return
    end
    world_state:add_condition(payload.type, payload.intensity or 0.3, payload.duration or 2)
end

local function apply_reputation(memory, reputation)
    if not memory or not memory.reputation or not reputation then
        return
    end
    memory.reputation.primary = reputation[1] or memory.reputation.primary
    memory.reputation.secondary = reputation[2] or memory.reputation.secondary
end

local function ensure_value_states(game_state)
    if not game_state.wealth then
        game_state.wealth = Wealth.new(50)
    end
    if not game_state.morality then
        game_state.morality = Morality.new(0)
    end
    if not game_state.lineage_power then
        game_state.lineage_power = LineagePower.new()
    end
end

function ShadowLife.current_age(game_state)
    local setup = current_setup(game_state)
    if not setup or not setup.start_age then
        return nil
    end
    return (setup.start_age or 0) + math.max(0, (game_state.generation or 1) - 1)
end

function ShadowLife.profile(game_state)
    local setup = current_setup(game_state)
    if not setup then
        return nil
    end
    local shadow_state = game_state and game_state.shadow_state or {}
    local shadow_body = game_state and game_state.shadow_setup and ShadowBody.snapshot(game_state) or nil
    local shadow_claim = game_state and game_state.shadow_setup and ShadowClaim.snapshot(game_state) or nil

    return {
        age = ShadowLife.current_age(game_state),
        birthplace = setup.birthplace_label or "Unknown",
        household = setup.household_label or "Unknown",
        education = setup.education_label or "Unknown",
        occupation = setup.calling_label or setup.occupation_label or "Unknown",
        vice = setup.vice_label or "Unknown",
        faith = setup.faith_label or "Unknown",
        burden = setup.burden_label or "Unknown",
        creed = setup.creed or "",
        role_line = "Exiled Branch | " .. (setup.calling_label or setup.occupation_label or "Unknown"),
        pressure_line = (setup.burden_label or "Unknown") .. " | " .. (setup.vice_label or "Unknown"),
        claim_house = shadow_claim and shadow_claim.house_name or (setup.claim_house_name or "Unnamed House"),
        claim_line = shadow_claim and shadow_claim.reclaim_line or ("Shadow of " .. (setup.claim_house_name or "Unnamed House")),
        claim_state_line = shadow_claim and shadow_claim.state_line or "Legitimacy Denied | Proof Lost | Exposure Hidden",
        usurper_line = shadow_claim and shadow_claim.danger_line or "Grievance Persistent | Ambition Cautious | Usurper Risk Contained",
        state_line = "Health " .. tostring(shadow_state.health or 0)
            .. " | Stress " .. tostring(shadow_state.stress or 0)
            .. " | Bonds " .. tostring(shadow_state.bonds or 0),
        body_line = shadow_body and shadow_body.body_line or "Wounds Clear | Illness Clear | Habit Quiet",
    }
end

function ShadowLife.opening_notice(game_state)
    local profile = ShadowLife.profile(game_state)
    if not profile then
        return nil
    end
    return (game_state.heir_name or "Unknown") .. " entered the record as the child of an exiled branch, marked by " .. string.lower(profile.burden) .. ", and already leaning toward " .. string.lower(profile.occupation) .. "."
end

function ShadowLife.apply_starting_state(game_state, world)
    local setup = current_setup(game_state)
    if not setup then
        return
    end

    ensure_value_states(game_state)

    local effects = {
        BIRTHPLACE_EFFECTS[setup.birthplace],
        HOUSEHOLD_EFFECTS[setup.household],
        OCCUPATION_EFFECTS[setup.occupation],
        VICE_EFFECTS[setup.vice],
        FAITH_EFFECTS[setup.faith],
        BURDEN_EFFECTS[setup.burden],
    }

    local total_wealth = 0
    local total_morality = 0
    local total_power = 0
    local opening_notes = {}

    for _, effect in ipairs(effects) do
        if effect then
            apply_resource_changes(world and world.resources, effect.resources, game_state.heir_name, game_state.generation)
            total_wealth = total_wealth + (effect.wealth or 0)
            total_morality = total_morality + (effect.morality or 0)
            total_power = total_power + (effect.power or 0)
            apply_condition(world and world.world_state, effect.condition)
            apply_reputation(game_state.cultural_memory, effect.reputation)
            if effect.note then
                opening_notes[#opening_notes + 1] = effect.note
            end
        end
    end

    game_state.wealth.value = Math.clamp((game_state.wealth.value or 50) + total_wealth, 0, 100)
    game_state.morality.score = Math.clamp((game_state.morality.score or 0) + total_morality, -100, 100)
    game_state.lineage_power.value = Math.clamp((game_state.lineage_power.value or 45) + total_power, 0, 100)
    game_state.shadow_opening_notes = opening_notes
    ShadowClaim.ensure_state(game_state)

    if world and world.world_state and world.world_state.chronicle then
        local profile = ShadowLife.profile(game_state)
        world.world_state.chronicle[#world.world_state.chronicle + 1] = {
            text = (game_state.heir_name or "Unknown") .. " came of age in " .. (profile and profile.birthplace or "an uncertain place") .. ", born from the cast-off blood of " .. (profile and profile.claim_house or "an unnamed house") .. ", and entered the record beneath " .. string.lower(profile and profile.burden or "an unnamed burden") .. "."
        }
        while #world.world_state.chronicle > 20 do
            table.remove(world.world_state.chronicle, 1)
        end
    end
end

return ShadowLife
