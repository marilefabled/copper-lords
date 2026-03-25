-- Dark Legacy — Blood Magic (Rites of Attrition)
-- Burn genetic potential for immediate power.
-- Pure Lua, zero Solar2D dependencies.

local rng = require("dredwork_core.rng")

local Rites = {}

Rites.DEFINITIONS = {
    rite_of_iron = {
        id = "rite_of_iron",
        label = "Rite of Iron",
        cost_traits = { PHY_VIT = -20 },
        bonus_steel = 50,
        bonus_description = "Immediately win an active campaign.",
        description = "Survive the war today by burning the health of your descendants tomorrow."
    },
    rite_of_whispers = {
        id = "rite_of_whispers",
        label = "Rite of Whispers",
        cost_traits = { MEN_WIL = -20 },
        bonus_lore = 50,
        bonus_description = "Immediately gain 50 Lore.",
        description = "Sacrifice the mental clarity of your line for immediate insight."
    },
    rite_of_harvest = {
        id = "rite_of_harvest",
        label = "Rite of the Harvest",
        cost_traits = { PHY_END = -20 },
        bonus_grain = 50,
        bonus_description = "Immediately gain 50 Grain.",
        description = "Feed the people now at the cost of the family's endurance."
    },
    rite_of_avarice = {
        id = "rite_of_avarice",
        label = "Rite of Avarice",
        cost_traits = { SOC_TRU = -20 },
        bonus_gold = 50,
        bonus_description = "Immediately gain 50 Gold.",
        description = "Trade the family's honesty for immediate wealth."
    }
}

--- Execute a rite.
---@param rite_id string
---@param context table { heir_genome, resources, campaign, world_state, generation }
---@return table result { success, label, description }
function Rites.execute(rite_id, context)
    local rite = Rites.DEFINITIONS[rite_id]
    if not rite or not context then return { success = false, error = "Invalid rite or context" } end
    
    -- Check if heir has enough to sacrifice (don't go below 0)
    if context.heir_genome then
        for trait_id, delta in pairs(rite.cost_traits) do
            local val = context.heir_genome:get_value(trait_id) or 50
            if val < math.abs(delta) then
                -- Still allow it? It's "Blood Magic", it should be dangerous.
                -- Maybe it just caps at 0.
            end
            context.heir_genome:set_value(trait_id, math.max(0, val + delta))
        end
    end
    
    -- Apply bonuses
    if rite.bonus_steel and context.resources then
        context.resources:change("steel", rite.bonus_steel, "Rite of Iron")
        -- If in a war, push it towards victory
        if context.campaign and context.campaign.active then
            context.campaign.war_score = 100
        end
    end
    if rite.bonus_lore and context.resources then
        context.resources:change("lore", rite.bonus_lore, "Rite of Whispers")
    end
    if rite.bonus_grain and context.resources then
        context.resources:change("grain", rite.bonus_grain, "Rite of the Harvest")
    end
    if rite.bonus_gold and context.resources then
        context.resources:change("gold", rite.bonus_gold, "Rite of Avarice")
    end
    
    -- Record in chronicle
    if context.world_state then
        context.world_state:add_chronicle(
            (context.heir_name or "The heir") .. " enacted the " .. rite.label .. ", sacrificing their blood for power."
        )
    end
    
    -- Integration: Court reacts to the "Unnatural" cost
    if context.court then
        local events = {}
        for _, member in ipairs(context.court.members) do
            if member.status == "active" then
                -- Loyalty drop for everyone
                member.loyalty = math.max(0, member.loyalty - 15)
                
                -- Check for immediate defection due to horror
                if member.loyalty < 10 and rng.chance(0.3) then
                    if context.shadow_lineages and member.role == "sibling" then
                         context.shadow_lineages:found_branch(member, context.generation, context.reliquary, "betrayal")
                         member.status = "exiled"
                         table.insert(events, member.name .. " fled in horror at the rite, vowing to cleanse the bloodline from the outside.")
                    end
                end
            end
        end
        return { 
            success = true, 
            label = rite.label, 
            description = rite.description,
            cost_traits = rite.cost_traits,
            court_events = events
        }
    end

    return { 
        success = true, 
        label = rite.label, 
        description = rite.description,
        cost_traits = rite.cost_traits
    }
end

return Rites
