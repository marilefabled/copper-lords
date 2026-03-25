-- Dark Legacy — Near-Miss Narrative Data
-- Dramatic text for when heirs/offspring narrowly survive death.
-- Pure data, no logic.

return {
    -- Offspring near-miss lines (for surviving children with high death chance)
    offspring_near_miss = {
        plague_close = {
            "Born sickly during the plague, but alive.",
            "The plague touched this one, but could not claim them.",
            "Fever-born. The healers did not expect survival.",
        },
        famine_close = {
            "Born thin and hungry, but breathing.",
            "The smallest of the litter — but alive.",
            "Starvation nearly claimed this one before they drew breath.",
        },
        war_close = {
            "Born amid the chaos of war, but spared.",
            "The violence came close. This one survived by chance.",
        },
        frailty_close = {
            "Born fragile, barely clinging to life.",
            "The weakest child — but they held on.",
            "A difficult birth. The bloodline nearly lost another.",
        },
        general = {
            "This one barely survived.",
            "Against all odds, alive.",
            "The family almost lost this child.",
        },
    },

    -- Heir near-miss lines (for heir surviving death check)
    heir_near_miss = {
        plague_close = {
            "Your heir narrowly survived the plague this generation.",
            "The sickness came for your heir. They endured — barely.",
        },
        war_close = {
            "Your heir nearly fell in battle this generation.",
            "War almost claimed your heir. They returned scarred but alive.",
        },
        famine_close = {
            "Starvation nearly took your heir this generation.",
            "Your heir wasted away but clung to life.",
        },
        frailty_close = {
            "Your heir's body nearly failed them this generation.",
            "The frailty of the bloodline almost ended here.",
        },
        madness_close = {
            "Your heir teetered on the edge of madness.",
            "Something dark stirred in your heir's mind this generation.",
        },
        general = {
            "Your heir narrowly escaped death this generation.",
            "Death came close. Your heir survived — this time.",
        },
    },
}
