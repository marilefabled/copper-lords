-- dredwork Dialogue — Templates
-- Personality-driven dialogue lines. Every axis produces distinct speech patterns.
-- Used by NPCs, court members, rivals, and ambient world characters.

local Templates = {
    --------------------------------------------------------------------------
    -- GREETINGS (by dominant personality axis)
    --------------------------------------------------------------------------
    greetings = {
        default = "Greetings.",

        bold = {
            "State your business quickly. I have blades to sharpen.",
            "You stand before greatness. Speak well.",
            "I've been expecting someone worth my time. Are you that person?",
            "Talk fast. My patience is a short-lived thing.",
            "Another visitor. Let's see if this one has spine.",
        },
        cautious = {
            "You may approach. Slowly.",
            "I've been watching the road. You were expected — but caution serves us all.",
            "Speak freely, but know that every word is weighed here.",
            "Enter. But leave your schemes at the threshold.",
        },
        friendly = {
            "Welcome! The hearth is warm and the company is better.",
            "It is good to see a fresh face in these dark times.",
            "Peace be upon you. How can I assist your journey?",
            "Come, sit. There's food enough and stories to share.",
            "A friend! At least, I choose to believe so. What news?",
        },
        cunning = {
            "I know why you're here. The question is, do you know the price?",
            "Whispers preceded you. They were... interesting.",
            "Softly now. The walls have ears, and I have curiosity.",
            "Every meeting is a transaction. What are you buying?",
            "How delightful. A visitor with secrets they think they're hiding.",
        },
        loyal = {
            "I serve the house. If you are a friend to it, you are a friend to me.",
            "My oath binds me here. What business do you bring?",
            "Speak true. I have no patience for those who would betray trust.",
        },
        volatile = {
            "WHAT?! Oh — it's you. Fine. Fine. What do you want?",
            "Today is not the day to test me. But speak anyway.",
            "I'm in a mood. Choose your words like you're choosing which bones to keep.",
        },
        proud = {
            "You address the heir of a house with a thousand years of history.",
            "I will hear your words, though few have earned the privilege.",
            "Kneel, or at least show proper respect. Then we may speak.",
        },
        curious = {
            "Oh, a visitor! What strange things have you seen on the road?",
            "Tell me everything. Leave nothing out. I must understand.",
            "The world is a puzzle and every person is a piece. What piece are you?",
        },
    },

    --------------------------------------------------------------------------
    -- RUMOR REACTIONS (by rumor tag)
    --------------------------------------------------------------------------
    rumor_reaction = {
        neutral  = "I heard something about %s. Hard to know what's true.",
        shame    = "Disgrace follows %s like a shadow. Everyone is talking about it.",
        praise   = "The name %s is on every tongue for the right reasons.",
        scandal  = "If the whispers about %s are true, the world is shifting beneath us.",
        danger   = "They say %s faces a terrible threat. I pray it passes.",
        fear     = "The people are afraid. The talk of %s has them looking over their shoulders.",
        wealth   = "Gold flows around %s. Whether honestly, who can say?",
        prestige = "Great deeds surround %s. Their name will be remembered.",
        migration = "Strangers arrive from %s. The roads are busy with the displaced.",
    },

    --------------------------------------------------------------------------
    -- WORLD STATE COMMENTARY (by current conditions)
    --------------------------------------------------------------------------
    world_state = {
        famine = {
            "The markets are empty. My children cry for bread.",
            "We're rationing now. Every grain counted. Every meal a negotiation.",
            "They say the harvest failed. We always say that. This time it's true.",
        },
        war = {
            "Soldiers everywhere. They take what they want and call it duty.",
            "My brother marched out last month. No word since.",
            "War is a rich man's game played with poor men's lives.",
        },
        plague = {
            "Don't touch me. Don't touch anything. The sickness is everywhere.",
            "The healers are overwhelmed. We burn the dead now.",
            "I've sealed my doors. May the gods have mercy on those outside.",
        },
        prosperity = {
            "These are good times. Wine flows, the granaries are full, and even I can smile.",
            "Prosperity! I'd forgotten what it tasted like. Sweet, like ripe fruit.",
            "For once, the future looks bright. I almost trust it.",
        },
        unrest = {
            "Something's coming. You can feel it in the air — the anger, the whispers.",
            "The people are done being patient. I've seen this before. It ends in fire.",
            "Be careful who you speak to. Loyalties are... fluid these days.",
        },
        corruption = {
            "Everyone has a price here. Even the magistrate.",
            "Justice? That's a luxury we can't afford. Not with the rot running this deep.",
            "The thieves run the city now. They just wear finer clothes than they used to.",
        },
        peace = {
            "Quiet days. Almost too quiet. Makes you wonder what's coming next.",
            "Nothing to report. The world turns. We endure.",
            "Peace is a garden. It needs tending, or the weeds creep in.",
        },
    },

    --------------------------------------------------------------------------
    -- COURT MEMBER DIALOGUE (by role)
    --------------------------------------------------------------------------
    court = {
        advisor = {
            "The numbers concern me. We must tighten our belts — or find new sources of revenue.",
            "I've studied the situation carefully. My counsel: patience, for now.",
            "There are opportunities here, if we have the courage to seize them.",
        },
        general = {
            "The troops are ready. Give the word and we march.",
            "Our defenses are adequate, but I'd sleep better with another regiment.",
            "War is inevitable. The only question is when, and on whose terms.",
        },
        priest = {
            "The faithful grow restless. They need reassurance — a sign, perhaps.",
            "The old ways are being forgotten. This troubles me deeply.",
            "I counsel temperance. The divine watches, and judges.",
        },
        spouse = {
            "Together we are strong. Apart, we are merely two more names in the ledger.",
            "I worry about the children. This world is no place for innocence.",
            "Stand firm. I will be beside you, whatever comes.",
        },
        sibling = {
            "We share blood, but do we share purpose? I wonder sometimes.",
            "Remember when we were children? Before all of this? I miss those days.",
            "Don't shut me out. Family is the only thing that matters when everything else falls.",
        },
        elder = {
            "I've seen this before. In my father's time. It ended badly then, too.",
            "Listen to an old fool's advice: trust slowly, act decisively, regret nothing.",
            "The young think they invented the world. They didn't. They inherited our mistakes.",
        },
    },

    --------------------------------------------------------------------------
    -- RIVAL DIALOGUE (by attitude)
    --------------------------------------------------------------------------
    rival = {
        hostile = {
            "Your house is a stain on the land. It will be removed.",
            "Every day you breathe is a day I grow stronger. Enjoy what time remains.",
            "We have nothing to discuss. The next time we meet, it will be with steel.",
        },
        wary = {
            "I watch you closely. Know that.",
            "We are not enemies — yet. But the line is thin, and my patience thinner.",
            "A truce, for now. But don't mistake tolerance for trust.",
        },
        neutral = {
            "Your house and mine have no quarrel. Let's keep it that way.",
            "We exist in the same world. That doesn't make us friends or foes.",
            "I know little of your house. Perhaps that's for the best.",
        },
        respectful = {
            "Your house has earned its place. I acknowledge that.",
            "There is much we could accomplish together. If trust can be built.",
            "I respect strength. Your house has shown it.",
        },
        devoted = {
            "Your cause is my cause. I stand with you.",
            "The bond between our houses is sacred. I will not see it broken.",
            "Command me. Your house has earned my loyalty through deeds, not words.",
        },
    },

    --------------------------------------------------------------------------
    -- MEMORY-DRIVEN LINES (shared history)
    --------------------------------------------------------------------------
    memory_gratitude = {
        "You helped me once. I haven't forgotten.",
        "I owe you. That's not something I say lightly.",
        "There was a time you could have walked away. You didn't. I remember.",
        "The debt between us — it's real. I carry it.",
        "You showed me kindness when no one else would. That changes things.",
        "I remember what you did for me. The world forgets. I don't.",
    },

    memory_grudge = {
        "I remember what you did. Don't think I've forgotten.",
        "We have unfinished business. You know what I mean.",
        "Every time I see your face, I remember. Every time.",
        "You wronged me. The world may not care, but I do.",
        "I've been patient. Don't mistake that for forgiveness.",
        "Some wounds don't heal. You gave me one.",
    },

    memory_witnessed = {
        "I was there, you know. I saw what happened.",
        "That thing that happened between us — it changed something.",
        "We've been through something together. That means something.",
        "I remember the last time we spoke. Do you?",
    },

    --------------------------------------------------------------------------
    -- CONTEXT-AWARE LINES (current state of the focal entity)
    --------------------------------------------------------------------------
    context_wealth_sympathy = {
        "You look thin. Are you eating?",
        "I can see it in your eyes. The hunger. Let me help.",
        "No one should have to live like this. Not here.",
        "The streets are hard. I know. I've been there.",
    },

    context_claim_aware = {
        "Your secret — I've kept it. But I need something in return.",
        "I know what you are. What you really are. Be careful.",
        "The things I know about you... they keep me up at night.",
        "I've said nothing. But others are asking questions.",
    },

    context_reputation = {
        "I know what people call you. %s. Is it true?",
        "They say you're %s. I wanted to see for myself.",
        "Your reputation precedes you. %s, they whisper.",
        "People speak your name with a certain... tone. %s, they say.",
        "I've heard the stories. %s. Are you proud of that?",
        "%s. That's what they call you now. Does it fit?",
    },
}

return Templates
