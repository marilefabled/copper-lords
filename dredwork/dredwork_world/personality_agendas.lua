local Math = require("dredwork_core.math")
-- Bloodweight — Personality Agendas ("Demands of the Blood")
-- Each heir arrives with 1-2 agendas derived from their strongest personality axes.
-- Fulfillment grants LP and priority boosts. Neglect creates taboos and priority drift.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local PersonalityAgendas = {}

-- ═══════════════════════════════════════════════════════
-- AGENDA DEFINITIONS
-- ═══════════════════════════════════════════════════════

-- Each axis maps to agendas for high (>=65) and low (<=35) values.
-- signals: council action IDs that fulfill this agenda
-- event_signals: event-side tags that fulfill this agenda
-- lp_reward: LP granted on fulfillment
-- neglect_taboo: optional taboo created on neglect
-- neglect_priority_shift: category priority drift on neglect

local AGENDA_DEFS = {
    PER_BLD_high = {
        { id = "conquest",
          label = "The March",
          description = "This heir craves conquest. Launch a campaign or forge steel into purpose.",
          signals = { "launch_campaign", "reinforce_campaign", "scorched_earth", "arm_the_holdings", "arm_the_peasants" },
          event_signals = { "war_victory", "military_triumph" },
          lp_reward = 4,
          neglect_taboo = { effect = "bloodline_fears_war", strength = 55 },
          neglect_priority_shift = { physical = -3 },
        },
        { id = "risk_taker",
          label = "The Wager",
          description = "The heir stakes everything on bold strokes. Commission a great work or forge a discovery.",
          signals = { "commission_great_work", "forge_discovery", "forge_relic", "provision_expedition" },
          event_signals = { "discovery_made" },
          lp_reward = 3,
          neglect_priority_shift = { creative = -2, mental = -2 },
        },
    },
    PER_BLD_low = {
        { id = "fortification",
          label = "The Bulwark",
          description = "This heir trusts walls over swords. Fortify, develop, or settle.",
          signals = { "fortify_border", "develop_holding", "arm_the_holdings", "found_settlement", "granary_reserve" },
          lp_reward = 3,
          neglect_priority_shift = { physical = -2 },
        },
    },

    PER_CRM_high = {
        { id = "vengeance",
          label = "The Reckoning",
          description = "The heir demands blood. Declare a rivalry, post a bounty, or scorch the earth.",
          signals = { "declare_rivalry", "post_bounty", "scorched_earth", "spread_rumors" },
          event_signals = { "enemy_punished", "cruel_choice" },
          lp_reward = 4,
          neglect_taboo = { effect = "bloodline_showed_weakness", strength = 50 },
          neglect_priority_shift = { social = 2 },
        },
    },
    PER_CRM_low = {
        { id = "reconciliation",
          label = "The Olive Branch",
          description = "This heir seeks peace. Forge an alliance, trade, or feed the faithful.",
          signals = { "seek_alliance", "atone", "trade_agreement", "negotiate_shadow", "feed_the_faithful", "feast_of_tribute", "sell_grain_stores", "trade_steel_provisions" },
          event_signals = { "peace_brokered", "merciful_choice" },
          lp_reward = 3,
          neglect_priority_shift = { social = -2 },
        },
    },

    PER_OBS_high = {
        { id = "fixation",
          label = "The Obsession",
          description = "The heir is consumed by a single purpose. Pursue the dream or ride the momentum.",
          signals = { "ride_momentum", "commission_great_work", "forge_discovery" },
          event_signals = { "dream_progress", "dream_fulfilled" },
          lp_reward = 5,
          neglect_taboo = { effect = "bloodline_lost_focus", strength = 55 },
        },
    },
    PER_OBS_low = {
        { id = "stability",
          label = "The Steady Hand",
          description = "This heir desires nothing exceptional. Consolidate. Invest. Maintain the ledger.",
          signals = { "consolidate", "granary_reserve", "invest_next_gen", "trade_agreement" },
          lp_reward = 2,
        },
    },

    PER_LOY_high = {
        { id = "blood_bond",
          label = "The Blood-Oath",
          description = "This heir would die for the bloodline's allies. Strengthen or forge an alliance.",
          signals = { "seek_alliance", "feast_of_tribute", "gift_of_iron", "trade_agreement" },
          event_signals = { "alliance_strengthened" },
          lp_reward = 3,
          neglect_priority_shift = { social = -3 },
        },
    },
    PER_LOY_low = {
        { id = "opportunist",
          label = "The Turncoat's Gambit",
          description = "Loyalty is currency this heir spends freely. Spread rumors, exile a courtier, or betray.",
          signals = { "declare_rivalry", "spread_rumors", "exile_courtier", "negotiate_shadow", "melt_down_relics" },
          lp_reward = 3,
          neglect_priority_shift = { social = 2 },
        },
    },

    PER_CUR_high = {
        { id = "revelation",
          label = "The Unsealed Ledger",
          description = "This heir must know. Forge a discovery, commission scholars, or investigate.",
          signals = { "forge_discovery", "provision_expedition", "send_scouts", "commission_scholars" },
          event_signals = { "discovery_made", "secret_revealed" },
          lp_reward = 4,
          neglect_priority_shift = { mental = -3 },
        },
    },
    PER_CUR_low = {
        { id = "orthodoxy",
          label = "The Closed Book",
          description = "This heir accepts the balance as written. Enforce customs or decree the faith.",
          signals = { "enforce_custom", "religious_decree", "tithe_to_the_faith", "consolidate" },
          lp_reward = 2,
        },
    },

    PER_VOL_high = {
        { id = "upheaval",
          label = "The Burning Ledger",
          description = "This heir craves disruption. Challenge the faith, declare rivalry, or scorch the earth.",
          signals = { "challenge_faith", "cultural_reform", "declare_rivalry", "scorched_earth" },
          event_signals = { "upheaval_caused" },
          lp_reward = 4,
          neglect_taboo = { effect = "bloodline_stagnated", strength = 45 },
        },
    },
    PER_VOL_low = {
        { id = "preservation",
          label = "The Unchanging Terms",
          description = "This heir resists all change. Enforce customs, build reserves, fortify the old ways.",
          signals = { "enforce_custom", "consolidate", "granary_reserve", "fortify_border" },
          lp_reward = 2,
        },
    },

    PER_PRI_high = {
        { id = "glory",
          label = "The Name Demands",
          description = "The family name must echo. Commission a great work, forge a relic, or launch a campaign.",
          signals = { "commission_great_work", "launch_campaign", "forge_relic", "canonize_ancestor" },
          event_signals = { "legend_earned", "great_work_completed" },
          lp_reward = 5,
          neglect_taboo = { effect = "bloodline_accepted_obscurity", strength = 50 },
          neglect_priority_shift = { creative = -2 },
        },
    },
    PER_PRI_low = {
        { id = "humility",
          label = "The Quiet Ledger",
          description = "This heir seeks no glory. Invest in the next generation or tend to the faith.",
          signals = { "invest_next_gen", "atone", "tithe_to_the_faith", "commune_ancestors" },
          lp_reward = 2,
        },
    },

    PER_ADA_high = {
        { id = "versatility",
          label = "The Restructuring",
          description = "This heir adapts to whatever the ledger demands. Act in two distinct domains.",
          signals = { "_any_two_distinct" },
          lp_reward = 2,
        },
    },
    PER_ADA_low = {
        { id = "rigidity",
          label = "The Unchanging Contract",
          description = "This heir refuses to bend. Reinforce the path the bloodline has always walked.",
          signals = { "enforce_custom", "consolidate", "fortify_border", "religious_decree" },
          lp_reward = 3,
          neglect_priority_shift = { mental = -2 },
        },
    },
}

-- ═══════════════════════════════════════════════════════
-- GENERATION
-- ═══════════════════════════════════════════════════════

--- Generate 1-2 agendas for an heir based on their personality.
---@param personality table Personality instance
---@param generation number current generation
---@return table agendas array (0-2 items)
function PersonalityAgendas.generate(personality, generation)
    if not personality or not personality.axes then return {} end

    -- Rank axes by distance from 50 (most extreme first)
    local ranked = {}
    for _, axis_id in ipairs({
        "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY",
        "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA",
    }) do
        local val = personality.axes[axis_id] or 50
        local dist = math.abs(val - 50)
        if dist >= 15 then
            ranked[#ranked + 1] = { axis = axis_id, value = val, distance = dist }
        end
    end

    table.sort(ranked, function(a, b) return a.distance > b.distance end)

    local agendas = {}
    local used_ids = {}

    for i = 1, math.min(2, #ranked) do
        local entry = ranked[i]
        local direction = entry.value >= 65 and "high" or "low"
        local key = entry.axis .. "_" .. direction
        local pool = AGENDA_DEFS[key]

        if pool and #pool > 0 then
            local pick = pool[rng.range(1, #pool)]
            if not used_ids[pick.id] then
                used_ids[pick.id] = true
                agendas[#agendas + 1] = {
                    id = pick.id,
                    axis = entry.axis,
                    axis_value = entry.value,
                    label = pick.label,
                    description = pick.description,
                    signals = pick.signals,
                    event_signals = pick.event_signals,
                    lp_reward = pick.lp_reward,
                    neglect_taboo = pick.neglect_taboo,
                    neglect_priority_shift = pick.neglect_priority_shift,
                    generation_set = generation,
                    fulfilled = false,
                }
            end
        end
    end

    return agendas
end

-- ═══════════════════════════════════════════════════════
-- EVALUATION
-- ═══════════════════════════════════════════════════════

--- Check which agendas were fulfilled or neglected.
---@param agendas table array of agenda instances
---@param action_ids table array of council action IDs taken this gen
---@param council_categories table|nil set of { [category] = true } for distinct category check
---@return table { fulfilled = {}, neglected = {} }
function PersonalityAgendas.evaluate(agendas, action_ids, council_categories)
    if not agendas then return { fulfilled = {}, neglected = {} } end

    local signal_set = {}
    for _, id in ipairs(action_ids or {}) do
        signal_set[id] = true
    end

    local fulfilled = {}
    local neglected = {}

    for _, agenda in ipairs(agendas) do
        local is_fulfilled = false

        -- Check council action signals
        if agenda.signals then
            for _, sig in ipairs(agenda.signals) do
                if sig == "_any_two_distinct" then
                    -- Special: count distinct council categories
                    local cat_count = 0
                    for _ in pairs(council_categories or {}) do cat_count = cat_count + 1 end
                    if cat_count >= 2 then is_fulfilled = true end
                elseif signal_set[sig] then
                    is_fulfilled = true
                end
                if is_fulfilled then break end
            end
        end

        -- Check event signals
        if not is_fulfilled and agenda.event_signals then
            for _, sig in ipairs(agenda.event_signals) do
                if signal_set[sig] then
                    is_fulfilled = true
                    break
                end
            end
        end

        if is_fulfilled then
            agenda.fulfilled = true
            fulfilled[#fulfilled + 1] = agenda
        else
            neglected[#neglected + 1] = agenda
        end
    end

    return { fulfilled = fulfilled, neglected = neglected }
end

-- ═══════════════════════════════════════════════════════
-- CONSEQUENCES
-- ═══════════════════════════════════════════════════════

local fulfillment_narratives = {
    "The heir's ambition was satisfied.",
    "What the blood demanded, the blood received.",
    "The heir acted on conviction. The ledger approves.",
}

local neglect_narratives = {
    "The heir's demands went unmet. The blood remembers the slight.",
    "What the blood demanded was denied. A wound forms in the record.",
    "The heir passed unfulfilled. The weight shifts in protest.",
}

--- Apply fulfillment rewards.
---@param agenda table the fulfilled agenda
---@param game_state table
---@param world table worldContext
---@return string narrative
function PersonalityAgendas.apply_fulfillment(agenda, game_state, world)
    -- LP bonus
    if game_state.lineage_power then
        local ok, LP = pcall(require, "dredwork_world.lineage_power")
        if ok and LP then
            LP.shift(game_state.lineage_power, agenda.lp_reward or 3)
        end
    end

    -- Priority boost: +2 to category aligned with the axis
    local axis_cat_map = {
        PER_BLD = "physical", PER_CRM = "social", PER_OBS = "mental",
        PER_LOY = "social", PER_CUR = "mental", PER_VOL = "creative",
        PER_PRI = "creative", PER_ADA = nil,
    }
    local boost_cat = axis_cat_map[agenda.axis]
    if boost_cat and game_state.cultural_memory then
        local cm = game_state.cultural_memory
        local PREFIX_MAP = { physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" }
        local prefix = PREFIX_MAP[boost_cat]
        if prefix and cm.trait_priorities then
            for id, _ in pairs(cm.trait_priorities) do
                if id:sub(1, 3) == prefix then
                    cm.trait_priorities[id] = math.min(100, cm.trait_priorities[id] + 2)
                end
            end
        end
    end

    return fulfillment_narratives[rng.range(1, #fulfillment_narratives)]
        .. " " .. agenda.label .. " — fulfilled."
end

--- Apply neglect consequences.
---@param agenda table the neglected agenda
---@param game_state table
---@param generation number
---@return string narrative
function PersonalityAgendas.apply_neglect(agenda, game_state, generation)
    -- LP penalty
    if game_state.lineage_power then
        local ok, LP = pcall(require, "dredwork_world.lineage_power")
        if ok and LP then
            LP.shift(game_state.lineage_power, -2)
        end
    end

    -- Taboo (if defined)
    if agenda.neglect_taboo and game_state.cultural_memory then
        local cm = game_state.cultural_memory
        if cm.add_taboo then
            cm:add_taboo(agenda.label, generation,
                agenda.neglect_taboo.effect, agenda.neglect_taboo.strength)
        end
    end

    -- Priority drift
    if agenda.neglect_priority_shift and game_state.cultural_memory then
        local cm = game_state.cultural_memory
        local PREFIX_MAP = { physical = "PHY", mental = "MEN", social = "SOC", creative = "CRE" }
        if cm.trait_priorities then
            for cat, delta in pairs(agenda.neglect_priority_shift) do
                local prefix = PREFIX_MAP[cat]
                if prefix then
                    for id, _ in pairs(cm.trait_priorities) do
                        if id:sub(1, 3) == prefix then
                            cm.trait_priorities[id] = Math.clamp(cm.trait_priorities[id] + delta, 0, 100)
                        end
                    end
                end
            end
        end
    end

    return neglect_narratives[rng.range(1, #neglect_narratives)]
        .. " " .. agenda.label .. " — unfulfilled."
end

-- ═══════════════════════════════════════════════════════
-- DISPLAY
-- ═══════════════════════════════════════════════════════

--- Get display-ready agenda data.
---@param agendas table array of agenda instances
---@return table array of { label, description, fulfilled }
function PersonalityAgendas.get_display(agendas)
    if not agendas then return {} end
    local out = {}
    for _, a in ipairs(agendas) do
        out[#out + 1] = {
            label = a.label,
            description = a.description,
            fulfilled = a.fulfilled or false,
        }
    end
    return out
end

-- ═══════════════════════════════════════════════════════
-- SERIALIZATION
-- ═══════════════════════════════════════════════════════

--- Serialize agendas for save.
---@param agendas table
---@return table
function PersonalityAgendas.to_table(agendas)
    if not agendas then return nil end
    local out = {}
    for _, a in ipairs(agendas) do
        out[#out + 1] = {
            id = a.id,
            axis = a.axis,
            axis_value = a.axis_value,
            label = a.label,
            description = a.description,
            signals = a.signals,
            event_signals = a.event_signals,
            lp_reward = a.lp_reward,
            neglect_taboo = a.neglect_taboo,
            neglect_priority_shift = a.neglect_priority_shift,
            generation_set = a.generation_set,
            fulfilled = a.fulfilled,
        }
    end
    return out
end

--- Deserialize agendas from save.
---@param data table
---@return table
function PersonalityAgendas.from_table(data)
    if not data then return nil end
    return data -- already in the right format
end

return PersonalityAgendas
