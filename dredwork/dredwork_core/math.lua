-- dredwork Core — Math Utilities

local Math = {}

--- Clamp a value between min and max.
---@param value number
---@param min number
---@param max number
---@return number
function Math.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

--- Linearly interpolate between a and b.
---@param a number
---@param b number
---@param t number
---@return number
function Math.lerp(a, b, t)
    return a + (b - a) * t
end

--- Round a number to the nearest integer or specific decimal place.
---@param value number
---@param bracket number|nil
---@return number
function Math.round(value, bracket)
    bracket = bracket or 1
    return math.floor(value / bracket + 0.5) * bracket
end

return Math
