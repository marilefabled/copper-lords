-- Dark Legacy — Serializer
-- Save/load genetics data to JSON-compatible Lua tables.
-- Uses pure Lua (no external JSON lib required for table form;
-- JSON string encoding provided as utility).

local Serializer = {}

--- Serialize a genome to a plain Lua table (JSON-compatible).
---@param genome table Genome object
---@return table serializable data
function Serializer.genome_to_table(genome)
    local data = { traits = {}, mastery_tags = genome.mastery_tags or {} }
    for id, trait in pairs(genome.traits) do
        local t = {
            id = trait.id,
            value = trait.value,
            category = trait.category,
            visibility = trait.visibility,
            inheritance_mode = trait.inheritance_mode,
        }
        if trait.alleles then
            t.alleles = {
                { value = trait.alleles[1].value, dominant = trait.alleles[1].dominant },
                { value = trait.alleles[2].value, dominant = trait.alleles[2].dominant },
            }
        end
        data.traits[id] = t
    end
    return data
end

--- Serialize cultural memory to a plain Lua table.
---@param memory table CulturalMemory object
---@return table serializable data
function Serializer.memory_to_table(memory)
    local function shallow_copy(t)
        if type(t) ~= "table" then return t end
        local copy = {}
        for k, v in pairs(t) do copy[k] = v end
        return copy
    end
    return {
        trait_priorities = shallow_copy(memory.trait_priorities),
        reputation = memory.reputation,
        taboos = shallow_copy(memory.taboos),
        blind_spots = shallow_copy(memory.blind_spots),
        relationships = shallow_copy(memory.relationships),
    }
end

--- Simple Lua table to JSON string encoder (pure Lua, no deps).
--- Optimized for large tables by using a buffer.
---@param val any Lua value (table, string, number, boolean, nil)
---@return string JSON string
function Serializer.to_json(val)
    local buffer = {}
    
    local function encode(v)
        local t = type(v)
        if t == "nil" then
            buffer[#buffer + 1] = "null"
        elseif t == "boolean" then
            buffer[#buffer + 1] = v and "true" or "false"
        elseif t == "number" then
            if v ~= v then buffer[#buffer + 1] = "0"
            elseif v == math.huge then buffer[#buffer + 1] = "99999"
            elseif v == -math.huge then buffer[#buffer + 1] = "-99999"
            else buffer[#buffer + 1] = tostring(v) end
        elseif t == "string" then
            buffer[#buffer + 1] = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t') .. '"'
        elseif t == "table" then
            -- Detect array vs object
            local is_array = true
            local count = 0
            local max_key = 0
            for k, _ in pairs(v) do
                count = count + 1
                if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then
                    is_array = false
                    break
                end
                if k > max_key then max_key = k end
            end
            
            if is_array and count > 0 and max_key ~= count then
                is_array = false -- sparse
            end
            
            if is_array then
                buffer[#buffer + 1] = "["
                for i = 1, count do
                    encode(v[i])
                    if i < count then buffer[#buffer + 1] = "," end
                end
                buffer[#buffer + 1] = "]"
            else
                buffer[#buffer + 1] = "{"
                local first = true
                for k, val_v in pairs(v) do
                    if not first then buffer[#buffer + 1] = "," end
                    first = false
                    encode(tostring(k))
                    buffer[#buffer + 1] = ":"
                    encode(val_v)
                end
                buffer[#buffer + 1] = "}"
            end
        else
            buffer[#buffer + 1] = "null"
        end
    end

    encode(val)
    return table.concat(buffer)
end

--- Simple JSON string to Lua table decoder (pure Lua, handles basics).
---@param str string JSON string
---@return any Lua value
function Serializer.from_json(str)
    if type(str) ~= "string" or #str == 0 then
        print("Warning: Serializer.from_json called with invalid input")
        return nil
    end

    local ok, result = pcall(function()
        -- Minimal JSON parser for save/load purposes
        local pos = 1

        local function skip_whitespace()
            while pos <= #str and str:sub(pos, pos):match("%s") do
                pos = pos + 1
            end
        end

        local parse_value -- forward declaration

        local function parse_string()
            assert(str:sub(pos, pos) == '"')
            pos = pos + 1
            local result = {}
            while pos <= #str do
                local c = str:sub(pos, pos)
                if c == '\\' then
                    pos = pos + 1
                    local esc = str:sub(pos, pos)
                    if esc == 'n' then result[#result + 1] = '\n'
                    elseif esc == 'r' then result[#result + 1] = '\r'
                    elseif esc == 't' then result[#result + 1] = '\t'
                    else result[#result + 1] = esc end
                elseif c == '"' then
                    pos = pos + 1
                    return table.concat(result)
                else
                    result[#result + 1] = c
                end
                pos = pos + 1
            end
            error("Unterminated string")
        end

        local function parse_number()
            local start = pos
            if str:sub(pos, pos) == '-' then pos = pos + 1 end
            while pos <= #str and str:sub(pos, pos):match("[%d%.eE%+%-]") do
                pos = pos + 1
            end
            return tonumber(str:sub(start, pos - 1))
        end

        local function parse_array()
            pos = pos + 1 -- skip [
            local arr = {}
            skip_whitespace()
            if str:sub(pos, pos) == ']' then
                pos = pos + 1
                return arr
            end
            while true do
                skip_whitespace()
                arr[#arr + 1] = parse_value()
                skip_whitespace()
                if str:sub(pos, pos) == ',' then
                    pos = pos + 1
                elseif str:sub(pos, pos) == ']' then
                    pos = pos + 1
                    return arr
                else
                    error("Expected ',' or ']' in array at position " .. pos)
                end
            end
        end

        local function parse_object()
            pos = pos + 1 -- skip {
            local obj = {}
            skip_whitespace()
            if str:sub(pos, pos) == '}' then
                pos = pos + 1
                return obj
            end
            while true do
                skip_whitespace()
                local key = parse_string()
                skip_whitespace()
                assert(str:sub(pos, pos) == ':', "Expected ':' at position " .. pos)
                pos = pos + 1
                skip_whitespace()
                obj[key] = parse_value()
                skip_whitespace()
                if str:sub(pos, pos) == ',' then
                    pos = pos + 1
                elseif str:sub(pos, pos) == '}' then
                    pos = pos + 1
                    return obj
                else
                    error("Expected ',' or '}' in object at position " .. pos)
                end
            end
        end

        parse_value = function()
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == '"' then return parse_string()
            elseif c == '{' then return parse_object()
            elseif c == '[' then return parse_array()
            elseif c == 't' then
                assert(str:sub(pos, pos + 3) == "true")
                pos = pos + 4
                return true
            elseif c == 'f' then
                assert(str:sub(pos, pos + 4) == "false")
                pos = pos + 5
                return false
            elseif c == 'n' then
                assert(str:sub(pos, pos + 3) == "null")
                pos = pos + 4
                return nil
            else
                return parse_number()
            end
        end

        return parse_value()
    end)

    if not ok then
        print("Error: Serializer.from_json parse failed: " .. tostring(result))
        return nil
    end
    return result
end

return Serializer
