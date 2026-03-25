-- dredwork Narrative — Template System
-- Data-driven text templates with variable substitution and conditional suffixes.

local RNG = require("dredwork_core.rng")

local Templates = {}

local _registry = {}

--------------------------------------------------------------------------------
-- Template Rendering
--------------------------------------------------------------------------------

--- Substitute {var} placeholders in a string.
local function substitute(text, vars)
    return text:gsub("{([%w_]+)}", function(key)
        return vars[key] or ("{" .. key .. "}")
    end)
end

--- Render a template by ID.
---@param template_id string
---@param vars table variable substitutions
---@param conditions table|nil set of active condition flags { high_unrest = true, ... }
---@return string|nil rendered text
---@return table|nil template definition
function Templates.render(template_id, vars, conditions)
    local tmpl = _registry[template_id]
    if not tmpl then return nil, nil end

    -- Pick a random variation
    local base
    if type(tmpl.text) == "table" then
        base = RNG.pick(tmpl.text)
    elseif type(tmpl.text) == "string" then
        base = tmpl.text
    else
        return nil, tmpl
    end

    -- Substitute variables
    local result = substitute(base, vars or {})

    -- Apply conditional suffixes
    if tmpl.suffixes and conditions then
        for _, suffix in ipairs(tmpl.suffixes) do
            if conditions[suffix.condition] then
                result = result .. substitute(suffix.text, vars or {})
            end
        end
    end

    return result, tmpl
end

--- Render from a raw text array (no registry lookup).
---@param text_array table array of string variations
---@param vars table
---@return string
function Templates.render_raw(text_array, vars)
    local base = RNG.pick(text_array) or ""
    return substitute(base, vars or {})
end

--- Get a raw template definition.
function Templates.get(template_id)
    return _registry[template_id]
end

--- Register a template (or override an existing one).
function Templates.register(tmpl)
    if tmpl and tmpl.id then
        _registry[tmpl.id] = tmpl
    end
end

--- Register many templates at once.
function Templates.register_batch(templates)
    for _, tmpl in ipairs(templates) do
        Templates.register(tmpl)
    end
end

--------------------------------------------------------------------------------
-- Built-in Templates
--------------------------------------------------------------------------------

Templates.register_batch({
    -- Event: Famine / Economic Scarcity
    {
        id = "event_scarcity_rising",
        category = "economy",
        tags = {"famine", "economy"},
        text = {
            "The granaries of {region} grow thin. The price of bread climbs beyond what common folk can bear.",
            "Hunger creeps into {region}. Markets thin, children grow gaunt, and whispers grow louder.",
            "Merchants in {region} hoard what grain remains. The poor go without.",
        },
        suffixes = {
            { condition = "high_unrest", text = " The people will not endure this quietly." },
            { condition = "has_rival", text = " {rival_name} watches from across the border, waiting." },
        },
        priority = 70,
        display_hint = "panel",
        cooldown_days = 60,
    },

    -- Event: Rebellion
    {
        id = "event_rebellion",
        category = "politics",
        tags = {"rebellion", "politics"},
        text = {
            "The streets erupt. What began as discontent has become open revolt against the rule of {lineage_name}.",
            "Rebellion. The word spreads like wildfire through {region}. Barricades rise in the market squares.",
            "It has come to this. The people of {region} have taken up arms against their rulers.",
        },
        suffixes = {
            { condition = "low_military", text = " The garrison is stretched dangerously thin." },
            { condition = "high_corruption", text = " Even the guard captains have divided loyalties." },
        },
        priority = 95,
        display_hint = "fullscreen",
        cooldown_days = 180,
    },

    -- Event: Criminal Sentenced
    {
        id = "event_criminal_sentenced",
        category = "crime",
        tags = {"crime", "justice"},
        text = {
            "A criminal has been hauled before the magistrate and sentenced to the dungeons.",
            "Justice is served — or at least, punishment is dealt. Another soul enters the {facility_name}.",
            "The guards drag another convicted wretch to the {facility_name}. The crowd jeers.",
        },
        priority = 40,
        display_hint = "toast",
        cooldown_days = 30,
    },

    -- Event: Match Completed
    {
        id = "event_match_completed",
        category = "sports",
        tags = {"sports"},
        text = {
            "The crowd roars as the match concludes. The victors are carried on shoulders through the streets.",
            "Another match in the books. The arena empties, but the arguments in the taverns are only beginning.",
            "The final whistle sounds. Champions are crowned and losers slink into the shadows.",
        },
        priority = 35,
        display_hint = "toast",
        cooldown_days = 15,
    },

    -- Event: Peril Strike
    {
        id = "event_peril_strike",
        category = "peril",
        tags = {"disaster", "peril"},
        text = {
            "Disaster strikes {region}! {peril_name} descends without warning.",
            "A terrible {peril_name} has befallen {region}. The damage is already mounting.",
            "The skies darken over {region}. {peril_name} has arrived.",
        },
        suffixes = {
            { condition = "low_gold", text = " The treasury is too depleted to mount a proper response." },
        },
        priority = 85,
        display_hint = "panel",
        cooldown_days = 90,
    },

    -- Event: Legitimacy Shift (Rumor impact)
    {
        id = "event_legitimacy_drop",
        category = "politics",
        tags = {"legitimacy", "rumor"},
        text = {
            "Scandalous whispers erode the standing of {lineage_name}. The court mutters behind closed doors.",
            "A wave of rumor has damaged the reputation of the ruling house. Trust is harder to earn than to lose.",
        },
        priority = 55,
        display_hint = "toast",
        cooldown_days = 45,
    },
    {
        id = "event_legitimacy_rise",
        category = "politics",
        tags = {"legitimacy", "rumor"},
        text = {
            "Tales of the {lineage_name}'s deeds spread through the land. The people's faith in their rulers grows.",
            "Praise echoes through the markets. The name of {lineage_name} is spoken with renewed respect.",
        },
        priority = 50,
        display_hint = "toast",
        cooldown_days = 45,
    },

    -- Event: Sports Victory
    {
        id = "event_sports_victory",
        category = "sports",
        tags = {"sports", "victory"},
        text = {
            "Victory! The champions parade through {region} to the adoration of the crowd.",
            "The people celebrate. A sports victory lifts the spirits of the realm.",
        },
        priority = 40,
        display_hint = "toast",
        cooldown_days = 15,
    },

    -- Chain: Famine Arc
    {
        id = "chain_famine_buildup",
        category = "chain",
        tags = {"famine", "economy", "chain"},
        text = {
            "Food prices have been climbing steadily in {region}. The poor are the first to feel it.",
            "The harvest was thin this season. Merchants speak of lean months ahead.",
        },
        priority = 60,
        display_hint = "toast",
    },
    {
        id = "chain_famine_crisis",
        category = "chain",
        tags = {"famine", "economy", "chain"},
        text = {
            "The famine deepens. In {region}, people fight over scraps. The markets have nothing left to sell.",
            "Starvation has taken hold. Bodies are found in the alleys of {region} each morning.",
        },
        priority = 80,
        display_hint = "panel",
    },
    {
        id = "chain_famine_climax",
        category = "chain",
        tags = {"famine", "economy", "chain"},
        text = {
            "The hunger has broken the people's patience. Riots sweep through {region}. Granaries are stormed.",
            "This is no longer mere hardship — it is a crisis. {region} teeters on the edge of total collapse.",
        },
        priority = 95,
        display_hint = "fullscreen",
    },
    {
        id = "chain_famine_resolution",
        category = "chain",
        tags = {"famine", "economy", "chain"},
        text = {
            "At last, the worst has passed. New supplies reach {region} and prices begin to fall. The scars remain.",
            "The famine ends — not with celebration, but with exhausted relief. {region} will recover, slowly.",
        },
        priority = 70,
        display_hint = "panel",
    },

    -- Chain: Plague Arc
    {
        id = "chain_plague_onset",
        category = "chain",
        tags = {"plague", "peril", "chain"},
        text = {
            "A sickness spreads through {region}. The healers are overwhelmed.",
            "Coughing. Fever. The signs are unmistakable — plague has come to {region}.",
        },
        priority = 75,
        display_hint = "panel",
    },
    {
        id = "chain_plague_peak",
        category = "chain",
        tags = {"plague", "peril", "chain"},
        text = {
            "The death toll mounts. Entire households are sealed. The streets of {region} are empty but for the burial carts.",
            "The plague shows no sign of abating. Fear rules {region} now, more than any lord or law.",
        },
        priority = 90,
        display_hint = "fullscreen",
    },
    {
        id = "chain_plague_waning",
        category = "chain",
        tags = {"plague", "peril", "chain"},
        text = {
            "The plague loosens its grip. Fewer fall sick each day. {region} begins to breathe again.",
            "The worst is over. The survivors emerge, blinking, into a changed world.",
        },
        priority = 65,
        display_hint = "panel",
    },

    -- Chain: Rebellion Arc
    {
        id = "chain_unrest_rising",
        category = "chain",
        tags = {"unrest", "politics", "chain"},
        text = {
            "Discontent simmers in {region}. Pamphlets appear on walls. Meetings are held in dark corners.",
            "The mood in {region} has shifted. People speak openly of grievances once whispered.",
        },
        priority = 60,
        display_hint = "toast",
    },
    {
        id = "chain_unrest_boiling",
        category = "chain",
        tags = {"unrest", "politics", "chain"},
        text = {
            "The unrest can no longer be ignored. Demonstrations block the thoroughfares of {region}. The guard watches nervously.",
            "Tensions in {region} have reached a breaking point. One spark could ignite it all.",
        },
        priority = 80,
        display_hint = "panel",
    },
    {
        id = "chain_unrest_resolved",
        category = "chain",
        tags = {"unrest", "politics", "chain"},
        text = {
            "The tensions have eased — for now. Whether through reform or force, order returns to {region}.",
            "Calm returns to {region}. But memory is long, and the root causes remain.",
        },
        priority = 60,
        display_hint = "panel",
    },

    -- Year/Generation Summaries
    {
        id = "summary_year",
        category = "summary",
        tags = {"summary"},
        text = {
            "Year {year} draws to a close. {lineage_name} endures.",
            "Another year passes for {lineage_name}. The wheel turns.",
            "The year {year} is consigned to memory. What comes next, none can say.",
        },
        priority = 45,
        display_hint = "panel",
    },
    {
        id = "summary_generation",
        category = "summary",
        tags = {"summary", "generation"},
        text = {
            "A generation has passed. The world {lineage_name} knew is not the world their children will inherit.",
            "The torch passes. Generation {generation} begins. The old ways fade; new ones take root.",
            "Twenty-five years gone. The elders who remember the old days grow fewer. A new generation rises.",
        },
        priority = 85,
        display_hint = "fullscreen",
    },
})

return Templates
