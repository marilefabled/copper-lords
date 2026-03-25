
-- Copper Lords — Game Logic Module
local RNG = require("dredwork_core.rng")
local Math = require("dredwork_core.math")

local CopperLords = {}

-- ─── Trait Definitions ───────────────────────────────────────────────────────
local ALL_TRAITS = {
    { name = "Greedy",   desc = "More coins, more heat",         mod = { coins = 1.3, suspicion = 1.2 } },
    { name = "Cunning",  desc = "Better odds, lower profile",    mod = { win_chance = 0.08, suspicion = 0.7 } },
    { name = "Clumsy",   desc = "Worse odds, draws attention",   mod = { win_chance = -0.1, suspicion = 1.5 } },
    { name = "Steady",   desc = "Recovers from fatigue faster",  mod = { fatigue = 0.7 } },
    { name = "Ghost",    desc = "Nearly invisible to the Watch",  mod = { suspicion = 0.4 } },
    { name = "Lucky",    desc = "Fortune favors the bold",        mod = { luck = 2, win_chance = 0.05 } },
    { name = "Brawler",  desc = "Wins fights, loses friends",     mod = { win_chance = 0.06, suspicion = 1.3 } },
    { name = "Silver Tongue", desc = "Talks their way out",       mod = { suspicion = 0.6, win_chance = 0.03 } },
    { name = "Reckless", desc = "High risk, high reward",         mod = { coins = 1.5, suspicion = 1.6, fatigue = 1.3 } },
    { name = "Patient",  desc = "Slow and safe",                  mod = { fatigue = 0.5, coins = 0.8 } }
}

-- ─── Hireable Grifter Pool ──────────────────────────────────────────────────
local HIRE_POOL = {
    { name = "Dace",   stats = { sleight = 4, nerve = 2, read = 1, luck = 0 }, trait_idx = 7 },
    { name = "Wren",   stats = { sleight = 1, nerve = 5, read = 3, luck = 1 }, trait_idx = 5 },
    { name = "Sable",  stats = { sleight = 3, nerve = 3, read = 3, luck = 0 }, trait_idx = 8 },
    { name = "Marten", stats = { sleight = 6, nerve = 0, read = 0, luck = 2 }, trait_idx = 9 },
    { name = "Plover", stats = { sleight = 2, nerve = 3, read = 4, luck = 1 }, trait_idx = 10 },
}

-- ─── Item Definitions ───────────────────────────────────────────────────────
local SHOP_ITEMS = {
    { id = "weighted_coin", name = "Weighted Coin", desc = "+10% win chance", cost = 80, mod = { win_chance = 0.10 } },
    { id = "marked_deck",   name = "Marked Deck",   desc = "+8% win, +15% suspicion", cost = 60, mod = { win_chance = 0.08, suspicion = 1.15 } },
    { id = "silk_gloves",   name = "Silk Gloves",    desc = "-30% suspicion gain", cost = 120, mod = { suspicion = 0.7 } },
    { id = "lucky_charm",   name = "Lucky Charm",    desc = "+5% win, -20% fatigue", cost = 150, mod = { win_chance = 0.05, fatigue = 0.8 } },
    { id = "bribe_kit",     name = "Bribe Kit",      desc = "Halves bribe costs", cost = 200, mod = { bribe_discount = 0.5 } },
}

-- ─── Constants ──────────────────────────────────────────────────────────────
local WIN_TARGET = 5000
local BRIBE_BASE_COST = 60
local HIRE_BASE_COST = 75
local HIRE_COST_SCALE = 1.5 -- each hire costs more

function CopperLords.init(engine)
    local gs = engine.game_state
    gs.coins = 100
    gs.day = 1
    gs.game_over = false
    gs.game_over_reason = ""
    gs.win = false
    gs.win_target = WIN_TARGET
    gs.paused = false

    -- Shop state
    gs.shop = {
        items = {},
        hire_pool = {},
        hire_cost = HIRE_BASE_COST,
        bribe_base = BRIBE_BASE_COST,
    }
    for _, item in ipairs(SHOP_ITEMS) do
        table.insert(gs.shop.items, {
            id = item.id, name = item.name, desc = item.desc,
            cost = item.cost, mod = item.mod, sold = false
        })
    end
    -- Build available hires
    for i, h in ipairs(HIRE_POOL) do
        table.insert(gs.shop.hire_pool, {
            index = i,
            name = h.name,
            stats = { sleight = h.stats.sleight, nerve = h.stats.nerve, read = h.stats.read, luck = h.stats.luck },
            trait = ALL_TRAITS[h.trait_idx],
            hired = false,
            cost = math.floor(HIRE_BASE_COST * (HIRE_COST_SCALE ^ (i - 1)))
        })
    end

    gs.grifters = {
        {
            id = 1, name = "Finch",
            stats = { sleight = 3, nerve = 2, read = 1, luck = 0 },
            traits = { ALL_TRAITS[2] }, -- Cunning
            items = {},
            fatigue = 0, suspicion = 0,
            settings = { cheat = 0.4, hours = 0.7 },
            status = "active",
            location_id = "district_1",
            lifetime_coins = 0, arrests = 0
        },
        {
            id = 2, name = "Vesper",
            stats = { sleight = 2, nerve = 4, read = 2, luck = 1 },
            traits = { ALL_TRAITS[4] }, -- Steady
            items = {},
            fatigue = 0, suspicion = 0,
            settings = { cheat = 0.2, hours = 0.6 },
            status = "active",
            location_id = "district_1",
            lifetime_coins = 0, arrests = 0
        },
        {
            id = 3, name = "Gully",
            stats = { sleight = 5, nerve = 1, read = 0, luck = 0 },
            traits = { ALL_TRAITS[1] }, -- Greedy
            items = {},
            fatigue = 0, suspicion = 0,
            settings = { cheat = 0.7, hours = 0.5 },
            status = "active",
            location_id = "district_2",
            lifetime_coins = 0, arrests = 0
        }
    }

    gs.next_grifter_id = 4

    gs.districts = {
        {
            id = "district_1",
            name = "The Gilded Market",
            wealth = 600, base_wealth = 600,
            law = 12, base_law = 12,
            skill_avg = 1, base_skill = 1,
            heat = 0,
            flavor = "Plump purses and distracted merchants."
        },
        {
            id = "district_2",
            name = "The Shadow Alley",
            wealth = 150, base_wealth = 150,
            law = 4, base_law = 4,
            skill_avg = 4, base_skill = 4,
            heat = 0,
            flavor = "Hard-eyed cutthroats and rigged dice."
        },
        {
            id = "district_3",
            name = "The High Roller Row",
            wealth = 2500, base_wealth = 2500,
            law = 30, base_law = 30,
            skill_avg = 6, base_skill = 6,
            heat = 0,
            flavor = "Silk-clad nobles with sharp wits."
        }
    }

    engine:on("STEP", function(context)
        if not gs.game_over and not gs.paused then
            CopperLords.tick(engine)
        end
    end)

    return CopperLords
end

-- ─── Difficulty Scaling ─────────────────────────────────────────────────────
function CopperLords.apply_scaling(engine)
    local gs = engine.game_state
    local day = gs.day
    -- Law ramps up every 5 days
    local law_scale = 1 + (day * 0.015)
    -- NPCs get smarter every 10 days
    local skill_scale = math.floor(day / 10) * 0.5

    for _, d in ipairs(gs.districts) do
        d.law = Math.clamp(math.floor(d.base_law * law_scale), d.base_law, 80)
        d.skill_avg = Math.clamp(d.base_skill + skill_scale, d.base_skill, 10)
    end
end

-- ─── Win Rate Estimate ──────────────────────────────────────────────────────
function CopperLords.estimate_win_rate(engine, grifter)
    local gs = engine.game_state
    local district = nil
    for _, d in ipairs(gs.districts) do
        if d.id == grifter.location_id then district = d; break end
    end
    if not district then return 0.5 end

    local win_chance = 0.5
    local cheat_intensity = grifter.settings.cheat or 0

    for _, trait in ipairs(grifter.traits or {}) do
        if trait.mod.win_chance then win_chance = win_chance + trait.mod.win_chance end
    end
    for _, item in ipairs(grifter.items or {}) do
        if item.mod and item.mod.win_chance then win_chance = win_chance + item.mod.win_chance end
    end

    local skill_bias = (grifter.stats.sleight - district.skill_avg) * 0.06
    local luck_bonus = (grifter.stats.luck or 0) * 0.02
    local cheat_bias = cheat_intensity * 0.45
    local fatigue_penalty = grifter.fatigue * 0.3
    local heat_penalty = (district.heat / 100) * 0.2

    return Math.clamp(win_chance + skill_bias + luck_bonus + cheat_bias - fatigue_penalty - heat_penalty, 0.05, 0.98)
end

-- ─── Main Tick ──────────────────────────────────────────────────────────────
function CopperLords.tick(engine)
    local gs = engine.game_state
    gs.day = gs.day + 1

    -- Difficulty scaling
    CopperLords.apply_scaling(engine)

    -- Random Daily Event (25% base, scales up slightly)
    local event_chance = Math.clamp(0.25 + (gs.day * 0.003), 0.25, 0.5)
    if RNG.chance(event_chance) then
        CopperLords.trigger_event(engine)
    end

    for _, district in ipairs(gs.districts) do
        district.heat = Math.clamp(district.heat - 2, 0, 100)
    end

    local all_jailed = true
    for _, grifter in ipairs(gs.grifters) do
        if grifter.status == "active" then
            all_jailed = false
            local encounters = math.max(1, math.floor(grifter.settings.hours * 5))
            local day_coins = 0
            local day_wins = 0
            local day_losses = 0
            local day_flavor = ""
            local sus_before = grifter.suspicion

            for i = 1, encounters do
                local result = CopperLords.resolve_encounter(engine, grifter)
                if result then
                    if result.win then
                        day_coins = day_coins + result.amount
                        day_wins = day_wins + 1
                    else
                        day_coins = day_coins - result.amount
                        day_losses = day_losses + 1
                    end
                    day_flavor = result.flavor
                end
                if grifter.status ~= "active" then break end
            end

            -- One summary event per grifter per day
            if day_wins + day_losses > 0 and grifter.status == "active" then
                local district_name = grifter.location_id
                for _, d in ipairs(gs.districts) do
                    if d.id == grifter.location_id then district_name = d.name; break end
                end
                engine:push_ui_event("DAY_SUMMARY", {
                    grifter = grifter.name,
                    district = district_name,
                    wins = day_wins,
                    losses = day_losses,
                    net = day_coins,
                    suspicion_delta = math.floor((grifter.suspicion - sus_before) * 100),
                    flavor = day_flavor
                })
            end

            -- Fatigue recovery at end of day
            local fatigue_rec = 0.08
            for _, trait in ipairs(grifter.traits or {}) do
                if trait.mod.fatigue then fatigue_rec = fatigue_rec / trait.mod.fatigue end
            end
            for _, item in ipairs(grifter.items or {}) do
                if item.mod and item.mod.fatigue then fatigue_rec = fatigue_rec / item.mod.fatigue end
            end
            grifter.fatigue = Math.clamp(grifter.fatigue - fatigue_rec, 0, 1)

            -- Suspicion natural decay (small)
            grifter.suspicion = Math.clamp(grifter.suspicion - 0.02, 0, 1)
        elseif grifter.status == "jailed" then
            grifter.suspicion = Math.clamp(grifter.suspicion - 0.08, 0, 1)
            if grifter.suspicion <= 0 then
                grifter.status = "active"
                grifter.fatigue = 0.3
                engine:push_ui_event("RELEASED", { grifter = grifter.name })
            end
        end
    end

    -- Compute win rates for UI
    for _, grifter in ipairs(gs.grifters) do
        grifter.win_rate = CopperLords.estimate_win_rate(engine, grifter)
    end

    -- Check win/loss
    if gs.coins >= gs.win_target then
        gs.game_over = true
        gs.win = true
        gs.game_over_reason = "You've amassed " .. gs.coins .. " copper. The city is yours."
        engine:push_ui_event("GAME_OVER", { win = true, reason = gs.game_over_reason })
    elseif all_jailed and gs.coins < BRIBE_BASE_COST then
        gs.game_over = true
        gs.win = false
        gs.game_over_reason = "All your grifters rot in jail and the coffers are empty."
        engine:push_ui_event("GAME_OVER", { win = false, reason = gs.game_over_reason })
    end
end

-- ─── Events ─────────────────────────────────────────────────────────────────
function CopperLords.trigger_event(engine)
    local gs = engine.game_state
    local events = {
        { name = "ROYAL_VISIT", text = "The King's procession passes through. Guards everywhere.", action = function()
            for _, d in ipairs(gs.districts) do
                d.base_law = Math.clamp(d.base_law + 3, 0, 60)
            end
        end },
        { name = "MERCANTILE_BOOM", text = "A rich caravan arrives. District wealth spikes!", action = function()
            local d = RNG.pick(gs.districts)
            d.base_wealth = math.floor(d.base_wealth * 1.4)
            d.wealth = d.base_wealth
        end },
        { name = "CITY_WATCH_STRIKE", text = "The Watch argues over pay. Security is lax.", action = function()
            for _, d in ipairs(gs.districts) do
                d.heat = Math.clamp(d.heat - 15, 0, 100)
                d.base_law = Math.clamp(d.base_law - 2, 2, 100)
            end
        end },
        { name = "INFORMANT_TIP", text = "A snitch whispered in the Watch's ear.", action = function()
            local active = {}
            for _, g in ipairs(gs.grifters) do
                if g.status == "active" then table.insert(active, g) end
            end
            if #active > 0 then
                local g = RNG.pick(active)
                g.suspicion = Math.clamp(g.suspicion + 0.25, 0, 1)
                engine:push_ui_event("SUSPICION_SPIKE", { grifter = g.name, amount = 25 })
            end
        end },
        { name = "FOGGY_NIGHT", text = "Thick mist blankets the streets. Harder to catch.", action = function()
            for _, d in ipairs(gs.districts) do
                d.heat = Math.clamp(d.heat - 25, 0, 100)
            end
        end },
        { name = "MARKET_CRASH", text = "A merchant guild collapses. Purses tighten.", action = function()
            local d = RNG.pick(gs.districts)
            d.base_wealth = math.floor(d.base_wealth * 0.7)
            d.wealth = d.base_wealth
        end },
        { name = "FESTIVAL", text = "Street festival! Crowds make easy marks.", action = function()
            local d = RNG.pick(gs.districts)
            d.wealth = math.floor(d.wealth * 1.8)
            d.heat = Math.clamp(d.heat - 10, 0, 100)
        end },
        { name = "CRACKDOWN", text = "The Watch launches a district sweep.", action = function()
            local d = RNG.pick(gs.districts)
            d.heat = Math.clamp(d.heat + 40, 0, 100)
            d.base_law = Math.clamp(d.base_law + 5, 0, 60)
        end },
    }
    local event = RNG.pick(events)
    event.action()
    engine:push_ui_event("EVENT", { title = event.name, text = event.text })
end

-- ─── Encounter Resolution ───────────────────────────────────────────────────
-- Returns { win, amount, flavor } or nil. Mutates grifter/district state.
-- Does NOT push UI events (the tick batches them).
function CopperLords.resolve_encounter(engine, grifter)
    local gs = engine.game_state
    local district = nil
    for _, d in ipairs(gs.districts) do
        if d.id == grifter.location_id then district = d; break end
    end
    if not district then return nil end

    local win_chance = 0.5
    local cheat_intensity = grifter.settings.cheat or 0
    local suspicion_mod = 1.0
    local coin_mod = 1.0

    -- Apply trait modifiers (READ-ONLY — no mutation)
    local luck_bonus = (grifter.stats.luck or 0) * 0.02
    for _, trait in ipairs(grifter.traits or {}) do
        if trait.mod.win_chance then win_chance = win_chance + trait.mod.win_chance end
        if trait.mod.suspicion then suspicion_mod = suspicion_mod * trait.mod.suspicion end
        if trait.mod.coins then coin_mod = coin_mod * trait.mod.coins end
        if trait.mod.luck then luck_bonus = luck_bonus + trait.mod.luck * 0.02 end
    end

    -- Apply item modifiers
    for _, item in ipairs(grifter.items or {}) do
        if item.mod then
            if item.mod.win_chance then win_chance = win_chance + item.mod.win_chance end
            if item.mod.suspicion then suspicion_mod = suspicion_mod * item.mod.suspicion end
            if item.mod.coins then coin_mod = coin_mod * item.mod.coins end
        end
    end

    local skill_bias = (grifter.stats.sleight - district.skill_avg) * 0.06
    local cheat_bias = cheat_intensity * 0.35
    local fatigue_penalty = grifter.fatigue * 0.25
    local heat_penalty = (district.heat / 100) * 0.15

    win_chance = Math.clamp(win_chance + skill_bias + luck_bonus + cheat_bias - fatigue_penalty - heat_penalty, 0.05, 0.95)

    local roll = RNG.random()
    local win = roll < win_chance

    -- Flavor text
    local flavors_win = {
        "A simple toss.", "The coin sings.", "Textbook palm.",
        "The mark never saw it.", "Clean as copper polish.",
        "A flick of the wrist.", "Child's play."
    }
    local flavors_lose = {
        "The mark was too sharp.", "Bad read on the crowd.",
        "Fumbled the switch.", "Nerves got the better of them.",
        "The crowd turned hostile.", "An unlucky bounce."
    }
    local flavor_cheat = {
        "A brazen palm-switch.", "Swapped the coin mid-air.",
        "Palmed a double-header.", "Sleight so fast it blurred."
    }

    local flavor
    if cheat_intensity > 0.6 then
        flavor = RNG.pick(flavor_cheat)
    elseif win then
        flavor = RNG.pick(flavors_win)
    else
        flavor = RNG.pick(flavors_lose)
    end

    local amount = 0
    if win then
        amount = math.floor((1 + (district.wealth * 0.008)) * coin_mod)
        gs.coins = gs.coins + amount
        grifter.lifetime_coins = (grifter.lifetime_coins or 0) + amount

        if cheat_intensity > 0.2 then
            district.heat = Math.clamp(district.heat + (cheat_intensity * 4), 0, 100)
        end
    else
        amount = math.max(1, math.floor(district.skill_avg * 0.5))
        gs.coins = Math.clamp(gs.coins - amount, 0, 9999999)
    end

    -- Fatigue per encounter (small)
    local fatigue_gain = 0.015
    for _, trait in ipairs(grifter.traits or {}) do
        if trait.mod.fatigue then fatigue_gain = fatigue_gain * trait.mod.fatigue end
    end
    grifter.fatigue = Math.clamp(grifter.fatigue + fatigue_gain, 0, 1)

    -- Suspicion per encounter
    -- Base detection is low; cheat intensity is the main driver
    local detection = cheat_intensity * 0.06 + (district.law * 0.001) + (district.heat * 0.001)
    local mitigation = grifter.stats.nerve * 0.012
    local sus_gain = math.max(0, (detection - mitigation) * suspicion_mod)

    grifter.suspicion = Math.clamp(grifter.suspicion + sus_gain, 0, 1)

    -- Arrest check (only above threshold)
    if grifter.suspicion > 0.5 then
        local arrest_chance = (grifter.suspicion - 0.5) * (district.law / 40)
        if RNG.chance(Math.clamp(arrest_chance, 0, 0.8)) then
            grifter.status = "jailed"
            grifter.arrests = (grifter.arrests or 0) + 1
            engine:push_ui_event("ARREST", { grifter = grifter.name, district = district.name })
        end
    end

    return { win = win, amount = amount, flavor = flavor }
end

-- ─── Player Actions ─────────────────────────────────────────────────────────
function CopperLords.move_grifter(engine, grifter_id, district_id)
    local gs = engine.game_state
    for _, g in ipairs(gs.grifters) do
        if g.id == grifter_id then
            g.location_id = district_id
            -- Find district name
            local dname = district_id
            for _, d in ipairs(gs.districts) do
                if d.id == district_id then dname = d.name; break end
            end
            engine:push_ui_event("GRIFTER_MOVED", { grifter = g.name, to = dname })
            return true
        end
    end
    return false
end

function CopperLords.bribe_grifter(engine, grifter_id)
    local gs = engine.game_state
    for _, g in ipairs(gs.grifters) do
        if g.id == grifter_id and g.status == "jailed" then
            -- Calculate bribe cost
            local cost = BRIBE_BASE_COST + (g.arrests * 30)
            -- Check for bribe kit discount
            for _, item in ipairs(g.items or {}) do
                if item.mod and item.mod.bribe_discount then
                    cost = math.floor(cost * item.mod.bribe_discount)
                end
            end
            if gs.coins >= cost then
                gs.coins = gs.coins - cost
                g.status = "active"
                g.suspicion = 0.15
                g.fatigue = 0.2
                engine:push_ui_event("BRIBE", { grifter = g.name, cost = cost })
                return true, cost
            else
                return false, cost
            end
        end
    end
    return false, 0
end

function CopperLords.buy_item(engine, item_id, grifter_id)
    local gs = engine.game_state
    -- Find the shop item
    local shop_item = nil
    for _, si in ipairs(gs.shop.items) do
        if si.id == item_id and not si.sold then
            shop_item = si
            break
        end
    end
    if not shop_item then return false end
    if gs.coins < shop_item.cost then return false end

    -- Find grifter
    for _, g in ipairs(gs.grifters) do
        if g.id == grifter_id then
            gs.coins = gs.coins - shop_item.cost
            table.insert(g.items, { id = shop_item.id, name = shop_item.name, mod = shop_item.mod })
            shop_item.sold = true
            engine:push_ui_event("ITEM_BOUGHT", { grifter = g.name, item = shop_item.name, cost = shop_item.cost })
            return true
        end
    end
    return false
end

function CopperLords.hire_grifter(engine, hire_index)
    local gs = engine.game_state
    local hire = nil
    for _, h in ipairs(gs.shop.hire_pool) do
        if h.index == hire_index and not h.hired then
            hire = h
            break
        end
    end
    if not hire then return false end
    if gs.coins < hire.cost then return false end

    gs.coins = gs.coins - hire.cost
    hire.hired = true

    local new_id = gs.next_grifter_id
    gs.next_grifter_id = new_id + 1

    table.insert(gs.grifters, {
        id = new_id,
        name = hire.name,
        stats = { sleight = hire.stats.sleight, nerve = hire.stats.nerve, read = hire.stats.read, luck = hire.stats.luck },
        traits = { hire.trait },
        items = {},
        fatigue = 0, suspicion = 0,
        settings = { cheat = 0.3, hours = 0.5 },
        status = "active",
        location_id = "district_1",
        lifetime_coins = 0, arrests = 0,
        win_rate = 0.5
    })

    engine:push_ui_event("HIRED", { grifter = hire.name, cost = hire.cost })
    return true
end

function CopperLords.get_bribe_cost(engine, grifter_id)
    local gs = engine.game_state
    for _, g in ipairs(gs.grifters) do
        if g.id == grifter_id then
            local cost = BRIBE_BASE_COST + ((g.arrests or 0) * 30)
            for _, item in ipairs(g.items or {}) do
                if item.mod and item.mod.bribe_discount then
                    cost = math.floor(cost * item.mod.bribe_discount)
                end
            end
            return cost
        end
    end
    return BRIBE_BASE_COST
end

return CopperLords
