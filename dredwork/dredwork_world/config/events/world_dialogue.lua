-- Dark Legacy — World Events: Dialogue & Interactions
-- Special events that involve direct interaction with NPCs (siblings, rivals, court).

return {
    -- ================================================================
    -- SIBLING INTERACTIONS
    -- ================================================================
    {
        id = "sibling_jealousy",
        title = "A Whisper in the Gallery",
        category = "personal",
        weight = 10,
        trigger = { chance = 0.1, requires_court_role = "sibling" },
        interlocutor = { name = "{sibling_name}", role = "Sibling" },
        opening = "Your sibling, {sibling_name}, corners you in the quiet of the ancestral gallery.",
        narrative = "You think you're the only one who carries the weight? I have the same blood. I have the same eyes. Yet I stand in your shadow.",
        options = {
            {
                label = "Comfort them",
                description = "Reassure them of their value to the house.",
                requires = { axis = "PER_LOY", min = 60 },
                consequences = {
                    lineage_power_shift = 2,
                    cultural_memory_shift = { social = 2 }
                }
            },
            {
                label = "Remind them of their place",
                description = "There is only one heir. The blood has chosen.",
                requires = { axis = "PER_PRI", min = 60 },
                consequences = {
                    lineage_power_shift = 5,
                    disposition_changes = { { faction_id = "player", delta = -10 } } -- Loyalty hit
                }
            },
            {
                label = "Offer a shared burden",
                description = "Grant them a holding to govern.",
                requires_resources = { type = "gold", min = 20 },
                consequences = {
                    resource_change = { type = "gold", delta = -20, reason = "Endowment" },
                    lose_holding = "any",
                    found_cadet_branch = true,
                    lineage_power_shift = -5,
                    narrative = "{sibling_name} takes the land and leaves your shadow, disappearing into the wild to forge their own destiny."
                }
            }
        }
    },

    -- ================================================================
    -- RIVAL INTERACTIONS
    -- ================================================================
    {
        id = "rival_temptation",
        title = "A Proposal from the Dark",
        category = "faction",
        weight = 8,
        trigger = { chance = 0.08, requires_rival = true },
        interlocutor = { name = "{rival_name}", role = "Rival Heir" },
        opening = "A secret meeting is arranged. {rival_name} of {faction_name} sits across from you, untouched by guards.",
        narrative = "Our houses have bled each other for a century. Why? For a few mines? For pride? We could own the world together, if you have the courage to betray your own council.",
        options = {
            {
                label = "Consider the pact",
                description = "Listen to their plan. Alliances are forged in blood.",
                requires = { axis = "PER_ADA", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 30 } },
                    add_relationship = { type = "ally", strength = 70, reason = "secret_pact" },
                    lineage_power_shift = -10 -- Council is furious
                }
            },
            {
                label = "Reject them with scorn",
                description = "Blood cannot be bargained with.",
                requires = { axis = "PER_LOY", min = 70 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    lineage_power_shift = 10 -- Council respects the integrity
                }
            }
        }
    },

    -- ================================================================
    -- ROMANCE / SPOUSE INTERACTIONS
    -- ================================================================
    {
        id = "spouse_vision",
        title = "Midnight Whispers",
        category = "personal",
        weight = 10,
        trigger = { chance = 0.1, requires_court_role = "spouse" },
        interlocutor = { name = "{spouse_name}", role = "Spouse" },
        opening = "In the safety of your chambers, your spouse speaks of a vision they had.",
        narrative = "I saw the world as it will be. Ash and silence. Unless we change. Unless we stop building walls and start building bridges.",
        options = {
            {
                label = "Listen to the vision",
                description = "Incorporate their insight into the family's future.",
                requires = { axis = "PER_CUR", min = 60 },
                consequences = {
                    resource_change = { type = "lore", delta = 10, reason = "Spousal insight" },
                    cultural_memory_shift = { mental = 3 }
                }
            },
            {
                label = "Dismiss it as fear",
                description = "Focus on the physical reality of the estate.",
                requires = { axis = "PER_OBS", min = 60 },
                consequences = {
                    lineage_power_shift = 5,
                    cultural_memory_shift = { physical = 2 }
                }
            }
        }
    },

    -- ================================================================
    -- COURT INTERACTIONS
    -- ================================================================
    {
        id = "court_schism",
        title = "The Divided Court",
        narrative = "Two factions within the court have developed irreconcilable visions for the bloodline's future. The tension is no longer whispered — it is shouted.",
        chance = 0.30,
        requires_generation_min = 8,
        options = {
            {
                label = "Mediate the dispute",
                description = "Find common ground. A divided court is a weak court.",
                stat_check = { primary = "SOC_ELO", secondary = "SOC_NEG", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { social = 4 },
                    narrative = "The mediator spoke. Both sides listened — not because they agreed, but because the alternative was worse.",
                },
            },
            {
                label = "Purge the dissidents",
                description = "There can be only one vision. The rest is noise.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { social = -3, physical = 2 },
                    taboo_chance = 0.15,
                    taboo_data = { trigger = "court_purge", effect = "ruthless_governance", strength = 65 },
                    narrative = "The dissenters were removed. The court grew quiet. Whether it was peace or fear, only the survivors knew.",
                },
            },
            {
                label = "Let them compete",
                description = "Set them against each other. The stronger vision will prevail.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = -1 },
                    narrative = "Competition sharpened both factions. The winner brought new ideas. The loser brought grudges.",
                },
            },
        },
    },
    {
        id = "court_fool",
        title = "The Court Fool Speaks True",
        narrative = "The court fool — kept for amusement, tolerated for irreverence — says something that silences the room. Something no advisor dared voice.",
        chance = 0.25,
        options = {
            {
                label = "Heed the fool's wisdom",
                description = "Truth wears strange masks.",
                requires = { axis = "PER_ADA", min = 40 },
                stat_check = { primary = "MEN_INT", secondary = "SOC_AWR", difficulty = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = 1 },
                    narrative = "The fool was right. The court was horrified — not by the truth, but by the fact that a fool had seen it first.",
                },
            },
            {
                label = "Dismiss the fool",
                description = "A jester's words carry no weight. Move on.",
                consequences = {
                    cultural_memory_shift = { social = 1 },
                    narrative = "The fool was waved away. The room laughed. But a few faces in the back did not.",
                },
            },
            {
                label = "Reward and elevate the fool",
                description = "If they see what advisors miss, perhaps they should advise.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = 2, creative = 2 },
                    narrative = "The fool was given a seat at the table. The advisors seethed. The fool grinned. And the bloodline, for once, listened to someone with nothing to lose.",
                },
            },
        },
    },
}
