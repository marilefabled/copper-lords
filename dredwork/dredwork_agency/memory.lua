-- dredwork Agency — Entity Memory
-- Entities remember events, grudges, debts, and witnessed actions.
-- Memory drives motivated behavior — personality produces action, memory produces *why*.

local Math = require("dredwork_core.math")

local Memory = {}

--- Create a fresh memory component.
function Memory.create()
    return {
        events = {},        -- { day, type, subject_id, text, emotional_weight }
        grudges = {},       -- { target_id, reason, intensity, day }
        debts = {},         -- { target_id, reason, weight, day } (gratitude owed)
        witnessed = {},     -- { day, event_type, details } (things seen but not directly involved in)
        max_events = 20,
        max_witnessed = 10,
    }
end

--- Record an event that happened to this entity.
function Memory.remember(mem, day, event_type, subject_id, text, emotional_weight)
    table.insert(mem.events, {
        day = day,
        type = event_type,
        subject_id = subject_id,
        text = text,
        weight = emotional_weight or 1.0,
    })
    while #mem.events > mem.max_events do
        table.remove(mem.events, 1)
    end
end

--- Record something this entity witnessed (not directly involved).
function Memory.witness(mem, day, event_type, details)
    table.insert(mem.witnessed, {
        day = day,
        type = event_type,
        details = details,
    })
    while #mem.witnessed > mem.max_witnessed do
        table.remove(mem.witnessed, 1)
    end
end

--- Add or intensify a grudge against a target.
function Memory.add_grudge(mem, target_id, reason, intensity)
    -- Check for existing grudge
    for _, g in ipairs(mem.grudges) do
        if g.target_id == target_id then
            g.intensity = Math.clamp(g.intensity + (intensity or 10), 0, 100)
            g.reason = reason or g.reason
            return g
        end
    end
    -- New grudge (max 5)
    local grudge = {
        target_id = target_id,
        reason = reason or "wronged",
        intensity = Math.clamp(intensity or 30, 0, 100),
    }
    table.insert(mem.grudges, grudge)
    while #mem.grudges > 5 do
        -- Remove weakest
        local min_idx, min_val = 1, 999
        for i, g in ipairs(mem.grudges) do
            if g.intensity < min_val then min_idx = i; min_val = g.intensity end
        end
        table.remove(mem.grudges, min_idx)
    end
    return grudge
end

--- Add or increase a debt of gratitude.
function Memory.add_debt(mem, target_id, reason, weight)
    for _, d in ipairs(mem.debts) do
        if d.target_id == target_id then
            d.weight = Math.clamp(d.weight + (weight or 5), 0, 100)
            return d
        end
    end
    local debt = {
        target_id = target_id,
        reason = reason or "helped",
        weight = Math.clamp(weight or 15, 0, 100),
    }
    table.insert(mem.debts, debt)
    while #mem.debts > 5 do
        local min_idx, min_val = 1, 999
        for i, d in ipairs(mem.debts) do
            if d.weight < min_val then min_idx = i; min_val = d.weight end
        end
        table.remove(mem.debts, min_idx)
    end
    return debt
end

--- Get the strongest grudge target.
function Memory.get_worst_enemy(mem)
    local worst, worst_intensity = nil, 0
    for _, g in ipairs(mem.grudges) do
        if g.intensity > worst_intensity then
            worst = g.target_id
            worst_intensity = g.intensity
        end
    end
    return worst, worst_intensity
end

--- Get the strongest debt target (who do I owe the most?).
function Memory.get_biggest_debt(mem)
    local best, best_weight = nil, 0
    for _, d in ipairs(mem.debts) do
        if d.weight > best_weight then
            best = d.target_id
            best_weight = d.weight
        end
    end
    return best, best_weight
end

--- Decay grudges and debts over time (called monthly).
function Memory.decay(mem)
    for i = #mem.grudges, 1, -1 do
        mem.grudges[i].intensity = mem.grudges[i].intensity - 1
        if mem.grudges[i].intensity <= 0 then table.remove(mem.grudges, i) end
    end
    for i = #mem.debts, 1, -1 do
        mem.debts[i].weight = mem.debts[i].weight - 0.5
        if mem.debts[i].weight <= 0 then table.remove(mem.debts, i) end
    end
end

--- Does this entity hold a grudge against target?
function Memory.has_grudge(mem, target_id)
    for _, g in ipairs(mem.grudges) do
        if g.target_id == target_id then return true, g.intensity end
    end
    return false, 0
end

--- Does this entity owe a debt to target?
function Memory.has_debt(mem, target_id)
    for _, d in ipairs(mem.debts) do
        if d.target_id == target_id then return true, d.weight end
    end
    return false, 0
end

return Memory
