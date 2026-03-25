-- Dark Legacy — Marriage Narrative Text Pools
-- Narrative text for each marriage type, used in matchmaking and offspring scenes.

local marriage_narratives = {
    forced = {
        intro = {
            "The alliance was demanded, not requested.",
            "Politics drew the bloodlines together by force.",
            "Neither family smiled at the pact. Both families needed it.",
            "A union born of necessity, not affection.",
        },
        transition_quote = {
            "The alliance was sealed in silence.",
            "What the blood demands, the blood receives.",
            "Some bonds are forged in desperation.",
            "The pact was signed. The heir obeyed.",
        },
        offspring_header = {
            "From a desperate alliance, the next generation stirs.",
            "Children of obligation, born under a cold star.",
            "The fruits of political necessity draw their first breath.",
        },
    },
    love = {
        intro = {
            "The heir's heart chose before the mind could intervene.",
            "A match made not by strategy, but by something deeper.",
            "Love took root where duty could not reach.",
            "The blood speaks in ways the ancestor cannot control.",
        },
        transition_quote = {
            "Your heir chose with the heart, not the blood.",
            "Some things even the ancestor cannot command.",
            "Love is the one force that defies the weight of legacy.",
            "The heart wants what the bloodline cannot predict.",
        },
        offspring_header = {
            "Born of genuine affection — a rare gift in this lineage.",
            "Children of love, untouched by the ancestor's cold calculus.",
            "From a union freely chosen, new life emerges.",
        },
    },
    arranged = {
        intro = {
            "The families agreed. The heirs complied.",
            "An arranged union — strategic, measured, and without surprises.",
            "Both houses saw the advantage. The match was made.",
            "A proper alliance, sealed in the old tradition.",
        },
        transition_quote = {
            "The arrangement proceeds as planned.",
            "Duty and strategy align in this generation.",
            "The old ways still hold. Alliances are forged in blood.",
            "What the houses agreed upon, the heirs accepted.",
        },
        offspring_header = {
            "The arrangement bears fruit. New blood enters the line.",
            "Children of alliance, carrying the weight of two houses.",
            "As planned, the next generation arrives.",
        },
    },
    forbidden = {
        intro = {
            "This union defies ancestral law. The blood rebels.",
            "A match the ancestors would have condemned.",
            "Against every instinct the lineage has accumulated — this one.",
            "The weight of generations presses against this choice.",
        },
        transition_quote = {
            "Defiance has a cost. The bloodline will remember.",
            "Against the blood, against the weight — but forward.",
            "Some walls are meant to be broken. Others, not.",
            "The ancestors stir in their graves.",
        },
        offspring_header = {
            "Born against the ancestors' wishes — what legacy will they carry?",
            "Children of defiance, marked by the weight of broken taboos.",
            "From a forbidden union, uncertain blood flows forth.",
        },
    },
    free = {
        intro = {
            "In this generation, the heir chose freely.",
            "No pacts. No politics. A clean choice.",
            "The bloodline stands unencumbered. Choose wisely.",
            "Freedom is rare in a lineage this old. Use it well.",
        },
        transition_quote = {
            "A free choice — the rarest luxury of legacy.",
            "Without constraint, the blood flows where it will.",
            "The heir chose. The ancestor watched.",
            "In freedom, the truest choices are made.",
        },
        offspring_header = {
            "From a freely chosen union, the next generation emerges.",
            "Children of choice, unbound by obligation.",
            "The blood flows freely into the next generation.",
        },
    },
}

return marriage_narratives
