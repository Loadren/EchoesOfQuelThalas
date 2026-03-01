#!/usr/bin/env python3
"""
Look up NPC gossip voice data from wago.tools and generate Lua tables
for the voice replacement system.

Follows the chain:
  Creature → CreatureDisplayInfo → NPCSounds → SoundKitEntry → FileDataID

NPCSounds slots:
  SoundID_0 = Greeting    SoundID_1 = Farewell
  SoundID_2 = Pissed      SoundID_3 = (variant)

Usage:
    python3 lookup_npc_voices.py 51796              # single creature
    python3 lookup_npc_voices.py 51796 240291        # multiple creatures
    python3 lookup_npc_voices.py --batch ids.txt     # one ID per line
    python3 lookup_npc_voices.py 51796 --old-build 11.0.7.58238  # compare builds
    python3 lookup_npc_voices.py --search "Silvermoon"            # search by name
"""

import argparse
import csv
import io
import sys
import urllib.request

WAGO_CSV = "https://wago.tools/db2/{table}/csv"
UA = {"User-Agent": "EoQT-lookup/1.0"}

SLOT_NAMES = ["greeting", "farewell", "pissed", "variant"]

# ── CSV helpers ──────────────────────────────────────────────

_cache = {}


def fetch_csv(table, build=None):
    key = (table, build)
    if key in _cache:
        return _cache[key]
    url = WAGO_CSV.format(table=table)
    if build:
        url += f"?build={build}"
    req = urllib.request.Request(url, headers=UA)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = resp.read().decode("utf-8")
    except Exception as e:
        print(f"  ERROR fetching {table} (build={build}): {e}", file=sys.stderr)
        return []
    rows = list(csv.DictReader(io.StringIO(data)))
    _cache[key] = rows
    return rows


def find_rows(table, column, value, build=None):
    rows = fetch_csv(table, build)
    val = str(value)
    return [r for r in rows if r.get(column) == val]


# ── Chain resolution ─────────────────────────────────────────

def resolve_creature(creature_id, build=None):
    """Creature → display IDs and name."""
    rows = find_rows("Creature", "ID", creature_id, build)
    if not rows:
        return None
    r = rows[0]
    displays = []
    for i in range(4):
        d = int(r.get(f"DisplayID_{i}", "0"))
        if d:
            displays.append(d)
    return {
        "id": creature_id,
        "name": r.get("Name_lang", "?"),
        "title": r.get("Title_lang", ""),
        "displays": displays,
    }


def resolve_display(display_id, build=None):
    """CreatureDisplayInfo → NPCSoundID (and SoundID for combat)."""
    rows = find_rows("CreatureDisplayInfo", "ID", display_id, build)
    if not rows:
        return None
    r = rows[0]
    return {
        "display_id": display_id,
        "npc_sound_id": int(r.get("NPCSoundID", "0")),
        "sound_id": int(r.get("SoundID", "0")),
        "gender": int(r.get("Gender", "2")),
    }


def resolve_npc_sounds(npc_sound_id, build=None):
    """NPCSounds → 4 SoundKit IDs."""
    rows = find_rows("NPCSounds", "ID", npc_sound_id, build)
    if not rows:
        return None
    r = rows[0]
    return {
        SLOT_NAMES[i]: int(r.get(f"SoundID_{i}", "0"))
        for i in range(4)
    }


def resolve_soundkit_files(soundkit_id, build=None):
    """SoundKitEntry → list of FileDataIDs for a SoundKit."""
    rows = find_rows("SoundKitEntry", "SoundKitID", soundkit_id, build)
    return sorted(int(r["FileDataID"]) for r in rows if int(r.get("FileDataID", "0")))


# ── Full resolution ──────────────────────────────────────────

def resolve_full(creature_id, build=None):
    """Complete chain for one creature, returns structured data."""
    creature = resolve_creature(creature_id, build)
    if not creature:
        return None

    creature["voice_data"] = []
    for disp_id in creature["displays"]:
        disp = resolve_display(disp_id, build)
        if not disp or disp["npc_sound_id"] == 0:
            continue

        npc_snd = resolve_npc_sounds(disp["npc_sound_id"], build)
        if not npc_snd:
            continue

        slots = {}
        for slot_name, sk_id in npc_snd.items():
            if sk_id == 0:
                continue
            files = resolve_soundkit_files(sk_id, build)
            slots[slot_name] = {"soundkit": sk_id, "files": files}

        creature["voice_data"].append({
            "display_id": disp_id,
            "npc_sound_id": disp["npc_sound_id"],
            "gender": disp["gender"],
            "slots": slots,
        })

    return creature


# ── Output ───────────────────────────────────────────────────

def print_creature_report(creature, old_creature=None):
    title = f" — {creature['title']}" if creature["title"] else ""
    print(f"\n{'='*60}")
    print(f"Creature {creature['id']}: {creature['name']}{title}")
    print(f"{'='*60}")

    if not creature["voice_data"]:
        print("  (no NPC voice data found)")
        return

    for vd in creature["voice_data"]:
        gender_str = {0: "Male", 1: "Female"}.get(vd["gender"], "Unknown")
        print(f"\n  Display {vd['display_id']}  NPCSoundID {vd['npc_sound_id']}  ({gender_str})")

        old_vd = None
        if old_creature:
            old_vd = next(
                (ov for ov in old_creature.get("voice_data", [])
                 if ov["display_id"] == vd["display_id"]),
                None,
            )

        for slot_name in SLOT_NAMES:
            slot = vd["slots"].get(slot_name)
            if not slot:
                continue
            print(f"    {slot_name:10s}  SK {slot['soundkit']:>8d}  → {slot['files']}")

            if old_vd:
                old_slot = old_vd["slots"].get(slot_name)
                if old_slot and old_slot["files"] != slot["files"]:
                    print(f"    {'':10s}  OLD SK {old_slot['soundkit']:>5d}  → {old_slot['files']}")
                elif old_slot:
                    print(f"    {'':10s}  (unchanged from old build)")
                else:
                    print(f"    {'':10s}  (not present in old build)")


def emit_lua(creatures, old_creatures=None):
    """Print Lua tables for VoiceData.lua."""
    mute_set = set()
    replacements = {}

    for creature in creatures:
        cid = creature["id"]
        old_c = (old_creatures or {}).get(cid)

        for vd in creature["voice_data"]:
            old_vd = None
            if old_c:
                old_vd = next(
                    (ov for ov in old_c.get("voice_data", [])
                     if ov["display_id"] == vd["display_id"]),
                    None,
                )

            for slot_name in ("greeting", "farewell"):
                slot = vd["slots"].get(slot_name)
                if not slot:
                    continue
                new_files = slot["files"]

                old_files = None
                if old_vd:
                    old_slot = old_vd["slots"].get(slot_name)
                    if old_slot and old_slot["files"] != new_files:
                        old_files = old_slot["files"]

                if old_files:
                    for f in new_files:
                        mute_set.add(f)

                    if cid not in replacements:
                        replacements[cid] = {
                            "name": creature["name"],
                            "greeting": [],
                            "farewell": [],
                        }
                    replacements[cid][slot_name] = old_files

    if not mute_set and not replacements:
        print("\n-- No voice changes detected between builds.")
        return

    print("\n" + "=" * 60)
    print("VoiceData.lua — paste or merge into your file")
    print("=" * 60)

    print("\nns.VoiceMute = {")
    for fdid in sorted(mute_set):
        print(f"    {fdid},")
    print("}")

    print("\nns.VoiceReplacements = {")
    for cid, data in sorted(replacements.items()):
        print(f"    [{cid}] = {{ -- {data['name']}")
        for slot in ("greeting", "farewell"):
            files = data[slot]
            if files:
                flist = ", ".join(str(f) for f in files)
                print(f"        {slot} = {{ {flist} }},")
        print("    },")
    print("}")


def search_creatures(term, build=None):
    rows = fetch_csv("Creature", build)
    term_l = term.lower()
    matches = []
    for r in rows:
        name = r.get("Name_lang", "")
        if term_l in name.lower():
            title = r.get("Title_lang", "")
            displays = [int(r.get(f"DisplayID_{i}", "0")) for i in range(4)]
            displays = [d for d in displays if d]
            matches.append((r["ID"], name, title, displays))
    return matches


# ── Main ─────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Look up NPC voice data from wago.tools"
    )
    parser.add_argument("creature_ids", nargs="*", type=int,
                        help="Creature IDs to look up")
    parser.add_argument("--batch", metavar="FILE",
                        help="File with one creature ID per line")
    parser.add_argument("--search", metavar="NAME",
                        help="Search creatures by name")
    parser.add_argument("--old-build", metavar="BUILD",
                        help="Compare with an older build (e.g. 11.0.7.58238)")
    parser.add_argument("--lua", action="store_true",
                        help="Output Lua tables for VoiceData.lua")
    args = parser.parse_args()

    if args.search:
        print(f"Searching for \"{args.search}\"...", file=sys.stderr)
        matches = search_creatures(args.search)
        if not matches:
            print("No creatures found.", file=sys.stderr)
            sys.exit(1)
        print(f"{'ID':>8s}  {'Name':<40s}  {'Title':<30s}  Displays")
        print("-" * 100)
        for cid, name, title, displays in sorted(matches, key=lambda x: int(x[0])):
            dstr = ", ".join(str(d) for d in displays)
            print(f"{cid:>8s}  {name:<40s}  {title:<30s}  {dstr}")
        return

    ids = list(args.creature_ids)
    if args.batch:
        with open(args.batch) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#"):
                    try:
                        ids.append(int(line))
                    except ValueError:
                        pass

    if not ids:
        parser.print_help()
        sys.exit(1)

    creatures = []
    old_creatures = {}

    for cid in ids:
        print(f"Resolving creature {cid}...", file=sys.stderr)
        c = resolve_full(cid)
        if not c:
            print(f"  Creature {cid} not found.", file=sys.stderr)
            continue
        creatures.append(c)

        old_c = None
        if args.old_build:
            print(f"  Resolving old build ({args.old_build})...", file=sys.stderr)
            old_c = resolve_full(cid, args.old_build)
            if old_c:
                old_creatures[cid] = old_c

        print_creature_report(c, old_c)

    if args.lua and creatures:
        emit_lua(creatures, old_creatures if args.old_build else None)


if __name__ == "__main__":
    main()
