-- Dark Legacy — Faction Ambition Events
-- High-stakes events driven by faction ambitions (expansion, dominance, revenge, etc.)
-- These fire when factions pursue autonomous goals.
return {
    -- 1. The Ultimatum (expansion ambition, progress > 70)
    {
        id = "faction_ultimatum",
        title = "The Ultimatum of {faction_name}",
        narrative = "{faction_name} has grown bold. Their emissary arrives not to negotiate, but to demand. A holding, they say, or war. The choice is {heir_name}'s — but the clock is theirs.",
        chance = 0.40,
        cooldown = 8,
        disposition_max = 20,
        requires_ambition = "expansion",
        requires_ambition_progress_min = 70,
        faction_power_min = 55,
        options = {
            {
                label = "Cede a holding",
                description = "Give them what they want. Live to fight another day.",
                consequences = {
                    narrative = "Land was signed away. The emissary smiled — the kind of smile that promises they'll be back for more.",
                    cultural_memory_shift = { social = -3, physical = -2 },
                    lose_holding = true,
                    disposition_changes = { { faction_id = "{faction_id}", delta = 15 } },
                },
            },
            {
                label = "Refuse and prepare for war",
                description = "They want war? They'll have it.",
                requires = { axis = "PER_BLD", min = 40 },
                consequences = {
                    narrative = "The emissary was sent back with the bloodline's answer: steel, not soil. {faction_name} mobilized within the week.",
                    add_condition = { type = "war", intensity = 0.6, duration = 4 },
                    cultural_memory_shift = { physical = 4 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -30 } },
                },
            },
            {
                label = "Counter-demand: they kneel or bleed",
                description = "Turn their ultimatum back on them. Audacity has its own currency.",
                requires = { axis = "PER_PRI", min = 60 },
                stat_check = { primary = "SOC_NEG", secondary = "SOC_CHA", difficulty = 60 },
                consequences = {
                    narrative = "The counter-demand landed like a slap. {faction_name} recoiled — and for the first time, hesitated. Power recognized power.",
                    cultural_memory_shift = { social = 5 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                },
                consequences_fail = {
                    narrative = "The bluff was called. {faction_name}'s emissary laughed — actually laughed — and the war began that same evening.",
                    add_condition = { type = "war", intensity = 0.7, duration = 4 },
                    cultural_memory_shift = { social = -3 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -35 } },
                },
            },
        },
    },
    -- 2. The Siege (dominance ambition, during war)
    {
        id = "faction_siege",
        title = "The Siege of the Seat",
        narrative = "{faction_name} has brought their full strength to bear. The ancestral seat is surrounded. Fires burn on every horizon. {heir_name} stands on the walls and counts the banners.",
        chance = 0.35,
        cooldown = 6,
        requires_condition = "war",
        requires_ambition = "dominance",
        faction_power_min = 50,
        options = {
            {
                label = "Defend the walls",
                description = "Stone and will. That's all you need.",
                stat_check = { primary = "PHY_STR", secondary = "MEN_COM", difficulty = 55 },
                consequences = {
                    narrative = "The walls held. {faction_name}'s siege engines burned. The defenders paid in blood, but the seat endured.",
                    cultural_memory_shift = { physical = 5, mental = 2 },
                },
                consequences_fail = {
                    narrative = "A breach. The walls that had stood for generations crumbled. {faction_name} poured through. The seat was saved only by the chaos of their own victory.",
                    cultural_memory_shift = { physical = 2 },
                    lose_holding = true,
                },
            },
            {
                label = "Negotiate surrender terms",
                description = "Preserve the people. Sacrifice the pride.",
                consequences = {
                    narrative = "The gates opened. {faction_name} entered as conquerors. The terms were generous — which somehow made it worse.",
                    remove_condition = "war",
                    add_condition = { type = "tribute_owed", intensity = 0.5, duration = 4 },
                    cultural_memory_shift = { social = 3, physical = -4 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 15 } },
                },
            },
            {
                label = "Sally forth at dawn",
                description = "One charge. Everything on the line.",
                requires = { axis = "PER_BLD", min = 60 },
                stat_check = { primary = "PHY_STR", secondary = "SOC_LEA", difficulty = 65 },
                consequences = {
                    narrative = "The gates opened before first light. What {faction_name} mistook for desperation was fury. The siege broke like a fever.",
                    remove_condition = "war",
                    cultural_memory_shift = { physical = 6 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -15 } },
                },
                consequences_fail = {
                    narrative = "The sortie failed. {heir_name}'s charge was met with a wall of steel. The retreat was worse than the charge.",
                    cultural_memory_shift = { physical = -2 },
                    mutation_triggers = { { type = "war", intensity = 0.8 } },
                },
            },
        },
    },
    -- 3. Blood Debt Called (revenge ambition, grudge active)
    {
        id = "faction_blood_debt",
        title = "The Blood Debt of {faction_name}",
        narrative = "{faction_name} has not forgotten. Their emissary arrives with a ledger — not of gold, but of grievances. Every slight catalogued. Every wound remembered. They demand reparations.",
        chance = 0.40,
        cooldown = 8,
        requires_ambition = "revenge",
        requires_grudge_against_player = true,
        options = {
            {
                label = "Pay the debt",
                description = "Gold for peace. The oldest transaction in the world.",
                consequences = {
                    narrative = "The debt was paid. {faction_name} accepted with the cold satisfaction of the vindicated. The grudge faded — but never quite vanished.",
                    cultural_memory_shift = { social = 2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 25 } },
                    clear_grudge = true,
                    resource_cost = { gold = 15 },
                },
            },
            {
                label = "Refuse the demand",
                description = "Debts are for merchants. This is a bloodline.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    narrative = "The refusal was absolute. {faction_name}'s emissary turned pale — then red. The grudge deepened into something uglier.",
                    add_condition = { type = "war", intensity = 0.5, duration = 3 },
                    cultural_memory_shift = { physical = 2, social = -3 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -20 } },
                    intensify_grudge = 20,
                },
            },
            {
                label = "Negotiate a partial settlement",
                description = "Meet them halfway. Neither side loses face entirely.",
                stat_check = { primary = "SOC_NEG", secondary = "MEN_CUN", difficulty = 50 },
                consequences = {
                    narrative = "A compromise. {faction_name} accepted less than they demanded, and the bloodline paid less than it feared. Both sides claimed victory.",
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 10 } },
                    resource_cost = { gold = 8 },
                },
                consequences_fail = {
                    narrative = "The negotiation collapsed into recriminations. {faction_name} stormed out. The debt remains — and now it has interest.",
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                },
            },
        },
    },
    -- 4. Coalition Demands (hegemony — 2+ allied factions)
    {
        id = "faction_coalition",
        title = "The Coalition Speaks",
        narrative = "It is not one house that stands before {heir_name}, but many. {faction_name} leads a coalition of the willing — or the coerced. Their terms are presented as one voice.",
        chance = 0.30,
        cooldown = 10,
        requires_ambition = "hegemony",
        requires_ambition_progress_min = 60,
        faction_power_min = 50,
        options = {
            {
                label = "Submit to their terms",
                description = "A coalition of houses is not something you fight. Not today.",
                consequences = {
                    narrative = "The bloodline bent. The coalition's terms were mild — suspiciously so. But the alternative was annihilation.",
                    cultural_memory_shift = { social = -4, physical = -2 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                },
            },
            {
                label = "Defy them all",
                description = "Let them come. All of them.",
                requires = { axis = "PER_BLD", min = 65 },
                consequences = {
                    narrative = "The bloodline stood alone against the world. It was magnificent. It was also extremely dangerous.",
                    add_condition = { type = "war", intensity = 0.7, duration = 4 },
                    cultural_memory_shift = { physical = 5, social = -5 },
                    disposition_changes = { { faction_id = "all", delta = -15 } },
                },
            },
            {
                label = "Split the coalition",
                description = "A chain is only as strong as its weakest link. Find it.",
                stat_check = { primary = "SOC_MAN", secondary = "MEN_CUN", difficulty = 60 },
                consequences = {
                    narrative = "Whispers were planted. Old rivalries inflamed. The coalition fractured from within. {faction_name} was left standing alone, furious and exposed.",
                    cultural_memory_shift = { social = 6, mental = 2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -20 } },
                },
                consequences_fail = {
                    narrative = "The attempt to divide them only united them further. The coalition held, and their terms grew harsher.",
                    cultural_memory_shift = { social = -3 },
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                },
            },
        },
    },
    -- 5. Desperate Gambit (survival ambition, power < 20)
    {
        id = "faction_desperate_gambit",
        title = "The Last Plea of {faction_name}",
        narrative = "{faction_name} is dying. Their emissary arrives not with demands, but with desperation. Everything they have — knowledge, land, loyalty — offered in exchange for protection.",
        chance = 0.45,
        cooldown = 10,
        requires_ambition = "survival",
        faction_power_max = 25,
        options = {
            {
                label = "Accept their offer",
                description = "A dying house's gratitude is worth something. So are their holdings.",
                consequences = {
                    narrative = "The deal was struck. {faction_name}'s remaining holdings passed to the bloodline. Their scholars joined your court. Their enemies became yours.",
                    cultural_memory_shift = { social = 3, mental = 2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 40 } },
                    resource_gain = { lore = 10, gold = 5 },
                },
            },
            {
                label = "Refuse and let them fall",
                description = "The weak perish. That is the weight of things.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    narrative = "{faction_name}'s emissary wept. The bloodline turned away. Within two generations, {faction_name} was a footnote.",
                    cultural_memory_shift = { physical = 1, social = -2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -30 } },
                },
            },
            {
                label = "Absorb through marriage",
                description = "Not charity — merger. Their blood strengthens yours.",
                consequences = {
                    narrative = "A marriage sealed the pact. {faction_name}'s bloodline mingled with yours. Their name faded, but their traits endured.",
                    cultural_memory_shift = { social = 4, creative = 2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 30 } },
                    mutation_triggers = { { type = "crossover", intensity = 0.4 } },
                },
            },
        },
    },
    -- 6. The Coup (any faction power > 80, player LP < 30)
    {
        id = "faction_coup",
        title = "The Coup",
        narrative = "{faction_name} moves against the bloodline. In the night, soldiers in unfamiliar livery seal the gates. {heir_name} wakes to the sound of steel on stone.",
        chance = 0.35,
        cooldown = 12,
        faction_power_min = 75,
        requires_lineage_power_max = 35,
        requires_generation_min = 10,
        options = {
            {
                label = "Crush the coup",
                description = "They came for the bloodline. The bloodline will answer.",
                stat_check = { primary = "PHY_STR", secondary = "SOC_LEA", difficulty = 60 },
                consequences = {
                    narrative = "The coup was broken before dawn. {faction_name}'s agents were dragged from hiding. The bloodline's fury was absolute.",
                    cultural_memory_shift = { physical = 5 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -40 } },
                },
                consequences_fail = {
                    narrative = "The resistance was valiant but insufficient. {faction_name}'s forces overwhelmed the household guard. The seat was lost.",
                    cultural_memory_shift = { physical = 2, social = -4 },
                    lose_holding = true,
                    disposition_changes = { { faction_id = "{faction_id}", delta = -20 } },
                },
            },
            {
                label = "Negotiate a power-sharing arrangement",
                description = "They have the swords. You have the name. Both matter.",
                stat_check = { primary = "SOC_NEG", secondary = "MEN_CUN", difficulty = 55 },
                consequences = {
                    narrative = "Terms were struck in whispers while soldiers waited. {faction_name} gained influence. The bloodline kept its name. Whether that's a victory depends on whom you ask.",
                    cultural_memory_shift = { social = 4 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 10 } },
                },
                consequences_fail = {
                    narrative = "The negotiation was a stalling tactic — and {faction_name} knew it. They took what they wanted anyway.",
                    cultural_memory_shift = { social = -3 },
                    lose_holding = true,
                },
            },
            {
                label = "Flee into exile",
                description = "Survive today. Return tomorrow.",
                consequences = {
                    narrative = "The bloodline fled before dawn, carrying what it could. {faction_name} claimed the seat. The exile began.",
                    add_condition = { type = "exodus", intensity = 0.6, duration = 3 },
                    cultural_memory_shift = { physical = -3, mental = 2 },
                    lose_holding = true,
                    disposition_changes = { { faction_id = "{faction_id}", delta = -15 } },
                },
            },
        },
    },
    -- 7. The Grand Challenge (dominance, no active war)
    {
        id = "faction_grand_challenge",
        title = "The Grand Challenge",
        narrative = "{faction_name} issues a challenge that echoes across {era_name}. A contest of prowess — champions of each house, witnessed by all. The stakes: supremacy.",
        chance = 0.30,
        cooldown = 8,
        requires_ambition = "dominance",
        requires_ambition_progress_min = 50,
        requires_no_condition = "war",
        options = {
            {
                label = "Accept the challenge",
                description = "The bloodline has never backed down from a contest.",
                requires = { axis = "PER_BLD", min = 40 },
                stat_check = { primary = "PHY_STR", secondary = "MEN_WIL", difficulty = 55 },
                consequences = {
                    narrative = "The challenge was met. The bloodline's champion fought with the weight of generations behind every blow. {faction_name} learned what they were truly facing.",
                    cultural_memory_shift = { physical = 5, social = 3 },
                    disposition_changes = { { faction_id = "all", delta = 5 } },
                },
                consequences_fail = {
                    narrative = "The bloodline's champion fell. {faction_name} claimed supremacy before witnesses. The shame would linger for generations.",
                    cultural_memory_shift = { physical = -2, social = -4 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                },
            },
            {
                label = "Decline the challenge",
                description = "Contests are for those with something to prove. You don't.",
                requires = { axis = "PER_PRI", max = 45 },
                consequences = {
                    narrative = "The bloodline declined. {faction_name} crowed about cowardice. The world shrugged — mostly.",
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -5 } },
                },
            },
            {
                label = "Accept, but rig the outcome",
                description = "Victory at any cost. They'll never know.",
                requires = { axis = "PER_CRM", min = 50 },
                stat_check = { primary = "MEN_CUN", secondary = "SOC_MAN", difficulty = 50 },
                consequences = {
                    narrative = "The fix was in. The bloodline's champion won — and only three people alive knew why. {faction_name} suspected, but proof is harder than suspicion.",
                    cultural_memory_shift = { mental = 3, social = 1 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -5 } },
                },
                consequences_fail = {
                    narrative = "The cheating was discovered mid-contest. The scandal was spectacular. Every house in the land heard of the bloodline's dishonor.",
                    cultural_memory_shift = { social = -6 },
                    disposition_changes = { { faction_id = "all", delta = -10 } },
                },
            },
        },
    },
    -- 8. Cultural Submission (cultural_supremacy ambition)
    {
        id = "faction_cultural_mandate",
        title = "The Cultural Mandate of {faction_name}",
        narrative = "{faction_name} does not come with swords, but with scholars and architects. They demand the bloodline adopt their ways — their art, their customs, their values. The threat is unspoken but clear.",
        chance = 0.35,
        cooldown = 8,
        requires_ambition = "cultural_supremacy",
        requires_ambition_progress_min = 60,
        options = {
            {
                label = "Accept their cultural influence",
                description = "Adaptation is survival. Their ways have merit.",
                consequences = {
                    narrative = "The bloodline bent its customs toward {faction_name}'s traditions. Something was lost. Something new was gained. Whether the exchange was fair would take generations to judge.",
                    cultural_memory_shift = { creative = 3, social = 2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = 20 } },
                },
            },
            {
                label = "Resist their influence",
                description = "The bloodline has its own identity. It will not be rewritten.",
                requires = { axis = "PER_PRI", min = 45 },
                consequences = {
                    narrative = "The bloodline held fast to its own traditions. {faction_name}'s scholars were politely escorted to the border. The message was clear.",
                    cultural_memory_shift = { social = -2 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -15 } },
                },
            },
            {
                label = "Counter-influence: spread your culture to them",
                description = "Two can play at cultural warfare.",
                stat_check = { primary = "CRE_ING", secondary = "SOC_CHA", difficulty = 55 },
                consequences = {
                    narrative = "The bloodline's own traditions proved more infectious than {faction_name} expected. Their own people began adopting your customs. The irony was delicious.",
                    cultural_memory_shift = { creative = 4, social = 3 },
                    disposition_changes = { { faction_id = "{faction_id}", delta = -10 } },
                },
                consequences_fail = {
                    narrative = "The cultural counter-offensive fell flat. {faction_name}'s traditions were simply more compelling to the masses. The bloodline's influence waned.",
                    cultural_memory_shift = { creative = -2 },
                },
            },
        },
    },
}
