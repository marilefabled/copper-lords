-- Dark Legacy — Faction Events: Autonomous Inter-Faction
-- Events driven by faction_relations system. Two factions interact independently.
return {
    {
        id = "faction_war_erupts",
        title = "War Between Houses",
        narrative = "War has erupted between {faction_name} and a rival house. The land trembles. You must decide where your bloodline stands.",
        chance = 0.35,
        disposition_min = -30,
        cooldown = 5,
        options = {
            {
                label = "Support {faction_name}",
                description = "Side with them. Earn their loyalty — and their enemies.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 20 } },
                    cultural_memory_shift = { physical = 2, social = 1 },
                    add_condition = { type = "war", intensity = 0.3, duration = 2 },
                    narrative = "The bloodline chose a side. Swords were drawn in another house's name.",
                },
            },
            {
                label = "Stay neutral",
                description = "Let them bleed. Watch from a distance.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { mental = 2 },
                    narrative = "Neutrality. A cold comfort, but a safe one. Both sides noted the silence.",
                },
            },
            {
                label = "Profit from the chaos",
                description = "While they fight, opportunities arise.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    cultural_memory_shift = { social = -2, creative = 2 },
                    mutation_triggers = { { type = "intermarriage", intensity = 0.3 } },
                    narrative = "The bloodline profited from misery. Efficient. Ruthless. Others took note.",
                },
            },
        },
    },
    {
        id = "faction_alliance_offer",
        title = "{faction_name} Proposes a Pact",
        narrative = "{faction_name} has formed a strong bond with another house. Now they seek to include your lineage in their growing coalition.",
        chance = 0.3,
        disposition_min = 15,
        cooldown = 5,
        options = {
            {
                label = "Join the pact",
                description = "Strength in numbers.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    add_relationship = { type = "ally", strength = 50, reason = "coalition_pact" },
                    cultural_memory_shift = { social = 3 },
                    narrative = "A pact was signed. The bloodline had new allies — and new obligations.",
                },
            },
            {
                label = "Decline politely",
                description = "Independence has value.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The offer was declined with grace. Some alliances cost too much.",
                },
            },
            {
                label = "Demand better terms",
                description = "If they want us, they pay for us.",
                requires = { axis = "PER_PRI", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Better terms were demanded. Pride has a price — sometimes others pay it.",
                },
            },
        },
    },
    {
        id = "faction_oathbreaker",
        title = "Betrayal Among Houses",
        narrative = "{faction_name} has betrayed a former ally. The breaking of oaths sends shockwaves through every court.",
        chance = 0.2,
        cooldown = 8,
        options = {
            {
                label = "Condemn the betrayal",
                description = "Oath-breakers must be named.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The betrayal was publicly condemned. Honor demanded nothing less.",
                },
            },
            {
                label = "Ignore it",
                description = "Their quarrels are not yours.",
                consequences = {
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The bloodline said nothing. In silence, there is safety. And complicity.",
                },
            },
            {
                label = "Exploit the opening",
                description = "A broken alliance leaves both sides vulnerable.",
                requires = { axis = "PER_CRM", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = -1, mental = 2 },
                    narrative = "The bloodline moved while others reeled. Opportunism is its own kind of strength.",
                },
            },
        },
    },
    {
        id = "faction_trade_offer",
        title = "Trade from {faction_name}",
        narrative = "{faction_name} proposes an exchange of resources. Their surplus complements your shortage.",
        chance = 0.35,
        disposition_min = -10,
        cooldown = 3,
        options = {
            {
                label = "Accept the trade",
                description = "Fair terms, fairly met.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 1, creative = 1 },
                    narrative = "Goods exchanged hands. A small step toward something larger.",
                },
            },
            {
                label = "Negotiate harder",
                description = "We can get more.",
                requires = { axis = "PER_PRI", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -5 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Hard bargaining. The terms improved — but good will diminished.",
                },
            },
            {
                label = "Refuse and posture",
                description = "We need nothing from them.",
                requires = { axis = "PER_BLD", min = 50 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The trade was refused with contempt. A statement, not a strategy.",
                },
            },
        },
    },
    {
        id = "faction_expansion",
        title = "{faction_name} Expands",
        narrative = "{faction_name} has absorbed a minor lordship. Their borders creep closer. Their ambitions grow.",
        chance = 0.25,
        faction_power_min = 65,
        cooldown = 6,
        options = {
            {
                label = "Demand they halt",
                description = "Their expansion threatens the balance.",
                requires = { axis = "PER_BLD", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -20 } },
                    cultural_memory_shift = { physical = 2, social = 1 },
                    narrative = "A line was drawn. Whether {faction_name} would respect it remained to be seen.",
                },
            },
            {
                label = "Match their expansion",
                description = "If they grow, so must we.",
                requires = { axis = "PER_PRI", min = 50 },
                consequences = {
                    add_condition = { type = "war", intensity = 0.3, duration = 2 },
                    cultural_memory_shift = { physical = 3 },
                    narrative = "Expansion begets expansion. The land groaned under the weight of ambition.",
                },
            },
            {
                label = "Offer a marriage pact",
                description = "If you can't stop them, join them. Your heir must marry from their house.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    mutation_triggers = { { type = "intermarriage", intensity = 0.4 } },
                    cultural_memory_shift = { social = 2 },
                    arranged_marriage_lock = true,
                    narrative = "A marriage was proposed. Blood would mingle. Your heir is betrothed.",
                },
            },
        },
    },
    {
        id = "faction_refugees",
        title = "Refugees from {faction_name}",
        narrative = "People flee from {faction_name}'s territory. Desperate, hungry, skilled. They beg for sanctuary.",
        chance = 0.3,
        faction_power_max = 35,
        cooldown = 4,
        options = {
            {
                label = "Welcome them",
                description = "New hands, new minds, new blood.",
                consequences = {
                    mutation_triggers = { { type = "intermarriage", intensity = 0.3 } },
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 2, creative = 1 },
                    narrative = "The refugees were welcomed. The bloodline grew richer for it.",
                },
            },
            {
                label = "Close the borders",
                description = "Their problems are not ours.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The gates closed. Safety chosen over compassion.",
                },
            },
            {
                label = "Take only the skilled",
                description = "Selective mercy. The useful live.",
                requires = { axis = "PER_CRM", min = 50 },
                consequences = {
                    mutation_triggers = { { type = "intermarriage", intensity = 0.2 } },
                    cultural_memory_shift = { mental = 2, social = -2 },
                    narrative = "Only the useful were admitted. The rest were turned away. Efficient. Cold.",
                },
            },
        },
    },
    {
        id = "faction_cultural_exchange",
        title = "Cultural Envoy from {faction_name}",
        narrative = "Scholars and artisans from {faction_name} arrive bearing knowledge and craft. They seek to share — and to learn.",
        chance = 0.25,
        disposition_min = 10,
        cooldown = 4,
        options = {
            {
                label = "Embrace the exchange",
                description = "Knowledge flows both ways.",
                requires = { axis = "PER_CUR", min = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { creative = 3, mental = 2 },
                    narrative = "Ideas were exchanged. The bloodline saw through new eyes.",
                },
            },
            {
                label = "Accept cautiously",
                description = "Share little, learn much.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 3 } },
                    cultural_memory_shift = { mental = 2 },
                    narrative = "The exchange was careful. Measured. The bloodline gave little and gained much.",
                },
            },
            {
                label = "Reject foreign influence",
                description = "Our ways are sufficient.",
                requires = { axis = "PER_ADA", max = 40 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { physical = 1 },
                    narrative = "Foreign ideas were rejected. Tradition held firm, for better or worse.",
                },
            },
        },
    },
    {
        id = "faction_hostage_exchange",
        title = "Hostage Demand from {faction_name}",
        narrative = "{faction_name} demands a hostage exchange as a sign of faith. A member of each house will live among the other.",
        chance = 0.2,
        disposition_min = -30,
        disposition_max = 30,
        cooldown = 6,
        options = {
            {
                label = "Agree to the exchange",
                description = "A dangerous trust, but trust nonetheless.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 15 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "Hostages were exchanged. A fragile peace, held together by the lives of children.",
                },
            },
            {
                label = "Refuse outright",
                description = "No member of this bloodline will be a prisoner.",
                requires = { axis = "PER_LOY", min = 60 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -15 } },
                    cultural_memory_shift = { physical = 1 },
                    narrative = "The demand was refused. Blood stays with blood.",
                },
            },
        },
    },
    {
        id = "faction_espionage_discovered",
        title = "Spies from {faction_name}",
        narrative = "Your people have uncovered agents of {faction_name} operating in your territory. Spying, mapping, counting swords.",
        chance = 0.2,
        disposition_max = 10,
        cooldown = 5,
        options = {
            {
                label = "Execute them publicly",
                description = "A message to all who would spy on us.",
                requires = { axis = "PER_CRM", min = 55 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -25 } },
                    cultural_memory_shift = { physical = 2, social = -3 },
                    narrative = "The spies died in the square. A message. Effective. Irreversible.",
                },
            },
            {
                label = "Feed them false information",
                description = "Let them report what we want them to report.",
                requires = { axis = "PER_CUR", min = 45 },
                consequences = {
                    cultural_memory_shift = { mental = 3 },
                    narrative = "The spies were turned. Their reports became weapons. Subtlety triumphed.",
                },
            },
            {
                label = "Expel them quietly",
                description = "Send them home. No blood. A warning.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = -10 } },
                    cultural_memory_shift = { social = 1 },
                    narrative = "The spies were sent home alive. A measured response. Diplomatic, even.",
                },
            },
        },
    },
    {
        id = "faction_succession_crisis",
        title = "Succession Crisis in {faction_name}",
        narrative = "{faction_name} is torn apart by a succession dispute. Two claimants fight for control. Both seek your support.",
        chance = 0.2,
        cooldown = 8,
        once_per_run = false,
        options = {
            {
                label = "Support the stronger claimant",
                description = "Back the winner. Reap the rewards.",
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 10 } },
                    cultural_memory_shift = { social = 2 },
                    narrative = "The bloodline backed a winner. The new leader remembered who helped them rise.",
                },
            },
            {
                label = "Support the weaker claimant",
                description = "A grateful puppet is more useful than a proud ally.",
                requires = { axis = "PER_CRM", min = 45 },
                consequences = {
                    disposition_changes = { { faction_id = "_target", delta = 5 } },
                    faction_power_shift = -10,
                    cultural_memory_shift = { mental = 2, social = 1 },
                    narrative = "The weaker claimant won — with help. Gratitude and debt. A useful combination.",
                },
            },
            {
                label = "Let them destroy each other",
                description = "Their weakness is your gain.",
                consequences = {
                    faction_power_shift = -15,
                    cultural_memory_shift = { mental = 1 },
                    narrative = "The bloodline watched as {faction_name} tore itself apart. Patient. Calculating.",
                },
            },
        },
    },
}
