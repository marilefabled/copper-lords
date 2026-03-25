-- dredwork Happenings — Event Catalog
-- Each happening has conditions, text, and options gated by signals/personality/location.
-- The player's perception determines what choices they see.

return {
    --------------------------------------------------------------------------
    -- STRANGER AT THE DOOR
    --------------------------------------------------------------------------
    {
        id = "stranger_door",
        title = "A Knock at Dawn",
        category = "social",
        chance = 0.06,
        cooldown_days = 20,
        condition = function(gs, focal, loc_type)
            return loc_type == "home" or loc_type == nil
        end,
        text = {
            "A knock at your door before sunrise. A figure stands in the half-light, hood drawn. They're shaking.",
            "Someone is at your door. They didn't use the road — you can see from the window they came through the fields.",
        },
        options = {
            {
                id = "feed_them",
                label = "Let them in. Feed them.",
                description = "Compassion costs bread.",
                consequences = {
                    { type = "text", value = "You share what little you have. They eat in silence. Before leaving, they grip your hand. 'I won't forget this.'" },
                    { type = "need", need = "belonging", delta = 5 },
                    { type = "gold", delta = -3, reason = "fed a stranger" },
                    { type = "relationship", target = "random_nearby", rel_type = "gratitude", delta = 10 },
                },
            },
            {
                id = "turn_away",
                label = "Send them away.",
                description = "You can't help everyone.",
                consequences = {
                    { type = "text", value = "You close the door. Their footsteps fade. You tell yourself it was the right call." },
                    { type = "need", need = "belonging", delta = -3 },
                },
            },
            {
                id = "interrogate",
                label = "Let them in — but watch their hands.",
                description = "Those aren't a beggar's calluses.",
                requires_affinity = { domain = "espionage", min = 35 },
                consequences = {
                    { type = "text", value = "You notice the scars. The way they scan the room. This is no vagrant. They're running from something — or someone. They owe you a truth now." },
                    { type = "need", need = "purpose", delta = 3 },
                    { type = "affinity_train", domain = "espionage", amount = 2 },
                },
            },
            {
                id = "recognize_spy",
                label = "You've seen that sigil before. Under the cloak.",
                description = "They're from the ruling house.",
                requires_affinity = { domain = "espionage", min = 55 },
                requires_claim_status = "whispered",
                consequences = {
                    { type = "text", value = "Your blood runs cold. The sigil beneath their traveling cloak — you recognize it. They weren't sent to beg. They were sent to find you. The question is: do they know they found you?" },
                    { type = "suspicion", delta = 15 },
                    { type = "need", need = "safety", delta = -15 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- A BODY IN THE ALLEY
    --------------------------------------------------------------------------
    {
        id = "body_alley",
        title = "Something in the Alley",
        category = "crime",
        chance = 0.04,
        cooldown_days = 40,
        condition = function(gs, focal, loc_type)
            return (loc_type == "market" or loc_type == "tavern") and
                gs.underworld and (gs.underworld.global_corruption or 0) > 30
        end,
        text = "A crowd gathers at the mouth of an alley. You push through. A body. Still warm. Nobody is talking.",
        options = {
            {
                id = "walk_away",
                label = "Keep walking. Not your problem.",
                description = "Getting involved is dangerous.",
                consequences = {
                    { type = "text", value = "You walk past. The crowd parts for you. By evening, no one mentions it. That's how things work here." },
                },
            },
            {
                id = "examine_body",
                label = "Look closer.",
                description = "Something about the wounds...",
                requires_affinity = { domain = "crime", min = 30 },
                consequences = {
                    { type = "text", value = "The cuts are precise. Professional. This wasn't a robbery — this was a message. Whoever did this wanted it found." },
                    { type = "affinity_train", domain = "crime", amount = 3 },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
            {
                id = "recognize_victim",
                label = "Wait. You know that face.",
                description = "That's someone connected to the court.",
                requires_affinity = { domain = "politics", min = 45 },
                consequences = {
                    { type = "text", value = "The face is familiar. You've seen them at court — a minor functionary, someone who handled records. Why would anyone kill a clerk? Unless the records were the point." },
                    { type = "affinity_train", domain = "politics", amount = 2 },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                },
            },
            {
                id = "take_evidence",
                label = "Pocket the document they were clutching.",
                description = "Before anyone else notices.",
                requires_affinity = { domain = "espionage", min = 45 },
                requires_personality = { PER_OBS = 45 },
                consequences = {
                    { type = "text", value = "Your hand moves before your conscience catches up. A folded paper, blood-spotted, slipped into your coat. Nobody saw. You'll read it later. Somewhere private." },
                    { type = "item", item_spec = { type = "document", name = "Bloodstained Document", description = "Taken from a dead clerk in an alley. The contents could be valuable — or dangerous.",
                        emotional_weight = -3, properties = { discovery = true } } },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- A LETTER ARRIVES
    --------------------------------------------------------------------------
    {
        id = "mysterious_letter",
        title = "A Letter Without a Seal",
        category = "espionage",
        chance = 0.05,
        cooldown_days = 30,
        condition = function(gs, focal, loc_type)
            return gs.claim and gs.claim.status ~= "hidden" and #(gs.claim.known_by or {}) >= 1
        end,
        text = "A letter, slipped under your door. No seal. No name. Just two words: 'They know.'",
        options = {
            {
                id = "panic",
                label = "Pack. Now. Move.",
                description = "Every second you stay is a second too long.",
                consequences = {
                    { type = "text", value = "You throw what you can carry into a bag. The ring. The blade. Nothing else matters. You're on the road before the sun clears the trees." },
                    { type = "need", need = "safety", delta = -20 },
                    { type = "need", need = "comfort", delta = -10 },
                },
            },
            {
                id = "calm_analyze",
                label = "Sit down. Think. Who sent this?",
                description = "Panicking is what they want.",
                requires_affinity = { domain = "espionage", min = 40 },
                consequences = {
                    { type = "text", value = "The paper. The ink. The handwriting. You don't recognize it, but you notice details: the paper is expensive. This came from someone with resources. A warning — or a trap." },
                    { type = "affinity_train", domain = "espionage", amount = 3 },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
            {
                id = "identify_sender",
                label = "The ink. You've seen this ink before.",
                description = "Someone in the court uses this exact shade.",
                requires_affinity = { domain = "espionage", min = 65 },
                requires_affinity_secondary = { domain = "social", min = 40 },
                consequences = {
                    { type = "text", value = "The deep blue-black. Expensive. Imported. Only one person you know uses this ink — and they sit at the treasurer's desk. They sent this. The question is why. Warning? Guilt? A play?" },
                    { type = "affinity_train", domain = "espionage", amount = 5 },
                    { type = "need", need = "purpose", delta = 8 },
                },
            },
            {
                id = "burn_it",
                label = "Burn it. Pretend it never came.",
                description = "What letter?",
                consequences = {
                    { type = "text", value = "The paper curls. Blackens. Gone. You watch the smoke. But the words stay. 'They know.' You can't unread that." },
                    { type = "need", need = "safety", delta = -5 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- FIRE IN THE NIGHT
    --------------------------------------------------------------------------
    {
        id = "fire_night",
        title = "Smoke and Shouts",
        category = "peril",
        chance = 0.04,
        cooldown_days = 45,
        condition = function(gs, focal, loc_type)
            return true -- can happen anywhere
        end,
        text = "You smell it before you see it. Smoke. Then the shouts. Something is burning.",
        options = {
            {
                id = "help",
                label = "Help fight the fire.",
                description = "People are in danger.",
                consequences = {
                    { type = "text", value = "You haul water until your arms give out. The fire dies before the building does, barely. Soot-covered strangers nod at you. You've been seen." },
                    { type = "need", need = "belonging", delta = 8 },
                    { type = "need", need = "comfort", delta = -5 },
                    { type = "relationship", target = "random_nearby", rel_type = "gratitude", delta = 15 },
                    { type = "rumor", subject = "a stranger", rumor_text = "Someone helped fight the fire last night. Nobody knew their name.", heat = 25, tags = { praise = true } },
                },
            },
            {
                id = "watch",
                label = "Watch from a distance.",
                description = "Not your fight.",
                consequences = {
                    { type = "text", value = "You watch the flames from the shadows. People run. Scream. You do nothing. When it's over, you slip away." },
                    { type = "need", need = "safety", delta = 2 },
                },
            },
            {
                id = "investigate_cause",
                label = "The fire started at the base of the wall. Deliberately.",
                description = "That's not where cooking fires go.",
                requires_affinity = { domain = "crime", min = 40 },
                consequences = {
                    { type = "text", value = "Char patterns don't lie. This fire was set. Oil at the foundation. Someone wanted this building to burn — and whoever lived in it to die or flee." },
                    { type = "affinity_train", domain = "crime", amount = 3 },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
            {
                id = "loot",
                label = "In the chaos, nobody's watching the market stalls.",
                description = "Survival doesn't care about morality.",
                requires_personality = { PER_CRM = 45 },
                consequences = {
                    { type = "text", value = "Your hands move while the world burns. Coins. Bread. A blade. Nobody saw. You think." },
                    { type = "gold", delta = 15, reason = "looted during fire" },
                    { type = "need", need = "comfort", delta = 3 },
                    { type = "need", need = "belonging", delta = -5 },
                },
                tags = { "cruel_act" },
            },
        },
    },

    --------------------------------------------------------------------------
    -- SOMEONE RECOGNIZES YOU
    --------------------------------------------------------------------------
    {
        id = "recognized",
        title = "A Familiar Face",
        category = "claim",
        chance = 0.06,
        cooldown_days = 25,
        condition = function(gs, focal, loc_type)
            return gs.claim and gs.claim.type and (loc_type == "market" or loc_type == "tavern" or loc_type == "court")
        end,
        text = {
            "A woman stops mid-stride. Stares. You've never seen her before. But the way she looks at you — she's seeing someone else. Someone you look like.",
            "An old man at the edge of the crowd freezes when you pass. His eyes go wide. He mouths a name. Not yours.",
        },
        options = {
            {
                id = "ignore",
                label = "Keep walking. Don't look back.",
                description = "They'll doubt themselves.",
                consequences = {
                    { type = "text", value = "You don't turn. You don't run. You walk. Steady. Normal. Behind you, you hear nothing. Maybe they let it go. Maybe." },
                    { type = "suspicion", delta = 3 },
                },
            },
            {
                id = "confront",
                label = "Stop. Look them in the eye. 'Can I help you?'",
                description = "Boldness can be its own disguise.",
                requires_personality = { PER_BLD = 40 },
                consequences = {
                    { type = "text", value = "They blink. Look away. 'Sorry, I... you remind me of someone.' They hurry off. You breathe. But they'll remember this face." },
                    { type = "suspicion", delta = 5 },
                },
            },
            {
                id = "follow_them",
                label = "Let them go. Then follow.",
                description = "They know something. Find out what.",
                requires_affinity = { domain = "espionage", min = 35 },
                consequences = {
                    { type = "text", value = "You trail them through three streets. They stop at a door you recognize — it belongs to someone connected to the ruling house. They knock. They're let in. Whatever they saw in your face, they're reporting it." },
                    { type = "suspicion", delta = 10 },
                    { type = "affinity_train", domain = "espionage", amount = 3 },
                    { type = "need", need = "safety", delta = -8 },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
            {
                id = "deny_aggressively",
                label = "Grab their arm. 'You're mistaken. Forget my face.'",
                description = "Make sure they understand.",
                requires_personality = { PER_BLD = 55 },
                consequences = {
                    { type = "text", value = "Fear in their eyes. Good. They nod. Pull free. Walk away fast. They won't talk — but they won't forget either." },
                    { type = "suspicion", delta = -2 },
                    { type = "need", need = "safety", delta = 3 },
                    { type = "need", need = "belonging", delta = -3 },
                },
                tags = { "hostile" },
            },
        },
    },

    --------------------------------------------------------------------------
    -- AN OFFER YOU CAN'T REFUSE
    --------------------------------------------------------------------------
    {
        id = "shady_offer",
        title = "A Proposition",
        category = "crime",
        chance = 0.04,
        cooldown_days = 35,
        condition = function(gs, focal, loc_type)
            return loc_type == "tavern" and gs.underworld and (gs.underworld.global_corruption or 0) > 20
        end,
        text = "A figure slides into the seat across from you. They don't introduce themselves. 'I have work. Pays well. No questions asked.'",
        options = {
            {
                id = "accept",
                label = "How much?",
                description = "Money is money.",
                consequences = {
                    { type = "text", value = "They name a price. It's generous. Too generous. But the pouch they slide across the table is heavy and real. The work will come later. By then, you'll be too deep to refuse." },
                    { type = "gold", delta = 25, reason = "shady work" },
                    { type = "need", need = "comfort", delta = 5 },
                    { type = "need", need = "purpose", delta = -3 },
                    { type = "affinity_train", domain = "crime", amount = 3 },
                },
            },
            {
                id = "refuse",
                label = "Not interested.",
                description = "Some money isn't worth earning.",
                consequences = {
                    { type = "text", value = "They shrug. Stand. 'Your loss.' They disappear into the crowd. You wonder if you'll see them again. You will." },
                },
            },
            {
                id = "probe",
                label = "What kind of work? And for whom?",
                description = "Information before commitment.",
                requires_affinity = { domain = "crime", min = 35 },
                consequences = {
                    { type = "text", value = "They study you. Then: 'Courier work. Packages. No opening, no asking.' A pause. 'The kind of people who hire me don't introduce themselves. But you already knew that.'" },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                },
            },
            {
                id = "turn_tables",
                label = "Counter-offer. I give you information instead.",
                description = "The best criminals are the ones who never get their hands dirty.",
                requires_affinity = { domain = "espionage", min = 50 },
                requires_personality = { PER_OBS = 50 },
                consequences = {
                    { type = "text", value = "Their eyebrows rise. Then a slow smile. 'You're not what I expected.' The conversation shifts. You're not the hired help anymore. You're the other side of the table." },
                    { type = "gold", delta = 10, reason = "information trade" },
                    { type = "affinity_train", domain = "espionage", amount = 4 },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                    { type = "need", need = "purpose", delta = 5 },
                    { type = "need", need = "status", delta = 3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- AN ANIMAL APPROACHES
    --------------------------------------------------------------------------
    {
        id = "stray_animal",
        title = "A Creature in the Rain",
        category = "nature",
        chance = 0.05,
        cooldown_days = 30,
        condition = function(gs, focal, loc_type)
            return loc_type == "wilds" or loc_type == "road" or loc_type == "home"
        end,
        text = "A thin dog watches you from ten paces. Ribs showing. One ear torn. But its eyes are steady. Intelligent. It doesn't beg. It waits.",
        options = {
            {
                id = "adopt",
                label = "Offer your hand.",
                description = "Everyone needs someone.",
                consequences = {
                    { type = "text", value = "It approaches. Sniffs. Decides. From this moment, you are no longer alone. The dog doesn't know your story, your claim, your secrets. It knows your hand. That's enough." },
                    { type = "need", need = "belonging", delta = 10 },
                    { type = "need", need = "comfort", delta = 5 },
                },
            },
            {
                id = "feed_leave",
                label = "Leave food. Keep walking.",
                description = "Attachments are dangerous.",
                consequences = {
                    { type = "text", value = "You set down what you can spare and walk away. You don't look back. You tell yourself that." },
                    { type = "need", need = "belonging", delta = 2 },
                    { type = "gold", delta = -1, reason = "food for stray" },
                },
            },
            {
                id = "notice_collar",
                label = "There's something around its neck. Hidden under the fur.",
                description = "That's not a stray. That's a messenger.",
                requires_affinity = { domain = "nature", min = 40 },
                consequences = {
                    { type = "text", value = "Your fingers find it — a thin leather band with a tiny scroll case. The message inside is coded. But the wax seal... you've seen that seal before." },
                    { type = "item", item_spec = { type = "document", name = "Coded Message", description = "Found on a 'stray' dog. The seal belongs to someone important.",
                        emotional_weight = 0, properties = { discovery = true } } },
                    { type = "affinity_train", domain = "espionage", amount = 3 },
                    { type = "affinity_train", domain = "nature", amount = 2 },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CAREER: Side Job Offer
    --------------------------------------------------------------------------
    {
        id = "side_job",
        title = "Extra Hours",
        category = "career",
        chance = 0.05,
        cooldown_days = 25,
        condition = function(gs, focal, loc_type)
            return gs.career and gs.career.initialized and (loc_type == "market" or loc_type == "tavern")
        end,
        text = "The foreman catches your arm. 'I need someone tonight. Double pay. But the work isn't... official.'",
        options = {
            {
                id = "accept_side",
                label = "Take the work.",
                description = "Money is money. Questions are expensive.",
                consequences = {
                    { type = "text", value = "The work is hard and the hours are dark. But the coin is real. You sleep late the next day, heavier in the purse and the bones." },
                    { type = "gold", delta = 12, reason = "side job" },
                    { type = "need", need = "comfort", delta = -5 },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
            {
                id = "refuse_side",
                label = "Decline. You have enough complications.",
                description = "Keep your hands clean.",
                consequences = {
                    { type = "text", value = "The foreman shrugs. 'Your loss.' He moves on to the next desperate face. There's always a next." },
                },
            },
            {
                id = "ask_what",
                label = "What kind of work, exactly?",
                description = "Details first.",
                requires_affinity = { domain = "crime", min = 30 },
                consequences = {
                    { type = "text", value = "He lowers his voice. 'Moving crates. From the docks. No questions about what's inside.' Smuggling. Small-scale, but real." },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CAREER: Workplace Rumor About Your Identity
    --------------------------------------------------------------------------
    {
        id = "workplace_rumor",
        title = "Whispers at Work",
        category = "career",
        chance = 0.04,
        cooldown_days = 35,
        condition = function(gs, focal, loc_type)
            return gs.career and gs.career.initialized and gs.claim and gs.claim.status ~= "hidden"
        end,
        text = "A colleague pulls you aside during the midday break. 'People are talking about you. About where you came from. About your face.'",
        options = {
            {
                id = "dismiss_rumor",
                label = "Laugh it off. 'People talk about everyone.'",
                description = "Deflect with confidence.",
                consequences = {
                    { type = "text", value = "They relax. Nod. 'You're right. It's nothing.' But they watch you differently for the rest of the day." },
                    { type = "suspicion", delta = 3 },
                },
            },
            {
                id = "investigate_rumor",
                label = "Ask who's been talking. Specifically.",
                description = "Find the source.",
                requires_affinity = { domain = "espionage", min = 35 },
                consequences = {
                    { type = "text", value = "They hesitate. 'The new clerk. The one who came from the capital. He was asking questions about lineages.' Your blood runs cold." },
                    { type = "suspicion", delta = 8 },
                    { type = "affinity_train", domain = "espionage", amount = 3 },
                    { type = "need", need = "safety", delta = -8 },
                },
            },
            {
                id = "threaten_silence",
                label = "Grip their arm. 'I'd appreciate your silence.'",
                description = "Make it clear this conversation never happened.",
                requires_personality = { PER_BLD = 50 },
                consequences = {
                    { type = "text", value = "Fear. Good. They nod quickly. Pull their arm free. The rumors stop — at this workplace, at least." },
                    { type = "suspicion", delta = -2 },
                    { type = "need", need = "belonging", delta = -4 },
                },
                tags = { "hostile" },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CAREER: Promotion Test
    --------------------------------------------------------------------------
    {
        id = "promotion_test",
        title = "A Test of Loyalty",
        category = "career",
        chance = 0.04,
        cooldown_days = 40,
        condition = function(gs, focal, loc_type)
            return gs.career and gs.career.initialized and gs.career.rank >= 30
        end,
        text = "Your superior calls you in. 'There's an opening above you. But I need to know something: where does your loyalty lie?'",
        options = {
            {
                id = "swear_loyalty",
                label = "With this house. Always.",
                description = "Tell them what they want to hear.",
                consequences = {
                    { type = "text", value = "They study your face for a long moment. Then nod. 'Good. Report tomorrow at the better desk.' The lie tastes like copper." },
                    { type = "need", need = "purpose", delta = -3 },
                    { type = "need", need = "status", delta = 5 },
                    { type = "gold", delta = 5, reason = "promotion bonus" },
                },
            },
            {
                id = "deflect_loyalty",
                label = "With the work itself. I do good work.",
                description = "Answer honestly without answering.",
                consequences = {
                    { type = "text", value = "'Hmm.' They're not satisfied, but they can't fault you. 'We'll see.' The promotion doesn't come. Not yet." },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CAREER: Patron's Request
    --------------------------------------------------------------------------
    {
        id = "patron_request",
        title = "A Favor Asked",
        category = "career",
        chance = 0.04,
        cooldown_days = 35,
        condition = function(gs, focal, loc_type)
            return gs.career and gs.career.rank >= 40 and (loc_type == "court" or loc_type == "market")
        end,
        text = "Someone with money and influence leans in. 'I have a task. Discreet. The pay is generous — but I need it done during your contact's meeting.'",
        options = {
            {
                id = "take_patron",
                label = "How generous?",
                description = "The claim can wait one day.",
                consequences = {
                    { type = "text", value = "Very generous. The work is done by evening. Your contact waited. They're not happy. But the gold is warm in your pocket." },
                    { type = "gold", delta = 20, reason = "patron's task" },
                    { type = "need", need = "purpose", delta = -5 },
                    { type = "suspicion", delta = -3 },
                },
            },
            {
                id = "refuse_patron",
                label = "I have prior commitments.",
                description = "Your real work matters more.",
                consequences = {
                    { type = "text", value = "'Pity.' They find someone else within the hour. You wonder if you'll regret it. The meeting goes well. Some things can't be bought." },
                    { type = "need", need = "purpose", delta = 5 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- ECONOMY: Landlord Doubles Rent
    --------------------------------------------------------------------------
    {
        id = "rent_doubled",
        title = "The Landlord's Visit",
        category = "economy",
        chance = 0.04,
        cooldown_days = 60,
        condition = function(gs, focal, loc_type)
            return loc_type == "home" or loc_type == nil
        end,
        text = "Your landlord stands in the doorway, arms crossed. 'Rates are going up. Double, starting next month. The whole street, not just you.' He doesn't look sorry.",
        options = {
            {
                id = "pay_double",
                label = "Pay it. You can't afford to move.",
                description = "Stability costs more than you thought.",
                consequences = {
                    { type = "text", value = "The coins leave your hand. The room stays yours. For now. You eat less this month." },
                    { type = "gold", delta = -10, reason = "rent increase" },
                    { type = "need", need = "comfort", delta = -5 },
                },
            },
            {
                id = "negotiate_rent",
                label = "Negotiate. You've been a good tenant.",
                description = "Words are cheaper than coin.",
                requires_affinity = { domain = "social", min = 30 },
                consequences = {
                    { type = "text", value = "He hesitates. 'Half increase. Final offer.' It's better than nothing. Your tongue earned you five coins this month." },
                    { type = "gold", delta = -5, reason = "negotiated rent" },
                },
            },
            {
                id = "threaten_landlord",
                label = "You know things about his dealings. Remind him.",
                description = "Leverage has many forms.",
                requires_affinity = { domain = "crime", min = 40 },
                consequences = {
                    { type = "text", value = "His face changes. 'Fine. Same rate.' He leaves quickly. You've made an enemy. But a quiet one." },
                    { type = "need", need = "safety", delta = -3 },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                },
                tags = { "hostile" },
            },
        },
    },

    --------------------------------------------------------------------------
    -- ECONOMY: Opportunity to Steal
    --------------------------------------------------------------------------
    {
        id = "theft_chance",
        title = "An Open Purse",
        category = "economy",
        chance = 0.05,
        cooldown_days = 25,
        condition = function(gs, focal, loc_type)
            return loc_type == "market" or loc_type == "tavern"
        end,
        text = "A merchant turns away. Their purse sits on the counter — fat, untended, practically inviting you.",
        options = {
            {
                id = "steal",
                label = "Take it. Fast.",
                description = "Survival doesn't wait for morals.",
                requires_personality = { PER_CRM = 35 },
                consequences = {
                    { type = "text", value = "Your hand moves. The purse vanishes. You walk out with your heart in your throat and coin in your pocket. Nobody saw. You think." },
                    { type = "gold", delta = 15, reason = "stolen purse" },
                    { type = "need", need = "belonging", delta = -5 },
                    { type = "suspicion", delta = 3 },
                },
                tags = { "cruel_act" },
            },
            {
                id = "resist_steal",
                label = "Leave it. That's not who you are.",
                description = "Or is it?",
                consequences = {
                    { type = "text", value = "You walk past. The merchant turns back, picks up the purse, never knowing how close it came. You feel lighter, somehow. And heavier." },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
            {
                id = "warn_merchant",
                label = "Tap the counter. 'Your purse.'",
                description = "Make an ally instead.",
                consequences = {
                    { type = "text", value = "The merchant blinks. Grabs the purse. Stares at you. 'Thank you. I... thank you.' They press a coin into your hand. The honest kind." },
                    { type = "gold", delta = 3, reason = "merchant's gratitude" },
                    { type = "need", need = "belonging", delta = 4 },
                    { type = "relationship", target = "random_nearby", rel_type = "gratitude", delta = 10 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- ECONOMY: A Loan With Strings
    --------------------------------------------------------------------------
    {
        id = "loan_offer",
        title = "A Generous Offer",
        category = "economy",
        chance = 0.04,
        cooldown_days = 45,
        condition = function(gs, focal, loc_type)
            local pw = focal and focal.components and focal.components.personal_wealth
            return pw and pw.gold < 15 and (loc_type == "tavern" or loc_type == "market")
        end,
        text = "A well-dressed stranger appears beside you. 'You look like someone who needs capital. I can help. Small interest. Almost nothing.'",
        options = {
            {
                id = "take_loan",
                label = "How much can you offer?",
                description = "Debt is better than starvation.",
                consequences = {
                    { type = "text", value = "Thirty coins. Just like that. The contract he produces is long and the ink is small. You sign anyway. What choice do you have?" },
                    { type = "gold", delta = 30, reason = "loan" },
                    { type = "need", need = "comfort", delta = 5 },
                    { type = "need", need = "safety", delta = -8 },
                },
            },
            {
                id = "refuse_loan",
                label = "I don't take money from strangers.",
                description = "The price is always more than the interest.",
                consequences = {
                    { type = "text", value = "'Your loss.' He slides away. You watch him approach someone else. Someone more desperate. You wonder how long until that's you." },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
            {
                id = "probe_lender",
                label = "Who sends you? Really.",
                description = "This isn't charity.",
                requires_affinity = { domain = "crime", min = 40 },
                consequences = {
                    { type = "text", value = "His smile slips. 'Does it matter?' It does. You press. Finally: 'The guild. We invest in people. Think of it as... recruitment.' The underworld wants you in their ledger." },
                    { type = "affinity_train", domain = "crime", amount = 3 },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- ECONOMY: Gambling Chance
    --------------------------------------------------------------------------
    {
        id = "gambling",
        title = "A Game of Chance",
        category = "economy",
        chance = 0.05,
        cooldown_days = 20,
        condition = function(gs, focal, loc_type)
            local pw = focal and focal.components and focal.components.personal_wealth
            return loc_type == "tavern" and pw and pw.gold >= 5
        end,
        text = "A circle of players. Dice. Stakes. The kind of game where fortunes change in a single throw.",
        options = {
            {
                id = "gamble_big",
                label = "Sit down. Push ten coins forward.",
                description = "Fortune favors the bold. Sometimes.",
                requires_gold = 10,
                consequences = {
                    { type = "text", value = "The dice roll. The table holds its breath. Luck — or its absence — decides your evening." },
                    { type = "gold", delta = 15, reason = "won gambling" },
                    { type = "need", need = "comfort", delta = 3 },
                },
            },
            {
                id = "gamble_small",
                label = "Watch first. Bet small.",
                description = "Learn the game before playing it.",
                requires_gold = 5,
                consequences = {
                    { type = "text", value = "Small stakes. Small returns. But you learn the patterns. The regulars. Who cheats. Who doesn't." },
                    { type = "gold", delta = 3, reason = "modest gambling" },
                    { type = "affinity_train", domain = "social", amount = 2 },
                },
            },
            {
                id = "watch_gamble",
                label = "Watch. Don't play.",
                description = "Information is free if you know where to sit.",
                consequences = {
                    { type = "text", value = "You watch the money move. You watch the faces. Someone's cheating — badly. Someone else knows and doesn't care. The tavern tells its stories in coin." },
                    { type = "affinity_train", domain = "crime", amount = 2 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CLAIM: Evidence Surfaces
    --------------------------------------------------------------------------
    {
        id = "evidence_surfaces",
        title = "A Witness Comes Forward",
        category = "claim",
        chance = 0.04,
        cooldown_days = 40,
        condition = function(gs, focal, loc_type)
            return gs.claim and gs.claim.type and gs.claim.status ~= "hidden"
        end,
        text = "An old woman approaches you at the edge of the crowd. 'I knew your mother,' she whispers. 'I have a letter.'",
        options = {
            {
                id = "take_letter",
                label = "Take the letter. Read it later.",
                description = "Evidence is currency in your world.",
                consequences = {
                    { type = "text", value = "The paper is old. Yellowed. But the handwriting — and the seal — are unmistakable. This is proof. Real proof. Your hands shake as you fold it away." },
                    { type = "need", need = "purpose", delta = 8 },
                    { type = "need", need = "safety", delta = -3 },
                    { type = "item", item_spec = { type = "document", name = "Mother's Letter", description = "A letter from your mother. Sealed with the house sigil. Proof of blood.",
                        emotional_weight = 8, properties = { discovery = true, evidence = true } } },
                },
            },
            {
                id = "question_witness",
                label = "How did you know her? What do you want?",
                description = "Trust no one. Especially the generous.",
                requires_affinity = { domain = "espionage", min = 35 },
                consequences = {
                    { type = "text", value = "'I was her maid. Before... before everything.' The old woman's eyes fill. 'I want nothing. I've carried this long enough.' She presses the letter into your hands and disappears into the crowd." },
                    { type = "need", need = "purpose", delta = 10 },
                    { type = "affinity_train", domain = "espionage", amount = 2 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CLAIM: Council Member Approachable
    --------------------------------------------------------------------------
    {
        id = "council_approach",
        title = "The Council Demands Proof",
        category = "claim",
        chance = 0.04,
        cooldown_days = 45,
        condition = function(gs, focal, loc_type)
            return gs.claim and (gs.claim.status == "known" or gs.claim.status == "challenged") and loc_type == "court"
        end,
        text = "A council member lingers after the session. They glance at you — quick, nervous. They want to talk. Privately.",
        options = {
            {
                id = "approach_council",
                label = "Approach them. Carefully.",
                description = "Every ally on the council is worth ten on the street.",
                consequences = {
                    { type = "text", value = "'I've looked into your claim,' they whisper. 'I'm not unsympathetic. But I need more than words. Bring me something real.' A crack in the wall. An opening." },
                    { type = "need", need = "purpose", delta = 5 },
                    { type = "need", need = "status", delta = 3 },
                    { type = "affinity_train", domain = "politics", amount = 3 },
                },
            },
            {
                id = "ignore_council",
                label = "Not here. Not now. Too many eyes.",
                description = "The court is never private.",
                consequences = {
                    { type = "text", value = "You walk past. They look disappointed but not surprised. The opportunity fades. Maybe there will be another." },
                    { type = "need", need = "safety", delta = 3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CLAIM: An Ally Wavers
    --------------------------------------------------------------------------
    {
        id = "ally_wavers",
        title = "An Ally Wavers",
        category = "claim",
        chance = 0.05,
        cooldown_days = 30,
        condition = function(gs, focal, loc_type)
            return gs.claim and #(gs.claim.known_by or {}) >= 3 and gs.claim.suspicion > 30
        end,
        text = {
            "One of your supporters finds you. Their face says everything. 'I'm getting pressure. From above. They're asking questions about my... associations.'",
            "A knock at your door. A familiar face — but the expression is wrong. Fear. 'We need to talk about what I've gotten into.'",
        },
        options = {
            {
                id = "reassure_ally",
                label = "Steady them. 'We're close. Don't waver now.'",
                description = "Courage is contagious. So is fear.",
                consequences = {
                    { type = "text", value = "They take a breath. Nod. 'You're right. I'm in this.' The fear doesn't leave their eyes, but the resolve holds. For now." },
                    { type = "need", need = "belonging", delta = 3 },
                    { type = "relationship", target = "random_nearby", rel_type = "trust", delta = 5 },
                },
            },
            {
                id = "release_ally",
                label = "Let them go. 'You've done enough. Be safe.'",
                description = "You won't hold someone with fear.",
                consequences = {
                    { type = "text", value = "Relief. Guilt. They grip your hand. 'I'm sorry.' They leave. One fewer supporter. But one fewer person in danger because of you." },
                    { type = "need", need = "belonging", delta = -5 },
                    { type = "need", need = "purpose", delta = -3 },
                },
            },
            {
                id = "threaten_ally",
                label = "Remind them what you know about them.",
                description = "Nobody leaves. Not now.",
                requires_personality = { PER_CRM = 50 },
                consequences = {
                    { type = "text", value = "Their face hardens. 'I see.' They stay. But the loyalty is gone. What's left is leverage, and leverage rots." },
                    { type = "need", need = "belonging", delta = -8 },
                    { type = "need", need = "safety", delta = 3 },
                    { type = "suspicion", delta = 5 },
                },
                tags = { "cruel_act" },
            },
        },
    },

    --------------------------------------------------------------------------
    -- CLAIM: Usurper's Response (during deliberation)
    --------------------------------------------------------------------------
    {
        id = "usurper_response",
        title = "The Usurper's Response",
        category = "claim",
        chance = 0.06,
        cooldown_days = 30,
        condition = function(gs, focal, loc_type)
            return gs.claim and gs.claim.status == "challenged"
        end,
        text = "A message arrives. Not a letter — a dagger, driven into your door. Wrapped around the blade: 'Withdraw, or the next one finds flesh.'",
        options = {
            {
                id = "stand_firm",
                label = "Leave the dagger where it is. Let them see you don't flinch.",
                description = "Fear is a weapon. Don't let them wield it.",
                consequences = {
                    { type = "text", value = "You leave it there. The whole street sees. By evening, the story has traveled. 'They tried to scare the claimant. It didn't work.' Your stock rises. So does the danger." },
                    { type = "need", need = "status", delta = 5 },
                    { type = "need", need = "safety", delta = -10 },
                    { type = "suspicion", delta = 5 },
                },
            },
            {
                id = "remove_quietly",
                label = "Remove it quietly. Tell no one.",
                description = "Don't give them the satisfaction.",
                consequences = {
                    { type = "text", value = "You pull the dagger free. Good steel. Someone spent real money on this threat. You add it to your collection of reasons to succeed." },
                    { type = "need", need = "safety", delta = -5 },
                    { type = "item", item_spec = { type = "weapon", name = "Threat Dagger", description = "Driven into your door by those who want you dead. Good steel, at least.",
                        emotional_weight = -5, properties = { evidence = true } } },
                },
            },
            {
                id = "investigate_sender",
                label = "Study the blade. The steel. The wrapping. Who made this?",
                description = "Every threat is information.",
                requires_affinity = { domain = "espionage", min = 40 },
                consequences = {
                    { type = "text", value = "The blade is unmarked but the leather wrapping — specific. A tanner in the lower quarter makes bindings like this. For one particular customer." },
                    { type = "affinity_train", domain = "espionage", amount = 4 },
                    { type = "need", need = "purpose", delta = 5 },
                    { type = "need", need = "safety", delta = -3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- RELATIONSHIP: NPC in Trouble
    --------------------------------------------------------------------------
    {
        id = "npc_trouble",
        title = "A Cry for Help",
        category = "social",
        chance = 0.05,
        cooldown_days = 30,
        condition = function(gs, focal, loc_type)
            return loc_type ~= "home"
        end,
        text = "Someone you know staggers toward you. Blood on their sleeve. Fear in their eyes. 'Please. They're coming.'",
        options = {
            {
                id = "hide_them",
                label = "Pull them inside. Hide them.",
                description = "You know what it's like to be hunted.",
                consequences = {
                    { type = "text", value = "You push them behind a stack of crates. Boots pass. Voices. Then silence. When it's safe, they emerge. The look in their eyes — you've earned something money can't buy." },
                    { type = "need", need = "belonging", delta = 8 },
                    { type = "need", need = "safety", delta = -3 },
                    { type = "relationship", target = "random_nearby", rel_type = "gratitude", delta = 20 },
                },
            },
            {
                id = "turn_away_npc",
                label = "Keep walking. Their problems aren't yours.",
                description = "Survival means choices. Hard ones.",
                consequences = {
                    { type = "text", value = "You don't turn. The sounds behind you — you don't listen to those either. By tomorrow, you've almost forgotten. Almost." },
                    { type = "need", need = "belonging", delta = -5 },
                    { type = "need", need = "safety", delta = 3 },
                },
            },
            {
                id = "confront_pursuers",
                label = "Step into the street. Face whoever's chasing them.",
                description = "Sometimes the only way out is through.",
                requires_personality = { PER_BLD = 55 },
                consequences = {
                    { type = "text", value = "Two men. Armed. They see you and hesitate. 'This isn't your business.' 'It is now.' They weigh the odds. Leave. For now. You've made enemies. And one very grateful ally." },
                    { type = "need", need = "belonging", delta = 10 },
                    { type = "need", need = "safety", delta = -8 },
                    { type = "relationship", target = "random_nearby", rel_type = "trust", delta = 15 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- RELATIONSHIP: Old Enemy Returns
    --------------------------------------------------------------------------
    {
        id = "old_enemy",
        title = "A Face from the Past",
        category = "social",
        chance = 0.03,
        cooldown_days = 50,
        condition = function(gs, focal, loc_type)
            return gs.clock and (gs.clock.total_days or 0) > 60
        end,
        text = "You see them across the room. Older. Changed. But unmistakable. Someone who wronged you — or whom you wronged. They've seen you too.",
        options = {
            {
                id = "approach_enemy",
                label = "Walk over. 'It's been a long time.'",
                description = "Face what you've been avoiding.",
                consequences = {
                    { type = "text", value = "The conversation is careful. Measured. Neither of you mentions the thing you're both thinking about. But by the end, something has shifted. Not forgiveness. Not yet. But... recognition." },
                    { type = "need", need = "belonging", delta = 5 },
                    { type = "need", need = "purpose", delta = 3 },
                    { type = "relationship", target = "random_nearby", rel_type = "trust", delta = 8 },
                },
            },
            {
                id = "avoid_enemy",
                label = "Leave. Immediately.",
                description = "Some doors should stay closed.",
                consequences = {
                    { type = "text", value = "You slip out before they can cross the room. But the image stays. They looked different. Tired. Maybe you do too." },
                    { type = "need", need = "safety", delta = 3 },
                    { type = "need", need = "belonging", delta = -3 },
                },
            },
        },
    },

    --------------------------------------------------------------------------
    -- RELATIONSHIP: Romantic Complication
    --------------------------------------------------------------------------
    {
        id = "romantic_complication",
        title = "Something Unspoken",
        category = "social",
        chance = 0.03,
        cooldown_days = 45,
        condition = function(gs, focal, loc_type)
            return loc_type == "tavern" or loc_type == "court" or loc_type == "home"
        end,
        text = "Their hand brushes yours. Not by accident — you both know it. The question hangs between you, unasked.",
        options = {
            {
                id = "lean_in",
                label = "Don't pull away.",
                description = "Some things matter more than plans.",
                consequences = {
                    { type = "text", value = "The moment stretches. Warm. Dangerous. When it ends, something has changed. You have something to lose now. That's either a strength or a weakness." },
                    { type = "need", need = "belonging", delta = 10 },
                    { type = "need", need = "comfort", delta = 5 },
                    { type = "relationship", target = "random_nearby", rel_type = "trust", delta = 12 },
                },
            },
            {
                id = "pull_away",
                label = "Step back. 'I can't. Not now.'",
                description = "Attachments are liabilities for someone with your secrets.",
                consequences = {
                    { type = "text", value = "Hurt flashes across their face. Then understanding. Or maybe resignation. 'When, then?' The question follows you home." },
                    { type = "need", need = "belonging", delta = -5 },
                    { type = "need", need = "purpose", delta = 3 },
                },
            },
        },
    },
}
