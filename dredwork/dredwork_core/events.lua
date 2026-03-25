-- dredwork Core — Event Bus
-- Instance-based messaging to allow modules to communicate without hard dependencies.
-- Each engine instance owns its own event bus.

local Events = {}
Events.__index = Events

--- Create a new event bus instance.
---@return table Events instance
function Events.new()
    local self = setmetatable({}, Events)
    self._listeners = {}
    return self
end

--- Subscribe to an event.
---@param event_name string
---@param callback function
function Events:on(event_name, callback)
    self._listeners[event_name] = self._listeners[event_name] or {}
    table.insert(self._listeners[event_name], callback)
end

--- Unsubscribe from an event.
---@param event_name string
---@param callback function
function Events:off(event_name, callback)
    if not self._listeners[event_name] then return end
    for i, cb in ipairs(self._listeners[event_name]) do
        if cb == callback then
            table.remove(self._listeners[event_name], i)
            break
        end
    end
end

--- Emit an event with optional arguments.
---@param event_name string
---@param ... any
function Events:emit(event_name, ...)
    if not self._listeners[event_name] then return end
    for _, callback in ipairs(self._listeners[event_name]) do
        callback(...)
    end
end

--- Clear all listeners for a specific event or all events.
---@param event_name string|nil
function Events:clear(event_name)
    if event_name then
        self._listeners[event_name] = nil
    else
        self._listeners = {}
    end
end

return Events
