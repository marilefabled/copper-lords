-- Bloodweight — Narrative Tables
-- Personality-tinted openings and reputation-tinted closings.
-- Era-aware variants for late-game freshness.
-- Pure data, no logic.

local narrative_tables = {}

-- ============================
-- GENERATION OPENINGS
-- Keyed by "AXIS_direction" (e.g., PER_CRM_high for cruel heir)
-- ============================
narrative_tables.openings = {
    -- Cruelty (high = cruel)
    PER_CRM_high = {
        "{heir_name} ruled with an iron hand and a cold heart.",
        "The name of {heir_name} was spoken only in whispers.",
        "Mercy was a word {heir_name} did not know.",
        "Under {heir_name}, the shadow of the bloodline lengthened.",
    },
    PER_CRM_low = {
        "{heir_name} carried the weight with surprisingly gentle hands.",
        "{heir_name} believed that kindness was the only strength that mattered.",
        "Under {heir_name}'s care, even the lowliest were given bread.",
        "The blood of {heir_name} ran with a mercy the ancestors never knew.",
    },

    -- Boldness (high = reckless/bold)
    PER_BLD_high = {
        "{heir_name} feared nothing, not even the ending of the world.",
        "{heir_name} met every dawn as a challenge to be conquered.",
        "Caution was a stranger to {heir_name}.",
        "The pulse of {heir_name} beat with the rhythm of conquest.",
    },
    PER_BLD_low = {
        "{heir_name} watched from the silence, calculating every risk.",
        "Every step {heir_name} took was measured twice against the silence.",
        "Patience was {heir_name}'s greatest weapon.",
        "{heir_name} knew that some victories are won by standing still.",
    },

    -- Volatility (high = explosive)
    PER_VOL_high = {
        "{heir_name} was a storm made flesh, unpredictable and fierce.",
        "No one could predict what {heir_name} would do next. Not even themselves.",
        "{heir_name} burned bright and terrible through the years.",
        "The mood of {heir_name} shifted like the winds of {world_name}.",
    },
    PER_VOL_low = {
        "{heir_name} was as still as the deep waters of {world_name}.",
        "Nothing moved {heir_name}. Not joy, not grief, not fear.",
        "{heir_name}'s composure was a fortress that no crisis could breach.",
        "Silence was the primary language of {heir_name}.",
    },

    -- Obsession
    PER_OBS_high = {
        "{heir_name} could not let go. Would not let go.",
        "{heir_name} pursued one truth to the exclusion of all others.",
        "Obsession drove {heir_name}. It was fuel and fire both.",
        "The focus of {heir_name} was a narrow beam that burned what it touched.",
    },
    PER_OBS_low = {
        "{heir_name} drifted between interests like a leaf on the surface of {world_name}.",
        "Nothing held {heir_name}'s attention for long.",
        "The mind of {heir_name} was a garden of a thousand unfinished paths.",
    },

    -- Pride
    PER_PRI_high = {
        "{heir_name} knew their worth—and made sure the world knew it too.",
        "The name was everything. {heir_name} would sooner die than see it diminished.",
        "{heir_name} wore pride like a suit of burnished armor.",
        "Every word from {heir_name} was a command, even when it was a question.",
    },
    PER_PRI_low = {
        "{heir_name} led from the shadows, asking for no recognition.",
        "Humility marked {heir_name}'s reign—a rare thing in the history of {world_name}.",
        "{heir_name} saw themselves only as a vessel for the blood, nothing more.",
    },

    -- Curiosity
    PER_CUR_high = {
        "{heir_name} asked questions that had no answers, and searched for them anyway.",
        "The unknown called to {heir_name} like a siren song from the edge of the world.",
        "{heir_name} would not rest until every secret was laid bare.",
        "Knowledge was the only currency {heir_name} valued.",
    },
    PER_CUR_low = {
        "{heir_name} was content with what was already known.",
        "Tradition was {heir_name}'s compass; innovation was treated as heresy.",
        "The old ways were sufficient for {heir_name}.",
    },

    -- Loyalty
    PER_LOY_high = {
        "Blood was everything to {heir_name}.",
        "{heir_name} would have burned the world to save a single sibling.",
        "Loyalty was not a virtue for {heir_name}. It was the only law.",
        "The bonds of {heir_name} were forged in iron and sealed in blood.",
    },
    PER_LOY_low = {
        "{heir_name} served only one master: their own ambition.",
        "Loyalty was a chain {heir_name} refused to wear.",
        "{heir_name} walked alone, even in a crowded court.",
    },

    -- Adaptability
    PER_ADA_high = {
        "{heir_name} bent with every wind and never once broke.",
        "Change was not feared by {heir_name}. It was embraced.",
        "{heir_name} was a mirror, reflecting whatever the world required.",
    },
    PER_ADA_low = {
        "The old ways were the only ways for {heir_name}.",
        "{heir_name} stood rigid against the tide of a changing world.",
        "To {heir_name}, to change was to betray the ancestors.",
    },

    -- Generic fallback
    generic = {
        "{heir_name} took up the mantle of the bloodline.",
        "The legacy continued through the hands of {heir_name}.",
        "{heir_name} now carried the weight of all who came before.",
        "A new chapter was written in the blood of {heir_name}.",
    },
}

-- ============================
-- ERA-SPECIFIC OPENINGS
-- Keyed by "AXIS_direction_era" — used when available, falls back to base
-- ============================
narrative_tables.era_openings = {
    -- === ANCIENT ===
    PER_CRM_high_ancient = {
        "{heir_name} ruled when the world was young and cruelty had no name for itself.",
        "In the first age, {heir_name}'s violence was called strength. No one corrected this.",
        "Before laws were written, {heir_name} dispensed justice with bare hands.",
    },
    PER_CRM_low_ancient = {
        "{heir_name} was gentle in an age that did not yet know the word.",
        "When the world was all tooth and claw, {heir_name} chose the open hand.",
        "Mercy, in the ancient days, was indistinguishable from weakness. {heir_name} proved otherwise.",
    },
    PER_BLD_high_ancient = {
        "{heir_name} strode into the primordial dark, daring it to bite.",
        "In an age without maps, {heir_name} walked toward the horizon and kept walking.",
        "The first fires were lit by hands like {heir_name}'s — reckless, reaching, unburned.",
    },
    PER_BLD_low_ancient = {
        "{heir_name} survived the first age by watching the bold ones die.",
        "While others charged into the unknown, {heir_name} counted the ones who returned.",
        "In the dawn of things, patience was the rarest form of courage. {heir_name} had reserves.",
    },
    PER_VOL_high_ancient = {
        "{heir_name} raged like the young world itself — volcanic, ungoverned, magnificent.",
        "The first storms had nothing on {heir_name}.",
        "In the ancient age, the line between fury and worship was thin. {heir_name} walked it badly.",
    },
    PER_VOL_low_ancient = {
        "{heir_name} was stone while the world around them still burned from its making.",
        "The ancient world was chaos. {heir_name} was not.",
    },
    PER_OBS_high_ancient = {
        "{heir_name} fixated on the old mysteries with the fervor of one who invented devotion.",
        "Before there were temples, {heir_name} had already built a shrine to one idea.",
    },
    PER_CUR_high_ancient = {
        "{heir_name} asked the first questions. The world, being new, had no answers prepared.",
        "Everything was unknown in the ancient age. {heir_name} found this intoxicating.",
    },
    PER_LOY_high_ancient = {
        "{heir_name} bound the first oaths when an oath was still a physical thing — blood on stone.",
        "In the beginning, loyalty was the only currency. {heir_name} was the richest heir alive.",
    },
    PER_PRI_high_ancient = {
        "{heir_name} demanded worship before there were gods to compete with.",
        "In the ancient age, pride and survival were the same impulse. {heir_name} had both in excess.",
    },
    PER_ADA_high_ancient = {
        "{heir_name} changed with the seasons when the seasons themselves were still being invented.",
        "The ancient world shifted daily. {heir_name} shifted faster.",
    },

    -- === IRON ===
    PER_CRM_high_iron = {
        "{heir_name} sharpened cruelty into policy. The Iron Age approved.",
        "Steel in the hand, nothing in the heart. {heir_name} was the age distilled.",
        "In an age of iron, {heir_name} was the coldest metal in the forge.",
    },
    PER_CRM_low_iron = {
        "Mercy in the Iron Age was an act of defiance. {heir_name} committed it daily.",
        "{heir_name} offered bread in an age that respected only blades.",
        "The iron age crushed the gentle. {heir_name} was gentle and somehow endured.",
    },
    PER_BLD_high_iron = {
        "{heir_name} charged into the age of steel as though born for it.",
        "Iron called to {heir_name} the way it calls to all who love the sound of impact.",
        "Every conflict was an invitation. {heir_name} never declined.",
    },
    PER_BLD_low_iron = {
        "{heir_name} navigated the Iron Age by the simple strategy of not dying first.",
        "While armies clashed, {heir_name} counted the cost and chose another way.",
    },
    PER_VOL_high_iron = {
        "{heir_name} was fire in an age of iron — warping everything they touched.",
        "The forges of the age were not hotter than {heir_name}'s temperament.",
    },
    PER_VOL_low_iron = {
        "{heir_name} was the cold water in which the hot iron of the age was quenched.",
        "Composure in the Iron Age was more dangerous than rage. {heir_name} knew this.",
    },
    PER_OBS_high_iron = {
        "{heir_name} hammered at one idea with the relentlessness of a smith at the anvil.",
        "The Iron Age rewarded obsession. {heir_name} was richly rewarded.",
    },
    PER_LOY_high_iron = {
        "{heir_name} swore oaths in an age that still believed oaths were binding. They were not wrong.",
        "In the age of iron, {heir_name}'s loyalty was the one alloy that did not rust.",
    },
    PER_PRI_high_iron = {
        "{heir_name} wore pride like armor in an age that respected nothing else.",
        "The Iron Age made kings of the proud and corpses of the humble. {heir_name} chose accordingly.",
    },
    PER_CUR_high_iron = {
        "{heir_name} questioned the swordsmiths and found the answers more dangerous than the blades.",
        "Curiosity in the Iron Age was measured in scars. {heir_name} had plenty.",
    },
    PER_ADA_high_iron = {
        "{heir_name} learned the language of iron quickly. Survival often resembles fluency.",
        "The age demanded adaptation. {heir_name} obliged, shedding old skin like armor outgrown.",
    },

    -- === DARK ===
    PER_CRM_high_dark = {
        "In the rot of the dark age, {heir_name}'s cruelty was barely distinguishable from the landscape.",
        "{heir_name} thrived where everything else was dying. This says something about {heir_name}.",
        "Cruelty was currency in the dark years. {heir_name} was wealthy.",
    },
    PER_CRM_low_dark = {
        "{heir_name} was kind in an age that punished kindness with extinction.",
        "The dark age devoured the merciful. {heir_name} was merciful and somehow unswallowed.",
        "Gentleness in the age of rot was not weakness. It was an act of war against despair.",
    },
    PER_BLD_high_dark = {
        "{heir_name} ran toward the collapse while everyone else ran from it.",
        "Boldness in the dark age was indistinguishable from a death wish. {heir_name} had both.",
    },
    PER_BLD_low_dark = {
        "{heir_name} husbanded every advantage the dark age had not yet stolen.",
        "Caution was the only luxury the dark age permitted. {heir_name} spent it wisely.",
    },
    PER_VOL_high_dark = {
        "In an age of despair, {heir_name}'s rage was the only warmth.",
        "{heir_name} was volatile in a time that had nothing left to break. They found things anyway.",
    },
    PER_VOL_low_dark = {
        "{heir_name} endured the dark age the way stone endures weather. Silently. Indefinitely.",
        "Nothing in the dark years could provoke {heir_name}. The world had already done its worst.",
    },
    PER_OBS_high_dark = {
        "While the world rotted, {heir_name} clung to a single purpose as though it were driftwood.",
        "{heir_name} was obsessed, which in the dark age meant: still alive.",
    },
    PER_LOY_high_dark = {
        "{heir_name} held the bloodline together when the dark age tried to dissolve it.",
        "Loyalty in the age of rot was an act of defiance against entropy. {heir_name} defied.",
    },
    PER_PRI_high_dark = {
        "{heir_name} maintained pride when there was nothing left to be proud of. This was either brave or insane.",
        "The dark age stripped everyone of dignity. {heir_name} refused to be stripped.",
    },
    PER_CUR_high_dark = {
        "{heir_name} asked questions in the dark age, when the answers were all corpses.",
        "Curiosity persisted in {heir_name} like a weed through rubble.",
    },
    PER_ADA_high_dark = {
        "{heir_name} adapted to the rot the way a body adapts to poison — partially, painfully, enough.",
        "The dark age demanded reinvention. {heir_name} reinvented.",
    },

    -- === ARCANE ===
    PER_CRM_high_arcane = {
        "{heir_name} wielded power without comprehension and cruelty without hesitation. The age was well-suited.",
        "Sorcery gave {heir_name}'s cruelty a longer reach. The world noticed.",
    },
    PER_CRM_low_arcane = {
        "{heir_name} was gentle in an age of terrible power. This made them either wise or doomed.",
        "Mercy in the arcane age meant refusing to use what you had been given. {heir_name} refused daily.",
    },
    PER_BLD_high_arcane = {
        "{heir_name} charged into mysteries that devoured the cautious and the bold alike.",
        "The arcane age rewarded boldness with power or annihilation. {heir_name} got both.",
    },
    PER_BLD_low_arcane = {
        "{heir_name} watched the arcane fires from a safe distance. This was the only intelligent response.",
        "Caution in the age of unbound power was not cowardice. It was the only form of genius.",
    },
    PER_VOL_high_arcane = {
        "{heir_name}'s emotions and the arcane resonated at the same destructive frequency.",
        "Power amplified everything. {heir_name} was already amplified.",
    },
    PER_VOL_low_arcane = {
        "{heir_name} was the still point in an age of wild energies.",
        "The arcane raged. {heir_name} did not. This was their only advantage.",
    },
    PER_OBS_high_arcane = {
        "{heir_name} pursued arcane secrets with a hunger that frightened the secrets themselves.",
        "Obsession in the arcane age was either the path to godhood or the path to something worse.",
    },
    PER_CUR_high_arcane = {
        "{heir_name} asked questions of forces that were not designed to answer.",
        "The arcane age was built for the curious. It also killed the curious. {heir_name} was both.",
    },
    PER_LOY_high_arcane = {
        "{heir_name} swore blood oaths in an age when blood had learned to listen.",
        "Loyalty took on strange dimensions when the dead could hear your promises.",
    },
    PER_PRI_high_arcane = {
        "{heir_name} demanded recognition from powers that did not know what a name was.",
        "Pride in the arcane age was the insistence that a mortal mattered. {heir_name} insisted loudly.",
    },
    PER_ADA_high_arcane = {
        "{heir_name} absorbed the arcane changes like a sponge absorbs poison — thoroughly and not without cost.",
        "Adaptation in the thinning age meant becoming something new every morning.",
    },

    -- === GILDED ===
    PER_CRM_high_gilded = {
        "{heir_name} was cruel in an age that had learned to gild cruelty in rhetoric.",
        "The gilded age hid its knives in silk. {heir_name} preferred silk.",
        "In an age of plenty, {heir_name}'s cruelty was refined, deliberate, and exquisitely funded.",
    },
    PER_CRM_low_gilded = {
        "{heir_name} was kind in an age where kindness was mistaken for naivety.",
        "The gilded age rewarded the ruthless. {heir_name} was gentle and paid the tax for it.",
        "Mercy in the age of gold was cheap to give and expensive to maintain. {heir_name} maintained it.",
    },
    PER_BLD_high_gilded = {
        "{heir_name} was bold in an age that had forgotten what boldness cost.",
        "The gilded age made conquest look easy. {heir_name} believed it.",
    },
    PER_BLD_low_gilded = {
        "{heir_name} saw through the gilt to the rot beneath, and measured every step accordingly.",
        "Caution in the gilded age looked like pessimism. It was not.",
    },
    PER_VOL_high_gilded = {
        "{heir_name} was volatile in an age of calm surfaces and deep currents.",
        "The gilded age polished everything. {heir_name} refused to be polished.",
    },
    PER_VOL_low_gilded = {
        "{heir_name}'s composure was indistinguishable from the gilded age itself. Smooth, expensive, and hiding everything.",
        "In the age of the gilt lie, {heir_name}'s stillness was the most honest thing in the room.",
    },
    PER_OBS_high_gilded = {
        "{heir_name} was obsessed in an age that preferred moderation. This was, naturally, unforgivable.",
        "The gilded age wanted balance. {heir_name} wanted one thing. The age lost.",
    },
    PER_LOY_high_gilded = {
        "{heir_name} was loyal in an age that had turned loyalty into a transaction.",
        "The gilded age priced everything. {heir_name}'s loyalty was the one thing it could not buy.",
    },
    PER_PRI_high_gilded = {
        "{heir_name} wore pride in an age where everyone wore it, and somehow wore it louder.",
        "Pride in the gilded age was ubiquitous. {heir_name}'s was merely the most expensive.",
    },
    PER_CUR_high_gilded = {
        "{heir_name} was curious in an age that believed it already knew everything worth knowing.",
        "The gilded age had catalogued the world. {heir_name} found the gaps in the catalogue.",
    },
    PER_ADA_high_gilded = {
        "{heir_name} adapted to prosperity the way others adapted to catastrophe — completely, and with suspicion.",
        "The gilded age changed people slowly. {heir_name} changed faster than it intended.",
    },

    -- === TWILIGHT ===
    PER_CRM_high_twilight = {
        "{heir_name} was cruel at the end of all things, which takes a particular kind of commitment.",
        "In the twilight, {heir_name}'s cruelty served no purpose. This did not stop them.",
        "The world was ending. {heir_name} was cruel to it anyway, out of habit or conviction.",
    },
    PER_CRM_low_twilight = {
        "{heir_name} was kind in the twilight, when kindness cost everything and bought nothing.",
        "Mercy at the end of the world was either the most noble or the most pointless act. {heir_name} did not distinguish.",
        "The twilight stripped everything to its essentials. {heir_name}'s essential was gentleness.",
    },
    PER_BLD_high_twilight = {
        "{heir_name} charged into the twilight as though there were still something to win.",
        "Boldness in the final age was indistinguishable from denial. {heir_name} denied magnificently.",
    },
    PER_BLD_low_twilight = {
        "{heir_name} was cautious in the twilight, which was like being cautious in a house already on fire.",
        "The final age offered nothing to the careful. {heir_name} was careful anyway.",
    },
    PER_VOL_high_twilight = {
        "{heir_name} raged against the dying light. The light died anyway.",
        "In the twilight, {heir_name}'s fury was the last warm thing in the world.",
    },
    PER_VOL_low_twilight = {
        "{heir_name} faced the end with the composure of someone who had expected it all along.",
        "The world dimmed. {heir_name} did not flinch. There was nothing left worth flinching for.",
    },
    PER_OBS_high_twilight = {
        "{heir_name} clung to one idea while the world released its grip on everything.",
        "Obsession in the twilight was the last form of faith.",
    },
    PER_LOY_high_twilight = {
        "{heir_name} held the bloodline together in the final age, when everything else was letting go.",
        "Loyalty in the twilight was the most expensive virtue. {heir_name} could not afford it and paid anyway.",
    },
    PER_PRI_high_twilight = {
        "{heir_name} maintained their pride as the world forgot why pride had ever mattered.",
        "The twilight humbled everything. {heir_name} was the last thing standing unhumbled.",
    },
    PER_CUR_high_twilight = {
        "{heir_name} asked questions at the end of the world. The answers, by then, were irrelevant.",
        "Curiosity in the final age was either defiance or madness. {heir_name} did not clarify.",
    },
    PER_ADA_high_twilight = {
        "{heir_name} adapted to the twilight. This was the saddest adaptation of all.",
        "The final age demanded surrender. {heir_name} adapted, which was the same thing said differently.",
    },
}

-- ============================
-- GENERATION CLOSINGS
-- Keyed by reputation archetype
-- ============================
narrative_tables.closings = {
    warriors = {
        "The blood endures. The sword remembers.",
        "Another generation forged in the heat of conflict.",
        "Strength was the only legacy they left behind.",
        "The blade was passed down, still sharp and hungry.",
    },
    scholars = {
        "Knowledge compounds. The weight of understanding deepened.",
        "What was learned in those years cannot be unlearned.",
        "The archives grew thick with the observations of {heir_name}.",
        "Wisdom, once gained, became a burden for the next to bear.",
    },
    diplomats = {
        "Alliances shifted, but the bloodline remained at the center.",
        "Words outlasted swords. The web of influence grew.",
        "Every friend was a shield, every secret a dagger in the dark.",
        "The game of houses continued, with new players and old grudges.",
    },
    artisans = {
        "Beauty persisted where empires were starting to crumble.",
        "What was made in those years would outlast the memory of {heir_name}.",
        "Creation was their only form of immortality.",
        "The great works endured. The maker returned to the dust.",
    },

    -- Generic fallback
    generic = {
        "And so the weight of the ancestors grew heavier.",
        "The bloodline endured, as it always must.",
        "Another generation passed into the silence of memory.",
        "The story of {heir_name} was done, but the blood remained.",
    },
}

-- ============================
-- ERA-SPECIFIC CLOSINGS
-- Keyed by "reputation_era" — used when available, falls back to base
-- ============================
narrative_tables.era_closings = {
    -- === ANCIENT ===
    warriors_ancient = {
        "The first blood was spilled. It would not be the last.",
        "In the dawn of things, the blade was the only truth. The bloodline spoke it fluently.",
        "They fought because the world was new and had not yet learned to negotiate.",
    },
    scholars_ancient = {
        "Knowledge, in the ancient days, was carved in stone. It endured because nothing else did.",
        "The first secrets were recorded. The ancestors would spend generations wishing they hadn't been.",
    },
    diplomats_ancient = {
        "The first alliances were sealed with blood, not ink. They held better for it.",
        "In the ancient age, a handshake was a contract. {heir_name}'s grip was remembered.",
    },
    artisans_ancient = {
        "The first works were rough. They outlasted everything that came after.",
        "What was built in the dawn of things was built to last, because nothing else would.",
    },
    generic_ancient = {
        "And so the bloodline's first chapter was written in mud and firelight.",
        "The ancient days passed. The weight, barely perceptible, had begun to accumulate.",
        "The beginning was over. The weight of it had only just started.",
    },

    -- === IRON ===
    warriors_iron = {
        "Steel remembers every blow. So does the bloodline.",
        "The Iron Age took its tithe. The bloodline paid in the only currency the age accepted.",
        "Another generation tested against the anvil. The metal held. Barely.",
    },
    scholars_iron = {
        "Knowledge grew between battles, in the pauses the Iron Age grudgingly permitted.",
        "The iron years were not kind to scholars. {heir_name}'s learning survived anyway, like a weed through plate armor.",
    },
    diplomats_iron = {
        "Words are quieter than swords. In the Iron Age, quieter things survived longer.",
        "The web of alliances tightened. In an age of iron, a web was worth more than a wall.",
    },
    artisans_iron = {
        "What was forged in the Iron Age carried the weight of the age itself — heavy, functional, unlovely.",
        "Beauty in the age of iron was an act of resistance. {heir_name} resisted.",
    },
    generic_iron = {
        "The Iron Age ground on. The bloodline ground on with it.",
        "Another generation paid the red tithe. The ledger does not close.",
        "Steel and blood. The iron years took their toll and offered nothing in return.",
    },

    -- === DARK ===
    warriors_dark = {
        "Victory in the dark age was indistinguishable from survival. The bloodline claimed both.",
        "They fought in the rot, and the rot fought back.",
        "War in the dark years was not a contest. It was a chore. The bloodline performed it.",
    },
    scholars_dark = {
        "Knowledge persisted in the dark age like embers in ash. {heir_name} blew on them.",
        "The scholars of the dark years wrote by firelight in rooms that smelled of mildew and fear.",
    },
    diplomats_dark = {
        "Alliances in the dark age were desperate things, built from need rather than trust.",
        "The web of influence frayed in the rot. {heir_name} retied what they could.",
    },
    artisans_dark = {
        "Art made in the dark age carried the stench of the era. It was, somehow, more honest for it.",
        "Creation persisted even in the rot. Especially in the rot.",
    },
    generic_dark = {
        "The dark years consumed another generation. The bloodline was thinner for it.",
        "Survival, in the dark age, was the only achievement worth recording. It was enough.",
        "The rot claimed another year. The bloodline held. The word 'held' is doing considerable work in that sentence.",
    },

    -- === ARCANE ===
    warriors_arcane = {
        "Strength in the arcane age was a quaint concept. {heir_name}'s strength, however, was not quaint.",
        "The arcane fires respected force. {heir_name} provided it.",
    },
    scholars_arcane = {
        "Knowledge, in the arcane age, was power. Literally. This made scholars dangerous and librarians terrifying.",
        "The arcane rewarded understanding and punished ignorance. {heir_name} understood enough to survive.",
    },
    diplomats_arcane = {
        "Diplomacy in the arcane age meant negotiating with forces that did not understand the concept of compromise.",
        "The web of influence now included things that were not entirely human. {heir_name} adjusted.",
    },
    artisans_arcane = {
        "Art in the arcane age was indistinguishable from sorcery. {heir_name}'s work blurred the line.",
        "What was created in the thinning carried an energy the creator did not fully understand.",
    },
    generic_arcane = {
        "The arcane age thinned the margins between what was possible and what was survivable.",
        "Power flowed. The bloodline drank. Whether it was nourishing or poisonous remained to be seen.",
        "The thinning continued. The bloodline persisted in the narrowing gap between wonder and catastrophe.",
    },

    -- === GILDED ===
    warriors_gilded = {
        "Strength in the gilded age was out of fashion. {heir_name} was unfashionable.",
        "The gilded age preferred its violence at a distance. {heir_name} preferred it close.",
    },
    scholars_gilded = {
        "The gilded age produced more scholars than it could employ. {heir_name}'s knowledge, at least, was useful.",
        "Learning, in the age of gold, was a luxury item. {heir_name} could afford it.",
    },
    diplomats_gilded = {
        "The gilded age was built for diplomats. Every surface was negotiable.",
        "In an age of wealth, influence was the only thing money could not directly buy. {heir_name} acquired it anyway.",
    },
    artisans_gilded = {
        "Art in the gilded age was abundant, expensive, and largely forgettable. {heir_name}'s was the exception.",
        "The gilded age gilded everything, including mediocrity. {heir_name}'s work needed no gilding.",
    },
    generic_gilded = {
        "The gilt lie continued. The bloodline prospered, which is not the same as thriving.",
        "Gold accumulated. Meaning did not. The gilded age offered no exchange rate between the two.",
        "Another generation passed in comfort. The bloodline was not improved by comfort.",
    },

    -- === TWILIGHT ===
    warriors_twilight = {
        "Strength, at the end, was the only thing that still made sense.",
        "The twilight respected nothing except force. {heir_name} was, at least, respected.",
    },
    scholars_twilight = {
        "Knowledge, in the final age, was a record of everything that had been lost.",
        "The twilight scholars catalogued the decline with the precision of a coroner.",
    },
    diplomats_twilight = {
        "Alliances in the twilight were formed between ruins. They held the way ruins hold each other up.",
        "Diplomacy in the final age was the art of dividing what remained.",
    },
    artisans_twilight = {
        "Art made in the twilight carried a beauty that was, at its core, grief.",
        "The last works were the most honest. There was nothing left to pretend about.",
    },
    generic_twilight = {
        "The twilight deepened. The bloodline exhaled.",
        "Another generation passed in the dimming. The weight was almost done accumulating.",
        "The final audit continued. The bloodline's account was nearly closed.",
        "The world grew quieter. The bloodline, for once, did not fill the silence.",
    },
}

return narrative_tables
