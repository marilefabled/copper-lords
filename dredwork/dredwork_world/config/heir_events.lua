-- Bloodweight — Heir Life Events
-- Personality-routed moments that happen EVERY generation.
-- Format matches Crucible Trials for reuse of the Crucible engine.
-- 18 events across physical, mental, social, mystical, creative themes.

return {
    -- =====================================================================
    -- 1. THE CHILDHOOD RIVAL (social — PER_VOL / PER_CRM)
    -- =====================================================================
    {
        id = "childhood_rival",
        name = "The Childhood Rival",
        theme = "social",
        opening = "In the halls of {lineage_name}, {heir_name} was never alone. A rival, born of a lesser branch, challenged every step.",
        stages = {
            {
                title = "The First Clash",
                narrative = "The rival mocks {heir_name}'s clumsy practice with the blade.",
                paths = {
                    {
                        id = "challenge",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} lashes out in a fury, ignoring the master's warnings.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 45 },
                        },
                    },
                    {
                        id = "ignore",
                        personality_axis = "PER_VOL",
                        direction = "low",
                        narrative = "{heir_name} continues the drill, eyes fixed forward, mind like stone.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_FOC", weight = 0.5, threshold = 50 },
                        },
                    },
                },
            },
            {
                title = "The Betrayal",
                narrative = "Years later, the rival attempts to undermine {heir_name} before the council.",
                paths = {
                    {
                        id = "expose",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} reveals a dark secret of the rival, ending their career forever.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_DEC", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "pardon",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} dismisses the charges with a laugh, showing the council who is truly in control.",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_ELO", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 2. THE GREAT HUNT (physical — PER_OBS / PER_BLD / PER_PRI)
    -- =====================================================================
    {
        id = "the_great_hunt",
        name = "The Great Hunt",
        theme = "physical",
        opening = "To prove their worth, {heir_name} must lead a hunt into the deepest woods of {realm}.",
        stages = {
            {
                title = "The Tracks",
                narrative = "The beast's trail is cold. The forest is silent.",
                paths = {
                    {
                        id = "patience",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} waits through the night, a shadow among shadows.",
                        trait_checks = {
                            { trait_id = "PHY_SEN", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_FOC", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "drive",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} pushes the hounds through the thicket, refusing to lose the scent.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Kill",
                narrative = "The beast is cornered. It is larger and more terrible than the tales told.",
                paths = {
                    {
                        id = "blade",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} closes the distance, wanting to feel the beast's breath.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.6, threshold = 65 },
                            { trait_id = "PHY_REF", weight = 0.4, threshold = 60 },
                        },
                    },
                    {
                        id = "bow",
                        personality_axis = "PER_PRI",
                        direction = "low",
                        narrative = "{heir_name} takes the shot from the shadows, prioritizing the kill over the glory.",
                        trait_checks = {
                            { trait_id = "PHY_COR", weight = 0.6, threshold = 65 },
                            { trait_id = "MEN_COM", weight = 0.4, threshold = 60 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 3. THE FORBIDDEN TOME (mental — PER_CUR / PER_VOL / PER_OBS / PER_LOY)
    -- =====================================================================
    {
        id = "forbidden_tome",
        name = "The Forbidden Tome",
        theme = "mental",
        opening = "A secret library, sealed by the ancestors, has been opened by {heir_name}.",
        stages = {
            {
                title = "The Seal",
                narrative = "The doors are locked with puzzles of logic and blood.",
                paths = {
                    {
                        id = "solve",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} spends weeks decoding the mechanisms, fascinated by the complexity.",
                        trait_checks = {
                            { trait_id = "MEN_INT", weight = 0.5, threshold = 65 },
                            { trait_id = "MEN_ANA", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "force",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} breaks the lock with a heavy hammer, uncaring for the artistry.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.6, threshold = 60 },
                            { trait_id = "CRE_MEC", weight = 0.4, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Knowledge",
                narrative = "The scrolls within speak of things the family has spent centuries trying to forget.",
                paths = {
                    {
                        id = "learn",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} devours the knowledge, regardless of the cost to their soul.",
                        trait_checks = {
                            { trait_id = "MEN_MEM", weight = 0.5, threshold = 65 },
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "burn",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} burns the library to the ground. Some secrets should stay buried.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.6, threshold = 60 },
                            { trait_id = "SOC_LEA", weight = 0.4, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 4. THE FEAST OF FOOLS (social — PER_ADA / PER_LOY / PER_VOL)
    -- =====================================================================
    {
        id = "the_feast_of_fools",
        name = "The Feast of Fools",
        theme = "social",
        opening = "A grand festival is held in the holdfast. {heir_name} must navigate the chaos and the masks.",
        stages = {
            {
                title = "The Masquerade",
                narrative = "A masked stranger approaches, offering a dance and a dangerous rumor.",
                paths = {
                    {
                        id = "dance",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} joins the dance, playing the game of masks and whispers.",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_AWR", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "watch",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} remains on the sidelines, watching the masks slip.",
                        trait_checks = {
                            { trait_id = "MEN_PER", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_CUN", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Brawl",
                narrative = "A fight breaks out in the great hall. The festival turns sour.",
                paths = {
                    {
                        id = "quell",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} steps between the fighters, demanding peace in the name of the bloodline.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 65 },
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "provoke",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} joins the fray, wanting to see who is truly strong.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_REF", weight = 0.5, threshold = 60 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 5. THE BROKEN ENGAGEMENT (social — PER_PRI / PER_ADA)
    -- =====================================================================
    {
        id = "the_broken_engagement",
        name = "The Broken Engagement",
        theme = "social",
        opening = "An alliance through marriage, years in the making, has been shattered by {heir_name}.",
        stages = {
            {
                title = "The Reason",
                narrative = "The court demands to know why the match was ended.",
                paths = {
                    {
                        id = "personal_distaste",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} simply states that the other was beneath the bloodline.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 65 },
                            { trait_id = "SOC_ELO", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "political_pivot",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} presents a list of strategic reasons for the change.",
                        trait_checks = {
                            { trait_id = "MEN_ANA", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_NEG", weight = 0.5, threshold = 60 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 6. THE HAUNTED KEEP (mystical — PER_OBS / PER_CUR)
    -- =====================================================================
    {
        id = "the_haunted_keep",
        name = "The Haunted Keep",
        theme = "mystical",
        opening = "Sent to govern a remote outpost, {heir_name} finds the keep is not as empty as it seems.",
        stages = {
            {
                title = "The Manifestation",
                narrative = "Objects move. Cold spots linger. A voice calls from the cellar.",
                paths = {
                    {
                        id = "exorcise",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} performs a ritual of cleansing, refusing to be intimidated.",
                        trait_checks = {
                            { trait_id = "CRE_RIT", weight = 0.5, threshold = 65 },
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "commune",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} seeks to understand the entity, offering blood and attention.",
                        trait_checks = {
                            { trait_id = "MEN_ABS", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_ITU", weight = 0.5, threshold = 60 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 7. THE DROWNING VILLAGE (physical — PER_BLD / PER_CRM)
    -- =====================================================================
    {
        id = "the_drowning_village",
        name = "The Drowning Village",
        theme = "physical",
        opening = "Floodwaters swallow a vassal village overnight. {heir_name} receives word at dawn.",
        stages = {
            {
                title = "The Waters Rise",
                narrative = "Survivors cling to rooftops. The river shows no sign of mercy.",
                paths = {
                    {
                        id = "wade_in",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} leads the rescue personally, waist-deep in the current.",
                        trait_checks = {
                            { trait_id = "PHY_END", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "direct_from_shore",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} organizes the effort from high ground, directing boats and ropes.",
                        trait_checks = {
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_STR", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Reckoning",
                narrative = "The waters recede. The village is mud and silence. Someone must decide what remains.",
                paths = {
                    {
                        id = "rebuild",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} pledges the holdfast's reserves to rebuild every home.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 60 },
                            { trait_id = "CRE_ARC", weight = 0.5, threshold = 50 },
                        },
                    },
                    {
                        id = "relocate",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} declares the site cursed and orders the survivors to the holdfast as laborers.",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 8. THE POISONED GIFT (mental — PER_CUR / PER_LOY)
    -- =====================================================================
    {
        id = "the_poisoned_gift",
        name = "The Poisoned Gift",
        theme = "mental",
        opening = "A crate arrives at the holdfast bearing the seal of an old ally. Inside: a bottle of rare wine and a letter of reconciliation.",
        stages = {
            {
                title = "The Suspicion",
                narrative = "The cellar master notes an unfamiliar sediment. The letter's handwriting trembles.",
                paths = {
                    {
                        id = "test_it",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} pours a measure for the hounds first, watching with clinical interest.",
                        trait_checks = {
                            { trait_id = "MEN_PER", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_ANA", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "drink_it",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} drinks deeply, refusing to insult an old friend with doubt.",
                        trait_checks = {
                            { trait_id = "PHY_IMM", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_VIT", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 9. THE BASTARD'S CLAIM (social — PER_LOY / PER_PRI)
    -- =====================================================================
    {
        id = "the_bastards_claim",
        name = "The Bastard's Claim",
        theme = "social",
        opening = "A stranger arrives at court claiming blood of {lineage_name}. They carry a birthmark that cannot be faked.",
        stages = {
            {
                title = "The Audience",
                narrative = "The court holds its breath. The stranger kneels, but not low enough.",
                paths = {
                    {
                        id = "acknowledge",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} accepts the claim, naming the stranger a ward of the bloodline.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_TRU", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "deny",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} declares the birthmark a coincidence and has the stranger escorted to the border.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Consequence",
                narrative = "Word spreads. The court whispers. The stranger's eyes linger on the throne.",
                paths = {
                    {
                        id = "elevate",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} gives the stranger a minor holding, keeping a potential enemy close.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_STR", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "silence",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} ensures the stranger vanishes before the next sunrise.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_MAN", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 10. THE FORGE BELOW (creative — PER_OBS / PER_CUR)
    -- =====================================================================
    {
        id = "the_forge_below",
        name = "The Forge Below",
        theme = "creative",
        opening = "Workers expanding the cellars break through into a chamber that should not exist. Inside: an ancient forge, still warm.",
        stages = {
            {
                title = "The First Flame",
                narrative = "The forge hums with a resonance that sets teeth on edge. Tools line the walls, some recognizable, some not.",
                paths = {
                    {
                        id = "study",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} spends days cataloguing every instrument, sketching the forge's construction.",
                        trait_checks = {
                            { trait_id = "CRE_MEC", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_PAT", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "use_it",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} begins hammering immediately, driven by a compulsion older than reason.",
                        trait_checks = {
                            { trait_id = "CRE_CRA", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_END", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 11. THE SILENT PLAGUE (physical — PER_ADA / PER_OBS)
    -- =====================================================================
    {
        id = "the_silent_plague",
        name = "The Silent Plague",
        theme = "physical",
        opening = "It begins with the servants. A cough. A pallor. Then the children stop eating.",
        stages = {
            {
                title = "The Quarantine",
                narrative = "The healer advises sealing the east wing. The servants beg to be let out.",
                paths = {
                    {
                        id = "seal_it",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} bars the doors personally, deaf to the pleading within.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "tend_them",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} enters the east wing without a mask, tending the sick with their own hands.",
                        trait_checks = {
                            { trait_id = "PHY_IMM", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Survivor's Guilt",
                narrative = "The plague passes. The holdfast is diminished. {heir_name} is the last to leave the sickroom.",
                paths = {
                    {
                        id = "mourn",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} names every corpse in the ledger, refusing to let the dead become numbers.",
                        trait_checks = {
                            { trait_id = "MEN_MEM", weight = 0.5, threshold = 55 },
                            { trait_id = "CRE_NAR", weight = 0.5, threshold = 50 },
                        },
                    },
                    {
                        id = "move_on",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} orders the east wing scrubbed and repurposed before the week is out.",
                        trait_checks = {
                            { trait_id = "MEN_DEC", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_STH", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 12. THE WANDERING SCHOLAR (mental — PER_CUR / PER_PRI)
    -- =====================================================================
    {
        id = "the_wandering_scholar",
        name = "The Wandering Scholar",
        theme = "mental",
        opening = "A disheveled traveler arrives claiming knowledge that will reshape the holdfast's understanding of its own history.",
        stages = {
            {
                title = "The Lecture",
                narrative = "The scholar unfurls a genealogy that contradicts three generations of accepted truth.",
                paths = {
                    {
                        id = "listen",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} clears the hall and listens until the candles gutter.",
                        trait_checks = {
                            { trait_id = "MEN_LRN", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_INT", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "dismiss",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} has the genealogy burned before the court can read it.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_DEC", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 13. THE COLLAPSED MINE (physical — PER_BLD / PER_LOY)
    -- =====================================================================
    {
        id = "the_collapsed_mine",
        name = "The Collapsed Mine",
        theme = "physical",
        opening = "The iron mine that feeds the holdfast caves in at midday. Thirty workers are trapped below.",
        stages = {
            {
                title = "The Shaft",
                narrative = "The foreman says digging will take three days. The air below will last two.",
                paths = {
                    {
                        id = "dig",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} strips to the waist and takes the first shift with the pick.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_END", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "engineer",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} summons every mason in the holding and devises a shoring plan.",
                        trait_checks = {
                            { trait_id = "MEN_SPA", weight = 0.5, threshold = 60 },
                            { trait_id = "CRE_MEC", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Toll",
                narrative = "Some are saved. Some are not. The mine must reopen if the holdfast is to survive.",
                paths = {
                    {
                        id = "compensate",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} pays the widows double and names the dead in the great hall.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "conscript",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} orders prisoners into the reopened shaft before the dust has settled.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 60 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 14. THE NIGHT COURT (social — PER_CRM / PER_ADA)
    -- =====================================================================
    {
        id = "the_night_court",
        name = "The Night Court",
        theme = "social",
        opening = "A servant is caught stealing grain from the holdfast stores. The punishment is death. The servant's child watches from the gallery.",
        stages = {
            {
                title = "The Verdict",
                narrative = "The court awaits {heir_name}'s judgment. The law is clear. The child's eyes are not.",
                paths = {
                    {
                        id = "execute",
                        personality_axis = "PER_CRM",
                        direction = "high",
                        narrative = "{heir_name} pronounces the sentence without looking at the gallery.",
                        trait_checks = {
                            { trait_id = "MEN_COM", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "commute",
                        personality_axis = "PER_CRM",
                        direction = "low",
                        narrative = "{heir_name} sentences the servant to the mines, commuting death to labor.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_STR", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Precedent",
                narrative = "Word of the judgment spreads. The holdfast watches to see what kind of ruler this will be.",
                paths = {
                    {
                        id = "codify",
                        personality_axis = "PER_ADA",
                        direction = "low",
                        narrative = "{heir_name} writes the judgment into law, ensuring the same sentence applies to all who follow.",
                        trait_checks = {
                            { trait_id = "MEN_ANA", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_LEA", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "leave_ambiguous",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} lets the precedent stand unwritten, preserving the right to judge each case anew.",
                        trait_checks = {
                            { trait_id = "MEN_CUN", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_MAN", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 15. THE OLD STEWARD'S CONFESSION (mental — PER_LOY / PER_CRM)
    -- =====================================================================
    {
        id = "the_old_stewards_confession",
        name = "The Old Steward's Confession",
        theme = "mental",
        opening = "On his deathbed, the holdfast's steward of forty years confesses to {heir_name} that the treasury has been short for decades.",
        stages = {
            {
                title = "The Ledger",
                narrative = "The numbers do not add up. They never did. The missing gold went to a family the steward never declared.",
                paths = {
                    {
                        id = "investigate",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} tears through the records, tracing every missing coin across thirty years.",
                        trait_checks = {
                            { trait_id = "MEN_ANA", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_FOC", weight = 0.5, threshold = 60 },
                        },
                    },
                    {
                        id = "forgive",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} closes the ledger and sits with the old man until he passes.",
                        trait_checks = {
                            { trait_id = "SOC_EMP", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 16. THE BRIDGE AT DAWN (physical — PER_BLD / PER_PRI)
    -- =====================================================================
    {
        id = "the_bridge_at_dawn",
        name = "The Bridge at Dawn",
        theme = "physical",
        opening = "A neighboring lord issues a formal challenge. Single combat. The bridge between their holdings. Dawn.",
        stages = {
            {
                title = "The Crossing",
                narrative = "The bridge is narrow. The river below is loud enough to swallow a scream.",
                paths = {
                    {
                        id = "fight",
                        personality_axis = "PER_BLD",
                        direction = "high",
                        narrative = "{heir_name} walks to the center of the bridge and draws steel without a word.",
                        trait_checks = {
                            { trait_id = "PHY_REF", weight = 0.5, threshold = 60 },
                            { trait_id = "PHY_AGI", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "negotiate",
                        personality_axis = "PER_BLD",
                        direction = "low",
                        narrative = "{heir_name} arrives with a treaty instead of a sword, betting on words over iron.",
                        trait_checks = {
                            { trait_id = "SOC_NEG", weight = 0.5, threshold = 60 },
                            { trait_id = "SOC_ELO", weight = 0.5, threshold = 60 },
                        },
                    },
                },
            },
            {
                title = "The Aftermath",
                narrative = "Blood or ink stains the bridge. Either way, the neighboring lord remembers this morning.",
                paths = {
                    {
                        id = "press_advantage",
                        personality_axis = "PER_PRI",
                        direction = "high",
                        narrative = "{heir_name} demands concessions while the opponent's pride is still bleeding.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 60 },
                            { trait_id = "MEN_STR", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "show_mercy",
                        personality_axis = "PER_PRI",
                        direction = "low",
                        narrative = "{heir_name} extends a hand, converting an enemy into a reluctant debtor.",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_NEG", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 17. THE ARTIST'S OBSESSION (creative — PER_OBS / PER_VOL)
    -- =====================================================================
    {
        id = "the_artists_obsession",
        name = "The Artist's Obsession",
        theme = "creative",
        opening = "{heir_name} commissions a portrait of the bloodline's history. The painter goes mad before finishing.",
        stages = {
            {
                title = "The Unfinished Work",
                narrative = "The painting is half brilliance, half fever dream. The faces of dead heirs stare from the canvas with accusatory precision.",
                paths = {
                    {
                        id = "finish_it",
                        personality_axis = "PER_OBS",
                        direction = "high",
                        narrative = "{heir_name} takes up the brush personally, working through the night to complete what the painter could not.",
                        trait_checks = {
                            { trait_id = "CRE_EXP", weight = 0.5, threshold = 55 },
                            { trait_id = "CRE_VIS", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "destroy_it",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} slashes the canvas with a dining knife, unable to bear the dead watching.",
                        trait_checks = {
                            { trait_id = "PHY_STR", weight = 0.5, threshold = 45 },
                            { trait_id = "MEN_STH", weight = 0.5, threshold = 50 },
                        },
                    },
                },
            },
        },
    },

    -- =====================================================================
    -- 18. THE EMPTY CRADLE (mystical — PER_VOL / PER_LOY)
    -- =====================================================================
    {
        id = "the_empty_cradle",
        name = "The Empty Cradle",
        theme = "mystical",
        opening = "A child is born to {lineage_name}, but something is wrong. The midwife will not meet {heir_name}'s eyes.",
        stages = {
            {
                title = "The Vigil",
                narrative = "The child does not cry. Does not open its eyes. But breathes, faintly, for three days.",
                paths = {
                    {
                        id = "pray",
                        personality_axis = "PER_LOY",
                        direction = "high",
                        narrative = "{heir_name} kneels beside the cradle for three days, refusing food, whispering the names of every ancestor.",
                        trait_checks = {
                            { trait_id = "MEN_WIL", weight = 0.5, threshold = 60 },
                            { trait_id = "CRE_RIT", weight = 0.5, threshold = 50 },
                        },
                    },
                    {
                        id = "rage",
                        personality_axis = "PER_VOL",
                        direction = "high",
                        narrative = "{heir_name} hurls the midwife's medicines from the window and demands a different healer from every holding.",
                        trait_checks = {
                            { trait_id = "SOC_INM", weight = 0.5, threshold = 55 },
                            { trait_id = "SOC_INF", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
            {
                title = "The Fourth Morning",
                narrative = "On the fourth morning, the child opens its eyes. They are the wrong color.",
                paths = {
                    {
                        id = "accept",
                        personality_axis = "PER_ADA",
                        direction = "high",
                        narrative = "{heir_name} names the child anyway and orders the holdfast to celebrate.",
                        trait_checks = {
                            { trait_id = "SOC_CHA", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_PLA", weight = 0.5, threshold = 55 },
                        },
                    },
                    {
                        id = "consult",
                        personality_axis = "PER_CUR",
                        direction = "high",
                        narrative = "{heir_name} sends for the oldest healer in {realm}, needing to understand what the eyes mean.",
                        trait_checks = {
                            { trait_id = "MEN_ITU", weight = 0.5, threshold = 55 },
                            { trait_id = "MEN_ABS", weight = 0.5, threshold = 55 },
                        },
                    },
                },
            },
        },
    },
}
