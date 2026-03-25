-- Dark Legacy — Portrait Data Maps
-- All mapping constants for procedural portrait generation.
-- Data only. No logic, no dependencies.

return {
    -- 12 mark anchor slots (relative to 100x100, origin center)
    SLOTS = {
        forehead       = { x = 0,   y = -36 },
        left_temple    = { x = -14, y = -26 },
        right_temple   = { x = 14,  y = -26 },
        left_eye       = { x = -7,  y = -22 },
        right_eye      = { x = 7,   y = -22 },
        throat         = { x = 0,   y = -10 },
        heart          = { x = 0,   y = 4   },
        left_shoulder  = { x = -22, y = 4   },
        right_shoulder = { x = 22,  y = 4   },
        left_arm       = { x = -28, y = 16  },
        right_arm      = { x = 28,  y = 16  },
        core           = { x = 0,   y = 18  },
    },

    -- 6 mark shape types
    SHAPES = {
        dot     = { type = "circle", radius = 2.5 },
        diamond = { type = "rect",   w = 4, h = 4, rotation = 45 },
        line_h  = { type = "line",   dx = 8, dy = 0 },
        line_v  = { type = "line",   dx = 0, dy = 8 },
        cross   = { type = "cross",  arm = 6 },
        ring    = { type = "circle", radius = 3.5, fill = false, stroke = 1 },
    },

    -- 70 trait-to-mark mappings (all 70 traits now represented)
    TRAIT_MARKS = {
        -- PHYSICAL (18)
        { id = "PHY_STR", slot = "left_shoulder",  shape = "line_h",  cat = "physical" },
        { id = "PHY_END", slot = "right_shoulder", shape = "line_h",  cat = "physical" },
        { id = "PHY_REF", slot = "right_temple",   shape = "diamond", cat = "physical" },
        { id = "PHY_VIT", slot = "heart",           shape = "dot",     cat = "physical" },
        { id = "PHY_AGI", slot = "left_arm",        shape = "diamond", cat = "physical" },
        { id = "PHY_PAI", slot = "left_shoulder",   shape = "cross",   cat = "physical" },
        { id = "PHY_SEN", slot = "left_temple",     shape = "dot",     cat = "physical" },
        { id = "PHY_COR", slot = "right_arm",       shape = "dot",     cat = "physical" },
        { id = "PHY_FER", slot = "core",            shape = "ring",    cat = "physical" },
        { id = "PHY_LON", slot = "core",            shape = "dot",     cat = "physical" },
        { id = "PHY_IMM", slot = "heart",           shape = "cross",   cat = "physical" },
        { id = "PHY_REC", slot = "heart",           shape = "line_v",  cat = "physical" },
        { id = "PHY_BON", slot = "left_arm",        shape = "line_v",  cat = "physical" },
        { id = "PHY_LUN", slot = "throat",          shape = "line_h",  cat = "physical" },
        { id = "PHY_MET", slot = "core",            shape = "line_v",  cat = "physical" },
        { id = "PHY_HGT", slot = "right_shoulder",  shape = "line_v",  cat = "physical" },
        { id = "PHY_BLD", slot = "left_shoulder",   shape = "line_v",  cat = "physical" },
        { id = "PHY_ADP", slot = "right_arm",       shape = "cross",   cat = "physical" },

        -- MENTAL (18)
        { id = "MEN_INT", slot = "forehead",        shape = "diamond", cat = "mental" },
        { id = "MEN_MEM", slot = "left_temple",     shape = "line_h",  cat = "mental" },
        { id = "MEN_FOC", slot = "forehead",        shape = "dot",     cat = "mental" },
        { id = "MEN_WIL", slot = "throat",          shape = "line_v",  cat = "mental" },
        { id = "MEN_PER", slot = "right_temple",    shape = "dot",     cat = "mental" },
        { id = "MEN_ANA", slot = "left_temple",     shape = "diamond", cat = "mental" },
        { id = "MEN_PAT", slot = "right_temple",    shape = "diamond", cat = "mental" },
        { id = "MEN_ITU", slot = "forehead",        shape = "cross",   cat = "mental" },
        { id = "MEN_LRN", slot = "left_temple",     shape = "ring",    cat = "mental" },
        { id = "MEN_COM", slot = "core",            shape = "dot",     cat = "mental" },
        { id = "MEN_SPA", slot = "right_temple",    shape = "ring",    cat = "mental" },
        { id = "MEN_STR", slot = "forehead",        shape = "line_v",  cat = "mental" },
        { id = "MEN_CUN", slot = "right_eye",       shape = "line_h",  cat = "mental" },
        { id = "MEN_PLA", slot = "left_eye",        shape = "line_h",  cat = "mental" },
        { id = "MEN_DRM", slot = "forehead",        shape = "line_h",  cat = "mental" },
        { id = "MEN_STH", slot = "throat",          shape = "cross",   cat = "mental" },
        { id = "MEN_ABS", slot = "throat",          shape = "ring",    cat = "mental" },
        { id = "MEN_DEC", slot = "throat",          shape = "diamond", cat = "mental" },

        -- SOCIAL (18)
        { id = "SOC_CHA", slot = "heart",           shape = "ring",    cat = "social" },
        { id = "SOC_EMP", slot = "heart",           shape = "dot",     cat = "social" },
        { id = "SOC_INM", slot = "left_shoulder",   shape = "line_v",  cat = "social" },
        { id = "SOC_ELO", slot = "throat",          shape = "ring",    cat = "social" },
        { id = "SOC_DEC", slot = "left_eye",        shape = "line_h",  cat = "social" },
        { id = "SOC_TRU", slot = "right_eye",       shape = "dot",     cat = "social" },
        { id = "SOC_LEA", slot = "forehead",        shape = "cross",   cat = "social" },
        { id = "SOC_NEG", slot = "right_arm",       shape = "line_v",  cat = "social" },
        { id = "SOC_AWR", slot = "right_temple",    shape = "cross",   cat = "social" },
        { id = "SOC_INF", slot = "left_arm",        shape = "ring",    cat = "social" },
        { id = "SOC_LYS", slot = "heart",           shape = "diamond", cat = "social" },
        { id = "SOC_PAK", slot = "core",            shape = "cross",   cat = "social" },
        { id = "SOC_CON", slot = "left_shoulder",   shape = "diamond", cat = "social" },
        { id = "SOC_TEA", slot = "right_arm",       shape = "ring",    cat = "social" },
        { id = "SOC_MAN", slot = "left_eye",        shape = "diamond", cat = "social" },
        { id = "SOC_CRD", slot = "right_eye",       shape = "diamond", cat = "social" },
        { id = "SOC_CUL", slot = "left_temple",     shape = "cross",   cat = "social" },
        { id = "SOC_HUM", slot = "core",            shape = "diamond", cat = "social" },

        -- CREATIVE (16)
        { id = "CRE_ING", slot = "forehead",        shape = "ring",    cat = "creative" },
        { id = "CRE_CRA", slot = "right_arm",       shape = "line_h",  cat = "creative" },
        { id = "CRE_EXP", slot = "core",            shape = "ring",    cat = "creative" },
        { id = "CRE_AES", slot = "right_eye",       shape = "ring",    cat = "creative" },
        { id = "CRE_IMP", slot = "right_shoulder",  shape = "diamond", cat = "creative" },
        { id = "CRE_VIS", slot = "left_eye",        shape = "diamond", cat = "creative" },
        { id = "CRE_NAR", slot = "left_temple",     shape = "line_v",  cat = "creative" },
        { id = "CRE_MEC", slot = "left_arm",        shape = "cross",   cat = "creative" },
        { id = "CRE_MUS", slot = "right_temple",    shape = "line_v",  cat = "creative" },
        { id = "CRE_ARC", slot = "right_shoulder",  shape = "cross",   cat = "creative" },
        { id = "CRE_SYM", slot = "forehead",        shape = "line_v",  cat = "creative" },
        { id = "CRE_RES", slot = "left_arm",        shape = "line_h",  cat = "creative" },
        { id = "CRE_INN", slot = "right_arm",       shape = "diamond", cat = "creative" },
        { id = "CRE_FLV", slot = "throat",          shape = "dot",     cat = "creative" },
        { id = "CRE_RIT", slot = "heart",           shape = "cross",   cat = "creative" },
        { id = "CRE_TIN", slot = "left_arm",        shape = "dot",     cat = "creative" },

        -- APPEARANCE (5)
        { id = "PHY_EYE", mark = "piercing_gaze",     threshold = 80, layer = "face" },
        { id = "PHY_HAI", mark = "wild_mane",          threshold = 80, layer = "hair" },
        { id = "PHY_SKN", mark = "weathered_skin",     threshold = 80, layer = "skin" },
        { id = "PHY_HTX", mark = "textured_hair",      threshold = 80, layer = "hair" },
        { id = "PHY_FSH", mark = "chiseled_features",  threshold = 80, layer = "face" },
    },

    -- Eye styles driven by most extreme personality axis
    EYE_STYLES = {
        PER_CRM = {
            high = { color = {0.80, 0.15, 0.10}, shape = "line_h", alpha = 0.8 },
            low  = { color = {0.40, 0.60, 0.85}, shape = "dot_soft", alpha = 0.7 },
        },
        PER_BLD = {
            high = { color = {0.90, 0.80, 0.40}, shape = "dot", alpha = 0.9 },
            low  = { color = {0.50, 0.50, 0.50}, shape = "dot_dim", alpha = 0.4 },
        },
        PER_VOL = {
            high = { color = {0.85, 0.50, 0.15}, shape = "dot", alpha = 0.8 },
            low  = { color = {0.45, 0.45, 0.50}, shape = "dot", alpha = 0.5 },
        },
        PER_OBS = {
            high = { color = {0.75, 0.70, 0.90}, shape = "dot_large", alpha = 1.0 },
            low  = { color = {0.50, 0.50, 0.50}, shape = "dot_dim", alpha = 0.3 },
        },
        PER_CUR = {
            high = { color = {0.45, 0.75, 0.65}, shape = "ring", alpha = 0.7 },
            low  = { color = {0.50, 0.45, 0.40}, shape = "dot", alpha = 0.5 },
        },
        PER_PRI = {
            high = { color = {0.85, 0.75, 0.40}, shape = "dot", alpha = 0.9 },
            low  = { color = {0.45, 0.45, 0.45}, shape = "dot_dim", alpha = 0.4 },
        },
        PER_LOY = {
            high = { color = {0.60, 0.55, 0.40}, shape = "dot", alpha = 0.7 },
            low  = { color = {0.55, 0.40, 0.35}, shape = "dot", alpha = 0.5 },
        },
        PER_ADA = {
            high = { color = {0.50, 0.65, 0.55}, shape = "dot", alpha = 0.7 },
            low  = { color = {0.55, 0.45, 0.40}, shape = "dot", alpha = 0.5 },
        },
        neutral = { color = {0.55, 0.50, 0.45}, shape = "dot", alpha = 0.5 },
    },

    -- Mark cap by portrait size
    MARK_CAPS = { [100] = 6, [70] = 5, [50] = 3, [40] = 3 },

    -- Category glow colors for marks
    CATEGORY_COLORS = {
        physical = { 0.70, 0.45, 0.30 },
        mental   = { 0.35, 0.55, 0.75 },
        social   = { 0.55, 0.70, 0.40 },
        creative = { 0.65, 0.40, 0.65 },
    },

    -- Silhouette body color
    SILHOUETTE_FILL = { 0.08, 0.07, 0.10 },

    -- Geometric face feature mappings (trait/personality → normalized 0-1 proportions)
    FACE_FEATURES = {
        eye_width       = { source = "MEN_PER", type = "trait" },
        eye_height      = { source = "PER_CRM", type = "personality", invert = true },
        brow_angle      = { source = "SOC_INM", type = "trait" },
        mouth_width     = { source = "SOC_CHA", type = "trait" },
        mouth_curve     = { source = "PER_CRM", type = "personality", invert = true },
        jaw_width       = { source = "PHY_BLD", type = "trait" },
        forehead_height = { source = "MEN_INT", type = "trait" },
        nose_length     = { source = "PER_PRI", type = "personality" },
    },
}
