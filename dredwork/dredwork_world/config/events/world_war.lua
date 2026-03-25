-- Dark Legacy — World Events: War
return {
    {
        id = "border_conflict",
        title = "War at the Borders",
        narrative = "Armed forces of {war_target_name} clash at the edges of your territory. The sound of steel reaches {heir_name}'s ears.",
        chance = 0.35,
        cooldown = 3,
        requires_no_condition = "war",
        options = {
            {
                label = "March to the front",
                description = "Lead the defense personally.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.6, duration = 3 },
                    cultural_memory_shift = { physical = 4, mental = 1 },
                    mutation_triggers = { { type = "war", intensity = 0.5 } },
                    narrative = "{heir_name} rode to war against {war_target_name}. The bloodline was tested in iron.",
                },
            },
            {
                label = "Fortify and defend",
                description = "Hold the walls. Let them come to us.",
                consequences = {
                    add_condition = { type = "war", intensity = 0.4, duration = 2 },
                    cultural_memory_shift = { physical = 2 },
                    narrative = "The walls held. {war_target_name} broke against stone and will.",
                },
            },
            {
                label = "Negotiate a truce",
                description = "Words before swords. Find common ground.",
                requires = { axis = "PER_PRI", max = 55 },
                consequences = {
                    cultural_memory_shift = { social = 3, physical = -2 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "A truce was struck with {war_target_name}. Not all were satisfied, but the blood stayed in its veins.",
                },
            },
            {
                label = "Deploy siege engines",
                description = "Your knowledge of siege craft turns a border skirmish into a decisive victory.",
                requires_discovery = "siege_craft",
                consequences = {
                    add_condition = { type = "war", intensity = 0.3, duration = 1 },
                    cultural_memory_shift = { physical = 3, creative = 2 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    narrative = "Engines of war rolled forward against {war_target_name}. The border was not just defended — it was moved.",
                },
            },
            {
                label = "Invoke the Blood of Iron",
                description = "Your dynasty's doctrine of physical supremacy makes this war inevitable — and winnable.",
                requires_doctrine = "blood_of_iron",
                consequences = {
                    add_condition = { type = "war", intensity = 0.5, duration = 2 },
                    cultural_memory_shift = { physical = 5 },
                    mutation_triggers = { { type = "war", intensity = 0.4 } },
                    narrative = "The doctrine demanded war with {war_target_name}. The bloodline answered. Iron rang against iron, and the bloodline's iron was stronger.",
                },
            },
        },
    },
    {
        id = "war_attrition",
        title = "The Grinding War",
        narrative = "The war against {war_target_name} has no end in sight. Supplies dwindle. Morale breaks. Every day costs more than the last.",
        chance = 0.35,
        cooldown = 3,
        requires_condition = "war",
        options = {
            {
                label = "Push forward",
                description = "One decisive strike could end this.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 3, mental = 2 },
                    mutation_triggers = { { type = "war", intensity = 0.6 } },
                    narrative = "The final push against {war_target_name} was brutal, but their line broke. Victory tastes like ash and iron.",
                },
            },
            {
                label = "Sue for peace",
                description = "End this. At any cost.",
                requires = { axis = "PER_PRI", max = 55 },
                consequences = {
                    remove_condition = "war",
                    cultural_memory_shift = { social = 3, physical = -3 },
                    narrative = "Peace was purchased from {war_target_name}. The price was pride. Some thought it too high.",
                },
            },
            {
                label = "Burn their crops",
                description = "Starve them out. Total war.",
                requires = { axis = "PER_CRM", min = 60 },
                consequences = {
                    add_condition = { type = "famine", intensity = 0.3, duration = 2 },
                    cultural_memory_shift = { physical = 2, social = -4 },
                    narrative = "The fields of {war_target_name} burned. Smoke choked the sky. They starved. So did the innocent.",
                },
            },
        },
    },
    {
        id = "war_hero_emerges",
        title = "A Hero of the Blood",
        narrative = "In the chaos of battle against {war_target_name}, a member of the family performed an act of extraordinary valor. The name rings across every camp.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "war",
        options = {
            {
                label = "Celebrate the hero",
                description = "Let the story grow. Morale is everything.",
                consequences = {
                    cultural_memory_shift = { physical = 2, social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "The hero's story spread. Allies rallied. Even {war_target_name} spoke the name with grudging respect.",
                },
            },
            {
                label = "Suppress the glory",
                description = "Heroes attract assassins. Keep the family safe.",
                requires = { axis = "PER_PRI", max = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The hero was quietly honored and hidden. Wisdom, perhaps. But songs die when no one sings them.",
                },
            },
            {
                label = "Exploit the fame",
                description = "Use the hero's reputation to recruit and intimidate.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 3, social = 1 },
                    disposition_changes = { { faction_id = "all", delta = -3 } },
                    narrative = "The hero's name was weaponized against {war_target_name}. Recruitment surged. But the hero themselves was lost in the myth.",
                },
            },
        },
    },
    {
        id = "war_siege",
        title = "The Siege Begins",
        narrative = "Forces of {war_target_name} encircle the stronghold. Supplies will last weeks, not months. The walls are old. The question is not whether they will break, but when.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "war",
        options = {
            {
                label = "Engineer the defenses",
                description = "Reinforce weak points. Build traps. Make them pay for every stone.",
                stat_check = { primary = "CRE_MEC", secondary = "MEN_STR", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { creative = 3, physical = 2 },
                    narrative = "Traps sprung. Walls held. The siege by {war_target_name} broke not against stone, but against the ingenuity of the blood.",
                },
            },
            {
                label = "Sally forth at dawn",
                description = "Break the siege with a single, devastating sortie.",
                requires = { axis = "PER_BLD", min = 60 },
                stat_check = { primary = "PHY_STR", secondary = "SOC_LEA", difficulty = 60 },
                consequences = {
                    cultural_memory_shift = { physical = 4, social = 1 },
                    mutation_triggers = { { type = "war", intensity = 0.7 } },
                    narrative = "The gates opened at first light. What poured out against {war_target_name} was not an army. It was a bloodline's fury.",
                },
            },
            {
                label = "Send for relief",
                description = "A rider slips through the lines. Allies may come — or may not.",
                stat_check = { primary = "SOC_NEG", secondary = "MEN_CUN", difficulty = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    cultural_memory_shift = { social = 3 },
                    narrative = "The rider made it through the lines of {war_target_name}. Allies arrived. The debt would be repaid in kind — or in blood. Either way, it was owed.",
                },
            },
        },
    },
    {
        id = "war_spoils",
        title = "The Spoils of Victory",
        narrative = "The forces of {war_target_name} are routed. Their camp lies open — wealth, weapons, prisoners, and secrets for the taking.",
        chance = 0.25,
        cooldown = 3,
        requires_condition = "war",
        options = {
            {
                label = "Claim everything",
                description = "Winner takes all. This is what victory means.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -2 },
                    narrative = "The camp of {war_target_name} was stripped bare. The victors grew fat on the spoils. The vanquished swore oaths of revenge in the dark.",
                },
            },
            {
                label = "Take only what's needed",
                description = "Moderation in victory speaks louder than greed.",
                consequences = {
                    cultural_memory_shift = { social = 3, mental = 1 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "Restraint was shown. Prisoners of {war_target_name} were returned. Their hatred cooled to grudging respect.",
                },
            },
            {
                label = "Study their weapons",
                description = "The enemy's craft reveals their thinking. Learn from it.",
                requires = { axis = "PER_CUR", min = 45 },
                stat_check = { primary = "CRE_ING", secondary = "MEN_ANA", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    narrative = "The weapons of {war_target_name} were strange. Their metallurgy, stranger. What the smiths learned would shape the bloodline's craft for generations.",
                },
            },
        },
    },
    {
        id = "war_deserters",
        title = "The Deserters",
        narrative = "Soldiers abandon the front against {war_target_name} in the night. They are found hiding in the village. Armed, desperate, and ashamed.",
        chance = 0.30,
        cooldown = 3,
        requires_condition = "war",
        options = {
            {
                label = "Execute them as examples",
                description = "Cowardice in wartime has one answer.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 2, social = -3 },
                    narrative = "The executions were public. No one else deserted. No one else slept well, either.",
                },
            },
            {
                label = "Return them to the line",
                description = "They broke once. Give them a chance to mend.",
                stat_check = { primary = "SOC_LEA", secondary = "SOC_EMP", difficulty = 50 },
                consequences = {
                    cultural_memory_shift = { social = 3 },
                    narrative = "The deserters were returned to face {war_target_name}. Some fought harder than before. Some did not. But the chance was given.",
                },
            },
            {
                label = "Conscript them as scouts",
                description = "Cowards know the terrain. They've already mapped every escape route.",
                requires = { axis = "PER_CUR", min = 40 },
                stat_check = { primary = "MEN_CUN", secondary = "SOC_MAN", difficulty = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 2, social = 1 },
                    narrative = "The deserters proved useful. Fear had made them observant. They knew every shadow and every path {war_target_name} didn't.",
                },
            },
        },
    },
    {
        id = "peace_terms",
        title = "Terms of Peace",
        narrative = "{war_target_name} sends emissaries under truce. They seek an end to the bloodshed — but on their terms.",
        chance = 0.25,
        cooldown = 5,
        requires_condition = "war",
        options = {
            {
                label = "Accept their terms",
                description = "Peace now. The cost can be counted later.",
                consequences = {
                    remove_condition = "war",
                    add_condition = { type = "tribute_owed", intensity = 0.4, duration = 3 },
                    cultural_memory_shift = { social = 3, physical = -2 },
                    narrative = "The terms were signed. Peace settled like dust after a collapse. The tribute would come due soon enough.",
                },
            },
            {
                label = "Counter with your own demands",
                description = "They came to bargain. So will you.",
                stat_check = { primary = "SOC_NEG", secondary = "MEN_CUN", difficulty = 55 },
                consequences = {
                    remove_condition = "war",
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    narrative = "The counter-terms were harsh but fair. {war_target_name} accepted with gritted teeth. Both sides saved face — barely.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "The negotiation collapsed. The emissaries of {war_target_name} left in cold fury. The war continues.",
                },
            },
            {
                label = "Reject and escalate",
                description = "Peace is for the weak. Push for total victory.",
                requires = { axis = "PER_BLD", min = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 4, social = -3 },
                    mutation_triggers = { { type = "war", intensity = 0.6 } },
                    narrative = "The emissaries were sent back with a message written in their own blood. {war_target_name} understood perfectly.",
                },
            },
        },
    },
    {
        id = "war_escalation",
        title = "The War Widens",
        narrative = "Allies of {war_target_name} have entered the conflict. What was one front is now two. The bloodline faces a war on multiple fronts.",
        chance = 0.20,
        cooldown = 5,
        requires_condition = "war",
        options = {
            {
                label = "Fight on all fronts",
                description = "Divide the army. Hold every line.",
                consequences = {
                    cultural_memory_shift = { physical = 3, mental = 2 },
                    mutation_triggers = { { type = "war", intensity = 0.7 } },
                    narrative = "The army split and marched in three directions. It was madness. But the bloodline held — barely.",
                },
            },
            {
                label = "Concentrate on the primary enemy",
                description = "Ignore the newcomers. Break {war_target_name} first.",
                requires = { axis = "PER_OBS", min = 45 },
                stat_check = { primary = "MEN_STR", secondary = "PHY_STR", difficulty = 55 },
                consequences = {
                    cultural_memory_shift = { physical = 4 },
                    narrative = "Everything was thrown at {war_target_name}. The gamble paid off — the primary enemy crumbled. The allies lost their nerve.",
                },
                consequences_fail = {
                    cultural_memory_shift = { physical = 2, social = -2 },
                    narrative = "The concentrated assault failed. Meanwhile, the flanking force ravaged the undefended holdings.",
                },
            },
            {
                label = "Seek allies of your own",
                description = "Two can play at coalition warfare.",
                stat_check = { primary = "SOC_NEG", secondary = "SOC_CHA", difficulty = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 4 },
                    narrative = "Alliances were forged in the heat of desperation. The war became everyone's problem — and that, somehow, made it manageable.",
                },
                consequences_fail = {
                    cultural_memory_shift = { social = -2 },
                    narrative = "No one came. The bloodline fought alone, as it always had.",
                },
            },
        },
    },
}
