-- dredwork Signals — Verification System
-- Vague signals can be investigated to become clear.
-- The gameplay loop: observe → suspect → verify → act.
-- Players who verify are slower but more precise.
-- Players who act on vague signals sometimes get it wrong.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Verification = {}

--- Create a pending verification for a vague signal.
---@param signal table the vague signal
---@param day number current day
---@return table verification record
function Verification.create(signal, day)
    return {
        signal = signal,
        created_day = day,
        status = "unverified",  -- unverified, verified_true, verified_false, expired
        verification_method = nil,  -- how it was verified (investigate, ask, observe)
        clear_text = nil,  -- filled when verified
    }
end

--- Attempt to verify a signal.
---@param verification table the verification record
---@param method string "investigate", "ask_someone", "observe_directly", "spy"
---@param actor_affinity number the actor's affinity score for this signal's domain
---@return boolean success
---@return string result_text
function Verification.attempt(verification, method, actor_affinity)
    if verification.status ~= "unverified" then
        return false, "Already resolved."
    end

    -- Base success chance depends on method and affinity
    local base_chance = {
        investigate      = 0.5,
        ask_someone      = 0.4,
        observe_directly = 0.6,
        spy              = 0.55,
    }

    local chance = (base_chance[method] or 0.4) + (actor_affinity or 30) / 200
    chance = Math.clamp(chance, 0.1, 0.9)

    if RNG.chance(chance) then
        -- Verification succeeds — signal was real
        verification.status = "verified_true"
        verification.verification_method = method

        local method_text = {
            investigate      = "Your investigation confirms it. The signs were real.",
            ask_someone      = "A trusted source confirms what you suspected.",
            observe_directly = "You see it with your own eyes. No doubt now.",
            spy              = "Your agent returns with proof. It's true.",
        }

        return true, method_text[method] or "Confirmed."
    else
        -- Verification fails — could mean the signal was false OR you just didn't find proof
        if RNG.chance(0.3) then
            -- Signal was actually false — a misread
            verification.status = "verified_false"
            verification.verification_method = method

            local false_text = {
                investigate      = "You dig deeper and find nothing. The original impression was wrong — or someone covered their tracks.",
                ask_someone      = "Nobody confirms it. Either they're lying, or you misread the situation.",
                observe_directly = "You watch carefully and see nothing to support your suspicion. A false alarm.",
                spy              = "Your agent finds no evidence. Either it was nothing, or they're better at hiding than you are at finding.",
            }

            return false, false_text[method] or "Nothing found."
        else
            -- Inconclusive — couldn't verify either way
            return false, "You couldn't confirm or deny it. The uncertainty remains."
        end
    end
end

--- Check if a verification has expired (signals older than 30 days lose relevance).
function Verification.is_expired(verification, current_day)
    return (current_day - (verification.created_day or 0)) > 30
end

--- Get verification methods available based on signal type and location.
function Verification.get_methods(signal, current_location_type)
    local methods = {}

    -- Always available
    table.insert(methods, { id = "observe_directly", label = "Look closer", description = "Pay more attention to this yourself." })

    -- Location-dependent methods
    if current_location_type == "tavern" or current_location_type == "market" then
        table.insert(methods, { id = "ask_someone", label = "Ask around", description = "See if others have noticed the same thing." })
    end

    if current_location_type == "court" or current_location_type == "home" then
        table.insert(methods, { id = "investigate", label = "Investigate", description = "Dedicate time and resources to finding the truth." })
    end

    if current_location_type == "tavern" or current_location_type == "dungeon" then
        table.insert(methods, { id = "spy", label = "Send a spy", description = "Pay someone to look into it for you." })
    end

    return methods
end

return Verification
