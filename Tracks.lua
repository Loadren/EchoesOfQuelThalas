local _, ns = ...

-- ============================================================
-- Track catalog — every original TBC music file for the
-- Eversong Woods and Ghostlands zones, keyed by name,
-- valued by FileDataID (from the wowdev community listfile).
--
-- Naming convention follows the original game files:
--   ES_ = Eversong,  GL_ = Ghostlands
--   Day/Night/Uni     = time-of-day variant (Uni = all day)
-- ============================================================

ns.Tracks = {

    -- Eversong > Buildings --------------------------------
    ES_BuildingWalkDay01       = 53458,
    ES_BuildingWalkDay02       = 53459,
    ES_BuildingWalkNight01     = 53460,
    ES_BuildingWalkNight02     = 53461,

    -- Eversong > Ruins (Dead Scar, etc.) ------------------
    ES_RuinsWalkDay01          = 53462,
    ES_RuinsWalkDay02          = 53463,
    ES_RuinsWalkDay03          = 53464,
    ES_RuinsWalkNight01        = 53465,
    ES_RuinsWalkNight02        = 53466,
    ES_RuinsWalkNight03        = 53467,

    -- Eversong > Scenic -----------------------------------
    ES_ScenicIntroNight01      = 53468,

    -- Eversong > Scorched (Scar areas) --------------------
    ES_ScortchedWalkDay01      = 53469,
    ES_ScortchedWalkDay02      = 53470,
    ES_ScortchedWalkNight01    = 53471,
    ES_ScortchedWalkNight02    = 53472,

    -- Silvermoon City -------------------------------------
    ES_SilvermoonIntro01       = 53473,
    ES_SilvermoonWalkDay01     = 53474,
    ES_SilvermoonWalkDay02     = 53475,
    ES_SilvermoonWalkDay03     = 53476,
    ES_SilvermoonWalkNight01   = 53477,
    ES_SilvermoonWalkNight02   = 53478,
    ES_SilvermoonWalkNight03   = 53479,

    -- Eversong > Sunstrider Isle --------------------------
    ES_SunstriderWalkDay01     = 53480,
    ES_SunstriderWalkDay02     = 53481,
    ES_SunstriderWalkDay03     = 53482,
    ES_SunstriderWalkNight01   = 53483,
    ES_SunstriderWalkNight02   = 53484,
    ES_SunstriderWalkNight03   = 53485,

    -- Ghostlands > Dark Eversong --------------------------
    GL_EversongDarkWalkUni01   = 53499,
    GL_EversongDarkWalkUni02   = 53500,
    GL_EversongDarkWalkUni03   = 53501,
    GL_EversongDarkWalkUni04   = 53502,

    -- Ghostlands > Forest 1 -------------------------------
    GL_Forest1WalkDay01        = 53503,
    GL_Forest1WalkDay02        = 53504,
    GL_Forest1WalkNight01      = 53505,

    -- Ghostlands > Forest 2 -------------------------------
    GL_Forest2WalkDay01        = 53506,
    GL_Forest2WalkNight01      = 53507,
    GL_Forest2WalkNight02      = 53508,

    -- Ghostlands > Forest 3 -------------------------------
    GL_Forest3WalkDay01        = 53509,
    GL_Forest3WalkNight01      = 53510,
    GL_Forest3WalkNight02      = 53511,
    GL_Forest3WalkNight03      = 53512,

    -- Ghostlands > Scenic ---------------------------------
    GL_ScenicWalkUni01         = 53513,
    GL_ScenicWalkUni02         = 53514,
    GL_ScenicWalkUni03         = 53515,

    -- Ghostlands > Shal'andis Isle (Windrunner Village) ---
    GL_ShalandisWalkUni01      = 53516,
    GL_ShalandisWalkUni02      = 53517,
    GL_ShalandisWalkUni03      = 53518,
}

-- ============================================================
-- Track durations (seconds) — extracted from the game audio
-- files via ffprobe.  Keyed by FileDataID so the engine can
-- schedule the next track when the current one finishes
-- instead of looping on a fixed timer.
-- ============================================================

ns.TrackDurations = {
    [53458] =  65.3,   -- ES_BuildingWalkDay01
    [53459] =  68.6,   -- ES_BuildingWalkDay02
    [53460] =  84.4,   -- ES_BuildingWalkNight01
    [53461] =  83.6,   -- ES_BuildingWalkNight02
    [53462] =  48.1,   -- ES_RuinsWalkDay01
    [53463] =  72.0,   -- ES_RuinsWalkDay02
    [53464] =  70.8,   -- ES_RuinsWalkDay03
    [53465] =  50.9,   -- ES_RuinsWalkNight01
    [53466] =  83.4,   -- ES_RuinsWalkNight02
    [53467] =  67.2,   -- ES_RuinsWalkNight03
    [53468] =  97.4,   -- ES_ScenicIntroNight01
    [53469] = 116.6,   -- ES_ScortchedWalkDay01
    [53470] = 102.8,   -- ES_ScortchedWalkDay02
    [53471] =  69.4,   -- ES_ScortchedWalkNight01
    [53472] =  61.0,   -- ES_ScortchedWalkNight02
    [53473] = 132.3,   -- ES_SilvermoonIntro01
    [53474] =  64.2,   -- ES_SilvermoonWalkDay01
    [53475] =  79.5,   -- ES_SilvermoonWalkDay02
    [53476] =  65.0,   -- ES_SilvermoonWalkDay03
    [53477] = 177.5,   -- ES_SilvermoonWalkNight01
    [53478] =  71.7,   -- ES_SilvermoonWalkNight02
    [53479] =  80.0,   -- ES_SilvermoonWalkNight03
    [53480] =  80.6,   -- ES_SunstriderWalkDay01
    [53481] =  58.4,   -- ES_SunstriderWalkDay02
    [53482] =  67.3,   -- ES_SunstriderWalkDay03
    [53483] = 100.2,   -- ES_SunstriderWalkNight01
    [53484] = 100.6,   -- ES_SunstriderWalkNight02
    [53485] =  86.2,   -- ES_SunstriderWalkNight03
    [53499] =  62.4,   -- GL_EversongDarkWalkUni01
    [53500] =  62.2,   -- GL_EversongDarkWalkUni02
    [53501] =  63.9,   -- GL_EversongDarkWalkUni03
    [53502] =  60.8,   -- GL_EversongDarkWalkUni04
    [53503] =  66.9,   -- GL_Forest1WalkDay01
    [53504] =  70.4,   -- GL_Forest1WalkDay02
    [53505] =  67.3,   -- GL_Forest1WalkNight01
    [53506] =  83.0,   -- GL_Forest2WalkDay01
    [53507] =  59.6,   -- GL_Forest2WalkNight01
    [53508] =  60.6,   -- GL_Forest2WalkNight02
    [53509] = 154.2,   -- GL_Forest3WalkDay01
    [53510] =  51.3,   -- GL_Forest3WalkNight01
    [53511] =  28.1,   -- GL_Forest3WalkNight02
    [53512] =  44.4,   -- GL_Forest3WalkNight03
    [53513] =  89.5,   -- GL_ScenicWalkUni01
    [53514] =  81.3,   -- GL_ScenicWalkUni02
    [53515] =  78.1,   -- GL_ScenicWalkUni03
    [53516] = 131.7,   -- GL_ShalandisWalkUni01
    [53517] = 104.0,   -- GL_ShalandisWalkUni02
    [53518] =  67.8,   -- GL_ShalandisWalkUni03
}
