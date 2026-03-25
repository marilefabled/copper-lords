-- Dark Legacy — Trait Summary Engine
-- Provides dynamic, level-based textual summaries for all 70 traits.
-- Each summary grounds the trait in what it DOES in the game world.
-- Pure Lua, zero Solar2D dependencies.

local TraitSummaries = {}

-- Summary pools for each trait category
-- Format: [trait_id] = { [level] = "summary" }
-- Levels: 1 (Abysmal), 2 (Weak), 3 (Decent), 4 (Strong), 5 (Legendary)

TraitSummaries.POOLS = {
    -- PHYSICAL
    PHY_STR = {
        "Too weak to swing a blade or hold a siege line.",
        "Struggles in combat and hard labor.",
        "Strong enough for what the bloodline demands.",
        "Overpowers most opponents; excels in trials of force.",
        "A force of nature — crushes challenges that break lesser heirs."
    },
    PHY_END = {
        "Collapses under any sustained effort; a liability in crisis.",
        "Tires quickly; can't endure long marches or sieges.",
        "Endures a full day's hardship without complaint.",
        "Outlasts most challengers; thrives during prolonged crises.",
        "Inexhaustible — pushes through plagues, wars, and famines alike."
    },
    PHY_REF = {
        "Reacts too slowly; ambushes and assassins find easy prey.",
        "Sluggish in combat and emergencies.",
        "Reacts well enough to survive the unexpected.",
        "Fast enough to dodge blades and catch falling heirs.",
        "Moves before the threat registers — virtually untouchable."
    },
    PHY_VIT = {
        "Sickly from birth; plagues will find them first.",
        "Prone to illness; vulnerable during epidemics.",
        "Healthy enough to weather most conditions.",
        "Radiates health; shrugs off fevers and blights.",
        "Near-immortal constitution — plagues pass them by entirely."
    },
    PHY_AGI = {
        "Clumsy and slow; fails mountain passes and escapes.",
        "Lacks the grace for difficult terrain or tight situations.",
        "Moves well enough through the world's challenges.",
        "Navigates treacherous ground and tight escapes with ease.",
        "Impossible grace — no terrain, trap, or obstacle can hold them."
    },
    PHY_PAI = {
        "Crumbles at the first wound; useless in the Blood Pit.",
        "Low tolerance; retreats from pain too quickly.",
        "Bears wounds without breaking.",
        "Fights through serious injury; hard to stop.",
        "Feels nothing — walks through fire, fights through death."
    },
    PHY_FER = {
        "The bloodline may end here. Few or no viable heirs.",
        "Unlikely to produce many offspring; succession at risk.",
        "Produces a healthy number of heirs to choose from.",
        "Highly fertile; plenty of candidates for the next generation.",
        "A wellspring of life — the bloodline will never lack for heirs."
    },
    PHY_LON = {
        "Destined for a short reign. Time is the enemy.",
        "Unlikely to rule long; fewer generations of impact.",
        "A normal lifespan — enough time to leave a mark.",
        "Ages slowly; a long reign to shape the bloodline.",
        "Seemingly ageless — decades to build, plan, and endure."
    },
    PHY_IMM = {
        "Defenseless against plague; first to fall in epidemics.",
        "Weak immunity; plagues hit harder and linger longer.",
        "Resists common disease well enough.",
        "Shrugs off plagues that decimate the populace.",
        "Blood so potent it purges any toxin or rot."
    },
    PHY_REC = {
        "Wounds fester and linger; injuries compound.",
        "Slow to heal; setbacks last longer.",
        "Recovers at a normal pace.",
        "Bounces back quickly; injuries rarely slow them down.",
        "Regenerative — recovers from near-death in days."
    },
    PHY_BON = {
        "Brittle bones; mountain crossings and falls are lethal.",
        "Fragile frame; vulnerable to crushing blows.",
        "Normal skeletal strength.",
        "Dense, heavy bones — hard to break, hard to stop.",
        "Skeleton like forged iron; virtually unbreakable."
    },
    PHY_LUN = {
        "Gasps for air on mountain passes; altitude is a death sentence.",
        "Poor breathing; struggles at elevation and under strain.",
        "Adequate breath control for most challenges.",
        "Deep lungs; excels in mountain crossings and underwater trials.",
        "Breathes where others suffocate — altitude and pressure mean nothing."
    },
    PHY_COR = {
        "Fumbles tools and weapons; a danger to themselves.",
        "Lacks the precision for delicate or dangerous work.",
        "Steady hands and reliable coordination.",
        "Expert control — excels with weapons, tools, and instruments.",
        "Perfect mastery over every movement; body obeys thought instantly."
    },
    PHY_MET = {
        "Burns through food and energy; famines hit doubly hard.",
        "Inefficient metabolism; needs more resources to function.",
        "Normal energy efficiency.",
        "Efficient body; survives on less during shortages.",
        "Thrives on crumbs — famine barely registers."
    },
    PHY_HGT = {
        "Short and compact; overlooked in crowds.",
        "Below average height.",
        "Average height.",
        "Tall and hard to ignore.",
        "Towers over everyone — an imposing physical presence."
    },
    PHY_BLD = {
        "Gaunt and frail; looks like a strong wind would end them.",
        "Lean and slight of build.",
        "A balanced, athletic frame.",
        "Broad and powerful; built for endurance.",
        "Massive and imposing — built like a fortress wall."
    },
    PHY_SEN = {
        "Oblivious to danger; ambushes and traps go unnoticed.",
        "Dull senses; misses what others catch.",
        "Alert enough to read the room.",
        "Sharp senses; spots threats and opportunities early.",
        "Predator's awareness — nothing moves unseen, unheard, or unsmelled."
    },
    PHY_ADP = {
        "Cannot function outside familiar conditions; climate kills.",
        "Struggles to adjust to new environments.",
        "Adapts to changing conditions over time.",
        "Quickly acclimates to heat, cold, and altitude.",
        "At home everywhere — the body reshapes itself to survive."
    },
    PHY_EYE = {
        "Sharp, emerald eyes.",
        "Icy blue eyes.",
        "Mist-grey eyes.",
        "Deep amber eyes.",
        "Piercing violet eyes."
    },
    PHY_HAI = {
        "Vivid, blood-red hair.",
        "Platinum-blonde hair.",
        "Burnished copper hair.",
        "Dark chestnut hair.",
        "Midnight-black hair."
    },
    PHY_SKN = {
        "Ghostly, porcelain skin.",
        "Pale, marble-like skin.",
        "Rich bronze skin.",
        "Weathered, olive skin.",
        "Deep obsidian-toned skin."
    },
    PHY_HTX = {
        "Silky straight hair.",
        "Flowing wavy hair.",
        "Wavy hair.",
        "Curly hair.",
        "Tightly coiled hair."
    },
    PHY_FSH = {
        "Very soft, rounded features.",
        "Defined features.",
        "Angular features.",
        "Sharp features.",
        "Razor-sharp, hawk-like features."
    },

    -- MENTAL
    MEN_INT = {
        "Too slow to read events or plan ahead; a liability in council.",
        "Struggles with complex decisions and strategy.",
        "Sharp enough to handle what the bloodline demands.",
        "A keen mind; sees solutions others miss.",
        "Transcendent intellect — outthinks every rival, every crisis."
    },
    MEN_MEM = {
        "Forgets alliances, grudges, and lessons — repeats old mistakes.",
        "Poor recall; the past is a blur.",
        "Remembers what matters.",
        "A scholarly memory; grudges and promises alike are never lost.",
        "Forgets nothing — every slight, every oath, every lesson etched in stone."
    },
    MEN_FOC = {
        "Scattered and unreliable; loses track of ongoing threats.",
        "Easily distracted from long-term goals.",
        "Focuses well when it counts.",
        "Unwavering attention; nothing slips past unnoticed.",
        "Locked on like a predator — can track a problem for years."
    },
    MEN_WIL = {
        "Breaks under pressure; easily swayed by rivals and events.",
        "Lacks the resolve to resist manipulation or hardship.",
        "Possesses a steady will.",
        "Stubborn and hard to bend; resists even the heir's own impulses.",
        "Iron will — nothing breaks them. Not pain. Not loss. Not time."
    },
    MEN_PER = {
        "Blind to threats and opportunities; always caught off guard.",
        "Misses obvious dangers and social cues.",
        "Observant enough to stay ahead of most trouble.",
        "Keen perception; catches shifts in faction mood and hidden threats.",
        "Nothing escapes their notice — sees the unseen, hears the unsaid."
    },
    MEN_ANA = {
        "Cannot untangle cause from effect; bad at reading event outcomes.",
        "Struggles to break down complex situations.",
        "Capable of working through most problems.",
        "Dissects problems quickly; excels at event stat checks.",
        "Deconstructs any system, any rival, any crisis — in seconds."
    },
    MEN_PAT = {
        "Sees only chaos; cannot anticipate consequences.",
        "Slow to spot trends or coming dangers.",
        "Recognizes the obvious patterns in the world.",
        "Reads the currents of history; anticipates shifts before they hit.",
        "Prophetic insight — predicts the future from the ripples of the past."
    },
    MEN_ITU = {
        "Gut instinct leads them wrong every time.",
        "Poor intuition; needs hard evidence for every decision.",
        "Reliable instincts in uncertain situations.",
        "Feels the truth before the facts arrive.",
        "Infallible instinct — the first guess is always right."
    },
    MEN_LRN = {
        "Painfully slow to adapt; falls behind as the world changes.",
        "Struggles to master new skills or ideas.",
        "Learns at a steady pace.",
        "A quick study; picks up skills and knowledge rapidly.",
        "Masters entire disciplines in a single generation."
    },
    MEN_COM = {
        "Panics in crisis; makes everything worse under pressure.",
        "Loses composure when stakes are high.",
        "Stays calm when it counts.",
        "A pillar of calm; steadies others during war and plague.",
        "Utterly unshakeable — the world could burn and they'd still think clearly."
    },
    MEN_SPA = {
        "Hopelessly lost in unfamiliar territory; fails navigation events.",
        "Poor sense of space and direction.",
        "Navigates well enough.",
        "Expert spatial awareness; excels in architecture and terrain.",
        "Sees the world from every angle — a born architect and navigator."
    },
    MEN_STR = {
        "Cannot plan beyond the current generation; no long-term vision.",
        "Short-sighted; misses long-term consequences.",
        "Plans ahead with reasonable foresight.",
        "A visionary strategist; plays the long game.",
        "Thinks in generations — every move serves the bloodline's future."
    },
    MEN_CUN = {
        "Naive and easily deceived; a target for every schemer.",
        "Lacks the guile to see through deception.",
        "Can be tricky when survival demands it.",
        "A master of manipulation; outmaneuvers rivals and factions.",
        "The architect of schemes — can deceive anyone, anywhere, anytime."
    },
    MEN_PLA = {
        "Rigid thinking; cannot adapt when the world shifts beneath them.",
        "Slow to change course.",
        "Adjusts beliefs when evidence demands it.",
        "Mentally flexible; thrives in changing eras and conditions.",
        "A mind like water — reshapes itself to fit any reality."
    },
    MEN_DRM = {
        "Dreamless and dull; no inner vision.",
        "Muddled subconscious.",
        "Vivid inner life; dreams lend occasional clarity.",
        "Prophetic clarity; the sleeping mind sees what waking eyes miss.",
        "The mind works even in sleep — a second life of insight."
    },
    MEN_STH = {
        "Crumbles under stress; makes bad decisions in crisis.",
        "Handles pressure poorly.",
        "Manages stress well enough to function.",
        "Thrives under pressure; performs better when stakes are highest.",
        "The greater the crisis, the sharper the mind becomes."
    },
    MEN_ABS = {
        "Cannot grasp metaphor, symbolism, or deeper meaning.",
        "Literal-minded; misses the subtext.",
        "Comfortable with abstract ideas.",
        "A philosopher's mind; masters the unseen and theoretical.",
        "Sees through the surface of everything — nothing is what it appears."
    },
    MEN_DEC = {
        "Paralyzed by choices; delays cost the bloodline dearly.",
        "Hesitates too long when action is needed.",
        "Decides with reasonable confidence.",
        "Bold and decisive; commits fully once a path is chosen.",
        "Instant, unerring judgment — never wastes a moment on doubt."
    },

    -- SOCIAL
    SOC_CHA = {
        "Repels people; factions and allies avoid the bloodline.",
        "Forgettable and uninspiring to others.",
        "Likable enough to maintain relationships.",
        "Magnetic; draws allies and sways opinions naturally.",
        "A force that pulls nations into orbit — impossible to ignore."
    },
    SOC_EMP = {
        "Cold and disconnected; cannot read or relate to others.",
        "Lacks understanding of what others feel or need.",
        "Compassionate enough to maintain trust.",
        "Deeply empathetic; feels the pain and joy of subjects and allies.",
        "Understands every soul they meet — the emotional heart of the bloodline."
    },
    SOC_INM = {
        "Completely unthreatening; rivals don't even register the heir.",
        "Lacks presence; easily dismissed.",
        "Commands a baseline of respect.",
        "Naturally intimidating; factions think twice before hostility.",
        "Terrifying aura — enemies submit before a word is spoken."
    },
    SOC_ELO = {
        "Stumbles over words; cannot persuade or inspire.",
        "Weak speaker; struggles to sway others.",
        "Speaks clearly and makes their case.",
        "Silver-tongued; turns council actions and diplomacy into art.",
        "Words so powerful they can stop wars or start religions."
    },
    SOC_DEC = {
        "Transparent as glass; every lie is obvious.",
        "Poor liar; secrets don't stay secret.",
        "Can keep a secret and bend the truth when needed.",
        "Convincing deceiver; rivals never see the true intent.",
        "A thousand masks — no one in {realm} knows their real face."
    },
    SOC_TRU = {
        "Known oath-breaker; no faction trusts the bloodline.",
        "Unreliable; alliances are fragile.",
        "Trustworthy enough to hold alliances together.",
        "A beacon of reliability; factions seek out the bloodline.",
        "Their word is the only currency that never devalues."
    },
    SOC_LEA = {
        "Cannot inspire or organize; the court falls apart.",
        "Weak leader; others question every decision.",
        "Leads competently when needed.",
        "A natural commander; others follow without hesitation.",
        "Defines an age — the kind of leader songs are written about."
    },
    SOC_NEG = {
        "Always gets the worst deal; gold and influence bleed away.",
        "Struggles to find fair terms in diplomacy.",
        "Negotiates reasonable outcomes.",
        "Expert dealmaker; always tips the balance in the bloodline's favor.",
        "Could sell ruin as prosperity and make the buyer feel grateful."
    },
    SOC_AWR = {
        "Socially blind; offends allies and misreads every room.",
        "Misses social cues; stumbles in court.",
        "Reads rooms well enough to avoid disaster.",
        "High social intelligence; navigates faction politics naturally.",
        "Reads the secret desires of a room before anyone speaks."
    },
    SOC_INF = {
        "Unknown; the bloodline's name carries no weight.",
        "Lacks social reach beyond the estate.",
        "Respected within their own lands.",
        "Renowned across {realm}; factions pay attention.",
        "A name that carries the weight of history itself."
    },
    SOC_LYS = {
        "Inspires nothing; no one would follow or fight for them.",
        "Lacks the bearing to inspire loyalty in others.",
        "Earns the loyalty of those who know them.",
        "Inspires deep loyalty; the court and allies stay true.",
        "To look upon them is to feel compelled to serve."
    },
    SOC_PAK = {
        "Forms no bonds; the bloodline is just a name to them.",
        "Slow to connect; family ties are weak.",
        "Bonds deeply with family and close allies.",
        "Intense loyalty to the inner circle; would die for blood.",
        "Would burn the world to protect a single loved one."
    },
    SOC_CON = {
        "Avoids all conflict; lets rivals walk over the bloodline.",
        "Backs down too easily; loses ground in disputes.",
        "Handles confrontation pragmatically.",
        "Naturally confrontational; doesn't let slights go unanswered.",
        "Thrives on conflict — a fire that burns brighter in a fight."
    },
    SOC_TEA = {
        "Cannot pass knowledge to the next generation effectively.",
        "Poor mentor; heirs and courts learn little from them.",
        "Transfers knowledge well enough.",
        "Inspiring teacher; the next generation arrives stronger.",
        "Could teach a stone to sing — a master of human potential."
    },
    SOC_MAN = {
        "Too transparent to influence anyone behind the scenes.",
        "Lacks the subtlety for political maneuvering.",
        "Can nudge opinions and shape outcomes quietly.",
        "Expert manipulator; reshapes faction politics from the shadows.",
        "Pulls every string in {realm} — and no one sees the hand."
    },
    SOC_CRD = {
        "Misreads crowds; public events backfire.",
        "Struggles to manage group sentiment.",
        "Reads and manages groups adequately.",
        "Expert at managing crowds and public perception.",
        "Plays a thousand people like a single instrument."
    },
    SOC_CUL = {
        "Offends every foreigner; cross-faction relations suffer.",
        "Struggles with foreign customs and diplomacy.",
        "Navigates cultural differences respectably.",
        "At ease in foreign courts; cross-faction bonds come naturally.",
        "A bridge between worlds — at home in every culture."
    },
    SOC_HUM = {
        "Humorless; takes everything literally. Tension never breaks.",
        "Lacks wit; conversations are heavy.",
        "Good-natured; lightens the mood when needed.",
        "Sharp wit that disarms tension and wins over rivals.",
        "Legendary humor — can defuse a crisis with a single line."
    },

    -- CREATIVE
    CRE_ING = {
        "No original thought; fails when old solutions don't apply.",
        "Struggles to solve problems that aren't straightforward.",
        "Finds workable solutions to most challenges.",
        "Ingenious problem-solver; excels in resource-scarce situations.",
        "Finds solutions that shouldn't exist — violates the logic of the possible."
    },
    CRE_CRA = {
        "Ruins every material they touch; no talent for making.",
        "Clumsy hands; poor at building or repairing.",
        "A competent builder; handles craft challenges well.",
        "Master artisan; creates works that strengthen the estate.",
        "Creates artifacts that vibrate with ancestral power."
    },
    CRE_EXP = {
        "Emotionally closed; cannot communicate meaning through any medium.",
        "Struggles to express ideas clearly.",
        "Communicates feelings and ideas effectively.",
        "Powerful expression; inspires through art, words, or presence.",
        "Every gesture communicates volumes — art and speech become one."
    },
    CRE_AES = {
        "Tasteless; cannot distinguish beauty from ugliness.",
        "Lacks aesthetic judgment.",
        "Appreciates and creates beauty in their surroundings.",
        "Refined taste; their eye elevates everything they touch.",
        "The final arbiter of beauty in {realm} — nothing escapes their judgment."
    },
    CRE_IMP = {
        "Freezes when plans fail; cannot adapt in the moment.",
        "Struggles when things don't go according to plan.",
        "Adapts on the fly when circumstances shift.",
        "Brilliant improviser; turns chaos into opportunity.",
        "Thrives in disorder — makes the impossible look planned."
    },
    CRE_VIS = {
        "No imagination; only sees what already exists.",
        "Lacks the ability to envision new possibilities.",
        "Dreams up workable ideas and plans.",
        "A visionary; sees futures others can't imagine.",
        "Sees things that haven't existed for a thousand years — and builds them."
    },
    CRE_NAR = {
        "Cannot tell a coherent story; history dies with them.",
        "Weak storyteller; the bloodline's deeds go unremembered.",
        "Tells the family's story well enough to be remembered.",
        "A master of myth; shapes how the bloodline is remembered.",
        "Weaves stories that become legend — reality bends to the telling."
    },
    CRE_MEC = {
        "Baffled by mechanisms; fails engineering challenges.",
        "Struggles with mechanical concepts.",
        "Understands how things work well enough.",
        "Mechanical genius; excels at engineering and invention.",
        "Speaks the language of gears and iron — machines obey."
    },
    CRE_MUS = {
        "Tone-deaf; music is noise to them.",
        "Lacks musical sense.",
        "Carries a tune; appreciates the power of song.",
        "Gifted musician; their music moves hearts and steadies nerves.",
        "The voice of the ancestors — can make the world dance or weep."
    },
    CRE_ARC = {
        "Cannot plan a structure; buildings crumble under their watch.",
        "Poor architectural instinct.",
        "Designs solid, functional structures.",
        "Visionary architect; great works rise under their direction.",
        "Designs monuments that look carved by gods — and last as long."
    },
    CRE_SYM = {
        "Blind to symbolism; rituals and ceremonies are empty motions.",
        "Misses the deeper meaning in signs and ceremony.",
        "Understands the language of symbol and ritual.",
        "Master of symbolism; gives weight to ceremony and meaning to marks.",
        "Sees the mythic structure underlying all of reality."
    },
    CRE_RES = {
        "Wastes everything; turns abundance into scarcity.",
        "Squanders resources and opportunities.",
        "Makes reasonable use of what's available.",
        "Incredibly resourceful; makes much from little.",
        "Could build a throne from a pile of ash."
    },
    CRE_INN = {
        "Clings to failing methods; cannot innovate even when dying.",
        "Slow to adopt new approaches.",
        "Improves things naturally over time.",
        "Compulsive innovator; pushes the bloodline forward.",
        "Never satisfied with what exists — always building what's next."
    },
    CRE_FLV = {
        "No discernment; treats all experiences equally.",
        "Poor sensory discrimination.",
        "Refined palate for life's subtleties.",
        "A connoisseur; their judgment elevates trade and culture.",
        "The ultimate judge of quality — nothing escapes their refined senses."
    },
    CRE_RIT = {
        "Ceremonies fall flat; faith and tradition lose power under them.",
        "Lacks instinct for meaningful ritual.",
        "Creates moments that feel significant.",
        "Master of ritual design; religious and cultural events resonate.",
        "Designs rituals that bind souls across generations."
    },
    CRE_TIN = {
        "No curiosity about how things work; never experiments.",
        "Rarely tinkers or explores mechanically.",
        "Naturally curious about objects and systems.",
        "Compulsive tinkerer; always improving and experimenting.",
        "A workshop of wonders — invention is their language."
    }
}

--- Get a dynamic summary for a trait based on its value.
---@param trait_id string
---@param value number 0-100
---@return string summary text
function TraitSummaries.get_summary(trait_id, value)
    local pool = TraitSummaries.POOLS[trait_id]
    if not pool then return "A trait of the bloodline." end

    local level = 1
    if value >= 85 then level = 5
    elseif value >= 65 then level = 4
    elseif value >= 40 then level = 3
    elseif value >= 20 then level = 2
    end

    return pool[level] or pool[3]
end

return TraitSummaries
