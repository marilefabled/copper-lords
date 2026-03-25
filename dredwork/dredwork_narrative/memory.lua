-- dredwork Narrative — Memory & Deduplication
-- Tracks what has been narrated, prevents repetition, throttles output.

local Memory = {}

--- Create a fresh memory state.
function Memory.create()
    return {
        recent_hashes = {},
        recent_hash_order = {},
        max_recent = 100,
        threads = {},
        cooldowns = {},
        beat_log = {},
        temperature_window = 30,
        max_temperature = 15,
    }
end

--- Generate a dedup hash for a template + key variables.
local function make_hash(template_id, vars)
    local parts = { template_id }
    if vars then
        if vars.region then parts[#parts + 1] = vars.region end
        if vars.heir_name then parts[#parts + 1] = vars.heir_name end
        if vars.subject then parts[#parts + 1] = vars.subject end
    end
    return table.concat(parts, ":")
end

--- Get the current narrative temperature (beats emitted in the window).
local function get_temperature(mem, clock)
    local count = 0
    local cutoff = (clock.total_days or 0) - mem.temperature_window
    for day, c in pairs(mem.beat_log) do
        if day > cutoff then
            count = count + c
        end
    end
    return count
end

--- Check if a beat should be emitted (dedup + cooldown + throttle).
---@param mem table memory state
---@param template_id string
---@param vars table template variables
---@param clock table engine clock
---@param priority number|nil beat priority (high priority bypasses throttle)
---@return boolean
function Memory.should_emit(mem, template_id, vars, clock, priority)
    priority = priority or 50
    local today = clock.total_days or 0

    -- 1. Hash dedup: was this exact beat emitted recently?
    local hash = make_hash(template_id, vars)
    if mem.recent_hashes[hash] then
        return false
    end

    -- 2. Cooldown: is this template on cooldown?
    if mem.cooldowns[template_id] and today < mem.cooldowns[template_id] then
        return false
    end

    -- 3. Temperature throttle (bypassed by high priority)
    if priority < 90 then
        local temp = get_temperature(mem, clock)
        if temp >= mem.max_temperature then
            return false
        end
    end

    return true
end

--- Record that a beat was emitted.
function Memory.record(mem, template_id, vars, clock, cooldown_days)
    local today = clock.total_days or 0
    local hash = make_hash(template_id, vars)

    -- Add to recent hashes (ring buffer)
    mem.recent_hashes[hash] = true
    table.insert(mem.recent_hash_order, hash)
    while #mem.recent_hash_order > mem.max_recent do
        local old = table.remove(mem.recent_hash_order, 1)
        mem.recent_hashes[old] = nil
    end

    -- Set cooldown
    if cooldown_days and cooldown_days > 0 then
        mem.cooldowns[template_id] = today + cooldown_days
    end

    -- Update temperature log
    mem.beat_log[today] = (mem.beat_log[today] or 0) + 1
end

--- Start a narrative thread (ongoing arc).
function Memory.start_thread(mem, thread_id, clock)
    mem.threads[thread_id] = {
        started_day = clock.total_days,
        last_beat_day = clock.total_days,
        beat_count = 1,
        resolved = false,
    }
end

--- Advance a thread (record a new beat in it).
function Memory.advance_thread(mem, thread_id, clock)
    local t = mem.threads[thread_id]
    if t then
        t.last_beat_day = clock.total_days
        t.beat_count = t.beat_count + 1
    end
end

--- Mark a thread as resolved.
function Memory.resolve_thread(mem, thread_id)
    local t = mem.threads[thread_id]
    if t then t.resolved = true end
end

--- Is a thread currently active?
function Memory.is_thread_active(mem, thread_id)
    local t = mem.threads[thread_id]
    return t and not t.resolved
end

--- Monthly cleanup: prune old temperature entries and expired cooldowns.
function Memory.cleanup(mem, clock)
    local today = clock.total_days or 0
    local cutoff = today - mem.temperature_window

    -- Prune beat log
    for day in pairs(mem.beat_log) do
        if day < cutoff then mem.beat_log[day] = nil end
    end

    -- Prune expired cooldowns
    for tid, expiry in pairs(mem.cooldowns) do
        if today >= expiry then mem.cooldowns[tid] = nil end
    end

    -- Prune resolved threads older than 1 year (360 days)
    for tid, t in pairs(mem.threads) do
        if t.resolved and (today - t.last_beat_day) > 360 then
            mem.threads[tid] = nil
        end
    end
end

return Memory
