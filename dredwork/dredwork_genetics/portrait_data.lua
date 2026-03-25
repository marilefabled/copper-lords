-- Dark Legacy — Portrait Data Generator
-- Pure Lua module. No Solar2D dependencies.
-- Takes genome + personality, returns plain data tables for rendering.

local portrait_maps = require("dredwork_genetics.config.portrait_maps")

local PortraitData = {}

--- Calculate silhouette and physical base from physical traits.
---@param genome table Genome instance
---@return table { head_radius, neck_width, shoulder_width, height_offset, skin_tone, hair_color, eye_color, hair_texture, face_angularity }
function PortraitData.calculate_silhouette(genome)
    if not genome then
        return { 
            head_radius = 16, neck_width = 6, shoulder_width = 28, height_offset = 0,
            skin_tone = 0.5, hair_color = 0.5, eye_color = 0.5, hair_texture = 0.5, face_angularity = 0.5
        }
    end

    local build = (genome.get_value and genome:get_value("PHY_BLD")) or 50
    local height = (genome.get_value and genome:get_value("PHY_HGT")) or 50
    local strength = (genome.get_value and genome:get_value("PHY_STR")) or 50
    
    -- New Appearance Traits
    local skin = (genome.get_value and genome:get_value("PHY_SKN")) or 50
    local hair = (genome.get_value and genome:get_value("PHY_HAI")) or 50
    local eye = (genome.get_value and genome:get_value("PHY_EYE")) or 50
    local htx = (genome.get_value and genome:get_value("PHY_HTX")) or 50
    local fsh = (genome.get_value and genome:get_value("PHY_FSH")) or 50

    -- Head radius: 14-18, influenced by build
    local head_radius = 14 + (build / 100) * 4

    -- Neck width: 4-8, influenced by build + strength
    local neck_width = 4 + ((build + strength) / 200) * 4

    -- Shoulder width: 22-34, influenced by build + strength
    local shoulder_width = 22 + ((build * 0.6 + strength * 0.4) / 100) * 12

    -- Height offset: -4 to +4, from PHY_HGT
    local height_offset = ((height - 50) / 50) * 4

    return {
        head_radius = head_radius,
        neck_width = neck_width,
        shoulder_width = shoulder_width,
        height_offset = height_offset,
        skin_tone = skin / 100,
        hair_color = hair / 100,
        eye_color = eye / 100,
        hair_texture = htx / 100,
        face_angularity = fsh / 100,
    }
end

--- Calculate which trait marks to display on the portrait.
---@param genome table Genome instance
---@param cap number maximum number of marks to show
---@return table sorted array of { slot, shape, cat, value, is_legendary }
function PortraitData.calculate_marks(genome, cap)
    cap = cap or 6
    if not genome then return {} end

    local marks = {}
    for _, mapping in ipairs(portrait_maps.TRAIT_MARKS) do
        -- Skip appearance-only entries (no slot = not renderable)
        if mapping.slot then
            local value = genome.get_value and genome:get_value(mapping.id)
            if value and value >= 65 then
                marks[#marks + 1] = {
                    slot = mapping.slot,
                    shape = mapping.shape,
                    cat = mapping.cat,
                    value = value,
                    is_legendary = value >= 90,
                }
            end
        end
    end

    -- Sort by value descending (highest traits get priority)
    table.sort(marks, function(a, b) return a.value > b.value end)

    -- Cap the number of marks
    if #marks > cap then
        local capped = {}
        for i = 1, cap do
            capped[i] = marks[i]
        end
        return capped
    end

    return marks
end

--- Calculate eye appearance from personality axes.
---@param personality table Personality instance (optional)
---@return table { style, color, alpha, shape, animate }
function PortraitData.calculate_eyes(personality)
    local styles = portrait_maps.EYE_STYLES
    local neutral = styles.neutral

    if not personality then
        return {
            style = "neutral",
            color = neutral.color,
            alpha = neutral.alpha,
            shape = neutral.shape,
            animate = false,
        }
    end

    -- Find the most extreme personality axis (furthest from 50)
    local best_axis = nil
    local best_distance = 0
    local best_value = 50

    local axes = { "PER_BLD", "PER_CRM", "PER_OBS", "PER_LOY", "PER_CUR", "PER_VOL", "PER_PRI", "PER_ADA" }
    for _, axis_id in ipairs(axes) do
        local value = personality.get_axis and personality:get_axis(axis_id) or 50
        local distance = math.abs(value - 50)
        if distance > best_distance then
            best_distance = distance
            best_axis = axis_id
            best_value = value
        end
    end

    -- If no axis is extreme enough (all within ±10 of 50), use neutral
    if best_distance < 10 or not best_axis then
        return {
            style = "neutral",
            color = neutral.color,
            alpha = neutral.alpha,
            shape = neutral.shape,
            animate = false,
        }
    end

    local axis_styles = styles[best_axis]
    if not axis_styles then
        return {
            style = "neutral",
            color = neutral.color,
            alpha = neutral.alpha,
            shape = neutral.shape,
            animate = false,
        }
    end

    local entry = best_value >= 50 and axis_styles.high or axis_styles.low
    return {
        style = best_axis .. (best_value >= 50 and "_high" or "_low"),
        color = entry.color,
        alpha = entry.alpha,
        shape = entry.shape,
        animate = entry.animate or false,
    }
end

--- Calculate geometric face proportions for Mode A.
---@param genome table Genome instance
---@param personality table Personality instance (optional)
---@return table { eye_w, eye_h, brow_angle, mouth_w, mouth_curve, jaw_w, forehead_h, nose_len }
function PortraitData.calculate_face(genome, personality)
    local features = portrait_maps.FACE_FEATURES
    local result = {}

    for key, mapping in pairs(features) do
        local raw = 50  -- default mid
        if mapping.type == "trait" and genome and genome.get_value then
            raw = genome:get_value(mapping.source) or 50
        elseif mapping.type == "personality" and personality and personality.get_axis then
            raw = personality:get_axis(mapping.source) or 50
        end

        -- Normalize to 0-1
        local normalized = raw / 100
        if mapping.invert then
            normalized = 1 - normalized
        end
        result[key] = normalized
    end

    return result
end

--- Calculate a deterministic seed from genome trait values.
---@param genome table Genome instance
---@return number hash value for deterministic jitter
function PortraitData.calculate_seed(genome)
    if not genome then return 0 end

    local hash = 5381
    local trait_ids = {
        "PHY_STR", "PHY_END", "PHY_REF", "PHY_VIT", "PHY_AGI",
        "PHY_PAI", "PHY_FER", "PHY_LON", "PHY_IMM", "PHY_REC",
        "PHY_BON", "PHY_LUN", "PHY_COR", "PHY_MET", "PHY_HGT",
        "PHY_BLD", "PHY_SEN", "PHY_ADP",
        "PHY_EYE", "PHY_HAI", "PHY_SKN", "PHY_HTX", "PHY_FSH",
        "MEN_INT", "MEN_MEM", "MEN_FOC", "MEN_WIL", "MEN_PER",
        "MEN_ANA", "MEN_PAT", "MEN_ITU", "MEN_LRN", "MEN_COM",
        "MEN_SPA", "MEN_STR", "MEN_CUN", "MEN_PLA", "MEN_DRM",
        "MEN_STH", "MEN_ABS", "MEN_DEC",
        "SOC_CHA", "SOC_EMP", "SOC_INM", "SOC_ELO", "SOC_DEC",
        "SOC_TRU", "SOC_LEA", "SOC_NEG", "SOC_AWR", "SOC_INF",
        "SOC_LYS", "SOC_PAK", "SOC_CON", "SOC_TEA", "SOC_MAN",
        "SOC_CRD", "SOC_CUL", "SOC_HUM",
        "CRE_ING", "CRE_CRA", "CRE_EXP", "CRE_AES", "CRE_IMP",
        "CRE_VIS", "CRE_NAR", "CRE_MEC", "CRE_MUS", "CRE_ARC",
        "CRE_SYM", "CRE_RES", "CRE_INN", "CRE_FLV", "CRE_RIT",
        "CRE_TIN",
    }

    for _, tid in ipairs(trait_ids) do
        local v = (genome.get_value and genome:get_value(tid)) or 50
        -- djb2 hash variant
        hash = ((hash * 33) + v) % 2147483647
    end

    return hash
end

--- Calculate polygon vertices for smooth body silhouette.
--- Returns a flat array of x,y pairs (~30 vertices) for display.newPolygon.
--- All coordinates relative to center origin, in 100x100 space (caller scales).
---@param silhouette table from calculate_silhouette()
---@return table flat array of vertex coordinates {x1, y1, x2, y2, ...}
function PortraitData.calculate_polygon_vertices(silhouette)
    local sil = silhouette or { head_radius = 16, neck_width = 6, shoulder_width = 28, height_offset = 0 }
    local hr = sil.head_radius or 16
    local nw = (sil.neck_width or 6) / 2
    local sw = (sil.shoulder_width or 28) / 2
    local yShift = sil.height_offset or 0
    local head_cy = -18 + yShift

    local verts = {}
    local function add(x, y) verts[#verts + 1] = x; verts[#verts + 1] = y end

    -- Calculate the angle where the head meets the neck on each side.
    -- Neck attaches 2px above the bottom of the head circle.
    local neck_y = head_cy + hr - 2
    local neck_sin = math.max(-1, math.min(1, (neck_y - head_cy) / hr))
    local neck_angle = math.asin(neck_sin)  -- angle from horizontal

    -- Single continuous outline:
    -- 1. Head arc: from left-neck junction, OVER THE TOP, down to right-neck junction
    --    Left junction angle = π - neck_angle (~2.08 rad, lower-left of circle)
    --    Right junction angle = neck_angle (~1.06 rad, lower-right of circle)
    --    We go counter-clockwise (increasing angle): left → π → 3π/2 (top) → 2π → right
    local arc_start = math.pi - neck_angle  -- left neck junction
    local arc_end = neck_angle               -- right neck junction
    -- Long arc over the top: 2π minus the short arc through the bottom
    local arc_sweep = (2 * math.pi) - (arc_start - arc_end)
    local arc_pts = 18
    for i = 0, arc_pts do
        local angle = arc_start + (arc_sweep * i / arc_pts)  -- increasing = over the top
        add(math.cos(angle) * hr, head_cy + math.sin(angle) * hr)
    end

    -- 2. Jawline right: smooth transition from head arc endpoint to neck
    local jaw_x = math.cos(arc_end) * hr  -- where the head arc ends (~x=7.75)
    add(jaw_x * 0.6, neck_y - 1)          -- jaw curve inward
    add(nw + 1.5, neck_y + 1)             -- jaw-to-neck blend

    -- 3. Right side: neck → shoulder → torso → bottom
    add(nw, neck_y + 3 + yShift)           -- neck right
    add(nw + 2, neck_y + 6 + yShift)   -- neck→shoulder transition
    add(sw * 0.7, 2 + yShift)
    add(sw, 4 + yShift)
    add(sw, 8 + yShift)
    add(sw * 0.85, 14 + yShift)
    add(sw * 0.6, 26 + yShift)
    add(sw * 0.5, 34 + yShift)         -- bottom right

    -- 4. Bottom center
    add(0, 36 + yShift)

    -- 5. Left side: bottom → torso → shoulder → neck (mirror of right)
    add(-sw * 0.5, 34 + yShift)
    add(-sw * 0.6, 26 + yShift)
    add(-sw * 0.85, 14 + yShift)
    add(-sw, 8 + yShift)
    add(-sw, 4 + yShift)
    add(-sw * 0.7, 2 + yShift)
    add(-nw - 2, neck_y + 6 + yShift)
    add(-nw, neck_y + 3 + yShift)         -- neck left

    -- 6. Jawline left: smooth transition from neck back to head arc start
    add(-nw - 1.5, neck_y + 1)
    add(-jaw_x * 0.6, neck_y - 1)         -- jaw curve (closes back to head arc start)

    return verts
end

--- Calculate animation parameters from personality for advanced portrait modes.
---@param personality table Personality instance (optional)
---@return table { eye_pulse_period, mark_breathe_period, glow_amplitude }
function PortraitData.calculate_animation_params(personality)
    if not personality or not personality.get_axis then
        return { eye_pulse_period = 3000, mark_breathe_period = 4000, glow_amplitude = 0.15 }
    end

    local vol = personality:get_axis("PER_VOL") or 50
    local obs = personality:get_axis("PER_OBS") or 50

    -- Volatile → faster pulse; stoic → slow/static
    local speed_factor = 0.5 + (vol / 100) * 1.5 -- 0.5x to 2.0x

    -- Obsessed → higher glow amplitude
    local glow_amp = 0.10 + (obs / 100) * 0.20

    return {
        eye_pulse_period = math.floor(3000 / speed_factor),
        mark_breathe_period = math.floor(4000 / speed_factor),
        glow_amplitude = glow_amp,
    }
end

--- Master function: generate complete portrait descriptor.
---@param genome table Genome instance
---@param personality table Personality instance (optional)
---@param size number portrait size (100, 70, 50, or 40)
---@return table complete portrait descriptor for rendering
function PortraitData.generate(genome, personality, size)
    size = size or 100

    -- Determine mark cap from size
    local caps = portrait_maps.MARK_CAPS
    local cap = caps[size]
    if not cap then
        -- Find closest size
        cap = 6
        for s, c in pairs(caps) do
            if size >= s then cap = c end
        end
    end

    local silhouette = PortraitData.calculate_silhouette(genome)
    local marks = PortraitData.calculate_marks(genome, cap)
    local eyes = PortraitData.calculate_eyes(personality)
    local face = PortraitData.calculate_face(genome, personality)
    local seed = PortraitData.calculate_seed(genome)

    -- Detection for Hook 2: Visual Decay (Blight)
    local vitality = (genome and genome.get_value and genome:get_value("PHY_VIT")) or 50
    local is_blighted = vitality < 25

    -- Detection for Hook 1: Shadow Lineage Marks
    local shadow_mark = nil
    if genome and genome.origin_faction_id and genome.origin_faction_id:find("^shadow_") then
        -- This genome belongs to a shadow lineage
        -- We can try to infer the mark if the faction data is passed or by faction ID
        shadow_mark = "shadow" -- generic shadow indicator for now
    end

    return {
        size = size,
        silhouette = silhouette,
        marks = marks,
        eyes = eyes,
        face = face,
        seed = seed,
        is_blighted = is_blighted,
        shadow_mark = shadow_mark,
        slots = portrait_maps.SLOTS,
        shapes = portrait_maps.SHAPES,
        category_colors = portrait_maps.CATEGORY_COLORS,
    }
end

return PortraitData
