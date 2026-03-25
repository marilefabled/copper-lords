--- dredwork-aibridge: Payload Encoder
--- Game-side module for extracting, encoding, and checksumming run data
--- into a portable wire format.
---
--- HOOKS:
---   extract(run_data) -> table     Required. Returns the payload to encode.
---   on_encoded(wire_string)        Optional. Called after encoding succeeds.
---
--- Usage:
---   local Encoder = require("dredwork-aibridge.lua.payload_encoder")
---   Encoder.set_hooks({
---     extract = function(run_data)
---       return { version = 1, name = run_data.name, score = run_data.score }
---     end,
---   })
---   local wire = Encoder.encode(run_data)

local PayloadEncoder = {}

-- ── Configuration ──
local _config = {
  prefix = "DWAI1",        -- Wire format prefix (change per project)
  version = 1,             -- Schema version
  chunk_width = 76,        -- Line width for copy/paste safety
}

local _hooks = {}

-- ── Base64url ──
local b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

local function base64url_encode(data)
  local result = {}
  local pad = #data % 3
  if pad > 0 then data = data .. string.rep("\0", 3 - pad) end

  for i = 1, #data, 3 do
    local b1, b2, b3 = string.byte(data, i, i + 2)
    local n = b1 * 65536 + b2 * 256 + b3

    local c1 = math.floor(n / 262144) + 1
    local c2 = math.floor(n / 4096) % 64 + 1
    local c3 = math.floor(n / 64) % 64 + 1
    local c4 = n % 64 + 1

    result[#result + 1] = string.sub(b64, c1, c1)
    result[#result + 1] = string.sub(b64, c2, c2)
    result[#result + 1] = string.sub(b64, c3, c3)
    result[#result + 1] = string.sub(b64, c4, c4)
  end

  local encoded = table.concat(result)
  if pad == 1 then
    encoded = string.sub(encoded, 1, -3)
  elseif pad == 2 then
    encoded = string.sub(encoded, 1, -2)
  end

  return encoded
end

local function base64url_decode(data)
  -- Pad to multiple of 4
  local pad = 4 - (#data % 4)
  if pad < 4 then data = data .. string.rep("=", pad) end

  local lookup = {}
  for i = 1, 64 do lookup[string.sub(b64, i, i)] = i - 1 end
  lookup["="] = 0

  local result = {}
  for i = 1, #data, 4 do
    local c1 = lookup[string.sub(data, i, i)] or 0
    local c2 = lookup[string.sub(data, i + 1, i + 1)] or 0
    local c3 = lookup[string.sub(data, i + 2, i + 2)] or 0
    local c4 = lookup[string.sub(data, i + 3, i + 3)] or 0

    local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

    result[#result + 1] = string.char(math.floor(n / 65536) % 256)
    result[#result + 1] = string.char(math.floor(n / 256) % 256)
    result[#result + 1] = string.char(n % 256)
  end

  -- Remove padding bytes
  local encoded_pad = 4 - (pad == 4 and 0 or pad)
  local total = #result
  if encoded_pad == 2 then
    result[total] = nil
  elseif encoded_pad == 3 then
    result[total] = nil
    result[total - 1] = nil
  end

  return table.concat(result)
end

-- ── Bitwise XOR (Lua 5.1 compatible) ──
local bxor
if bit32 then
  bxor = bit32.bxor
elseif bit then
  bxor = bit.bxor
else
  bxor = function(a, b)
    local r, p = 0, 1
    for _ = 0, 31 do
      local a_bit = a % 2
      local b_bit = b % 2
      if a_bit ~= b_bit then r = r + p end
      a = math.floor(a / 2)
      b = math.floor(b / 2)
      p = p * 2
    end
    return r
  end
end

-- ── FNV-1a Hash (32-bit) ──
local function fnv1a(str)
  local hash = 2166136261
  for i = 1, #str do
    hash = bxor(hash, string.byte(str, i))
    hash = (hash * 16777619) % 4294967296
  end
  return string.format("%08x", hash)
end

-- ── JSON Serializer (minimal, Lua 5.1 compatible) ──
local function to_json(val)
  -- Use project's serializer if available
  if _hooks.to_json then return _hooks.to_json(val) end

  local t = type(val)
  if t == "nil" then return "null"
  elseif t == "boolean" then return val and "true" or "false"
  elseif t == "number" then
    if val ~= val then return "null" end
    if val == math.huge or val == -math.huge then return "null" end
    return string.format("%.14g", val)
  elseif t == "string" then
    local escaped = val:gsub('\\', '\\\\'):gsub('"', '\\"')
                       :gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    return '"' .. escaped .. '"'
  elseif t == "table" then
    -- Array check
    local is_array = #val > 0
    if is_array then
      local parts = {}
      for i = 1, #val do
        parts[i] = to_json(val[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      local parts = {}
      for k, v in pairs(val) do
        if type(k) == "string" then
          parts[#parts + 1] = to_json(k) .. ":" .. to_json(v)
        end
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  end
  return "null"
end

-- ── Public API ──

--- Configure the encoder.
--- @param opts table { prefix, version, chunk_width }
function PayloadEncoder.configure(opts)
  if opts.prefix then _config.prefix = opts.prefix end
  if opts.version then _config.version = opts.version end
  if opts.chunk_width then _config.chunk_width = opts.chunk_width end
end

--- Set hook functions.
--- @param hooks table { extract, on_encoded, to_json }
function PayloadEncoder.set_hooks(hooks)
  _hooks = hooks or {}
end

--- Extract and encode run data into wire format.
--- @param run_data table Raw game state
--- @return string|nil wire The encoded wire string, or nil on error
--- @return string|nil error Error message if encoding failed
function PayloadEncoder.encode(run_data)
  if not _hooks.extract then
    return nil, "No extract hook set. Call set_hooks({ extract = fn }) first."
  end

  local ok, payload = pcall(_hooks.extract, run_data)
  if not ok then
    return nil, "Extract hook failed: " .. tostring(payload)
  end

  if type(payload) ~= "table" then
    return nil, "Extract hook must return a table."
  end

  -- Stamp version
  payload.v = payload.v or _config.version

  -- Serialize
  local json_str = to_json(payload)

  -- Checksum
  local checksum = fnv1a(json_str)

  -- Encode
  local encoded = base64url_encode(json_str)

  -- Build wire string: PREFIX:RAW:CHECKSUM:DATA
  local wire = _config.prefix .. ":RAW:" .. checksum .. ":" .. encoded

  -- Chunk for copy/paste safety
  if _config.chunk_width > 0 then
    local chunks = {}
    for i = 1, #wire, _config.chunk_width do
      chunks[#chunks + 1] = string.sub(wire, i, i + _config.chunk_width - 1)
    end
    wire = table.concat(chunks, "\n")
  end

  if _hooks.on_encoded then
    pcall(_hooks.on_encoded, wire)
  end

  return wire
end

--- Decode a wire format string back to a table.
--- @param wire string The wire format string
--- @return table|nil payload The decoded payload, or nil on error
--- @return string|nil error Error message if decoding failed
function PayloadEncoder.decode(wire)
  if not wire or wire == "" then
    return nil, "Empty input"
  end

  -- Strip whitespace/newlines (undo chunking)
  wire = wire:gsub("%s+", "")

  -- Parse format: PREFIX:MODE:CHECKSUM:DATA
  local prefix, mode, checksum, data = wire:match("^([^:]+):([^:]+):([^:]+):(.+)$")
  if not prefix then
    return nil, "Invalid wire format"
  end

  if prefix ~= _config.prefix then
    return nil, "Unknown prefix: " .. prefix .. " (expected " .. _config.prefix .. ")"
  end

  -- Decode
  local json_str
  if mode == "RAW" then
    json_str = base64url_decode(data)
  else
    return nil, "Unknown mode: " .. mode
  end

  -- Verify checksum
  local computed = fnv1a(json_str)
  if computed ~= checksum then
    -- Warn but don't fail — data might still be usable
    io.write("[dredwork-aibridge] Checksum mismatch: expected " .. checksum .. ", got " .. computed .. "\n")
  end

  -- Parse JSON
  if _hooks.from_json then
    local ok, result = pcall(_hooks.from_json, json_str)
    if ok then return result end
    return nil, "JSON parse failed: " .. tostring(result)
  end

  -- Minimal fallback: try load as Lua (NOT safe for untrusted input)
  return nil, "No from_json hook set. Provide a JSON parser via set_hooks({ from_json = fn })."
end

-- Export utilities for reuse
PayloadEncoder.base64url_encode = base64url_encode
PayloadEncoder.base64url_decode = base64url_decode
PayloadEncoder.fnv1a = fnv1a

return PayloadEncoder
