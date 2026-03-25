local Math = require("dredwork_core.math")
local ShadowPossessions = {}

local OCCUPATION_ITEMS = {
    laborer = { id = "work_knife", label = "Work Knife", kind = "item", status = "Serviceable", upkeep = 0, yield = 1, weight = "common", stain = 0 },
    scribe = { id = "ledger_satchel", label = "Ledger Satchel", kind = "item", status = "Useful", upkeep = 0, yield = 2, weight = "common", stain = 0 },
    soldier = { id = "service_blade", label = "Service Blade", kind = "item", status = "Worn", upkeep = 1, yield = 2, weight = "scarred", stain = 1 },
    courtier = { id = "borrowed_livery", label = "Borrowed Livery", kind = "item", status = "Precarious", upkeep = 1, yield = 1, weight = "delicate", stain = 0 },
    tinker = { id = "tool_wrap", label = "Tool Wrap", kind = "item", status = "Useful", upkeep = 1, yield = 2, weight = "oily", stain = 0 },
    performer = { id = "stage_cloak", label = "Stage Cloak", kind = "item", status = "Gaudy", upkeep = 1, yield = 2, weight = "showy", stain = 0 },
}

local HOUSEHOLD_PLACES = {
    devout = { id = "family_shrine", label = "Family Shrine", kind = "place", status = "Watchful", upkeep = 0, yield = 1, weight = "sacred", stain = 0 },
    debtor = { id = "leased_room", label = "Leased Room", kind = "place", status = "Thin-Walled", upkeep = 1, yield = 1, weight = "borrowed", stain = 0 },
    martial = { id = "yard_bed", label = "Yard Bed", kind = "place", status = "Hard", upkeep = 0, yield = 1, weight = "brutal", stain = 0 },
    scholarly = { id = "copy_desk", label = "Copy Desk", kind = "place", status = "Cold", upkeep = 1, yield = 2, weight = "quiet", stain = 0 },
    fractured = { id = "split_hearth", label = "Split Hearth", kind = "place", status = "Contested", upkeep = 1, yield = 0, weight = "tense", stain = 0 },
    wandering = { id = "road_cart", label = "Road Cart", kind = "place", status = "Unsteady", upkeep = 1, yield = 1, weight = "moving", stain = 0 },
}

local BURDEN_ITEMS = {
    claim = { id = "branch_token", label = "Branch Token", kind = "item", status = "Hidden", upkeep = 0, yield = 1, weight = "forbidden", stain = 0 },
    debt = { id = "credit_ledger", label = "Creditor's Ledger Leaf", kind = "item", status = "Damning", upkeep = 0, yield = 0, weight = "binding", stain = 1 },
    oath = { id = "oath_thread", label = "Oath Thread", kind = "item", status = "Binding", upkeep = 0, yield = 0, weight = "sacred", stain = 0 },
}

local function setup_of(game_state)
    return game_state and game_state.shadow_setup or nil
end

local function add_copy(list, spec)
    if not list or not spec or not spec.id then
        return
    end
    for _, existing in ipairs(list) do
        if existing.id == spec.id then
            return
        end
    end
    list[#list + 1] = {
        id = spec.id,
        label = spec.label or spec.id,
        kind = spec.kind or "item",
        status = spec.status or "Held",
        upkeep = spec.upkeep or 0,
        yield = spec.yield or 0,
        weight = spec.weight or "plain",
        stain = spec.stain or 0,
        note = spec.note,
    }
end

local function remove_id(list, id)
    if not list or not id then
        return
    end
    for index = #list, 1, -1 do
        if list[index].id == id then
            table.remove(list, index)
            return
        end
    end
end

local function by_kind(state, kind)
    local out = {}
    for _, entry in ipairs(state.entries or {}) do
        if entry.kind == kind then
            out[#out + 1] = entry
        end
    end
    return out
end

local function summarize_kind(entries)
    if #entries == 0 then
        return "None"
    end
    local first = entries[1]
    if #entries == 1 then
        return first.label .. " | " .. (first.status or "Held")
    end
    return first.label .. " +" .. tostring(#entries - 1)
end

local function recompute_totals(state)
    local upkeep = 0
    local yield = 0
    local stain = 0
    for _, entry in ipairs(state.entries or {}) do
        upkeep = upkeep + (entry.upkeep or 0)
        yield = yield + (entry.yield or 0)
        stain = stain + (entry.stain or 0)
    end
    state.upkeep = upkeep
    state.yield = yield
    state.stain = stain
end

function ShadowPossessions.ensure_state(game_state)
    game_state.shadow_possessions = game_state.shadow_possessions or {}
    local state = game_state.shadow_possessions
    state.entries = state.entries or {}
    if state.initialized then
        recompute_totals(state)
        return state
    end

    local setup = setup_of(game_state) or {}
    add_copy(state.entries, OCCUPATION_ITEMS[setup.occupation or "laborer"] or OCCUPATION_ITEMS.laborer)
    add_copy(state.entries, HOUSEHOLD_PLACES[setup.household or "debtor"] or HOUSEHOLD_PLACES.debtor)
    if BURDEN_ITEMS[setup.burden or ""] then
        add_copy(state.entries, BURDEN_ITEMS[setup.burden])
    end

    state.initialized = true
    recompute_totals(state)
    return state
end

function ShadowPossessions.apply(game_state, payload)
    local state = ShadowPossessions.ensure_state(game_state)
    if not payload then
        return ShadowPossessions.snapshot(game_state)
    end

    for _, entry in ipairs(payload.add or {}) do
        add_copy(state.entries, entry)
    end
    for _, id in ipairs(payload.remove or {}) do
        remove_id(state.entries, id)
    end
    for _, shift in ipairs(payload.adjust or {}) do
        for _, entry in ipairs(state.entries) do
            if entry.id == shift.id then
                if shift.status then
                    entry.status = shift.status
                end
                if shift.note then
                    entry.note = shift.note
                end
                if type(shift.upkeep) == "number" then
                    entry.upkeep = Math.clamp((entry.upkeep or 0) + shift.upkeep, 0, 10)
                end
                if type(shift.yield) == "number" then
                    entry.yield = Math.clamp((entry.yield or 0) + shift.yield, 0, 10)
                end
                if type(shift.stain) == "number" then
                    entry.stain = Math.clamp((entry.stain or 0) + shift.stain, 0, 10)
                end
            end
        end
    end

    recompute_totals(state)
    return ShadowPossessions.snapshot(game_state)
end

function ShadowPossessions.tick_year(game_state)
    if not game_state then
        return nil
    end
    local state = ShadowPossessions.ensure_state(game_state)
    recompute_totals(state)
    return ShadowPossessions.snapshot(game_state)
end

function ShadowPossessions.snapshot(game_state)
    if not game_state then
        return nil
    end
    local state = ShadowPossessions.ensure_state(game_state)
    local items = by_kind(state, "item")
    local places = by_kind(state, "place")
    local people = by_kind(state, "person")

    return {
        entries = state.entries,
        items = items,
        places = places,
        people = people,
        item_count = #items,
        place_count = #places,
        people_count = #people,
        upkeep = state.upkeep or 0,
        yield = state.yield or 0,
        stain = state.stain or 0,
        overview_line = tostring(#items) .. " items | " .. tostring(#places) .. " places | " .. tostring(#people) .. " held",
        item_line = summarize_kind(items),
        place_line = summarize_kind(places),
        people_line = summarize_kind(people),
    }
end

return ShadowPossessions
