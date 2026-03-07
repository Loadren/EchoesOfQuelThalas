# Changelog

## 1.4.1

- Added named profiles — create multiple independent configurations, each with its own zone mapping and custom packs
- Switch between profiles live; the active profile's music starts immediately on switch
- Import a profile string as a new named profile (choose a name at import time) or into the current profile (merge or replace)
- Export always reflects the currently active profile

## 1.4.0

- Added a **Profiles** tab in the settings panel to export and import zone mappings
- Export generates a compressed, printable string (via LibDeflate + LibSerialize) that can be copy-pasted or printed to chat in chunks with `/eoqt export`
- Import accepts a profile string and lets you choose **Merge** (add only zones not already configured) or **Replace** (overwrite your entire zone mapping)

## 1.3.2

- Fixed silence gap setting not working for most players — the gap timer now always fires between tracks regardless of the `Sound_ZoneMusicNoDelay` CVar
- Extended `silence.ogg` from 5 s to 30 s so the gap timer always has room regardless of WoW's crossfade speed
- Removed the Crossfade Duration slider — zone-exit fade is now a fixed 3 s

## 1.3.1

- Added Sanctum of Light tracks (`MN_SanctumOfLightA/D/H`) to Silvermoon packs — plays in the Sanctum of Light interior in Silvermoon City

## 1.3.0

- Consolidated 18 packs down to 11 — three per main zone (TBC / Midnight / TBC + Midnight) for Silvermoon, Eversong, and Ghostlands, plus Scorched Lands and Isle of Quel'Danas utility packs
- Added Outland Blood Elf tracks (`OL_BloodElfBaseWalkUni01/02`) to the Ghostlands packs; these play in Tranquillien and the Hatchet Hills area
- Added Ghostlands (map 95) as a supported zone — covers the mountain pass between Eastern Plaguelands and Quel'Thalas, with Sungraze Peak and Hatchet Hills subzone mappings
- Custom packs: users can now create, rename, and delete their own music packs in the Music Packs panel, pick any track from the full catalog, and preview tracks in-game before adding them
- Custom packs appear in the Zone Mapping dropdown alongside the built-in ones

## 1.2.0

- Added Twilight's Blade tracks (`MN_TwilightsBladeA/C/D/H`) and Atal'abasi Ruins tracks (`MN_AtalAbasiB/C/D`), discovered via ZoneMusic DB audit
- Added standalone packs for Midnight: Twilight's Blade and Midnight: Atal'abasi Ruins
- Filled real ffprobe durations for all 36 previously unmeasured Midnight tracks (Eversong Base, Village, Sunstrider, Windrunner, Tranquillien, Quel'Danas, Sunwell, Twilight's Blade, Atal'abasi) — engine now schedules rotation based on actual track length instead of the 90s fallback

## 1.1.1

- Removed NPC voice replacement experiment

## 1.1.0

- Added NPC voice replacement for gossip, quest, and merchant interactions (later removed in 1.1.1)

## 1.0.0

- Initial release
- Plays original TBC music in Silvermoon City, Eversong Woods, Ghostlands-themed subzones (Windrunner Village, Windrunner Spire, Ruins of Deatholme), Scorched subzones, Murder Row, and Isle of Quel'Danas
- Silvermoon intro track plays once per zone entry
- Day/night track rotation based on game time
- Silence gap and crossfade duration configurable via Options → AddOns
- Zone Mapping panel to override music per zone or subzone
- Music Packs panel with per-track enable/disable toggles and in-game preview
- Midnight tracks included in all main packs, disabled by default
- `/eoqt now` command to identify unmapped subzones
- Disables itself inside instances and delves
