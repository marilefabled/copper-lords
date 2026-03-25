-- dredwork Agency — Secrets
-- Entities know things other entities don't.
-- Secrets create information asymmetry. Revealed secrets change relationships.

local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local Secrets = {}

--- Create a fresh secrets component.
function Secrets.create()
    return {
        known = {},     -- { id, type, subject_id, text, severity, known_day }
        max_secrets = 10,
    }
end

--- Add a secret to an entity's knowledge.
function Secrets.learn(secrets, secret)
    -- Check for duplicate
    for _, s in ipairs(secrets.known) do
        if s.id == secret.id then return s end
    end

    local entry = {
        id = secret.id or ("secret_" .. #secrets.known),
        type = secret.type or "general",   -- embezzlement, affair, conspiracy, betrayal, crime, identity
        subject_id = secret.subject_id,     -- who is the secret about
        about_id = secret.about_id,         -- alternate: who else is involved
        text = secret.text or "A hidden truth.",
        severity = Math.clamp(secret.severity or 30, 0, 100),
        known_day = secret.known_day or 0,
    }

    table.insert(secrets.known, entry)
    while #secrets.known > secrets.max_secrets do
        -- Remove least severe
        local min_idx, min_sev = 1, 999
        for i, s in ipairs(secrets.known) do
            if s.severity < min_sev then min_idx = i; min_sev = s.severity end
        end
        table.remove(secrets.known, min_idx)
    end

    return entry
end

--- Check if entity knows a specific secret.
function Secrets.knows(secrets, secret_id)
    for _, s in ipairs(secrets.known) do
        if s.id == secret_id then return true, s end
    end
    return false
end

--- Check if entity knows ANY secret about a subject.
function Secrets.knows_about(secrets, subject_id)
    local results = {}
    for _, s in ipairs(secrets.known) do
        if s.subject_id == subject_id then table.insert(results, s) end
    end
    return #results > 0, results
end

--- Reveal a secret (called when information leaks).
--- Returns the secret data for the emitter to broadcast.
function Secrets.reveal(secrets, secret_id)
    for i, s in ipairs(secrets.known) do
        if s.id == secret_id then
            table.remove(secrets.known, i)
            return s
        end
    end
    return nil
end

--- Get the most damaging secret this entity holds (for leverage).
function Secrets.get_most_damaging(secrets)
    local worst, worst_sev = nil, 0
    for _, s in ipairs(secrets.known) do
        if s.severity > worst_sev then
            worst = s
            worst_sev = s.severity
        end
    end
    return worst
end

--- Generate a secret about an entity (factory function).
---@param about table entity the secret is about
---@param secret_type string
---@param day number
---@return table secret
function Secrets.generate(about, secret_type, day)
    local templates = {
        embezzlement = { text = "%s has been skimming from the treasury.", severity = 50 },
        affair = { text = "%s has been seen with someone outside the household.", severity = 40 },
        conspiracy = { text = "%s has been meeting with enemies of the house.", severity = 70 },
        betrayal = { text = "%s plans to betray their oath.", severity = 80 },
        crime = { text = "%s has committed crimes in the shadows.", severity = 55 },
        identity = { text = "%s is not who they claim to be.", severity = 60 },
        weakness = { text = "%s has a hidden vulnerability.", severity = 35 },
        ambition = { text = "%s secretly covets the seat of power.", severity = 45 },
    }

    local template = templates[secret_type] or templates.weakness
    return {
        id = secret_type .. "_" .. (about.id or "?") .. "_" .. (day or 0),
        type = secret_type,
        subject_id = about.id,
        text = string.format(template.text, about.name or "Someone"),
        severity = template.severity + RNG.range(-10, 10),
        known_day = day,
    }
end

return Secrets
