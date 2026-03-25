-- Dark Legacy — World Events: Prosperity
return {
    {
        id = "golden_age",
        title = "A Season of Plenty",
        narrative = "Peace reigns. Trade flourishes. The culture of {culture_value_1} shapes how the bloodline spends its abundance.",
        chance = 0.25,
        requires_no_condition = "war",
        options = {
            {
                label = "Invest in the arts",
                description = "Commission great works. Build monuments to beauty.",
                consequences = {
                    cultural_memory_shift = { creative = 4, social = 2 },
                    disposition_changes = { { faction_id = "all", delta = 3 } },
                    narrative = "Beauty flourished under {heir_name}'s patronage.",
                },
            },
            {
                label = "Strengthen defenses",
                description = "Peace never lasts. Prepare for what comes.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    cultural_memory_shift = { physical = 3, mental = 2 },
                    narrative = "While others feasted, {heir_name} built walls. Wise or paranoid? Time would tell.",
                },
            },
            {
                label = "Forge new alliances",
                description = "Prosperity is the best time to make friends.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 4 },
                    narrative = "Treaties were signed. Hands were shaken. The web of alliance grew.",
                },
            },
        },
    },
    {
        id = "trade_boom",
        title = "Markets Overflow",
        narrative = "Trade routes swell with goods from distant lands. Gold flows like water. Everyone wants a piece.",
        chance = 0.25,
        requires_no_condition = { "famine", "war" },
        options = {
            {
                label = "Expand trade routes",
                description = "More connections. More wealth. More influence.",
                consequences = {
                    cultural_memory_shift = { social = 3, mental = 2 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    wealth_change = { delta = 12, source = "trade" },
                    narrative = "New routes were carved across the realm. Gold followed, and with it, influence.",
                },
            },
            {
                label = "Corner the market",
                description = "Why share when you can dominate?",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    cultural_memory_shift = { mental = 3, social = -3 },
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    wealth_change = { delta = 18, source = "crime" },
                    moral_act = { act_id = "exploitation", description = "Cornered the market ruthlessly" },
                    narrative = "The market was cornered. Rivals seethed. The coffers overflowed.",
                },
            },
            {
                label = "Invest in the family",
                description = "Use the surplus to strengthen the bloodline's foundations.",
                consequences = {
                    cultural_memory_shift = { physical = 2, mental = 2, social = 1, creative = 1 },
                    wealth_change = { delta = -5, source = "investment" },
                    narrative = "The wealth was poured into the family. Libraries, training grounds, artisan workshops. The bloodline grew richer in every way.",
                },
            },
            {
                label = "Impose trade levies",
                description = "The roads belong to us. All who use them will pay.",
                requires_lineage_power_min = 60,
                consequences = {
                    cultural_memory_shift = { social = -2, mental = 2 },
                    disposition_changes = { { faction_id = "all", delta = -8 } },
                    wealth_change = { delta = 15, source = "tribute" },
                    moral_act = { act_id = "oppression", description = "Imposed trade levies on weaker houses" },
                    narrative = "Levies were imposed. The trade roads answered to the bloodline. Gold poured in. Resentment simmered.",
                },
            },
        },
    },
    {
        id = "festival_of_unity",
        title = "A Festival of Unity",
        narrative = "A rare moment of peace inspires a grand gathering. All houses are invited. Even old enemies.",
        chance = 0.2,
        requires_no_condition = { "war", "plague" },
        options = {
            {
                label = "Host grandly",
                description = "Spare no expense. Let the world see your magnificence.",
                requires = { axis = "PER_PRI", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 8 } },
                    cultural_memory_shift = { social = 3, creative = 2 },
                    narrative = "The festival was magnificent. Even rivals toasted the host. The name shone.",
                },
            },
            {
                label = "Attend humbly",
                description = "Be present. Be gracious. Let others take the spotlight.",
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Quiet attendance. No spectacle. But genuine warmth that money cannot buy.",
                },
            },
            {
                label = "Use the gathering for espionage",
                description = "Everyone's guard is down. Perfect for intelligence.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "Spies mingled with guests. Secrets were gathered alongside toasts. No one noticed.",
                },
            },
        },
    },
    {
        id = "golden_vein",
        title = "A Vein of Pure Gold",
        narrative = "Miners have struck a massive vein of gold beneath ancestral lands. The potential wealth is staggering.",
        chance = 0.15,
        requires_no_condition = "war",
        options = {
            {
                label = "Mine it relentlessly",
                description = "Extract as much as possible, as fast as possible.",
                requires = { axis = "PER_CRM", min = 40 },
                consequences = {
                    wealth_change = { delta = 30, source = "trade", description = "Exploited a massive gold vein" },
                    cultural_memory_shift = { physical = 2, social = -1 },
                    moral_act = { act_id = "exploitation", description = "Worked miners to the bone for gold" },
                    narrative = "The mines ran day and night. Lives were lost to cave-ins, but the gold flowed.",
                },
            },
            {
                label = "Keep it secret",
                description = "Mine slowly. Don't let the world know how rich you are.",
                requires = { axis = "PER_ADA", min = 45 },
                consequences = {
                    wealth_change = { delta = 15, source = "trade" },
                    cultural_memory_shift = { mental = 3 },
                    narrative = "The gold trickled in quietly. The world remained ignorant of the true depth of the bloodline's wealth.",
                },
            },
            {
                label = "Use it to back a new currency",
                description = "A bold economic move that could redefine power.",
                requires_lineage_power_min = 65,
                consequences = {
                    lineage_power_shift = 15,
                    wealth_change = { delta = 10, source = "investment" },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                    cultural_memory_shift = { creative = 2, social = 2 },
                    narrative = "The gold backed a new currency bearing the family seal. True power is not just having money, but making it.",
                },
            },
        },
    },
    {
        id = "price_of_bread",
        title = "The Cost of Prosperity",
        narrative = "The trade boom has caused massive inflation. The markets are overflowing, but the common people cannot afford bread.",
        chance = 0.20,
        requires_condition = "prosperity",
        options = {
            {
                label = "Subsidize the grain",
                description = "Spend wealth to keep the people fed and happy.",
                consequences = {
                    wealth_change = { delta = -15, source = "investment", description = "Subsidized food for the populace" },
                    disposition_changes = { { faction_id = "all", delta = 10 } },
                    moral_act = { act_id = "charity", description = "Fed the people during high inflation" },
                    cultural_memory_shift = { social = 3 },
                    narrative = "The coffers lightened, but the people's bellies were full. The bloodline was loved, for a time.",
                },
            },
            {
                label = "Let the market correct itself",
                description = "The strong survive. The weak do not.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    wealth_change = { delta = 5, source = "trade" },
                    cultural_memory_shift = { physical = 2, social = -3 },
                    lineage_power_shift = -5,
                    narrative = "The markets churned. Many starved while the merchants grew fat. Resentment fermented in the lower streets.",
                },
            },
            {
                label = "Crack down on merchants",
                description = "Force prices down with the threat of violence.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "all", delta = -5 } },
                    lineage_power_shift = 8,
                    cultural_memory_shift = { physical = 3 },
                    moral_act = { act_id = "oppression", description = "Used violence to control markets" },
                    narrative = "Merchants who defied the price caps were hanged. Bread was cheap, but fear was cheaper.",
                },
            },
        },
    },
}
