-- Dark Legacy — Trait Definitions
-- All 70 traits defined as data. Pure data table, no logic.
-- Categories: physical (18), mental (18), social (18), creative (16)

local trait_definitions = {

    -- =========================================================================
    -- PHYSICAL (18 traits)
    -- =========================================================================
    { id = "PHY_STR", name = "Strength",                 category = "physical", scale = "standard",   description = "Raw physical power",                              visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_END", name = "Endurance",                category = "physical", scale = "standard",   description = "Sustained physical effort",                       visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_REF", name = "Reflexes",                 category = "physical", scale = "standard",   description = "Reaction speed",                                 visibility = "visible", inheritance_mode = "dominant_recessive" },
    { id = "PHY_VIT", name = "Vitality",                 category = "physical", scale = "standard",   description = "Base health, disease resistance",                 visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_AGI", name = "Agility",                  category = "physical", scale = "standard",   description = "Movement speed, flexibility",                     visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_PAI", name = "Pain Tolerance",           category = "physical", scale = "standard",   description = "Threshold before impairment",                     visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_FER", name = "Fertility",                category = "physical", scale = "standard",   description = "Likelihood of producing offspring",               visibility = "hidden",  inheritance_mode = "blended" },
    { id = "PHY_LON", name = "Longevity",                category = "physical", scale = "standard",   description = "Natural lifespan tendency",                       visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_IMM", name = "Immune Response",          category = "physical", scale = "standard",   description = "Resistance to plague/disease events",             visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_REC", name = "Recovery Rate",            category = "physical", scale = "standard",   description = "Speed of healing after injury",                   visibility = "hinted",  inheritance_mode = "blended" },
    { id = "PHY_BON", name = "Bone Density",             category = "physical", scale = "standard",   description = "Skeletal resilience",                             visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_LUN", name = "Lung Capacity",            category = "physical", scale = "standard",   description = "Stamina in extreme conditions",                   visibility = "hidden",  inheritance_mode = "blended" },
    { id = "PHY_COR", name = "Coordination",             category = "physical", scale = "standard",   description = "Fine motor control",                              visibility = "hinted",  inheritance_mode = "blended" },
    { id = "PHY_MET", name = "Metabolism",               category = "physical", scale = "standard",   description = "Efficiency of nutrient processing",               visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_HGT", name = "Height Tendency",          category = "physical", scale = "magnitude",  description = "Tall vs short tendency",                          visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_BLD", name = "Build",                    category = "physical", scale = "magnitude",  description = "Lean vs stocky tendency",                         visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_SEN", name = "Senses (Acute)",           category = "physical", scale = "standard",   description = "Sharpness of sight/hearing/smell",                visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "PHY_ADP", name = "Adaptability (Physical)",  category = "physical", scale = "standard",   description = "Body's ability to acclimate to new environments", visibility = "hidden",  inheritance_mode = "blended" },
    { id = "PHY_EYE", name = "Eye Color",                category = "physical", scale = "pigment",    description = "Pigmentation of the iris (Light to Dark)",        visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_HAI", name = "Hair Color",               category = "physical", scale = "pigment",    description = "Pigmentation of hair (Light to Dark)",            visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_SKN", name = "Skin Tone",                category = "physical", scale = "pigment",    description = "Melanin density in the skin (Fair to Deep)",       visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_HTX", name = "Hair Texture",             category = "physical", scale = "texture",    description = "Structure of hair (Straight to Coily)",           visibility = "visible", inheritance_mode = "blended" },
    { id = "PHY_FSH", name = "Face Shape",               category = "physical", scale = "angularity", description = "Structure of facial features (Soft to Angular)",   visibility = "visible", inheritance_mode = "blended" },

    -- =========================================================================
    -- MENTAL (18 traits)
    -- =========================================================================
    { id = "MEN_INT", name = "Intellect",            category = "mental", scale = "standard", description = "Raw cognitive ability",                          visibility = "visible", inheritance_mode = "blended" },
    { id = "MEN_MEM", name = "Memory",               category = "mental", scale = "standard", description = "Retention and recall",                           visibility = "visible", inheritance_mode = "dominant_recessive" },
    { id = "MEN_FOC", name = "Focus",                category = "mental", scale = "standard", description = "Sustained attention",                            visibility = "visible", inheritance_mode = "blended" },
    { id = "MEN_WIL", name = "Willpower",            category = "mental", scale = "standard", description = "Resistance to coercion, mental endurance",       visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_PER", name = "Perception",           category = "mental", scale = "standard", description = "Ability to read situations, notice details",     visibility = "visible", inheritance_mode = "blended" },
    { id = "MEN_ANA", name = "Analytical Thinking",  category = "mental", scale = "standard", description = "Breaking problems into parts",                   visibility = "hinted",  inheritance_mode = "blended" },
    { id = "MEN_PAT", name = "Pattern Recognition",  category = "mental", scale = "standard", description = "Spotting trends, connections",                   visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_ITU", name = "Intuition",            category = "mental", scale = "standard", description = "Gut-level decision accuracy",                    visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_LRN", name = "Learning Speed",       category = "mental", scale = "standard", description = "Rate of skill acquisition",                      visibility = "hinted",  inheritance_mode = "blended" },
    { id = "MEN_COM", name = "Composure",            category = "mental", scale = "standard", description = "Clarity under pressure",                         visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_SPA", name = "Spatial Reasoning",    category = "mental", scale = "standard", description = "Navigation, architecture, tactics",              visibility = "hidden",  inheritance_mode = "blended" },
    { id = "MEN_STR", name = "Strategic Depth",      category = "mental", scale = "standard", description = "Long-term planning capacity",                    visibility = "hinted",  inheritance_mode = "blended" },
    { id = "MEN_CUN", name = "Cunning",              category = "mental", scale = "standard", description = "Deception ability, reading manipulation",        visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_PLA", name = "Mental Plasticity",    category = "mental", scale = "standard", description = "Ability to change beliefs/habits",               visibility = "hidden",  inheritance_mode = "blended" },
    { id = "MEN_DRM", name = "Dream Clarity",        category = "mental", scale = "standard", description = "Vividness of subconscious processing",           visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "MEN_STH", name = "Stress Threshold",     category = "mental", scale = "standard", description = "Point at which cognition degrades",              visibility = "hidden",  inheritance_mode = "blended" },
    { id = "MEN_ABS", name = "Abstract Thought",     category = "mental", scale = "standard", description = "Comfort with non-literal concepts",              visibility = "hidden",  inheritance_mode = "blended" },
    { id = "MEN_DEC", name = "Decisiveness",         category = "mental", scale = "standard", description = "Speed and confidence of choices",                visibility = "hinted",  inheritance_mode = "dominant_recessive" },

    -- =========================================================================
    -- SOCIAL (18 traits)
    -- =========================================================================
    { id = "SOC_CHA", name = "Charisma",              category = "social", scale = "standard",  description = "Presence, magnetism",                                  visibility = "visible", inheritance_mode = "dominant_recessive" },
    { id = "SOC_EMP", name = "Empathy",               category = "social", scale = "standard",  description = "Ability to feel others' states",                       visibility = "visible", inheritance_mode = "blended" },
    { id = "SOC_INM", name = "Intimidation",          category = "social", scale = "standard",  description = "Ability to project threat/authority",                   visibility = "visible", inheritance_mode = "dominant_recessive" },
    { id = "SOC_ELO", name = "Eloquence",             category = "social", scale = "standard",  description = "Verbal persuasion and clarity",                        visibility = "visible", inheritance_mode = "blended" },
    { id = "SOC_DEC", name = "Deception",             category = "social", scale = "standard",  description = "Ability to mislead convincingly",                      visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "SOC_TRU", name = "Trustworthiness",       category = "social", scale = "standard",  description = "How reliably they keep commitments",                   visibility = "hinted",  inheritance_mode = "blended" },
    { id = "SOC_LEA", name = "Leadership",            category = "social", scale = "standard",  description = "Ability to organize and inspire groups",               visibility = "visible", inheritance_mode = "blended" },
    { id = "SOC_NEG", name = "Negotiation",           category = "social", scale = "standard",  description = "Finding mutually beneficial terms",                    visibility = "hinted",  inheritance_mode = "blended" },
    { id = "SOC_AWR", name = "Social Awareness",      category = "social", scale = "standard",  description = "Reading room dynamics, status",                        visibility = "hinted",  inheritance_mode = "blended" },
    { id = "SOC_INF", name = "Influence Reach",       category = "social", scale = "standard",  description = "How far their reputation carries",                     visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "SOC_LYS", name = "Loyalty Signal",        category = "social", scale = "standard",  description = "How loyalty-worthy they appear to others",             visibility = "hidden",  inheritance_mode = "blended" },
    { id = "SOC_PAK", name = "Pack Bonding",          category = "social", scale = "intensity", description = "Speed/depth of forming attachments",                   visibility = "hidden",  inheritance_mode = "blended" },
    { id = "SOC_CON", name = "Conflict Style",        category = "social", scale = "intensity", description = "Tendency toward confrontation vs avoidance",           visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "SOC_TEA", name = "Teaching Ability",      category = "social", scale = "standard",  description = "Capacity to transfer knowledge",                      visibility = "hinted",  inheritance_mode = "blended" },
    { id = "SOC_MAN", name = "Manipulative Range",    category = "social", scale = "standard",  description = "Sophistication of social manipulation",                visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "SOC_CRD", name = "Crowd Reading",         category = "social", scale = "standard",  description = "Ability to read group sentiment",                     visibility = "hidden",  inheritance_mode = "blended" },
    { id = "SOC_CUL", name = "Cultural Sensitivity",  category = "social", scale = "standard",  description = "Ability to navigate foreign social norms",             visibility = "hidden",  inheritance_mode = "blended" },
    { id = "SOC_HUM", name = "Humor",                 category = "social", scale = "standard",  description = "Comedic instinct, social disarming",                  visibility = "hinted",  inheritance_mode = "dominant_recessive" },

    -- =========================================================================
    -- CREATIVE (16 traits)
    -- =========================================================================
    { id = "CRE_ING", name = "Ingenuity",           category = "creative", scale = "standard", description = "Novel problem-solving",                                 visibility = "visible", inheritance_mode = "blended" },
    { id = "CRE_CRA", name = "Craftsmanship",       category = "creative", scale = "standard", description = "Skill in building/making",                              visibility = "visible", inheritance_mode = "blended" },
    { id = "CRE_EXP", name = "Expression",          category = "creative", scale = "standard", description = "Ability to externalize internal states",                visibility = "visible", inheritance_mode = "blended" },
    { id = "CRE_AES", name = "Aesthetic Sense",     category = "creative", scale = "standard", description = "Sensitivity to beauty, design",                         visibility = "hinted",  inheritance_mode = "blended" },
    { id = "CRE_IMP", name = "Improvisation",       category = "creative", scale = "standard", description = "Creating under pressure without prep",                  visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "CRE_VIS", name = "Vision",              category = "creative", scale = "standard", description = "Ability to imagine things that don't exist yet",        visibility = "hinted",  inheritance_mode = "dominant_recessive" },
    { id = "CRE_NAR", name = "Narrative Instinct",  category = "creative", scale = "standard", description = "Storytelling, mythmaking",                              visibility = "hinted",  inheritance_mode = "blended" },
    { id = "CRE_MEC", name = "Mechanical Aptitude", category = "creative", scale = "standard", description = "Understanding how things work/fit together",            visibility = "visible", inheritance_mode = "blended" },
    { id = "CRE_MUS", name = "Musical Sense",       category = "creative", scale = "standard", description = "Rhythm, harmony, auditory pattern",                    visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "CRE_ARC", name = "Architectural Eye",   category = "creative", scale = "standard", description = "Structural design, spatial beauty",                    visibility = "hidden",  inheritance_mode = "blended" },
    { id = "CRE_SYM", name = "Symbolic Thinking",   category = "creative", scale = "standard", description = "Ability to work with metaphor, ritual",                visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "CRE_RES", name = "Resourcefulness",     category = "creative", scale = "standard", description = "Making much from little",                              visibility = "hinted",  inheritance_mode = "blended" },
    { id = "CRE_INN", name = "Innovation Drive",    category = "creative", scale = "standard", description = "Compulsion to improve/change things",                  visibility = "hidden",  inheritance_mode = "blended" },
    { id = "CRE_FLV", name = "Flavor/Taste",        category = "creative", scale = "standard", description = "Culinary, material, sensory discrimination",           visibility = "hidden",  inheritance_mode = "blended" },
    { id = "CRE_RIT", name = "Ritual Design",       category = "creative", scale = "standard", description = "Ability to create meaningful ceremonies",              visibility = "hidden",  inheritance_mode = "dominant_recessive" },
    { id = "CRE_TIN", name = "Tinkering",           category = "creative", scale = "standard", description = "Compulsive experimentation with objects",              visibility = "hidden",  inheritance_mode = "dominant_recessive" },
}

-- Build a lookup table by ID for fast access
local by_id = {}
for _, def in ipairs(trait_definitions) do
    by_id[def.id] = def
end
trait_definitions.by_id = by_id

return trait_definitions
