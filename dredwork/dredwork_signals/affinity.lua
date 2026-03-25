-- dredwork Signals — Affinity System
-- Each character is attuned to certain domains and blind to others.
-- Affinity shifts based on what you DO — spend time at the tavern, crime perception rises.
-- Your perception is trained by living your life.

local Math = require("dredwork_core.math")

local Affinity = {}

--- Signal domains that affinity tracks.
Affinity.DOMAINS = {
    "economy", "politics", "military", "crime", "religion",
    "nature", "social", "domestic", "espionage", "peril",
}

--- Create a fresh affinity component from personality + role.
---@param personality table { PER_BLD, PER_OBS, PER_LOY, PER_CUR, ... }
---@param role string|nil current role (general, priest, treasurer, etc.)
---@return table affinity component { domain = 0-100, ... }
function Affinity.create(personality, role)
    local p = personality or {}
    local function get(id)
        local v = p[id]; if type(v) == "table" then return v.value or 50 end; return v or 50
    end

    -- Start with baseline derived from personality
    local obs = get("PER_OBS")
    local cur = get("PER_CUR")
    local bld = get("PER_BLD")
    local loy = get("PER_LOY")
    local crm = get("PER_CRM")
    local vol = get("PER_VOL")
    local pri = get("PER_PRI")
    local ada = get("PER_ADA")

    local a = {
        economy   = 30 + (obs - 50) * 0.3 + (cur - 50) * 0.2,
        politics  = 30 + (obs - 50) * 0.3 + (pri - 50) * 0.3,
        military  = 30 + (bld - 50) * 0.4 + (vol - 50) * 0.1,
        crime     = 20 + (obs - 50) * 0.3 + (crm - 50) * 0.3,
        religion  = 25 + (loy - 50) * 0.2 + (ada - 50) * -0.2,
        nature    = 20 + (cur - 50) * 0.3 + (ada - 50) * 0.2,
        social    = 35 + (loy - 50) * 0.3 + (obs - 50) * 0.2,
        domestic  = 30 + (loy - 50) * 0.2,
        espionage = 15 + (obs - 50) * 0.4 + (crm - 50) * 0.2,
        peril     = 30 + (obs - 50) * 0.2 + (cur - 50) * 0.1,
    }

    -- Role boosts specific domains significantly
    local role_boosts = {
        general      = { military = 30, politics = 10 },
        spymaster    = { espionage = 35, crime = 20, social = 10 },
        treasurer    = { economy = 30, crime = 10 },
        priest       = { religion = 35, social = 10 },
        steward      = { domestic = 25, economy = 15 },
        ambassador   = { politics = 25, social = 20 },
        judge        = { crime = 25, politics = 15 },
        master_hunter = { nature = 35, peril = 15 },
        ruler        = { politics = 15, military = 10, economy = 10, social = 10 },
    }

    if role and role_boosts[role] then
        for domain, boost in pairs(role_boosts[role]) do
            a[domain] = (a[domain] or 30) + boost
        end
    end

    -- Clamp all values
    for domain, val in pairs(a) do
        a[domain] = Math.clamp(val, 0, 100)
    end

    return a
end

--- Shift affinity based on an action the character performed.
--- Spending time at a location or performing actions in a domain trains perception.
---@param affinity table the affinity component
---@param domain string which domain was exercised
---@param amount number how much to shift (default 1)
function Affinity.train(affinity, domain, amount)
    amount = amount or 1
    if affinity[domain] then
        affinity[domain] = Math.clamp(affinity[domain] + amount, 0, 100)
    end
end

--- Shift affinity based on location type visited.
function Affinity.train_from_location(affinity, location_type)
    local location_domains = {
        home     = { "domestic" },
        court    = { "politics", "social" },
        market   = { "economy" },
        barracks = { "military" },
        temple   = { "religion" },
        tavern   = { "crime", "social" },
        gate     = { "military", "peril" },
        wilds    = { "nature", "peril" },
        dungeon  = { "crime", "espionage" },
        road     = { "peril" },
    }

    local domains = location_domains[location_type]
    if domains then
        for _, domain in ipairs(domains) do
            Affinity.train(affinity, domain, 0.5)
        end
    end
end

--- Shift affinity based on an interaction performed.
function Affinity.train_from_interaction(affinity, interaction_category)
    local category_domains = {
        social     = { "social" },
        hostile    = { "military", "crime" },
        diplomatic = { "politics", "social" },
        espionage  = { "espionage", "crime" },
        governance = { "politics" },
        military   = { "military" },
        spiritual  = { "religion" },
        bond       = { "social", "nature" },
        command    = { "military" },
        domestic   = { "domestic" },
        legacy     = { "politics" },
        discovery  = { "nature", "peril" },
        personal   = { "domestic" },
        action     = {},
        movement   = { "peril" },
    }

    local domains = category_domains[interaction_category]
    if domains then
        for _, domain in ipairs(domains) do
            Affinity.train(affinity, domain, 0.3)
        end
    end
end

--- Get the clarity level for a signal based on affinity.
---@param affinity table the affinity component
---@param signal_domain string which domain the signal belongs to
---@return string "clear" | "vague" | "missed"
---@return number score (0-100) for fine-grained use
function Affinity.get_clarity(affinity, signal_domain)
    local score = affinity[signal_domain] or 0

    -- Add small random variance so perception isn't deterministic
    score = score + (math.random() - 0.5) * 15

    if score >= 50 then
        return "clear", score
    elseif score >= 25 then
        return "vague", score
    else
        return "missed", score
    end
end

--- Natural decay: unused domains slowly fade (monthly).
function Affinity.decay(affinity)
    for domain, val in pairs(affinity) do
        if type(val) == "number" and val > 20 then
            affinity[domain] = Math.clamp(val - 0.3, 0, 100)
        end
    end
end

return Affinity
