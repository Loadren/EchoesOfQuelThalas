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
--
-- Three packs per main zone: (TBC), (Midnight), (TBC + Midnight).
-- Subzone utility packs (SCORCHED, QUELDANAS) are listed after.
-- ============================================================

ns.MusicPacks = {

    -- --------------------------------------------------------
    -- Silvermoon City
    -- --------------------------------------------------------

    SILVERMOON = {
        label = "Silvermoon (TBC)",
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

    SILVERMOON_MIDNIGHT = {
        label = "Silvermoon (Midnight)",
        any = {
            T.MN_SilvermoonCityA,
            T.MN_SilvermoonCityB,
            T.MN_SilvermoonCityC,
            T.MN_SilvermoonCityD,
            T.MN_SilvermoonCityE,
            T.MN_SilvermoonCityF,
            T.MN_SilvermoonCityG,
            T.MN_SilvermoonCityH,
            T.MN_SilvermoonCityI,
            T.MN_SilvermoonCityJ,
            T.MN_SilvermoonHordeA,
            T.MN_SilvermoonHordeB,
            T.MN_SilvermoonHordeC,
        },
    },

    SILVERMOON_MIXED = {
        label = "Silvermoon (TBC + Midnight)",
        intro = T.ES_SilvermoonIntro01,
        day = {
            T.ES_SilvermoonWalkDay01,
            T.ES_SilvermoonWalkDay02,
            T.ES_SilvermoonWalkDay03,
            T.MN_SilvermoonCityA,
            T.MN_SilvermoonCityB,
            T.MN_SilvermoonCityC,
            T.MN_SilvermoonCityD,
            T.MN_SilvermoonCityE,
            T.MN_SilvermoonCityF,
            T.MN_SilvermoonCityG,
            T.MN_SilvermoonCityH,
            T.MN_SilvermoonCityI,
            T.MN_SilvermoonCityJ,
            T.MN_SilvermoonHordeA,
            T.MN_SilvermoonHordeB,
            T.MN_SilvermoonHordeC,
        },
        night = {
            T.ES_SilvermoonWalkNight01,
            T.ES_SilvermoonWalkNight02,
            T.ES_SilvermoonWalkNight03,
            T.MN_SilvermoonCityA,
            T.MN_SilvermoonCityB,
            T.MN_SilvermoonCityC,
            T.MN_SilvermoonCityD,
            T.MN_SilvermoonCityE,
            T.MN_SilvermoonCityF,
            T.MN_SilvermoonCityG,
            T.MN_SilvermoonCityH,
            T.MN_SilvermoonCityI,
            T.MN_SilvermoonCityJ,
        },
    },

    -- --------------------------------------------------------
    -- Eversong Woods
    -- --------------------------------------------------------

    EVERSONG = {
        label = "Eversong (TBC)",
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

    EVERSONG_MIDNIGHT = {
        label = "Eversong (Midnight)",
        day = {
            T.MN_EversongBaseDayA,
            T.MN_EversongBaseDayB,
            T.MN_EversongBaseDayC,
            T.MN_EversongBaseDayD,
            T.MN_EversongBaseDayE,
            T.MN_SunstriderDayA,
            T.MN_SunstriderDayB,
            T.MN_SunstriderDayC,
        },
        night = {
            T.MN_EversongBaseNightA,
            T.MN_EversongBaseNightB,
            T.MN_EversongBaseNightC,
            T.MN_EversongBaseNightD,
            T.MN_EversongBaseNightE,
            T.MN_SunstriderNightA,
            T.MN_SunstriderNightB,
            T.MN_SunstriderNightC,
        },
        any = {
            T.MN_EversongBaseUni01,
            T.MN_EversongVillageA,
            T.MN_EversongVillageB,
            T.MN_EversongVillageC,
            T.MN_TranquillienA,
        },
    },

    EVERSONG_MIXED = {
        label = "Eversong (TBC + Midnight)",
        day = {
            T.ES_BuildingWalkDay01,
            T.ES_BuildingWalkDay02,
            T.ES_RuinsWalkDay01,
            T.ES_RuinsWalkDay02,
            T.ES_RuinsWalkDay03,
            T.ES_SunstriderWalkDay01,
            T.ES_SunstriderWalkDay02,
            T.ES_SunstriderWalkDay03,
            T.MN_EversongBaseDayA,
            T.MN_EversongBaseDayB,
            T.MN_EversongBaseDayC,
            T.MN_EversongBaseDayD,
            T.MN_EversongBaseDayE,
            T.MN_SunstriderDayA,
            T.MN_SunstriderDayB,
            T.MN_SunstriderDayC,
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
            T.MN_EversongBaseNightA,
            T.MN_EversongBaseNightB,
            T.MN_EversongBaseNightC,
            T.MN_EversongBaseNightD,
            T.MN_EversongBaseNightE,
            T.MN_SunstriderNightA,
            T.MN_SunstriderNightB,
            T.MN_SunstriderNightC,
        },
        any = {
            T.MN_EversongBaseUni01,
            T.MN_EversongVillageA,
            T.MN_EversongVillageB,
            T.MN_EversongVillageC,
            T.MN_TranquillienA,
        },
    },

    -- --------------------------------------------------------
    -- Ghostlands
    -- --------------------------------------------------------

    GHOSTLANDS = {
        label = "Ghostlands (TBC)",
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
            -- Outland Blood Elf Base (Tranquillien / Hatchet Hills feel)
            T.OL_BloodElfBaseWalkUni01,
            T.OL_BloodElfBaseWalkUni02,
        },
    },

    GHOSTLANDS_MIDNIGHT = {
        label = "Ghostlands (Midnight)",
        any = {
            T.MN_WindrunnerA,
            T.MN_WindrunnerB,
            T.MN_WindrunnerC,
            T.MN_WindrunnerD,
            T.MN_WindrunnerE,
            T.MN_WindrunnerF,
        },
    },

    GHOSTLANDS_MIXED = {
        label = "Ghostlands (TBC + Midnight)",
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
            T.OL_BloodElfBaseWalkUni01,
            T.OL_BloodElfBaseWalkUni02,
            T.MN_WindrunnerA,
            T.MN_WindrunnerB,
            T.MN_WindrunnerC,
            T.MN_WindrunnerD,
            T.MN_WindrunnerE,
            T.MN_WindrunnerF,
        },
    },

    -- --------------------------------------------------------
    -- Subzone utility packs
    -- --------------------------------------------------------

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
            T.MN_QuelDanasA,
            T.MN_SunwellA,
        },
    },
}

-- Stable ordering for dropdown menus and Music Packs panel
ns.MusicPackOrder = {
    "SILVERMOON",
    "SILVERMOON_MIDNIGHT",
    "SILVERMOON_MIXED",
    "EVERSONG",
    "EVERSONG_MIDNIGHT",
    "EVERSONG_MIXED",
    "GHOSTLANDS",
    "GHOSTLANDS_MIDNIGHT",
    "GHOSTLANDS_MIXED",
    "SCORCHED",
    "QUELDANAS",
}
