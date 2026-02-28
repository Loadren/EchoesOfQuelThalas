local _, ns = ...
local T = ns.Tracks

-- ============================================================
-- Music Packs — predefined track collections users can assign
-- to any zone or subzone via the settings panel.
--
-- Each pack mirrors the zone-config schema:
--   label  = display name for the UI
--   day    = { FileDataID, ... }   (06:00–20:59)
--   night  = { FileDataID, ... }   (21:00–05:59)
--   any    = { FileDataID, ... }   (merged into active pool)
--   intro  = FileDataID            (optional, plays once)
-- ============================================================

ns.MusicPacks = {

    EVERSONG = {
        label = "Eversong Woods",
        day = {
            T.ES_BuildingWalkDay01,
            T.ES_BuildingWalkDay02,
            T.ES_RuinsWalkDay01,
            T.ES_RuinsWalkDay02,
            T.ES_RuinsWalkDay03,
            T.ES_SunstriderWalkDay01,
            T.ES_SunstriderWalkDay02,
            T.ES_SunstriderWalkDay03,
        },
        night = {
            T.ES_BuildingWalkNight01,
            T.ES_BuildingWalkNight02,
            T.ES_RuinsWalkNight01,
            T.ES_RuinsWalkNight02,
            T.ES_RuinsWalkNight03,
            T.ES_SunstriderWalkNight01,
            T.ES_SunstriderWalkNight02,
            T.ES_SunstriderWalkNight03,
            T.ES_ScenicIntroNight01,
        },
    },

    SILVERMOON = {
        label = "Silvermoon City",
        intro = T.ES_SilvermoonIntro01,
        day = {
            T.ES_SilvermoonWalkDay01,
            T.ES_SilvermoonWalkDay02,
            T.ES_SilvermoonWalkDay03,
        },
        night = {
            T.ES_SilvermoonWalkNight01,
            T.ES_SilvermoonWalkNight02,
            T.ES_SilvermoonWalkNight03,
        },
    },

    SCORCHED = {
        label = "Scorched Lands",
        day = {
            T.ES_ScortchedWalkDay01,
            T.ES_ScortchedWalkDay02,
        },
        night = {
            T.ES_ScortchedWalkNight01,
            T.ES_ScortchedWalkNight02,
        },
    },

    GHOSTLANDS_FOREST = {
        label = "Ghostlands Forest",
        day = {
            T.GL_Forest1WalkDay01,
            T.GL_Forest1WalkDay02,
            T.GL_Forest2WalkDay01,
            T.GL_Forest3WalkDay01,
        },
        night = {
            T.GL_Forest1WalkNight01,
            T.GL_Forest2WalkNight01,
            T.GL_Forest2WalkNight02,
            T.GL_Forest3WalkNight01,
            T.GL_Forest3WalkNight02,
            T.GL_Forest3WalkNight03,
        },
    },

    GHOSTLANDS_DARK = {
        label = "Dark Ghostlands",
        any = {
            T.GL_EversongDarkWalkUni01,
            T.GL_EversongDarkWalkUni02,
            T.GL_EversongDarkWalkUni03,
            T.GL_EversongDarkWalkUni04,
        },
    },

    GHOSTLANDS_SCENIC = {
        label = "Ghostlands Scenic",
        any = {
            T.GL_ScenicWalkUni01,
            T.GL_ScenicWalkUni02,
            T.GL_ScenicWalkUni03,
        },
    },

    SHALANDIS = {
        label = "Shal'andis Isle",
        any = {
            T.GL_ShalandisWalkUni01,
            T.GL_ShalandisWalkUni02,
            T.GL_ShalandisWalkUni03,
        },
    },

    GHOSTLANDS_FULL = {
        label = "Full Ghostlands",
        day = {
            T.GL_Forest1WalkDay01,
            T.GL_Forest1WalkDay02,
            T.GL_Forest2WalkDay01,
            T.GL_Forest3WalkDay01,
        },
        night = {
            T.GL_Forest1WalkNight01,
            T.GL_Forest2WalkNight01,
            T.GL_Forest2WalkNight02,
            T.GL_Forest3WalkNight01,
            T.GL_Forest3WalkNight02,
            T.GL_Forest3WalkNight03,
        },
        any = {
            T.GL_EversongDarkWalkUni01,
            T.GL_EversongDarkWalkUni02,
            T.GL_EversongDarkWalkUni03,
            T.GL_EversongDarkWalkUni04,
            T.GL_ScenicWalkUni01,
            T.GL_ScenicWalkUni02,
            T.GL_ScenicWalkUni03,
            T.GL_ShalandisWalkUni01,
            T.GL_ShalandisWalkUni02,
            T.GL_ShalandisWalkUni03,
        },
    },

    EVERSONG_NIGHT = {
        label = "Eversong Night",
        night = {
            T.ES_BuildingWalkNight01,
            T.ES_BuildingWalkNight02,
            T.ES_RuinsWalkNight01,
            T.ES_RuinsWalkNight02,
            T.ES_RuinsWalkNight03,
            T.ES_SunstriderWalkNight01,
            T.ES_SunstriderWalkNight02,
            T.ES_SunstriderWalkNight03,
            T.ES_ScenicIntroNight01,
        },
    },

    QUELDANAS = {
        label = "Isle of Quel'Danas",
        any = {
            T.GL_EversongDarkWalkUni01,
            T.GL_EversongDarkWalkUni02,
            T.GL_EversongDarkWalkUni03,
            T.GL_EversongDarkWalkUni04,
            T.GL_ScenicWalkUni01,
            T.GL_ScenicWalkUni02,
            T.GL_ScenicWalkUni03,
        },
    },
}

-- Stable ordering for dropdown menus
ns.MusicPackOrder = {
    "EVERSONG",
    "SILVERMOON",
    "SCORCHED",
    "GHOSTLANDS_FOREST",
    "GHOSTLANDS_DARK",
    "GHOSTLANDS_SCENIC",
    "SHALANDIS",
    "GHOSTLANDS_FULL",
    "EVERSONG_NIGHT",
    "QUELDANAS",
}
