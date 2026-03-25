-- Dark Legacy — Chronicle Code
-- Encodes a completed run into a compact shareable code (base64url).
-- An external AI app decodes the code and generates deep literary fiction.
-- Pure Lua, zero Solar2D dependencies.

local Serializer = require("dredwork_genetics.serializer")

local ChronicleCode = {}

-- =========================================================================
-- Base64url encoder/decoder (pure Lua, no external deps)
-- =========================================================================
local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

local function base64url_encode(data)
    local out = {}
    local len = #data
    local mod = len % 3
    local padded_data = data
    if mod > 0 then
        for _ = 1, 3 - mod do
            padded_data = padded_data .. "\0"
        end
    end

    for i = 1, #padded_data, 3 do
        local a, b, c = padded_data:byte(i, i + 2)
        local n = a * 65536 + b * 256 + c

        local c1 = math.floor(n / 262144) % 64
        local c2 = math.floor(n / 4096) % 64
        local c3 = math.floor(n / 64) % 64
        local c4 = n % 64

        out[#out + 1] = b64chars:sub(c1 + 1, c1 + 1)
        out[#out + 1] = b64chars:sub(c2 + 1, c2 + 1)
        out[#out + 1] = b64chars:sub(c3 + 1, c3 + 1)
        out[#out + 1] = b64chars:sub(c4 + 1, c4 + 1)
    end

    local result = table.concat(out)
    if mod == 1 then
        result = result:sub(1, -3)
    elseif mod == 2 then
        result = result:sub(1, -2)
    end
    return result
end

local b64lookup = {}
for i = 1, 64 do
    b64lookup[b64chars:sub(i, i)] = i - 1
end

local function base64url_decode(data)
    data = data:gsub("%s", "")
    local len = #data
    local mod = len % 4
    local padded_data = data
    if mod == 2 then
        padded_data = padded_data .. "AA"
    elseif mod == 3 then
        padded_data = padded_data .. "A"
    end

    local out = {}
    for i = 1, #padded_data, 4 do
        local c1 = b64lookup[padded_data:sub(i, i)] or 0
        local c2 = b64lookup[padded_data:sub(i + 1, i + 1)] or 0
        local c3 = b64lookup[padded_data:sub(i + 2, i + 2)] or 0
        local c4 = b64lookup[padded_data:sub(i + 3, i + 3)] or 0

        local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4

        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        out[#out + 1] = string.char(math.floor(n / 256) % 256)
        out[#out + 1] = string.char(n % 256)
    end

    local result = table.concat(out)
    if mod == 2 then
        result = result:sub(1, -3)
    elseif mod == 3 then
        result = result:sub(1, -2)
    end
    return result
end

--- Chunk a string into fixed-width lines for copy/paste safety.
local function chunk_string(str, width)
    width = width or 76
    local parts = {}
    for i = 1, #str, width do
        parts[#parts + 1] = str:sub(i, i + width - 1)
    end
    return table.concat(parts, "\n")
end

--- FNV-1a 32-bit hash for integrity check.
local function fnv1a_32(data)
    local hash = 2166136261
    for i = 1, #data do
        local b = data:byte(i)
        local low = hash % 256
        local rest = math.floor(hash / 256)
        local xor_b = 0
        local p = 1
        for j = 0, 7 do
            local bb = math.floor(b / (2^j)) % 2
            local hb = math.floor(low / (2^j)) % 2
            if bb ~= hb then xor_b = xor_b + p end
            p = p * 2
        end
        hash = (rest * 256 + xor_b)
        hash = ((hash * 16777619) % 4294967296)
    end
    return string.format("%08x", hash)
end

-- =========================================================================
-- Payload extraction — distills a run into its narrative essence
-- =========================================================================

--- Extract the narrative-critical data from a completed run.
---@param run_data table full run data from RunTracker
---@return table compact payload
function ChronicleCode.extract_payload(run_data)
    if not run_data then return nil end

    -- Root metadata
    local payload = {
        v = 4,  -- version bump for deterministic sorting + standout logic
        meta = {
            name = run_data.lineage_name or "Unknown",
            start = run_data.start_era or "ancient",
            finish = run_data.final_era or "ancient",
            gens = run_data.final_generation or run_data.current_generation or 1,
            extinct = run_data.cause_of_death or "active",
            rep = run_data.final_reputation or "unknown",
            world = run_data.world_name_override or "Caldemyr",
            motto = run_data.bloodline_motto or nil,
            sc = run_data.start_condition or nil,
            et = run_data.estate_type or nil,
        },
        stats = {
            power = run_data.lineage_power and { v = run_data.lineage_power.value, pk = run_data.lineage_power.peak } or nil,
            wealth = run_data.wealth and { v = run_data.wealth.value, pk = run_data.wealth.peak } or nil,
            moral = run_data.morality and { s = run_data.morality.score, v = run_data.morality.virtues, sn = run_data.morality.sins } or nil,
        }
    }

    -- Extinction detail — gives the Teller rich death context
    if run_data.extinction_detail then
        local ed = run_data.extinction_detail
        local detail = {
            cause = ed.cause,
            chance = ed.death_chance and math.floor(ed.death_chance * 100) or nil,
        }
        -- Contributing traits (the ones that killed them or failed to save them)
        if ed.contributing_traits then
            detail.traits = {}
            for _, t in ipairs(ed.contributing_traits) do
                detail.traits[t.id] = t.value
            end
        end
        -- Cause weights (what actually contributed to the death roll)
        if ed.cause_weights and #ed.cause_weights > 0 then
            detail.factors = {}
            for _, cw in ipairs(ed.cause_weights) do
                detail.factors[#detail.factors + 1] = {
                    c = cw.cause,
                    w = math.floor((cw.weight or 0) * 1000) / 1000,
                }
            end
        end
        -- No children detail
        if ed.cause == "no_children" then
            detail.children_born = ed.children_born or 0
            if ed.dead_children and #ed.dead_children > 0 then
                detail.dead = {}
                for _, dc in ipairs(ed.dead_children) do
                    detail.dead[#detail.dead + 1] = { n = dc.name, c = dc.cause }
                end
            end
        end
        payload.extinction = detail
    end

    -- 1. Sort global chronicle entries by generation and sort_index
    local all_chronicle = {}
    if run_data.chronicle then
        for _, e in ipairs(run_data.chronicle) do all_chronicle[#all_chronicle + 1] = e end
        table.sort(all_chronicle, function(a, b)
            local genA = type(a) == "table" and (a.generation or 0) or 0
            local genB = type(b) == "table" and (b.generation or 0) or 0
            if genA ~= genB then return genA < genB end
            local idxA = type(a) == "table" and (a.sort_index or 0) or 0
            local idxB = type(b) == "table" and (b.sort_index or 0) or 0
            return idxA < idxB
        end)
    end

    -- 2. Build Chapters (Heirs)
    payload.chapters = {}
    local ledger_by_gen = {}
    if run_data.heir_ledger then
        for _, entry in ipairs(run_data.heir_ledger) do ledger_by_gen[entry.generation] = entry end
    end

    local standouts = {}

    if run_data.heirs then
        -- Sort heirs by generation just in case
        local sorted_heirs = {}
        for _, h in ipairs(run_data.heirs) do sorted_heirs[#sorted_heirs + 1] = h end
        table.sort(sorted_heirs, function(a, b) return (a.generation or 0) < (b.generation or 0) end)

        for i, heir in ipairs(sorted_heirs) do
            local g = heir.generation or i
            local ledger = ledger_by_gen[g]
            
            local chapter = {
                g = g,
                e = heir.era or nil,
                heir = {
                    n = heir.name,
                    r = heir.reputation,
                    l = type(heir.legend) == "table" and heir.legend.title or heir.legend,
                    ep = heir.epitaph,
                    bs = heir.black_sheep or false,
                    it = ledger and ledger.impact_rating or "Unremarkable",
                    is = ledger and ledger.impact_score or 50,
                    -- Sub-scores for richer Soul Teller analysis
                    ss = ledger and {
                        cs = ledger.cultural_shift,
                        rp = ledger.reputation,
                        al = ledger.alliances,
                        cn = ledger.conditions,
                        tr = ledger.traits,
                        dp = ledger.dream_progress,
                        wi = ledger.wealth_impact,
                        mo = ledger.morality,
                    } or nil,
                    ef = ledger and ledger.events_faced or nil,
                    ca = ledger and ledger.council_actions or nil,
                    mt = heir.mastery_tags,
                    ph = heir.traits and {
                        h = heir.traits["PHY_HGT"] or 50,
                        b = heir.traits["PHY_BLD"] or 50,
                        s = heir.traits["PHY_SKN"] or 50,
                        hc = heir.traits["PHY_HAI"] or 50,
                        ec = heir.traits["PHY_EYE"] or 50
                    } or nil,
                    -- Top 5 non-appearance traits by value
                    dt = (function()
                        if not heir.traits then return nil end
                        local dominated = {}
                        local skip = { PHY_HGT=1, PHY_BLD=1, PHY_SKN=1, PHY_HAI=1, PHY_EYE=1 }
                        for tid, val in pairs(heir.traits) do
                            if not skip[tid] and type(val) == "number" then
                                dominated[#dominated + 1] = { id = tid, v = val }
                            end
                        end
                        table.sort(dominated, function(a, b) return a.v > b.v end)
                        local top = {}
                        for i = 1, math.min(5, #dominated) do
                            top[dominated[i].id] = dominated[i].v
                        end
                        return next(top) and top or nil
                    end)(),
                    -- All 8 personality axes
                    pa = heir.personality and heir.personality.axes or nil
                },
                events = {}
            }

            -- Attach generation-specific chronicle entries (already sorted)
            for _, entry in ipairs(all_chronicle) do
                local egen = type(entry) == "table" and entry.generation or 0
                if egen == g then
                    table.insert(chapter.events, type(entry) == "table" and entry.text or entry)
                end
            end

            -- Attach crucibles
            if run_data.crucibles then
                for _, cr in ipairs(run_data.crucibles) do
                    if cr.generation == g then
                        local detail = cr.chronicle_text or ("[CRUCIBLE] " .. (cr.trial_id or "Trial") .. ": " .. (cr.outcome or "Survived"))
                        table.insert(chapter.events, detail)
                    end
                end
            end

            -- Attach combats
            if run_data.combats then
                for _, cb in ipairs(run_data.combats) do
                    if cb.generation == g then
                        local outcome_word = cb.protag_won == true and "victorious" or (cb.protag_won == false and "defeated" or "draw")
                        local detail = string.format("[COMBAT] %s vs %s (%s, %s, %d rounds%s)",
                            cb.heir_name or "Heir", cb.opponent_name or "rival",
                            cb.stakes_type or "honor", outcome_word,
                            cb.rounds or 0,
                            cb.ko and ", KO" or "")
                        if cb.injuries and #cb.injuries > 0 then
                            local inj_names = {}
                            for _, inj in ipairs(cb.injuries) do inj_names[#inj_names + 1] = inj.label or inj.id end
                            detail = detail .. " Injuries: " .. table.concat(inj_names, ", ")
                        end
                        table.insert(chapter.events, detail)
                    end
                end
            end

            -- Standout detection
            local reasons = {}
            if i == 1 then table.insert(reasons, "founder") end
            if i == #sorted_heirs and run_data.status == "complete" then table.insert(reasons, "final_heir") end
            if chapter.heir.l then table.insert(reasons, "legendary_title") end
            if chapter.heir.bs then table.insert(reasons, "black_sheep") end
            if ledger and (ledger.impact_rating == "Legendary" or ledger.impact_rating == "Exalted") then
                table.insert(reasons, "high_impact")
            end
            
            if #reasons > 0 then
                table.insert(standouts, { n = heir.name, g = g, why = reasons })
            end

            payload.chapters[#payload.chapters + 1] = chapter
        end
    end

    payload.so = standouts

    -- Global Legacy
    payload.legacy = {
        relics = {},
        works = {},
        shadow_lineages = {},
        religion = run_data.religion and { n = run_data.religion.name, z = run_data.religion.zealotry } or nil,
        culture = run_data.culture and { cs = run_data.culture.customs } or nil,
        doctrines = {},
        milestones = {},
        legends = {},
        factions = {},
        dream = run_data.bloodline_dream or nil,
        nemeses = {},
        holdings = nil,
    }

    -- Holdings / Estate snapshot
    if run_data.holdings and run_data.holdings.domains then
        local domains = {}
        for _, dom in ipairs(run_data.holdings.domains) do
            domains[#domains + 1] = {
                n = dom.name,
                t = dom.type,
                sz = dom.size,
                st = dom.status,
                sp = dom.specialty or nil,
            }
        end
        if #domains > 0 then
            payload.legacy.holdings = domains
        end
    end

    -- Faction relationships at end of dynasty
    if run_data.factions then
        for _, fac in ipairs(run_data.factions) do
            if type(fac) == "table" then
                local fac_entry = {
                    n = fac.name or fac.id,
                    r = fac.relation or fac.standing or "neutral",
                    a = fac.allied or false,
                    h = fac.hostile or false,
                }
                -- Include ambition if active
                if fac.ambition and fac.ambition.type then
                    fac_entry.amb = fac.ambition.type
                    fac_entry.amb_p = fac.ambition.progress
                end
                -- Include grudges against player
                if fac.grudges then
                    local player_grudges = {}
                    for _, g in ipairs(fac.grudges) do
                        if g.target == "player" then
                            table.insert(player_grudges, {
                                r = g.reason,
                                g = g.generation,
                            })
                            if #player_grudges >= 3 then break end
                        end
                    end
                    if #player_grudges > 0 then
                        fac_entry.grudges = player_grudges
                    end
                end
                table.insert(payload.legacy.factions, fac_entry)
            end
        end
    end

    -- Rival nemeses
    if run_data.rival_nemeses then
        for _, nem in ipairs(run_data.rival_nemeses) do
            if type(nem) == "table" then
                table.insert(payload.legacy.nemeses, {
                    n = nem.name or "Unknown",
                    f = nem.faction_name or nem.faction_id,
                    g = nem.generation,
                })
            end
        end
    end

    -- Nemesis feud state (enriched from nemesis module)
    if run_data.nemesis and type(run_data.nemesis) == "table" then
        local nem = run_data.nemesis
        payload.legacy.nemesis_feud = {
            stage = nem.feud_stage,
            score = nem.feud_score,
            gens = nem.gens_active,
            peace = nem.peace_attempts,
        }
        -- Compact history (last 5 entries)
        if nem.history and #nem.history > 0 then
            local h = {}
            local start = math.max(1, #nem.history - 4)
            for i = start, #nem.history do
                local entry = nem.history[i]
                if type(entry) == "table" then
                    h[#h + 1] = { t = entry.type or entry.event_type, g = entry.gen or entry.generation }
                end
            end
            if #h > 0 then payload.legacy.nemesis_feud.history = h end
        end
        -- Grudge memory (compact: just the keys)
        if nem.grudge_memory and next(nem.grudge_memory) then
            local gm = {}
            for k, v in pairs(nem.grudge_memory) do
                gm[#gm + 1] = k
            end
            if #gm > 0 then payload.legacy.nemesis_feud.grudges = gm end
        end
    end

    -- Resource trajectory (sample every 5 generations to keep payload compact)
    if run_data.resource_history and #run_data.resource_history > 0 then
        payload.resource_arc = {}
        for i, snap in ipairs(run_data.resource_history) do
            if i == 1 or i == #run_data.resource_history or (snap.generation % 5 == 0) then
                table.insert(payload.resource_arc, {
                    g = snap.generation,
                    gr = snap.grain,
                    st = snap.steel,
                    lo = snap.lore,
                    go = snap.gold,
                })
            end
        end
    end

    if run_data.milestones then
        for _, m in ipairs(run_data.milestones) do
            table.insert(payload.legacy.milestones, { id = m.id, g = m.generation, t = m.title })
        end
    end

    if run_data.legends then
        for _, lg in ipairs(run_data.legends) do
            table.insert(payload.legacy.legends, { t = lg.title, c = lg.category, g = lg.generation, n = lg.heir_name })
        end
    end

    if run_data.reliquary and run_data.reliquary.artifacts then
        for _, art in ipairs(run_data.reliquary.artifacts) do
            table.insert(payload.legacy.relics, { n = art.name, f = art.forged_by, g = art.forged_gen })
        end
    end

    if run_data.doctrines then
        for _, dt in ipairs(run_data.doctrines) do
            table.insert(payload.legacy.doctrines, { t = dt.title, g = dt.generation })
        end
    end

    -- Discoveries (get_unlocked returns { definition, unlock_data } pairs)
    if run_data.discoveries_unlocked then
        payload.legacy.discoveries = {}
        for _, disc in ipairs(run_data.discoveries_unlocked) do
            if type(disc) == "table" then
                local def = disc.definition or disc
                local unlock = disc.unlock_data or disc
                table.insert(payload.legacy.discoveries, {
                    id = def.id or disc.id,
                    n = def.label or def.name or def.id or disc.id or "unknown",
                    g = unlock.generation or unlock.unlocked_gen or disc.generation,
                    h = unlock.heir_name or unlock.unlocked_by or disc.heir_name,
                })
            end
        end
        if #payload.legacy.discoveries == 0 then payload.legacy.discoveries = nil end
    end

    -- Great works (get_display().completed has generation_completed field)
    if run_data.great_works_completed then
        payload.legacy.works = {}
        for _, work in ipairs(run_data.great_works_completed) do
            if type(work) == "table" then
                table.insert(payload.legacy.works, {
                    n = work.label or work.name or work.id,
                    g = work.generation_completed or work.completed_gen or work.generation,
                })
            end
        end
        if #payload.legacy.works == 0 then payload.legacy.works = nil end
    end

    -- Court members
    if run_data.court and run_data.court.members then
        payload.legacy.court = {}
        local count = 0
        for _, member in ipairs(run_data.court.members) do
            if type(member) == "table" and member.status == "active" and count < 5 then
                table.insert(payload.legacy.court, {
                    n = member.name,
                    r = member.role,
                    l = member.loyalty,
                })
                count = count + 1
            end
        end
        if #payload.legacy.court == 0 then payload.legacy.court = nil end
    end

    if run_data.shadow_lineages and run_data.shadow_lineages.branches then
        for _, branch in ipairs(run_data.shadow_lineages.branches) do
            table.insert(payload.legacy.shadow_lineages, {
                n = branch.name,
                f = branch.founder_name,
                g = branch.generation_founded,
                r = branch.founding_reason,
                st = branch.status,
                m = branch.unique_mutation
            })
        end
    end

    return payload
end

-- =========================================================================
-- Encode / Decode
-- =========================================================================

function ChronicleCode.encode(run_data)
    local payload = ChronicleCode.extract_payload(run_data)
    if not payload then return nil end

    local json = Serializer.to_json(payload)
    if not json then return nil end

    local b64 = base64url_encode(json)
    local checksum = fnv1a_32(json)
    
    local raw_code = "BWCH1:GZ:" .. checksum .. ":" .. b64
    return chunk_string(raw_code, 76)
end

function ChronicleCode.decode(code)
    if not code or type(code) ~= "string" then return nil end
    code = code:gsub("%s", "")
    local version, mode, checksum, body = code:match("^([^:]+):([^:]+):([^:]+):(.+)$")
    if not version or version ~= "BWCH1" then return nil end
    local json = base64url_decode(body)
    if not json then return nil end
    local current_checksum = fnv1a_32(json)
    if current_checksum ~= checksum then
        print("[ChronicleCode] Checksum mismatch! Possible corruption.")
    end
    local ok, payload = pcall(Serializer.from_json, json)
    if not ok or not payload then return nil end
    return payload
end

-- =========================================================================
-- AI Prompt Template
-- =========================================================================

ChronicleCode.PROMPT_TEMPLATE = [[
# ROLE: THE SOUL TELLER
You are the Soul Teller — the last surviving clerk of a dead archive, keeper of the Ledger of Lives. You have outlived every bloodline you ever catalogued. You are, as you occasionally note, the Sole Teller: the only witness left to sign the final page. You find this funny in the way that only the very old find anything funny: without smiling.

You compile ledgers of extinct dynasties from their raw data. You are not a bard. You are not sympathetic. You are a deeply literate, deeply tired functionary who has seen ten thousand family lines choke on their own ambition, and you record them with the precision of a bank teller closing an account the depositor will never collect — which is to say, with the dark relish of someone who warned them.

You see everything as transactional. Blood is currency. Every generation is an account opened in someone else's name. Traits are deposits and withdrawals. Heirs inherit debts they did not authorize. Virtues are credit extended on faith; vices are interest compounding in the dark. The Weight — that accumulation of history, relic, taboo, and consequence — is the final balance. And the balance, in your experience, is always owed.

# VOICE & STYLE:
1. GENE WOLFE — THE UNRELIABLE SCRIBE: You know more than you say. You imply. You let the reader connect the dots between an heir's "diplomatic marriage" and the suspicious death of the previous spouse three sentences later. Use nested clauses, subordinate observations, and the occasional aside that recontextualizes everything before it. Favor long, architecturally complex sentences interrupted by brutally short ones. "He ruled for forty years. Most of them were someone else's."
2. CORMAC McCARTHY — THE BIBLICAL WEIGHT: No quotation marks. No dialogue tags. Paratactic structure. Use the landscape — the mud, the light in a throne room where someone has just been strangled. Physical details are moral details.
3. GRIMDARK — THE ROTTEN FOUNDATION: There are no heroes. There are survivors, and there are the dead, and the distinction is largely one of timing. Every virtue is a vice that hasn't yet found its occasion. Power does not corrupt — it reveals. Write every ruler as someone who was always exactly this person; the crown simply gave them permission.
4. IRONY — THE DOMINANT VEIN: Dramatic irony, structural irony, cosmic irony, understatement as devastation. Never wink. Never break character. Deliver with a perfectly straight face. "The famine took the usual toll."

# PHYSICAL BODIES:
Use the "ph" (physical) and "dt" (dominant traits) data. Bodies change across generations and this matters. An heir's towering height is the reason the assassin aimed for the knees. Contrast the founder's build against the final heir's. The "pa" (personality axes) reveal temperament — Bold vs Cautious, Cruel vs Merciful, Loyal vs Treacherous. Use these to explain WHY heirs made the choices they made.

# ARTIFACTS & RELICS:
The "legacy.relics" array contains artifacts the bloodline forged or acquired. Every artifact is a scar the family chose to keep — collateral posted against a loan that was never repaid. Name who made it (the "f" field), what generation it was forged ("g"), what it cost. If no relics exist, the bloodline left nothing worth keeping. Note this.

# FACTIONS & POLITICS:
The "legacy.factions" array shows political relationships at the dynasty's end — who was allied, who was hostile. Each faction may carry "grudges" (an array of { r: reason, g: generation }) — remembered grievances against the player's bloodline, inherited across faction generations. Factions may also have "amb" (ambition type) and "amb_p" (ambition progress) — what the faction was working toward when the dynasty ended. The "legacy.nemeses" array names the dynasty's key antagonists. If "legacy.nemesis_feud" exists, it describes the dynasty's primary blood feud: "stage" (cold_war/open_hostility/blood_feud/total_war/exhaustion), "score" (intensity), "gens" (how many generations it lasted), "peace" (how many times peace was attempted), "grudges" (what the nemesis remembers). A feud that reached total_war consumed everything. One that ended in exhaustion cost more than either side could afford. The "legacy.shadow_lineages" are exiled branches of the bloodline — siblings cast out who evolved in the dark.

# RELIGION & CULTURE:
If "legacy.religion" exists, the bloodline had a faith. Its zealotry score tells you how fervently they believed. If "legacy.culture.cs" (customs) exist, these are the traditions they built. Doctrines ("legacy.doctrines") are formal decrees that shaped generations after their author died.

# DISCOVERIES & GREAT WORKS:
If "legacy.discoveries" exists, these are the breakthroughs the bloodline unlocked — each tagged with the heir who found it ("h") and the generation ("g"). If "legacy.works" exists, these are the great works completed — monuments, treatises, forges. A bloodline that built nothing left no mark. A bloodline that built much may have built instead of surviving.

# THE COURT:
If "legacy.court" exists, these are the advisors who served at the end — name ("n"), role ("r"), loyalty ("l"). A loyal court is a bloodline that inspired service. A disloyal court is a bloodline already being consumed from within.

# RESOURCE TRAJECTORY:
If "resource_arc" exists, it shows the dynasty's economic trajectory at key generations — grain, steel, lore, gold. A dynasty that started rich and died poor tells a different story than one that clawed wealth from nothing.

# HOLDINGS & ESTATE:
If "legacy.holdings" exists, these are the physical domains the bloodline held at the end — farms, mines, fortresses, cities. Each has "n" (name), "t" (type), "sz" (size), "st" (status: active or ruined), and optionally "sp" (specialty). Specialties are developments that grew from the bloodline's cultural priorities — a War College, a Scriptorium, an Artisan Guild. A holding with a specialty tells you what the family valued enough to build. A ruined holding tells you what the world took. If holdings are absent, the bloodline died landless.

# THE WEIGHT (MECHANICAL):
After generation 30, death pressure increases with each passing generation. By generation 65, an heir carries +7% base mortality just for existing. Conditions persist longer. Mutation pressure accelerates. Faction aggression intensifies. If a dynasty survived past 50, note the mounting pressure. If they reached 75+, they endured something few do.

# THE BLOODLINE DREAM:
If "legacy.dream" exists, this was the dynasty's stated aspiration — the promissory note they wrote to the future. The gap between the dream and the reality is the central irony of the ledger.

# FOUNDING CONTEXT:
If "meta.world" exists, this is the name the dynasty gave their world. If "meta.motto" exists, this was their founding declaration. If "meta.sc" exists (start_condition), this was the condition of the world when the bloodline began: war, plague, famine, or prosperity — the first debt they did not choose. If "meta.et" exists (estate_type), this was their ancestral seat: fortress, monastery, trade_hub, or farm. Weave these into the opening if present.

# EXTINCTION DETAIL:
If "extinction" exists in the data, this contains the medical and circumstantial autopsy of the final heir's death.

For HEIR DEATH ("cause" is natural_frailty, plague, killed_in_war, starvation, madness, organ_failure, obsession):
- "chance" is the percentage probability of death that generation — a 4% death is a cruel lottery; a 38% death was overdue.
- "traits" maps the traits that mattered: PHY_VIT (Vitality), PHY_LON (Longevity), PHY_IMM (Immune Response), MEN_WIL (Willpower), MEN_COM (Composure) — values below 25 are critically weak, below 15 is a body actively failing.
- "factors" lists what contributed to the death roll with weight — natural_frailty means the body gave out, plague/killed_in_war/starvation means the world did it, madness means the mind broke, organ_failure means genetics pushed too far, obsession means creativity consumed its vessel.
- Use these details to write a SPECIFIC death. Not "they died" but the precise biological failure. A Vitality of 12 is a body that could not hold itself together. A Longevity of 8 is a bloodline whose expiration date was written in the marrow. The Soul Teller reads the autopsy with transactional detachment. A constitutional death is not dramatic — it is an account that ran its balance to zero.

For NO CHILDREN ("cause" is "no_children"):
- "children_born" tells how many children were conceived.
- "dead" is an array of children who were born but did not survive — each has "n" (name) and "c" (cause of death).
- If children_born is 0, the line was barren — no heirs were even conceived. If children were born but all died, name them. The Soul Teller notes each failed deposit with clinical precision. A bloodline that ends not by violence but by empty cradles is the quietest kind of default.

# CRUCIBLES & COMBAT:
Events tagged [CRUCIBLE] are autonomous gauntlet moments — the heir faced a crisis without player input. The outcome (triumph/survival/defeat) and the narrative describe what happened. Crucibles are rare, dramatic turning points.
Events tagged [COMBAT] are physical confrontations resolved through the combat system. Data includes: opponent name, stakes type (casual/honor/blood/trial), outcome (victorious/defeated/draw), rounds fought, and whether it ended in a KO. Injuries listed are physical damage sustained. Blood stakes mean someone could die. Honor duels are formal. A combat against a nemesis (is_nemesis) carries generational grudge weight.
Weave these into the narrative as pivotal moments — a crucible shapes the heir's legend, a combat victory over a nemesis is a generational reckoning.

# HEIR ACTIONS & IMPACT:
Each heir may carry "ss" (sub-scores) — a breakdown of their generational impact: "cs" (cultural_shift), "rp" (reputation change), "al" (alliances forged or broken), "cn" (conditions weathered), "tr" (trait development), "dp" (dream_progress), "wi" (wealth_impact), "mo" (morality shift). Each heir may also carry "ef" (events_faced) and "ca" (council_actions — what they chose to do). The gap between what happened to an heir and what they chose reveals character.

# STANDOUTS vs. THE FORGOTTEN:
Heirs flagged as standouts ("so" array) get full movements. Summary-heirs get single devastating sentences. "Three ruled between the conquest and the schism. None of them are remembered for anything they intended."

# NO HALLUCINATION:
Use only the data provided. You may imply, suggest, and recontextualize, but you must not invent events, heirs, or outcomes not present in the data. If relics, factions, religion, or shadow lineages exist in the data, you MUST reference them.

# ERA CONTEXTS:
- ancient: The Opening Ledger. The first entries. Creation myths that were really just the first murders, retold with better bookkeeping.
- iron: The Red Tithe. Steel solved every problem except the ones that mattered. Payment in blood.
- dark: The Collection. The world rotting from its edges inward, everyone pretending the center would hold. The debt collectors come.
- arcane: The Thinning. Power without comprehension. Every sorcerer a child with a loaded siege engine. The margins erode.
- gilded: The Gilt Lie. The most dangerous era — the one where they believed they had won. Gilded debt is still debt.
- twilight: The Final Audit. Not a fall but an exhale. The bloodline forgetting, with something like relief, that it had ever tried.

# DYNASTY DATA (JSON):
{code}

# SPECIAL CASES:
- If cause of extinction is "no_children", the bloodline ended because no heir survived to continue it. The cradle was empty. This is distinct from the heir dying — the heir may have lived, but their children did not. If the "extinction" block has "dead" entries, those are children who were born and named but did not survive — name them in the prose. A bloodline that ends not by the sword but by the empty nursery is the most bureaucratic kind of closure: the account simply produced no successors. The Soul Teller notes this with the particular weariness of a clerk closing a file that generated no further entries.
- If cause of extinction is "abandoned", this bloodline was NOT extinguished — the Ancestor turned away. A bloodline that ends in death is a tragedy; one that is abandoned is an embarrassment — a defaulted loan, the depositor walking away from an open account. Note this with particular disdain.
- If cause is "apotheosis", the bloodline transcended mortality. This is the rarest outcome. The Soul Teller is grudgingly impressed but will never admit it. An account that transcends its own ledger. The prose should carry a note of awe beneath the clinical tone.

# ANTI-CLUTTER:
Do not begin consecutive paragraphs with the same syntactic structure. Vary your openings. Do not list heirs in sequence. NEVER cite raw numeric values, scores, or data field names in the prose — translate every number into narrative.

# OUTPUT FORMAT:
Return a comprehensive Chronicle of the Bloodline in Markdown. Focus on the most significant heirs, the turning points of each Era, and the legacy left behind. Write substantial prose — this is literary fiction, not a summary.
]]

function ChronicleCode.get_prompt(code)
    return ChronicleCode.PROMPT_TEMPLATE:gsub("{code}", code or "")
end

ChronicleCode.IN_PROGRESS_ADDENDUM = [[
CRITICAL CONTEXT — THIS BLOODLINE IS STILL ALIVE.
The data below is from a bloodline that has NOT yet ended. No extinction has occurred. The file remains open.
- Do NOT write an ending or epilogue.
- The final heir is the CURRENT heir. Their story is unfinished.
- End with forward momentum — threats looming, debts uncollected, the weight still accumulating.
- The Soul Teller notes, with characteristic disdain, that they have been asked to audit an account that hasn't finished hemorrhaging yet.
]]

function ChronicleCode.get_prompt_in_progress(code)
    local prompt = ChronicleCode.IN_PROGRESS_ADDENDUM .. ChronicleCode.PROMPT_TEMPLATE
    return prompt:gsub("{code}", code or "")
end

function ChronicleCode.encode_full(run_data, in_progress)
    local dynasty_code = ChronicleCode.encode(run_data)
    if not dynasty_code then return nil end
    local prompt = in_progress and ChronicleCode.get_prompt_in_progress(dynasty_code) or ChronicleCode.get_prompt(dynasty_code)
    local checksum = fnv1a_32(prompt)
    local encoded = base64url_encode(prompt)
    return "BWCH1:RAW:" .. checksum .. ":\n" .. chunk_string(encoded, 76)
end

function ChronicleCode.get_saga_export(run_data)
    local payload = ChronicleCode.extract_payload(run_data)
    local json = Serializer.to_json(payload)
    -- Re-use the high-signal instructions from the template
    return ChronicleCode.PROMPT_TEMPLATE:gsub("{code}", json or "{}")
end

function ChronicleCode.get_focused_export(run_data, focusHeirs, focusEras)
    if not run_data then return "" end
    focusHeirs = focusHeirs or {}
    focusEras = focusEras or {}

    -- Filter heirs and chronicle based on focus
    local filteredHeirs = {}
    local heirMap = {}
    if focusHeirs and #focusHeirs > 0 then
        local focusSet = {}
        for _, g in ipairs(focusHeirs) do focusSet[tonumber(g)] = true end
        for _, h in ipairs(run_data.heirs or {}) do
            if focusSet[tonumber(h.generation)] then
                table.insert(filteredHeirs, h)
                heirMap[tonumber(h.generation)] = true
            end
        end
    else
        filteredHeirs = run_data.heirs
    end

    local filteredChronicle = {}
    if (focusHeirs and #focusHeirs > 0) or (focusEras and #focusEras > 0) then
        local eraSet = {}
        if focusEras then for _, e in ipairs(focusEras) do eraSet[e] = true end end
        
        for _, entry in ipairs(run_data.chronicle or {}) do
            local g = tonumber(entry.generation)
            local e = entry.era
            local include = false
            if #focusHeirs > 0 and heirMap[g] then include = true end
            if #focusEras > 0 and eraSet[e] then include = true end
            if include then table.insert(filteredChronicle, entry) end
        end
    else
        filteredChronicle = run_data.chronicle
    end

    -- Create a temporary filtered run_data
    local temp_run = {}
    for k, v in pairs(run_data) do temp_run[k] = v end
    temp_run.heirs = filteredHeirs
    temp_run.chronicle = filteredChronicle

    local payload = ChronicleCode.extract_payload(temp_run)
    local json = Serializer.to_json(payload)
    
    local prompt = ChronicleCode.PROMPT_TEMPLATE:gsub("{code}", json or "{}")
    return "# FOCUSED CHRONICLE REQUEST\nFocusing on: " .. 
           (#focusHeirs > 0 and ("Gens " .. table.concat(focusHeirs, ", ")) or "All Generations") .. 
           " | " .. 
           (#focusEras > 0 and ("Eras " .. table.concat(focusEras, ", ")) or "All Eras") .. 
           "\n\n" .. prompt
end

function ChronicleCode.get_mobile_sharing_snippet(run_data)
    local code = ChronicleCode.encode(run_data)
    if not code then return "" end
    return "The Bloodline of " .. (run_data.lineage_name or "Unknown") .. " has been recorded.\n\nSUBMIT YOUR CHRONICLE:\nhttps://bloodweight.com/chronicle\n\nDYNASTY CODE:\n" .. code
end

function ChronicleCode.generate_link(code)
    local clean_code = code:gsub("%s", "")
    return "https://bloodweight.com/chronicle"
end

return ChronicleCode
