-- dredwork Geography — Regional State
-- Each region tracks its own suspicion, reputation awareness, and player history.
-- Your claim pressure is LOCAL. Moving regions changes the game.
--
-- "In Ironhold, they know your face. In Ashenmoor, you're nobody again."

local Math = require("dredwork_core.math")
local RNG = require("dredwork_core.rng")

local RegionalState = {}

--- Create regional state for a region.
function RegionalState.create(region_id)
    return {
        region_id = region_id,
        suspicion = 0,          -- 0-100 local suspicion (separate from global claim.suspicion)
        reputation_known = false, -- does this region know your reputation?
        visits = 0,              -- how many times you've been here
        days_spent = 0,          -- total days in this region
        last_visit_day = 0,      -- when you last visited
        contacts = {},           -- entity_ids you've interacted with here
        rumors_heard = {},       -- rumor_ids that have reached this region
        is_capital = false,      -- seat of the ruling house (claim target)
        danger_level = "safe",   -- safe, cautious, dangerous, hostile
    }
end

--- Update danger level from suspicion.
function RegionalState.update_danger(state)
    local s = state.suspicion
    if s >= 75 then state.danger_level = "hostile"
    elseif s >= 50 then state.danger_level = "dangerous"
    elseif s >= 25 then state.danger_level = "cautious"
    else state.danger_level = "safe" end
end

--- Record a visit to this region.
function RegionalState.arrive(state, day)
    state.visits = state.visits + 1
    state.last_visit_day = day
end

--- Record a contact (entity you interacted with here).
function RegionalState.add_contact(state, entity_id)
    for _, c in ipairs(state.contacts) do
        if c == entity_id then return end
    end
    table.insert(state.contacts, entity_id)
end

--- Monthly tick: suspicion drift, reputation spread.
function RegionalState.tick_monthly(state, gs, distance_from_capital)
    -- Suspicion decay based on distance from capital (further = slower spread)
    local decay = distance_from_capital > 3 and 3 or (distance_from_capital > 1 and 2 or 1)
    state.suspicion = Math.clamp(state.suspicion - decay, 0, 100)

    -- Capital always has baseline suspicion creep if claim is active
    if state.is_capital and gs.claim and gs.claim.type then
        state.suspicion = Math.clamp(state.suspicion + 2, 0, 100)
    end

    -- Suspicion spreads from global claim suspicion to this region (attenuated by distance)
    if gs.claim and gs.claim.suspicion > 20 then
        local spread = math.floor(gs.claim.suspicion * 0.1 / math.max(1, distance_from_capital))
        state.suspicion = Math.clamp(state.suspicion + spread, 0, 100)
    end

    RegionalState.update_danger(state)
    state.days_spent = state.days_spent + 30
end

--- Get how familiar you are with this region.
function RegionalState.get_familiarity(state)
    if state.days_spent > 180 then return "native"
    elseif state.days_spent > 90 then return "established"
    elseif state.days_spent > 30 then return "familiar"
    elseif state.visits > 0 then return "newcomer"
    end
    return "unknown"
end

--- Get contact count in this region.
function RegionalState.get_contact_count(state)
    return #state.contacts
end

return RegionalState
