-- dredwork Core — String Utilities

local Strings = {}

--- Capitalize the first letter of a string.
---@param value string
---@return string
function Strings.titleize(value)
    return tostring(value or ""):gsub("^%l", string.upper)
end

--- Convert a string to a snake_case slug.
---@param value string
---@return string
function Strings.slugify(value)
    local slug = tostring(value or "")
    slug = slug:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    return slug
end

--- Split a string by a delimiter.
---@param str string
---@param delimiter string
---@return table
function Strings.split(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

return Strings
