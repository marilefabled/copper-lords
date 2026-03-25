--- dredwork-aibridge: Network Sender
--- Game-side module for POSTing payloads with exponential backoff
--- and graceful fallback.
---
--- HOOKS:
---   on_status(msg)              Optional. Called with status messages during retries.
---   on_success(response_data)   Optional. Called on successful POST.
---   on_fail(reason, payload)    Optional. Called when all retries exhausted.
---   on_fallback(payload)        Optional. Called to handle fallback (e.g., clipboard).
---   parse_response(body)        Optional. Custom response parser. Default: JSON.
---   is_success(response_data)   Optional. Custom success check. Default: { success = true }.
---
--- Usage:
---   local Sender = require("dredwork-aibridge.lua.network_sender")
---   Sender.send("https://example.com/api/submit", payload_json, {
---     on_success = function(data) print("URL: " .. data.url) end,
---     on_fail = function(reason) print("Failed: " .. reason) end,
---   })

local NetworkSender = {}

-- ── Configuration ──
local _config = {
  max_retries = 3,
  backoff_ms = { 1500, 3000, 6000 },
  timeout_seconds = 300,
  content_type = "application/json",
}

--- Configure retry behavior.
--- @param opts table { max_retries, backoff_ms, timeout_seconds, content_type }
function NetworkSender.configure(opts)
  if opts.max_retries then _config.max_retries = opts.max_retries end
  if opts.backoff_ms then _config.backoff_ms = opts.backoff_ms end
  if opts.timeout_seconds then _config.timeout_seconds = opts.timeout_seconds end
  if opts.content_type then _config.content_type = opts.content_type end
end

--- Send a POST request with exponential backoff.
--- @param url string Target URL
--- @param payload string Encoded payload body (usually JSON)
--- @param hooks table Callback hooks (on_status, on_success, on_fail, on_fallback, parse_response, is_success)
function NetworkSender.send(url, payload, hooks)
  hooks = hooks or {}
  local attempt = 0

  -- Try to load a JSON parser for response parsing
  local Serializer
  pcall(function()
    Serializer = require("dredwork_genetics.serializer")
  end)

  local function try_parse(body)
    if hooks.parse_response then
      return pcall(hooks.parse_response, body)
    elseif Serializer and Serializer.from_json then
      return pcall(Serializer.from_json, body)
    end
    return false, nil
  end

  local function check_success(data)
    if hooks.is_success then
      return hooks.is_success(data)
    end
    -- Default: look for { success = true }
    return data and data.success == true
  end

  local function do_fallback(reason)
    if hooks.on_fallback then
      pcall(hooks.on_fallback, payload)
    end
    if hooks.on_fail then
      pcall(hooks.on_fail, reason, payload)
    end
  end

  local function attempt_send()
    attempt = attempt + 1

    if hooks.on_status then
      if attempt > 1 then
        pcall(hooks.on_status, "Retrying... (attempt " .. attempt .. " of " .. _config.max_retries .. ")")
      else
        pcall(hooks.on_status, "Sending...")
      end
    end

    -- Solar2D network.request
    local network = network -- Solar2D global
    if not network or not network.request then
      do_fallback("Network API not available.")
      return
    end

    network.request(url, "POST", function(event)
      if event.isError or event.status >= 400 then
        -- Retry or fail
        if attempt < _config.max_retries then
          local delay = _config.backoff_ms[attempt] or _config.backoff_ms[#_config.backoff_ms]
          if hooks.on_status then
            pcall(hooks.on_status, "Connection issue. Retrying in " .. math.floor(delay / 1000) .. "s...")
          end
          timer.performWithDelay(delay, attempt_send)
        else
          do_fallback("Connection failed after " .. _config.max_retries .. " attempts.")
        end
        return
      end

      -- Parse response
      local parseOk, responseData = try_parse(event.response)
      if parseOk and check_success(responseData) then
        if hooks.on_success then
          pcall(hooks.on_success, responseData)
        end
      else
        -- Response didn't meet success criteria
        if attempt < _config.max_retries then
          local delay = _config.backoff_ms[attempt] or _config.backoff_ms[#_config.backoff_ms]
          timer.performWithDelay(delay, attempt_send)
        else
          do_fallback("Server returned unexpected response after " .. _config.max_retries .. " attempts.")
        end
      end
    end, {
      headers = {
        ["Content-Type"] = _config.content_type,
      },
      body = payload,
      timeout = _config.timeout_seconds,
    })
  end

  attempt_send()
end

return NetworkSender
