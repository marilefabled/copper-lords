-- Dark Legacy — Event Chain Definitions
-- Multi-generation story arcs that span 2-4 linked events.
-- Each chain has stages; player choices at each stage influence the next.
-- Pure Lua, zero Solar2D dependencies.

return {
    -- Chain 1: Track the source of a plague
    {
        id = "plague_origin",
        title = "The Source of the Sickness",
        stages = 3,
        trigger = {
            type = "condition",
            condition = "plague",
            min_generation = 3,
        },
        stage_delay = { 1, 2 }, -- min/max gens between stages
        events = {
            -- Stage 1: Discovery
            {
                stage = 1,
                title = "Whispers of the Source",
                narrative = "The plague has ravaged the land for too long. Rumors speak of its origin — a tainted well deep in the borderlands. {heir_name} must decide: seek it out, or endure.",
                options = {
                    {
                        label = "Investigate the source",
                        description = "Send scouts to the borderlands. Knowledge is power.",
                        choice_key = "investigate",
                        consequences = {
                            narrative = "Scouts venture into plague-touched lands.",
                            cultural_memory_shift = { mental = 3 },
                        },
                    },
                    {
                        label = "Endure and pray",
                        description = "Focus on survival. The plague will pass on its own.",
                        choice_key = "endure",
                        consequences = {
                            narrative = "The family hunkers down and waits.",
                            cultural_memory_shift = { physical = 2 },
                        },
                    },
                },
            },
            -- Stage 2: Confrontation (varies by choice)
            {
                stage = 2,
                title = "The Heart of the Plague",
                narrative_by_choice = {
                    investigate = "Your scouts found it — a fouled spring, guarded by desperate outcasts who worship the sickness. {heir_name} must choose how to deal with them.",
                    endure = "The plague persists. A wandering healer arrives, claiming to know the cure — but demands a terrible price.",
                    default = "The plague grows worse. A decision must be made.",
                },
                options_by_choice = {
                    investigate = {
                        {
                            label = "Purge the spring by force",
                            description = "Root out the cultists and cleanse the water.",
                            choice_key = "purge",
                            consequences = {
                                narrative = "Blood is spilled to cleanse the source.",
                                cultural_memory_shift = { physical = 5 },
                                mutation_triggers = { { type = "plague", intensity = 0.3 } },
                            },
                            requires = { axis = "PER_BLD", min = 40 },
                        },
                        {
                            label = "Negotiate with the outcasts",
                            description = "Perhaps they can be reasoned with.",
                            choice_key = "negotiate",
                            consequences = {
                                narrative = "Words prove mightier than swords — for now.",
                                cultural_memory_shift = { social = 5 },
                            },
                        },
                    },
                    endure = {
                        {
                            label = "Pay the healer's price",
                            description = "Whatever it takes to end the suffering.",
                            choice_key = "pay",
                            consequences = {
                                narrative = "The cost is steep, but the cure is real.",
                                cultural_memory_shift = { creative = -3 },
                            },
                        },
                        {
                            label = "Refuse and persist",
                            description = "The family has survived worse.",
                            choice_key = "refuse",
                            consequences = {
                                narrative = "The healer departs. The plague continues.",
                            },
                        },
                    },
                },
            },
            -- Stage 3: Resolution
            {
                stage = 3,
                title = "The Plague's Legacy",
                narrative_by_choice = {
                    purge = "The spring runs clear. The plague fades, but the violence leaves its mark on the bloodline.",
                    negotiate = "An uneasy peace holds with the outcasts. The plague weakens slowly, a compromise in all things.",
                    pay = "The healer's cure spreads through the land. But the price paid haunts the family's dreams.",
                    refuse = "The plague finally burns itself out. The family emerges scarred but unbroken.",
                    default = "The plague passes. Life continues.",
                },
                options = {
                    {
                        label = "Remember this lesson",
                        description = "The family will never forget.",
                        choice_key = "remember",
                        consequences = {
                            narrative = "A new chapter is written in the chronicle of survival.",
                            remove_condition = "plague",
                        },
                    },
                },
            },
        },
    },

    -- Chain 2: A rival heir emerges
    {
        id = "rival_heir",
        title = "The Shadow Heir",
        stages = 3,
        trigger = {
            type = "faction",
            faction_hostile = true,
            min_generation = 5,
        },
        stage_delay = { 2, 3 },
        events = {
            {
                stage = 1,
                title = "A Challenger Appears",
                narrative = "Word reaches {heir_name} that a rival house has produced an heir of extraordinary talent. They claim your bloodline's right to rule is ending.",
                options = {
                    {
                        label = "Challenge them openly",
                        description = "Meet this rival head-on.",
                        choice_key = "challenge",
                        consequences = {
                            narrative = "A public challenge is issued. The world watches.",
                            cultural_memory_shift = { physical = 3 },
                        },
                        requires = { axis = "PER_BLD", min = 50 },
                    },
                    {
                        label = "Study the rival",
                        description = "Knowledge of your enemy is the first weapon.",
                        choice_key = "study",
                        consequences = {
                            narrative = "Spies are dispatched. Information flows back.",
                            cultural_memory_shift = { mental = 3 },
                        },
                    },
                    {
                        label = "Ignore the pretender",
                        description = "They are beneath your notice.",
                        choice_key = "ignore",
                        consequences = {
                            narrative = "Silence can be a weapon — or a mistake.",
                        },
                        requires = { axis = "PER_PRI", min = 60 },
                    },
                },
            },
            {
                stage = 2,
                title = "The Rival Grows Bold",
                narrative_by_choice = {
                    challenge = "The rival accepted your challenge and won allies to their cause. Now they march toward your domain.",
                    study = "Your spies reveal the rival's weakness — but they also discovered your agents. Trust erodes.",
                    ignore = "Your silence emboldened them. The rival now claims sovereignty over your ancestral lands.",
                    default = "The rival's influence grows.",
                },
                options = {
                    {
                        label = "Propose alliance through marriage",
                        description = "If you can't beat them, join them.",
                        choice_key = "marry",
                        consequences = {
                            narrative = "A marriage pact is offered. Blood binds stronger than steel.",
                            cultural_memory_shift = { social = 5 },
                        },
                    },
                    {
                        label = "Crush them utterly",
                        description = "There can be only one dynasty.",
                        choice_key = "crush",
                        consequences = {
                            narrative = "War is declared. The bloodline commits everything.",
                            cultural_memory_shift = { physical = 5 },
                            mutation_triggers = { { type = "war", intensity = 0.5 } },
                        },
                        requires = { axis = "PER_CRM", min = 50 },
                    },
                },
            },
            {
                stage = 3,
                title = "The Rival's End",
                narrative_by_choice = {
                    marry = "The marriage unites two bloodlines. Old hatreds simmer beneath the surface, but the dynasty endures — changed, but stronger.",
                    crush = "The rival is destroyed. Their name is erased. But the cost in blood and reputation will echo for generations.",
                    default = "The rivalry reaches its conclusion.",
                },
                options = {
                    {
                        label = "Write the history",
                        description = "The victors decide what is remembered.",
                        choice_key = "conclude",
                        consequences = {
                            narrative = "The chronicle records your version of events.",
                        },
                    },
                },
            },
        },
    },

    -- Chain 3: Ancient artifact discovery
    {
        id = "ancient_artifact",
        title = "The Relic Below",
        stages = 4,
        trigger = {
            type = "trait",
            category = "creative",
            min_average = 55,
            min_generation = 8,
        },
        stage_delay = { 1, 2 },
        events = {
            {
                stage = 1,
                title = "Something in the Earth",
                narrative = "Diggers unearth something ancient beneath the family estate. It pulses with a light that has no source. {heir_name} must decide what to do with it.",
                options = {
                    {
                        label = "Study the artifact",
                        description = "Knowledge before action.",
                        choice_key = "study",
                        consequences = {
                            narrative = "Scholars are summoned. The artifact is examined.",
                            cultural_memory_shift = { mental = 3 },
                        },
                    },
                    {
                        label = "Seal it away",
                        description = "Some things are better left buried.",
                        choice_key = "seal",
                        consequences = {
                            narrative = "The artifact is reburied. But its light haunts the family's dreams.",
                        },
                    },
                },
            },
            {
                stage = 2,
                title = "The Artifact Speaks",
                narrative_by_choice = {
                    study = "The scholars report that the artifact contains knowledge from before the first era. It wants to be used.",
                    seal = "The sealed artifact calls to {heir_name} in dreams. It cannot be ignored forever.",
                    default = "The artifact's influence grows.",
                },
                options = {
                    {
                        label = "Unlock its power",
                        description = "The risk is worth the reward.",
                        choice_key = "unlock",
                        consequences = {
                            narrative = "The artifact opens. Something changes in the blood.",
                            mutation_triggers = { { type = "mystical", intensity = 0.7 } },
                        },
                        requires = { axis = "PER_CUR", min = 50 },
                    },
                    {
                        label = "Destroy it",
                        description = "End this before it consumes the bloodline.",
                        choice_key = "destroy",
                        consequences = {
                            narrative = "The artifact shatters. The light dies. But was it truly destroyed?",
                            cultural_memory_shift = { physical = 3 },
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "The Artifact's Gift",
                narrative_by_choice = {
                    unlock = "The artifact's knowledge floods into the bloodline. Senses sharpen. Minds expand. But something else entered too.",
                    destroy = "The shattered pieces of the artifact glow faintly in the family vault. They are reforming.",
                    default = "The artifact's story continues.",
                },
                options = {
                    {
                        label = "Embrace the change",
                        description = "Let the artifact's gift transform the bloodline.",
                        choice_key = "embrace",
                        consequences = {
                            narrative = "The bloodline is forever altered.",
                            mutation_triggers = { { type = "mystical", intensity = 1.0 } },
                            cultural_memory_shift = { creative = 8 },
                        },
                    },
                    {
                        label = "Fight the influence",
                        description = "The bloodline's identity must be preserved.",
                        choice_key = "resist",
                        consequences = {
                            narrative = "Willpower holds the line. The artifact's influence wanes.",
                            cultural_memory_shift = { mental = 5 },
                        },
                        requires = { axis = "PER_OBS", min = 40 },
                    },
                },
            },
            {
                stage = 4,
                title = "The Relic's Legacy",
                narrative_by_choice = {
                    embrace = "The artifact is now part of the bloodline. Its light glows in the family's eyes. The world will never look at them the same way.",
                    resist = "The artifact falls silent at last. The bloodline endured its temptation. But the memory of its power lingers.",
                    default = "The artifact's story ends — for now.",
                },
                options = {
                    {
                        label = "Record the truth",
                        description = "Future generations must know.",
                        choice_key = "record",
                        consequences = {
                            narrative = "The chronicle gains a chapter that reads like myth.",
                        },
                    },
                },
            },
        },
    },

    -- Chain 4: Betrayal from within
    {
        id = "betrayal_within",
        title = "The Traitor's Shadow",
        stages = 3,
        trigger = {
            type = "personality",
            axis = "PER_LOY",
            max_value = 35,
            min_generation = 5,
        },
        stage_delay = { 1, 2 },
        events = {
            {
                stage = 1,
                title = "Seeds of Doubt",
                narrative = "Trusted advisors whisper that someone close to {heir_name} plots against the family. The evidence is thin, but the suspicion grows.",
                options = {
                    {
                        label = "Investigate quietly",
                        description = "Find the truth before acting.",
                        choice_key = "investigate",
                        consequences = {
                            narrative = "Eyes and ears are placed in the household.",
                            cultural_memory_shift = { mental = 2 },
                        },
                    },
                    {
                        label = "Confront the suspects",
                        description = "Demand loyalty or face consequences.",
                        choice_key = "confront",
                        consequences = {
                            narrative = "Accusations fly. Bonds are tested.",
                            cultural_memory_shift = { social = -2 },
                        },
                        requires = { axis = "PER_BLD", min = 40 },
                    },
                },
            },
            {
                stage = 2,
                title = "The Traitor Revealed",
                narrative_by_choice = {
                    investigate = "The investigation reveals the traitor — a member of the inner circle, selling secrets to a rival house.",
                    confront = "Your confrontation spooked the traitor into acting early. An assassination attempt barely fails.",
                    default = "The betrayal becomes clear.",
                },
                options = {
                    {
                        label = "Execute the traitor",
                        description = "Make an example. Fear is loyalty's enforcer.",
                        choice_key = "execute",
                        consequences = {
                            narrative = "The traitor dies. The household trembles.",
                            cultural_memory_shift = { social = -3 },
                        },
                        requires = { axis = "PER_CRM", min = 50 },
                    },
                    {
                        label = "Exile them",
                        description = "Mercy may earn more loyalty than cruelty.",
                        choice_key = "exile",
                        consequences = {
                            narrative = "The traitor is cast out. Some call it weakness; others, wisdom.",
                            cultural_memory_shift = { social = 3 },
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "After the Betrayal",
                narrative_by_choice = {
                    execute = "The execution sends a clear message. The family's household is purged of doubt — and warmth.",
                    exile = "The exiled traitor joins a rival house. Their knowledge of your bloodline becomes a weapon in another's hands.",
                    default = "The betrayal's wounds slowly heal.",
                },
                options = {
                    {
                        label = "Strengthen the inner circle",
                        description = "Never again.",
                        choice_key = "strengthen",
                        consequences = {
                            narrative = "Trust is rebuilt, carefully and slowly.",
                            taboo_chance = 0.4,
                            taboo_data = { trigger = "betrayal", effect = "distrust_outsiders", strength = 60 },
                        },
                    },
                },
            },
        },
    },

    -- Chain 5: Forbidden knowledge
    {
        id = "forbidden_knowledge",
        title = "The Unwritten Texts",
        stages = 3,
        trigger = {
            type = "personality",
            axis = "PER_CUR",
            min_value = 65,
            min_generation = 7,
        },
        stage_delay = { 1, 3 },
        events = {
            {
                stage = 1,
                title = "The Hidden Library",
                narrative = "{heir_name}'s insatiable curiosity leads to a forbidden archive, sealed since before the current era. The knowledge within could transform the bloodline — or destroy it.",
                options = {
                    {
                        label = "Open the archive",
                        description = "Knowledge cannot be evil. Only ignorance.",
                        choice_key = "open",
                        consequences = {
                            narrative = "The seals break. Ancient knowledge floods in.",
                            cultural_memory_shift = { mental = 5 },
                        },
                    },
                    {
                        label = "Reseal and forget",
                        description = "Some doors should remain closed.",
                        choice_key = "reseal",
                        consequences = {
                            narrative = "Discipline prevails. The archive remains sealed.",
                        },
                    },
                },
            },
            {
                stage = 2,
                title = "The Price of Knowing",
                narrative_by_choice = {
                    open = "The forbidden texts reveal secrets of the bloodline's true nature. But the knowledge brings nightmares that won't stop.",
                    reseal = "The sealed archive calls in dreams. {heir_name}'s heir feels the pull even stronger.",
                    default = "The forbidden knowledge makes itself known.",
                },
                options = {
                    {
                        label = "Pursue the deeper truths",
                        description = "Follow the knowledge to its end.",
                        choice_key = "pursue",
                        consequences = {
                            narrative = "The mind expands beyond safe limits.",
                            mutation_triggers = { { type = "mystical", intensity = 0.6 } },
                            cultural_memory_shift = { mental = 5, creative = 3 },
                        },
                    },
                    {
                        label = "Burn the texts",
                        description = "End this madness before it consumes the bloodline.",
                        choice_key = "burn",
                        consequences = {
                            narrative = "Pages turn to ash. The nightmares fade. But so does something precious.",
                            cultural_memory_shift = { mental = -3 },
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "Enlightenment or Madness",
                narrative_by_choice = {
                    pursue = "The deepest truth is revealed: the bloodline carries something ancient within it. This knowledge brings clarity — and a burden no heir can put down.",
                    burn = "The ashes scatter on the wind. The family is safe, but a path to greatness has been forever closed.",
                    default = "The forbidden knowledge settles into history.",
                },
                options = {
                    {
                        label = "Accept what was learned",
                        description = "The truth changes nothing — and everything.",
                        choice_key = "accept",
                        consequences = {
                            narrative = "The bloodline carries new understanding. Whether it is a gift or a curse remains to be seen.",
                        },
                    },
                },
            },
        },
    },

    -- Chain 6: Succession crisis
    {
        id = "succession_crisis",
        title = "Blood Against Blood",
        stages = 2,
        trigger = {
            type = "special",
            condition = "multiple_heirs",
            min_generation = 4,
        },
        stage_delay = { 1, 1 },
        events = {
            {
                stage = 1,
                title = "The Disputed Succession",
                narrative = "The bloodline's strength has become its weakness. Multiple powerful heirs vie for dominance, and the family threatens to tear itself apart.",
                options = {
                    {
                        label = "Declare a trial of worth",
                        description = "Let the strongest prove themselves.",
                        choice_key = "trial",
                        consequences = {
                            narrative = "A contest is declared. The heirs compete.",
                            cultural_memory_shift = { physical = 3 },
                        },
                    },
                    {
                        label = "Broker a compromise",
                        description = "Divide responsibilities to preserve unity.",
                        choice_key = "compromise",
                        consequences = {
                            narrative = "Diplomacy holds the family together — barely.",
                            cultural_memory_shift = { social = 3 },
                        },
                    },
                },
            },
            {
                stage = 2,
                title = "The Succession Resolved",
                narrative_by_choice = {
                    trial = "The trial is complete. One heir stands victorious, but the others nurse their wounds — and their grudges.",
                    compromise = "The compromise holds, but the family's unity is a fragile thing. Resentment simmers.",
                    default = "The succession is settled.",
                },
                options = {
                    {
                        label = "Unite the bloodline",
                        description = "Heal what was broken.",
                        choice_key = "unite",
                        consequences = {
                            narrative = "The family moves forward. The scars remain.",
                        },
                    },
                },
            },
        },
    },

    -- Chain 7: The old pact
    {
        id = "the_old_pact",
        title = "The Pact Remembered",
        stages = 3,
        trigger = {
            type = "cultural_memory",
            requires = "old_relationship_ally",
            min_generation = 15,
        },
        stage_delay = { 2, 3 },
        events = {
            {
                stage = 1,
                title = "The Pact is Called",
                narrative = "An ancient ally invokes a pact made generations ago. They demand the bloodline honor its word — at a cost your ancestors never imagined.",
                options = {
                    {
                        label = "Honor the pact",
                        description = "A promise is a promise, no matter the cost.",
                        choice_key = "honor",
                        consequences = {
                            narrative = "The word of the bloodline holds. The cost begins.",
                            cultural_memory_shift = { social = 5 },
                        },
                        requires = { axis = "PER_LOY", min = 40 },
                    },
                    {
                        label = "Refuse the pact",
                        description = "Times have changed. The pact is outdated.",
                        choice_key = "refuse",
                        consequences = {
                            narrative = "The pact is broken. An ally becomes an enemy.",
                            cultural_memory_shift = { social = -5 },
                        },
                    },
                },
            },
            {
                stage = 2,
                title = "The Pact's Weight",
                narrative_by_choice = {
                    honor = "Honoring the pact drains resources but strengthens bonds. Your ally rewards loyalty with loyalty.",
                    refuse = "The betrayed ally spreads word of your dishonor. Former friends grow cold.",
                    default = "The pact's consequences unfold.",
                },
                options = {
                    {
                        label = "See it through",
                        description = "Stay the course.",
                        choice_key = "continue",
                        consequences = {
                            narrative = "The story of the pact continues to unfold.",
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "The Pact's Legacy",
                narrative_by_choice = {
                    honor = "The honored pact becomes legend. Your family's word is known to be iron. Allies seek you out.",
                    refuse = "The broken pact becomes a cautionary tale. Your family is known for pragmatism — or treachery.",
                    default = "The pact passes into history.",
                },
                options = {
                    {
                        label = "Write it in the chronicle",
                        description = "Let history judge.",
                        choice_key = "chronicle",
                        consequences = {
                            narrative = "The pact's story is recorded for all time.",
                        },
                    },
                },
            },
        },
    },

    -- Chain 8: Blood prophecy
    {
        id = "blood_prophecy",
        title = "The Prophecy in the Blood",
        stages = 4,
        trigger = {
            type = "special",
            condition = "trait_fossil",
            min_generation = 12,
        },
        stage_delay = { 1, 2 },
        events = {
            {
                stage = 1,
                title = "A Vision in the Blood",
                narrative = "A seer approaches {heir_name} with an impossible claim: the blood itself carries a prophecy. Traits that once defined the family's greatest ancestor are stirring again.",
                options = {
                    {
                        label = "Listen to the seer",
                        description = "If the blood speaks, the blood should be heard.",
                        choice_key = "listen",
                        consequences = {
                            narrative = "The seer reveals fragments of the prophecy.",
                            cultural_memory_shift = { creative = 3 },
                        },
                    },
                    {
                        label = "Dismiss the seer",
                        description = "Prophecies are for fools.",
                        choice_key = "dismiss",
                        consequences = {
                            narrative = "The seer departs with a warning: the blood will not be ignored.",
                        },
                    },
                },
            },
            {
                stage = 2,
                title = "The Prophecy Unfolds",
                narrative_by_choice = {
                    listen = "The prophecy speaks of a restoration — the bloodline's lost greatness returning through a single heir. But the path is narrow.",
                    dismiss = "Despite being dismissed, the prophecy manifests. Strange echoes of past ancestors appear in the heir's abilities.",
                    default = "The prophecy makes itself known.",
                },
                options = {
                    {
                        label = "Pursue the prophecy",
                        description = "Breed toward the vision. Force destiny.",
                        choice_key = "pursue",
                        consequences = {
                            narrative = "The bloodline bends toward its prophesied shape.",
                            cultural_memory_shift = { creative = 5, mental = 3 },
                        },
                    },
                    {
                        label = "Let fate decide",
                        description = "If it's meant to be, it will happen without forcing.",
                        choice_key = "fate",
                        consequences = {
                            narrative = "The family continues as it always has. What will be, will be.",
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "The Trial of Blood",
                narrative_by_choice = {
                    pursue = "Generations of deliberate breeding converge. The prophesied heir is born — but the trial isn't over.",
                    fate = "Without guidance, the prophecy's path twists. An unexpected heir emerges with echoes of the old blood.",
                    default = "The prophecy approaches its climax.",
                },
                options = {
                    {
                        label = "Protect the chosen heir",
                        description = "This heir must survive at all costs.",
                        choice_key = "protect",
                        consequences = {
                            narrative = "Everything is sacrificed to protect the prophesied one.",
                            cultural_memory_shift = { physical = 3, social = -2 },
                        },
                    },
                    {
                        label = "Test them like any other",
                        description = "Prophecy means nothing if the heir is weak.",
                        choice_key = "test",
                        consequences = {
                            narrative = "The heir faces the same trials as every ancestor before them.",
                        },
                    },
                },
            },
            {
                stage = 4,
                title = "The Prophecy's End",
                narrative_by_choice = {
                    protect = "The protected heir fulfills the prophecy. The bloodline's lost traits surge back to life. But at what cost to the family's other strengths?",
                    test = "Tested and proven, the heir carries the prophecy forward on their own strength. The restoration is partial but earned.",
                    default = "The prophecy reaches its conclusion.",
                },
                options = {
                    {
                        label = "Accept the blood's destiny",
                        description = "The prophecy is fulfilled.",
                        choice_key = "accept",
                        consequences = {
                            narrative = "The blood prophecy passes into legend. The bloodline is changed forever.",
                            mutation_triggers = { { type = "mystical", intensity = 0.5 } },
                        },
                    },
                },
            },
        },
    },

    -- Chain 9: The Great War (3 stages, triggered by prolonged campaign)
    {
        id = "the_great_war",
        title = "The Great War",
        stages = 3,
        trigger = {
            type = "condition",
            condition = "war",
            min_duration = 3,
            min_generation = 8,
        },
        stage_delay = { 1, 2 },
        events = {
            {
                stage = 1,
                title = "The War Widens",
                narrative = "What began as a border dispute has consumed everything. Allies are drawn in. Neutral houses choose sides. {heir_name} watches the map and sees no safe ground left.",
                options = {
                    {
                        label = "Forge a grand alliance",
                        description = "Unite every willing house against the common enemy.",
                        choice_key = "alliance",
                        consequences = {
                            narrative = "Banners were raised from every corner of the realm. The alliance was fragile, but it was massive.",
                            cultural_memory_shift = { social = 5 },
                            disposition_changes = { { faction_id = "all", delta = 10 } },
                        },
                    },
                    {
                        label = "Fight alone",
                        description = "Allies are liabilities. The bloodline needs no one.",
                        choice_key = "alone",
                        consequences = {
                            narrative = "The bloodline stood alone. It was terrifying. It was also, in its own grim way, magnificent.",
                            cultural_memory_shift = { physical = 5 },
                            mutation_triggers = { { type = "war", intensity = 0.5 } },
                        },
                        requires = { axis = "PER_PRI", min = 55 },
                    },
                },
            },
            {
                stage = 2,
                title = "The Turning Point",
                narrative_by_choice = {
                    alliance = "The grand alliance meets the enemy in a decisive engagement. Every house has committed its best. There will be no second chances.",
                    alone = "Alone and surrounded, the bloodline faces the decisive battle. No reserves. No retreat. Only the weight of blood and the edge of iron.",
                    default = "The war reaches its climax. A single battle will decide everything.",
                },
                options = {
                    {
                        label = "Lead the charge personally",
                        description = "The heir at the front. The bloodline's name on every lip.",
                        choice_key = "charge",
                        consequences = {
                            narrative = "The charge was legendary. Songs would be written — if anyone survived to sing them.",
                            cultural_memory_shift = { physical = 6, social = 3 },
                        },
                        requires = { axis = "PER_BLD", min = 50 },
                    },
                    {
                        label = "Command from the rear",
                        description = "Strategy wins wars. Heroics win graves.",
                        choice_key = "command",
                        consequences = {
                            narrative = "The battle was won by precision, not passion. The heir's name was spoken with respect, not awe.",
                            cultural_memory_shift = { mental = 5, social = 2 },
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "The Peace",
                narrative_by_choice = {
                    charge = "The war is over. The bloodline's charge broke the enemy. Now the terms must be set — and the dead must be counted.",
                    command = "The war is over. Strategy carried the day. Now the victors must decide what peace looks like.",
                    default = "The great war ends. The world will never be the same.",
                },
                options = {
                    {
                        label = "Dictate harsh terms",
                        description = "They started this. They'll remember how it ended.",
                        choice_key = "harsh",
                        consequences = {
                            narrative = "The terms were carved in stone and sealed with humiliation. The defeated would remember. They would always remember.",
                            remove_condition = "war",
                            cultural_memory_shift = { physical = 3, social = -3 },
                            disposition_changes = { { faction_id = "all", delta = -10 } },
                            taboo_chance = 0.5,
                            taboo_data = { trigger = "great_war_victory", effect = "righteous_conquest", strength = 70 },
                        },
                    },
                    {
                        label = "Offer generous peace",
                        description = "Mercy now prevents the next war.",
                        choice_key = "generous",
                        consequences = {
                            narrative = "The peace was generous. Former enemies were treated as future allies. It was either wisdom or naivety — history would decide.",
                            remove_condition = "war",
                            cultural_memory_shift = { social = 6 },
                            disposition_changes = { { faction_id = "all", delta = 15 } },
                        },
                    },
                },
            },
        },
    },

    -- Chain 10: Blood Feud (4 stages, triggered by intense faction grudge)
    {
        id = "blood_feud",
        title = "The Blood Feud",
        stages = 4,
        trigger = {
            type = "faction",
            faction_hostile = true,
            faction_grudge_intensity_min = 60,
            min_generation = 8,
        },
        stage_delay = { 2, 3 },
        events = {
            {
                stage = 1,
                title = "The Insult Remembered",
                narrative = "An old wound tears open. A faction's envoy arrives bearing a list of grievances — not demands, but a recitation. They want {heir_name} to know that nothing has been forgotten.",
                options = {
                    {
                        label = "Apologize for past wrongs",
                        description = "Humility may defuse this before it ignites.",
                        choice_key = "apologize",
                        consequences = {
                            narrative = "The apology was offered. Whether it was accepted remained to be seen. But the gesture was noted.",
                            cultural_memory_shift = { social = 3 },
                        },
                    },
                    {
                        label = "Dismiss the grievances",
                        description = "The past is past. They need to move on.",
                        choice_key = "dismiss",
                        consequences = {
                            narrative = "The dismissal was absolute. The envoy's face went white, then red. The feud deepened.",
                            cultural_memory_shift = { social = -3 },
                        },
                        requires = { axis = "PER_PRI", min = 50 },
                    },
                },
            },
            {
                stage = 2,
                title = "Escalation",
                narrative_by_choice = {
                    apologize = "The apology was rejected. They wanted more — a raid on your borders, a kidnapping of a vassal. The feud has its own momentum now.",
                    dismiss = "Your dismissal was the spark. Raids strike your holdings. Allies are pressured to abandon you. The feud becomes a siege of reputation.",
                    default = "The feud escalates beyond words.",
                },
                options = {
                    {
                        label = "Retaliate in kind",
                        description = "Strike back. Match them blow for blow.",
                        choice_key = "retaliate",
                        consequences = {
                            narrative = "The bloodline struck back. Raids answered raids. The border became a wound that wouldn't close.",
                            cultural_memory_shift = { physical = 4, social = -2 },
                            mutation_triggers = { { type = "war", intensity = 0.4 } },
                        },
                        requires = { axis = "PER_BLD", min = 40 },
                    },
                    {
                        label = "Seek mediation",
                        description = "Find a neutral party. End this before it consumes both houses.",
                        choice_key = "mediate",
                        consequences = {
                            narrative = "A mediator was found — reluctantly. Both sides sat at a table they'd rather have overturned.",
                            cultural_memory_shift = { social = 4 },
                        },
                    },
                },
            },
            {
                stage = 3,
                title = "The Reckoning",
                narrative_by_choice = {
                    retaliate = "The cycle of retaliation has reached its breaking point. One side must break — or both will. A final confrontation is unavoidable.",
                    mediate = "Mediation has stalled. Both sides have agreed to a final resolution — a duel between champions, or a war to end it.",
                    default = "The feud demands resolution.",
                },
                options = {
                    {
                        label = "Declare war and end this",
                        description = "No more half-measures. Total war.",
                        choice_key = "war",
                        consequences = {
                            narrative = "War was declared. Not the petty raids of before, but proper war. The kind that ends houses.",
                            add_condition = { type = "war", intensity = 0.7, duration = 4 },
                            cultural_memory_shift = { physical = 5 },
                        },
                        requires = { axis = "PER_BLD", min = 45 },
                    },
                    {
                        label = "Challenge their champion to a grand duel",
                        description = "One fight. Two champions. The world watches.",
                        choice_key = "duel",
                        consequences = {
                            narrative = "The duel was set. Champions named. The weight of generations rested on two pairs of shoulders.",
                            cultural_memory_shift = { physical = 3, social = 3 },
                        },
                    },
                },
            },
            {
                stage = 4,
                title = "The Feud's Legacy",
                narrative_by_choice = {
                    war = "The war ended. One house stands diminished but alive. The other stands victorious but exhausted. The feud is over — or is it merely sleeping?",
                    duel = "The duel is finished. One champion fell. The crowd was silent. Whatever was settled, it was settled with blood.",
                    default = "The blood feud reaches its end.",
                },
                options = {
                    {
                        label = "Let the feud die",
                        description = "Enough blood has been spilled. Let it end here.",
                        choice_key = "end",
                        consequences = {
                            narrative = "The feud was declared over. Both houses bore their scars. The chronicle recorded it all — the insult, the raids, the reckoning, and the exhausted peace.",
                            remove_condition = "war",
                            cultural_memory_shift = { social = 3 },
                            taboo_chance = 0.6,
                            taboo_data = { trigger = "blood_feud", effect = "feud_memory", strength = 75 },
                        },
                    },
                    {
                        label = "Swear an oath: this house will be destroyed",
                        description = "The feud doesn't end. It transforms.",
                        choice_key = "oath",
                        consequences = {
                            narrative = "An oath was sworn in blood. The feud became a crusade. Future generations would inherit not just land and title, but a holy obligation of destruction.",
                            cultural_memory_shift = { physical = 3, social = -4 },
                            taboo_chance = 1.0,
                            taboo_data = { trigger = "blood_feud_oath", effect = "eternal_enmity", strength = 90 },
                        },
                        requires = { axis = "PER_OBS", min = 55 },
                    },
                },
            },
        },
    },
}
