# Echoes of Quel'Thalas

Replaces the Midnight soundtrack in Quel'Thalas with the original TBC music.

Midnight merged Eversong Woods and Ghostlands into one zone and gave everything new music. If you preferred the old stuff, this addon swaps it back in. The original tracks play while you're in the zone. Leave, and WoW's normal zone music picks up again.

## Covered zones

- **Silvermoon City** — original Silvermoon tracks; the city intro plays once when you first walk in
- **Eversong Woods** — original Eversong tracks
- **Ghostlands-themed subzones** (Windrunner Village, Windrunner Spire, Ruins of Deatholme) — original Ghostlands tracks
- **Scorched subzones** (Suncrown Village, Suncrown Tree, etc.) — scorched Eversong ambience
- **Murder Row** — dark Ghostlands tracks
- **Isle of Quel'Danas** — original Quel'Danas tracks

## How it works

Track-to-track transitions use WoW's built-in crossfade through `PlayMusic()`. When you leave a configured zone, the current track fades to silence before handing control back to the game's zone music. Tracks rotate based on their actual duration with a configurable pause between them. Day and night each have their own track pool.

## Settings

`/eoqt options` or Options > AddOns > Echoes of Quel'Thalas.

- Turn the addon on or off
- Verbose mode — prints which track is playing in chat
- Silence gap and crossfade duration sliders
- Assign music packs to any zone or subzone
- Add your own zones and subzones to the list

## Slash commands

- `/eoqt` — toggle on/off
- `/eoqt now` — show current zone, subzone, and active track info
- `/eoqt zones` — list all configured zones
- `/eoqt verbose` — toggle track name printing
- `/eoqt options` — open settings

## Good to know

- Respects WoW's Music and Loop Music toggles. Turn off Music in the game options and the addon stops. Turn off Loop Music and it plays one track, then waits.
- No bundled music files. All tracks are Blizzard's own FileDataIDs from the game data. The only extra file is a small silence.ogg used for fade transitions.
- Zone and subzone names are localized for all 10 WoW client languages.
