local _, ns = ...

-- ============================================================
-- VoiceData.lua — Midnight Blood Elf NPC voice replacement data
--
-- Generated via tools/lookup_npc_voices.py comparing current
-- build against 11.0.7.58238 (pre-Midnight).
--
-- Data chain: Creature → CreatureDisplayInfo → NPCSounds
--   → SoundKit → SoundKitEntry → FileDataID
--
-- New Midnight NPCSoundIDs (generic belf NPC voices):
--   3310 (Male 1)   3314 (Male 2)
--   3393 (Female 1)  3295 (Female 2)
--
-- Old TBC-era NPCSoundIDs they replaced:
--   195/197 (Male)   189/191 (Female)
-- ============================================================

-- FileDataIDs of Midnight-era generic belf NPC greeting/farewell
-- voices. These are muted globally via MuteSoundFile().
ns.VoiceMute = {
    -- Male variant 1 (NPCSoundID 3310)
    --   farewell SK 314181
    7433708, 7433710, 7433712, 7433714, 7433716, 7433718,
    --   greeting SK 314182
    7433720, 7433722, 7433724, 7433726, 7433728, 7433730, 7433732,

    -- Male variant 2 (NPCSoundID 3314)
    --   farewell SK 314186
    7387005, 7387008, 7387010, 7387024, 7387026, 7387028, 7387030,
    --   greeting SK 314187
    7387032, 7387034, 7387036, 7387038, 7387040, 7387042, 7387044,

    -- Female variant 1 (NPCSoundID 3393)
    --   farewell SK 316920
    7433709, 7433711, 7433713, 7433715, 7433717, 7433719,
    --   greeting SK 316921
    7433721, 7433723, 7433725, 7433727, 7433729, 7433731, 7433733,

    -- Female variant 2 (NPCSoundID 3295)
    --   farewell SK 311938
    7387033, 7387035, 7387037, 7387039, 7387041, 7387043, 7387045,
    --   greeting SK 311939
    7387007, 7387009, 7387011, 7387025, 7387027, 7387029, 7387031,
}

-- Old TBC-era replacement voices, keyed by gender (2=male, 3=female
-- per UnitSex return values).
ns.VoiceOld = {
    [2] = { -- Male (old SK 9738 greeting, SK 9737 farewell)
        greeting = { 556894, 556897, 556898, 556899, 556901, 556907 },
        farewell = { 556903, 556909, 556912, 556914, 556915, 556916 },
    },
    [3] = { -- Female (old SK 9725 greeting, SK 9726 farewell)
        greeting = { 556826, 556828, 556839, 556841, 556842, 556845, 556846 },
        farewell = { 556825, 556827, 556830, 556831, 556835, 556840 },
    },
}

-- Creature IDs whose displays use the new Midnight belf NPCSoundIDs
-- (3310/3314/3393/3295). The VoiceEngine checks this set to decide
-- whether to play old replacement voices on interaction.
ns.VoiceCreatures = {
    [51796]  = true, -- Silvermoon City Guardian
    [158322] = true, -- Silvermoon Soldier
    [232336] = true, -- Arlor Morrowmourn
    [233123] = true, -- Olanea Rosekind
    [235711] = true, -- Silvermoon Evacuee
    [244073] = true, -- Royal Guard
    [245935] = true, -- Light's Vanguard
    [249621] = true, -- Sunwell Guard
    [250547] = true, -- Blood Elf Civilian
    [250584] = true, -- Silvermoon Guard (typo in data: "Silvermooon")
    [250980] = true, -- Silvermoon Resident
    [251671] = true, -- Lightbloated Magister
    [253383] = true, -- Light's Vanguard
    [254600] = true, -- Anuve Liltleaf
    [255011] = true, -- Tactical Telemancer Seralia
    [256908] = true, -- Eversong Farstrider
    [256911] = true, -- Phoenixfire Magister
    [256960] = true, -- Eversong Farstrider
    [257161] = true, -- Blazing Pyromancer
    [260360] = true, -- Silvermoon Guard
    [260421] = true, -- Hurried Courier
    [260465] = true, -- Bloomrotten Corpse
    [260489] = true, -- Bloomrotten Corpse
}
