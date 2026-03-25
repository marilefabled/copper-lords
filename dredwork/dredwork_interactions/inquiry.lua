-- dredwork Interactions — Inquiry System
-- The player actively seeks information rather than waiting for signals.
-- What you can ask about depends on what you know (affinity, relationships, location).
-- What you LEARN depends on who you ask and what THEY know.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")
local Affinity = require("dredwork_signals.affinity")

local Inquiry = {}

--- Inquiry types available.
local INQUIRY_TYPES = {
    {
        id = "listen_rumors",
        label = "Listen for rumors",
        description = "Sit. Watch. Let the world talk.",
        location_types = { "tavern", "market", "court" },
        affinity_domain = "social",
        min_affinity = 0,  -- always available but better with higher social
        execute = function(focal, gs, engine)
            local results = {}
            if not gs.rumor_network or not gs.rumor_network.rumors then
                return { text = "Nothing. The silence itself might be suspicious." }
            end

            local aff = focal.components.signal_affinity or {}
            local social = aff.social or 30
            local heard = {}

            for _, r in pairs(gs.rumor_network.rumors) do
                if r.dead then goto skip end
                -- Higher social affinity = hear more rumors
                if RNG.chance(social / 150) and (r.heat or 0) > 20 then
                    table.insert(heard, r)
                end
                ::skip::
            end

            if #heard == 0 then
                return { text = "You listen. People talk about weather, prices, nothing. Either the world is quiet, or you're not hearing the right conversations." }
            end

            -- Sort by heat, return top 2-3
            table.sort(heard, function(a, b) return (a.heat or 0) > (b.heat or 0) end)
            local lines = { "You lean in. You listen. The room speaks:" }
            for i = 1, math.min(3, #heard) do
                table.insert(lines, "\"" .. (heard[i].text or "...") .. "\"")
            end

            -- Train social affinity
            Affinity.train(focal.components.signal_affinity, "social", 2)

            return { text = table.concat(lines, "\n"), rumors_heard = #heard }
        end,
    },
    {
        id = "ask_about_person",
        label = "Ask about someone",
        description = "What do people say about them?",
        location_types = { "tavern", "market", "court", "temple" },
        affinity_domain = "social",
        min_affinity = 25,
        needs_target = "person",
        execute = function(focal, gs, engine, target)
            if not target then return { text = "Ask about who?" } end

            local aff = focal.components.signal_affinity or {}
            local social = aff.social or 30

            -- Check rumors about this person
            local about_them = {}
            if gs.rumor_network and gs.rumor_network.rumors then
                for _, r in pairs(gs.rumor_network.rumors) do
                    if not r.dead and r.subject == target.name then
                        table.insert(about_them, r)
                    end
                end
            end

            -- Check their reputation through relationships
            local entities = engine:get_module("entities")
            local their_rels = entities and entities:get_relationships(target.id) or {}
            local loyalty_sum = 0
            local rel_count = 0
            for _, rel in ipairs(their_rels) do
                loyalty_sum = loyalty_sum + (rel.strength or 50)
                rel_count = rel_count + 1
            end
            local avg_loyalty = rel_count > 0 and (loyalty_sum / rel_count) or 50

            local lines = {}
            if #about_them > 0 and social > 30 then
                local r = about_them[1]
                table.insert(lines, "People say: \"" .. (r.text or "...") .. "\"")
            else
                table.insert(lines, "Nobody has much to say about " .. target.name .. ". That could mean anything.")
            end

            -- Social affinity determines depth
            if social > 50 then
                if avg_loyalty > 70 then
                    table.insert(lines, "From what you gather, " .. target.name .. " is well-regarded. People speak fondly.")
                elseif avg_loyalty < 30 then
                    table.insert(lines, "The name " .. target.name .. " makes people uncomfortable. Conversations shift when they're mentioned.")
                end
            end

            Affinity.train(focal.components.signal_affinity, "social", 1)

            return { text = table.concat(lines, " ") }
        end,
    },
    {
        id = "inquire_politics",
        label = "Ask about the political situation",
        description = "Who's in charge? How stable are things?",
        location_types = { "court", "tavern" },
        affinity_domain = "politics",
        min_affinity = 30,
        execute = function(focal, gs, engine)
            local aff = focal.components.signal_affinity or {}
            local pol = aff.politics or 30
            local lines = {}

            if pol < 40 then
                table.insert(lines, "You ask around. The answers are vague. You don't know the right questions yet.")
                Affinity.train(focal.components.signal_affinity, "politics", 2)
                return { text = table.concat(lines, " ") }
            end

            if gs.politics then
                local legit = gs.politics.legitimacy or 50
                local unrest = gs.politics.unrest or 0

                if legit > 70 then table.insert(lines, "The ruling house is strong. People speak of them with respect — or fear. Hard to tell the difference.")
                elseif legit > 40 then table.insert(lines, "The rulers hold, but the grip is loosening. You can hear it in the way people choose their words.")
                else table.insert(lines, "The ruling house is weak. Everyone knows it. The question is who moves first.") end

                if unrest > 60 then table.insert(lines, "The people are angry. You can feel it in the air. Something is coming.")
                elseif unrest > 30 then table.insert(lines, "There's tension. Pamphlets. Meetings. Nothing open yet, but the undercurrent is there.") end
            end

            if pol > 60 then
                table.insert(lines, "You read between the lines. The real power isn't on the throne — it's in the people who stand behind it.")
            end

            Affinity.train(focal.components.signal_affinity, "politics", 2)
            return { text = table.concat(lines, " ") }
        end,
    },
    {
        id = "inquire_economy",
        label = "Ask about trade and prices",
        description = "How's the economy? Who's making money?",
        location_types = { "market", "tavern" },
        affinity_domain = "economy",
        min_affinity = 25,
        execute = function(focal, gs, engine)
            local aff = focal.components.signal_affinity or {}
            local econ = aff.economy or 30
            local lines = {}

            if gs.markets then
                local any_bad = false
                for rid, market in pairs(gs.markets) do
                    local food = market.prices and market.prices.food or 5
                    if econ > 40 then
                        if food > 15 then
                            table.insert(lines, "Food prices in " .. rid .. " are dangerous. People are going hungry.")
                            any_bad = true
                        elseif food < 4 then
                            table.insert(lines, "The markets in " .. rid .. " are flush. Good harvests. Good times.")
                        end
                    end
                end
                if not any_bad and econ < 40 then
                    table.insert(lines, "You ask about prices. The vendor shrugs. 'Same as always.' You don't know if that's good or bad.")
                end
            end

            Affinity.train(focal.components.signal_affinity, "economy", 2)
            return { text = #lines > 0 and table.concat(lines, " ") or "The economy is... what it is. You don't know enough to read it yet." }
        end,
    },
    {
        id = "inquire_rivals",
        label = "Ask about the other houses",
        description = "Who else has power? What are they doing?",
        location_types = { "tavern", "court", "gate" },
        affinity_domain = "politics",
        min_affinity = 35,
        execute = function(focal, gs, engine)
            local aff = focal.components.signal_affinity or {}
            local pol = aff.politics or 30
            local lines = {}

            if gs.rivals and gs.rivals.houses then
                for _, house in ipairs(gs.rivals.houses) do
                    if house.status ~= "active" then goto skip end
                    if pol > 45 then
                        if house.heir and house.heir.attitude == "hostile" then
                            table.insert(lines, house.name .. " is hostile. Their heir, " .. house.heir.name .. ", makes no secret of their contempt.")
                        elseif house.heir and house.heir.attitude == "devoted" then
                            table.insert(lines, house.name .. " is an ally — or at least, not an enemy. For now.")
                        else
                            table.insert(lines, house.name .. " watches. Waits. Their intentions are unclear.")
                        end
                    else
                        table.insert(lines, "You hear the name " .. house.name .. " but can't piece together what they want.")
                    end
                    ::skip::
                end
            end

            Affinity.train(focal.components.signal_affinity, "politics", 2)
            return { text = #lines > 0 and table.concat(lines, " ") or "You don't know enough about the power structures here yet." }
        end,
    },
    {
        id = "read_the_room",
        label = "Observe carefully",
        description = "Stop. Watch. Notice what you usually miss.",
        location_types = nil,  -- available everywhere
        affinity_domain = nil, -- trains whatever domain matches the location
        min_affinity = 0,
        execute = function(focal, gs, engine)
            -- Generate extra signals for this location
            local signals = engine:get_module("signals")
            if signals then
                signals:generate(gs, gs.clock or {})
            end

            local active = signals and signals:get_active() or {}
            if #active > 0 then
                local best = active[1]
                -- Train the domain of whatever you noticed
                if focal.components.signal_affinity and best.category then
                    Affinity.train(focal.components.signal_affinity, best.category, 3)
                end
                return { text = "You slow down. You look. And you see: " .. best.text }
            end

            return { text = "You watch carefully. Nothing stands out — but the act of looking sharpens your eye." }
        end,
    },
    {
        id = "consult_ally",
        label = "Consult someone you trust",
        description = "Ask a friend what they know.",
        location_types = nil,  -- anywhere, but needs a trusted person present
        affinity_domain = "social",
        min_affinity = 20,
        needs_target = "person",
        execute = function(focal, gs, engine, target)
            if not target then return { text = "Trust is earned. You haven't earned enough yet." } end

            -- Check relationship strength
            local entities = engine:get_module("entities")
            if not entities then return { text = "Nobody to ask." } end
            local rels = entities:get_relationships(focal.id)
            local trust = 0
            for _, rel in ipairs(rels) do
                if rel.a == target.id or rel.b == target.id then
                    trust = trust + (rel.strength or 0)
                end
            end

            if trust < 40 then
                return { text = target.name .. " gives you a polite but empty answer. You're not close enough for the real truth." }
            end

            -- They share what THEY know based on THEIR affinity
            local their_p = target.components.personality or {}
            local their_obs = their_p.PER_OBS or 50
            if type(their_obs) == "table" then their_obs = their_obs.value or 50 end

            local lines = { target.name .. " leans in." }

            if their_obs > 60 then
                -- Observant allies give better intel
                if gs.politics and gs.politics.unrest > 40 then
                    table.insert(lines, "\"The people are restless. I've been watching. It's worse than they're saying in court.\"")
                end
                if gs.underworld and gs.underworld.global_corruption > 40 then
                    table.insert(lines, "\"Something's rotten in the institutions. Follow the money.\"")
                end
            end

            if their_obs <= 60 then
                table.insert(lines, "\"I don't know much. But I know you can trust me. That has to count for something.\"")
            end

            Affinity.train(focal.components.signal_affinity, "social", 1)
            return { text = table.concat(lines, " ") }
        end,
    },
}

--- Get available inquiry types for current context.
---@param focal table focal entity
---@param location_type string|nil current location type
---@param nearby_people table|nil array of nearby person entities
---@return table array of { id, label, description, available, reason }
function Inquiry.get_available(focal, location_type, nearby_people)
    local aff = focal.components.signal_affinity or {}
    local result = {}

    for _, inq in ipairs(INQUIRY_TYPES) do
        local available = true
        local reason = nil

        -- Location check
        if inq.location_types then
            local loc_ok = false
            for _, lt in ipairs(inq.location_types) do
                if lt == location_type then loc_ok = true; break end
            end
            if not loc_ok then
                available = false
                reason = "Not available here."
            end
        end

        -- Affinity check
        if available and inq.affinity_domain and inq.min_affinity > 0 then
            local player_aff = aff[inq.affinity_domain] or 0
            if player_aff < inq.min_affinity then
                available = false
                reason = "You don't know enough about this yet."
            end
        end

        -- Target check
        if available and inq.needs_target then
            if not nearby_people or #nearby_people == 0 then
                available = false
                reason = "Nobody here to ask."
            end
        end

        table.insert(result, {
            id = inq.id,
            label = inq.label,
            description = inq.description,
            available = available,
            unavailable_reason = reason,
            needs_target = inq.needs_target,
        })
    end

    return result
end

--- Execute an inquiry.
---@param inquiry_id string
---@param focal table focal entity
---@param gs table game_state
---@param engine table
---@param target table|nil target entity (for person-targeted inquiries)
---@return table { text }
function Inquiry.execute(inquiry_id, focal, gs, engine, target)
    for _, inq in ipairs(INQUIRY_TYPES) do
        if inq.id == inquiry_id then
            return inq.execute(focal, gs, engine, target)
        end
    end
    return { text = "You're not sure what you were looking for." }
end

return Inquiry
