-- Dark Legacy — Epitaphs + Foreshadowing
-- Auto-generated one-liner per heir summarizing what they were to the lineage.
-- Foreshadowing: brief hooks about what's coming next.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Epitaphs = {}

-- Epitaph templates keyed by dominant personality axis direction
local personality_epitaphs = {
    PER_BLD_high = {
        "{name} charged into every storm, and the blood remembers the thunder.",
        "{name} feared nothing. The world learned to fear {name}.",
        "Where others hesitated, {name} moved. The bloodline carries that fire still.",
    },
    PER_BLD_low = {
        "{name} watched from the shadows, and the family survived because of it.",
        "Caution was {name}'s gift to the bloodline.",
        "{name} chose patience over glory. The lineage endured.",
    },
    PER_CRM_high = {
        "None were spared under {name}'s reign. The scars remain.",
        "{name} ruled without mercy. The world took note.",
        "The cruelty of {name} echoes through every generation since.",
    },
    PER_CRM_low = {
        "{name} healed what others would have destroyed.",
        "Mercy defined {name}, and the family was better for it.",
        "{name} showed kindness in an age that rewarded none.",
    },
    PER_OBS_high = {
        "{name} could not let go. The obsession consumed everything.",
        "What {name} wanted, {name} pursued to the end of all things.",
        "The fixation of {name} shaped the bloodline's destiny.",
    },
    PER_OBS_low = {
        "{name} drifted through life like smoke. Nothing held.",
        "{name} cared for nothing long enough to leave a mark.",
    },
    PER_LOY_high = {
        "{name} would have died for the blood. And nearly did.",
        "Loyalty was the only language {name} spoke.",
        "{name} held the family together when all else crumbled.",
    },
    PER_LOY_low = {
        "{name} served no one but {name}. The family remembers.",
        "Trust was a foreign word to {name}.",
    },
    PER_CUR_high = {
        "{name} asked questions no one else dared to ask.",
        "The curiosity of {name} opened doors the family never knew existed.",
        "{name} reached for the unknown and brought back wonders.",
    },
    PER_CUR_low = {
        "{name} stayed the course. Tradition above all.",
        "{name} never questioned. Never wavered. Never changed.",
    },
    PER_VOL_high = {
        "{name} burned bright and unpredictable. The family still feels the heat.",
        "No one could predict {name}. That was the danger, and the gift.",
        "{name} was a storm that refused to pass.",
    },
    PER_VOL_low = {
        "{name} was stone. Unmoved. Unshaken. Unreachable.",
        "The calm of {name} steadied the bloodline through chaos.",
    },
    PER_PRI_high = {
        "{name} demanded the world's respect, and refused to live without it.",
        "Pride was {name}'s armor and prison both.",
        "The vanity of {name} built monuments that still cast shadows.",
    },
    PER_PRI_low = {
        "{name} sought no glory. The family barely noticed.",
        "{name} lived humbly. History almost forgot.",
    },
    PER_ADA_high = {
        "{name} became whatever the world demanded. A survivor above all.",
        "{name} bent but never broke. The bloodline learned flexibility.",
    },
    PER_ADA_low = {
        "{name} held to doctrine with iron conviction. Change was the enemy.",
        "Rigid as iron, {name} would not bend. And so the world bent around {name}.",
    },
}

-- Event-based epitaph overrides
local event_epitaphs = {
    survived_plague = {
        "{name} endured what should have killed them. The plague could not claim this one.",
        "{name} walked through the plague and emerged scarred but breathing.",
    },
    survived_famine = {
        "{name} starved but did not fall. The bloodline owes its survival to that stubbornness.",
        "Hunger could not break {name}.",
    },
    survived_war = {
        "{name} walked through fire and came out the other side.",
        "War took everything from {name} except breath.",
    },
}

-- Death cause epitaphs
local death_epitaphs = {
    plague = {
        "{name} fell to the plague, as so many had before.",
        "The sickness that haunted the bloodline finally claimed {name}.",
    },
    killed_in_war = {
        "{name} fell on the field, sword still in hand.",
        "War took {name}, as it takes all who charge willingly.",
    },
    starvation = {
        "{name} wasted away. The land gave nothing.",
        "Hunger claimed {name} when the world had nothing left to offer.",
    },
    natural_frailty = {
        "{name} was born too fragile for this world.",
        "The body of {name} could not carry the weight of the bloodline.",
    },
    madness = {
        "{name} lost themselves. The mind shattered before the body followed.",
        "Madness took {name}, and the family could only watch.",
    },
}

-- Legend title epitaph additions
local legend_epitaphs = {
    "They called {name} \"{legend}\", and the name outlived the flesh.",
    "History remembers {name} as {legend}. The bloodline remembers the cost.",
    "{legend} — a title earned in blood and time.",
}

-- Fallback generic epitaphs
local generic_epitaphs = {
    "{name} lived. {name} died. The ledger records both.",
    "Another generation passed. {name} carried the weight.",
    "{name} added their chapter to the chronicle. It was enough.",
    "The blood remembers {name}, even if history does not.",
}

--- Substitute variables in a template string.
local function sub(template, vars)
    local result = template
    for k, v in pairs(vars) do
        result = result:gsub("{" .. k .. "}", tostring(v))
    end
    return result
end

--- Generate an epitaph for an heir.
---@param heir_genome table
---@param heir_personality table
---@param cultural_memory table
---@param events_faced table|nil { survived_plague, survived_famine, survived_war }
---@param legend_title string|nil
---@param heir_name string
---@param death_cause string|nil
---@return string epitaph
function Epitaphs.generate(heir_genome, heir_personality, cultural_memory, events_faced, legend_title, heir_name, death_cause)
    events_faced = events_faced or {}
    local vars = { name = heir_name or "the heir" }
    local pool = {}

    -- Priority 1: Death cause (if heir died)
    if death_cause and death_epitaphs[death_cause] then
        for _, t in ipairs(death_epitaphs[death_cause]) do
            pool[#pool + 1] = t
        end
    end

    -- Priority 2: Legend title reference
    if legend_title then
        vars.legend = legend_title
        for _, t in ipairs(legend_epitaphs) do
            pool[#pool + 1] = t
        end
    end

    -- Priority 3: Event-driven epitaphs
    if events_faced.survived_plague then
        for _, t in ipairs(event_epitaphs.survived_plague) do
            pool[#pool + 1] = t
        end
    end
    if events_faced.survived_famine then
        for _, t in ipairs(event_epitaphs.survived_famine) do
            pool[#pool + 1] = t
        end
    end
    if events_faced.survived_war then
        for _, t in ipairs(event_epitaphs.survived_war) do
            pool[#pool + 1] = t
        end
    end

    -- Priority 4: Dominant personality axis
    if heir_personality then
        local axes = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }
        local extreme_axis = nil
        local extreme_dist = 0
        for _, axis in ipairs(axes) do
            local val = heir_personality:get_axis(axis) or 50
            local dist = math.abs(val - 50)
            if dist > extreme_dist then
                extreme_dist = dist
                extreme_axis = axis
            end
        end

        if extreme_axis and extreme_dist >= 15 then
            local val = heir_personality:get_axis(extreme_axis) or 50
            local direction = val >= 50 and "high" or "low"
            local key = extreme_axis .. "_" .. direction
            if personality_epitaphs[key] then
                for _, t in ipairs(personality_epitaphs[key]) do
                    pool[#pool + 1] = t
                end
            end
        end
    end

    -- Fallback: generic
    if #pool == 0 then
        pool = generic_epitaphs
    end

    local template = pool[rng.range(1, #pool)]
    return sub(template, vars)
end

-- Foreshadowing templates
local foreshadow_templates = {
    plague_worsening = "The plague shows no sign of relenting...",
    famine_worsening = "The harvests grow thinner each generation...",
    war_continues = "The drums of war still echo across the land.",
    low_vitality = "Your heir's frail constitution worries the court.",
    low_fertility = "The bloodline struggles to produce heirs.",
    hostile_faction = "A rival house sharpens its blades in the shadows.",
    declining_strength = "The bloodline weakens. Three generations of decline.",
    declining_intellect = "The family's minds grow duller with each generation.",
    blind_spot_danger = "What the family cannot see may be its undoing.",
    high_mutation = "Something stirs in the blood. The mutations accelerate.",
    taboo_pressure = "Ancient wounds weigh heavy on the family's choices.",
    rising_power = "The dynasty's influence grows. Others take notice.",
}

--- Generate foreshadowing lines (1-2 max).
---@param world_state table
---@param cultural_memory table
---@param next_heir_genome table
---@param extra table|nil { trait_trends, mutation_pressure }
---@return table array of strings
function Epitaphs.foreshadow(world_state, cultural_memory, next_heir_genome, extra)
    extra = extra or {}
    local lines = {}

    if not world_state or not next_heir_genome then return lines end

    -- Check conditions
    local conditions = world_state.conditions or {}
    for _, cond in ipairs(conditions) do
        if cond.type == "plague" and (cond.remaining_gens or 0) >= 2 then
            lines[#lines + 1] = foreshadow_templates.plague_worsening
        elseif cond.type == "famine" and (cond.remaining_gens or 0) >= 2 then
            lines[#lines + 1] = foreshadow_templates.famine_worsening
        elseif cond.type == "war" and (cond.remaining_gens or 0) >= 2 then
            lines[#lines + 1] = foreshadow_templates.war_continues
        end
    end

    -- Check dangerously low traits in next heir
    local vitality = next_heir_genome:get_value("PHY_VIT") or 50
    if vitality < 25 then
        lines[#lines + 1] = foreshadow_templates.low_vitality
    end

    local fertility = next_heir_genome:get_value("PHY_FER") or 50
    if fertility < 20 then
        lines[#lines + 1] = foreshadow_templates.low_fertility
    end

    -- Check for hostile factions (via cultural memory relationships)
    if cultural_memory and cultural_memory.relationships then
        for _, rel in ipairs(cultural_memory.relationships) do
            if rel.type == "enemy" and (rel.strength or 0) >= 60 then
                lines[#lines + 1] = foreshadow_templates.hostile_faction
                break
            end
        end
    end

    -- Check blind spots
    if cultural_memory then
        local blind_spots = cultural_memory:get_blind_spots()
        if blind_spots and #blind_spots > 0 then
            lines[#lines + 1] = foreshadow_templates.blind_spot_danger
        end
    end

    -- Check trait trends (declining vitality over generations)
    if extra.trait_trends then
        if extra.trait_trends.declining_vitality then
            lines[#lines + 1] = foreshadow_templates.declining_strength
        end
        if extra.trait_trends.declining_intellect then
            lines[#lines + 1] = foreshadow_templates.declining_intellect
        end
    end

    -- Check mutation pressure
    if extra.mutation_pressure and extra.mutation_pressure > 60 then
        lines[#lines + 1] = foreshadow_templates.high_mutation
    end

    -- Check taboo pressure
    if cultural_memory and cultural_memory.taboos and #cultural_memory.taboos >= 3 then
        lines[#lines + 1] = foreshadow_templates.taboo_pressure
    end

    -- Check rising power (no hostile conditions + strong reputation + high priority)
    if #lines == 0 and cultural_memory then
        local no_hostile_conditions = true
        local conditions = world_state.conditions or {}
        for _, cond in ipairs(conditions) do
            if cond.type == "plague" or cond.type == "famine" or cond.type == "war" then
                no_hostile_conditions = false
                break
            end
        end
        if no_hostile_conditions and cultural_memory.trait_priorities then
            local prefix_to_cat = { PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" }
            local cat_sums, cat_counts = {}, {}
            for id, priority in pairs(cultural_memory.trait_priorities) do
                local prefix = id:sub(1, 3)
                local cat = prefix_to_cat[prefix]
                if cat then
                    cat_sums[cat] = (cat_sums[cat] or 0) + priority
                    cat_counts[cat] = (cat_counts[cat] or 0) + 1
                end
            end
            local best_cat, best_avg = nil, 0
            for cat, sum in pairs(cat_sums) do
                local avg = sum / (cat_counts[cat] or 1)
                if avg > best_avg then
                    best_avg = avg
                    best_cat = cat
                end
            end
            if best_avg > 65 then
                lines[#lines + 1] = foreshadow_templates.rising_power
            end
        end
    end

    -- Cap at 2 lines max
    if #lines > 2 then
        -- Pick the first 2 (most urgent)
        lines = { lines[1], lines[2] }
    end

    return lines
end

return Epitaphs
