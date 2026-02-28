#!/usr/bin/env python3
"""
Look up a WoW subzone by its localized name and generate Lua code
for Locale.lua and Zones.lua.

Usage:
    python3 lookup_subzone.py "Luméclat Ath'Ran"
    python3 lookup_subzone.py "Solcouronne" --locale deDE --key SUNCROWN
    python3 lookup_subzone.py --id 15996

Options:
    --locale LOC   Which locale the input name is in (default: frFR)
    --id ID        Look up directly by AreaTable ID instead of by name
    --key KEY      Force a specific locale-independent key (default: auto-generated)
"""

import argparse
import csv
import io
import re
import sys
import urllib.request

WAGO_CSV = "https://wago.tools/db2/AreaTable/csv"
LOCALES = ["enUS", "frFR", "deDE", "esES", "ptBR", "ruRU", "itIT", "koKR", "zhCN", "zhTW"]
LOCALE_BLOCKS = {
    "enUS": None,
    "frFR": 'if locale == "frFR" then',
    "deDE": 'elseif locale == "deDE" then',
    "esES": 'elseif locale == "esES" or locale == "esMX" then',
    "ptBR": 'elseif locale == "ptBR" then',
    "ruRU": 'elseif locale == "ruRU" then',
    "itIT": 'elseif locale == "itIT" then',
    "koKR": 'elseif locale == "koKR" then',
    "zhCN": 'elseif locale == "zhCN" then',
    "zhTW": 'elseif locale == "zhTW" then',
}


def fetch_csv(locale=None):
    url = WAGO_CSV
    if locale:
        url += f"?locale={locale}"
    req = urllib.request.Request(url, headers={"User-Agent": "EoQT-lookup/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read().decode("utf-8")


def find_area_id(name, locale):
    text = fetch_csv(locale if locale != "enUS" else None)
    reader = csv.reader(io.StringIO(text))
    header = next(reader)
    id_idx = header.index("ID")
    name_idx = header.index("AreaName_lang")
    matches = []
    for row in reader:
        if row[name_idx].strip() == name:
            matches.append(row[id_idx])
    return matches


def get_name_by_id(area_id, locale):
    text = fetch_csv(locale if locale != "enUS" else None)
    reader = csv.reader(io.StringIO(text))
    header = next(reader)
    id_idx = header.index("ID")
    name_idx = header.index("AreaName_lang")
    for row in reader:
        if row[id_idx] == str(area_id):
            return row[name_idx]
    return None


def to_lua_escaped(s):
    result = []
    for b in s.encode("utf-8"):
        if 32 <= b < 127:
            result.append(chr(b))
        else:
            result.append(f"\\{b}")
    return "".join(result)


def make_key(english_name):
    key = english_name.upper()
    key = re.sub(r"[''']", "", key)
    key = re.sub(r"[^A-Z0-9]+", "_", key)
    key = key.strip("_")
    return key


def main():
    parser = argparse.ArgumentParser(description="Look up WoW subzone translations")
    parser.add_argument("name", nargs="?", help="Localized subzone name to search for")
    parser.add_argument("--locale", default="frFR", help="Locale of the input name (default: frFR)")
    parser.add_argument("--id", type=int, help="AreaTable ID (skip name search)")
    parser.add_argument("--key", help="Force locale-independent key")
    args = parser.parse_args()

    if not args.name and not args.id:
        parser.print_help()
        sys.exit(1)

    area_id = args.id
    if not area_id:
        print(f"Searching for \"{args.name}\" in {args.locale}...", file=sys.stderr)
        matches = find_area_id(args.name, args.locale)
        if not matches:
            print(f"ERROR: No AreaTable entry found for \"{args.name}\" in {args.locale}", file=sys.stderr)
            sys.exit(1)
        if len(matches) > 1:
            print(f"WARNING: Multiple matches: {matches}. Using first.", file=sys.stderr)
        area_id = int(matches[0])
        print(f"Found AreaTable ID: {area_id}", file=sys.stderr)

    translations = {}
    for loc in LOCALES:
        print(f"  Fetching {loc}...", file=sys.stderr)
        name = get_name_by_id(area_id, loc)
        if name:
            translations[loc] = name
        else:
            print(f"  WARNING: No {loc} translation for ID {area_id}", file=sys.stderr)

    en_name = translations.get("enUS", f"UNKNOWN_{area_id}")
    key = args.key or make_key(en_name)

    print(f"\nAreaTable ID: {area_id}")
    print(f"Key: {key}")
    print(f"English: {en_name}")
    print()

    for loc in LOCALES:
        name = translations.get(loc, "???")
        print(f"  {loc:5s}  {name}")

    print()
    print("=" * 60)
    print("Locale.lua — base (enUS)")
    print("=" * 60)
    lua_en = to_lua_escaped(en_name)
    pad = max(20, len(key) + 4)
    print(f'    {key:<{pad}} = "{lua_en}",')

    print()
    print("=" * 60)
    print("Locale.lua — locale overrides")
    print("=" * 60)
    for loc in LOCALES:
        if loc == "enUS":
            continue
        name = translations.get(loc)
        if not name:
            continue
        lua_str = to_lua_escaped(name)
        block = LOCALE_BLOCKS[loc]
        print(f"-- {block}")
        print(f'    subzones.{key:<{pad}} = "{lua_str}"')
        print()

    print("=" * 60)
    print("Zones.lua — subzone entry (fill in tracks)")
    print("=" * 60)
    print(f"            {key} = {{")
    print(f"                day   = {{ }},")
    print(f"                night = {{ }},")
    print(f"            }},")


if __name__ == "__main__":
    main()
