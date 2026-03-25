-- dredwork Signals — Signal Chains (Investigation Threads)
-- One signal leads to another. Pull the thread and see where it goes.
-- Verification doesn't just confirm — it opens deeper signals.
-- Some threads lead to betrayal. Some to nothing. Some to things you wish you hadn't found.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local SignalChains = {}

--- Chain definitions: when you verify a signal in domain X,
--- what deeper signal might it reveal?
local CHAIN_LINKS = {
    -- Loyalty concern → espionage trail
    loyalty = {
        {
            trigger_severity = "warning",
            chance = 0.4,
            next_domain = "espionage",
            next_severity = "warning",
            clear_text = "%s has been visiting the tavern after dark. Alone. Regularly.",
            vague_text = "Something about %s's schedule has changed. You can't pin it down.",
            depth = 1,
        },
        {
            trigger_severity = "critical",
            chance = 0.5,
            next_domain = "rivals",
            next_severity = "critical",
            clear_text = "%s was seen meeting with an envoy from a rival house. The conversation was private.",
            vague_text = "You hear %s's name mentioned in connection with outsiders. Could be nothing.",
            depth = 1,
        },
    },

    -- Espionage → crime or conspiracy
    espionage = {
        {
            trigger_severity = "warning",
            chance = 0.35,
            next_domain = "crime",
            next_severity = "warning",
            clear_text = "The meetings aren't political — they're criminal. Money is changing hands in the shadows.",
            vague_text = "Whatever is happening involves coin. Lots of it. But you can't trace where.",
            depth = 2,
        },
        {
            trigger_severity = "warning",
            chance = 0.3,
            next_domain = "secrets",
            next_severity = "critical",
            clear_text = "You find what you were looking for. And it's worse than you imagined.",
            vague_text = "There's something buried here. You're close. But close to what?",
            depth = 2,
        },
    },

    -- Economy → crime (embezzlement trail)
    economy = {
        {
            trigger_severity = "warning",
            chance = 0.3,
            next_domain = "crime",
            next_severity = "warning",
            clear_text = "The numbers don't add up. Someone is skimming. The discrepancy points to the treasury.",
            vague_text = "Something about the ledgers feels off. But you're not sure what you're looking at.",
            depth = 1,
        },
        {
            trigger_severity = "critical",
            chance = 0.4,
            next_domain = "politics",
            next_severity = "warning",
            clear_text = "The scarcity isn't natural. Supplies are being diverted. Someone benefits from this famine.",
            vague_text = "The shortage doesn't match the harvest reports. Something doesn't connect.",
            depth = 1,
        },
    },

    -- Crime → secrets (who's behind it)
    crime = {
        {
            trigger_severity = "warning",
            chance = 0.35,
            next_domain = "secrets",
            next_severity = "warning",
            clear_text = "You trace the corruption to a name. Someone you know. Someone who smiles at you in court.",
            vague_text = "The thread leads to the court. But which face? They all smile the same.",
            depth = 2,
        },
    },

    -- Politics → rivals (who's stirring unrest)
    politics = {
        {
            trigger_severity = "warning",
            chance = 0.3,
            next_domain = "rivals",
            next_severity = "warning",
            clear_text = "The pamphlets are printed on paper that doesn't come from here. Someone outside is funding the discontent.",
            vague_text = "The unrest feels... organized. As if someone is conducting it. But from where?",
            depth = 1,
        },
        {
            trigger_severity = "critical",
            chance = 0.4,
            next_domain = "loyalty",
            next_severity = "critical",
            clear_text = "The unrest isn't just in the streets. Someone in your own court is feeding it.",
            vague_text = "The anger knows too much. Details that only an insider could share.",
            depth = 2,
        },
    },

    -- Rivals → military (they're preparing for war)
    rivals = {
        {
            trigger_severity = "critical",
            chance = 0.5,
            next_domain = "military",
            next_severity = "critical",
            clear_text = "It's not just posturing. They've mobilized. The attack will come within the month.",
            vague_text = "Something is moving beyond the border. Dust, maybe. Or boots.",
            depth = 2,
        },
        {
            trigger_severity = "warning",
            chance = 0.3,
            next_domain = "espionage",
            next_severity = "warning",
            clear_text = "They have a spy in your court. You don't know who, but information is leaking.",
            vague_text = "They seem to know things they shouldn't. Too prepared. Too ready.",
            depth = 2,
        },
    },

    -- Religion → politics (theocratic pressure)
    religion = {
        {
            trigger_severity = "warning",
            chance = 0.3,
            next_domain = "politics",
            next_severity = "warning",
            clear_text = "The priests aren't just preaching — they're organizing. Political demands wrapped in scripture.",
            vague_text = "The sermons have an edge to them. More about the world than the divine.",
            depth = 1,
        },
    },

    -- Nature → peril (predators mean something)
    nature = {
        {
            trigger_severity = "warning",
            chance = 0.35,
            next_domain = "peril",
            next_severity = "warning",
            clear_text = "The wolves are fleeing something. Whatever drove them from the highlands is worse than wolves.",
            vague_text = "Animals behaving strangely. Patterns broken. Something in the ecosystem has shifted.",
            depth = 1,
        },
    },
}

--- When a signal is verified, check if it opens a deeper thread.
---@param verified_signal table the signal that was just verified
---@param focal table the focal entity
---@param day number
---@return table|nil new_signal (or nil if no chain link fires)
function SignalChains.try_chain(verified_signal, focal, day)
    local domain = verified_signal.category
    local severity = verified_signal.severity
    local links = CHAIN_LINKS[domain]
    if not links then return nil end

    for _, link in ipairs(links) do
        if link.trigger_severity == severity and RNG.chance(link.chance) then
            -- Check if focal has affinity for the next domain
            local aff = focal.components.signal_affinity
            local next_aff = aff and aff[link.next_domain] or 30

            local clarity = "vague"
            if next_aff > 50 then clarity = "clear" end

            local format_arg = verified_signal.format_arg

            return {
                type = clarity == "clear" and "observed" or "vague",
                clarity = clarity,
                category = link.next_domain,
                severity = link.next_severity,
                text = clarity == "clear"
                    and (format_arg and string.format(link.clear_text, format_arg) or link.clear_text)
                    or (format_arg and string.format(link.vague_text, format_arg) or link.vague_text),
                depth = link.depth,
                day = day,
                verifiable = clarity == "vague",
                chain_source = verified_signal.category,
            }
        end
    end

    return nil
end

--- Get chain link definitions (for debug/UI).
function SignalChains.get_links()
    return CHAIN_LINKS
end

return SignalChains
