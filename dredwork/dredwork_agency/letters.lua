-- dredwork Agency — Letters & Messages
-- Information that travels WITHOUT you.
-- NPCs send updates, warnings, requests, and scheme progress reports.
-- Letters arrive at locations where you can be reached (home, court, gate).
-- They create the feeling that the world continues when you're not looking.
--
-- "A letter waits for you. The seal is unfamiliar. The handwriting is not."

local RNG = require("dredwork_core.rng")

local Letters = {}

--- Create the letters component for game state.
function Letters.create()
    return {
        inbox = {},         -- { sender_id, sender_name, subject, body, day, read, location, category, actions }
        sent = {},          -- letters you've sent (for tracking)
        max_inbox = 20,
    }
end

--- Send a letter to the player.
---@param gs table game_state
---@param spec table { sender_id, sender_name, subject, body, category, location, day, actions }
function Letters.send(gs, spec)
    gs._letters = gs._letters or Letters.create()

    local letter = {
        id = "letter_" .. (#gs._letters.inbox + 1) .. "_" .. (spec.day or 0),
        sender_id = spec.sender_id,
        sender_name = spec.sender_name or "Unknown",
        subject = spec.subject or "A letter",
        body = spec.body or "",
        category = spec.category or "personal",   -- personal, scheme, warning, request, informant
        location = spec.location or "home",        -- where the letter is delivered
        day = spec.day or 0,
        read = false,
        actions = spec.actions,   -- optional: { { id, label, on_select(gs, engine) } }
        urgent = spec.urgent or false,
    }

    table.insert(gs._letters.inbox, letter)
    while #gs._letters.inbox > gs._letters.max_inbox do
        table.remove(gs._letters.inbox, 1)
    end

    return letter
end

--- Get unread letters at the player's current location.
function Letters.get_unread(gs, location_type)
    if not gs._letters then return {} end
    local unread = {}
    for _, letter in ipairs(gs._letters.inbox) do
        if not letter.read and (letter.location == location_type or letter.location == "any") then
            table.insert(unread, letter)
        end
    end
    return unread
end

--- Get all unread letters count.
function Letters.get_unread_count(gs)
    if not gs._letters then return 0 end
    local count = 0
    for _, letter in ipairs(gs._letters.inbox) do
        if not letter.read then count = count + 1 end
    end
    return count
end

--- Mark a letter as read.
function Letters.mark_read(gs, letter_id)
    if not gs._letters then return end
    for _, letter in ipairs(gs._letters.inbox) do
        if letter.id == letter_id then letter.read = true; return end
    end
end

--- Generate scheme progress letters from NPC co-schemers.
function Letters.generate_scheme_update(gs, npc_name, scheme_label, step_label, status, day)
    local bodies = {
        progress = {
            "The work continues. " .. step_label .. " — it's moving. Slowly, but it's moving. I'll send word when there's more.",
            "Progress on our matter. " .. step_label .. " is underway. No complications yet. I say 'yet' because I'm learning caution from you.",
            "Things are moving. " .. step_label .. ". I've made contact with the right people. Trust the process.",
        },
        success = {
            step_label .. " — done. It wasn't easy, but it's done. Come find me when you can. We should talk about the next step.",
            "Good news. " .. step_label .. " is complete. The pieces are falling into place. Your instinct was right.",
            "It's finished. " .. step_label .. ". I'll tell you the details in person. Some things shouldn't be written down.",
        },
        complication = {
            "A problem. " .. step_label .. " — there's a complication. Someone is asking questions. I need guidance.",
            "We need to talk. " .. step_label .. " hit a wall. I can work around it, but it'll cost more. Or more time. Your call.",
            "Trouble. " .. step_label .. " isn't going as planned. I won't put the details in writing. Find me.",
        },
        betrayal = {
            "I'm sorry. I can't do this anymore. The risk is too great. I've destroyed what I could. Don't come looking for me.",
        },
    }

    local pool = bodies[status] or bodies.progress
    Letters.send(gs, {
        sender_name = npc_name,
        subject = scheme_label .. " — Update",
        body = RNG.pick(pool),
        category = "scheme",
        location = "home",
        day = day,
        urgent = status == "complication" or status == "betrayal",
    })
end

--- Generate informant reports.
function Letters.generate_informant_report(gs, informant_name, content, day)
    Letters.send(gs, {
        sender_name = informant_name,
        subject = "What I've heard",
        body = content,
        category = "informant",
        location = "home",
        day = day,
    })
end

--- Generate a warning from an ally.
function Letters.generate_warning(gs, sender_name, warning_text, day)
    Letters.send(gs, {
        sender_name = sender_name,
        subject = "Urgent",
        body = warning_text,
        category = "warning",
        location = "any",
        day = day,
        urgent = true,
    })
end

--- Generate a request from an NPC.
function Letters.generate_request(gs, sender_name, request_text, day, actions)
    Letters.send(gs, {
        sender_name = sender_name,
        subject = "A Request",
        body = request_text,
        category = "request",
        location = "home",
        day = day,
        actions = actions,
    })
end

return Letters
