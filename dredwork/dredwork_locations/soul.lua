-- dredwork Locations — Soul
-- What each location IS. Not just tags and interactions —
-- what modules are active here, what narrator speaks, what you can perceive,
-- what kind of world you're standing in.
--
-- The tavern is the crime/social/rumor world.
-- The temple is the religion/culture world.
-- The court is the politics/loyalty world.
-- Same simulation. Different lens. Different game.

local Soul = {}

--- Complete location definition: the simulation slice visible from this place.
Soul.DEFINITIONS = {
    home = {
        -- What you can perceive here
        signal_domains = { "domestic", "self", "social" },
        -- What narrator voice speaks here
        narrator = "whispers",
        -- What modules are "loud" here (drive encounters and signals)
        active_modules = { "home", "bonds", "mortality", "animals" },
        -- What kind of encounters generate
        encounter_flavor = "domestic",
        -- What inquiries work here
        inquiry_types = { "consult_ally", "read_the_room" },
        -- The feeling
        atmosphere = "private",
        -- What you notice that you wouldn't elsewhere
        unique_signals = {
            { condition = function(gs) return gs.home and gs.home.attributes and (gs.home.attributes.condition or 50) < 30 end,
              text_clear = "The walls are speaking. Cracks you can fit fingers into. This place is dying.",
              text_vague = "Something creaks overhead. Probably nothing.",
              domain = "domestic" },
            { condition = function(gs) return gs.animals and gs.animals.pets and #gs.animals.pets > 0 end,
              text_clear = function(gs) local pet = gs.animals.pets[1]; return (pet.name or "Your companion") .. " is curled by the fire. Breathing steady. Present." end,
              text_vague = "The sound of something alive, nearby. Comforting.",
              domain = "nature" },
        },
    },

    court = {
        signal_domains = { "politics", "loyalty", "social", "rivals" },
        narrator = "chronicle",
        active_modules = { "politics", "court", "rivals", "heritage", "decisions" },
        encounter_flavor = "political",
        inquiry_types = { "inquire_politics", "ask_about_person", "inquire_rivals", "read_the_room", "consult_ally" },
        atmosphere = "formal",
        unique_signals = {
            { condition = function(gs) return gs.politics and (gs.politics.legitimacy or 50) < 30 end,
              text_clear = "The throne is surrounded by empty space. People keep their distance. They can smell weakness.",
              text_vague = "The room feels different today. Fewer people near the center.",
              domain = "politics" },
            { condition = function(gs) return gs.politics and (gs.politics.unrest or 0) > 50 end,
              text_clear = "The guards are doubled. That tells you everything the court speeches don't.",
              text_vague = "More guards than usual. Or maybe you're just noticing them more.",
              domain = "politics" },
        },
    },

    market = {
        signal_domains = { "economy", "social", "crime" },
        narrator = "streets",
        active_modules = { "economy", "rumor", "strife", "animals" },
        encounter_flavor = "trade",
        inquiry_types = { "listen_rumors", "inquire_economy", "ask_about_person", "read_the_room" },
        atmosphere = "crowded",
        unique_signals = {
            { condition = function(gs)
                if not gs.markets then return false end
                for _, m in pairs(gs.markets) do
                    if m.prices and m.prices.food and m.prices.food > 12 then return true end
                end; return false
              end,
              text_clear = "The bread vendor has raised the rope barrier. Only those who can pay get close. The others watch.",
              text_vague = "The crowd is thinner than usual. Something about the way people hold their coins.",
              domain = "economy" },
        },
    },

    tavern = {
        signal_domains = { "crime", "social", "espionage", "rumors" },
        narrator = "streets",
        active_modules = { "crime", "rumor", "dialogue", "strife" },
        encounter_flavor = "underworld",
        inquiry_types = { "listen_rumors", "ask_about_person", "inquire_politics", "inquire_rivals", "read_the_room" },
        atmosphere = "dark_social",
        unique_signals = {
            { condition = function(gs) return gs.underworld and (gs.underworld.global_corruption or 0) > 40 end,
              text_clear = "The corner tables are full tonight. Business is good — the wrong kind of business.",
              text_vague = "Something about this place. The way conversations die when you look too long.",
              domain = "crime" },
            { condition = function(gs) return gs.claim and gs.claim.suspicion > 30 end,
              text_clear = "A man near the door is watching you. Not drinking. Not talking. Just watching.",
              text_vague = "You feel eyes. Can't place whose.",
              domain = "espionage" },
        },
    },

    barracks = {
        signal_domains = { "military", "politics", "peril" },
        narrator = "chronicle",
        active_modules = { "military", "conquest", "duel", "technology" },
        encounter_flavor = "military",
        inquiry_types = { "read_the_room", "consult_ally" },
        atmosphere = "disciplined",
        unique_signals = {
            { condition = function(gs) return gs.military and (gs.military.total_power or 0) < 50 end,
              text_clear = "The racks are half empty. Not enough soldiers. Not enough steel. If the enemy came now...",
              text_vague = "Quieter than a barracks should be.",
              domain = "military" },
            { condition = function(gs)
                if not gs.military or not gs.military.units then return false end
                for _, u in ipairs(gs.military.units) do if (u.morale or 50) > 80 then return true end end
                return false
              end,
              text_clear = "These soldiers have fire. You can see it in the way they drill. Ready. Hungry.",
              text_vague = "Energy here. Focused. Sharp.",
              domain = "military" },
        },
    },

    temple = {
        signal_domains = { "religion", "social", "self" },
        narrator = "divine",
        active_modules = { "religion", "culture", "heritage" },
        encounter_flavor = "spiritual",
        inquiry_types = { "read_the_room", "consult_ally", "ask_about_person" },
        atmosphere = "sacred",
        unique_signals = {
            { condition = function(gs) return gs.religion and gs.religion.active_faith and gs.religion.active_faith.attributes and (gs.religion.active_faith.attributes.zeal or 50) > 70 end,
              text_clear = "The faithful are fervent today. Eyes closed. Hands clasped. The kind of belief that moves mountains — or burns heretics.",
              text_vague = "More prayers than usual. Louder. Something has stirred them.",
              domain = "religion" },
            { condition = function(gs) return gs.religion and (gs.religion.diversity or 10) > 40 end,
              text_clear = "You notice different symbols on different necks. This temple serves more than one truth. The tension is invisible but present.",
              text_vague = "Not everyone here seems to be praying to the same thing.",
              domain = "religion" },
        },
    },

    gate = {
        signal_domains = { "military", "peril", "rivals" },
        narrator = "chronicle",
        active_modules = { "geography", "military", "conquest", "strife" },
        encounter_flavor = "border",
        inquiry_types = { "inquire_rivals", "read_the_room" },
        atmosphere = "exposed",
        unique_signals = {
            { condition = function(gs) return gs.empire and gs.empire.territories and #gs.empire.territories > 0 end,
              text_clear = "Supply wagons heading out. The empire's reach costs more every day.",
              text_vague = "More traffic at the gate than usual. Official-looking.",
              domain = "military" },
        },
    },

    wilds = {
        signal_domains = { "nature", "peril", "self" },
        narrator = "nature",
        active_modules = { "animals", "peril", "geography", "strife" },
        encounter_flavor = "wilderness",
        inquiry_types = { "read_the_room" },
        atmosphere = "primal",
        unique_signals = {
            { condition = function(gs)
                if not gs.animals or not gs.animals.regional_populations then return false end
                for _, pops in pairs(gs.animals.regional_populations) do
                    for _, pop in pairs(pops) do
                        if (pop.density or 0) > 50 then return true end
                    end
                end; return false
              end,
              text_clear = "The wildlife is dense here. Tracks everywhere. The ecosystem is thriving — or something is driving them toward you.",
              text_vague = "Sounds in the undergrowth. More than usual. Life is thick here.",
              domain = "nature" },
        },
    },

    dungeon = {
        signal_domains = { "crime", "espionage", "self" },
        narrator = "whispers",
        active_modules = { "punishment", "crime", "secrets" },
        encounter_flavor = "prison",
        inquiry_types = { "read_the_room" },
        atmosphere = "oppressive",
        unique_signals = {
            { condition = function(gs) return gs.justice and #(gs.justice.prisoners or {}) > 3 end,
              text_clear = "The cells are full. The sounds that come from below the floor are the sounds of people who've given up.",
              text_vague = "Sounds. Below. You don't want to know.",
              domain = "crime" },
        },
    },

    road = {
        signal_domains = { "peril", "social", "nature" },
        narrator = "streets",
        active_modules = { "geography", "strife", "peril" },
        encounter_flavor = "travel",
        inquiry_types = { "read_the_room" },
        atmosphere = "transient",
        unique_signals = {},
    },
}

--- Get the soul definition for a location type.
function Soul.get(location_type)
    return Soul.DEFINITIONS[location_type]
end

--- Get which signal domains are visible at this location.
function Soul.get_visible_domains(location_type)
    local def = Soul.DEFINITIONS[location_type]
    return def and def.signal_domains or {}
end

--- Get which narrator voice speaks at this location.
function Soul.get_narrator(location_type)
    local def = Soul.DEFINITIONS[location_type]
    return def and def.narrator or "whispers"
end

--- Get unique signals for this location based on world state.
---@param location_type string
---@param gs table game_state
---@param clarity string "clear" or "vague"
---@return table|nil { text, domain }
function Soul.get_unique_signal(location_type, gs, clarity)
    local def = Soul.DEFINITIONS[location_type]
    if not def or not def.unique_signals then return nil end

    for _, sig in ipairs(def.unique_signals) do
        if sig.condition(gs) then
            local text
            if clarity == "clear" then
                text = type(sig.text_clear) == "function" and sig.text_clear(gs) or sig.text_clear
            else
                text = sig.text_vague
            end
            return { text = text, domain = sig.domain }
        end
    end

    return nil
end

--- Get the atmosphere label for a location.
function Soul.get_atmosphere(location_type)
    local def = Soul.DEFINITIONS[location_type]
    return def and def.atmosphere or "neutral"
end

return Soul
