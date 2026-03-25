local Math = require("dredwork_core.math")
local ShadowBody = {}


local function current_setup(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function current_age(game_state)
    local setup = current_setup(game_state)
    if not setup then
        return 20
    end
    return (setup.start_age or 20) + math.max(0, (game_state.generation or 1) - 1)
end

local function title_case_words(text)
    local lower = tostring(text or ""):lower()
    return (lower:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest
    end))
end

local function label_from_id(id)
    return title_case_words(tostring(id or "unknown"):gsub("_", " "))
end

local function sorted_entries(pool)
    local entries = {}
    for id, entry in pairs(pool or {}) do
        entries[#entries + 1] = {
            id = id,
            label = entry.label or label_from_id(id),
            severity = entry.severity or 0,
        }
    end
    table.sort(entries, function(a, b)
        if a.severity == b.severity then
            return a.label < b.label
        end
        return a.severity > b.severity
    end)
    return entries
end

local function total_load(pool)
    local total = 0
    for _, entry in pairs(pool or {}) do
        total = total + (entry.severity or 0)
    end
    return total
end

local function adjust_entry(pool, item, multiplier)
    if not pool or not item then
        return
    end
    local id = item.id or tostring(item.label or "unknown"):lower():gsub("[^%w]+", "_")
    local label = item.label or label_from_id(id)
    local delta = math.floor((item.severity or 0) * (multiplier or 1))
    if delta == 0 then
        return
    end
    local entry = pool[id] or { label = label, severity = 0 }
    entry.label = label
    entry.severity = Math.clamp((entry.severity or 0) + delta, 0, 100)
    if entry.severity <= 0 then
        pool[id] = nil
    else
        pool[id] = entry
    end
end

local function relieve_pool(pool, amount, preferred_id)
    local remaining = math.max(0, amount or 0)
    if remaining <= 0 or not pool then
        return
    end

    if preferred_id and pool[preferred_id] then
        local entry = pool[preferred_id]
        local used = math.min(remaining, entry.severity or 0)
        entry.severity = (entry.severity or 0) - used
        remaining = remaining - used
        if entry.severity <= 0 then
            pool[preferred_id] = nil
        end
    end

    for _, entry in ipairs(sorted_entries(pool)) do
        if remaining <= 0 then
            break
        end
        local target = pool[entry.id]
        if target then
            local used = math.min(remaining, target.severity or 0)
            target.severity = (target.severity or 0) - used
            remaining = remaining - used
            if target.severity <= 0 then
                pool[entry.id] = nil
            end
        end
    end
end

local function load_label(kind, load)
    local value = tonumber(load) or 0
    if kind == "wounds" then
        if value >= 60 then return "Ravaged" end
        if value >= 34 then return "Marked" end
        if value >= 14 then return "Bruised" end
        return "Clear"
    elseif kind == "illnesses" then
        if value >= 58 then return "Failing" end
        if value >= 30 then return "Ailing" end
        if value >= 12 then return "Low Fever" end
        return "Clear"
    elseif kind == "compulsions" then
        if value >= 64 then return "Owned" end
        if value >= 36 then return "Driven" end
        if value >= 16 then return "Hooked" end
        return "Quiet"
    end
    return tostring(value)
end

local function lead_line(entries, empty_label)
    if #entries == 0 then
        return empty_label
    end
    local parts = {}
    for index = 1, math.min(2, #entries) do
        local entry = entries[index]
        parts[#parts + 1] = entry.label .. " " .. tostring(entry.severity)
    end
    return table.concat(parts, " | ")
end

local function ensure_shadow_state(game_state)
    game_state.shadow_state = game_state.shadow_state or {}
    return game_state.shadow_state
end

function ShadowBody.ensure_state(game_state)
    game_state.shadow_body = game_state.shadow_body or {}
    local state = game_state.shadow_body
    if state.initialized then
        return state
    end

    state.wounds = state.wounds or {}
    state.illnesses = state.illnesses or {}
    state.compulsions = state.compulsions or {}
    state.scars = state.scars or {}
    state.relapse_risks = state.relapse_risks or {}
    state.convalescing = false

    local setup = current_setup(game_state) or {}
    if setup.burden == "scar" then
        adjust_entry(state.wounds, { id = "old_scar", label = "Old Scar", severity = 24 }, 1)
    elseif setup.burden == "parent" then
        adjust_entry(state.illnesses, { id = "sleeplessness", label = "Sleeplessness", severity = 12 }, 1)
    end

    if setup.vice == "drink" then
        adjust_entry(state.compulsions, { id = "drink_hunger", label = "Bottle Hunger", severity = 22 }, 1)
    elseif setup.vice == "gaming" then
        adjust_entry(state.compulsions, { id = "gaming_hunger", label = "Gaming Hunger", severity = 18 }, 1)
    elseif setup.vice == "obsession" then
        adjust_entry(state.compulsions, { id = "obsessive_fixation", label = "Obsessive Fixation", severity = 24 }, 1)
    elseif setup.vice == "fervor" then
        adjust_entry(state.compulsions, { id = "ecstatic_fervor", label = "Ecstatic Fervor", severity = 18 }, 1)
    end

    if setup.occupation == "soldier" then
        adjust_entry(state.wounds, { id = "campaign_knots", label = "Campaign Knots", severity = 10 }, 1)
    elseif setup.occupation == "laborer" then
        adjust_entry(state.wounds, { id = "overworked_back", label = "Overworked Back", severity = 8 }, 1)
    end

    state.initialized = true
    return state
end

function ShadowBody.apply(game_state, payload)
    if not game_state or not payload then
        return ShadowBody.snapshot(game_state)
    end
    local state = ShadowBody.ensure_state(game_state)
    local singular = {
        wound = "wounds",
        illness = "illnesses",
        compulsion = "compulsions",
    }
    local plural = {
        wounds = "wounds",
        illnesses = "illnesses",
        compulsions = "compulsions",
    }

    for key, bucket in pairs(singular) do
        if payload[key] then
            adjust_entry(state[bucket], payload[key], 1)
        end
    end
    for key, bucket in pairs(plural) do
        for _, item in ipairs(payload[key] or {}) do
            adjust_entry(state[bucket], item, 1)
        end
    end

    relieve_pool(state.wounds, payload.ease_wounds or 0, payload.preferred_wound)
    relieve_pool(state.illnesses, payload.ease_illnesses or payload.ease_illness or 0, payload.preferred_illness)

    -- Track relapse risk before relieving compulsions
    for id, entry in pairs(state.compulsions) do
        if (entry.severity or 0) >= 40 then
            state.relapse_risks = state.relapse_risks or {}
            state.relapse_risks[id] = { label = entry.label, peak = math.max(entry.severity, (state.relapse_risks[id] and state.relapse_risks[id].peak) or 0) }
        end
    end
    relieve_pool(state.compulsions, payload.ease_compulsions or payload.ease_compulsion or 0, payload.preferred_compulsion)

    -- Scar formation: wounds above 50 severity leave permanent marks
    state.scars = state.scars or {}
    for id, entry in pairs(state.wounds) do
        if (entry.severity or 0) >= 50 and not state.scars[id] then
            state.scars[id] = {
                label = (entry.label or label_from_id(id)) .. " (Scarred)",
                severity = math.floor(entry.severity * 0.3),
                origin_severity = entry.severity,
            }
        end
    end

    return ShadowBody.snapshot(game_state)
end

function ShadowBody.snapshot(game_state)
    if not game_state then
        return {
            wounds = {},
            illnesses = {},
            compulsions = {},
            wound_load = 0,
            illness_load = 0,
            compulsion_load = 0,
            wound_label = "Clear",
            illness_label = "Clear",
            compulsion_label = "Quiet",
            primary_wounds = "No lasting wounds.",
            primary_illnesses = "No active illness.",
            primary_compulsions = "No ruling habit.",
            body_line = "Wounds Clear | Illness Clear | Habit Quiet",
            scars = {},
            scar_load = 0,
            convalescing = false,
            relapse_risks = {},
        }
    end

    local state = ShadowBody.ensure_state(game_state)
    local wounds = sorted_entries(state.wounds)
    local illnesses = sorted_entries(state.illnesses)
    local compulsions = sorted_entries(state.compulsions)
    local wound_load = total_load(state.wounds)
    local illness_load = total_load(state.illnesses)
    local compulsion_load = total_load(state.compulsions)

    local scars = sorted_entries(state.scars or {})
    local scar_load = total_load(state.scars or {})
    local combined_wound_load = wound_load + scar_load

    local relapse_list = {}
    for id, risk in pairs(state.relapse_risks or {}) do
        local still_active = state.compulsions[id] and (state.compulsions[id].severity or 0) > 0
        if not still_active then
            relapse_list[#relapse_list + 1] = { id = id, label = risk.label, peak = risk.peak }
        end
    end

    local convalescing = (combined_wound_load + illness_load) >= 60

    return {
        wounds = wounds,
        illnesses = illnesses,
        compulsions = compulsions,
        wound_load = wound_load,
        illness_load = illness_load,
        compulsion_load = compulsion_load,
        wound_label = load_label("wounds", combined_wound_load),
        illness_label = load_label("illnesses", illness_load),
        compulsion_label = load_label("compulsions", compulsion_load),
        primary_wounds = lead_line(wounds, "No lasting wounds."),
        primary_illnesses = lead_line(illnesses, "No active illness."),
        primary_compulsions = lead_line(compulsions, "No ruling habit."),
        body_line = "Wounds " .. load_label("wounds", combined_wound_load)
            .. " | Illness " .. load_label("illnesses", illness_load)
            .. " | Habit " .. load_label("compulsions", compulsion_load),
        scars = scars,
        scar_load = scar_load,
        convalescing = convalescing,
        relapse_risks = relapse_list,
    }
end

local WHISPER_TABLE = {
    { kind = "wounds", threshold = 50, text = "The old wound speaks louder than the body's owner." },
    { kind = "wounds", threshold = 34, text = "Flesh remembers what pride tries to forget." },
    { kind = "wounds", threshold = 20, text = "A bruise with ambition lingers past its welcome." },
    { kind = "illnesses", threshold = 46, text = "Fever takes up residence and begins redecorating." },
    { kind = "illnesses", threshold = 28, text = "The sickness has learned patience." },
    { kind = "illnesses", threshold = 14, text = "Something low hums beneath the ribs." },
    { kind = "compulsions", threshold = 56, text = "The habit has its own schedule now." },
    { kind = "compulsions", threshold = 38, text = "Appetite sends notes that read like scripture." },
    { kind = "compulsions", threshold = 20, text = "A craving stirs behind a polite face." },
    { kind = "scars", threshold = 30, text = "Old scars itch when the weather changes inside." },
    { kind = "scars", threshold = 15, text = "Scar tissue keeps its own counsel." },
    { kind = "age", threshold = 55, text = "The body has begun writing its resignation letter." },
    { kind = "age", threshold = 45, text = "Mornings arrive later than they used to." },
    { kind = "age", threshold = 35, text = "Youth left without forwarding its address." },
    { kind = "combined", threshold = 80, text = "The body is a city under siege from its own geography." },
}

function ShadowBody.generate_whispers(game_state)
    if not game_state then return {} end
    local state = ShadowBody.ensure_state(game_state)
    local age = current_age(game_state)
    local wound_load = total_load(state.wounds)
    local illness_load = total_load(state.illnesses)
    local compulsion_load = total_load(state.compulsions)
    local scar_load = total_load(state.scars or {})
    local combined = wound_load + illness_load + compulsion_load + scar_load

    local loads = {
        wounds = wound_load,
        illnesses = illness_load,
        compulsions = compulsion_load,
        scars = scar_load,
        age = age,
        combined = combined,
    }

    local whispers = {}
    for _, entry in ipairs(WHISPER_TABLE) do
        local value = loads[entry.kind] or 0
        if value >= entry.threshold then
            whispers[#whispers + 1] = entry.text
        end
        if #whispers >= 3 then break end
    end

    state.whispers = state.whispers or {}
    for _, w in ipairs(whispers) do
        state.whispers[#state.whispers + 1] = w
        while #state.whispers > 8 do
            table.remove(state.whispers, 1)
        end
    end

    return whispers
end

function ShadowBody.get_whispers(game_state)
    if not game_state or not game_state.shadow_body then return {} end
    return game_state.shadow_body.whispers or {}
end

function ShadowBody.tick_year(game_state)
    if not game_state then
        return {}
    end

    local body = ShadowBody.ensure_state(game_state)
    local shadow = ensure_shadow_state(game_state)
    local setup = current_setup(game_state) or {}
    local age = current_age(game_state)
    local health = shadow.health or 50
    local stress = shadow.stress or 50

    local wound_relief = 2 + (health >= 62 and 1 or 0) - (age >= 45 and 1 or 0)
    local illness_relief = 2 + (health >= 58 and stress <= 58 and 1 or 0)
    local compulsion_relief = stress <= 42 and 2 or 0

    if setup.burden == "scar" then
        adjust_entry(body.wounds, { id = "old_scar", label = "Old Scar", severity = health <= 46 and 3 or 1 }, 1)
    end
    if setup.vice == "drink" then
        adjust_entry(body.compulsions, { id = "drink_hunger", label = "Bottle Hunger", severity = stress >= 58 and 4 or 2 }, 1)
    elseif setup.vice == "gaming" then
        adjust_entry(body.compulsions, { id = "gaming_hunger", label = "Gaming Hunger", severity = stress >= 60 and 4 or 2 }, 1)
    elseif setup.vice == "obsession" then
        adjust_entry(body.compulsions, { id = "obsessive_fixation", label = "Obsessive Fixation", severity = ((shadow.craft or 50) >= 58 or stress >= 56) and 4 or 2 }, 1)
    elseif setup.vice == "fervor" then
        adjust_entry(body.compulsions, { id = "ecstatic_fervor", label = "Ecstatic Fervor", severity = ((shadow.notoriety or 0) >= 54 or stress >= 50) and 3 or 2 }, 1)
    end

    if health <= 34 then
        adjust_entry(body.illnesses, { id = "wasting_fever", label = "Wasting Fever", severity = 4 }, 1)
    elseif stress >= 74 then
        adjust_entry(body.illnesses, { id = "sleeplessness", label = "Sleeplessness", severity = 3 }, 1)
    end

    -- Aging pressure: older bodies heal slower, wounds fester
    local aging_penalty = 0
    if age >= 55 then
        aging_penalty = 2
    elseif age >= 40 then
        aging_penalty = 1
    end
    wound_relief = math.max(0, wound_relief - aging_penalty)
    illness_relief = math.max(0, illness_relief - math.floor(aging_penalty * 0.5))

    relieve_pool(body.wounds, math.max(0, wound_relief), setup.burden == "scar" and "old_scar" or nil)
    relieve_pool(body.illnesses, math.max(0, illness_relief))
    relieve_pool(body.compulsions, math.max(0, compulsion_relief))

    -- Scar worsening: old scars grow slowly with age
    body.scars = body.scars or {}
    for id, scar in pairs(body.scars) do
        if age >= 40 then
            scar.severity = Math.clamp((scar.severity or 0) + 1, 0, 50)
        end
    end

    -- Scar formation from severe wounds that persist
    for id, entry in pairs(body.wounds) do
        if (entry.severity or 0) >= 50 and not body.scars[id] then
            body.scars[id] = {
                label = (entry.label or label_from_id(id)) .. " (Scarred)",
                severity = math.floor(entry.severity * 0.3),
                origin_severity = entry.severity,
            }
        end
    end

    -- Relapse: suppressed compulsions can return under stress
    body.relapse_risks = body.relapse_risks or {}
    for id, risk in pairs(body.relapse_risks) do
        local still_active = body.compulsions[id] and (body.compulsions[id].severity or 0) > 0
        if not still_active and stress >= 62 then
            local relapse_severity = math.floor((risk.peak or 20) * 0.25)
            if relapse_severity >= 4 then
                adjust_entry(body.compulsions, { id = id, label = risk.label, severity = relapse_severity }, 1)
            end
        end
    end

    -- Convalescence flag
    body.convalescing = (total_load(body.wounds) + total_load(body.scars or {}) + total_load(body.illnesses)) >= 60

    local snapshot = ShadowBody.snapshot(game_state)
    local wound_drag = math.floor((snapshot.wound_load + snapshot.scar_load) / 34)
    local illness_drag = math.floor(snapshot.illness_load / 28)
    local compulsion_drag = math.floor(snapshot.compulsion_load / 36)

    shadow.health = Math.clamp((shadow.health or 50) - wound_drag - illness_drag, 0, 100)
    shadow.stress = Math.clamp((shadow.stress or 50) + illness_drag + compulsion_drag, 0, 100)
    shadow.bonds = Math.clamp((shadow.bonds or 50) - math.floor(snapshot.compulsion_load / 60), 0, 100)
    shadow.standing = Math.clamp((shadow.standing or 50) - math.floor((snapshot.illness_load + snapshot.compulsion_load) / 90), 0, 100)
    shadow.craft = Math.clamp((shadow.craft or 50) - math.floor(snapshot.wound_load / 80), 0, 100)

    snapshot = ShadowBody.snapshot(game_state)
    local lines = {
        "Wounds " .. snapshot.wound_label .. " | Illness " .. snapshot.illness_label .. " | Habit " .. snapshot.compulsion_label .. ".",
        "Body marks: " .. snapshot.primary_wounds,
        "Illness and habit: " .. snapshot.primary_illnesses .. " | " .. snapshot.primary_compulsions,
    }
    if #snapshot.scars > 0 then
        lines[#lines + 1] = "Old scars: " .. lead_line(snapshot.scars, "None") .. "."
    end
    if snapshot.convalescing then
        lines[#lines + 1] = "The body is convalescing. Actions this year will be harder."
    end
    if #snapshot.relapse_risks > 0 then
        lines[#lines + 1] = "Relapse risk: " .. snapshot.relapse_risks[1].label .. "."
    end

    local whispers = ShadowBody.generate_whispers(game_state)
    for _, w in ipairs(whispers) do
        lines[#lines + 1] = w
    end

    return lines, whispers
end

return ShadowBody
