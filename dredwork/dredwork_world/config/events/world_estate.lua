-- Dark Legacy — Estate & Court Events
-- Events specifically focused on acquiring/losing Holdings, Artifacts, and Court members.

return {
    -- ================================================================
    -- HOLDINGS EVENTS
    -- ================================================================
    {
        id = "the_lost_mine",
        title = "The Glimmer in the Dark",
        category = "world",
        weight = 10,
        trigger = { era = "all", chance = 0.05 },
        opening = "Scouts returning from the borderlands speak of a forgotten vein of iron in the high crags.",
        options = {
            {
                label = "Claim the land",
                narrative = "{heir_name} sends a company of soldiers to plant the family sigil.",
                check = { type = "stat", trait = "SOC_LEA", difficulty = 60 },
                consequences = {
                    gain_holding = { name = "Iron Crag Mine", type = "mine", size = 2 },
                    lineage_power_shift = 5
                },
                consequences_fail = {
                    lineage_power_shift = -5,
                    narrative = "The claim is contested by local tribes. The venture ends in a bloody retreat."
                }
            },
            {
                label = "Sell the coordinates",
                narrative = "Better to have gold in hand than iron in the ground.",
                consequences = {
                    wealth_change = { delta = 15, source = "trade", description = "Sold mining rights" }
                }
            }
        }
    },
    {
        id = "the_frontier_village",
        title = "A Petition for Protection",
        category = "world",
        weight = 10,
        trigger = { era = "all", chance = 0.05 },
        opening = "A group of settlers offers their loyalty in exchange for the family's protection.",
        options = {
            {
                label = "Incorporate them",
                narrative = "{heir_name} accepts the petition, adding the village to the estate.",
                consequences = {
                    gain_holding = { name = "generate", type = "village", size = 1 },
                    wealth_change = { delta = -5, source = "investment", description = "Initial infrastructure" }
                }
            },
            {
                label = "Refuse and tax",
                narrative = "We offer no protection, but they still tread on our sphere of influence.",
                consequences = {
                    wealth_change = { delta = 8, source = "tax", description = "Border transit fees" }
                }
            }
        }
    },

    -- ================================================================
    -- RELIQUARY EVENTS
    -- ================================================================
    {
        id = "the_forging",
        title = "The Masterwork",
        category = "personal",
        weight = 15,
        trigger = { traits = { CRE_CRA = 75 }, chance = 0.1 },
        opening = "{heir_name} has spent years in the ancestral forges, obsessing over a singular design.",
        options = {
            {
                label = "Forge a weapon",
                narrative = "A blade that will never dull, carrying the weight of the bloodline.",
                consequences = {
                    gain_artifact = { name = "Blood-Edge", type = "weapon", effect = { trait_bonus = { PHY_STR = 10 } } }
                }
            },
            {
                label = "Forge a crown",
                narrative = "A symbol of authority that radiates command.",
                consequences = {
                    gain_artifact = { name = "The Iron Circlet", type = "relic", effect = { lineage_power_bonus = 10 } }
                }
            }
        }
    },

    -- ================================================================
    -- COURT EVENTS
    -- ================================================================
    {
        id = "the_distant_cousin",
        title = "A Branch Reconnected",
        category = "world",
        weight = 10,
        trigger = { chance = 0.08 },
        opening = "A distant relation, carrying the family's sharp eyes but none of its coin, arrives at the gates.",
        options = {
            {
                label = "Welcome them to court",
                narrative = "{heir_name} grants them a seat at the table. Blood is blood.",
                consequences = {
                    add_court_member = { name = "Cousin Alaric", role = "advisor", loyalty = 60, competence = 70 }
                }
            },
            {
                label = "Send them to the borders",
                narrative = "If they wish to be family, let them prove it in the mud.",
                consequences = {
                    add_court_member = { name = "Cousin Alaric", role = "guard", loyalty = 40, competence = 80 }
                }
            }
        }
    },

    -- ================================================================
    -- RESOURCE & LOGISTICS EVENTS
    -- ================================================================
    {
        id = "the_grain_trade",
        title = "A Hunger in the Lowlands",
        category = "world",
        weight = 12,
        trigger = { chance = 0.1 },
        opening = "A neighboring house is starving. They offer a wagon of refined gold for any steel we can spare to guard their borders.",
        options = {
            {
                label = "Sell the steel",
                narrative = "{heir_name} empties the armories for a chest of coin.",
                consequences = {
                    resource_change = { type = "steel", delta = -10, reason = "Trade" },
                    resource_change_2 = { type = "gold", delta = 25, reason = "Trade" }
                }
            },
            {
                label = "Refuse terms",
                narrative = "Steel is life. Gold cannot buy a sharp blade when the war comes.",
                consequences = {
                    lineage_power_shift = 2
                }
            }
        }
    },
    {
        id = "the_forbidden_library",
        title = "The Heretic's Hoard",
        category = "world",
        weight = 8,
        trigger = { era = "all", chance = 0.06 },
        opening = "A vault of ancient scrolls has been unearthed in a ruined holding. The faith marks it as forbidden.",
        options = {
            {
                label = "Seize the lore",
                narrative = "{heir_name} ignores the priests, claiming the knowledge for the bloodline.",
                consequences = {
                    resource_change = { type = "lore", delta = 15, reason = "Discovery" },
                    religion_action = "preserve"
                }
            },
            {
                label = "Burn the vault",
                narrative = "Some things are better left forgotten. The faith is pleased.",
                consequences = {
                    religion_action = "boost_zealotry",
                    lineage_power_shift = 5
                }
            }
        }
    }
}
