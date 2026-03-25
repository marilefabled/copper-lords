-- dredwork Core — Seedable RNG
-- Instance-based PRNG using xorshift32 for deterministic, independent sequences.
-- Backward compatible: module-level functions delegate to a default instance.

-- Portable bitwise ops: Lua 5.3+ native, LuaJIT/5.1 via bit library
local bxor, lshift, rshift, band
if bit32 then
    bxor, lshift, rshift, band = bit32.bxor, bit32.lshift, bit32.rshift, bit32.band
elseif bit then
    bxor, lshift, rshift, band = bit.bxor, bit.lshift, bit.rshift, bit.band
else
    -- Lua 5.3+ native bitwise operators via load() to avoid parse errors on 5.1
    local fn = load("return function(a,b) return a ~ b end") or load("return function(a,b) return a end")
    bxor = fn()
    fn = load("return function(a,n) return a << n end") or load("return function(a,n) return a end")
    lshift = fn()
    fn = load("return function(a,n) return a >> n end") or load("return function(a,n) return a end")
    rshift = fn()
    fn = load("return function(a,b) return a & b end") or load("return function(a,b) return a end")
    band = fn()
end

local UINT32 = 0xFFFFFFFF

--- Internal: advance xorshift32 state.
local function xorshift32(state)
    state = bxor(state, lshift(state, 13))
    state = bxor(state, rshift(state, 17))
    state = bxor(state, lshift(state, 5))
    return band(state, UINT32)
end

--------------------------------------------------------------------------------
-- Instance methods live on a separate metatable so static wrappers on RNG
-- (for backward compatibility) don't shadow them.
--------------------------------------------------------------------------------
local Instance = {}
Instance.__index = Instance

--- Seed (or re-seed) this instance.
---@param seed number
function Instance:seed(seed)
    self._seed = seed
    -- Ensure non-zero state for xorshift
    self._state = (math.floor(math.abs(seed)) % UINT32)
    if self._state == 0 then self._state = 1 end
    -- Warm up the generator
    for _ = 1, 8 do self._state = xorshift32(self._state) end
end

--- Get the original seed for save/replay.
---@return number
function Instance:get_seed()
    return self._seed
end

--- Return a random float in [0, 1).
---@return number
function Instance:random()
    self._state = xorshift32(self._state)
    return (self._state % 0x7FFFFFFF) / 0x7FFFFFFF
end

--- Return a random integer in [min, max] (inclusive).
---@param min number
---@param max number
---@return number
function Instance:range(min, max)
    return min + math.floor(self:random() * (max - min + 1))
end

--- Return a float from an approximate normal distribution (Box-Muller).
---@param mean number (default 0)
---@param stddev number (default 1)
---@return number
function Instance:normal(mean, stddev)
    mean = mean or 0
    stddev = stddev or 1
    local u1 = math.max(1e-10, self:random())
    local u2 = self:random()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mean + z * stddev
end

--- Return true with the given probability [0, 1].
---@param chance number probability between 0 and 1
---@return boolean
function Instance:chance(chance)
    return self:random() < chance
end

--- Pick a random item from a list.
---@param list table
---@return any
function Instance:pick(list)
    if not list or #list == 0 then return nil end
    return list[self:range(1, #list)]
end

--- Pick an item from a list based on weights.
---@param list table
---@param weight_fn function|nil optional function to extract weight from item
---@return any
function Instance:weighted_pick(list, weight_fn)
    if not list or #list == 0 then return nil end

    local total_weight = 0
    for _, item in ipairs(list) do
        total_weight = total_weight + (weight_fn and weight_fn(item) or item.weight or 1)
    end

    local roll = self:random() * total_weight
    local current = 0
    for _, item in ipairs(list) do
        current = current + (weight_fn and weight_fn(item) or item.weight or 1)
        if roll <= current then
            return item
        end
    end
    return list[1]
end

--------------------------------------------------------------------------------
-- Public module table: constructor + static wrappers for backward compatibility
--------------------------------------------------------------------------------
local RNG = {}

--- Create a new independent RNG instance.
---@param seed number
---@return table RNG instance
function RNG.new(seed)
    local self = setmetatable({}, Instance)
    self._state = 0
    self:seed(seed or os.time())
    return self
end

-- Default instance (created at require-time)
local _default = RNG.new(os.time())

--- Set the default instance (called by the engine on startup).
function RNG.set_default(instance)
    _default = instance
end

--- Get the default instance.
function RNG.get_default()
    return _default
end

-- Static wrappers that delegate to the default instance.
-- Existing code doing `local RNG = require("dredwork_core.rng"); RNG.random()` keeps working.
function RNG.seed(s)                  return _default:seed(s)                   end
function RNG.get_seed()               return _default:get_seed()                end
function RNG.random()                 return _default:random()                  end
function RNG.range(min, max)          return _default:range(min, max)           end
function RNG.normal(mean, stddev)     return _default:normal(mean, stddev)      end
function RNG.chance(c)                return _default:chance(c)                 end
function RNG.pick(list)               return _default:pick(list)                end
function RNG.weighted_pick(list, wfn) return _default:weighted_pick(list, wfn)  end

return RNG
