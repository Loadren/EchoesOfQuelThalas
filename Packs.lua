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
            -- Midnight Eversong (disabled by default)
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
            -- Midnight Eversong (disabled by default)
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
            -- Midnight Eversong (disabled by default)
            T.MN_EversongBaseUni01,
            T.MN_EversongVillageA,
            T.MN_EversongVillageB,
            T.MN_EversongVillageC,
            T.MN_TranquillienA,
        },
        disabledByDefault = {
            [T.MN_EversongBaseDayA]   = true,
            [T.MN_EversongBaseDayB]   = true,
            [T.MN_EversongBaseDayC]   = true,
            [T.MN_EversongBaseDayD]   = true,
            [T.MN_EversongBaseDayE]   = true,
            [T.MN_EversongBaseNightA] = true,
            [T.MN_EversongBaseNightB] = true,
            [T.MN_EversongBaseNightC] = true,
            [T.MN_EversongBaseNightD] = true,
            [T.MN_EversongBaseNightE] = true,
            [T.MN_EversongBaseUni01]  = true,
            [T.MN_EversongVillageA]   = true,
            [T.MN_EversongVillageB]   = true,
            [T.MN_EversongVillageC]   = true,
            [T.MN_SunstriderDayA]     = true,
            [T.MN_SunstriderDayB]     = true,
            [T.MN_SunstriderDayC]     = true,
            [T.MN_SunstriderNightA]   = true,
            [T.MN_SunstriderNightB]   = true,
            [T.MN_SunstriderNightC]   = true,
            [T.MN_TranquillienA]      = true,
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
        any = {
            -- Midnight Silvermoon (disabled by default)
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
        disabledByDefault = {
            [T.MN_SilvermoonCityA]  = true,
            [T.MN_SilvermoonCityB]  = true,
            [T.MN_SilvermoonCityC]  = true,
            [T.MN_SilvermoonCityD]  = true,
            [T.MN_SilvermoonCityE]  = true,
            [T.MN_SilvermoonCityF]  = true,
            [T.MN_SilvermoonCityG]  = true,
            [T.MN_SilvermoonCityH]  = true,
            [T.MN_SilvermoonCityI]  = true,
            [T.MN_SilvermoonCityJ]  = true,
            [T.MN_SilvermoonHordeA] = true,
            [T.MN_SilvermoonHordeB] = true,
            [T.MN_SilvermoonHordeC] = true,
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
            -- Midnight Windrunner Village (disabled by default)
            T.MN_WindrunnerA,
            T.MN_WindrunnerB,
            T.MN_WindrunnerC,
            T.MN_WindrunnerD,
            T.MN_WindrunnerE,
            T.MN_WindrunnerF,
        },
        disabledByDefault = {
            [T.MN_WindrunnerA] = true,
            [T.MN_WindrunnerB] = true,
            [T.MN_WindrunnerC] = true,
            [T.MN_WindrunnerD] = true,
            [T.MN_WindrunnerE] = true,
            [T.MN_WindrunnerF] = true,
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
            -- Midnight Quel'Danas (disabled by default)
            T.MN_QuelDanasA,
            T.MN_SunwellA,
        },
        disabledByDefault = {
            [T.MN_QuelDanasA] = true,
            [T.MN_SunwellA]   = true,
        },
    },

    MIDNIGHT_EVERSONG = {
        label = "Midnight: Eversong Woods",
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

    MIDNIGHT_WINDRUNNER = {
        label = "Midnight: Windrunner Village",
        any = {
            T.MN_WindrunnerA,
            T.MN_WindrunnerB,
            T.MN_WindrunnerC,
            T.MN_WindrunnerD,
            T.MN_WindrunnerE,
            T.MN_WindrunnerF,
        },
    },

    MIDNIGHT_QUELDANAS = {
        label = "Midnight: Quel'Danas",
        any = {
            T.MN_QuelDanasA,
            T.MN_SunwellA,
        },
    },

    MIDNIGHT_SILVERMOON = {
        label = "Midnight: Silvermoon City",
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
        },
    },

    MIDNIGHT_HORDE = {
        label = "Midnight: Horde Quarter",
        any = {
            T.MN_SilvermoonHordeA,
            T.MN_SilvermoonHordeB,
            T.MN_SilvermoonHordeC,
        },
    },

    MIDNIGHT_TWILIGHTSBLADE = {
        label = "Midnight: Twilight's Blade",
        -- Dark sub-area of Eversong Woods (shadow/void-touched zone).
        -- Assign via Zone Mapping once you find the subzone with /eoqt now.
        any = {
            T.MN_TwilightsBladeA,
            T.MN_TwilightsBladeC,
            T.MN_TwilightsBladeD,
            T.MN_TwilightsBladeH,
        },
    },

    MIDNIGHT_ATALABASI = {
        label = "Midnight: Atal'abasi Ruins",
        -- Ancient troll ruins within Eversong Woods (Troll Crypt area).
        -- Assign via Zone Mapping once you find the subzone with /eoqt now.
        any = {
            T.MN_AtalAbasiB,
            T.MN_AtalAbasiC,
            T.MN_AtalAbasiD,
        },
    },

    SILVERMOON_MIXED = {
        label = "Silvermoon Mixed (TBC + Midnight)",
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
}

-- Stable ordering for dropdown menus
ns.MusicPackOrder = {
    "EVERSONG",
    "SILVERMOON",
    "SILVERMOON_MIXED",
    "MIDNIGHT_EVERSONG",
    "MIDNIGHT_WINDRUNNER",
    "MIDNIGHT_SILVERMOON",
    "MIDNIGHT_HORDE",
    "MIDNIGHT_QUELDANAS",
    "MIDNIGHT_TWILIGHTSBLADE",
    "MIDNIGHT_ATALABASI",
    "SCORCHED",
    "GHOSTLANDS_FOREST",
    "GHOSTLANDS_DARK",
    "GHOSTLANDS_SCENIC",
    "SHALANDIS",
    "GHOSTLANDS_FULL",
    "EVERSONG_NIGHT",
    "QUELDANAS",
}
