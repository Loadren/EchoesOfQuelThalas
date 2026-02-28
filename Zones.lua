local _, ns = ...

-- ============================================================
-- Zone → music-pack mapping (Midnight UiMapIDs)
--
-- This is the default configuration loaded when no user
-- override exists.  Each zone references a pack key from
-- Packs.lua.  Subzones map to pack keys as well.
--
-- Schema:
--   nameKey  = "LOCALE_KEY"          (looked up via ns.L)
--   pack     = "PACK_KEY"            (from ns.MusicPacks)
--   subzones = { [KEY] = "PACK_KEY", ... }
--
-- Discover zone / subzone info in-game:   /eoqt now
-- ============================================================

ns.ZoneMusic = {

    -- Silvermoon City (2393)
    [2393] = {
        nameKey  = "SILVERMOON_CITY",
        pack     = "SILVERMOON",
        subzones = {
            MURDER_ROW = "GHOSTLANDS_DARK",
        },
    },

    -- Eversong Woods (2395) — merged with Ghostlands in Midnight
    [2395] = {
        nameKey  = "EVERSONG_WOODS",
        pack     = "EVERSONG",
        subzones = {
            WINDRUNNER_VILLAGE = "GHOSTLANDS_FULL",
            WINDRUNNER_SPIRE   = "GHOSTLANDS_FULL",
            RUINS_OF_DEATHOLME = "QUELDANAS",
            LIGHTBLOOM_ATHRAN  = "SCORCHED",
            SUNCROWN_VILLAGE   = "SCORCHED",
            SUNCROWN_TREE      = "SCORCHED",
        },
    },

    -- Isle of Quel'Danas (2424)
    [2424] = {
        nameKey  = "ISLE_OF_QUELDANAS",
        pack     = "QUELDANAS",
    },
}
