local Math = require("dredwork_core.math")
-- Dark Legacy — Council System
-- One strategic action per generation. The player's proactive agency.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")
local council_actions = require("dredwork_world.config.council_actions")
local ok_br, blood_rites = pcall(require, "dredwork_world.config.blood_rites")
if not ok_br then blood_rites = {} end

-- Optional modules (pcall-wrapped)
local ok_sc, StatCheck = pcall(require, "dredwork_world.stat_check")
if not ok_sc then StatCheck = nil end
local ok_doc, Doctrines = pcall(require, "dredwork_world.doctrines")
if not ok_doc then Doctrines = nil end

local CAT_TO_PREFIX = { physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" }
local CAT_LABELS = { physical = "BODY", mental = "MIND", social = "WORD", creative = "ART" }

local Council = {}

-- Build combined action pool once (static config data)
local _combined_pool = nil
local function get_combined_pool()
    if _combined_pool then return _combined_pool end
    _combined_pool = {}
    for _, a in ipairs(council_actions) do _combined_pool[#_combined_pool + 1] = a end
    for _, a in ipairs(blood_rites) do
        -- Wrap blood rites with category tag without mutating source data
        local wrapped = setmetatable({ is_blood_rite = true, category = a.category or "faith" }, { __index = a })
        _combined_pool[#_combined_pool + 1] = wrapped
    end
    return _combined_pool
end

--- Get all council actions for this generation with availability info.
--- Returns all actions; unavailable ones are marked with available=false and gated_reason.
---@param context table { heir_personality, cultural_memory, factions, world_state, great_works, discoveries, heir_genome }
---@return table array of action definitions with available and gated_reason fields
function Council.get_available_actions(context)
    local EventEngine = require("dredwork_world.event_engine")
    local all_actions = {}
    local combined_pool = get_combined_pool()

    for _, action in ipairs(combined_pool) do
        local eligible = true
        local gated_reason = nil
        local hidden = false

        -- Personality gate
        if action.requires and context.heir_personality then
            local val = context.heir_personality:get_axis(action.requires.axis)
            if action.requires.min and val < action.requires.min then
                eligible = false
                gated_reason = EventEngine.get_gate_reason(action.requires)
            elseif action.requires.max and val > action.requires.max then
                eligible = false
                gated_reason = EventEngine.get_gate_reason(action.requires)
            end
        end

        -- Personality hard blocks (extreme personality prevents action entirely)
        if eligible and action.personality_blocks and context.heir_personality then
            for _, block in ipairs(action.personality_blocks) do
                local val = context.heir_personality:get_axis(block.axis)
                if block.min and val >= block.min then
                    eligible = false
                    gated_reason = block.reason or "The heir's nature forbids this."
                    break
                end
                if block.max and val <= block.max then
                    eligible = false
                    gated_reason = block.reason or "The heir's nature forbids this."
                    break
                end
            end
        end

        -- Reputation gate
        if eligible and action.requires_reputation and context.cultural_memory then
            if context.cultural_memory.reputation.primary ~= action.requires_reputation
               and context.cultural_memory.reputation.secondary ~= action.requires_reputation then
                eligible = false
                gated_reason = "Your reputation does not grant access to this..."
            end
        end

        -- Taboo block
        if eligible and action.blocked_by_taboo and context.cultural_memory then
            if context.cultural_memory:is_taboo(action.blocked_by_taboo) then
                eligible = false
                gated_reason = "A taboo of the bloodline forbids this."
            end
        end

        -- Great work gate: hide "commission" if one is already in progress
        if eligible and action.system_action == "start_great_work" then
            if context.great_works and context.great_works.in_progress then
                eligible = false
                gated_reason = "A great work is already under construction."
            end
        end

        -- Blood Rite Cost gate
        if eligible and action.requires_cost and context.heir_genome then
            local cost_def = action.requires_cost
            if cost_def.trait then
                local val = context.heir_genome:get_value(cost_def.trait) or 50
                if val <= cost_def.cost then
                    eligible = false
                    gated_reason = "Bloodline lacks the vitality to survive this rite."
                end
            elseif cost_def.traits then
                local all_ok = true
                for _, t in ipairs(cost_def.traits) do
                    local val = context.heir_genome:get_value(t) or 50
                    if val <= cost_def.cost then all_ok = false; break end
                end
                if not all_ok then
                    eligible = false
                    gated_reason = "Bloodline lacks the physical substance for this sacrifice."
                end
            end
        end

        -- World Condition gate (existing + no_condition)
        if eligible and action.requires_condition and context.world_state then
            if not context.world_state:has_condition(action.requires_condition) then
                eligible = false
                gated_reason = "Requires the world to be experiencing " .. action.requires_condition:upper() .. "."
            end
        end
        if eligible and action.requires_no_condition and context.world_state then
            if context.world_state:has_condition(action.requires_no_condition) then
                eligible = false
                gated_reason = "Cannot be done while " .. action.requires_no_condition:upper() .. " grips the world."
            end
        end

        -- Religion gate: actions that require an active faith
        -- Hidden from menu entirely (player can't change this mid-generation)
        if eligible and action.requires_religion_active then
            if not context.religion or not context.religion.active then
                eligible = false
                gated_reason = "The bloodline follows no faith. A religion must emerge first."
                hidden = true
            end
        end

        -- Zealotry gate: blood rites and high-faith actions require minimum zealotry
        if eligible and action.requires_zealotry_min then
            local zealotry = 0
            if context.religion and context.religion.zealotry then
                zealotry = context.religion.zealotry
            end
            if zealotry < action.requires_zealotry_min then
                eligible = false
                gated_reason = "The faith lacks fervor. Requires zealotry " .. action.requires_zealotry_min .. "+."
            end
        end

        -- Era gate: some actions only available in specific eras
        -- Hidden from menu (player can't change era mid-generation)
        if eligible and action.requires_era then
            local current_era = context.world_state and context.world_state.current_era_key or "ancient"
            local era_ok = false
            for _, era in ipairs(action.requires_era) do
                if era == current_era then era_ok = true; break end
            end
            -- Zealotry 80+ overrides era restriction (desperate faith transcends the age)
            if not era_ok then
                local zealotry = context.religion and context.religion.zealotry or 0
                if zealotry >= 80 then
                    era_ok = true
                end
            end
            if not era_ok then
                eligible = false
                local era_names = table.concat(action.requires_era, "/")
                gated_reason = "This rite demands a darker age (" .. era_names .. ")."
                hidden = true
            end
        end

        -- Generation gate: actions that require a minimum number of generations
        -- Hidden from menu entirely (player can't change this mid-generation)
        if eligible and action.requires_generation_min then
            local gen = context.generation or (context.world_state and context.world_state.generation) or 1
            if gen < action.requires_generation_min then
                eligible = false
                gated_reason = "The bloodline is too young. Requires Gen " .. action.requires_generation_min .. "."
                hidden = true
            end
        end

        -- Resource gates
        local res = context.resources
        if eligible and action.requires_gold_min and res then
            if res.gold < action.requires_gold_min then
                eligible = false
                gated_reason = "Insufficient Gold (need " .. action.requires_gold_min .. ")."
            end
        end
        if eligible and action.requires_steel_min and res then
            if res.steel < action.requires_steel_min then
                eligible = false
                gated_reason = "Insufficient Steel (need " .. action.requires_steel_min .. ")."
            end
        end
        if eligible and action.requires_grain_min and res then
            if res.grain < action.requires_grain_min then
                eligible = false
                gated_reason = "Insufficient Grain (need " .. action.requires_grain_min .. ")."
            end
        end
        if eligible and action.requires_lore_min and res then
            if res.lore < action.requires_lore_min then
                eligible = false
                gated_reason = "Insufficient Lore (need " .. action.requires_lore_min .. ")."
            end
        end

        -- Morality gates
        if eligible and action.requires_morality_min and context.morality then
            local score = context.morality.score or 0
            if score < action.requires_morality_min then
                eligible = false
                gated_reason = "The bloodline's reputation is too dark for this. Requires moral standing " .. action.requires_morality_min .. "+."
            end
        end
        if eligible and action.requires_morality_max and context.morality then
            local score = context.morality.score or 0
            if score > action.requires_morality_max then
                eligible = false
                gated_reason = "The bloodline is too righteous for this. Requires moral standing below " .. action.requires_morality_max .. "."
            end
        end

        -- Holdings gate
        if eligible and action.requires_holdings_min and context.holdings then
            if #context.holdings.domains < action.requires_holdings_min then
                eligible = false
                gated_reason = "Requires owning at least " .. action.requires_holdings_min .. " domains."
            end
        end

        if eligible and action.requires_target_holding and context.holdings then
            if #context.holdings.domains == 0 then
                eligible = false
                gated_reason = "Requires at least one holding to develop."
            end
        end

        -- Faction Disposition gate
        if eligible and action.requires_target_faction and (action.requires_disposition_min or action.requires_disposition_max) then
            -- Note: this only works if a target is ALREADY selected, 
            -- but for the menu, we should check if ANY faction qualifies.
            local any_qualifies = false
            for _, f in ipairs(context.factions:get_all()) do
                local disp = f.disposition
                local ok = true
                if action.requires_disposition_min and disp < action.requires_disposition_min then ok = false end
                if action.requires_disposition_max and disp > action.requires_disposition_max then ok = false end
                if ok then any_qualifies = true; break end
            end
            if not any_qualifies then
                eligible = false
                gated_reason = "No target house meets the diplomatic requirements."
            end
        end

        -- Discovery gate
        if eligible and action.requires_discovery then
            local has_disc = false
            if context.discoveries and context.discoveries.unlocked then
                has_disc = context.discoveries.unlocked[action.requires_discovery] ~= nil
            end
            if not has_disc then
                eligible = false
                gated_reason = "Requires the discovery of " .. action.requires_discovery:gsub("_", " "):upper() .. "."
            end
        end

        -- Flexible Resource gate (table form)
        if eligible and action.requires_resources and context.resources then
            local res_req = action.requires_resources
            if context.resources[res_req.type] < (res_req.min or 0) then
                eligible = false
                gated_reason = "Insufficient " .. res_req.type:upper() .. " (need " .. res_req.min .. ")."
            end
        end

        -- Living world gates: actions require specific world state
        -- All hidden when unavailable (player can't change these mid-generation)
        if eligible and action.system_action == "start_apotheosis" then
            local Apotheosis = require("dredwork_world.config.apotheosis_mega_project")
            local val = context.heir_genome:get_value(Apotheosis.required_trait) or 0
            if val < Apotheosis.required_trait_min then
                eligible = false
                gated_reason = "Heir must possess at least " .. Apotheosis.required_trait_min .. " " .. Apotheosis.required_trait:gsub("MEN_", "") .. "."
                hidden = true
            end
            if eligible and context.resources.lore < Apotheosis.resource_costs.lore then
                eligible = false
                gated_reason = "Requires " .. Apotheosis.resource_costs.lore .. " Lore sacrifice."
                hidden = true
            end
            if eligible and context.holdings then
                local has_temple = false
                for _, d in ipairs(context.holdings.domains) do
                    if d.type == Apotheosis.required_holding_type then has_temple = true; break end
                end
                if not has_temple then
                    eligible = false
                    gated_reason = "Requires a Temple to focus the energies."
                    hidden = true
                end
            end
        end

        if eligible and action.system_action == "canonize_ancestor" then
            local has_temple = false
            if context.holdings then
                for _, d in ipairs(context.holdings.domains) do
                    if d.type == "temple" then has_temple = true; break end
                end
            end
            if not has_temple then
                eligible = false
                gated_reason = "Requires a Temple to enshrine the new god."
                hidden = true
            elseif context.echoes and #context.echoes.spirits == 0 then
                eligible = false
                gated_reason = "There are no Legendary Ancestral Echoes to deify."
                hidden = true
            end
        end

        if eligible and action.system_action == "pursue_dream" then
            if not context.bloodline_dream or context.bloodline_dream.status ~= "active" then
                eligible = false
                gated_reason = "The bloodline has no active dream to pursue."
                hidden = true
            end
        end

        if eligible and action.system_action == "restore_fossil" then
            local has_fossils = false
            pcall(function()
                local ok_tf, TraitFossils = pcall(require, "dredwork_world.trait_fossils")
                if ok_tf and TraitFossils and context.trait_peaks and context.heir_genome then
                    local fossils = TraitFossils.detect(context.trait_peaks, context.heir_genome)
                    has_fossils = #fossils > 0
                end
            end)
            if not has_fossils then
                eligible = false
                gated_reason = "No lost greatness to reclaim. The bloodline holds steady."
                hidden = true
            end
        end

        if eligible and action.system_action == "ride_momentum" then
            local has_ascending = false
            if context.momentum then
                for _, entry in pairs(context.momentum) do
                    if type(entry) == "table" and entry.direction == "rising" and entry.streak >= 3 then
                        has_ascending = true
                        break
                    end
                end
            end
            if not has_ascending then
                eligible = false
                gated_reason = "No ascending momentum to ride. The bloodline drifts."
                hidden = true
            end
        end

        if eligible and action.system_action == "suppress_undercurrent" then
            local has_undercurrent = false
            if context.undercurrent_streaks then
                for _, streak in pairs(context.undercurrent_streaks) do
                    if streak and streak > 0 then
                        has_undercurrent = true
                        break
                    end
                end
            end
            if not has_undercurrent then
                eligible = false
                gated_reason = "No hidden patterns stir beneath the surface."
                hidden = true
            end
        end

        -- Shadow lineage gate: negotiate requires at least one hidden branch
        if eligible and action.system_action == "negotiate_shadow" then
            local has_shadow = false
            if context.shadow_lineages and context.shadow_lineages.branches then
                for _, branch in ipairs(context.shadow_lineages.branches) do
                    if branch.status == "hidden" then
                        has_shadow = true
                        break
                    end
                end
            end
            if not has_shadow then
                eligible = false
                gated_reason = "No exiled branches exist to negotiate with."
                hidden = true
            end
        end

        -- Campaign gates: reinforce requires active, launch requires inactive
        if eligible and action.system_action == "reinforce_campaign" then
            if not context.campaign or not context.campaign.active then
                eligible = false
                gated_reason = "No military campaign is currently active."
                hidden = true
            end
        end
        if eligible and action.system_action == "start_campaign" then
            if context.campaign and context.campaign.active then
                eligible = false
                gated_reason = "A military campaign is already underway."
            end
        end

        -- Exile courtier gate: requires court with at least one active member
        if eligible and action.system_action == "exile_courtier" then
            local has_court = false
            if context.court and context.court.members then
                for _, m in ipairs(context.court.members) do
                    if m.status == "active" then
                        has_court = true
                        break
                    end
                end
            end
            if not has_court then
                eligible = false
                gated_reason = "The court is empty. There is no one left to exile."
                hidden = true
            end
        end

        -- Commune with ancestors gate: requires enshrined echoes with enough aura
        if eligible and action.system_action == "commune_ancestors" then
            local can_commune = false
            if context.echoes and #context.echoes.spirits > 0 and context.echoes.aura >= 15 then
                can_commune = true
            end
            if not can_commune then
                eligible = false
                if not context.echoes or #context.echoes.spirits == 0 then
                    gated_reason = "No ancestors have left strong enough echoes to invoke."
                else
                    gated_reason = "Insufficient ancestral aura (need 15+)."
                end
                hidden = not context.echoes or #context.echoes.spirits == 0
            end
        end

        -- Investigate rumor gate: requires active rumors
        if eligible and action.system_action == "investigate_rumor" then
            local has_rumors = false
            if context.rumors and context.rumors.active then
                has_rumors = #context.rumors.active > 0
            end
            if not has_rumors then
                eligible = false
                gated_reason = "No rumors circulate to investigate."
                hidden = true
            end
        end

        -- Lineage power gate
        if eligible and action.requires_lineage_power_min then
            local power_val = context.lineage_power and context.lineage_power.value or 45
            if power_val < action.requires_lineage_power_min then
                eligible = false
                gated_reason = "Your house lacks the authority (need power " .. action.requires_lineage_power_min .. "+)"
            end
        end

        -- Wealth gate
        if eligible and action.requires_wealth_min then
            local wealth_val = context.wealth and context.wealth.value or 50
            if wealth_val < action.requires_wealth_min then
                eligible = false
                gated_reason = "The bloodline lacks the wealth (need wealth " .. action.requires_wealth_min .. "+)"
            end
        end
        if eligible and action.requires_wealth_max then
            local wealth_val = context.wealth and context.wealth.value or 50
            if wealth_val > action.requires_wealth_max then
                eligible = false
                gated_reason = "The bloodline's wealth makes this unnecessary."
            end
        end

        -- Religion gate: religious actions require active religion
        if eligible and (action.system_action == "religious_decree" or action.system_action == "challenge_faith") then
            if not context.religion or not context.religion.active then
                eligible = false
                gated_reason = "The bloodline follows no faith."
            end
        end

        -- Culture gate: culture actions require culture system
        if eligible and (action.system_action == "enforce_custom" or action.system_action == "cultural_reform") then
            if not context.culture then
                eligible = false
                gated_reason = "No cultural traditions exist to enforce or reform."
            end
            if eligible and action.system_action == "cultural_reform" and context.culture then
                if not context.culture.customs or #context.culture.customs == 0 then
                    eligible = false
                    gated_reason = "No customs exist to reform."
                end
            end
        end

        -- Urgency tagging: context-aware action prioritization
        local urgency = nil
        if eligible then
            pcall(function()
                local res = context.resources
                -- Critical resource shortages → resource-fixing actions are urgent
                if res then
                    if res.grain <= 5 and (action.id == "granary_reserve" or action.id == "trade_agreement" or action.id == "consolidate") then
                        urgency = "CRITICAL"
                    end
                    if res.steel <= 3 and action.id == "arm_the_holdings" then urgency = "CRITICAL" end
                    if res.gold <= 5 and (action.id == "consolidate" or action.id == "trade_agreement") then
                        urgency = urgency or "CRITICAL"
                    end
                    if res.lore <= 3 and (action.id == "forge_discovery" or action.id == "consolidate") then
                        urgency = urgency or "URGENT"
                    end
                end
                -- Hostile factions → diplomatic/warfare actions are urgent
                if context.factions then
                    local hostile_count = 0
                    for _, f in ipairs(context.factions:get_all()) do
                        if f:is_hostile() and f.status ~= "fallen" then hostile_count = hostile_count + 1 end
                    end
                    if hostile_count >= 2 and (action.id == "seek_alliance" or action.id == "fortify_border") then
                        urgency = urgency or "URGENT"
                    end
                    if hostile_count >= 3 and action.id == "feast_of_tribute" then
                        urgency = urgency or "URGENT"
                    end
                end
                -- Active conditions → condition-responsive actions
                if context.world_state then
                    if context.world_state:has_condition("war") and (action.id == "fortify_border" or action.id == "scorched_earth" or action.id == "reinforce_campaign") then
                        urgency = urgency or "URGENT"
                    end
                    if context.world_state:has_condition("famine") and (action.id == "granary_reserve" or action.id == "trade_agreement") then
                        urgency = urgency or "CRITICAL"
                    end
                    if context.world_state:has_condition("plague") and action.id == "consolidate" then
                        urgency = urgency or "URGENT"
                    end
                end
                -- Ascending momentum → ride it
                if context.momentum then
                    for _, entry in pairs(context.momentum) do
                        if type(entry) == "table" and entry.direction == "rising" and entry.streak >= 3 then
                            if action.id == "ride_momentum" then urgency = "TIMELY" end
                            break
                        end
                    end
                end
            end)
        end

        -- Generate cost display string
        local costs = {}
        if action.requires_gold_min then table.insert(costs, tostring(action.requires_gold_min) .. " GOLD") end
        if action.requires_steel_min then table.insert(costs, tostring(action.requires_steel_min) .. " STEEL") end
        if action.requires_lore_min then table.insert(costs, tostring(action.requires_lore_min) .. " LORE") end
        if action.requires_grain_min then table.insert(costs, tostring(action.requires_grain_min) .. " GRAIN") end
        if action.requires_cost then
            local c = action.requires_cost
            local traitName = c.trait and c.trait:gsub(".*_", "") or "BLOOD"
            table.insert(costs, tostring(c.cost) .. " " .. traitName)
        end
        local cost_display = #costs > 0 and table.concat(costs, " / ") or "FREE"

        all_actions[#all_actions + 1] = {
            id = action.id,
            category = action.category,
            label = action.label,
            description = action.description,
            requires = action.requires,
            requires_reputation = action.requires_reputation,
            requires_target_faction = action.requires_target_faction,
            requires_category_choice = action.requires_category_choice,
            narrative = action.narrative,
            consequences = action.consequences,
            consequences_fail = action.consequences_fail,
            stat_check = action.stat_check,
            system_action = action.system_action,
            blocked_by_taboo = action.blocked_by_taboo,
            personality_blocks = action.personality_blocks,
            requires_lineage_power_min = action.requires_lineage_power_min,
            requires_wealth_min = action.requires_wealth_min,
            requires_wealth_max = action.requires_wealth_max,
            requires_condition = action.requires_condition,
            available = eligible,
            gated_reason = gated_reason,
            hidden = hidden,
            cost_display = cost_display,
            urgency = urgency,
        }
    end

    return all_actions
end

--- Execute a council action and apply consequences.
---@param action table the chosen action definition
---@param context table { world_state, factions, cultural_memory, mutation_pressure, generation, heir_personality, heir_genome, discoveries, great_works }
---@param target_faction_id string|nil faction ID if action targets a specific faction
---@param chosen_category string|nil chosen category key for requires_category_choice actions
---@param target_holding_id string|nil holding ID if action targets a specific holding
---@return table effects { narrative, consequence_lines, stat_check, ... }
function Council.execute(action, context, target_faction_id, chosen_category, target_holding_id)
    local effects = { narrative = action.narrative or "" }
    local lines = {}  -- consequence visibility lines

    -- Pay Blood Rite Cost (Permanent Trait Degradation)
    if action.requires_cost and context.heir_genome then
        local cost_def = action.requires_cost
        if cost_def.trait then
            local trait = context.heir_genome:get_trait(cost_def.trait)
            if trait then
                trait:set_value(math.max(0, trait:get_value() - cost_def.cost))
                -- Force a negative mutation to permanently scar the lineage
                local Mutation = require("dredwork_genetics.mutation")
                Mutation.force_mutation(context.heir_genome, cost_def.trait, -cost_def.cost, "Blood Sacrifice")
                lines[#lines + 1] = { text = "Permanently sacrificed " .. cost_def.cost .. " " .. cost_def.trait:gsub(".*_", ""), color_key = "negative" }
                context.world_state:add_chronicle("Blood Rite: The heir sacrificed their own vitality (" .. cost_def.trait:gsub(".*_", "") .. ") to empower the bloodline.")
            end
        elseif cost_def.traits then
            for _, t_id in ipairs(cost_def.traits) do
                local trait = context.heir_genome:get_trait(t_id)
                if trait then
                    trait:set_value(math.max(0, trait:get_value() - cost_def.cost))
                    local Mutation = require("dredwork_genetics.mutation")
                    Mutation.force_mutation(context.heir_genome, t_id, -cost_def.cost, "Blood Sacrifice")
                    lines[#lines + 1] = { text = "Permanently sacrificed " .. cost_def.cost .. " " .. t_id:gsub(".*_", ""), color_key = "negative" }
                end
            end
            context.world_state:add_chronicle("Blood Rite: A great physical sacrifice was made to enact the council's will.")
        end
    end

    -- Evaluate stat check if present
    local check_passed = true
    if action.stat_check and StatCheck and context.heir_genome then
        -- Compute wild attribute bonuses (same as event resolution path)
        local wild_bonuses = nil
        local ok_bio, HeirBiography = pcall(require, "dredwork_world.heir_biography")
        if ok_bio and HeirBiography then
            pcall(function()
                local wa = HeirBiography.get_wild_attributes(
                    context.heir_genome, context.heir_personality
                )
                wild_bonuses = HeirBiography.wild_bonuses(wa)
            end)
        end
        -- Holdings defense bonus: more domains = better physical stat checks
        if context.holdings and context.holdings.domains then
            pcall(function()
                local domain_count = #context.holdings.domains
                if domain_count >= 2 then
                    if not wild_bonuses then wild_bonuses = {} end
                    wild_bonuses.physical = (wild_bonuses.physical or 0) + math.min(8, domain_count * 2)
                end
            end)
        end
        local rel_effects = context.reliquary and context.reliquary:get_effects() or nil
        -- Merge discovery trait bonuses into stat check bonuses
        if context.discoveries then
            pcall(function()
                local disc_effects = context.discoveries:get_effects()
                if disc_effects and disc_effects.trait_bonuses then
                    if not rel_effects then rel_effects = { trait_bonuses = {} } end
                    if not rel_effects.trait_bonuses then rel_effects.trait_bonuses = {} end
                    for trait_id, bonus in pairs(disc_effects.trait_bonuses) do
                        rel_effects.trait_bonuses[trait_id] = (rel_effects.trait_bonuses[trait_id] or 0) + bonus
                    end
                end
            end)
        end
        local result = StatCheck.evaluate(
            context.heir_genome,
            action.stat_check,
            context.heir_personality,
            context.cultural_memory,
            wild_bonuses,
            context.momentum,
            rel_effects,
            nil, -- rival_heir
            context.echo_bonuses,
            context.culture,
            context.generation,
            context.morality
        )
        check_passed = result.success
        effects.stat_check = result
        effects.stat_check_quality = StatCheck.get_quality(result)

        local quality = effects.stat_check_quality
        local quality_labels = {
            triumph = "TRIUMPH", success = "SUCCESS",
            failure = "FAILURE", disaster = "DISASTER",
        }
        local quality_colors = {
            triumph = "special", success = "positive",
            failure = "negative", disaster = "negative",
        }
        local margin_sign = result.margin >= 0 and "+" or ""
        lines[#lines + 1] = {
            text = (quality_labels[quality] or "CHECK") .. " — Your " .. result.score .. " vs " .. result.difficulty .. " (" .. margin_sign .. result.margin .. ")",
            color_key = quality_colors[quality] or "neutral",
        }
    end

    -- Select consequences based on check result
    local consequences
    if check_passed then
        consequences = action.consequences
    else
        consequences = action.consequences_fail or action.consequences
        -- Override narrative for failure if consequences_fail has one
        if action.consequences_fail and action.consequences_fail.narrative then
            effects.narrative = action.consequences_fail.narrative
        end
    end

    if not consequences then
        effects.consequence_lines = lines
        return effects
    end

    -- System actions: wire council to real game systems
    if check_passed and action.system_action then
        Council._execute_system_action(action.system_action, context, target_faction_id, lines, effects)
    end

    -- Mutation triggers
    if consequences.mutation_triggers then
        local Mutation = require("dredwork_genetics.mutation")
        for _, mt in ipairs(consequences.mutation_triggers) do
            Mutation.add_trigger(context.mutation_pressure, mt.type, mt.intensity or 1.0)
            lines[#lines + 1] = {
                text = "Mutation pressure stirs (" .. (mt.type or "unknown") .. ")",
                color_key = "special",
            }
        end
    end

    -- Disposition changes
    if consequences.disposition_changes and context.factions then
        -- Doctrine: marriage_disposition_bonus adds extra to marriage-related actions
        local marriage_bonus = 0
        if Doctrines and action.id == "diplomatic_marriage" then
            marriage_bonus = Doctrines.get_modifier(
                { doctrines = context.doctrines or {} }, "marriage_disposition_bonus")
        end

        for _, dc in ipairs(consequences.disposition_changes) do
            local delta = dc.delta
            if dc.faction_id == "_target" and marriage_bonus > 0 then
                delta = delta + marriage_bonus
            end
            if action.id == "seek_alliance" and context.culture and context.culture:has_custom("diplomatic_code") then
                delta = delta + 10 -- social_bonus_on_alliance
            end

            if dc.faction_id == "all" then
                context.factions:shift_all_disposition(delta)
                local sign = delta >= 0 and "+" or ""
                lines[#lines + 1] = {
                    text = "All factions: " .. sign .. tostring(delta),
                    color_key = delta >= 0 and "positive" or "negative",
                }
            elseif dc.faction_id == "_target" and target_faction_id then
                local f = context.factions:get(target_faction_id)
                if f then
                    f:shift_disposition(delta)
                    local sign = delta >= 0 and "+" or ""
                    lines[#lines + 1] = {
                        text = f.name .. ": " .. sign .. tostring(delta),
                        color_key = delta >= 0 and "positive" or "negative",
                    }
                end
            end
        end
    end

    -- Cultural memory shift
    if consequences.cultural_memory_shift then
        for cat, delta in pairs(consequences.cultural_memory_shift) do
            local prefix = CAT_TO_PREFIX[cat]
            if prefix then
                -- Count traits in this category to distribute delta evenly
                local trait_count = 0
                for id, _ in pairs(context.cultural_memory.trait_priorities) do
                    if id:sub(1, 3) == prefix then trait_count = trait_count + 1 end
                end
                local per_trait = trait_count > 0 and (delta / trait_count) or 0
                for id, priority in pairs(context.cultural_memory.trait_priorities) do
                    if id:sub(1, 3) == prefix then
                        context.cultural_memory.trait_priorities[id] =
                            Math.clamp(priority + per_trait, 0, 100)
                    end
                end
                if delta ~= 0 then
                    local direction = delta > 0 and "rises" or "falls"
                    lines[#lines + 1] = {
                        text = "The bloodline shifts: " .. (CAT_LABELS[cat] or cat:upper()) .. " " .. direction,
                        color_key = "neutral",
                    }
                end
            end
        end
    end

    -- Cultural memory shift for chosen category (invest in next gen, etc.)
    if consequences.cultural_memory_shift_chosen and chosen_category then
        local prefix = CAT_TO_PREFIX[chosen_category]
        local delta = consequences.cultural_memory_shift_chosen
        if prefix and delta ~= 0 then
            for id, priority in pairs(context.cultural_memory.trait_priorities) do
                if id:sub(1, 3) == prefix then
                    context.cultural_memory.trait_priorities[id] =
                        Math.clamp(priority + delta, 0, 100)
                end
            end
            local direction = delta > 0 and "rises" or "falls"
            lines[#lines + 1] = {
                text = "The bloodline shifts: " .. (CAT_LABELS[chosen_category] or chosen_category:upper()) .. " " .. direction,
                color_key = "neutral",
            }
        end
    end

    -- Add relationship
    if consequences.add_relationship and target_faction_id then
        context.cultural_memory:add_relationship(
            target_faction_id,
            consequences.add_relationship.type,
            context.generation,
            consequences.add_relationship.strength or 60,
            consequences.add_relationship.reason or "council_action"
        )
        local rel_type = consequences.add_relationship.type
        local f = context.factions and context.factions:get(target_faction_id)
        local fname = f and f.name or target_faction_id
        if rel_type == "ally" then
            lines[#lines + 1] = {
                text = "Bond forged: ally with " .. fname,
                color_key = "positive",
            }
        else
            lines[#lines + 1] = {
                text = "Enmity declared: enemy of " .. fname,
                color_key = "negative",
            }
        end
    end

    -- Offspring stat boost (stored in context for matchmaking/breeding phase)
    if consequences.offspring_boost then
        local boost = {}
        for k, v in pairs(consequences.offspring_boost) do boost[k] = v end
        -- SOC_TEA amplifies offspring education: high teaching heir makes nurture more effective
        if boost.amount and context.heir_genome then
            local teaching = context.heir_genome:get_value("SOC_TEA") or 50
            if teaching >= 70 then
                local extra = math.floor((teaching - 60) / 10)
                boost.amount = boost.amount + extra
                lines[#lines + 1] = {
                    text = "The heir's teaching ability amplifies the investment (+" .. extra .. ")",
                    color_key = "special",
                }
            end
        end
        effects.offspring_boost = boost
        lines[#lines + 1] = {
            text = "The next generation will be shaped by this",
            color_key = "special",
        }
    end

    -- Faction info reveal — intel advantage: disposition boost + rival power drain
    if consequences.reveal_faction_info and target_faction_id then
        effects.reveal_faction_info = target_faction_id
        local f = context.factions and context.factions:get(target_faction_id)
        local fname = f and f.name or target_faction_id
        if f then
            -- Intel gives diplomatic leverage: +10 disposition (knowledge breeds respect/fear)
            f.disposition = (f.disposition or 0) + 10
            lines[#lines + 1] = {
                text = "Secrets of " .. fname .. " revealed (+10 leverage)",
                color_key = "positive",
            }
            -- Sap rival's hidden strength
            if f.power then
                f.power = math.max(0, f.power - 5)
                lines[#lines + 1] = {
                    text = fname .. " weakened by exposed secrets",
                    color_key = "neutral",
                }
            end
        else
            lines[#lines + 1] = {
                text = "Secrets of " .. fname .. " revealed",
                color_key = "neutral",
            }
        end
    end

    -- Resource Change
    if consequences.resource_change and context.resources then
        local changes = consequences.resource_change
        if changes.type then changes = { changes } end -- Handle single object vs array

        for _, rc in ipairs(changes) do
            context.resources:change(rc.type, rc.delta, rc.reason or action.label, context.heir_name, context.generation)
            local sign = rc.delta >= 0 and "+" or ""
            local amount = tostring(math.abs(math.floor(rc.delta)))
            lines[#lines + 1] = {
                text = rc.type:upper() .. " " .. sign .. amount,
                color_key = rc.delta >= 0 and "positive" or "negative",
            }
        end
    end

    -- Holding Size Increase
    if consequences.holding_size_increase and context.holdings and target_holding_id then
        local holding = nil
        for _, h in ipairs(context.holdings.domains) do
            if h.id == target_holding_id then
                holding = h
                break
            end
        end

        if holding then
            local amount = consequences.holding_size_increase.amount or 1
            if holding.status == "ruined" then
                -- Restore ruined domain instead of just growing it
                holding.status = "active"
                holding.size = 1
                lines[#lines + 1] = {
                    text = holding.name .. " restored from ruins",
                    color_key = "positive",
                }
            else
                holding.size = holding.size + amount
                lines[#lines + 1] = {
                    text = holding.name .. " size increased by " .. tostring(amount),
                    color_key = "positive",
                }
            end
        end
    end

    -- Wealth change
    if consequences.wealth_change and context.wealth then
        pcall(function()
            local Wealth = require("dredwork_world.wealth")
            local wc = consequences.wealth_change
            Wealth.change(context.wealth, wc.delta or 0, wc.source or "council",
                context.generation or 0, wc.description or action.label)
            local tier = Wealth.get_tier(context.wealth)
            local sign = (wc.delta or 0) >= 0 and "+" or ""
            lines[#lines + 1] = {
                text = "Wealth " .. sign .. tostring(math.floor(wc.delta or 0)) .. " (" .. tier.label .. ")",
                color_key = (wc.delta or 0) >= 0 and "positive" or "negative",
            }
        end)
    end

    -- Lineage Power shift
    if consequences.lineage_power_shift and context.lineage_power then
        pcall(function()
            local LP = require("dredwork_world.lineage_power")
            local delta = consequences.lineage_power_shift
            LP.shift(context.lineage_power, delta)
            local tier = LP.get_tier(context.lineage_power)
            local sign = delta >= 0 and "+" or ""
            lines[#lines + 1] = {
                text = "Power " .. sign .. tostring(delta) .. " (" .. tier.label .. ")",
                color_key = delta >= 0 and "positive" or "negative",
            }
        end)
    end

    -- Moral act
    if consequences.moral_act and context.morality then
        pcall(function()
            local MoralityMod = require("dredwork_world.morality")
            local ma = consequences.moral_act
            MoralityMod.record_act(context.morality, ma.act_id, context.generation or 0, ma.description)
            lines[#lines + 1] = {
                text = "Moral act: " .. (ma.description or ma.act_id):gsub("_", " "),
                color_key = (context.morality.score >= 0) and "neutral" or "negative",
            }
        end)
    end

    -- Remove condition (blood rite consequence)
    if consequences.remove_condition and context.world_state then
        pcall(function()
            context.world_state:remove_condition(consequences.remove_condition)
            lines[#lines + 1] = {
                text = (consequences.remove_condition or ""):upper() .. " has been lifted",
                color_key = "positive",
            }
        end)
    end

    -- Faction power shift (blood rite consequence — no target_faction, affects nemesis faction)
    if consequences.faction_power_shift and not consequences.target_faction then
        pcall(function()
            if context.rival_heirs and context.factions then
                local nemesis = context.rival_heirs:get_nemesis()
                if nemesis and nemesis.faction_id then
                    local f = context.factions:get(nemesis.faction_id)
                    if f then
                        f:shift_power(consequences.faction_power_shift)
                        local direction = consequences.faction_power_shift > 0 and "grows stronger" or "grows weaker"
                        lines[#lines + 1] = {
                            text = f.name .. " " .. direction,
                            color_key = "neutral",
                        }
                    end
                end
            end
        end)
    end

    -- Kill nemesis (blood rite consequence)
    if consequences.kill_nemesis and context.rival_heirs then
        pcall(function()
            local nemesis = context.rival_heirs:get_nemesis()
            if nemesis and nemesis.alive then
                nemesis.alive = false
                local nem_name = nemesis.name or "the Nemesis"
                lines[#lines + 1] = {
                    text = nem_name .. " has been erased",
                    color_key = "negative",
                }
                if context.world_state then
                    context.world_state:add_chronicle(nem_name .. " was struck from the record by ritual.", {
                        origin = {
                            type = "blood_rite",
                            heir_name = context.heir_name or "Unknown",
                            gen = context.generation or 0,
                            detail = "kill_nemesis"
                        }
                    })
                end
            end
        end)
    end

    -- Chronicle entry with causality origin tracking
    if effects.narrative and effects.narrative ~= "" then
        context.world_state:add_chronicle(effects.narrative, {
            origin = {
                type = "council",
                heir_name = context.heir_name or "Unknown",
                gen = context.generation or 0,
                detail = action.label
            }
        })
        effects.narrative_chronicled = true
    end

    effects.consequence_lines = lines
    return effects
end

-- =========================================================================
-- System action dispatcher: connects council to real game systems
-- =========================================================================
function Council._execute_system_action(system_action, context, target_faction_id, lines, effects)
    if system_action == "start_great_work" then
        if context.great_works and context.heir_genome then
            local era_key = context.world_state and context.world_state.current_era_key or "ancient"
            local available = context.great_works:get_available(context.heir_genome, era_key)
            if #available > 0 then
                -- Pick the first available (could be player-chosen in future)
                local tmpl = available[1]
                local initial_progress = 0
                if context.culture and context.culture:has_custom("artisan_guilds") then
                    initial_progress = 1 -- creative_bonus_on_craft
                end
                local started = context.great_works:start(tmpl.id, context.generation, context.heir_name, initial_progress)
                if started then
                    lines[#lines + 1] = {
                        text = "GREAT WORK BEGUN: " .. tmpl.label,
                        color_key = "special",
                    }
                    lines[#lines + 1] = {
                        text = (tmpl.investment_gens - initial_progress) .. " generations to complete",
                        color_key = "neutral",
                    }
                end
            else
                lines[#lines + 1] = {
                    text = "The age offers no worthy monument for this bloodline — not yet",
                    color_key = "neutral",
                }
            end
        end
    elseif system_action == "forge_discovery" then
        if context.discoveries and context.heir_genome then
            local era_key = context.world_state and context.world_state.current_era_key or "ancient"
            local available = context.discoveries:get_available(context.heir_genome, era_key)
            if #available > 0 then
                local disc = available[rng.range(1, #available)]
                context.discoveries:unlock(disc.id, context.generation, context.heir_name)
                lines[#lines + 1] = {
                    text = "DISCOVERY: " .. disc.label,
                    color_key = "special",
                }
                lines[#lines + 1] = {
                    text = disc.flavor,
                    color_key = "neutral",
                }
            else
                lines[#lines + 1] = {
                    text = "The heir's mind churns, but no breakthrough comes",
                    color_key = "neutral",
                }
            end
        end
    elseif system_action == "religious_decree" then
        if context.religion and context.religion.active then
            context.religion.zealotry = math.min(100, (context.religion.zealotry or 50) + 10)
            lines[#lines + 1] = {
                text = "Zealotry rises (+10)",
                color_key = "special",
            }
        end
    elseif system_action == "challenge_faith" then
        if context.religion and context.religion.active then
            context.religion.schism_pressure = (context.religion.schism_pressure or 0) + 25
            lines[#lines + 1] = {
                text = "Schism pressure builds (+25)",
                color_key = "negative",
            }
        end
    elseif system_action == "enforce_custom" then
        if context.culture then
            context.culture.rigidity = math.min(80, (context.culture.rigidity or 50) + 10)
            lines[#lines + 1] = {
                text = "Cultural rigidity increases (+10)",
                color_key = "neutral",
            }
        end
    elseif system_action == "cultural_reform" then
        if context.culture then
            context.culture.rigidity = math.max(0, (context.culture.rigidity or 50) - 15)
            lines[#lines + 1] = {
                text = "Cultural rigidity weakens (-15)",
                color_key = "neutral",
            }
            -- Remove newest custom if any
            if context.culture.customs and #context.culture.customs > 0 then
                local removed = table.remove(context.culture.customs)
                if removed then
                    lines[#lines + 1] = {
                        text = "Custom abandoned: " .. (removed.label or removed.id),
                        color_key = "negative",
                    }
                end
            end
        end
    -- =========================================================================
    -- Living world system actions (Wave 2)
    -- =========================================================================
    elseif system_action == "pursue_dream" then
        if context.bloodline_dream and context.bloodline_dream.status == "active" then
            local dream = context.bloodline_dream
            -- Boost the dream trait via offspring_boost
            if effects then
                effects.offspring_boost = { trait = dream.trait_id, bonus = 10 }
            end
            lines[#lines + 1] = {
                text = "Pursuing the dream of " .. (dream.trait_name or "greatness") .. " (+10 offspring boost)",
                color_key = "special",
            }
            -- Shift cultural memory toward dream category
            local cat = dream.category
            if cat and context.cultural_memory then
                local prefix = CAT_TO_PREFIX[cat]
                if prefix then
                    for id, priority in pairs(context.cultural_memory.trait_priorities) do
                        if id:sub(1, 3) == prefix then
                            context.cultural_memory.trait_priorities[id] =
                                Math.clamp(priority + 3, 0, 100)
                        end
                    end
                end
            end
        end
    elseif system_action == "start_apotheosis" then
        if context.world_state then
            context.world_state._pending_apotheosis = true
            lines[#lines + 1] = {
                text = "ASCENSION RITUAL BEGUN",
                color_key = "special",
            }
        end
    elseif system_action == "start_campaign" then
        if context.campaign then
            context.campaign:start(target_faction_id)
            -- Auto-assign the most competent court member as general
            if context.court and context.court.members then
                local best = nil
                for _, m in ipairs(context.court.members) do
                    if m.status == "active" and (not best or (m.competence or 0) > (best.competence or 0)) then
                        best = m
                    end
                end
                if best then
                    context.campaign:assign_general(best)
                    lines[#lines + 1] = {
                        text = best.name .. " appointed as General (Competence: " .. (best.competence or 50) .. ")",
                        color_key = "neutral",
                    }
                end
            end
            -- Add "war" condition to the world while campaign is active
            if context.world_state then
                context.world_state:add_condition("war", 0.5, 6)
            end
            lines[#lines + 1] = {
                text = "MILITARY CAMPAIGN STARTED",
                color_key = "negative",
            }
        end
    elseif system_action == "canonize_ancestor" then
        if context.echoes and context.religion and context.religion.active then
            -- Auto-select the strongest echo for simplicity
            local chosen = nil
            for _, s in ipairs(context.echoes.spirits) do
                if not chosen or (s.impact_tier == "Legendary" and chosen.impact_tier ~= "Legendary") then
                    chosen = s
                end
            end
            if chosen then
                local domains = { "war", "harvest", "secrets", "fertility" }
                local domain = domains[rng.range(1, #domains)]
                context.religion:deify_ancestor(chosen.name, chosen.generation, domain)
                lines[#lines + 1] = {
                    text = chosen.name .. " has been deified as the God of " .. domain:upper(),
                    color_key = "special",
                }
            end
        end
    elseif system_action == "restore_fossil" then
        pcall(function()
            local ok_tf, TraitFossils = pcall(require, "dredwork_world.trait_fossils")
            if ok_tf and TraitFossils and context.trait_peaks and context.heir_genome then
                local fossils = TraitFossils.detect(context.trait_peaks, context.heir_genome)
                if #fossils > 0 then
                    local fossil = fossils[1]  -- most dramatic gap
                    if effects then
                        effects.offspring_boost = { trait = fossil.trait_id, bonus = 8 }
                    end
                    lines[#lines + 1] = {
                        text = "Reclaiming " .. fossil.trait_name .. " (was " ..
                            fossil.peak_value .. ", now " .. fossil.current_value .. ")",
                        color_key = "special",
                    }
                    -- Shift cultural memory toward the fossil's category
                    local cat = ({ PHY = "physical", MEN = "mental", SOC = "social", CRE = "creative" })[fossil.trait_id:sub(1, 3)] or "physical"
                    if context.cultural_memory then
                        local prefix = CAT_TO_PREFIX[cat]
                        if prefix then
                            for id, priority in pairs(context.cultural_memory.trait_priorities) do
                                if id:sub(1, 3) == prefix then
                                    context.cultural_memory.trait_priorities[id] =
                                        Math.clamp(priority + 4, 0, 100)
                                end
                            end
                        end
                    end
                end
            end
        end)
    elseif system_action == "ride_momentum" then
        if context.momentum then
            -- Find the strongest ascending category and amplify it
            local best_cat, best_streak = nil, 0
            for cat, entry in pairs(context.momentum) do
                if type(entry) == "table" and entry.direction == "rising"
                   and entry.streak >= 3 and entry.streak > best_streak then
                    best_cat = cat
                    best_streak = entry.streak
                end
            end
            if best_cat then
                -- Amplify the streak by adding +2
                context.momentum[best_cat].streak = context.momentum[best_cat].streak + 2
                lines[#lines + 1] = {
                    text = "Momentum amplified: " .. best_cat:upper() .. " streak +" .. 2,
                    color_key = "special",
                }
                -- Cultural memory boost in the ascending category
                if context.cultural_memory then
                    local prefix = CAT_TO_PREFIX[best_cat]
                    if prefix then
                        for id, priority in pairs(context.cultural_memory.trait_priorities) do
                            if id:sub(1, 3) == prefix then
                                context.cultural_memory.trait_priorities[id] =
                                    Math.clamp(priority + 3, 0, 100)
                            end
                        end
                    end
                end
            end
        end
    elseif system_action == "suppress_undercurrent" then
        pcall(function()
            local ok_uc, Undercurrent = pcall(require, "dredwork_world.undercurrent")
            if ok_uc and Undercurrent then
                -- Reset undercurrent streaks to suppress building patterns
                if context.undercurrent_streaks then
                    local suppressed = 0
                    for pattern_id, streak in pairs(context.undercurrent_streaks) do
                        if streak > 0 then
                            context.undercurrent_streaks[pattern_id] = math.max(0, streak - 2)
                            suppressed = suppressed + 1
                        end
                    end
                    if suppressed > 0 then
                        lines[#lines + 1] = {
                            text = suppressed .. " hidden pattern(s) suppressed",
                            color_key = "special",
                        }
                    else
                        lines[#lines + 1] = {
                            text = "The undercurrent recedes... for now",
                            color_key = "neutral",
                        }
                    end
                end
            end
        end)
    -- =========================================================================
    -- Thin-tab system actions (Diplomacy, Warfare, Intrigue)
    -- =========================================================================
    elseif system_action == "diplomatic_marriage" then
        if context.rival_heirs and target_faction_id then
            local rival = context.rival_heirs:get(target_faction_id)
            if rival then
                local RivalHeirs = require("dredwork_world.rival_heirs").RivalHeirs
                RivalHeirs.record_interaction(rival, context.generation or 1, "marriage_pact",
                    "A dynastic marriage bound the bloodlines.", 20)
                lines[#lines + 1] = {
                    text = "Marriage pact forged with " .. (rival.name or "the rival heir"),
                    color_key = "special",
                }
            end
        end
    elseif system_action == "negotiate_shadow" then
        if context.shadow_lineages and context.shadow_lineages.branches then
            local target = nil
            for _, branch in ipairs(context.shadow_lineages.branches) do
                if branch.status == "hidden" then target = branch; break end
            end
            if target then
                -- 50/50: reconciliation weakens them, or they reject and grow stronger
                if rng.chance(0.5) then
                    target.power = math.max(0, target.power - 20)
                    lines[#lines + 1] = {
                        text = target.name .. " softens. Their power wanes (-20).",
                        color_key = "special",
                    }
                    if context.factions then
                        lines[#lines + 1] = {
                            text = "The exiles may yet return to the fold.",
                            color_key = "neutral",
                        }
                    end
                else
                    target.power = target.power + 10
                    lines[#lines + 1] = {
                        text = target.name .. " rejects the offer. They grow bolder (+10 power).",
                        color_key = "negative",
                    }
                    -- Record the slight — disposition penalty if they emerge
                    table.insert(target.history, "Rejected a parley offer in Gen " .. (context.generation or 1) .. ".")
                end
            end
        end
    elseif system_action == "conscript_levies" then
        if context.holdings and context.holdings.domains then
            local domain_count = #context.holdings.domains
            local steel_gain = domain_count * 4
            local grain_loss = domain_count * 2
            if context.resources then
                context.resources:change("steel", steel_gain, "Conscript levies", context.heir_name, context.generation)
                context.resources:change("grain", -grain_loss, "Feeding the levy", context.heir_name, context.generation)
            end
            lines[#lines + 1] = {
                text = domain_count .. " domains mustered: +" .. steel_gain .. " Steel, -" .. grain_loss .. " Grain",
                color_key = "special",
            }
            -- Domains shrink from the drain
            for _, domain in ipairs(context.holdings.domains) do
                if domain.size and domain.size > 1 and rng.chance(0.3) then
                    domain.size = domain.size - 1
                    lines[#lines + 1] = {
                        text = (domain.name or "A domain") .. " diminished from the levy",
                        color_key = "negative",
                    }
                    break -- Only damage one domain per conscription
                end
            end
        end
    elseif system_action == "post_bounty" then
        if context.rival_heirs and target_faction_id then
            local rival = context.rival_heirs:get(target_faction_id)
            if rival then
                local RivalHeirs = require("dredwork_world.rival_heirs").RivalHeirs
                -- Assassination attempt: check against rival's resourcefulness
                local rival_defense = (rival.personality and rival.personality.PER_OBS or 50) / 100
                if rng.chance(0.5 - rival_defense * 0.3) then
                    -- Success: rival dies
                    rival.alive = false
                    rival.generation_died = context.generation or 1
                    RivalHeirs.record_interaction(rival, context.generation or 1, "assassination",
                        "Killed by hired assassins.", -50)
                    lines[#lines + 1] = {
                        text = rival.name .. " was found dead. The bounty is claimed.",
                        color_key = "special",
                    }
                else
                    -- Failure: rival survives and hates you
                    RivalHeirs.record_interaction(rival, context.generation or 1, "assassination_attempt",
                        "Survived an assassination attempt.", -30)
                    lines[#lines + 1] = {
                        text = rival.name .. " survived. They will not forget.",
                        color_key = "negative",
                    }
                    if context.factions then
                        local faction = context.factions:get(target_faction_id)
                        if faction then
                            faction.disposition = math.max(-100, (faction.disposition or 0) - 20)
                        end
                    end
                end
            end
        end
    elseif system_action == "reinforce_campaign" then
        if context.campaign and context.campaign.active then
            context.campaign.war_score = math.min(100, (context.campaign.war_score or 50) + 20)
            lines[#lines + 1] = {
                text = "War score boosted (+20). The tide may yet turn.",
                color_key = "special",
            }
        end
    elseif system_action == "investigate_rumor" then
        if context.rumors and context.rumors.active and #context.rumors.active > 0 then
            local rumor = context.rumors.active[rng.range(1, #context.rumors.active)]
            lines[#lines + 1] = {
                text = "INVESTIGATED: \"" .. (rumor.text or "Unknown whisper") .. "\"",
                color_key = "neutral",
            }
            if rumor.reliability and rumor.reliability >= 0.7 then
                lines[#lines + 1] = {
                    text = "Agents confirm: this intelligence is reliable.",
                    color_key = "special",
                }
                -- Reliable intel about a faction grants disposition insight
                if rumor.source_faction and context.factions then
                    local faction = context.factions:get(rumor.source_faction)
                    if faction then
                        if effects then effects.reveal_faction_info = true end
                        lines[#lines + 1] = {
                            text = "Intelligence gathered on " .. (faction.name or "a rival house"),
                            color_key = "special",
                        }
                    end
                end
            elseif rumor.reliability and rumor.reliability < 0.3 then
                lines[#lines + 1] = {
                    text = "A fabrication. Someone wanted us chasing shadows.",
                    color_key = "negative",
                }
            else
                lines[#lines + 1] = {
                    text = "The truth remains unclear. Partial intelligence only.",
                    color_key = "neutral",
                }
            end
        end
    elseif system_action == "exile_courtier" then
        if context.court and context.court.members then
            -- Find the least loyal active member
            local worst = nil
            local worst_loyalty = 999
            for _, m in ipairs(context.court.members) do
                if m.status == "active" and (m.loyalty or 50) < worst_loyalty then
                    worst = m
                    worst_loyalty = m.loyalty or 50
                end
            end
            if worst then
                worst.status = "exiled"
                lines[#lines + 1] = {
                    text = (worst.name or "A courtier") .. " has been exiled (loyalty was " .. worst_loyalty .. ")",
                    color_key = "negative",
                }
                -- Low-loyalty exiles may found a shadow lineage
                if worst_loyalty < 30 and context.shadow_lineages then
                    local branch = context.shadow_lineages:found_branch(worst, context.generation or 1, context.reliquary, "exile")
                    if branch then
                        lines[#lines + 1] = {
                            text = worst.name .. " has founded " .. branch.name .. " in the wilds.",
                            color_key = "negative",
                        }
                    end
                end
                -- Moral consequence for exile
                if context.morality then
                    local Morality = require("dredwork_world.morality")
                    Morality.record_act(context.morality, "ruthless_order", context.generation or 1,
                        "Exiled " .. (worst.name or "a courtier") .. " from the court")
                end
            end
        end
    elseif system_action == "forge_relic" then
        if context.reliquary then
            local relic_templates = {
                { name = "The Bloodstone Crown", type = "crown", effect = { lineage_power_bonus = 5 },
                  description = "A crown set with a gem that pulses with the heartbeat of the bloodline." },
                { name = "The Ashen Blade", type = "weapon", effect = { trait_bonus = { PHY_STR = 5 } },
                  description = "A sword forged in the ashes of the family's enemies." },
                { name = "The Whispering Tome", type = "tome", effect = { trait_bonus = { MEN_INT = 5 } },
                  description = "A book that writes itself, recording every secret the bloodline discovers." },
                { name = "The Iron Sigil", type = "relic", effect = { mutation_pressure_reduction = 5 },
                  description = "A sigil that stabilizes the blood against corruption." },
                { name = "The Mourner's Ring", type = "relic", effect = { trait_bonus = { SOC_EMP = 3, MEN_COM = 3 } },
                  description = "A ring carved from the bone of a beloved ancestor." },
            }
            -- Pick one not already in the reliquary
            local available = {}
            for _, tmpl in ipairs(relic_templates) do
                local already_exists = false
                for _, art in ipairs(context.reliquary.artifacts) do
                    if art.name == tmpl.name then already_exists = true; break end
                end
                if not already_exists then available[#available + 1] = tmpl end
            end
            if #available > 0 then
                local chosen = available[rng.range(1, #available)]
                context.reliquary:add_artifact({
                    name = chosen.name,
                    type = chosen.type,
                    effect = chosen.effect,
                    forged_by = context.heir_name or "unknown",
                    forged_gen = context.generation or 1,
                    description = chosen.description,
                })
                lines[#lines + 1] = {
                    text = "RELIC FORGED: " .. chosen.name,
                    color_key = "special",
                }
                lines[#lines + 1] = {
                    text = chosen.description,
                    color_key = "neutral",
                }
            else
                lines[#lines + 1] = {
                    text = "The forges produced nothing new. All great relics already exist.",
                    color_key = "neutral",
                }
            end
        end
    elseif system_action == "commune_ancestors" then
        if context.echoes and #context.echoes.spirits > 0 then
            -- Pick the echo with best synergy to the current heir
            local invocations = context.echoes:get_invocations(context.heir_personality)
            if #invocations > 0 then
                -- Sort by synergy (best first)
                table.sort(invocations, function(a, b) return a.synergy > b.synergy end)
                local chosen = invocations[1]
                local bonuses = context.echoes:invoke(chosen.spirit.name, chosen.cost)
                if bonuses then
                    -- Store trait bonuses for the offspring phase
                    if effects then
                        effects.echo_bonuses = bonuses
                        -- Also set as offspring boost (strongest trait)
                        local best_trait, best_val = nil, 0
                        for trait_id, val in pairs(bonuses) do
                            if val > best_val then best_trait = trait_id; best_val = val end
                        end
                        if best_trait then
                            effects.offspring_boost = { trait = best_trait, bonus = math.floor(best_val / 2) }
                        end
                    end
                    lines[#lines + 1] = {
                        text = "INVOKED: The ghost of " .. chosen.spirit.name .. " (Gen " .. chosen.spirit.generation .. ")",
                        color_key = "special",
                    }
                    lines[#lines + 1] = {
                        text = "Aura remaining: " .. context.echoes.aura,
                        color_key = "neutral",
                    }
                else
                    lines[#lines + 1] = {
                        text = "The ancestors did not answer. The aura was too weak.",
                        color_key = "negative",
                    }
                end
            end
        end
    -- =========================================================================
    -- Resource-strategic system actions (v0.13.0)
    -- =========================================================================
    elseif system_action == "seal_granaries" then
        -- Sealed grain acts as famine insurance: reduces famine severity next time it hits
        if context.world_state then
            context.world_state._granary_sealed = true
            lines[#lines + 1] = {
                text = "Granaries sealed. Famine resistance strengthened.",
                color_key = "special",
            }
        end
    elseif system_action == "provision_expedition" then
        -- Expedition yields: discovery chance, lore, or a new holding lead
        if context.discoveries and context.heir_genome then
            local era_key = context.world_state and context.world_state.current_era_key or "ancient"
            local available = context.discoveries:get_available(context.heir_genome, era_key)
            if #available > 0 and rng.chance(0.4) then
                local disc = available[rng.range(1, #available)]
                context.discoveries:unlock(disc.id, context.generation, context.heir_name)
                lines[#lines + 1] = {
                    text = "EXPEDITION DISCOVERY: " .. disc.label,
                    color_key = "special",
                }
            else
                -- Fallback: lore and cultural shift
                if context.resources then
                    context.resources:change("lore", 5, "Expedition findings", context.heir_name, context.generation)
                end
                lines[#lines + 1] = {
                    text = "The expedition returned with knowledge (+5 Lore)",
                    color_key = "positive",
                }
            end
        else
            if context.resources then
                context.resources:change("lore", 5, "Expedition findings", context.heir_name, context.generation)
            end
            lines[#lines + 1] = {
                text = "The expedition returned with knowledge (+5 Lore)",
                color_key = "positive",
            }
        end
    elseif system_action == "arm_holdings" then
        -- Armed holdings resist war damage and boost physical nurture
        if context.holdings and context.holdings.domains then
            local armed = 0
            for _, domain in ipairs(context.holdings.domains) do
                domain._armed = true
                armed = armed + 1
            end
            lines[#lines + 1] = {
                text = armed .. " domain(s) armed. Holdings resist war damage this generation.",
                color_key = "special",
            }
        end
    elseif system_action == "specialize_holding" then
        -- Deliberately specialize a holding
        if context.holdings then
            pcall(function()
                -- Find target domain (passed via target_holding_id, or pick best unspecialized)
                local target_dom = nil
                if target_holding_id then
                    for _, dom in ipairs(context.holdings.domains) do
                        if dom.id == target_holding_id and dom.status == "active" then
                            target_dom = dom; break
                        end
                    end
                end
                if not target_dom then
                    -- Pick first active unspecialized domain
                    for _, dom in ipairs(context.holdings.domains) do
                        if dom.status == "active" and not dom.specialty then
                            target_dom = dom; break
                        end
                    end
                end
                if not target_dom then
                    -- Fall back to any active domain (re-specialize)
                    for _, dom in ipairs(context.holdings.domains) do
                        if dom.status == "active" then target_dom = dom; break end
                    end
                end

                if target_dom then
                    local Holdings = require("dredwork_world.holdings")
                    -- Pick best specialty based on cultural memory
                    local cm = context.cultural_memory or {}
                    local best_cat, best_val = "physical", 0
                    for _, cat in ipairs({ "physical", "mental", "social", "creative" }) do
                        if (cm[cat] or 0) > best_val then
                            best_cat = cat
                            best_val = cm[cat] or 0
                        end
                    end

                    -- Pick from that category, preferring affinity matches
                    local pool = Holdings.CATEGORY_SPECIALTIES[best_cat] or {}
                    local chosen_id = nil
                    for _, spec_id in ipairs(pool) do
                        local spec = Holdings.SPECIALTIES[spec_id]
                        if spec and spec.affinity then
                            for _, aff in ipairs(spec.affinity) do
                                if aff == target_dom.type then chosen_id = spec_id; break end
                            end
                        end
                        if chosen_id then break end
                    end
                    if not chosen_id and #pool > 0 then
                        chosen_id = pool[rng.range(1, #pool)]
                    end

                    if chosen_id then
                        local ok, narrative = context.holdings:set_specialty(target_dom.id, chosen_id)
                        if ok then
                            local spec = Holdings.SPECIALTIES[chosen_id]
                            lines[#lines + 1] = {
                                text = "HOLDING SPECIALIZED: " .. target_dom.name .. " → " .. (spec and spec.label or chosen_id),
                                color_key = "special",
                            }
                            if narrative then
                                lines[#lines + 1] = { text = narrative, color_key = "positive" }
                            end
                        end
                    end
                end
            end)
        end

    elseif system_action == "found_settlement" then
        -- Create a new holding
        if context.holdings then
            local Holdings = require("dredwork_world.holdings")
            local settlement_types = { "farm", "village", "mine", "outpost" }
            local stype = settlement_types[rng.range(1, #settlement_types)]
            local era_key = context.world_state and context.world_state.current_era_key or "ancient"
            local sname = Holdings.generate_name(stype, era_key)
            context.holdings:add_domain({
                id = stype .. "_" .. tostring(context.generation or 0),
                name = sname,
                type = stype,
                size = 1,
            })
            lines[#lines + 1] = {
                text = "SETTLEMENT FOUNDED: " .. sname .. " (" .. stype .. ")",
                color_key = "special",
            }
            -- Gaining a holding ends exodus — you have a home now
            if context.world_state and context.world_state:has_condition("exodus") then
                context.world_state:remove_condition("exodus")
                lines[#lines + 1] = {
                    text = "EXODUS ENDED — the bloodline has put down roots",
                    color_key = "positive",
                }
            end
        end
    end
end

return Council
