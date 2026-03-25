local Math = require("dredwork_core.math")
-- Dark Legacy — The Crucible (Autonomous Gauntlet System)
-- Every few generations, a crisis strikes that the heir must face without player input.
-- Personality drives path selection, traits determine success.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Crucible = {}

-- Minimum generation before first crucible can fire
local MIN_GENERATION = 5

-- Generational gap range (randomized per check)
local GAP_MIN = 12
local GAP_MAX = 15

-- Mutation pressure threshold for trigger
local PRESSURE_THRESHOLD = 80

-- Death chance parameters on defeat
local BASE_DEATH_CHANCE = 0.15
local DEATH_CHANCE_PER_ZERO = 0.05
local MAX_DEATH_CHANCE = 0.50

-- Outcome thresholds
local TRIUMPH_THRESHOLD = 0.75
local SURVIVAL_THRESHOLD = 0.35

--- Load trial definitions.
---@return table array of trial definitions
local function get_trials()
    return require("dredwork_world.config.crucible_trials")
end

--- Check if a crucible should trigger this generation.
---@param context table { generation, world_state, mutation_pressure, last_crucible_gen }
---@return boolean
function Crucible.should_trigger(context)
    local gen = context.generation or 0
    if gen < MIN_GENERATION then return false end

    local last = context.last_crucible_gen
    if not last and context.world_state then
        last = context.world_state.last_crucible_gen or 0
    end
    last = last or 0

    -- 1. Era transition (check if generations_in_era == 0 meaning just transitioned)
    if context.world_state and context.world_state.generations_in_era == 0 then
        return true
    end

    -- 2. Extreme mutation pressure
    local pressure = 0
    if context.mutation_pressure then
        pressure = context.mutation_pressure.value or 0
    end
    if pressure >= PRESSURE_THRESHOLD then
        return true
    end

    -- 3. Triple condition (3+ active conditions)
    if context.world_state and context.world_state.conditions then
        local active_count = 0
        for _, cond in ipairs(context.world_state.conditions) do
            if cond.remaining_gens and cond.remaining_gens > 0 then
                active_count = active_count + 1
            end
        end
        if active_count >= 3 then
            return true
        end
    end

    -- 4. Generational gap (randomized threshold)
    local gap = gen - last
    local threshold = rng.range(GAP_MIN, GAP_MAX)
    if gap >= threshold then
        return true
    end

    return false
end

--- Select a trial appropriate for current conditions.
--- Trials with matching affinity (conditions/eras) are weighted higher.
---@param context table { generation, world_state, mutation_pressure }
---@return table trial definition
function Crucible.select_trial(context)
    local trials = get_trials()

    -- Score each trial by affinity match
    local scored = {}
    local active_conditions = {}
    local current_era = "ancient"

    if context.world_state then
        current_era = context.world_state.current_era_key or "ancient"
        if context.world_state.conditions then
            for _, cond in ipairs(context.world_state.conditions) do
                if cond.remaining_gens and cond.remaining_gens > 0 then
                    active_conditions[cond.type] = true
                end
            end
        end
    end

    for _, trial in ipairs(trials) do
        -- Exclude the apotheosis trial from normal selection — it's only triggered
        -- by the "Begin the Ascension" council action (via _pending_apotheosis)
        if trial.id ~= "the_ascension" then

        local score = 1  -- base score
        if trial.affinity then
            -- Condition match
            if trial.affinity.conditions then
                for _, cond in ipairs(trial.affinity.conditions) do
                    if active_conditions[cond] then
                        score = score + 3
                    end
                end
            end
            -- Era match
            if trial.affinity.eras then
                for _, era in ipairs(trial.affinity.eras) do
                    if era == current_era then
                        score = score + 2
                        break
                    end
                end
            end
        end
        -- Living world affinity bonuses
        if context.bloodline_dream and trial.theme then
            -- Dream alignment: if family dreams of "mental" and trial is scholarly, boost it
            local dream_cat = context.bloodline_dream.category
            if dream_cat then
                local theme_cat_map = {
                    combat = "physical", survival = "physical",
                    diplomatic = "social", political = "social",
                    mystical = "creative", psychological = "mental",
                    legacy = "social",
                }
                if theme_cat_map[trial.theme] == dream_cat then
                    score = score + 2
                end
            end
        end
        if context.momentum and context.momentum.state == "ASCENDING" then
            score = score + 1  -- ascending momentum makes all trials slightly more likely
        end
        if context.religion and context.religion.zealotry then
            -- High zealotry favors mystical/legacy trials
            if context.religion.zealotry >= 75 and
               (trial.theme == "mystical" or trial.theme == "legacy") then
                score = score + 2
            end
        end

        scored[#scored + 1] = { trial = trial, score = score }
        end -- the_ascension exclusion
    end

    -- Weighted random selection
    local total_score = 0
    for _, s in ipairs(scored) do
        total_score = total_score + s.score
    end

    local roll = rng.random() * total_score
    local cumulative = 0
    for _, s in ipairs(scored) do
        cumulative = cumulative + s.score
        if roll < cumulative then
            return s.trial
        end
    end

    -- Fallback (use scored pool which excludes the_ascension)
    if #scored > 0 then
        return scored[rng.range(1, #scored)].trial
    end
    if #trials > 0 then return trials[1] end
    return nil
end

--- Evaluate a single trait check against the heir's genome.
---@param check table { trait_id, weight, threshold }
---@param heir_genome table genome instance
---@param reliquary_effects table|nil aggregated effects from reliquary
---@param rival_stat number|nil optional rival stat to use as threshold
---@param echo_bonuses table|nil optional { trait_id = bonus } from invoked echo
---@return number score (0.0, 0.5, or 1.0) weighted by check.weight
local function score_trait_check(check, heir_genome, reliquary_effects, rival_stat, echo_bonuses)
    local value = heir_genome:get_value(check.trait_id) or 50
    if reliquary_effects and reliquary_effects.trait_bonuses then
        value = value + (reliquary_effects.trait_bonuses[check.trait_id] or 0)
    end
    if echo_bonuses and echo_bonuses[check.trait_id] then
        value = value + echo_bonuses[check.trait_id]
    end
    
    -- If rival_stat is provided, they are the competitive threshold
    local threshold = rival_stat or check.threshold or 50

    if value >= threshold then
        return check.weight * 1.0
    elseif value >= threshold - 15 then
        return check.weight * 0.5
    else
        return check.weight * 0.0
    end
end

--- Select the best matching path based on personality and player 'nudge'.
---@param paths table array of path definitions
---@param heir_personality table personality instance
---@param context table|nil context for player 'nudge' influence
---@return table selected path
local function select_path(paths, heir_personality, context)
    local best_path = paths[1]
    local best_score = -999

    -- Momentum-based nudge: if player has strong momentum, it slightly tilts personality bias
    local nudge = 0
    if context and context.momentum and type(context.momentum) == "table" then
        if context.momentum.state == "ASCENDING" then
            nudge = 5  -- nudge toward higher axis values
        elseif context.momentum.state == "DESCENDING" then
            nudge = -5 -- nudge toward lower
        end
    end

    for _, path in ipairs(paths) do
        local axis_val = heir_personality:get_axis(path.personality_axis) or 50
        local score
        if path.direction == "high" then
            score = axis_val + nudge
        else
            score = (100 - axis_val) - nudge
        end
        if score > best_score then
            best_score = score
            best_path = path
        end
    end

    return best_path
end

--- Resolve a single stage: personality picks path, traits score it.
---@param stage table stage definition
---@param heir_genome table genome instance
---@param heir_personality table personality instance
---@param context table|nil
---@param trial_theme string|nil
---@param rival_heir table|nil optional competitor
---@return table { path_chosen, path_narrative, score, trait_results, stage_narrative }
function Crucible.resolve_stage(stage, heir_genome, heir_personality, context, trial_theme, rival_heir)
    local path = select_path(stage.paths, heir_personality, context)

    local rel_effects = context and context.reliquary and context.reliquary:get_effects() or nil
    local echo_bonuses = context and context.echo_bonuses or nil

    -- Score trait checks
    local total_score = 0
    local trait_results = {}
    for _, check in ipairs(path.trait_checks) do
        -- NEMESIS SYSTEM: If we have a rival, the threshold is their actual stat
        local rival_stat = nil
        if rival_heir and rival_heir.genome then
            rival_stat = rival_heir.genome[check.trait_id]
        end

        local check_score = score_trait_check(check, heir_genome, rel_effects, rival_stat, echo_bonuses)
        total_score = total_score + check_score
        trait_results[#trait_results + 1] = {
            trait_id = check.trait_id,
            weight = check.weight,
            score = check_score,
        }
    end

    -- Wealth Influence: High wealth can mitigate a poor score (buying your way out)
    if total_score < 0.5 and context and context.wealth and context.wealth.value >= 75 then
        total_score = total_score + 0.15
        total_score = math.min(1.0, total_score)
        -- This logic is silent in narrative for now, but mechanically pushes survival
    end

    -- Lineage Power Influence: High power adds a floor to the score
    if context and context.lineage_power and context.lineage_power.value >= 80 then
        total_score = math.max(total_score, 0.25) -- prevents disastrous failure
    end

    -- Normalize to 0.0-1.0
    local normalized = Math.clamp(total_score, 0, 1)

    -- 2. Mastery Bonuses: Direct stage overrides
    if heir_genome and heir_genome.mastery_tags then
        local theme = trial_theme or "survival"
        if theme == "combat" and heir_genome.mastery_tags.MASTER_WARRIOR then
            normalized = math.max(normalized, 0.7) -- Minimum Survival for Warriors in combat
        elseif theme == "diplomatic" and heir_genome.mastery_tags.MASTER_DIPLOMAT then
            normalized = math.max(normalized, 0.7)
        elseif (theme == "mystical" or theme == "psychological") and heir_genome.mastery_tags.MASTER_MYSTIC then
            normalized = math.max(normalized, 0.7)
        elseif theme == "legacy" and heir_genome.mastery_tags.MASTER_SCHOLAR then
            normalized = math.max(normalized, 0.7)
        elseif (theme == "political" or theme == "diplomatic") and heir_genome.mastery_tags.MASTER_SPY then
            normalized = math.max(normalized, 0.7)
        end
    end

    return {
        path_chosen = path.id,
        path_narrative = path.narrative or "",
        score = normalized,
        trait_results = trait_results,
        stage_title = stage.title,
        stage_narrative = stage.narrative or "",
    }
end

--- Determine outcome string from total score.
---@param score number 0.0-1.0
---@return string "triumph", "survival", or "defeat"
local function get_outcome(score)
    if score >= TRIUMPH_THRESHOLD then
        return "triumph"
    elseif score >= SURVIVAL_THRESHOLD then
        return "survival"
    else
        return "defeat"
    end
end

--- Get consequence definition based on outcome.
---@param outcome string "triumph", "survival", or "defeat"
---@param trial table trial definition
---@param context table { generation, world_state }
---@return table consequence table compatible with EventEngine.apply_consequences
function Crucible.get_consequences(outcome, trial, context)
    -- Living world flavor fragments
    local dream_frag = ""
    if context and context.bloodline_dream then
        dream_frag = " The bloodline's dream trembles in the aftermath."
    end
    local religion_frag = ""
    if context and context.religion and context.religion.name then
        local Religion = require("dredwork_world.religion")
        religion_frag = " " .. Religion.display_name(context.religion.name) .. " faith interprets the outcome."
    end

    -- Trial theme (exodus/combat trials have territorial consequences)
    local theme = trial.theme or "survival"
    local is_exodus = theme == "survival" and (trial.id or ""):find("exodus")

    if outcome == "triumph" then
        local cons = {
            cultural_memory_shift = { physical = 3, mental = 3, social = 3, creative = 3 },
            mutation_triggers = { { type = "crucible_triumph", intensity = -0.5 } },
            disposition_changes = { { faction_id = "all", delta = 8 } },
            narrative = "The crucible is passed. " .. (trial.name or "The trial") .. " forged the bloodline stronger." .. religion_frag,
        }
        -- Fossil restoration bonus on triumph — pick the highest peak trait
        if context and context.trait_peaks then
            local best_trait, best_val = nil, 0
            for tid, peak in pairs(context.trait_peaks) do
                local v = type(peak) == "table" and (peak.value or 0) or (peak or 0)
                if v > best_val then best_trait, best_val = tid, v end
            end
            if best_trait then
                cons.offspring_boost = { trait = best_trait, bonus = 5 }
            end
        end
        -- Exodus triumph: old holdings lost, but a new settlement is founded
        if is_exodus then
            cons.lose_holding = true
            local Holdings = require("dredwork_world.holdings")
            local era_key = context and context.world_state and context.world_state.current_era_key or "ancient"
            cons.gain_holding = {
                name = Holdings.generate_name("village", era_key),
                type = "village",
                size = 2,
                description = "Founded after the exodus, on land won by blood and endurance.",
            }
            cons.add_condition = { type = "exodus", intensity = 0.4, duration = 2 }
            cons.narrative = "The exodus succeeded. " .. (trial.name or "The march") .. " cost everything, but new land was claimed." .. religion_frag
        end
        -- Combat triumph: holdings intact, narrative only
        return cons
    elseif outcome == "survival" then
        local cons = {
            cultural_memory_shift = { physical = 1 },
            narrative = "The crucible is survived. " .. (trial.name or "The trial") .. " tested the blood, but the line endures." .. dream_frag,
        }
        -- Exodus survival: lose a holding, add exodus condition
        if is_exodus then
            cons.lose_holding = true
            cons.add_condition = { type = "exodus", intensity = 0.6, duration = 3 }
            cons.narrative = "The family fled. " .. (trial.name or "The march") .. " stripped them of land, but the blood survived." .. dream_frag
        end
        -- Combat survival: holdings damaged
        if theme == "combat" then
            cons.damage_holding = true
        end
        return cons
    else -- defeat
        local cons = {
            cultural_memory_shift = { physical = 2, mental = -2, social = -2, creative = -2 },
            mutation_triggers = { { type = "crucible_defeat", intensity = 0.7 } },
            disposition_changes = { { faction_id = "all", delta = -5 } },
            taboo_chance = 0.3,
            taboo_data = {
                trigger = "crucible_defeat_" .. (trial.id or "unknown"),
                effect = "failed_" .. (trial.theme or "trial"),
                strength = 70,
            },
            narrative = "The crucible broke the heir. " .. (trial.name or "The trial") .. " exposed the bloodline's weakness." .. religion_frag .. dream_frag,
        }
        -- Exodus defeat: lose multiple holdings, long exodus condition
        if is_exodus then
            cons.lose_holding = 2
            cons.add_condition = { type = "exodus", intensity = 0.8, duration = 5 }
            cons.narrative = "The exodus failed. The family was scattered, their holdings seized or abandoned." .. religion_frag .. dream_frag
        end
        -- Combat defeat: lose a holding
        if theme == "combat" then
            cons.lose_holding = true
        end
        -- Undercurrent amplifies defeat consequences
        if context and context.undercurrent_streaks then
            for _, streak in pairs(context.undercurrent_streaks) do
                if streak and streak >= 3 then
                    cons.mutation_triggers[1].intensity = 1.0
                    break
                end
            end
        end
        return cons
    end
end

--- Run the full crucible: all stages sequentially.
---@param trial table trial definition
---@param heir_genome table genome instance
---@param heir_personality table personality instance
---@param heir_name string
---@param context table { generation, world_state, mutation_pressure }
---@param is_life_event boolean|nil if true, reduces narrative intensity
---@param rival_heir table|nil optional specific competitor
---@return table full crucible result
function Crucible.run(trial, heir_genome, heir_personality, heir_name, context, is_life_event, rival_heir)
    local vars = {
        heir_name = heir_name or "the heir",
        lineage_name = context.lineage_name or "the bloodline",
        era_name = context.world_state and context.world_state:get_era_name() or "this age",
    }

    -- Inject rival heir vars (nemesis appears in crucible narrative)
    local nemesis = context.rival_heirs and context.rival_heirs:get_nemesis() or nil
    local active_rival = rival_heir or nemesis

    if nemesis then
        vars.rival_name = nemesis.name
        vars.rival_faction = nemesis.faction_name
        vars.rival_attitude = nemesis.attitude
    end

    -- Simple {key} substitution
    local function sub(text)
        if not text then return "" end
        return text:gsub("{([%w_]+)}", function(key)
            return vars[key] or ("{" .. key .. "}")
        end)
    end

    local stage_results = {}
    local total_score = 0
    local zero_count = 0

    for _, stage in ipairs(trial.stages) do
        local result = Crucible.resolve_stage(stage, heir_genome, heir_personality, context, trial.theme, active_rival)
        result.path_narrative = sub(result.path_narrative)
        result.stage_narrative = sub(result.stage_narrative)
        stage_results[#stage_results + 1] = result
        total_score = total_score + result.score
        if result.score == 0 then
            zero_count = zero_count + 1
        end
    end

    local avg_score = total_score / math.max(1, #stage_results)
    local outcome = get_outcome(avg_score)

    -- Heir death check (only on defeat)
    local heir_dies = false
    local death_cause = nil
    local death_chance = 0
    if outcome == "defeat" then
        death_chance = BASE_DEATH_CHANCE + (zero_count * DEATH_CHANCE_PER_ZERO)
        death_chance = math.min(death_chance, MAX_DEATH_CHANCE)
        if rng.chance(death_chance) then
            heir_dies = true
            death_cause = "crucible_" .. (trial.id or "trial")
        end
    end

    -- Build consequence definition
    local consequence_def = Crucible.get_consequences(outcome, trial, context)

    -- Build chronicle text
    local chronicle_lines = {}
    chronicle_lines[#chronicle_lines + 1] = sub(trial.opening or "")
    for _, sr in ipairs(stage_results) do
        chronicle_lines[#chronicle_lines + 1] = sr.stage_narrative
        chronicle_lines[#chronicle_lines + 1] = sr.path_narrative
    end
    if outcome == "triumph" then
        chronicle_lines[#chronicle_lines + 1] = heir_name .. " emerged triumphant from " .. trial.name .. "."
    elseif outcome == "survival" then
        chronicle_lines[#chronicle_lines + 1] = heir_name .. " endured " .. trial.name .. ", scarred but standing."
    else
        if heir_dies then
            chronicle_lines[#chronicle_lines + 1] = heir_name .. " fell during " .. trial.name .. ". The bloodline is shattered."
        else
            chronicle_lines[#chronicle_lines + 1] = heir_name .. " was broken by " .. trial.name .. ", but lived."
        end
    end

    -- Life events are quieter — strip the dramatic crucible framing
    if is_life_event then
        consequence_def.narrative = nil
    end

    return {
        trial_id = trial.id,
        trial_name = trial.name,
        trial_theme = trial.theme,
        opening = sub(trial.opening or ""),
        stages = stage_results,
        total_score = avg_score,
        outcome = outcome,
        heir_dies = heir_dies,
        death_cause = death_cause,
        death_chance = death_chance,
        consequence_def = consequence_def,
        chronicle_text = table.concat(chronicle_lines, " "),
    }
end

return Crucible
