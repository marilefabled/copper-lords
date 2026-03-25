-- Dark Legacy — Procedural Event Narrative Fragments
-- Pure data. Text fragments for combinatorial event generation.
-- Organized by archetype x era/condition/response type.

local fragments = {}

-- =========================================================================
-- TITLES by archetype x era
-- =========================================================================
fragments.titles = {
    conflict = {
        generic = {
            "A Challenge Arises",
            "Blood in the Hall",
            "The Line is Drawn",
            "Tension at the Borders",
            "A Dispute Demands Resolution",
            "Swords Drawn at Dawn",
        },
        ancient = {
            "Trial by Stone and Fire",
            "The Old Grudge Awakens",
            "A Primal Challenge",
        },
        medieval = {
            "Challenge of Arms",
            "A Feudal Dispute",
            "The Banner is Raised",
        },
        renaissance = {
            "A Duel of Honor",
            "The Court Divides",
            "Political Crossfire",
        },
        arcane = {
            "The Wards Crack",
            "Power Clashes with Power",
            "A Rift in the Weave",
        },
        industrial = {
            "Strike and Lockout",
            "The Machines of War Turn",
            "Resources Under Siege",
        },
        twilight = {
            "The Last Confrontation",
            "A Dying World's Rage",
            "Embers and Ash",
        },
    },
    discovery = {
        generic = {
            "An Unexpected Find",
            "Something Stirs Below",
            "Knowledge Unearthed",
            "A Secret Revealed",
            "Whispers of the Unknown",
        },
        ancient = {
            "Bones Beneath the Earth",
            "The First Writing",
            "A Primordial Cache",
        },
        medieval = {
            "The Hidden Chamber",
            "A Monk's Hidden Work",
            "Lost Relics Found",
        },
        renaissance = {
            "The Scholar's Breakthrough",
            "A New Philosophy Emerges",
            "Forgotten Manuscripts",
        },
        arcane = {
            "The Grimoire Speaks",
            "An Artifact Awakens",
            "Arcane Residue Detected",
        },
        industrial = {
            "The Prototype Works",
            "A Scientific Discovery",
            "Innovation from Wreckage",
        },
        twilight = {
            "Echoes of What Was",
            "Salvage from the Ruins",
            "The Last Archives",
        },
    },
    betrayal = {
        generic = {
            "A Knife in the Dark",
            "Treachery Revealed",
            "The Mask Falls",
            "Trust Broken",
            "An Ally's True Face",
        },
        ancient = {
            "Blood Oath Shattered",
            "The Elder's Deception",
        },
        medieval = {
            "The Vassal's Betrayal",
            "Poison in the Cup",
        },
        renaissance = {
            "The Courtier's Plot",
            "Letters of Conspiracy",
        },
        arcane = {
            "The Familiar Turns",
            "A Pact Perverted",
        },
        industrial = {
            "Corporate Sabotage",
            "The Inside Man",
        },
        twilight = {
            "The Survivor's Calculation",
            "Desperation Breeds Treachery",
        },
    },
    crisis = {
        generic = {
            "A Crisis Unfolds",
            "Everything at Stake",
            "The Ground Shifts",
            "Catastrophe Looms",
            "The Breaking Point",
            "Ruin Approaches",
        },
        ancient = {
            "The Earth Trembles",
            "A Primal Disaster",
        },
        medieval = {
            "The Castle Burns",
            "Siege Without Warning",
        },
        renaissance = {
            "The City Panics",
            "Order Collapses",
        },
        arcane = {
            "Reality Frays",
            "The Seal Breaks",
        },
        industrial = {
            "The Infrastructure Fails",
            "Collapse of the System",
        },
        twilight = {
            "The Final Collapse",
            "Twilight Deepens",
        },
    },
    opportunity = {
        generic = {
            "A Door Opens",
            "Fortune Favors the Bold",
            "An Opening Appears",
            "The Stars Align",
            "A Rare Chance",
        },
        ancient = {
            "A Bountiful Season",
            "The Spirits Offer Gifts",
        },
        medieval = {
            "The King's Favor",
            "A Merchant's Proposal",
        },
        renaissance = {
            "A Patron's Interest",
            "The Academy Opens",
        },
        arcane = {
            "The Ley Lines Surge",
            "A Convergence of Power",
        },
        industrial = {
            "The Market Booms",
            "A Contract Worth Millions",
        },
        twilight = {
            "A Glimmer in the Darkness",
            "Resources Unclaimed",
        },
    },
    ceremony = {
        generic = {
            "A Rite of Passage",
            "The Gathering",
            "A Sacred Occasion",
            "The Bloodline Convenes",
        },
        ancient = {
            "The Bonfire Ritual",
            "First Blood Ceremony",
        },
        medieval = {
            "The Crowning",
            "A Feast of Lords",
        },
        renaissance = {
            "The Grand Ball",
            "A Public Dedication",
        },
        arcane = {
            "The Binding Ritual",
            "Circle of Invocation",
        },
        industrial = {
            "The Inaugural Address",
            "Foundation Ceremony",
        },
        twilight = {
            "The Last Rite",
            "Memorial of the Fallen",
        },
    },
}

-- =========================================================================
-- NARRATIVES by archetype x active condition
-- =========================================================================
fragments.narratives = {
    conflict = {
        generic = {
            "Tensions have been building for seasons. Now {heir_name} must face the consequences.",
            "A rival force challenges the {lineage_name} claim. The response will shape generations.",
            "The calm shatters. Forces beyond {heir_name}'s control demand a reckoning.",
            "Word arrives of a challenge that cannot be ignored. The {lineage_name} must respond.",
        },
        plague = {
            "In the shadow of plague, rivals see weakness. Someone moves against the {lineage_name}.",
            "Disease has thinned the ranks. Now comes the vultures. {heir_name} must fight on two fronts.",
        },
        war = {
            "Battle rages across the land. Within the chaos, a new threat emerges for {heir_name}.",
            "War breeds opportunists. A rival force exploits the fighting to challenge the {lineage_name}.",
        },
        famine = {
            "Hunger sharpens every grudge. A dispute over scarce resources turns violent.",
            "Starving neighbors turn predatory. The {lineage_name} holdings are targeted.",
        },
    },
    discovery = {
        generic = {
            "Something long buried has come to light. {heir_name} must decide what to do with it.",
            "Scouts report an unusual find. The {lineage_name} could benefit — or be cursed.",
            "A chance discovery opens new possibilities for the bloodline.",
        },
        plague = {
            "While searching for a cure, {heir_name}'s people uncover something unexpected.",
            "The plague drives diggers into old ground. What they find changes everything.",
        },
        war = {
            "The battlefield yields more than blood — a discovery among the ruins.",
            "Soldiers stumble upon something valuable in the aftermath of fighting.",
        },
        famine = {
            "Desperate foragers dig deeper than ever before and find something strange.",
            "The search for food leads to an ancient cache hidden beneath the earth.",
        },
    },
    betrayal = {
        generic = {
            "Someone close to {heir_name} has been working against the {lineage_name}. The truth emerges.",
            "Trust is shattered. A confidant's treachery comes to light.",
            "An ally's loyalty was a mask. {heir_name} learns the truth too late — or just in time.",
        },
        plague = {
            "Plague breeds paranoia, and paranoia breeds truth. A traitor is revealed.",
        },
        war = {
            "In the fog of war, allegiances shift. Someone has sold out the {lineage_name}.",
        },
        famine = {
            "Someone has been hoarding while others starve. The betrayal cuts deep.",
        },
    },
    crisis = {
        generic = {
            "Disaster strikes without warning. {heir_name} must act immediately or watch everything crumble.",
            "A chain of failures cascades through {lineage_name} holdings. The response must be swift.",
            "The situation deteriorates rapidly. There may be no good options.",
        },
        plague = {
            "The plague worsens beyond anyone's prediction. {heir_name} faces impossible choices.",
        },
        war = {
            "The enemy breaks through. {heir_name}'s position is compromised. Retreat or stand?",
        },
        famine = {
            "The stores are empty. The people are desperate. {heir_name} must decide who eats and who doesn't.",
        },
    },
    opportunity = {
        generic = {
            "A rare opening presents itself. {heir_name} must decide whether to seize it.",
            "Fortune smiles on the {lineage_name} — but every gift has its price.",
            "An unexpected opportunity could reshape the bloodline's future.",
        },
        plague = {
            "Others flee the plague. Their abandoned holdings tempt the {lineage_name}.",
        },
        war = {
            "The enemy's flank is exposed. A bold move now could change everything.",
        },
        famine = {
            "A hidden granary is found. Others will want it too.",
        },
    },
    ceremony = {
        generic = {
            "The {lineage_name} gather for a rite that will define the next era of the bloodline.",
            "Tradition calls. {heir_name} must lead the ceremony — but how?",
            "A sacred occasion brings the family together. What happens next will be remembered.",
        },
        plague = {
            "Even plague cannot stop the old rites. The ceremony proceeds under a pall.",
        },
        war = {
            "In the midst of war, the family insists on the ancient ceremony.",
        },
        famine = {
            "The rite must go on, even with empty bellies. The ancestors demand it.",
        },
    },
}

-- =========================================================================
-- OPTION LABELS by response type
-- =========================================================================
fragments.option_labels = {
    aggressive = {
        "Strike First",
        "Attack Without Mercy",
        "Show No Quarter",
        "Crush the Opposition",
        "Take It By Force",
    },
    cautious = {
        "Proceed Carefully",
        "Wait and Watch",
        "Gather More Information",
        "Take the Safe Path",
        "Avoid Unnecessary Risk",
    },
    clever = {
        "Outmaneuver Them",
        "Turn It to Advantage",
        "A Cunning Solution",
        "Use Their Own Strength Against Them",
        "Think Three Steps Ahead",
    },
    merciful = {
        "Show Mercy",
        "Extend an Olive Branch",
        "Forgive, but Remember",
        "Spare Them",
        "Choose Compassion",
    },
    cruel = {
        "Make an Example",
        "Let Them Suffer",
        "Break Them Utterly",
        "No Mercy, No Memory",
        "The Cruelest Option",
    },
    pragmatic = {
        "Do What Must Be Done",
        "The Practical Choice",
        "Sacrifice for Stability",
        "Accept the Cost",
        "The Lesser Evil",
    },
}

-- =========================================================================
-- OPTION DESCRIPTIONS by response type
-- =========================================================================
fragments.option_descriptions = {
    aggressive = {
        "Meet force with greater force. The bloodline's strength will be known.",
        "An aggressive response sends a clear message: the {lineage_name} are not to be tested.",
        "Violence is the oldest language. {heir_name} speaks it fluently.",
    },
    cautious = {
        "Patience preserves what boldness might destroy. Wait for the right moment.",
        "Hasty action leads to generational regret. Better to be careful.",
        "Observe. Analyze. Then — and only then — act.",
    },
    clever = {
        "Brute force is for those without alternatives. There is a smarter path.",
        "Turn the situation inside out. What looks like a threat becomes a tool.",
        "The cleverest move is the one no one sees coming.",
    },
    merciful = {
        "Mercy is not weakness — it is an investment in future loyalty.",
        "Kindness now may yield unexpected returns generations hence.",
        "Let mercy define the {lineage_name}, not cruelty.",
    },
    cruel = {
        "Fear is the fastest teacher. Make the lesson unforgettable.",
        "They will not dare test the {lineage_name} again. See to it.",
        "Suffering is a tool. Apply it precisely and without remorse.",
    },
    pragmatic = {
        "Ideals are a luxury. Right now, survival is what matters.",
        "The practical choice may not be glorious, but the {lineage_name} endure.",
        "Weigh the costs. Accept what cannot be avoided. Move on.",
    },
}

-- =========================================================================
-- CONSEQUENCE NARRATIVES by response type x outcome
-- =========================================================================
fragments.consequence_narratives = {
    aggressive = {
        success = {
            "The display of force works. The {lineage_name} reputation for strength grows.",
            "Decisive action carries the day. Others take note.",
        },
        mixed = {
            "Victory, but at a cost. The {lineage_name} are stronger — and bloodier.",
            "The aggressive approach succeeds, but new enemies are made.",
        },
        failure = {
            "Aggression overreaches. The {lineage_name} pay for it in blood and standing.",
            "The strike fails. The {lineage_name} look foolish and dangerous — a bad combination.",
        },
    },
    cautious = {
        success = {
            "Patience proves wise. The threat dissolves without needless bloodshed.",
            "Careful observation reveals the path. The {lineage_name} navigate safely.",
        },
        mixed = {
            "The cautious approach preserves stability, but opportunity slips away.",
            "No harm done — but no advantage gained either.",
        },
        failure = {
            "Hesitation is mistaken for weakness. Others grow bold against the {lineage_name}.",
            "The window closes while the {lineage_name} deliberate.",
        },
    },
    clever = {
        success = {
            "The gambit pays off beautifully. The {lineage_name} are whispered about with respect.",
            "Cunning wins the day. Resources are gained with minimal loss.",
        },
        mixed = {
            "The plan partially works. Some gains, some complications.",
            "Clever enough to avoid disaster, but not to claim full victory.",
        },
        failure = {
            "Too clever by half. The scheme unravels and trust is damaged.",
            "The manipulation is detected. The {lineage_name} name is tarnished.",
        },
    },
    merciful = {
        success = {
            "Mercy earns unexpected loyalty. A former enemy becomes a tentative friend.",
            "Compassion resonates. The {lineage_name} reputation shifts toward wisdom.",
        },
        mixed = {
            "Some appreciate the mercy; others see it as weakness. The outcome is uncertain.",
            "Mercy given, consequences uncertain. Time will tell if it was wise.",
        },
        failure = {
            "Mercy is exploited. Those spared return stronger and angrier.",
            "Compassion without strength is suicide. The {lineage_name} learn this the hard way.",
        },
    },
    cruel = {
        success = {
            "Fear spreads like fire. None will challenge the {lineage_name} soon.",
            "The message is received. Compliance follows where defiance once stood.",
        },
        mixed = {
            "The cruelty achieves its immediate goal, but whispers of tyranny grow louder.",
            "Effective, but the {lineage_name} now sleep with one eye open.",
        },
        failure = {
            "Cruelty breeds united opposition. The {lineage_name} face more enemies than before.",
            "The brutality backfires spectacularly. A coalition forms against the bloodline.",
        },
    },
    pragmatic = {
        success = {
            "The practical choice proves correct. The {lineage_name} endure and stabilize.",
            "No glory, but no disaster either. The bloodline continues.",
        },
        mixed = {
            "Pragmatism preserves the status quo. Neither gain nor loss.",
            "The cost is paid. The {lineage_name} survive — diminished, but intact.",
        },
        failure = {
            "Even pragmatism has limits. The compromise satisfies no one.",
            "The middle ground collapses. The {lineage_name} please nobody.",
        },
    },
}

-- =========================================================================
-- ERA ADJECTIVES (for flavor text injection)
-- =========================================================================
fragments.era_adjectives = {
    ancient = { "primordial", "ancient", "bone-carved", "spirit-touched" },
    medieval = { "iron-forged", "feudal", "battle-scarred", "stone-walled" },
    renaissance = { "gilded", "enlightened", "ink-stained", "court-polished" },
    arcane = { "arcane", "ether-touched", "rune-marked", "shadow-wreathed" },
    industrial = { "steam-driven", "coal-blackened", "modern", "mechanized" },
    twilight = { "twilight", "ash-covered", "fading", "desperate" },
}

-- =========================================================================
-- REPUTATION FLAVORS
-- =========================================================================
fragments.reputation_flavors = {
    warriors = {
        "The {lineage_name}'s reputation for violence precedes them.",
        "Others eye the {lineage_name} with the wary respect given to predators.",
    },
    scholars = {
        "The {lineage_name}'s knowledge is both sought and feared.",
        "Wisdom follows the {lineage_name} name like a shadow.",
    },
    diplomats = {
        "The {lineage_name}'s word carries weight in every hall.",
        "Where others draw swords, the {lineage_name} draw treaties.",
    },
    artisans = {
        "The {lineage_name}'s craftsmanship is legendary.",
        "Beauty and ingenuity mark the {lineage_name} holdings.",
    },
    tyrants = {
        "The {lineage_name} name is spoken in whispers of fear.",
        "None defy the {lineage_name} openly. None dare.",
    },
    unknown = {
        "The {lineage_name} are still making their name.",
    },
}

-- =========================================================================
-- CONDITION MODIFIERS (appended to narratives when conditions are active)
-- =========================================================================
fragments.condition_modifiers = {
    plague = {
        "The stench of plague hangs over everything.",
        "Death carts rattle through the streets as this unfolds.",
        "Half the witnesses are sick. The other half are afraid.",
    },
    war = {
        "The distant sounds of battle underscore every word.",
        "Smoke from the frontlines drifts over the scene.",
        "Soldiers in bloodstained armor stand watch as events proceed.",
    },
    famine = {
        "Hollow-eyed faces watch from every doorway.",
        "The sound of hungry children haunts the proceedings.",
        "Even the powerful look gaunt. There is not enough.",
    },
}

return fragments
