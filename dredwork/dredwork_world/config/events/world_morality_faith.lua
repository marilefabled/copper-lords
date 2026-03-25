-- Bloodweight — World Events: Morality & Faith
-- Events that fire based on moral standing and zealotry, creating pressure and consequence.
return {
    -- ═══════════════════════════════════════════════════════
    -- HIGH MORALITY EVENTS (the burden of righteousness)
    -- ═══════════════════════════════════════════════════════
    {
        id = "saints_burden",
        title = "The Saint's Burden",
        narrative = "Word of the bloodline's virtue has spread beyond the borders. Pilgrims arrive. Petitioners line the road. The desperate crawl to your gate with their hands out and their mouths open.",
        chance = 0.50,
        cooldown = 8,
        requires_morality_min = 50,
        options = {
            {
                label = "Feed and shelter them all",
                description = "The righteous cannot turn away the needy. Even when the needy are legion.",
                consequences = {
                    resource_change = {
                        { type = "grain", delta = -12, reason = "Feeding pilgrims and petitioners" },
                        { type = "gold", delta = -8, reason = "Sheltering the desperate" },
                    },
                    disposition_changes = { { faction_id = "all", delta = 10 } },
                    lineage_power_shift = 12,
                    moral_act = { act_id = "charity", description = "Fed and sheltered pilgrims who came seeking the bloodline's virtue" },
                    narrative = "They ate. They wept. They blessed the family's name. The granaries wept too, but silently.",
                },
            },
            {
                label = "Accept only the useful",
                description = "Charity is a luxury. Select the skilled and the strong. Turn the rest away.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    resource_change = { type = "grain", delta = -5, reason = "Selective charity" },
                    cultural_memory_shift = { mental = 2 },
                    moral_act = { act_id = "pragmatism", description = "Turned away the weak while sheltering the useful" },
                    narrative = "The gates opened for the smiths, the scholars, the soldiers. The rest were given a meal and a direction. Mercy, rationed.",
                },
            },
            {
                label = "Close the gates",
                description = "Enough. Virtue is not an invitation. Let them find another savior.",
                requires = { axis = "PER_CRM", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    cultural_memory_shift = { social = -3 },
                    moral_act = { act_id = "abandonment", description = "Turned away pilgrims who came seeking the bloodline's aid" },
                    narrative = "The gates slammed shut. The petitioners wailed. The heir watched from the wall and felt nothing. Or tried to.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- LOW MORALITY EVENTS (the world turns against you)
    -- ═══════════════════════════════════════════════════════
    {
        id = "the_reckoning",
        title = "The Reckoning",
        narrative = "The bloodline's sins have become a story told in every tavern and temple. An alliance of the wronged has formed. They do not want gold. They want justice.",
        chance = 0.55,
        cooldown = 10,
        requires_morality_max = -40,
        requires_generation_min = 8,
        options = {
            {
                label = "Pay reparations",
                description = "Gold buys forgiveness. Or at least silence.",
                requires_resources = { type = "gold", min = 25 },
                consequences = {
                    resource_change = { type = "gold", delta = -25, reason = "Reparations to the wronged" },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    moral_act = { act_id = "sacrifice", description = "Paid reparations for the bloodline's accumulated sins" },
                    narrative = "The gold was counted, divided, and distributed. It did not undo anything. But the mob dispersed.",
                },
            },
            {
                label = "Publicly atone",
                description = "The heir kneels in the dirt. The bloodline confesses. It costs nothing but pride.",
                requires = { axis = "PER_PRI", max = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 12 } },
                    lineage_power_shift = -10,
                    cultural_memory_shift = { social = 5 },
                    moral_act = { act_id = "sacrifice", description = "Publicly knelt before the wronged and confessed the bloodline's sins" },
                    narrative = "The heir knelt in the market square and spoke every sin aloud. The crowd listened in silence. When it was over, something had changed. Maybe.",
                },
            },
            {
                label = "Crush the accusers",
                description = "The strong do not apologize. Scatter them.",
                requires = { axis = "PER_BLD", min = 60 },
                stat_check = {
                    primary = { trait = "PHY_STR", weight = 1.0 },
                    secondary = { trait = "SOC_INF", weight = 0.5 },
                    difficulty = 50,
                },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -15 } },
                    cultural_memory_shift = { physical = 3, social = -5 },
                    lineage_power_shift = 5,
                    moral_act = { act_id = "cruelty", description = "Crushed an alliance of the wronged who demanded justice" },
                    narrative = "The accusers were scattered by riders. The stories would continue. But the storytellers had learned to whisper.",
                },
                consequences_fail = {
                    disposition_changes = { { faction_id = "all", delta = -20 } },
                    cultural_memory_shift = { social = -6 },
                    lineage_power_shift = -12,
                    moral_act = { act_id = "cruelty", description = "Tried and failed to silence the bloodline's accusers" },
                    narrative = "The riders were turned back. The accusers grew bolder. The bloodline's name became synonymous with weakness and evil — the worst possible combination.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- HIGH ZEALOTRY EVENTS (the faith demands)
    -- ═══════════════════════════════════════════════════════
    {
        id = "zealots_demand",
        title = "The Faithful Demand",
        narrative = "The priesthood arrives in force. The zealots have decided that the bloodline must prove its devotion — not with words, but with sacrifice.",
        chance = 0.50,
        cooldown = 6,
        requires_zealotry_min = 60,
        options = {
            {
                label = "Submit to the tithe",
                description = "Give the faith what it wants. Gold, grain, obedience.",
                consequences = {
                    resource_change = {
                        { type = "gold", delta = -12, reason = "Mandatory tithe" },
                        { type = "grain", delta = -8, reason = "Temple provisions" },
                    },
                    cultural_memory_shift = { social = 3 },
                    moral_act = { act_id = "honoring_oath", description = "Submitted to the faith's tithe demands" },
                    narrative = "The coffers were opened for the priests. They took what they wanted and blessed what remained.",
                },
            },
            {
                label = "Offer a relic instead",
                description = "Give the faith something priceless. A single offering to satisfy an endless hunger.",
                requires_resources = { type = "lore", min = 8 },
                consequences = {
                    resource_change = { type = "lore", delta = -8, reason = "Sacred relic donated to temple" },
                    cultural_memory_shift = { creative = 2, mental = -1 },
                    lineage_power_shift = 5,
                    narrative = "An ancestral tome was surrendered to the temple. The priests were appeased. The library was diminished.",
                },
            },
            {
                label = "Refuse the priesthood",
                description = "The bloodline bows to no clergy. Let the faith remember who built the temples.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    cultural_memory_shift = { mental = 2, social = -3 },
                    moral_act = { act_id = "pragmatism", description = "Refused the priesthood's demands for tribute" },
                    narrative = "The heir stood in the temple doorway and said no. The priests retreated. The cracks in the faith widened.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- ZEALOTRY × MORALITY CROSSOVER
    -- ═══════════════════════════════════════════════════════
    {
        id = "holy_war_pressure",
        title = "The Crusade Beckons",
        narrative = "The priesthood has identified an enemy of the faith among the rival houses. They demand a holy war. Refusal would mark the bloodline as faithless.",
        chance = 0.45,
        cooldown = 10,
        requires_zealotry_min = 65,
        requires_no_condition = "war",
        requires_generation_min = 10,
        options = {
            {
                label = "Declare holy war",
                description = "March under the faith's banner. The priests will bless the blades. The faithful will follow.",
                consequences = {
                    add_condition = { type = "war", intensity = 0.6, duration = 3 },
                    cultural_memory_shift = { physical = 4, social = -2 },
                    resource_change = { type = "steel", delta = -8, reason = "Arming the crusade" },
                    lineage_power_shift = 10,
                    moral_act = { act_id = "ruthless_order", description = "Declared holy war at the priesthood's demand" },
                    narrative = "The banners were blessed. The swords were anointed. The bloodline marched to war in the name of something larger than itself.",
                },
            },
            {
                label = "Fund the war without fighting",
                description = "Pay for the crusade. Let others bleed.",
                requires_resources = { type = "gold", min = 20 },
                consequences = {
                    resource_change = { type = "gold", delta = -20, reason = "Crusade funding" },
                    cultural_memory_shift = { social = 1 },
                    moral_act = { act_id = "pragmatism", description = "Funded a holy war without participating" },
                    narrative = "The gold flowed to the crusade. Mercenaries fought in the bloodline's name while the heir watched from behind walls.",
                },
            },
            {
                label = "Refuse the crusade",
                description = "No. Wars are fought for land and gold, not gods. Let the priests find another sword.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = -4 },
                    lineage_power_shift = -5,
                    moral_act = { act_id = "diplomacy", description = "Refused the priesthood's demand for holy war" },
                    narrative = "The heir refused. The priests cursed the family from the pulpit. The faithful muttered. But no one marched.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- RELIGIOUS HYPOCRISY (high zealotry + low morality)
    -- ═══════════════════════════════════════════════════════
    {
        id = "religious_hypocrisy",
        title = "The Hypocrite's Mirror",
        narrative = "A wandering preacher has arrived at the gates, and the people flock to hear. The sermon is about your bloodline — about the gap between what the faith demands and what the family does.",
        chance = 0.55,
        cooldown = 8,
        requires_zealotry_min = 45,
        requires_morality_max = -15,
        requires_generation_min = 6,
        options = {
            {
                label = "Silence the preacher",
                description = "Heresy against the ruling house is still heresy.",
                requires = { axis = "PER_CRM", min = 45 },
                consequences = {
                    cultural_memory_shift = { social = -4 },
                    moral_act = { act_id = "oppression", description = "Silenced a preacher who spoke against the bloodline's hypocrisy" },
                    narrative = "The preacher was dragged from the market square. The people watched in silence. The sermon continued in whispers.",
                },
            },
            {
                label = "Debate the preacher publicly",
                description = "Meet the accusation with words, not fists. Win the crowd.",
                stat_check = {
                    primary = { trait = "SOC_ELO", weight = 1.0 },
                    secondary = { trait = "MEN_INT", weight = 0.5 },
                    difficulty = 50,
                },
                consequences = {
                    cultural_memory_shift = { social = 3, mental = 2 },
                    lineage_power_shift = 8,
                    narrative = "The heir met the preacher in the square and spoke. The crowd listened. By nightfall, the preacher had been forgotten. The heir had not.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -3 },
                    lineage_power_shift = -8,
                    narrative = "The heir spoke, and the preacher dismantled every argument. The crowd turned. The bloodline's hypocrisy was now a proven fact.",
                },
            },
            {
                label = "Reform. Genuinely.",
                description = "The preacher is right. Change the bloodline's ways.",
                requires = { axis = "PER_ADA", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = 5, physical = -2 },
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    moral_act = { act_id = "sacrifice", description = "Reformed the bloodline's practices after public condemnation" },
                    lineage_power_shift = 5,
                    narrative = "The heir listened. The heir changed. The preacher left satisfied. Whether the change would last was another question entirely.",
                },
            },
        },
    },

    -- ═══════════════════════════════════════════════════════
    -- SCHISM AFTERMATH (low zealotry after schism)
    -- ═══════════════════════════════════════════════════════
    {
        id = "faith_vacuum",
        title = "The Empty Temple",
        narrative = "The faith has fractured. The temples stand half-empty. Something must fill the void — new devotion, or something worse.",
        chance = 0.60,
        cooldown = 10,
        requires_zealotry_min = 5,
        requires_morality_max = 80,
        requires_generation_min = 8,
        once_per_run = true,
        options = {
            {
                label = "Rebuild the faith from within",
                description = "Start over. New tenets, new priests, same god. Maybe.",
                requires_resources = { type = "gold", min = 15 },
                consequences = {
                    resource_change = { type = "gold", delta = -15, reason = "Temple reconstruction" },
                    cultural_memory_shift = { social = 4, creative = 2 },
                    moral_act = { act_id = "honoring_oath", description = "Rebuilt the faith after schism" },
                    narrative = "The temples were scrubbed clean and rededicated. New priests were trained. The faithful returned, cautious but hopeful.",
                },
            },
            {
                label = "Let the faith die",
                description = "Some institutions serve their purpose and then rot. Let it go.",
                requires = { axis = "PER_CUR", min = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 4, social = -3 },
                    lineage_power_shift = -5,
                    narrative = "The temples fell silent. The priests drifted away. The bloodline stood alone, unblessed and unburdened.",
                },
            },
            {
                label = "Fill the void with fear",
                description = "If they will not worship, they will obey. Replace devotion with discipline.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 3, social = -5 },
                    lineage_power_shift = 8,
                    moral_act = { act_id = "oppression", description = "Replaced religious devotion with authoritarian control" },
                    narrative = "The empty temples became courthouses. The priests became enforcers. The faithful became the obedient.",
                },
            },
        },
    },
}
