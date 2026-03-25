-- dredwork Signals — Clarity Variants
-- Every signal has a clear, vague, and missed form.
-- Clear: you understand what it means.
-- Vague: you notice something but can't place it.
-- Missed: you never see it. That's the point.

local Clarity = {}

--- Signal text pools by category × severity × clarity.
--- Missing entries fall back to generic vague/clear text.
local VARIANTS = {
    economy = {
        critical = {
            clear = {
                "The market stalls are bare. A woman clutches an empty basket, staring at nothing. Famine is here.",
                "Food prices have doubled since last month. You can count the remaining sacks of grain. It won't last.",
            },
            vague = {
                "Something's off at the market. Fewer people. Quieter than it should be.",
                "You notice a vendor packing up early. The stalls seem thinner today. Maybe it's nothing.",
            },
        },
        warning = {
            clear = {
                "Fewer vendors today. Prices scratched and re-scratched on the boards. Rising steadily.",
                "The baker's loaves are smaller than last week. Same price. He hopes you won't notice.",
            },
            vague = {
                "The market feels different today. Can't quite say how.",
                "You buy bread. Was it always this expensive? You can't remember.",
            },
        },
        positive = {
            clear = {
                "The market overflows. Laughter between vendors. The smell of ripe fruit carries on the wind.",
            },
            vague = {
                "The market feels lively today. Good energy. You're not sure why.",
            },
        },
    },
    politics = {
        critical = {
            clear = {
                "Angry voices carry through the walls. Groups gather at corners and go silent when guards pass. This is the sound before breaking.",
                "A crowd blocks the main thoroughfare. Their demands are written on signs. Their faces are written with rage.",
            },
            vague = {
                "Something in the air tonight. A tension you can't name. People move differently.",
                "The streets feel wrong. You can't explain it. Just... wrong.",
            },
        },
        warning = {
            clear = {
                "A pamphlet on the ground, trampled but readable. Complaints. Demands. Names you recognize.",
                "Fewer people bow as you pass. Some look through you. One meets your gaze — holds it too long.",
            },
            vague = {
                "You find a crumpled paper. The writing is too smudged to read, but someone felt strongly enough to write it.",
                "Was that person staring at you? Probably not. Probably.",
            },
        },
        positive = {
            clear = {
                "People step aside as you pass. Heads dip. A child points and whispers to their mother, who smiles and nods.",
            },
            vague = {
                "People seem... warmer today. More nods. More space made for you. It feels good.",
            },
        },
    },
    military = {
        warning = {
            clear = {
                "The walls feel empty. Fewer patrols. The guardhouse door hangs open, unmanned. If enemies came now...",
                "Soldiers sit idle. Their eyes are dull. One sharpens a blade absently, but the edge is already gone.",
            },
            vague = {
                "The guards seem distracted today. Or is it just you?",
                "You pass the barracks. Quieter than usual. You think.",
            },
        },
    },
    crime = {
        warning = {
            clear = {
                "The magistrate's new robes are finer than his salary explains. The dock workers avert their eyes when you pass.",
                "Someone has been carving marks into the tavern wall. A code you recognize. The underworld is busy.",
            },
            vague = {
                "Something about the magistrate's smile doesn't sit right. Too comfortable.",
                "Marks on the wall. Scratches? Deliberate? You can't tell.",
            },
        },
    },
    religion = {
        warning = {
            clear = {
                "The faithful preach louder each day. Their eyes burn with certainty. It's compelling — or frightening, depending on where you stand.",
                "Someone has painted a symbol on a door. A warning. The family that lived there is gone.",
            },
            vague = {
                "The temple seems busier lately. More chanting. Louder.",
                "A strange mark on a door. Paint? Blood? You walk past.",
            },
        },
    },
    loyalty = {
        critical = {
            clear = {
                "%s won't meet your eyes. Their smile is a mask. Something behind it is calculating. They're already somewhere else in their mind.",
            },
            vague = {
                "%s seems distracted. Distant. Probably just tired.",
            },
        },
        warning = {
            clear = {
                "%s responds when spoken to but volunteers nothing. The warmth is gone. Whatever changed, it changed quietly.",
            },
            vague = {
                "Was %s always this quiet? You try to remember. You can't.",
            },
        },
        positive = {
            clear = {
                "%s stands a little closer than they need to. Watchful. Ready. Yours.",
            },
            vague = {
                "%s seems comfortable around you. That's good. You think.",
            },
        },
    },
    rivals = {
        critical = {
            clear = {
                "Travelers from %s speak of armories working through the night. Steel being shaped. Preparations for something that hasn't been announced.",
            },
            vague = {
                "A traveler mentions %s but changes the subject when pressed. Interesting.",
            },
        },
        warning = {
            clear = {
                "The envoy from %s was curt. Their words were polite. Their tone was a blade wrapped in silk.",
            },
            vague = {
                "The envoy from %s left quickly. Was that normal? You're not sure.",
            },
        },
        positive = {
            clear = {
                "A gift arrives from %s. Unprompted. Well-chosen. The gesture speaks volumes about their intentions.",
            },
            vague = {
                "Something arrived from %s. A package. Unopened. Probably fine.",
            },
        },
    },
    peril = {
        critical = {
            clear = {
                "The air tastes wrong. Sweet and heavy. You hold your breath passing the lower quarters. You've smelled this before. Plague.",
            },
            vague = {
                "Something in the air. A sweetness that doesn't belong. You walk faster.",
            },
        },
        warning = {
            clear = {
                "Smoke on the horizon. Too much for a cooking fire. Too little for a war. Something is burning that shouldn't be.",
            },
            vague = {
                "Is that smoke? Or clouds? Hard to tell from here.",
            },
        },
    },
    nature = {
        warning = {
            clear = {
                "The wolves are closer to the walls this season. Something has driven them from the high ground. Prey is scarce — or a predator is pushing them.",
            },
            vague = {
                "Howling at night. Closer than before. Or your imagination. Either way, you don't sleep well.",
            },
        },
        positive = {
            clear = {
                "Birdsong this morning. Richer than usual. The forest is healthy. That means the land is healthy.",
            },
            vague = {
                "Nice morning. Birds. Sun. The kind of day that makes you forget the rest.",
            },
        },
    },
    self = {
        critical = {
            clear = {
                "Your hands won't stop trembling. You grip them together under the table where no one can see. This is fear.",
            },
            vague = {
                "You feel off today. Can't settle. Can't focus. Something underneath, like a low hum.",
            },
        },
        warning = {
            clear = {
                "The hall is full of people. You are surrounded. You have never felt more alone. You know exactly why.",
            },
            vague = {
                "Restless. That's the word. You can't sit still. Don't know what you're looking for.",
            },
        },
    },
    secrets = {
        warning = {
            clear = {
                "%s laughs at something someone said. But you notice their hand tighten on the cup. You know what they're hiding. The question is when.",
            },
            vague = {
                "Something about %s today. A flicker in their expression. Gone before you could read it.",
            },
        },
    },
}

--- Get a clarity-appropriate text for a signal.
---@param category string signal category
---@param severity string "critical", "warning", "positive"
---@param clarity string "clear" or "vague"
---@param format_arg string|nil optional name/label for %s substitution
---@return string text
function Clarity.get_text(category, severity, clarity, format_arg)
    local cat_pool = VARIANTS[category]
    if not cat_pool then
        if clarity == "vague" then return "Something catches your attention. You can't place it." end
        return "You notice something."
    end

    local sev_pool = cat_pool[severity]
    if not sev_pool then
        sev_pool = cat_pool.warning or {}
    end

    local clarity_pool = sev_pool[clarity]
    if not clarity_pool or #clarity_pool == 0 then
        if clarity == "vague" then
            return "Something feels different. You can't quite say what."
        end
        return "You notice a change."
    end

    local text = clarity_pool[math.random(#clarity_pool)]

    -- Substitute %s with format_arg if present
    if format_arg and text:find("%%s") then
        text = string.format(text, format_arg)
    end

    return text
end

return Clarity
