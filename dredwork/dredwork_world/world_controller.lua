local Math = require("dredwork_core.math")
-- Dark Legacy — World Controller
-- Per-generation tick orchestrator. Ties all world systems together.
-- Pure Lua, zero Solar2D dependencies.

local WorldState = require("dredwork_world.world_state")
local rng = require("dredwork_core.rng")
local faction_module = require("dredwork_world.faction")
local FactionManager = faction_module.FactionManager
local EventEngine = require("dredwork_world.event_engine")
local Council = require("dredwork_world.council")
local Chronicle = require("dredwork_world.chronicle")

-- Faction autonomy systems (pcall-wrapped)
local ok_fr, FactionRelations = pcall(require, "dredwork_world.faction_relations")
if not ok_fr then FactionRelations = nil end
local ok_rum, Rumors = pcall(require, "dredwork_world.rumors")
if not ok_rum then Rumors = nil end
local ok_disc, Discoveries = pcall(require, "dredwork_world.discoveries")
if not ok_disc then Discoveries = nil end
local ok_rel, Religion = pcall(require, "dredwork_world.religion")
if not ok_rel then Religion = nil end
local ok_cul, Culture = pcall(require, "dredwork_world.culture")
if not ok_cul then Culture = nil end
local ok_nur, Nurture = pcall(require, "dredwork_world.nurture")
if not ok_nur then Nurture = nil end
local ok_gw, GreatWorks = pcall(require, "dredwork_world.great_works")
if not ok_gw then GreatWorks = nil end
local ok_legends, Legends = pcall(require, "dredwork_world.legends")
if not ok_legends then Legends = nil end
local ok_sc, StatCheck = pcall(require, "dredwork_world.stat_check")
if not ok_sc then StatCheck = nil end
local ok_bio, HeirBiography = pcall(require, "dredwork_world.heir_biography")
if not ok_bio then HeirBiography = nil end
local ok_doc, Doctrines = pcall(require, "dredwork_world.doctrines")
if not ok_doc then Doctrines = nil end
local ok_rh, rival_heirs_mod = pcall(require, "dredwork_world.rival_heirs")
local RivalHeirManager = ok_rh and rival_heirs_mod.RivalHeirManager or nil
local ok_lp, LineagePower = pcall(require, "dredwork_world.lineage_power")
if not ok_lp then LineagePower = nil end

-- New expanded world systems
local ok_reliq, Reliquary = pcall(require, "dredwork_world.reliquary")
if not ok_reliq then Reliquary = nil end
local ok_bs, BlackSheep = pcall(require, "dredwork_world.black_sheep")
if not ok_bs then BlackSheep = nil end
local ok_dream, BloodlineDream = pcall(require, "dredwork_world.bloodline_dream")
if not ok_dream then BloodlineDream = nil end
local ok_milestones, Milestones = pcall(require, "dredwork_world.milestones")
if not ok_milestones then Milestones = nil end
local ok_hold, Holdings = pcall(require, "dredwork_world.holdings")
if not ok_hold then Holdings = nil end
local ok_crt, Court = pcall(require, "dredwork_world.court")
if not ok_crt then Court = nil end
local ok_res, Resources = pcall(require, "dredwork_world.resources")
if not ok_res then Resources = nil end
local ok_echo, Echoes = pcall(require, "dredwork_world.echoes")
if not ok_echo then Echoes = nil end
local ok_shadow, ShadowLineages = pcall(require, "dredwork_world.shadow_lineage")
if not ok_shadow then ShadowLineages = nil end
local ok_mom, Momentum = pcall(require, "dredwork_world.momentum")
if not ok_mom then Momentum = nil end
local ok_camp, Campaign = pcall(require, "dredwork_world.campaign")
if not ok_camp then Campaign = nil end
local ok_nem, NemesisMod = pcall(require, "dredwork_world.nemesis")
if not ok_nem then NemesisMod = nil end

local WorldController = {}

--- Initialize a complete world state for a new game.
---@param era_key string starting era key
---@param custom_config table|nil optional overrides for worldbuilder mode
---@return table world context { world_state, factions, event_engine }
function WorldController.init(era_key, custom_config)
    local factions = FactionManager.new(custom_config)
    local ctx = {
        world_state = WorldState.new(era_key, custom_config),
        factions = factions,
        event_engine = EventEngine.new(),
    }
    -- Initialize faction autonomy systems
    if FactionRelations then
        ctx.faction_relations = FactionRelations.new(factions)
    end
    if Rumors then
        ctx.rumors = Rumors.new()
    end
    if Discoveries then
        ctx.discoveries = Discoveries.new()
    end
    if Religion then
        ctx.religion = Religion.new()
    end
    if Culture then
        ctx.culture = Culture.new()
    end
    if GreatWorks then
        ctx.great_works = GreatWorks.new()
    end
    if RivalHeirManager then
        ctx.rival_heirs = RivalHeirManager.new()
    end
    if Momentum then
        ctx.momentum = Momentum.new()
    end
    -- Initialize expanded world systems
    if Reliquary then
        ctx.reliquary = Reliquary.new()
    end
    if Holdings then
        ctx.holdings = Holdings.new(custom_config)
    end
    if Court then
        ctx.court = Court.new()
    end
    if Resources then
        ctx.resources = Resources.new(custom_config)
    end
    if Echoes then
        ctx.echoes = Echoes.new()
    end
    if ShadowLineages then
        ctx.shadow_lineages = ShadowLineages.new()
        -- Seed shadow lineages from abandoned past runs (restless bloodlines)
        pcall(function()
            local CrossRun = require("dredwork_world.cross_run")
            local abandoned = CrossRun.get_abandoned_shadows()
            for _, ghost in ipairs(abandoned) do
                local branch = {
                    id = "ghost_" .. tostring(rng.range(10000, 99999)),
                    name = "The " .. ghost.name .. " Remnant",
                    founder_name = ghost.name,
                    founder_traits = {},
                    stolen_relics = {},
                    generation_founded = 0,
                    founding_reason = "abandonment",
                    power = ghost.power,
                    status = "hidden",
                    history = { ghost.reason },
                    divergence_score = 10,
                    unique_mutation = "Hollow-Blood",
                }
                ctx.shadow_lineages.branches[#ctx.shadow_lineages.branches + 1] = branch
            end
        end)
    end
    if Campaign then
        ctx.campaign = Campaign.new()
    end
    -- Initialize nemesis from worldbuilder config
    if NemesisMod then
        local nem_faction_id = nil
        if custom_config and custom_config.factions then
            for _, fdef in ipairs(custom_config.factions) do
                if fdef.is_rival then
                    nem_faction_id = fdef.id
                    break
                end
            end
        end
        ctx.nemesis = NemesisMod.new(nem_faction_id)
        if nem_faction_id then
            -- Determine faction type for expectation
            local faction_type = nil
            pcall(function()
                local f = ctx.factions:get(nem_faction_id)
                if f then faction_type = f:get_dominant_category() end
                -- Map category to faction type key
                local cat_to_type = { physical = "warriors", mental = "scholars", social = "diplomats", creative = "artisans" }
                faction_type = cat_to_type[faction_type] or "warriors"
            end)
            ctx.nemesis:set_faction(nem_faction_id, faction_type)
        end
    end
    return ctx
end

--- Build the context table needed by event engine, council, etc.
---@param world table world context from init()
---@param game_state table GeneticsController state
---@return table context
function WorldController.build_context(world, game_state)
    return {
        world_state = world.world_state,
        factions = world.factions,
        faction_relations = world.faction_relations,
        rumors = world.rumors,
        religion = world.religion,
        culture = world.culture,
        discoveries = world.discoveries,
        great_works = world.great_works,
        reliquary = world.reliquary,
        holdings = world.holdings,
        court = world.court,
        resources = world.resources,
        echoes = world.echoes,
        shadow_lineages = world.shadow_lineages,
        campaign = world.campaign,
        nemesis = world.nemesis,
        heir_personality = game_state.heir_personality,
        heir_genome = game_state.current_heir,
        cultural_memory = game_state.cultural_memory,
        generation = game_state.generation,
        heir_name = game_state.heir_name,
        lineage_name = game_state.lineage_name,
        mutation_pressure = game_state.mutation_pressure,
        max_events = game_state.max_events,
        doctrines = game_state.doctrines,
        active_chains = game_state.active_chains,
        rival_heirs = world.rival_heirs,
        -- Living world data (consumed by event engine, council, crucible)
        momentum = world.momentum,
        bloodline_dream = game_state.bloodline_dream,
        trait_peaks = game_state.trait_peaks,
        ancestor_snapshots = game_state.ancestor_snapshots,
        undercurrent_streaks = game_state.undercurrent_streaks,
        wealth = game_state.wealth,
        morality = game_state.morality,
        lineage_moral_reputation = game_state.lineage_moral_reputation,
        lineage_power = game_state.lineage_power,
        heir_ledger = game_state.heir_ledger,
        -- Mutable reference for consequences that modify game_state directly
        game_state = game_state,
    }
end

--- Generate events for this generation.
---@param world table world context
---@param game_state table GeneticsController state
---@return table array of event objects
function WorldController.generate_events(world, game_state)
    local context = WorldController.build_context(world, game_state)
    return world.event_engine:generate(context)
end

--- Resolve a player-chosen event option.
---@param event table the event
---@param option_index number which option was chosen (1-based)
---@param world table world context
---@param game_state table GeneticsController state
---@param echo_bonuses table|nil optional bonuses from ghost council
---@return table effects
function WorldController.resolve_event(event, option_index, world, game_state, echo_bonuses)
    local context = WorldController.build_context(world, game_state)
    context.echo_bonuses = echo_bonuses -- Inject into context for event engine

    -- Populate dialogue-specific vars for substitution
    local vars = {
        heir_name = game_state.heir_name or "the heir",
        lineage_name = game_state.lineage_name or "the bloodline",
    }

    if world.court then
        for _, mem in ipairs(world.court.members) do
            if mem.role == "sibling" and not vars.sibling_name then
                vars.sibling_name = mem.name
            elseif mem.role == "spouse" and not vars.spouse_name then
                vars.spouse_name = mem.name
            end
        end
    end
    -- Fallbacks for names
    vars.sibling_name = vars.sibling_name or "your sibling"
    vars.spouse_name = vars.spouse_name or "your spouse"

    if world.rival_heirs then
        local target_id = event.target_faction or event.faction_id
        if target_id == "_target" then target_id = event.target_faction end
        local rival = target_id and world.rival_heirs:get(target_id) or world.rival_heirs:get_nemesis()
        if rival then
            vars.rival_name = rival.name
            vars.faction_name = rival.faction_name
        end
    end
    vars.rival_name = vars.rival_name or "the rival"
    vars.faction_name = vars.faction_name or "the rival house"

    -- Perform substitution on event fields before resolution
    local function sub(text)
        if not text then return "" end
        return text:gsub("{([%w_]+)}", function(key)
            return vars[key] or ("{" .. key .. "}")
        end)
    end

    if event.interlocutor and event.interlocutor.name then
        event.interlocutor.name = sub(event.interlocutor.name)
    end
    event.narrative = sub(event.narrative)
    event.opening = sub(event.opening)

    if event.auto_resolve then
        -- Personal events auto-resolve — but heir personality can still resist
        context.target_faction = event.target_faction
        local effects = EventEngine.auto_resolve(event, context)
        if game_state and game_state.heir_personality and event.auto_consequence then
            local auto_resistance = nil
            pcall(function()
                auto_resistance = EventEngine.check_heir_resistance(
                    { consequences = event.auto_consequence }, game_state.heir_personality
                )
            end)
            if auto_resistance then
                effects.heir_resisted = true
                effects.resistance = auto_resistance
                effects.consequence_lines = effects.consequence_lines or {}
                table.insert(effects.consequence_lines, 1, {
                    text = auto_resistance.narrative,
                    color_key = "special",
                })
            end
        end
        return effects
    end

    local option = event.options and event.options[option_index]
    if not option then return { narrative = "" } end

    -- PERSONALITY AUTONOMY: Check if the heir resists this choice
    local resistance = nil
    if game_state and game_state.heir_personality then
        pcall(function()
            resistance = EventEngine.check_heir_resistance(option, game_state.heir_personality)
        end)
    end

    -- Inject target faction if event has one
    if event.target_faction and option.consequences then
        option.consequences.target_faction = event.target_faction
    end
    if event.target_faction and option.consequences_fail then
        option.consequences_fail.target_faction = event.target_faction
    end

    -- Helper: apply heir resistance to effects after consequence resolution
    local function apply_resistance(effects)
        if not resistance then return effects end
        effects.heir_resisted = true
        effects.resistance = resistance
        effects.consequence_lines = effects.consequence_lines or {}

        -- Resistance narrative line
        table.insert(effects.consequence_lines, 1, {
            text = resistance.narrative,
            color_key = "special",
        })
        table.insert(effects.consequence_lines, 2, {
            text = "HEIR RESISTED — effectiveness reduced",
            color_key = "negative",
        })

        -- Dampen positive lineage_power_shift (heir's half-hearted effort)
        if effects.lineage_power_shift then
            effects.lineage_power_shift = math.floor(
                effects.lineage_power_shift * (1 - resistance.resistance_strength * 0.5)
            )
        end

        -- Record the resistance as a chronicle whisper
        if context.world_state then
            context.world_state:add_chronicle(
                resistance.narrative, {
                    origin = {
                        type = "heir_resistance",
                        heir_name = game_state.heir_name or "the heir",
                        gen = game_state.generation or 0,
                        detail = "Resisted due to " .. resistance.axis_name
                    }
                }
            )
        end
        return effects
    end

    -- Evaluate stat check if present
    -- Compat: convert old flat `stat_check` format to structured `check` format
    if not option.check and option.stat_check then
        local sc = option.stat_check
        option.check = {
            difficulty = sc.difficulty or 50,
        }
        if sc.primary then
            option.check.primary = { trait = sc.primary, weight = 1.0 }
        end
        if sc.secondary then
            option.check.secondary = { trait = sc.secondary, weight = 0.5 }
        end
        if sc.tertiary then
            option.check.tertiary = { trait = sc.tertiary, weight = 0.25 }
        end
    end

    local consequences = option.consequences or {}
    if option.check and StatCheck and game_state and game_state.current_heir then
        local wild_bonuses = nil
        if HeirBiography then
            pcall(function()
                local wa = HeirBiography.get_wild_attributes(
                    game_state.current_heir, game_state.heir_personality
                )
                wild_bonuses = HeirBiography.wild_bonuses(wa)
            end)
        end

        -- Holdings defense bonus: more domains = better physical stat checks
        if world.holdings and world.holdings.domains then
            pcall(function()
                local domain_count = #world.holdings.domains
                if domain_count >= 2 then
                    if not wild_bonuses then wild_bonuses = {} end
                    wild_bonuses.physical = (wild_bonuses.physical or 0) + math.min(8, domain_count * 2)
                end
            end)
        end

        local rel_effects = world.reliquary and world.reliquary:get_effects() or nil

        -- Merge discovery trait bonuses into stat check bonuses
        if world.discoveries then
            pcall(function()
                local disc_effects = world.discoveries:get_effects()
                if disc_effects and disc_effects.trait_bonuses then
                    if not rel_effects then rel_effects = { trait_bonuses = {} } end
                    if not rel_effects.trait_bonuses then rel_effects.trait_bonuses = {} end
                    for trait_id, bonus in pairs(disc_effects.trait_bonuses) do
                        rel_effects.trait_bonuses[trait_id] = (rel_effects.trait_bonuses[trait_id] or 0) + bonus
                    end
                end
            end)
        end

        -- NEMESIS SYSTEM: identify if we are competing against a specific rival heir
        local rival_competitor = nil
        if (event.category == "faction" or event.target_faction) and world.rival_heirs then
            local target_id = event.target_faction or event.faction_id
            if target_id == "_target" then target_id = event.target_faction end
            if target_id then
                rival_competitor = world.rival_heirs:get(target_id)
            end
        end

        -- If heir resists, apply a penalty to the stat check difficulty
        local resistance_penalty = 0
        if resistance then
            resistance_penalty = math.floor(resistance.resistance_strength * 15)
        end

        local result = StatCheck.evaluate(
            game_state.current_heir,
            option.check,
            game_state.heir_personality,
            game_state.cultural_memory,
            wild_bonuses,
            game_state.momentum,
            rel_effects,
            rival_competitor,
            echo_bonuses,
            context.culture,
            game_state.generation,
            game_state.morality
        )

        -- Apply resistance penalty to score (reluctant heir performs worse)
        if resistance_penalty > 0 then
            result.score = result.score - resistance_penalty
            result.success = result.score >= result.difficulty
        end

        if result.success then
            consequences = option.consequences or {}
        else
            consequences = option.consequences_fail or option.consequences or {}
        end
        -- Attach check result for UI feedback
        local effects = EventEngine.apply_consequences(consequences, context)

        -- Tag the primary result with origin
        if effects.narrative and effects.narrative ~= "" then
            context.world_state:add_chronicle(effects.narrative, {
                origin = {
                    type = "event",
                    heir_name = game_state.heir_name,
                    gen = game_state.generation,
                    detail = event.label or event.id
                }
            })
        end

        effects.stat_check = result
        effects.stat_check_quality = StatCheck.get_quality(result)

        -- Prepend stat check result line to consequence panel
        local quality = effects.stat_check_quality
        local quality_labels = {
            triumph = "TRIUMPH", success = "SUCCESS",
            failure = "FAILURE", disaster = "DISASTER",
        }
        local quality_colors = {
            triumph = "special", success = "positive",
            failure = "negative", disaster = "negative",
        }
        local check_line = {
            text = (quality_labels[quality] or "CHECK") ..
                   " (score " .. result.score .. " vs " .. result.difficulty .. ")",
            color_key = quality_colors[quality] or "neutral",
        }
        effects.consequence_lines = effects.consequence_lines or {}
        table.insert(effects.consequence_lines, 1, check_line)

        return apply_resistance(effects)
    end

    return apply_resistance(EventEngine.apply_consequences(consequences, context))
end

--- Get available council actions.
---@param world table world context
---@param game_state table GeneticsController state
---@return table array of action definitions
function WorldController.get_council_actions(world, game_state)
    local context = WorldController.build_context(world, game_state)
    return Council.get_available_actions(context)
end

--- Execute a council action.
---@param action table the chosen action definition
---@param world table world context
---@param game_state table GeneticsController state
---@param target_faction_id string|nil
---@param chosen_category string|nil chosen category key for category-choice actions
---@param target_holding_id string|nil target holding for domain actions
---@return table effects
function WorldController.execute_council_action(action, world, game_state, target_faction_id, chosen_category, target_holding_id)
    local context = WorldController.build_context(world, game_state)
    local effects = Council.execute(action, context, target_faction_id, chosen_category, target_holding_id)

    -- PERSONALITY AUTONOMY: Check if the heir resists this council action
    if game_state and game_state.heir_personality and action.consequences then
        local resistance = nil
        pcall(function()
            resistance = EventEngine.check_heir_resistance(
                { consequences = action.consequences }, game_state.heir_personality
            )
        end)
        if resistance then
            effects.heir_resisted = true
            effects.resistance = resistance
            effects.consequence_lines = effects.consequence_lines or {}

            table.insert(effects.consequence_lines, 1, {
                text = resistance.narrative,
                color_key = "special",
            })
            table.insert(effects.consequence_lines, 2, {
                text = "HEIR RESISTED — the order was carried out reluctantly",
                color_key = "negative",
            })

            -- Record in chronicle
            if world.world_state then
                world.world_state:add_chronicle(
                    resistance.narrative, {
                        origin = {
                            type = "heir_resistance",
                            heir_name = game_state.heir_name or "the heir",
                            gen = game_state.generation or 0,
                            detail = "Resisted council action: " .. (action.label or action.id)
                        }
                    }
                )
            end
        end
    end

    return effects
end

--- Apply doctrine modifiers to world-side systems (religion, culture, factions).
--- Called at the start of advance_generation.
---@param game_state table GeneticsController state
---@param world table world context
function WorldController._apply_world_doctrine_modifiers(game_state, world)
    if not Doctrines then return end

    -- Religion modifiers
    if Religion and world.religion then
        Religion._doctrine_zealotry_floor = Doctrines.get_modifier(game_state, "zealotry_floor")
        Religion._doctrine_religion_locked = Doctrines.has_modifier(game_state, "religion_locked")
        local schism_mult = Doctrines.get_modifier(game_state, "schism_pressure_multiplier")
        Religion._doctrine_schism_pressure_mult = schism_mult ~= 0 and schism_mult or 1.0
        local zeal_mult = Doctrines.get_modifier(game_state, "zealotry_bonus_multiplier")
        Religion._doctrine_zealotry_bonus_mult = zeal_mult ~= 0 and zeal_mult or 1.0
    end

    -- Culture modifiers
    if Culture and world.culture then
        Culture._doctrine_culture_locked = Doctrines.has_modifier(game_state, "culture_locked")
        Culture._doctrine_rigidity_floor = Doctrines.get_modifier(game_state, "rigidity_floor")
    end

    -- Faction modifiers
    local FactionMgr = require("dredwork_world.faction").FactionManager
    FactionMgr._doctrine_disposition_drift = Doctrines.get_modifier(game_state, "faction_disposition_drift")
    FactionMgr._doctrine_permanent_alliance = Doctrines.has_modifier(game_state, "permanent_alliance")
    FactionMgr._doctrine_permanent_enmity = Doctrines.has_modifier(game_state, "permanent_enmity")
    local ally_floor = Doctrines.get_modifier(game_state, "alliance_disposition_floor")
    FactionMgr._doctrine_alliance_disp_floor = ally_floor ~= 0 and ally_floor or nil
    local enmity_ceil = Doctrines.get_modifier(game_state, "enmity_disposition_ceiling")
    FactionMgr._doctrine_enmity_disp_ceiling = enmity_ceil ~= 0 and enmity_ceil or nil

    -- Cultural Memory modifiers
    local CulturalMemory = require("dredwork_genetics.cultural_memory")
    local taboo_mult = Doctrines.get_modifier(game_state, "taboo_decay_multiplier")
    CulturalMemory._doctrine_taboo_decay_mult = taboo_mult ~= 0 and taboo_mult or 1.0
    local rel_mult = Doctrines.get_modifier(game_state, "relationship_decay_multiplier")
    CulturalMemory._doctrine_relationship_decay_mult = rel_mult ~= 0 and rel_mult or 1.0
    local shift_speed = Doctrines.get_modifier(game_state, "cultural_shift_speed")
    CulturalMemory._doctrine_cultural_shift_speed = shift_speed ~= 0 and shift_speed or 1.0
    CulturalMemory._doctrine_blind_spot_pierce = Doctrines.has_modifier(game_state, "blind_spot_pierce")

    -- Custom culture effects
    if world.culture then
        local discovery_decay_reduction = 0
        if world.discoveries then
            local disc_effects = world.discoveries:get_effects()
            discovery_decay_reduction = disc_effects.cultural_memory_decay_reduction or 0
        end

        if world.culture:has_custom("ancestor_worship") then
            CulturalMemory._custom_decay_mult = math.max(0.1, 0.5 - discovery_decay_reduction)
        else
            CulturalMemory._custom_decay_mult = math.max(0.1, 1.0 - discovery_decay_reduction)
        end
        if world.culture:has_custom("blood_oaths") then
            CulturalMemory._custom_relationship_bonus = 20 -- relationship_strength_bonus
        else
            CulturalMemory._custom_relationship_bonus = 0
        end
    end
end

--- Advance the world by one generation. Call AFTER GeneticsController.advance_generation.
---@param world table world context
---@param game_state table GeneticsController state
---@param old_category_avgs table|nil snapshots of CM priorities before the genetics update
---@return table results { world_advance, chronicle_entry, momentum_events }
function WorldController.advance_generation(world, game_state, old_category_avgs)
    local results = {}
    if not world.world_state then return results end
    local context = WorldController.build_context(world, game_state)

    -- Snapshot faction dispositions for delta tracking (heir ledger)
    local old_dispositions = {}
    if world.factions then
        pcall(function()
            for _, f in ipairs(world.factions:get_all()) do
                old_dispositions[f.id] = f.disposition or 0
            end
        end)
    end

    -- Snapshot condition count for tracking new conditions
    local old_condition_count = 0
    if world.world_state and world.world_state.conditions then
        old_condition_count = #world.world_state.conditions
    end

    -- Advance world state FIRST so world_state.generation matches game_state.generation
    -- before any chronicle entries are added (prevents generation bleed in viewer)
    local ok_ws, err_ws = pcall(function()
        results.world_advance = world.world_state:advance(context)
    end)
    if not ok_ws then print("Error in WorldController: World State Advance: " .. tostring(err_ws)) end

    -- Late-game mutation pressure acceleration: the genome destabilizes over time
    pcall(function()
        if generation >= 50 and game_state.mutation_pressure then
            -- +1 ambient pressure per gen past 50, capping at +3
            local extra = math.min(3, math.floor((generation - 50) / 10) + 1)
            game_state.mutation_pressure.value = math.min(100, game_state.mutation_pressure.value + extra)
            results.weight_mutation_pressure = extra
        end
    end)

    -- Black Sheep Detection (Heir vs Family)
    if BlackSheep then
        local bs_data = BlackSheep.detect(game_state.current_heir, game_state.heir_personality, game_state.cultural_memory)
        if bs_data then
            results.black_sheep = bs_data
            game_state.is_black_sheep = true
            world.world_state:add_chronicle("Breaking the Mold: " .. bs_data.narrative, {
                origin = { type = "black_sheep", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Breaking the Mold" }
            })
            -- Reward: +5 power for a notable outlier
            if game_state.lineage_power then
                local LP = require("dredwork_world.lineage_power")
                LP.shift(game_state.lineage_power, 5)
            end
        end
    end

    -- 0. Apply doctrine modifiers to world systems before ticking
    WorldController._apply_world_doctrine_modifiers(game_state, world)

    -- 0b. Update Momentum
    if Momentum and world.momentum and old_category_avgs then
        local ok, err = pcall(function()
            local new_avgs = game_state.cultural_memory:get_category_averages()
            local mom_results = Momentum.update(world.momentum, old_category_avgs, new_avgs)
            results.momentum_events = mom_results.changes
            
            -- Add momentum changes to chronicle
            for _, change in ipairs(results.momentum_events) do
                world.world_state:add_chronicle(change.narrative, {
                    origin = { type = "momentum", heir_name = game_state.heir_name, gen = game_state.generation, detail = change.category or "generational shift" }
                })
            end
        end)
        if not ok then print("Error in WorldController: Momentum Tick: " .. tostring(err)) end
    end

    -- 1. World state already advanced above (before chronicle entries)

    -- 2. Evolve all factions
    local ok_fac, err_fac = pcall(function()
        world.factions:evolve_all(world.world_state)
    end)
    if not ok_fac then print("Error in WorldController: Faction Evolution: " .. tostring(err_fac)) end

    -- 2a. FACTION RETALIATION: Hostile factions actively harm the player
    pcall(function()
        results.faction_retaliation = {}
        for _, f in ipairs(world.factions:get_all()) do
            if f:is_hostile() and f.status ~= "fallen" then
                local hostility = math.abs(f.disposition)
                local faction_power = f.power or 50
                local dominant = f:get_dominant_category()

                -- Get rival heir name for personal narration
                local rival = world.rival_heirs and world.rival_heirs.heirs[f.id]
                local rival_name = rival and rival.alive and rival.name or nil

                -- Chance of retaliation scales with hostility, power, and era
                -- Late-game factions are bolder: +20% at gen 40, +50% at gen 60+
                local gen_aggression = 1.0
                if generation >= 60 then gen_aggression = 1.5
                elseif generation >= 40 then gen_aggression = 1.2 end
                local retaliation_chance = (hostility / 100) * (faction_power / 100) * 0.6 * gen_aggression
                if rng.chance(retaliation_chance) then
                    local action = nil
                    local leader = rival_name and (rival_name .. " of " .. f.name) or f.name

                    -- Warriors raid holdings
                    if dominant == "physical" and world.holdings and #world.holdings.domains > 0 then
                        local damage = world.holdings:damage_random_domain()
                        if damage then
                            action = { type = "raid", faction = f.name, text = leader .. " ordered a raid on our holdings. " .. damage }
                            if world.resources then
                                local stolen = math.floor(faction_power * 0.15)
                                world.resources:change("grain", -stolen, f.name .. " raid", game_state.heir_name, game_state.generation)
                            end
                        end
                    -- Scholars sabotage lore
                    elseif dominant == "mental" and world.resources then
                        local lore_loss = math.floor(faction_power * 0.08)
                        world.resources:change("lore", -lore_loss, f.name .. " sabotage", game_state.heir_name, game_state.generation)
                        action = { type = "sabotage", faction = f.name, text = leader .. " sent agents to burn our archives. Lore -" .. lore_loss .. "." }
                    -- Diplomats undermine reputation
                    elseif dominant == "social" then
                        if game_state.lineage_power then
                            local LP = require("dredwork_world.lineage_power")
                            LP.shift(game_state.lineage_power, -5)
                        end
                        -- Poison other factions against us
                        for _, other in ipairs(world.factions:get_all()) do
                            if other.id ~= f.id and not other:is_hostile() then
                                other:shift_disposition(-3)
                            end
                        end
                        action = { type = "slander", faction = f.name, text = leader .. " whispered our name like a curse in every court. Power -5, all factions grow suspicious." }
                    -- Artisans embargo trade
                    elseif dominant == "creative" and world.resources then
                        local gold_loss = math.floor(faction_power * 0.12)
                        world.resources:change("gold", -gold_loss, f.name .. " embargo", game_state.heir_name, game_state.generation)
                        action = { type = "embargo", faction = f.name, text = leader .. " sealed the trade routes. Gold -" .. gold_loss .. "." }
                    end

                    if action then
                        action.rival_name = rival_name
                        results.faction_retaliation[#results.faction_retaliation + 1] = action
                        world.world_state:add_chronicle(action.text, {
                            origin = { type = "faction_retaliation", heir_name = game_state.heir_name, gen = game_state.generation, detail = f.name .. " " .. action.type }
                        })
                    end
                end
            end
        end
    end)

    -- 2a-ii. NEMESIS TICK: Personal rival escalation
    if world.nemesis and world.nemesis.faction_id then
        pcall(function()
            local nem_faction = world.factions:get(world.nemesis.faction_id)
            local nem_rival = world.rival_heirs and world.rival_heirs.heirs[world.nemesis.faction_id]
            local nem_ctx = {
                resources = world.resources,
                holdings = world.holdings,
                factions = world.factions,
                lineage_power = game_state.lineage_power,
            }
            local nem_results = world.nemesis:tick(nem_faction, nem_rival, generation, nem_ctx)
            results.nemesis = nem_results

            -- Surface nemesis initiative narration
            if not nem_results.narration then
                nem_results.narration = world.nemesis:get_initiative_narration(nem_faction, nem_rival)
            end

            -- Nemesis secret actions feed into faction retaliation display
            if nem_results.secret and nem_results.secret.hostile then
                results.faction_retaliation[#results.faction_retaliation + 1] = {
                    type = "nemesis_secret",
                    faction = nem_faction and nem_faction.name or "Unknown",
                    text = nem_results.secret.text,
                    rival_name = nem_rival and nem_rival.name or nil,
                }
            end
        end)
    end

    -- 2b. Tick rival heirs (succession, death, attitude updates)
    if world.rival_heirs then
        local ok, err = pcall(function()
            results.rival_heir_events = world.rival_heirs:tick(
                world.factions, game_state.generation, context
            )
        end)
        if not ok then print("Error in WorldController: Rival Heirs Tick: " .. tostring(err)) end
    end

    -- 3. Tick inter-faction relations
    if world.faction_relations then
        local ok, err = pcall(function()
            -- Tie-in: Power affects Disposition (High power = others more deferential)
            local power_val = (game_state.lineage_power and game_state.lineage_power.value) or 50
            if power_val >= 70 then
                local relations = world.faction_relations
                for _, f in ipairs(world.factions:get_all()) do
                    relations:shift(f.id, "player", 1, "Awe of lineage power", game_state.generation)
                end
            end
            results.faction_events = world.faction_relations:tick(
                game_state.generation, world.factions, world.rumors
            )

            -- Process faction events for world impacts
            for _, fe in ipairs(results.faction_events) do
                if fe.type == "faction_war_declared" then
                    -- Faction wars destabilize the world
                    if world.world_state then
                        world.world_state:add_condition("war", 0.3, 3, {
                            target_faction_id = fe.faction_a,
                            target_faction_name = fe.faction_a,
                        })
                    end
                elseif fe.type == "faction_skirmish" then
                    -- Skirmishes can damage player holdings if they happen nearby (random chance)
                    if world.holdings and rng.range(1, 100) <= 20 then
                        local damage_text = world.holdings:damage_random_domain()
                        if damage_text then
                            world.world_state:add_chronicle(damage_text, {
                                origin = { type = "faction_conflict", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Holdings damaged by skirmish" }
                            })
                        end
                    end
                end
            end
        end)
        if not ok then print("Error in WorldController: Faction Relations Tick: " .. tostring(err)) end
    end

    -- 4. Generate rumors
    if world.rumors then
        local ok, err = pcall(function()
            local context = WorldController.build_context(world, game_state)
            world.rumors:generate(context)
        end)
        if not ok then print("Error in WorldController: Rumor Generation: " .. tostring(err)) end
    end

    -- 5. Tick religion
    if world.religion and world.religion.active then
        local ok, err = pcall(function()
            local heir_genome = game_state.current_heir
            results.religion = world.religion:tick(
                heir_genome, game_state.cultural_memory, game_state.generation
            )
        end)
        if not ok then print("Error in WorldController: Religion Tick: " .. tostring(err)) end
    elseif world.religion and not world.religion.active and Religion then
        -- Auto-generate religion at generation 3-5
        local gen = game_state.generation or 0
        if gen >= 3 and gen <= 5 then
            local ok, err = pcall(function()
                world.religion:generate(game_state.cultural_memory, gen)
            end)
            if not ok then print("Error in WorldController: Religion Generation: " .. tostring(err)) end
        end
    end

    -- 6. Tick culture
    if world.culture then
        local ok, err = pcall(function()
            -- Tie-in: Wealth affects Rigidity (High wealth = harder to change culture)
            local wealth_val = (game_state.wealth and game_state.wealth.value) or 50
            local ok_cul_mod, CultureModule = pcall(require, "dredwork_world.culture")
            if ok_cul_mod then
                CultureModule._doctrine_rigidity_floor = math.max(CultureModule._doctrine_rigidity_floor or 0, math.floor(wealth_val / 2.5))
            end
            world.culture:tick(
                game_state.cultural_memory,
                game_state.generation,
                world.world_state and world.world_state.current_era_key or nil
            )
        end)
        if not ok then print("Error in WorldController: Culture Tick: " .. tostring(err)) end
    end

    -- 7. Auto-unlock discoveries (Requires Lore)
    if world.discoveries and game_state.current_heir then
        local ok, err = pcall(function()
            local era_key = world.world_state.current_era_key or "ancient"
            local available = world.discoveries:get_available(game_state.current_heir, era_key)
            for _, disc in ipairs(available) do
                -- Check if lineage has enough Lore (e.g., 5 Lore per discovery)
                local lore_cost = 5
                if not world.resources or world.resources.lore >= lore_cost then
                    if world.resources then
                        world.resources:change("lore", -lore_cost, "Unlocked Discovery: " .. disc.label, game_state.heir_name, game_state.generation)
                    end
                    
                    world.discoveries:unlock(disc.id, game_state.generation, game_state.heir_name)
                    results.discoveries_unlocked = results.discoveries_unlocked or {}
                    results.discoveries_unlocked[#results.discoveries_unlocked + 1] = disc
                    -- Chronicle entry for discovery
                    world.world_state:add_chronicle(
                        (game_state.heir_name or "The heir") .. " forged a discovery: " .. (disc.label or disc.id) .. ".", {
                        origin = { type = "discovery", heir_name = game_state.heir_name, gen = game_state.generation, detail = disc.label or disc.id }
                    })
                end
            end
            -- Flag first discovery for event engine (narrative event next gen)
            if results.discoveries_unlocked and #results.discoveries_unlocked > 0 then
                local first = results.discoveries_unlocked[1]
                world.world_state._pending_discovery = {
                    label = first.label or first.id,
                    flavor = first.flavor or "",
                    category = first.category or "mental",
                    discoverer = game_state.heir_name or "the heir",
                }
            end
        end)
        if not ok then print("Error in WorldController: Discovery Tick: " .. tostring(err)) end
    end

    -- 8. Progress great works
    if world.great_works and world.great_works.in_progress then
        local ok, err = pcall(function()
            -- Tie-in: Great Works drain Wealth during construction
            if game_state.wealth then
                local Wealth = require("dredwork_world.wealth")
                Wealth.change(game_state.wealth, -6, "investment", game_state.generation, "Construction costs for " .. world.great_works.in_progress.label)
            end
            -- Also drain Gold directly
            if world.resources then
                world.resources:change("gold", -5, "Great Work Construction", game_state.heir_name, game_state.generation)
            end
            local completion = world.great_works:invest(game_state.generation, game_state.heir_name)
            if completion then
                results.great_work_completed = completion
                -- Chronicle entry for great work completion
                world.world_state:add_chronicle(
                    "A great work was completed: " .. (completion.label or completion.id) ..
                    ". Begun by " .. (completion.builder or "unknown") ..
                    ", finished by " .. (completion.completer or "unknown") .. ".", {
                    origin = { type = "great_work", heir_name = completion.completer or game_state.heir_name, gen = game_state.generation, detail = completion.label or completion.id }
                })
            end
        end)
        if not ok then print("Error in WorldController: Great Works Tick: " .. tostring(err)) end
    end

    -- 9. Apply discovery effects (mutation pressure reduction)
    if world.discoveries then
        local ok, err = pcall(function()
            local disc_effects = world.discoveries:get_effects()
            if disc_effects.mutation_pressure_reduction > 0 then
                game_state.mutation_pressure.value = math.max(0,
                    game_state.mutation_pressure.value - disc_effects.mutation_pressure_reduction)
            end
        end)
        if not ok then print("Error in WorldController: Discovery Effects: " .. tostring(err)) end
    end

    -- 9c. Apply Reliquary effects (mutation pressure reduction)
    if world.reliquary then
        local ok, err = pcall(function()
            local rel_effects = world.reliquary:get_effects()
            if rel_effects.mutation_pressure_reduction > 0 then
                game_state.mutation_pressure.value = math.max(0,
                    game_state.mutation_pressure.value - rel_effects.mutation_pressure_reduction)
            end
        end)
        if not ok then print("Error in WorldController: Reliquary Effects: " .. tostring(err)) end
    end

    -- 9d. Apply Great Works effects (mutation pressure reduction)
    if world.great_works then
        local ok, err = pcall(function()
            local gw_effects = world.great_works:get_effects()
            if gw_effects.mutation_pressure_reduction and gw_effects.mutation_pressure_reduction > 0 then
                game_state.mutation_pressure.value = math.max(0,
                    game_state.mutation_pressure.value - gw_effects.mutation_pressure_reduction)
            end
        end)
        if not ok then print("Error in WorldController: Great Works Effects: " .. tostring(err)) end
    end

    -- 9b. Condition ↔ Religion/Culture feedback loop
    -- Plague shakes faith (schism pressure), war inspires zeal, famine erodes culture
    if world.world_state and world.world_state.conditions then
        local conditions = world.world_state.conditions
        for _, cond in ipairs(conditions) do
            if cond.remaining_gens and cond.remaining_gens > 0 then
                if cond.type == "plague" and world.religion and world.religion.active then
                    -- Plague shakes faith: schism pressure builds
                    world.religion.schism_pressure = (world.religion.schism_pressure or 0) + 5
                end
                if cond.type == "war" and world.religion and world.religion.active then
                    -- War inspires zealotry: prayer in battle
                    world.religion.zealotry = math.min(100, (world.religion.zealotry or 0) + 3)
                end
                if cond.type == "famine" and world.culture then
                    -- Famine erodes customs: survival trumps tradition
                    world.culture.rigidity = math.max(0, (world.culture.rigidity or 50) - 3)
                end
            end
        end
    end

    -- 10. Check for Fail-States (The Last Stand / Phase 3)
    local ok, err = pcall(function()
        local lp_val = (game_state.lineage_power and game_state.lineage_power.value) or 50
        local w_val = (game_state.wealth and game_state.wealth.value) or 50

        if lp_val <= 5 or w_val <= 5 then
            -- Trigger the final crisis flag
            results.trigger_last_stand = true
            -- Find the Last Stand trial definition
            local crucible_trials = require("dredwork_world.config.crucible_trials")
            local last_stand_tmpl = nil
            for _, t in ipairs(crucible_trials) do
                if t.id == "the_last_stand" then last_stand_tmpl = t; break end
            end

            if last_stand_tmpl then
                local Crucible = require("dredwork_world.crucible")
                local context = WorldController.build_context(world, game_state)
                local last_stand_result = Crucible.run(
                    last_stand_tmpl, game_state.current_heir, game_state.heir_personality,
                    game_state.heir_name, context
                )
                results.last_stand_result = last_stand_result
                world.world_state.last_crucible_gen = game_state.generation or 0
            end
        end
    end)
    if not ok then print("Error in WorldController: Fail-State Check: " .. tostring(err)) end

    -- 10a2. Regular Crucible / Combat trigger (skip if Last Stand already triggered)
    if not results.trigger_last_stand then
        local ok, err = pcall(function()
            local Crucible = require("dredwork_world.crucible")
            local context = WorldController.build_context(world, game_state)
            context.last_crucible_gen = world.world_state.last_crucible_gen

            if Crucible.should_trigger(context) then
                local trial = Crucible.select_trial(context)
                if trial then
                    if trial.theme == "combat" then
                        -- Combat v2: build combatants and resolve
                        local ok_bridge, Bridge = pcall(require, "dredwork_combat_v2.bridge")
                        local ok_combat, Combat = pcall(require, "dredwork_combat_v2.combat")
                        if ok_bridge and ok_combat then
                            local protag = Bridge.build_heir(game_state, world)
                            -- Build opponent from nemesis or default rival
                            local opponent = nil
                            if world.rival_heirs then
                                local nemesis = world.rival_heirs:get_nemesis()
                                if nemesis then
                                    local faction = world.factions and world.factions:get(nemesis.faction_id)
                                    opponent = Bridge.build_rival(nemesis, faction, world)
                                end
                            end
                            if not opponent then
                                -- Generic combat rival from strongest hostile faction
                                local hostile_faction = nil
                                if world.factions then
                                    for _, f in ipairs(world.factions:get_active()) do
                                        if f:is_hostile() then
                                            if not hostile_faction or f.power > hostile_faction.power then
                                                hostile_faction = f
                                            end
                                        end
                                    end
                                end
                                if hostile_faction then
                                    opponent = Bridge.build_rival(nil, hostile_faction, world)
                                else
                                    opponent = Combat.build_default("A Challenger")
                                end
                            end
                            local stakes_type = opponent.is_nemesis and "blood" or "honor"
                            local stakes = Bridge.build_stakes(stakes_type, "courtyard")
                            local seed = (game_state.generation or 1) * 7919 + (world.world_state.era_index or 1) * 31
                            local combat_result = Combat.resolve(protag, opponent, seed, stakes)
                            results.trigger_combat = true
                            results.combat_result = combat_result
                            results.combat_protagonist = protag
                            results.combat_opponent = opponent
                            results.combat_stakes_type = stakes_type

                            -- Add combat narrative to chronicle
                            local outcome = combat_result.outcome or {}
                            local outcome_word = outcome.protag_won == true and "victorious" or (outcome.protag_won == false and "defeated" or "fought to a draw")
                            local chronicle_text = string.format(
                                "%s faced %s in %s combat and was %s. %d rounds fought.",
                                game_state.heir_name or "The heir",
                                opponent.name or "a rival",
                                stakes_type,
                                outcome_word,
                                outcome.rounds or 0
                            )
                            world.world_state:add_chronicle(chronicle_text, {
                                generation = game_state.generation,
                                heir_name = game_state.heir_name,
                                origin = { type = "combat", heir_name = game_state.heir_name, gen = game_state.generation, detail = stakes_type .. " combat vs " .. (opponent.name or "rival") },
                            })
                        else
                            -- Fallback to abstract crucible if combat v2 not available
                            local crucible_result = Crucible.run(
                                trial, game_state.current_heir, game_state.heir_personality,
                                game_state.heir_name, context
                            )
                            results.trigger_crucible = true
                            results.crucible_result = crucible_result
                        end
                    else
                        -- Non-combat trial: use abstract crucible system
                        local crucible_result = Crucible.run(
                            trial, game_state.current_heir, game_state.heir_personality,
                            game_state.heir_name, context
                        )
                        results.trigger_crucible = true
                        results.crucible_result = crucible_result

                        -- Add crucible narrative to chronicle
                        if crucible_result.chronicle_text then
                            world.world_state:add_chronicle(crucible_result.chronicle_text, {
                                generation = game_state.generation,
                                heir_name = game_state.heir_name,
                                origin = { type = "crucible", heir_name = game_state.heir_name, gen = game_state.generation, detail = crucible_result.trial_name or "Trial" },
                            })
                        end
                    end
                    world.world_state.last_crucible_gen = game_state.generation or 0
                end
            end
        end)
        if not ok then print("Error in WorldController: Crucible/Combat Check: " .. tostring(err)) end
    end

    -- 10b. Great work completion effects
    if results.great_work_completed then
        local ok, err = pcall(function()
            local gw = results.great_work_completed
            local effect = gw.effect or {}

            -- Apply zealotry bonus to religion
            if effect.zealotry_bonus and effect.zealotry_bonus > 0 and world.religion and world.religion.active then
                world.religion.zealotry = math.min(100, (world.religion.zealotry or 0) + effect.zealotry_bonus)
            end

            -- Apply disposition bonus to all factions
            if effect.disposition_bonus and effect.disposition_bonus > 0 then
                world.factions:shift_all_disposition(effect.disposition_bonus)
            end

            -- Flag great work completion for event engine (faction reaction next gen)
            world.world_state._pending_great_work = {
                label = gw.label or gw.id,
                completer = gw.completer or "unknown",
            }
        end)
        if not ok then print("Error in WorldController: Great Work Effects: " .. tostring(err)) end
    end

    -- 11. Religion → faction disposition: zealotry alignment
    -- Factions whose dominant category matches religion tenets get a small disposition boost
    if world.religion and world.religion.active and world.religion.zealotry > 30 then
        local ok, err = pcall(function()
            local tenet_cats = {}
            for _, tenet in ipairs(world.religion.tenets or {}) do
                tenet_cats[tenet.category] = true
            end
            local scale = world.religion.zealotry / 100
            for _, f in ipairs(world.factions:get_active()) do
                local dom = f:get_dominant_category()
                if tenet_cats[dom] then
                    -- Small boost: factions aligned with our religion like us more
                    f:shift_disposition(math.floor(2 * scale))
                end
            end
        end)
        if not ok then print("Error in WorldController: Religion-Faction Alignment: " .. tostring(err)) end
    end

    -- 11. Schism result → world event flag (consumed by event engine next gen)
    if results.religion and results.religion.schism_triggered then
        world.world_state._pending_schism = true
    end

    -- 12. Sync world generation counter
    world.world_state.generation = game_state.generation

    -- 12b. Update Cultural Memory
    pcall(function()
        local cm = game_state.cultural_memory
        local old_avgs = cm:get_category_averages()
        
        -- Black Sheep Multiplier
        local CulturalMemory = require("dredwork_genetics.cultural_memory")
        CulturalMemory._cultural_memory_shift_mult = BlackSheep and BlackSheep.get_shift_multiplier(results.black_sheep) or 1.0
        
        -- Momentum decay resistance
        local bonuses = {}
        if world.momentum then
            for cat, entry in pairs(world.momentum) do
                if type(entry) == "table" and entry.streak >= 3 and entry.direction == "rising" then
                    bonuses[cat] = true
                end
            end
        end
        
        cm:update(game_state.current_heir, bonuses)
        
        -- Calculate shifts for the ledger/chronicle
        local new_avgs = cm:get_category_averages()
        results.cultural_memory_shifts = {
            physical = new_avgs.physical - old_avgs.physical,
            mental = new_avgs.mental - old_avgs.mental,
            social = new_avgs.social - old_avgs.social,
            creative = new_avgs.creative - old_avgs.creative,
        }
    end)

    -- 13. Detect undercurrent patterns and apply roar-level effects
    local ok, err = pcall(function()
        local ok_uc, Undercurrent = pcall(require, "dredwork_world.undercurrent")
        if ok_uc and Undercurrent then
            -- Wire gameState fields Undercurrent.detect needs
            game_state._world_state = world.world_state
            local detected = Undercurrent.detect(game_state)
            results.undercurrents = detected

            -- Log all detected undercurrents to the chronicle
            for _, uc in ipairs(detected) do
                world.world_state:add_chronicle("Systemic Pattern: " .. uc.title .. ". " .. uc.narrative, {
                    origin = { type = "undercurrent", gen = game_state.generation, detail = uc.title }
                })
            end

            -- Undercurrent consequences based on severity
            for _, uc in ipairs(detected) do
                if uc.severity == "roar" then
                    -- Roar: strong mutation pressure
                    local Mutation = require("dredwork_genetics.mutation")
                    Mutation.add_trigger(game_state.mutation_pressure, "undercurrent", 0.5)
                elseif uc.severity == "murmur" then
                    -- Murmur: mild cultural memory drift toward the pattern's category
                    if game_state.cultural_memory and uc.pattern_id then
                        local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[uc.pattern_id:sub(1, 3)]
                        if cat then
                            local prefix = ({ physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" })[cat]
                            for id, priority in pairs(game_state.cultural_memory.trait_priorities) do
                                if id:sub(1, 3) == prefix then
                                    game_state.cultural_memory.trait_priorities[id] =
                                        Math.clamp(priority + 1, 0, 100)
                                end
                            end
                        end
                    end
                end
            end

            -- Flag strongest undercurrent for event engine
            local strongest = Undercurrent.get_strongest(detected)
            if strongest and (strongest.severity == "murmur" or strongest.severity == "roar") then
                world.world_state._pending_undercurrent = {
                    pattern_id = strongest.pattern_id,
                    title = strongest.title,
                    narrative = strongest.narrative,
                    severity = strongest.severity,
                    generation_span = strongest.generation_span,
                }
            end
        end
    end)
    if not ok then print("Error in WorldController: Undercurrent Detection: " .. tostring(err)) end

    -- 13b. Tick Bloodline Dream
    if ok_dream and BloodlineDream then
        pcall(function()
            if not game_state.bloodline_dream then
                -- 10% chance to start a dream if none exists
                if rng.range(1, 100) <= 10 then
                    game_state.bloodline_dream = BloodlineDream.generate(game_state.cultural_memory, game_state.generation, game_state._last_dream_trait, game_state._last_dream_category)
                    if game_state.bloodline_dream then
                        world.world_state:add_chronicle("Ancestral Dream: " .. game_state.bloodline_dream.description, {
                            origin = { type = "dream", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Ancestral Dream" }
                        })
                    end
                end
            else
                local dream = game_state.bloodline_dream
                if dream.status == "active" then
                    -- 1. Check fulfillment
                    local fulfilled, narrative = BloodlineDream.check_fulfillment(dream, game_state.current_heir)
                    if fulfilled then
                        results.dream_fulfilled = true
                        dream.status = "fulfilled"
                        dream.fulfillment_narrative = narrative
                        world.world_state:add_chronicle(narrative, {
                            origin = { type = "dream_fulfilled", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Dream Fulfilled" }
                        })
                        
                        -- Consequences
                        local LP = require("dredwork_world.lineage_power")
                        LP.shift(game_state.lineage_power, 10)
                        game_state.mutation_pressure.value = math.max(0, game_state.mutation_pressure.value - 10)
                    -- 2. Check expiry
                    elseif game_state.generation >= dream.deadline_generation then
                        world.world_state:add_chronicle(BloodlineDream.get_expiry_narrative(), {
                            origin = { type = "dream_expired", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Dream expired" }
                        })
                        -- Mutate into a new dream
                        game_state.bloodline_dream = BloodlineDream.mutate(dream, game_state.cultural_memory, game_state.generation)
                        if game_state.bloodline_dream then
                            world.world_state:add_chronicle("A New Ambition: " .. game_state.bloodline_dream.description, {
                                origin = { type = "dream", heir_name = game_state.heir_name, gen = game_state.generation, detail = "New Ambition" }
                            })
                        end
                    end
                end
            end
        end)
    end

    -- 13c. Tick Holdings (gather passive yields)
    if world.holdings then
        local ok, err = pcall(function()
            local yields = world.holdings:get_yields()
            results.holdings_yields = yields
            
            -- Transfer yields to Resources system
            if world.resources then
                for res_type, amount in pairs(yields) do
                    if amount > 0 then
                        world.resources:change(res_type, amount, "Domain yields")
                    end
                end

                -- Holdings maintenance: large domains cost gold to maintain
                local total_upkeep = 0
                for _, domain in ipairs(world.holdings.domains or {}) do
                    if domain.size and domain.size >= 3 then
                        total_upkeep = total_upkeep + (domain.size - 2)
                    end
                end
                if total_upkeep > 0 then
                    world.resources:change("gold", -total_upkeep, "Domain upkeep",
                        game_state.heir_name, game_state.generation)
                end

                -- Reliquary Wealth Bonus
                if world.reliquary then
                    local rel_effects = world.reliquary:get_effects()
                    if rel_effects.wealth_bonus > 0 then
                        world.resources:change("gold", rel_effects.wealth_bonus, "Artifact tribute")
                    end
                end
                
                -- Sync Gold to Wealth bar (0-100 scale)
                if game_state.wealth then
                    local gold_val = world.resources.gold or 50
                    local current_wealth = game_state.wealth.value or 50
                    local diff = gold_val - current_wealth
                    
                    -- Don't bother with tiny changes
                    if math.abs(diff) > 1 then
                        local Wealth = require("dredwork_world.wealth")
                        -- Apply half the difference to smoothly sync wealth with gold reserves
                        Wealth.change(game_state.wealth, diff * 0.5, "trade", game_state.generation, "Fluctuations in the gold economy")
                    end
                end
            end

            -- Tick holding specialization (organic development)
            if world.holdings and game_state.cultural_memory then
                pcall(function()
                    local spec_narratives = world.holdings:tick_specialization(game_state.cultural_memory)
                    if spec_narratives and #spec_narratives > 0 then
                        results.holding_specializations = spec_narratives
                        for _, sn in ipairs(spec_narratives) do
                            world.world_state:add_chronicle(
                                sn.domain_name .. " developed a " .. sn.specialty_label .. ".",
                                { type = "holdings", detail = sn.domain_name }
                            )
                        end
                    end
                end)
            end

            -- Crisis Check: Resource-based collapses
            if world.resources then
                local starving, cause = world.resources:check_crisis()
                if starving then
                    local debt_whisper = ""
                    if cause == "famine" then
                        local last = world.resources.last_spenders.grain
                        if last then
                            debt_whisper = " A consequence of " .. last.name .. "'s choices in Gen " .. last.generation .. "."
                        end
                        local famine_origin = last and { type = "resource_crisis", heir_name = last.name, gen = last.generation, detail = "Grain depletion" } or nil
                        world.world_state:add_chronicle("The granaries are empty. The people are starving." .. debt_whisper, { origin = famine_origin })
                        world.world_state:add_condition("famine", 0.9, 3)
                        local LP = require("dredwork_world.lineage_power")
                        LP.shift(game_state.lineage_power, -10)
                        -- Trauma taboo: the bloodline remembers starvation
                        if game_state.cultural_memory then
                            game_state.cultural_memory:add_taboo(
                                "famine_collapse", game_state.generation,
                                "will_never_waste_grain", 75)
                        end
                    elseif cause == "vulnerability" then
                        local last = world.resources.last_spenders.steel
                        if last then
                            debt_whisper = " A consequence of " .. last.name .. "'s choices in Gen " .. last.generation .. "."
                        end
                        local vuln_origin = last and { type = "resource_crisis", heir_name = last.name, gen = last.generation, detail = "Steel depletion" } or nil
                        world.world_state:add_chronicle("The armories are empty. The borders are defenseless." .. debt_whisper, { origin = vuln_origin })
                        local LP = require("dredwork_world.lineage_power")
                        LP.shift(game_state.lineage_power, -15)
                        -- War events auto-worsen without steel
                        if world.world_state:has_condition("war") then
                            world.world_state:add_chronicle("Without steel, the war consumed the bloodline's holdings.", {
                                origin = { type = "resource_crisis", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Defenseless during war" }
                            })
                            if world.holdings then world.holdings:damage_random_domain() end
                            LP.shift(game_state.lineage_power, -10)
                        end
                        -- Trauma taboo: the bloodline remembers defenselessness
                        if game_state.cultural_memory then
                            game_state.cultural_memory:add_taboo(
                                "military_collapse", game_state.generation,
                                "will_never_neglect_defenses", 75)
                        end
                    end
                end

                -- Lore crisis: zero lore = cultural stagnation
                if world.resources.lore <= 0 then
                    local last = world.resources.last_spenders.lore
                    local lore_whisper = ""
                    if last then
                        lore_whisper = " A consequence of " .. last.name .. "'s choices in Gen " .. last.generation .. "."
                    end
                    world.world_state:add_chronicle("The libraries are bare. The bloodline forgets what it once knew." .. lore_whisper, {
                        origin = { type = "resource_crisis", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Lore depletion" }
                    })
                    -- Mutation pressure rises without scholarly oversight
                    game_state.mutation_pressure.value = math.min(100, game_state.mutation_pressure.value + 8)
                    -- Cultural memory degrades
                    if game_state.cultural_memory then
                        for id, priority in pairs(game_state.cultural_memory.trait_priorities) do
                            if id:sub(1, 3) == "MEN" then
                                game_state.cultural_memory.trait_priorities[id] =
                                    math.max(0, priority - 3)
                            end
                        end
                    end
                end
            end

            -- Apply World Condition impacts to Resources
            if world.world_state and world.resources then
                -- Pantheon bonuses
                if world.religion and world.religion.pantheon then
                    local p_effects = world.religion:get_world_effects()
                    
                    if p_effects.grain_bonus > 0 then
                        world.resources:change("grain", p_effects.grain_bonus, "Blessing of the Harvest God")
                    end
                    if p_effects.steel_bonus > 0 then
                        world.resources:change("steel", p_effects.steel_bonus, "Blessing of the God of Blades")
                    end
                    if p_effects.lore_bonus > 0 then
                        world.resources:change("lore", p_effects.lore_bonus, "Blessing of the God of Secrets")
                    end

                    -- Abandonment penalty: If God of Rot exists but religion is inactive
                    if not world.religion.active then
                        local has_rot = false
                        for _, god in ipairs(world.religion.pantheon) do
                            if god.domain == "rot" then has_rot = true; break end
                        end
                        if has_rot then
                            -- Abandoned God of Rot makes plague deadlier
                            for _, cond in ipairs(world.world_state.conditions) do
                                if cond.type == "plague" then
                                    cond.intensity = math.min(1.0, cond.intensity + 0.3)
                                end
                            end
                        end
                    else
                        -- Active God of Rot reduces plague intensity
                        if p_effects.plague_intensity_mod ~= 0 then
                             for _, cond in ipairs(world.world_state.conditions) do
                                if cond.type == "plague" then
                                    cond.intensity = math.max(0.1, cond.intensity + p_effects.plague_intensity_mod)
                                end
                            end
                        end
                        -- God of Blades reduces war intensity (shortens wars)
                        if p_effects.war_intensity_mod ~= 0 then
                             for _, cond in ipairs(world.world_state.conditions) do
                                if cond.type == "war" then
                                    cond.intensity = math.max(0.1, cond.intensity + p_effects.war_intensity_mod)
                                end
                            end
                        end
                    end
                end

                for _, cond in ipairs(world.world_state.conditions) do
                    if cond.type == "famine" then
                        world.resources:change("grain", -7 * cond.intensity, "Famine consumption", game_state.heir_name, game_state.generation)
                    elseif cond.type == "war" then
                        world.resources:change("steel", -10 * cond.intensity, "War consumption", game_state.heir_name, game_state.generation)
                        world.resources:change("gold", -8 * cond.intensity, "War costs", game_state.heir_name, game_state.generation)
                    elseif cond.type == "plague" then
                        world.resources:change("gold", -5 * cond.intensity, "Economic stagnation", game_state.heir_name, game_state.generation)
                        world.resources:change("lore", -2 * cond.intensity, "Loss of scholars", game_state.heir_name, game_state.generation)
                    elseif cond.type == "tribute_owed" then
                        local tribute_gold = cond.metadata and cond.metadata.gold_per_gen or 8
                        world.resources:change("gold", -tribute_gold, "Tribute payment", game_state.heir_name, game_state.generation)
                        local creditor_name = cond.metadata and cond.metadata.creditor_faction_id or "unknown"
                        if world.factions then
                            local creditor = world.factions:get(creditor_name)
                            if creditor then creditor_name = creditor.name end
                        end
                        world.world_state:add_chronicle("Tribute of " .. tribute_gold .. " gold paid to " .. creditor_name .. ".", {
                            origin = { type = "tribute", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Tribute to " .. creditor_name }
                        })
                    elseif cond.type == "war_weariness" then
                        -- War weariness: reduced productivity
                        world.resources:change("grain", -3, "War weariness — exhausted labor", game_state.heir_name, game_state.generation)
                        world.resources:change("steel", -2, "War weariness — depleted smiths", game_state.heir_name, game_state.generation)
                    end
                end

                -- Passive recovery floor: prevent total resource death spirals
                -- Grain and gold slowly recover toward a minimum survival threshold
                local grain = world.resources.grain or 0
                if grain < 20 then
                    world.resources:change("grain", math.max(3, math.floor((20 - grain) * 0.3)), "Foraging and rationing")
                end
                local gold = world.resources.gold or 0
                if gold < 10 then
                    world.resources:change("gold", math.max(1, math.floor((10 - gold) * 0.25)), "Scavenging and barter")
                end
                local steel = world.resources.steel or 0
                if steel < 5 then
                    world.resources:change("steel", 1, "Salvage and scrap")
                end
                local lore = world.resources.lore or 0
                if lore < 3 then
                    world.resources:change("lore", 1, "Oral tradition preserves fragments")
                end
            end

            -- Wealth floor from holdings: owning land guarantees minimum wealth
            if world.holdings and #world.holdings.domains > 0 then
                if game_state.wealth and game_state.wealth.value < 35 then
                    local Wealth = require("dredwork_world.wealth")
                    local recovery = math.max(1, math.floor((35 - game_state.wealth.value) * 0.15))
                    Wealth.change(game_state.wealth, recovery, "trade", game_state.generation, "Domain subsistence income")
                end
            end

            -- Crisis Check: Loss of all land (fires ONCE, not every gen)
            if world.holdings and world.holdings.domains and #world.holdings.domains == 0 then
                -- Check if we've already recorded this crisis
                local already_landless = false
                if game_state.cultural_memory and game_state.cultural_memory.taboos then
                    for _, tab in ipairs(game_state.cultural_memory.taboos) do
                        if tab.trigger == "total_landlessness" then
                            already_landless = true
                            break
                        end
                    end
                end
                if not already_landless then
                    local LP = require("dredwork_world.lineage_power")
                    LP.shift(game_state.lineage_power, -20) -- massive loss of standing
                    world.world_state:add_chronicle("The bloodline is landless, wandering the wastes without a home.", {
                        origin = { type = "crisis", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Total landlessness" }
                    })
                    world.world_state:add_condition("exodus", 0.8, 5) -- forced migration
                    -- Trauma taboo: the bloodline will never forget losing everything
                    if game_state.cultural_memory then
                        game_state.cultural_memory:add_taboo(
                            "total_landlessness", game_state.generation,
                            "will_never_surrender_holdings", 95)
                    end
                end
            end
        end)
        if not ok then print("Error in WorldController: Holdings Tick: " .. tostring(err)) end
    end

    -- 13c. Tick Court (betrayals, boons)
    if world.court then
        local ok, err = pcall(function()
            local lp_val = (game_state.lineage_power and game_state.lineage_power.value) or 50
            local w_val = (game_state.wealth and game_state.wealth.value) or 50
            local court_events = world.court:tick(lp_val, w_val, context)
            results.court_events = court_events
            
            for _, ce in ipairs(court_events) do
                -- Apply basic consequence
                if ce.consequence then
                    if ce.consequence.lineage_power_delta and game_state.lineage_power then
                        local LP = require("dredwork_world.lineage_power")
                        LP.shift(game_state.lineage_power, ce.consequence.lineage_power_delta)
                    end
                    if ce.consequence.wealth_delta and game_state.wealth then
                        local Wealth = require("dredwork_world.wealth")
                        Wealth.change(game_state.wealth, ce.consequence.wealth_delta, "court", game_state.generation, ce.text)
                    end
                    if ce.consequence.lose_lore and world.resources then
                        world.resources:change("lore", -ce.consequence.lose_lore, "Court betrayal theft")
                    end
                    if ce.consequence.gain_gold and world.resources then
                        world.resources:change("gold", ce.consequence.gain_gold, "Courtier boon")
                    end
                    -- New: Faction Power Shift (Traitors help the enemy)
                    if ce.consequence.faction_id and ce.consequence.faction_power_delta then
                        local fac = world.factions:get(ce.consequence.faction_id)
                        if fac then
                            fac.power = math.min(100, fac.power + ce.consequence.faction_power_delta)
                        end
                    end
                end
                world.world_state:add_chronicle(ce.text, {
                    origin = { type = "court", heir_name = game_state.heir_name, gen = game_state.generation, detail = ce.type or "Court event" }
                })
            end
        end)
        if not ok then print("Error in WorldController: Court Tick: " .. tostring(err)) end
    end

    -- 13d. Tick Shadow Lineages
    if world.shadow_lineages then
        local ok, err = pcall(function()
            local shadow_events = world.shadow_lineages:tick(game_state.generation, world)
            results.shadow_events = shadow_events
            for _, se in ipairs(shadow_events) do
                if se.type == "cadet_emergence" then
                    world.world_state:add_chronicle(se.text, {
                        origin = { type = "shadow_lineage", gen = game_state.generation, detail = "Shadow house emergence" }
                    })
                    -- Trauma taboo: never trust the traitor's blood
                    if game_state.cultural_memory and se.faction_id then
                        game_state.cultural_memory:add_taboo(
                            "shadow_emergence", game_state.generation,
                            "will_never_ally_with_" .. se.faction_id, 90)
                    end
                end
            end
        end)
        if not ok then print("Error in WorldController: Shadow Lineages Tick: " .. tostring(err)) end
    end

    -- 13e. Tick Active Campaign (Warfare)
    if world.campaign and world.campaign.active then
        local ok, err = pcall(function()
            -- Refresh war condition while campaign is active (with target metadata)
            if world.world_state then
                local war_meta = nil
                if world.campaign.target_faction_id then
                    local target_f = world.factions and world.factions:get(world.campaign.target_faction_id)
                    war_meta = {
                        target_faction_id = world.campaign.target_faction_id,
                        target_faction_name = target_f and target_f.name or "unknown house",
                    }
                end
                world.world_state:add_condition("war", 0.5, 2, war_meta)
            end
            local camp_results = world.campaign:tick(world.resources)
            if camp_results.events then
                for _, ce in ipairs(camp_results.events) do
                    world.world_state:add_chronicle(ce, {
                        origin = { type = "campaign", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Campaign event" }
                    })
                end
            end
            if camp_results.status == "victory" then
                world.world_state:add_chronicle("The campaign concluded in total victory.", {
                    origin = { type = "campaign", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Military victory" }
                })
                local LP = require("dredwork_world.lineage_power")
                if game_state.lineage_power then LP.shift(game_state.lineage_power, 20) end
                -- Victory crushes the target faction's disposition
                if world.campaign.target_faction_id and world.factions then
                    local target = world.factions:get(world.campaign.target_faction_id)
                    if target then target:shift_disposition(-25) end
                end
                -- Record interaction with rival heir
                if world.campaign.target_faction_id and world.rival_heirs then
                    local rival = world.rival_heirs:get(world.campaign.target_faction_id)
                    if rival then
                        local RH = require("dredwork_world.rival_heirs").RivalHeirs
                        RH.record_interaction(rival, game_state.generation, "war_defeat",
                            "Defeated in war by the bloodline.", -25)
                    end
                end
                -- Victory spoils: weaken target faction, gain resources
                if world.campaign.target_faction_id and world.factions then
                    local target = world.factions:get(world.campaign.target_faction_id)
                    if target and target.shift_power then target:shift_power(-15) end
                end
                if world.resources then
                    world.resources:change("gold", 10, "War spoils from victory", game_state.heir_name, game_state.generation)
                    world.resources:change("steel", 5, "Captured arms and materiel", game_state.heir_name, game_state.generation)
                end
                -- Chronicle naming the target faction
                if world.campaign.target_faction_id then
                    local target_f = world.factions and world.factions:get(world.campaign.target_faction_id)
                    local target_name = target_f and target_f.name or world.campaign.target_faction_id
                    world.world_state:add_chronicle("The forces of " .. target_name .. " were broken. Their power diminished, their stores plundered.", {
                        origin = { type = "campaign", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Victory over " .. target_name }
                    })
                end
            elseif camp_results.status == "defeat" then
                world.world_state:add_chronicle("The campaign ended in disaster.", {
                    origin = { type = "campaign", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Military disaster" }
                })
                local LP = require("dredwork_world.lineage_power")
                if game_state.lineage_power then LP.shift(game_state.lineage_power, -20) end
                -- Potentially lose a holding
                if world.holdings then world.holdings:lose_domain() end
                -- Defeat emboldens the target faction
                if world.campaign.target_faction_id and world.factions then
                    local target = world.factions:get(world.campaign.target_faction_id)
                    if target then target:shift_disposition(-10) end -- They grow bolder/hostile
                end
                -- Record interaction with rival heir
                if world.campaign.target_faction_id and world.rival_heirs then
                    local rival = world.rival_heirs:get(world.campaign.target_faction_id)
                    if rival then
                        local RH = require("dredwork_world.rival_heirs").RivalHeirs
                        RH.record_interaction(rival, game_state.generation, "war_victory",
                            "Defeated the bloodline in war.", 15) -- They gain respect/contempt
                    end
                end
                -- Trauma taboo: the bloodline remembers military disaster
                if game_state.cultural_memory then
                    game_state.cultural_memory:add_taboo(
                        "campaign_disaster", game_state.generation,
                        "will_never_wage_reckless_war", 80)
                end
                -- Defeat empowers the victor faction
                if world.campaign.target_faction_id and world.factions then
                    local victor = world.factions:get(world.campaign.target_faction_id)
                    if victor and victor.shift_power then victor:shift_power(15) end
                    -- Victor gains diplomatic standing with all other factions
                    if world.faction_relations then
                        for _, f in ipairs(world.factions:get_all()) do
                            if f.id ~= world.campaign.target_faction_id then
                                world.faction_relations:shift(world.campaign.target_faction_id, f.id, 10,
                                    "Prestige from defeating the bloodline", game_state.generation)
                            end
                        end
                    end
                end
                -- Tribute owed to the victorious faction
                if world.world_state and world.campaign.target_faction_id then
                    world.world_state:add_condition("tribute_owed", 0.5, 3, {
                        creditor_faction_id = world.campaign.target_faction_id,
                        gold_per_gen = 8,
                    })
                end
                -- Victor faction gains a grudge advantage
                if world.campaign.target_faction_id and world.factions then
                    local victor = world.factions:get(world.campaign.target_faction_id)
                    if victor and victor.add_grudge then
                        victor:add_grudge("player", "War victory — the bloodline was broken", game_state.generation, 60)
                    end
                end
            elseif camp_results.status == "stalemate" then
                world.world_state:add_chronicle("The war ground to a bitter stalemate. Neither side could break the other.", {
                    origin = { type = "campaign", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Military stalemate" }
                })
                local LP = require("dredwork_world.lineage_power")
                if game_state.lineage_power then LP.shift(game_state.lineage_power, -5) end
                -- Stalemate slightly reduces hostility (exhaustion on both sides)
                if world.campaign.target_faction_id and world.factions then
                    local target = world.factions:get(world.campaign.target_faction_id)
                    if target then target:shift_disposition(10) end
                end
                -- War weariness from inconclusive campaigns
                if world.world_state then
                    world.world_state:add_condition("war_weariness", 0.4, 2)
                end
            end
        end)
        if not ok then print("Error in WorldController: Campaign Tick: " .. tostring(err)) end
    end

    -- 14. Update wealth (natural decay + event-driven changes happen via apply_consequences)
    local ok, err = pcall(function()
        local Wealth = require("dredwork_world.wealth")
        if not game_state.wealth then game_state.wealth = Wealth.new(50) end
        Wealth.decay(game_state.wealth, game_state.generation)
        results.wealth_tier = Wealth.get_tier(game_state.wealth)
    end)
    if not ok then print("Error in WorldController: Wealth Decay: " .. tostring(err)) end

    -- 15. Update morality (decay + compute lineage reputation)
    local ok, err = pcall(function()
        local MoralityMod = require("dredwork_world.morality")
        if not game_state.morality then game_state.morality = MoralityMod.new(0) end
        MoralityMod.decay(game_state.morality)
        -- Update persistent lineage moral reputation
        game_state.lineage_moral_reputation = MoralityMod.update_lineage_reputation(
            game_state.morality, game_state.lineage_moral_reputation or 0)
        results.moral_standing = MoralityMod.get_standing(game_state.morality)
        results.in_trouble, results.trouble_severity = MoralityMod.check_trouble(game_state.morality)

        -- Tie-in: Morality affects Faction Disposition
        local mor_disp = MoralityMod.disposition_modifier(game_state.morality)
        if mor_disp ~= 0 then
            world.factions:shift_all_disposition(mor_disp)
        end

        -- Tie-in: Morality affects Religion
        if world.religion and world.religion.active then
            if game_state.morality.score > 40 then
                -- Virtuous heir inspires zeal
                world.religion.zealotry = math.min(100, (world.religion.zealotry or 0) + 2)
            elseif game_state.morality.score < -40 then
                -- Sinful heir build schism pressure
                world.religion.schism_pressure = math.min(100, (world.religion.schism_pressure or 0) + 5)
            end
        end

        -- 15a. Zealotry Pressure: high zealotry drains resources (the faith demands)
        if world.religion and world.religion.active then
            local zeal = world.religion.zealotry or 0
            if zeal >= 70 and world.resources then
                local drain = math.floor((zeal - 60) / 10) -- 1 at 70, 2 at 80, 3 at 90, 4 at 100
                world.resources:change("gold", -drain, "Temple maintenance and priestly stipends",
                    game_state.heir_name, generation)
                results.zealotry_gold_drain = drain
            end
            if zeal >= 80 and world.resources then
                world.resources:change("grain", -2, "Ritual offerings and temple feasts",
                    game_state.heir_name, generation)
                results.zealotry_grain_drain = 2
            end
        end

        -- 15b. Check for Bounty (Low Morality penalty)
        local in_trouble, severity = MoralityMod.check_trouble(game_state.morality)
        if in_trouble and rng.range(1, 100) <= 15 then
            -- Check for alliance protection (friendly factions might hide you)
            local protected = false
            if world.factions then
                for _, f in ipairs(world.factions:get_active()) do
                    if f:is_friendly() and rng.range(1, 100) <= 40 then
                        protected = true
                        world.world_state:add_chronicle(f.name .. " shielded the heir from bounty hunters seeking justice for their past acts.", {
                            origin = { type = "bounty", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Faction protection" }
                        })
                        break
                    end
                end
            end

            if not protected then
                local cost = 20
                if world.resources and world.resources.gold >= cost then
                    world.resources:change("gold", -cost, "Bribing bounty hunters")
                    world.world_state:add_chronicle("Bounty hunters were silenced with a heavy purse of gold.", {
                        origin = { type = "bounty", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Bounty bribe" }
                    })
                else
                    -- Scarring: permanent trait damage
                    local Mutation = require("dredwork_genetics.mutation")
                    Mutation.force_mutation(game_state.current_heir, "PHY_VIT", -10, "Bounty Hunter Scar")
                    world.world_state:add_chronicle("Bounty hunters cornered the heir. They survived, but the encounter left deep scars on the bloodline.", {
                        origin = { type = "bounty", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Bounty scarring" }
                    })
                    -- Trauma taboo: the bloodline swears against dark acts
                    if game_state.cultural_memory then
                        game_state.cultural_memory:add_taboo(
                            "bounty_scarring", game_state.generation,
                            "will_never_repeat_cruelty", 85)
                    end
                end
            end
        end
    end)
    if not ok then print("Error in WorldController: Morality Tick: " .. tostring(err)) end

    -- 16. Record heir contribution to lineage ledger
    local ok, err = pcall(function()
        local HeirLedger = require("dredwork_world.heir_ledger")
        if not game_state.heir_ledger then game_state.heir_ledger = {} end

        -- Mandatory Heir Life Event (Autonomous personality-routed moment)
        local HeirEvents = require("dredwork_world.config.heir_events")
        local Crucible = require("dredwork_world.crucible")
        local trial = HeirEvents[rng.range(1, #HeirEvents)]
        local context = WorldController.build_context(world, game_state)
        local life_result = Crucible.run(
            trial, game_state.current_heir, game_state.heir_personality,
            game_state.heir_name, context, true
        )
        results.heir_life_event = life_result
        game_state.heir_life_event = life_result
        -- NOTE: Do NOT set last_crucible_gen here. Life events are autonomous
        -- background moments, not player-facing crucibles. Setting this would
        -- suppress real scene-based crucibles by resetting the gap timer.
        -- Apply consequences from life event (usually cultural shifts)
        if life_result.consequence_def then
            EventEngine.apply_consequences(life_result.consequence_def, context)
        end
        -- Add to chronicle
        world.world_state:add_chronicle(life_result.chronicle_text, {
            origin = { type = "life_event", heir_name = game_state.heir_name, gen = game_state.generation, detail = "Crucible moment" }
        })

        -- Compute cultural deltas from this generation's results
        local cultural_deltas = results.cultural_memory_shifts or nil

        -- Count conditions weathered
        local conditions_weathered = 0
        if world.world_state and world.world_state.conditions then
            for _, cond in ipairs(world.world_state.conditions) do
                if cond.remaining_gens and cond.remaining_gens > 0 then
                    conditions_weathered = conditions_weathered + 1
                end
            end
        end

        -- Dream progress delta (how close this heir got to the dream target)
        local dream_delta = nil
        if game_state.bloodline_dream and game_state.bloodline_dream.status == "active" and game_state.current_heir then
            local dream = game_state.bloodline_dream
            local current_val = game_state.current_heir:get_value(dream.trait_id) or 0
            dream_delta = math.min(1.0, current_val / math.max(1, dream.target_value))
        end

        -- Wealth score for this heir (normalized 0-100)
        local wealth_score = game_state.wealth and game_state.wealth.value or 50

        -- Morality score for this heir (mapped from -100..100 to 0..100)
        local morality_score = 50
        if game_state.morality then
            morality_score = Math.clamp(50 + game_state.morality.score / 2, 0, 100)
        end

        -- 16b. Evaluate for Legend title
        local legend = nil
        if ok_legends and Legends then
            local extra = {
                child_deaths = game_state.child_deaths or 0,
                survived_death_check = game_state.survived_death_check or false,
                is_black_sheep = game_state.is_black_sheep or false,
                cultural_shift = results.cultural_memory_shifts and (math.abs(results.cultural_memory_shifts.physical) + math.abs(results.cultural_memory_shifts.mental) + math.abs(results.cultural_memory_shifts.social) + math.abs(results.cultural_memory_shifts.creative)) or 0,
                faction_shifts = game_state.faction_shifts or 0,
            }
            legend = Legends.evaluate(
                game_state.current_heir,
                game_state.heir_personality,
                game_state.cultural_memory,
                world.world_state,
                {}, -- generation_events (not easily available here, passing empty)
                extra,
                game_state.heir_name
            )
            if legend then
                results.legend = legend
                world.world_state:add_chronicle("Legend Earned: " .. legend.title, {
                    origin = { type = "legend", heir_name = game_state.heir_name, gen = game_state.generation, detail = legend.title }
                })
                
                -- Rewards based on rarity (using internal knowledge of Legend categories/triggers)
                local LP = require("dredwork_world.lineage_power")
                local aura_gain = 0
                local power_gain = 5
                
                if legend.id == "the_monster" or legend.id == "the_breaker" or legend.id == "the_eternal" or legend.id == "the_perfect" then
                    power_gain = 15
                    aura_gain = 50
                elseif legend.category == "rare" or legend.category == "dramatic" then
                    power_gain = 10
                    aura_gain = 25
                end
                
                LP.shift(game_state.lineage_power, power_gain)
                if world.echoes then world.echoes:recharge(aura_gain) end
            end
        end

        -- Compute faction disposition deltas for heir ledger
        results.disposition_changes = {}
        if world.factions then
            pcall(function()
                for _, f in ipairs(world.factions:get_all()) do
                    local delta = (f.disposition or 0) - (old_dispositions[f.id] or 0)
                    if delta ~= 0 then
                        results.disposition_changes[#results.disposition_changes + 1] = {
                            faction_id = f.id,
                            delta = delta,
                        }
                    end
                end
            end)
        end

        -- Count significant faction shifts this generation (disposition crossed ±25 threshold)
        for _, dc in ipairs(results.disposition_changes) do
            if math.abs(dc.delta) >= 25 then
                game_state.faction_shifts = (game_state.faction_shifts or 0) + 1
            end
        end

        -- Count new conditions added this generation
        local new_condition_count = 0
        if world.world_state and world.world_state.conditions then
            new_condition_count = #world.world_state.conditions
        end
        results.conditions_added = math.max(0, new_condition_count - old_condition_count)

        -- Pull events_faced and council_actions from gameState (set by scenes)
        results.events_resolved = game_state.last_gen_events_count or 0
        results.council_actions = game_state.last_gen_council_actions or 0
        game_state.last_gen_events_count = 0
        game_state.last_gen_council_actions = 0

        local Serializer = require("dredwork_genetics.serializer")

        -- Check if this generation already has a ledger entry (founder recorded at game start)
        local existing = HeirLedger.get(game_state.heir_ledger, game_state.generation)

        local entry = HeirLedger.record({
            generation = game_state.generation,
            heir_name = game_state.heir_name or "Unknown",
            legend_title = legend and legend.title or nil,
            era = world.world_state and world.world_state:get_era_name() or "unknown",
            heir = game_state.current_heir,
            genome_data = Serializer.genome_to_table(game_state.current_heir),
            personality_data = game_state.heir_personality and game_state.heir_personality:to_table() or nil,
            trait_priorities = game_state.cultural_memory and game_state.cultural_memory.trait_priorities,
            cultural_deltas = cultural_deltas,
            disposition_deltas = results.disposition_changes,
            conditions_weathered = conditions_weathered,
            conditions_caused = results.conditions_added,
            dream_delta = dream_delta,
            wealth_score = wealth_score,
            morality_score = morality_score,
            events_faced = results.events_resolved or 0,
            council_actions = results.council_actions or 0,
            acts = (function()
                if not game_state.morality then return {} end
                local MoralityRef = require("dredwork_world.morality")
                return MoralityRef.acts_for_generation(game_state.morality, game_state.generation)
            end)(),
        })

        if existing then
            -- Founder was recorded at game start with minimal data — replace with full entry
            for k, v in pairs(entry) do existing[k] = v end
            results.heir_impact = existing
        else
            HeirLedger.append(game_state.heir_ledger, entry)
            results.heir_impact = entry
        end

        -- GHOST COUNCIL: Enshrine legendary/ruinous heirs
        if world.echoes then
            world.echoes:recharge(10)
            local ok_e, err_e = pcall(function()
                local enshrine_data = {
                    name = entry.heir_name,
                    generation = entry.generation,
                    impact_tier = entry.impact_rating,
                    traits = {},
                    mastery_tags = game_state.current_heir.mastery_tags or {}
                }
                for id, t in pairs(game_state.current_heir.traits) do
                    enshrine_data.traits[id] = t:get_value()
                end
                world.echoes:enshrine(enshrine_data)
            end)
            if not ok_e then print("Error in WorldController: Ghost Council Enshrine: " .. tostring(err_e)) end
        end
    end)
    if not ok then print("Error in WorldController: Heir Ledger: " .. tostring(err)) end

    -- 17. Compute lineage power
    local ok, err = pcall(function()
        if LineagePower then
            if not game_state.lineage_power then
                game_state.lineage_power = LineagePower.new()
            end
            -- Build a context snapshot for power computation
            local power_ctx = WorldController.build_context(world, game_state)
            power_ctx.heir_ledger_entry = results.heir_impact
            LineagePower.compute(power_ctx, game_state.lineage_power)
            results.lineage_power = game_state.lineage_power.value
            results.lineage_power_tier = LineagePower.get_tier(game_state.lineage_power)
        end
    end)
    if not ok then print("Error in WorldController: Lineage Power Computation: " .. tostring(err)) end

    -- 17a. Evaluate personality agendas
    local ok, err = pcall(function()
        if game_state.heir_agendas and #game_state.heir_agendas > 0 then
            local PersonalityAgendas = require("dredwork_world.personality_agendas")
            local eval = PersonalityAgendas.evaluate(
                game_state.heir_agendas,
                game_state.last_gen_action_ids or {},
                game_state.last_gen_council_categories or {}
            )
            results.agenda_results = eval
            results.agenda_narratives = {}
            for _, agenda in ipairs(eval.fulfilled) do
                local narrative = PersonalityAgendas.apply_fulfillment(agenda, game_state, world)
                results.agenda_narratives[#results.agenda_narratives + 1] = narrative
            end
            for _, agenda in ipairs(eval.neglected) do
                local narrative = PersonalityAgendas.apply_neglect(agenda, game_state, generation)
                results.agenda_narratives[#results.agenda_narratives + 1] = narrative
            end

            -- Add agenda narratives to chronicle
            for _, narrative in ipairs(results.agenda_narratives) do
                if narrative and narrative ~= "" then
                    world.world_state:add_chronicle(narrative, {
                        generation = game_state.generation,
                        heir_name = game_state.heir_name,
                        origin = { type = "agenda", heir_name = game_state.heir_name, gen = game_state.generation },
                    })
                end
            end
        end
    end)
    if not ok then print("Error in WorldController: Personality Agendas: " .. tostring(err)) end

    -- 17b. Passive Ancestor Echo Invocation
    if world.echoes and #world.echoes.spirits > 0 and world.echoes.aura >= 25 then
        pcall(function()
            if rng.range(1, 100) <= 10 then -- 10% chance per generation
                local invocs = world.echoes:get_invocations(game_state.heir_personality)
                if #invocs > 0 then
                    table.sort(invocs, function(a, b) return a.synergy > b.synergy end)
                    local best = invocs[1]
                    local bonuses = world.echoes:invoke(best.spirit.name, 25)
                    if bonuses then
                        results.echo_bonuses = bonuses
                        results.ancestor_echo_invoked = true
                        world.world_state:add_chronicle("Dynasty Echo: The spirit of " .. best.spirit.name .. " manifested to guide the heir.", {
                            origin = { type = "echo", heir_name = best.spirit.name, gen = best.spirit.generation or game_state.generation, detail = "Ancestral echo" }
                        })
                    end
                end
            end
        end)
    end

    -- 17. Check for Special Special Projects (Apotheosis / Win State)
    local ok, err = pcall(function()
        if world.world_state and world.world_state._pending_apotheosis then
            local Apotheosis = require("dredwork_world.config.apotheosis_mega_project")
            local Crucible = require("dredwork_world.crucible")
            local trials = require("dredwork_world.config.crucible_trials")
            local context = WorldController.build_context(world, game_state)
            
            local trial_tmpl = nil
            for _, t in ipairs(trials) do
                if t.id == Apotheosis.crucible_trial_id then trial_tmpl = t; break end
            end

            if trial_tmpl then
                local ascension_result = Crucible.run(
                    trial_tmpl, game_state.current_heir, game_state.heir_personality,
                    game_state.heir_name, context
                )
                results.apotheosis_result = ascension_result
                world.world_state._pending_apotheosis = nil -- consume

                if ascension_result.outcome == "triumph" then
                    results.game_won = true
                    results.victory_type = "apotheosis"
                end
            end
        end
    end)
    if not ok then print("Error in WorldController: Apotheosis Check: " .. tostring(err)) end

    -- Generation 100 hard cap: force apotheosis if not already won
    if not results.game_won and game_state.generation and game_state.generation >= 100 then
        results.game_won = true
        results.victory_type = "apotheosis"
    end

    if world.culture and world.resources and world.culture:has_custom("scholarly_tradition") then
        world.resources:change("lore", 5, "Scholarly Tradition")
    end

    -- 18. Check for Milestones
    if Milestones then
        local ms_context = {
            generation = game_state.generation,
            start_era = world.world_state.start_era_key,
            current_era = world.world_state.current_era_key,
            conditions = world.world_state.conditions,
            heir_genome = game_state.current_heir,
            mutation_count = results.mutation_count or 0,
            factions = world.factions,
            faction_shifts = game_state.faction_shifts or 0,
            milestone_count = game_state.milestone_count or 0,
            cultural_memory = game_state.cultural_memory,
            reputation_changed = game_state.reputation_changed,
            reputation_locked_gens = game_state.reputation_locked_gens,
            era_shifted = results.world_advance and results.world_advance.era_shifted,
            heir_death_chance = game_state.heir_death_chance,
            heir_died = game_state.heir_died,
            surviving_children = game_state.surviving_children,
            total_children_attempted = game_state.total_children_attempted,
            is_black_sheep = game_state.is_black_sheep,
            near_extinction = game_state.near_extinction,
            has_legend = (results.heir_impact and results.heir_impact.impact_rating == "Legendary"),
            mental_priority_high_gens = game_state.mental_priority_high_gens,
            physical_priority_high_gens = game_state.physical_priority_high_gens,
            dream_fulfilled = results.dream_fulfilled,
            has_ascending_momentum = (function()
                if not world.momentum then return false end
                for _, m in pairs(world.momentum) do
                    if type(m) == "table" and m.direction == "rising" and m.streak >= 3 then return true end
                end
                return false
            end)(),
            has_fossil_restoration = results.fossil_restored,
            has_ancestor_echo = results.ancestor_echo_invoked,
        }

        game_state.achieved_milestones = game_state.achieved_milestones or {}
        local new_ms = Milestones.check(ms_context, game_state.achieved_milestones)
        if #new_ms > 0 then
            results.milestones = new_ms
            local LP = require("dredwork_world.lineage_power")
            for _, ms in ipairs(new_ms) do
                table.insert(game_state.achieved_milestones, ms.id)
                game_state.milestone_count = (game_state.milestone_count or 0) + 1
                world.world_state:add_chronicle("Dynasty Milestone: " .. ms.title, {
                    origin = { type = "milestone", heir_name = game_state.heir_name, gen = game_state.generation, detail = ms.title }
                })
                -- Reward: +5 power per milestone
                if game_state.lineage_power then
                    LP.shift(game_state.lineage_power, 5)
                end
            end
        end
    end

    -- Win condition milestones: chronicle entries at generation landmarks
    local gen = game_state.generation or 1
    local landmark_messages = {
        [10] = "The bloodline has endured ten generations. The blood remembers what names forget.",
        [25] = "Twenty-five generations. The weight of history presses deeper into the marrow.",
        [30] = "Thirty generations. The Weight begins to press. From here, every heir carries the accumulated burden of those who came before. Survival grows harder.",
        [50] = "Half a hundred generations. The bloodline has outlasted kingdoms. The genome strains under the weight of its own history.",
        [75] = "Seventy-five generations. The blood is ancient now, thick with memory. Few bloodlines endure this long. Fewer still endure what comes next.",
        [100] = "One hundred generations. The bloodline has transcended mortality itself.",
    }
    if landmark_messages[gen] then
        world.world_state:add_chronicle(landmark_messages[gen], {
            origin = { type = "landmark", heir_name = game_state.heir_name, gen = gen, detail = "Generation " .. gen .. " landmark" }
        })
    end

    -- Breeding plateau acknowledgment at Gen 10
    if gen == 10 then
        world.world_state:add_chronicle(
            "Bloodline Wisdom: The family's traits have settled into recognizable patterns. " ..
            "From here, progress demands deliberate cultivation — not chance.", {
            origin = { type = "bloodline_wisdom", heir_name = game_state.heir_name, gen = gen, detail = "Breeding plateau reached" }
        })
    end

    -- Compute mortality risk for visibility (does NOT roll — just computes the number)
    pcall(function()
        if game_state.current_heir and game_state.heir_personality then
            local conditions = world.world_state and world.world_state.conditions or {}
            local Viability = require("dredwork_genetics.viability")
            -- Temporarily compute without rolling by using the formula directly
            local genome = game_state.current_heir
            local personality = game_state.heir_personality
            local vitality = (genome:get_value("PHY_VIT") or 50) / 100
            local longevity = (genome:get_value("PHY_LON") or 50) / 100
            local immune = (genome:get_value("PHY_IMM") or 50) / 100
            local willpower = (genome:get_value("MEN_WIL") or 50) / 100
            local composure = (genome:get_value("MEN_COM") or 50) / 100
            local boldness = (personality:get_axis("PER_BLD") or 50) / 100
            local volatility = (personality:get_axis("PER_VOL") or 50) / 100

            local death_chance = 0.02
            if gen and gen <= 3 then death_chance = 0.01
            elseif gen and gen > 30 then
                local weight_bonus = math.min(0.07, (gen - 30) * 0.002)
                death_chance = death_chance + weight_bonus
            end
            local risk_lines = {}

            -- The Weight: show generational burden as a risk factor
            if gen and gen > 30 then
                local weight_pct = math.floor(math.min(7, (gen - 30) * 0.2))
                if weight_pct >= 1 then
                    risk_lines[#risk_lines + 1] = { source = "The Weight (Gen " .. gen .. ")", pct = weight_pct }
                end
            end

            for _, cond in ipairs(conditions) do
                local intensity = cond.intensity or 0.5
                if cond.type == "plague" then
                    local risk = intensity * 0.05 * (1 - immune * 0.7)
                    death_chance = death_chance + risk
                    if risk > 0.01 then risk_lines[#risk_lines + 1] = { source = "Plague", pct = math.floor(risk * 100) } end
                elseif cond.type == "war" then
                    local risk = intensity * 0.08 * (0.5 + boldness * 0.5)
                    death_chance = death_chance + risk
                    if risk > 0.01 then risk_lines[#risk_lines + 1] = { source = "War", pct = math.floor(risk * 100) } end
                elseif cond.type == "famine" then
                    local frailty = 1 - vitality
                    local risk = intensity * 0.04 * (0.3 + frailty * 0.7)
                    death_chance = death_chance + risk
                    if risk > 0.01 then risk_lines[#risk_lines + 1] = { source = "Famine", pct = math.floor(risk * 100) } end
                end
            end

            if vitality < 0.25 then
                local risk = (0.25 - vitality) * 0.15
                death_chance = death_chance + risk
                risk_lines[#risk_lines + 1] = { source = "Low Vitality (" .. math.floor(vitality * 100) .. ")", pct = math.floor(risk * 100) }
            end
            if longevity < 0.20 then
                local risk = (0.20 - longevity) * 0.10
                death_chance = death_chance + risk
                risk_lines[#risk_lines + 1] = { source = "Low Longevity (" .. math.floor(longevity * 100) .. ")", pct = math.floor(risk * 100) }
            end
            if willpower < 0.15 and volatility > 0.80 then
                death_chance = death_chance + 0.04
                risk_lines[#risk_lines + 1] = { source = "Madness risk", pct = 4 }
            end

            local cap = (gen and gen <= 3) and 0.08 or 0.45
            if death_chance > cap then death_chance = cap end

            results.mortality_risk = {
                pct = math.floor(death_chance * 100),
                risk_lines = risk_lines,
            }
        end
    end)

    return results
end

--- Generate a generation-closing chronicle entry.
---@param world table world context
---@param game_state table GeneticsController state
---@param event_narratives table array of narrative strings from resolved events
---@param world_results table|nil optional results from advance_generation
---@param old_heir_data table|nil optional snapshot of the outgoing heir
---@return string chronicle text
function WorldController.generate_chronicle(world, game_state, event_narratives, world_results, old_heir_data)
    if not world.world_state then return "" end
    local all_narratives = {}

    -- 1. Get all fragments added to the world state this generation
    local gen = world.world_state.generation
    if world.world_state.chronicle then
        for _, entry in ipairs(world.world_state.chronicle) do
            if entry.generation == gen and entry.text then
                table.insert(all_narratives, entry.text)
            end
        end
    end

    -- 2. Event narratives from player choices are already stored in
    -- world_state.chronicle by resolve_event() (line ~420), so they were
    -- collected in step 1. No need to add them again.

    -- 3. Add Faction events (if not already chronicled by fragments)
    if world_results and world_results.faction_events then
        for _, fe in ipairs(world_results.faction_events) do
            local fa = world.factions:get(fe.faction_a)
            local fb = world.factions:get(fe.faction_b)
            local name_a = fa and fa.name or "A house"
            local name_b = fb and fb.name or "another"

            local text = nil
            if fe.type == "faction_alliance_formed" then
                text = name_a .. " and " .. name_b .. " forged a blood-pact."
            elseif fe.type == "faction_war_declared" then
                text = "Steel was drawn between " .. name_a .. " and " .. name_b .. "."
            end
            if text then
                table.insert(all_narratives, text)
                world.world_state:add_chronicle(text, { generation = gen })
            end
        end
    end

    -- 4. Add Rival Heir events (if not already chronicled)
    if world_results and world_results.rival_heir_events then
        for _, re in ipairs(world_results.rival_heir_events) do
            if (re.type == "rival_death" or re.type == "rival_succession") and re.text then
                table.insert(all_narratives, re.text)
                world.world_state:add_chronicle(re.text, { generation = gen })
            end
        end
    end

    -- Return compact summary for in-game display (no prose generation).
    -- The Soul Teller on bloodweight.com generates the literary chronicle
    -- from the raw fragments and heir data.
    if #all_narratives == 0 then
        return "A quiet generation. Nothing of note was recorded."
    end
    return table.concat(all_narratives, "\n")
end

--- Generate faction-affiliated mate candidates.
--- 2-3 of count candidates come from active factions.
---@param world table world context
---@param game_state table GeneticsController state
---@param count number total candidates to generate (default 4)
---@return table array of { faction_id, faction_name, category_bias, personality_bias }
function WorldController.get_faction_mate_info(world, game_state, count)
    count = count or 4
    local active = world.factions:get_active()
    if #active == 0 then return {} end

    local cm = game_state.cultural_memory
    local faction_count = math.min(count - 1, #active) -- at least 1 non-faction candidate
    faction_count = math.max(1, faction_count)

    -- War reduces faction mate availability (travel is dangerous)
    if world.world_state then
        for _, cond in ipairs(world.world_state.conditions or {}) do
            if cond.type == "war" and faction_count > 1 then
                faction_count = faction_count - 1
                break
            end
        end
    end

    local mates = {}
    local used = {}

    for i = 1, faction_count do
        -- Pick a faction, avoid duplicates
        local faction = nil
        for _ = 1, 10 do
            local idx = rng.range(1, #active)
            if not used[active[idx].id] then
                faction = active[idx]
                used[faction.id] = true
                break
            end
        end

        if faction then
            -- Check if this faction is taboo-blocked or too hostile for mating
            local taboo_key = "will_never_ally_with_" .. faction.id
            local disposition = faction.disposition or 0
            if cm and cm:is_taboo(taboo_key) then
                -- Skip this faction (taboo-blocked)
            elseif disposition <= -50 then
                -- Deeply hostile factions refuse to send mates
                -- (forced marriages from events bypass this via get_faction_mate_info_locked)
            else
                local mate_info = {
                    faction_id = faction.id,
                    faction_name = faction.name,
                    faction_obj = faction,
                    category_bias = faction:get_dominant_category(),
                    personality_bias = faction.personality,
                    disposition = faction.disposition,
                    trait_hints = {},  -- living world alignment hints
                }

                -- Dream alignment: if faction's category matches dream category
                local dream = game_state.bloodline_dream
                if dream and dream.status == "active" then
                    local faction_cat = faction:get_dominant_category()
                    if faction_cat == dream.category then
                        mate_info.trait_hints[#mate_info.trait_hints + 1] = {
                            type = "dream",
                            trait_id = dream.trait_id,
                            trait_name = dream.trait_name,
                            label = "Dream-aligned",
                        }
                    end
                end

                -- Fossil alignment: if faction's category matches a fossil's category
                pcall(function()
                    local ok_tf, TraitFossils = pcall(require, "dredwork_world.trait_fossils")
                    if ok_tf and TraitFossils and game_state.trait_peaks and game_state.current_heir then
                        local fossils = TraitFossils.detect(game_state.trait_peaks, game_state.current_heir)
                        if #fossils > 0 then
                            local fossil = fossils[1]
                            local prefix_to_cat = {
                                PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative",
                            }
                            local fossil_cat = prefix_to_cat[fossil.trait_id:sub(1, 3)]
                            if fossil_cat and faction:get_dominant_category() == fossil_cat then
                                mate_info.trait_hints[#mate_info.trait_hints + 1] = {
                                    type = "fossil",
                                    trait_id = fossil.trait_id,
                                    trait_name = fossil.trait_name,
                                    label = "May restore " .. fossil.trait_name,
                                }
                            end
                        end
                    end
                end)

                -- Momentum alignment: if faction's category is ascending
                if game_state.momentum then
                    local faction_cat = faction:get_dominant_category()
                    local entry = game_state.momentum[faction_cat]
                    if entry and type(entry) == "table"
                       and entry.direction == "rising" and entry.streak >= 3 then
                        mate_info.trait_hints[#mate_info.trait_hints + 1] = {
                            type = "momentum",
                            category = faction_cat,
                            label = "Riding " .. faction_cat:upper() .. " momentum",
                        }
                    end
                end

                mates[#mates + 1] = mate_info
            end
        end
    end

    return mates
end

--- Generate mate info locked to a single faction (arranged marriage).
--- All candidates come from the specified faction.
---@param world table world context
---@param game_state table GeneticsController state
---@param count number total candidate count
---@param faction_id string faction to lock to
---@return table array of faction mate info
function WorldController.get_faction_mate_info_locked(world, game_state, count, faction_id)
    count = count or 4
    local faction = world.factions:get(faction_id)
    if not faction then
        -- Faction doesn't exist (removed/dead), fall back to normal
        return WorldController.get_faction_mate_info(world, game_state, count)
    end

    local mates = {}
    local base_info = {
        faction_id = faction.id,
        faction_name = faction.name,
        faction_obj = faction,
        category_bias = faction:get_dominant_category(),
        personality_bias = faction.personality,
        disposition = faction.disposition,
        trait_hints = {},
    }

    -- Dream alignment
    local dream = game_state.bloodline_dream
    if dream and dream.status == "active" then
        local faction_cat = faction:get_dominant_category()
        if faction_cat == dream.category then
            base_info.trait_hints[#base_info.trait_hints + 1] = {
                type = "dream",
                trait_id = dream.trait_id,
                trait_name = dream.trait_name,
                label = "Dream-aligned",
            }
        end
    end

    -- Fossil alignment (parity with get_faction_mate_info)
    pcall(function()
        local ok_tf, TraitFossils = pcall(require, "dredwork_world.trait_fossils")
        if ok_tf and TraitFossils and game_state.trait_peaks and game_state.current_heir then
            local fossils = TraitFossils.detect(game_state.trait_peaks, game_state.current_heir)
            if #fossils > 0 then
                local fossil = fossils[1]
                local prefix_to_cat = {
                    PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative",
                }
                local fossil_cat = prefix_to_cat[fossil.trait_id:sub(1, 3)]
                if fossil_cat and faction:get_dominant_category() == fossil_cat then
                    base_info.trait_hints[#base_info.trait_hints + 1] = {
                        type = "fossil",
                        trait_id = fossil.trait_id,
                        trait_name = fossil.trait_name,
                        label = "May restore " .. fossil.trait_name,
                    }
                end
            end
        end
    end)

    -- Momentum alignment (parity with get_faction_mate_info)
    if game_state.momentum then
        local faction_cat = faction:get_dominant_category()
        local entry = game_state.momentum[faction_cat]
        if entry and type(entry) == "table"
           and entry.direction == "rising" and entry.streak >= 3 then
            base_info.trait_hints[#base_info.trait_hints + 1] = {
                type = "momentum",
                category = faction_cat,
                label = "Riding " .. faction_cat:upper() .. " momentum",
            }
        end
    end

    -- All candidates from this faction
    for i = 1, count do
        local info = {}
        for k, v in pairs(base_info) do
            if type(v) == "table" then
                local copy = {}
                for kk, vv in pairs(v) do copy[kk] = vv end
                info[k] = copy
            else
                info[k] = v
            end
        end
        -- Copy trait_hints array properly
        info.trait_hints = {}
        for _, h in ipairs(base_info.trait_hints) do
            local hc = {}
            for kk, vv in pairs(h) do hc[kk] = vv end
            info.trait_hints[#info.trait_hints + 1] = hc
        end
        mates[#mates + 1] = info
    end

    return mates
end

--- Compute nurture modifiers for a newborn.
---@param world table world context
---@param game_state table GeneticsController state
---@return table array of { source, trait, bonus, description }
function WorldController.compute_nurture(world, game_state)
    if not Nurture then return {} end
    local ok, mods = pcall(Nurture.compute,
        world.world_state,
        game_state.cultural_memory,
        world.world_state and world.world_state.current_era_key or nil,
        world.discoveries,
        world.culture
    )
    if not ok then mods = {} end

    -- Religion nurture: zealotry provides bonuses based on tenets
    if world.religion and world.religion.active and world.religion.zealotry > 40 then
        pcall(function()
            local bonuses = world.religion:get_bonuses() -- returns { [trait_id] = bonus }
            for trait_id, bonus in pairs(bonuses) do
                if bonus > 0 then
                    mods[#mods + 1] = {
                        source = "religion",
                        trait = trait_id,
                        bonus = bonus,
                        description = "Raised in " .. (ok_rel and Religion.display_name(world.religion.name) or world.religion.name or "the faith") .. ".",
                        origin = { type = "religion", detail = world.religion.name or "Faith" }
                    }
                end
            end
        end)
    end

    -- Culture nurture: customs provide small bonuses
    if world.culture then
        pcall(function()
            local custom_bonuses = {
                trial_by_combat = { trait = "PHY_STR", bonus = 2, desc = "Trial by combat shapes the young." },
                scholarly_tradition = { trait = "MEN_INT", bonus = 2, desc = "Scholarship is expected." },
                diplomatic_code = { trait = "SOC_NEG", bonus = 2, desc = "Diplomacy is a birthright." },
                artisan_guilds = { trait = "CRE_CRA", bonus = 2, desc = "Craft is taught before letters." },
            }
            for _, c in ipairs(world.culture.customs or {}) do
                local cb = custom_bonuses[c.id]
                if cb then
                    mods[#mods + 1] = {
                        source = "culture",
                        trait = cb.trait,
                        bonus = cb.bonus,
                        description = cb.desc,
                        origin = { type = "culture", detail = c.label or c.id }
                    }
                end
            end
        end)
    end

    -- Discovery nurture: already handled by Nurture.compute() which receives
    -- world.discoveries as a parameter. Adding origin tags to those entries instead.
    for _, mod in ipairs(mods) do
        if mod.source == "discovery" and not mod.origin then
            mod.origin = { type = "discovery", detail = "Ancient Knowledge" }
        end
    end

    -- Reliquary nurture: artifact-derived bonuses
    if world.reliquary then
        pcall(function()
            local rel_effects = world.reliquary:get_effects()
            for trait_id, bonus in pairs(rel_effects.trait_bonuses or {}) do
                if bonus > 0 then
                    -- Try to find which artifact provided this specific trait
                    local art_name = "Ancestral Artifacts"
                    for _, art in ipairs(world.reliquary.artifacts or {}) do
                        if art.effect and art.effect.trait_bonus and art.effect.trait_bonus[trait_id] then
                            art_name = art.name; break
                        end
                    end

                    mods[#mods + 1] = {
                        source = "reliquary",
                        trait = trait_id,
                        bonus = bonus,
                        description = "Blessed by ancestral artifacts.",
                        origin = { type = "reliquary", detail = art_name }
                    }
                end
            end
        end)
    end

    -- Great Works nurture: completed monuments provide lasting bonuses
    if world.great_works then
        pcall(function()
            local gw_effects = world.great_works:get_effects()
            for trait_id, bonus in pairs(gw_effects.trait_bonuses or {}) do
                if bonus > 0 then
                    -- Find which great work provided this bonus
                    local gw_name = "Ancestral Monuments"
                    for _, work in ipairs(world.great_works.completed or {}) do
                        if work.effect and work.effect.trait_bonus and work.effect.trait_bonus[trait_id] then
                            gw_name = work.label or work.id; break
                        end
                    end

                    mods[#mods + 1] = {
                        source = "great_work",
                        trait = trait_id,
                        bonus = bonus,
                        description = "Raised in the shadow of " .. gw_name .. ".",
                        origin = { type = "great_work", detail = gw_name }
                    }
                end
            end
        end)
    end

    -- Resource nurture: abundance/scarcity effects
    if world.resources then
        pcall(function()
            local res_mods = world.resources:compute_nurture_modifiers()
            for _, rm in ipairs(res_mods) do
                mods[#mods + 1] = {
                    source = "resources",
                    trait = rm.trait,
                    bonus = rm.bonus,
                    description = rm.description,
                    origin = { type = "resources", detail = "Family Reserves" }
                }
            end
        end)
    end

    -- Holdings nurture: land-based upbringing bonuses
    if world.holdings then
        pcall(function()
            local hold_mods = world.holdings:compute_nurture_modifiers()
            for _, hm in ipairs(hold_mods) do
                mods[#mods + 1] = {
                    source = "holdings",
                    trait = hm.trait,
                    bonus = hm.bonus,
                    description = hm.description,
                    origin = { type = "holdings", detail = "Ancestral Domains" }
                }
            end
        end)
    end

    -- Momentum nurture: streak-based effects
    if world.momentum and Momentum then
        pcall(function()
            local mom_mods = Momentum.compute_nurture_modifiers(world.momentum)
            for _, mm in ipairs(mom_mods) do
                mods[#mods + 1] = {
                    source = "momentum",
                    trait = mm.trait,
                    bonus = mm.bonus,
                    description = mm.description,
                    origin = { type = "momentum", detail = "Blood Tradition" }
                }
            end
        end)
    end

    -- Near-death scar nurture: parent's brush with death marks the next generation
    if game_state.near_death_scar then
        pcall(function()
            local scar = game_state.near_death_scar
            mods[#mods + 1] = {
                source = "near_death",
                trait = "MEN_WIL",
                bonus = 3,
                description = "Raised by a parent scarred by " .. (scar.cause or "death") .. ". The young learn vigilance.",
                origin = { type = "near_death", detail = game_state.heir_name or "The Heir" }
            }
        end)
    end

    -- Re-cap at 5 modifiers if religion/culture added more
    if #mods > 5 then
        table.sort(mods, function(a, b) return a.bonus > b.bonus end)
        local capped = {}
        for i = 1, 5 do capped[i] = mods[i] end
        mods = capped
    end

    return mods
end

--- Apply nurture modifiers to a genome.
---@param genome table Genome
---@param modifiers table array from compute_nurture()
function WorldController.apply_nurture(genome, modifiers)
    if not Nurture then return end
    pcall(Nurture.apply, genome, modifiers)
end

--- Serialize the world state for saving.
---@param world table world context
---@return table
function WorldController.to_table(world)
    local data = {
        world_state = world.world_state:to_table(),
        factions = world.factions:to_table(),
    }
    if world.faction_relations then
        data.faction_relations = world.faction_relations:to_table()
    end
    if world.rumors then
        data.rumors = world.rumors:to_table()
    end
    if world.discoveries then
        data.discoveries = world.discoveries:to_table()
    end
    if world.religion then
        data.religion = world.religion:to_table()
    end
    if world.culture then
        data.culture = world.culture:to_table()
    end
    if world.great_works then
        data.great_works = world.great_works:to_table()
    end
    if world.rival_heirs then
        data.rival_heirs = world.rival_heirs:to_table()
    end
    if world.holdings then
        data.holdings = world.holdings:to_table()
    end
    if world.reliquary then
        data.reliquary = world.reliquary:to_table()
    end
    if world.court then
        data.court = world.court:to_table()
    end
    if world.resources then
        data.resources = world.resources:to_table()
    end
    if world.echoes then
        data.echoes = world.echoes:to_table()
    end
    if world.shadow_lineages then
        data.shadow_lineages = world.shadow_lineages:to_table()
    end
    if world.momentum then
        data.momentum = Momentum.to_table(world.momentum)
    end
    if world.campaign and Campaign then
        data.campaign = Campaign.to_table(world.campaign)
    end
    if world.nemesis and NemesisMod then
        data.nemesis = world.nemesis:to_table()
    end
    return data
end

--- Restore world state from saved data.
---@param data table
---@return table world context
function WorldController.from_table(data)
    local ctx = {
        world_state = WorldState.from_table(data.world_state or {}),
        factions = FactionManager.from_table(data.factions or {}),
        event_engine = EventEngine.new(),
    }
    if FactionRelations and data.faction_relations then
        ctx.faction_relations = FactionRelations.from_table(data.faction_relations)
    elseif FactionRelations then
        ctx.faction_relations = FactionRelations.new(ctx.factions)
    end
    if Rumors and data.rumors then
        ctx.rumors = Rumors.from_table(data.rumors)
    elseif Rumors then
        ctx.rumors = Rumors.new()
    end
    if Discoveries and data.discoveries then
        ctx.discoveries = Discoveries.from_table(data.discoveries)
    elseif Discoveries then
        ctx.discoveries = Discoveries.new()
    end
    if Religion and data.religion then
        ctx.religion = Religion.from_table(data.religion)
    elseif Religion then
        ctx.religion = Religion.new()
    end
    if Culture and data.culture then
        ctx.culture = Culture.from_table(data.culture)
    elseif Culture then
        ctx.culture = Culture.new()
    end
    if GreatWorks and data.great_works then
        ctx.great_works = GreatWorks.from_table(data.great_works)
    elseif GreatWorks then
        ctx.great_works = GreatWorks.new()
    end
    if RivalHeirManager and data.rival_heirs then
        ctx.rival_heirs = RivalHeirManager.from_table(data.rival_heirs)
    elseif RivalHeirManager then
        ctx.rival_heirs = RivalHeirManager.new()
    end
    if Momentum and data.momentum then
        ctx.momentum = Momentum.from_table(data.momentum)
    elseif Momentum then
        ctx.momentum = Momentum.new()
    end
    local Holdings = require("dredwork_world.holdings")
    if Holdings and data.holdings then
        ctx.holdings = Holdings.from_table(data.holdings)
    elseif Holdings then
        ctx.holdings = Holdings.new()
    end
    local Reliquary = require("dredwork_world.reliquary")
    if Reliquary and data.reliquary then
        ctx.reliquary = Reliquary.from_table(data.reliquary)
    elseif Reliquary then
        ctx.reliquary = Reliquary.new()
    end
    local Court = require("dredwork_world.court")
    if Court and data.court then
        ctx.court = Court.from_table(data.court)
    elseif Court then
        ctx.court = Court.new()
    end
    local Resources = require("dredwork_world.resources")
    if Resources and data.resources then
        ctx.resources = Resources.from_table(data.resources)
    elseif Resources then
        ctx.resources = Resources.new()
    end
    local Echoes = require("dredwork_world.echoes")
    if Echoes and data.echoes then
        ctx.echoes = Echoes.from_table(data.echoes)
    elseif Echoes then
        ctx.echoes = Echoes.new()
    end
    local ShadowLineages = require("dredwork_world.shadow_lineage")
    if ShadowLineages and data.shadow_lineages then
        ctx.shadow_lineages = ShadowLineages.from_table(data.shadow_lineages)
    elseif ShadowLineages then
        ctx.shadow_lineages = ShadowLineages.new()
    end
    local Campaign = require("dredwork_world.campaign")
    if Campaign and data.campaign then
        ctx.campaign = Campaign.from_table(data.campaign)
    elseif Campaign then
        ctx.campaign = Campaign.new()
    end
    if NemesisMod and data.nemesis then
        ctx.nemesis = NemesisMod.from_table(data.nemesis)
    elseif NemesisMod then
        ctx.nemesis = NemesisMod.new(nil)
    end
    return ctx
end

return WorldController
