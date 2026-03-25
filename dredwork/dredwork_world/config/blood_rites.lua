-- Dark Legacy — Blood Rites (Rites of Attrition)
-- Powerful, desperate measures that burn permanent genetic health
-- for immediate, overwhelming survival benefits.
-- GATING: Religion active + Zealotry 65+ + Gen 15+ + Era (arcane/dark/twilight)
-- or Zealotry 80+ in any era after Gen 15.

return {
    {
        id = "rite_of_iron",
        name = "The Rite of Iron",
        description = "Burn your lineage's vitality to summon a ghostly legion. Permanently degrades PHY_VIT by 20. Grants +50 Steel and +20 Lineage Power.",
        requires_cost = { trait = "PHY_VIT", cost = 20 },
        requires_religion_active = true,
        requires_generation_min = 15,
        requires_zealotry_min = 65,
        requires_era = { "dark", "arcane", "twilight" },
        consequences = {
            resource_change = { type = "steel", delta = 50, reason = "Rite of Iron" },
            lineage_power_shift = 20,
            narrative = "The blood was spilled on the altar. The ancestors marched, their armor ringing in the night. We will survive this, but our children will cough blood.",
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } }
        }
    },
    {
        id = "rite_of_the_golden_calf",
        name = "The Rite of the Golden Calf",
        description = "Transmute empathy into pure gold. Permanently degrades SOC_EMP by 20. Grants +80 Gold and clears all famine conditions.",
        requires_cost = { trait = "SOC_EMP", cost = 20 },
        requires_religion_active = true,
        requires_generation_min = 15,
        requires_zealotry_min = 65,
        requires_era = { "dark", "arcane", "gilded", "twilight" },
        consequences = {
            resource_change = { type = "gold", delta = 80, reason = "Rite of the Golden Calf" },
            remove_condition = "famine",
            narrative = "The heart hardens. The vaults fill. We bought our salvation with our humanity.",
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } }
        }
    },
    {
        id = "rite_of_the_erased",
        name = "The Rite of the Erased",
        description = "Sacrifice your mind to erase a bitter enemy. Permanently degrades MEN_MEM by 20. Instantly kills the Nemesis heir and severely weakens their faction.",
        requires_cost = { trait = "MEN_MEM", cost = 20 },
        requires_religion_active = true,
        requires_generation_min = 20,
        requires_zealotry_min = 75,
        requires_era = { "arcane", "twilight" },
        consequences = {
            kill_nemesis = true,
            faction_power_shift = -30,
            narrative = "We forgot the faces of our grandparents so that our enemy would cease to exist. A fair trade.",
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } }
        }
    },
    {
        id = "rite_of_the_harvest",
        name = "The Rite of the Blood Harvest",
        description = "Burn the physical stature of the lineage to accelerate crop growth. Permanently degrades PHY_HGT and PHY_BLD by 15. Grants +100 Grain.",
        requires_cost = { traits = { "PHY_HGT", "PHY_BLD" }, cost = 15 },
        requires_religion_active = true,
        requires_generation_min = 15,
        requires_zealotry_min = 65,
        requires_era = { "dark", "arcane", "twilight" },
        consequences = {
            resource_change = { type = "grain", delta = 100, reason = "Blood Harvest" },
            remove_condition = "famine",
            narrative = "The soil drank our height and breadth, and returned it as wheat. We will be smaller, but we will not starve.",
            mutation_triggers = { { type = "mystical_proximity", intensity = 0.5 } }
        }
    }
}
