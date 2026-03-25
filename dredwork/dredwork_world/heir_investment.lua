-- Dark Legacy — Heir Investment System
-- Allows player to spend resources to boost current heir's development.
-- Provides agency during the heir's turn.

local HeirInvestment = {}

HeirInvestment.OPTIONS = {
    physical = {
        label = "Military Training",
        cost = { gold = 10, steel = 5 },
        trait_prefix = "PHY",
        bonus = 5,
        description = "Intensive drills to harden the body."
    },
    mental = {
        label = "Deep Study",
        cost = { lore = 12, gold = 5 },
        trait_prefix = "MEN",
        bonus = 5,
        description = "Hours in the scriptorium mastering forgotten logic."
    },
    social = {
        label = "Court Diplomacy",
        cost = { gold = 12, grain = 5 },
        trait_prefix = "SOC",
        bonus = 5,
        description = "Navigating the dangerous waters of high society."
    },
    creative = {
        label = "Artistic Patronage",
        cost = { lore = 8, gold = 8 },
        trait_prefix = "CRE",
        bonus = 5,
        description = "Surrounding the heir with the finest minds and artisans."
    }
}

--- Get the current cost for an investment option, adjusted by Lineage Power.
function HeirInvestment.get_adjusted_cost(option_id, lineage_power)
    local opt = HeirInvestment.OPTIONS[option_id]
    if not opt then return {} end
    
    local power_val = (lineage_power and lineage_power.value) or 50
    -- High power (70+) gives 20% discount, low power (30-) gives 20% penalty
    local multiplier = 1.0
    if power_val >= 70 then multiplier = 0.8
    elseif power_val <= 30 then multiplier = 1.2 end
    
    local adjusted = {}
    for res, amt in pairs(opt.cost) do
        adjusted[res] = math.floor(amt * multiplier)
    end
    return adjusted
end

--- Check if an investment can be made.
function HeirInvestment.can_afford(option_id, resources, lineage_power)
    local adjusted = HeirInvestment.get_adjusted_cost(option_id, lineage_power)
    if not resources then return false end
    for res, amt in pairs(adjusted) do
        if (resources[res] or 0) < amt then return false end
    end
    return true
end

--- Apply an investment to the current heir.
function HeirInvestment.apply(option_id, heir_genome, resources, world_state, lineage_power)
    local opt = HeirInvestment.OPTIONS[option_id]
    if not opt or not heir_genome or not resources then return false end
    
    local adjusted = HeirInvestment.get_adjusted_cost(option_id, lineage_power)
    
    -- Deduct costs
    for res, amt in pairs(adjusted) do
        resources:change(res, -amt, "Heir Investment: " .. opt.label)
    end
    
    -- Apply bonuses to all traits in category
    local count = 0
    for id, trait in pairs(heir_genome.traits) do
        if id:sub(1, 3) == opt.trait_prefix then
            local current = trait:get_value()
            trait:set_value(math.min(100, current + opt.bonus))
            count = count + 1
        end
    end
    
    if world_state then
        world_state:add_chronicle("The heir underwent " .. opt.label .. ", sharpening their " .. option_id .. " potential.")
    end
    
    return true
end

return HeirInvestment
