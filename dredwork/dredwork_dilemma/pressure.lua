-- dredwork_dilemma/pressure.lua
-- Pressure: a generic representation of something demanding the player's attention.
-- Any system can emit pressures. The dilemma engine pairs them into trade-offs.

local Pressure = {}

--[[
    Pressure record:
    {
        id        = unique key (e.g. "bond:grievance:core:1", "rumor:shame:combat:f1:3")
        source    = module that generated it ("bonds", "rumor", "body", "claim", "combat")
        category  = broad type ("relationship", "reputation", "survival", "identity", "conflict")
        urgency   = 0-100 (how soon this explodes if ignored)
        label     = short display label ("Horg's Broken Contract")
        summary   = one-line description for the player
        subject   = who/what is at the center (name string)
        tags      = { "grievance", "hostile", ... } for pairing logic
        address   = what happens if the player spends attention on this
        neglect   = what happens if the player ignores this
    }

    address/neglect are effect specs:
    {
        narrative = "What the player sees",
        effects   = { shadow = {}, bond_effect = {}, rumor_effect = {}, body = {}, claim = {} },
    }
]]

function Pressure.create(spec)
    if not spec or not spec.id then return nil end
    return {
        id = spec.id,
        source = spec.source or "unknown",
        category = spec.category or "survival",
        urgency = math.max(0, math.min(100, spec.urgency or 50)),
        label = spec.label or "A Pressure",
        summary = spec.summary or "Something demands attention.",
        subject = spec.subject or "unknown",
        tags = spec.tags or {},
        address = spec.address or {
            narrative = "You spent attention here.",
            effects = {},
        },
        neglect = spec.neglect or {
            narrative = "This was left to fester.",
            effects = {},
        },
    }
end

function Pressure.has_tag(pressure, tag)
    if not pressure or not pressure.tags then return false end
    for _, t in ipairs(pressure.tags) do
        if t == tag then return true end
    end
    return false
end

return Pressure
