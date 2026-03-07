local addonName, ns = ...

local ZONES         = ns.ZoneMusic
local PACKS         = ns.MusicPacks
local DURATIONS     = ns.TrackDurations
local DEFAULT_DUR   = 90
local SILENCE_TRACK = "Interface\\AddOns\\EchoesOfQuelThalas\\silence.ogg"

local function GetSilenceGap() return (ns.db and ns.db.silenceGap) or 4 end
local CROSSFADE_SEC = 3

-- Looks up a pack from built-in packs first, then user-created custom packs.
local function GetPack(key)
    if not key then return nil end
    return PACKS[key] or (ns.db and ns.db.customPacks and ns.db.customPacks[key])
end

local TRACK_NAMES   = {}
for name, id in pairs(ns.Tracks) do
    TRACK_NAMES[id] = name
end
local MAX_DEPTH     = 5
local RANDOM_SAFETY = 20
local PREFIX        = "|cffFFD700Echoes of Quel'Thalas:|r "

-- ============================================================
-- Saved variables (persisted between sessions)
-- ============================================================

local db

local frame = CreateFrame("Frame")

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CVAR_UPDATE")

-- ============================================================
-- Playback state
-- ============================================================

local enabled            = true
local isPlaying          = false
local isPreviewing       = false
local currentZoneId      = nil
local currentConfig      = nil
local currentGroup       = nil
local currentPackKey     = nil
local lastTrack          = nil
local introPlayed        = false
local rotateTicker       = nil
local fadeTimer          = nil
local pendingCheck       = nil
local loadingScreenEnded = false

-- ============================================================
-- Utilities
-- ============================================================

local function IsDaytime()
    local hour = GetGameTime()
    return hour >= 6 and hour < 21
end

local function ResolveZone(mapId)
    if not mapId then return nil, nil end

    -- User-added custom zones (exact match, no parent walk)
    local overrides = db and db.zoneOverrides
    if overrides and overrides[mapId] and overrides[mapId].isCustom then
        return mapId, overrides[mapId]
    end

    for _ = 1, MAX_DEPTH do
        if ZONES[mapId] then
            return mapId, ZONES[mapId]
        end
        local info = C_Map.GetMapInfo(mapId)
        if not info or not info.parentMapID or info.parentMapID == 0 then
            return nil, nil
        end
        mapId = info.parentMapID
    end
    return nil, nil
end

local function ResolveConfig(zoneId, zoneEntry)
    local subzoneText = GetSubZoneText()
    local overrides = db and db.zoneOverrides
    local zoneOv = overrides and overrides[zoneId]

    -- 1. Subzone overrides from user settings
    if subzoneText and subzoneText ~= "" and zoneOv and zoneOv.subzones then
        local key = ns.SubzoneKeys[subzoneText] or subzoneText
        local packKey = zoneOv.subzones[key]
        if packKey and packKey ~= "DEFAULT" then
            if packKey == "NONE" then return nil, key, nil end
            local p = GetPack(packKey)
            if p then return p, key, packKey end
        end
    end

    -- 2. Default subzone from Zones.lua (values are pack keys)
    if zoneEntry.subzones and subzoneText and subzoneText ~= "" then
        local key = ns.SubzoneKeys[subzoneText]
        if key and zoneEntry.subzones[key] then
            local packKey = zoneEntry.subzones[key]
            local p = GetPack(packKey)
            if p then return p, key, packKey end
        end
    end

    -- 3. Zone-level pack override
    if zoneOv and zoneOv.pack and zoneOv.pack ~= "DEFAULT" then
        if zoneOv.pack == "NONE" then return nil, nil, nil end
        local p = GetPack(zoneOv.pack)
        if p then return p, nil, zoneOv.pack end
    end

    -- 4. Zone default pack
    local packKey = zoneEntry.pack
    if packKey then
        local p = GetPack(packKey)
        if p then return p, nil, packKey end
    end

    return nil, nil, nil
end

local function BuildPool(config, packKey)
    local pool = {}
    local timed = IsDaytime() and config.day or config.night
    if timed then
        for _, id in ipairs(timed) do pool[#pool + 1] = id end
    end
    if config.any then
        for _, id in ipairs(config.any) do pool[#pool + 1] = id end
    end
    local ov  = packKey and db and db.packOverrides and db.packOverrides[packKey]
    local dis = ov and ov.disabled
    local dbd = config.disabledByDefault
    if not dis and not dbd then return pool end
    local filtered = {}
    for _, id in ipairs(pool) do
        local userSet = dis and dis[id]
        -- tri-state: true = force off, false = force on, nil = use pack default
        if userSet ~= true then
            if userSet == false or not (dbd and dbd[id]) then
                filtered[#filtered + 1] = id
            end
        end
    end
    return filtered
end

local function PickTrack(config, packKey)
    local pool = BuildPool(config, packKey)
    if #pool == 0 then return nil end
    if #pool == 1 then
        lastTrack = pool[1]
        return pool[1]
    end
    for _ = 1, RANDOM_SAFETY do
        local track = pool[math.random(#pool)]
        if track ~= lastTrack then
            lastTrack = track
            return track
        end
    end
    lastTrack = pool[1]
    return pool[1]
end

-- ============================================================
-- Playback control
--
-- Transitions between tracks use PlayMusic() directly — the
-- engine crossfades on the Music channel automatically.
--
-- To fade to silence (leaving all configured zones), we play
-- the bundled silence.ogg — the engine crossfades the current
-- track into silence — then call StopMusic() after the
-- crossfade to hand control back to native zone music.
-- ============================================================

local function CancelTimers()
    if rotateTicker then
        rotateTicker:Cancel()
        rotateTicker = nil
    end
    if fadeTimer then
        fadeTimer:Cancel()
        fadeTimer = nil
    end
end

local function HardStop()
    CancelTimers()
    StopMusic()
    isPlaying = false
    currentZoneId = nil
    currentConfig = nil
    currentGroup = nil
    currentPackKey = nil
    lastTrack = nil
end

local function FadeOutThenStop()
    if not isPlaying then
        HardStop()
        return
    end

    CancelTimers()
    isPlaying = false
    currentZoneId = nil
    currentConfig = nil
    currentGroup = nil
    currentPackKey = nil
    lastTrack = nil

    PlayMusic(SILENCE_TRACK)
    fadeTimer = C_Timer.NewTimer(CROSSFADE_SEC, function()
        fadeTimer = nil
        StopMusic()
    end)
end

local function PrintTrack(track, dur)
    if db and db.verbose then
        local name = TRACK_NAMES[track] or tostring(track)
        print(PREFIX .. name .. "  (" .. string.format("%.0f", dur) .. "s)")
    end
end

local function ScheduleRotation(track, dur)
    if rotateTicker then rotateTicker:Cancel() end
    rotateTicker = C_Timer.NewTimer(dur, function()
        PlayMusic(SILENCE_TRACK)
        rotateTicker = C_Timer.NewTimer(GetSilenceGap(), function()
            rotateTicker = nil
            if not isPlaying or not currentConfig then return end
            local next = PickTrack(currentConfig, currentGroup)
            if not next then return end
            local nextDur = DURATIONS[next] or DEFAULT_DUR
            PlayMusic(next)
            PrintTrack(next, nextDur)
            ScheduleRotation(next, nextDur)
        end)
    end)
end

local function BeginPlayback(zoneId, effectiveConfig, zoneName, introTrack, groupKey)
    local track
    if introTrack and not introPlayed then
        track = introTrack
        introPlayed = true
    else
        track = PickTrack(effectiveConfig, groupKey)
    end
    if not track then return end

    if rotateTicker then
        rotateTicker:Cancel()
        rotateTicker = nil
    end

    currentZoneId = zoneId
    currentConfig = effectiveConfig
    currentGroup = groupKey
    currentPackKey = groupKey
    isPlaying = true

    local dur = DURATIONS[track] or DEFAULT_DUR
    PlayMusic(track)
    PrintTrack(track, dur)
    ScheduleRotation(track, dur)
end

local function StartMusic(zoneId, effectiveConfig, zoneName, forceRestart, introTrack, groupKey)
    -- Same group = seamless transition (keep current track playing)
    if not forceRestart and isPlaying
       and groupKey and currentGroup and groupKey == currentGroup then
        currentZoneId = zoneId
        currentConfig = effectiveConfig
        return
    end

    if not forceRestart and isPlaying
       and currentZoneId == zoneId
       and currentConfig == effectiveConfig then
        return
    end

    if fadeTimer then
        fadeTimer:Cancel()
        fadeTimer = nil
    end

    if zoneId ~= currentZoneId then
        introPlayed = false
    end

    BeginPlayback(zoneId, effectiveConfig, zoneName, introTrack, groupKey)
end

local function StopCurrentMusic(skipFade)
    if skipFade or not isPlaying then
        HardStop()
    else
        FadeOutThenStop()
    end
end

-- ============================================================
-- Zone check with debounce
-- ============================================================

local function CheckZone()
    local wasLoadingScreen = loadingScreenEnded
    loadingScreenEnded = false

    if not enabled or GetCVar("Sound_EnableMusic") == "0" then
        if isPlaying then
            StopCurrentMusic(wasLoadingScreen)
        end
        return
    end

    local inInstance = IsInInstance()
    if inInstance then
        if isPlaying then
            StopCurrentMusic(wasLoadingScreen)
        end
        return
    end

    local mapId = C_Map.GetBestMapForUnit("player")
    local zoneId, zoneConfig = ResolveZone(mapId)

    if zoneId and zoneConfig then
        local L = ns.L
        local effectiveConfig, subKey, groupKey = ResolveConfig(zoneId, zoneConfig)
        if not effectiveConfig then
            StopCurrentMusic(wasLoadingScreen)
            return
        end
        local ov = db.zoneOverrides and db.zoneOverrides[zoneId]
        local displayName = (ov and ov.name)
            or (zoneConfig.nameKey and L[zoneConfig.nameKey])
            or ("zone " .. zoneId)
        if subKey then
            local subName = ns.SubzoneNames[subKey] or subKey
            displayName = displayName .. " \xe2\x80\x94 " .. subName
        end
        local intro = effectiveConfig and effectiveConfig.intro
        StartMusic(zoneId, effectiveConfig, displayName, wasLoadingScreen, intro, groupKey)
    else
        StopCurrentMusic(wasLoadingScreen)
    end
end

local function ScheduleCheck()
    if isPreviewing then return end
    if pendingCheck then return end
    pendingCheck = C_Timer.NewTimer(0.5, function()
        pendingCheck = nil
        CheckZone()
    end)
end

ns.ForceCheckZone = function()
    if pendingCheck then pendingCheck:Cancel(); pendingCheck = nil end
    CheckZone()
end

ns.PreviewTrack = function(fdid)
    isPreviewing = true
    CancelTimers()
    PlayMusic(fdid)
end

ns.StopPreview = function()
    isPreviewing = false
    local mapId = C_Map.GetBestMapForUnit("player")
    local zoneId = ns.ResolveZone(mapId)
    if zoneId then
        ns.ForceCheckZone()
    else
        StopMusic()
    end
end

ns.SetEnabled = function(val)
    enabled = val
    if db then db.enabled = val end
    if val then
        ns.ForceCheckZone()
    else
        StopCurrentMusic()
    end
end

ns.BuildPool = BuildPool
ns.ResolveZone = ResolveZone
ns.GetPack = GetPack

-- ============================================================
-- Profile export / import
-- ============================================================

-- v2 payload: { zoneOverrides = {...}, customPacks = {...} }
-- v1 payload (legacy): raw zoneOverrides table
local PROFILE_PREFIX_V2 = "EoQT:2:"
local PROFILE_PREFIX_V1 = "EoQT:1:"

local function DecodeProfilePayload(str)
    local encoded
    local isV1 = false
    if str:sub(1, #PROFILE_PREFIX_V2) == PROFILE_PREFIX_V2 then
        encoded = str:sub(#PROFILE_PREFIX_V2 + 1)
    elseif str:sub(1, #PROFILE_PREFIX_V1) == PROFILE_PREFIX_V1 then
        encoded = str:sub(#PROFILE_PREFIX_V1 + 1)
        isV1 = true
    else
        return nil, nil, "Not a valid EoQT profile string"
    end

    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then return nil, nil, "Libraries not loaded" end

    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then return nil, nil, "Failed to decode string" end

    local decompressed = LibDeflate:DecompressDeflate(compressed)
    if not decompressed then return nil, nil, "Failed to decompress" end

    local ok, data = LibSerialize:Deserialize(decompressed)
    if not ok or type(data) ~= "table" then return nil, nil, "Failed to deserialize" end

    local zones  = isV1 and data or (data.zoneOverrides or {})
    local cpacks = (not isV1) and (data.customPacks or {}) or {}
    return zones, cpacks
end

ns.ExportProfile = function()
    if not db then return nil end
    local LibSerialize = LibStub and LibStub("LibSerialize", true)
    local LibDeflate   = LibStub and LibStub("LibDeflate",   true)
    if not LibSerialize or not LibDeflate then return nil, "Libraries not loaded" end

    local payload = {
        zoneOverrides = db.zoneOverrides or {},
        customPacks   = db.customPacks   or {},
    }
    local serialized = LibSerialize:Serialize(payload)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded    = LibDeflate:EncodeForPrint(compressed)
    return PROFILE_PREFIX_V2 .. encoded
end

ns.ImportProfile = function(str, mode)
    if type(str) ~= "string" then return false, "Invalid input" end
    if not db then return false, "Addon not loaded" end

    local zones, cpacks, err = DecodeProfilePayload(str)
    if not zones then return false, err end

    local prof = db.profiles[db.activeProfile]
    if mode == "replace" then
        prof.zoneOverrides = zones
        prof.customPacks   = cpacks
        db.zoneOverrides   = zones
        db.customPacks     = cpacks
    else
        for k, v in pairs(zones) do
            if db.zoneOverrides[k] == nil then db.zoneOverrides[k] = v end
        end
        for k, v in pairs(cpacks) do
            if db.customPacks[k] == nil then db.customPacks[k] = v end
        end
    end

    if ns.ForceCheckZone then ns.ForceCheckZone() end
    return true
end

ns.ImportIntoNewProfile = function(str, name)
    if type(str) ~= "string" then return false, "Invalid input" end
    if not db then return false, "Addon not loaded" end

    local zones, cpacks, err = DecodeProfilePayload(str)
    if not zones then return false, err end

    local key = "prof_" .. time()
    db.profiles[key] = {
        name          = name or "Imported Profile",
        zoneOverrides = zones,
        customPacks   = cpacks,
    }
    return true, key
end

-- ============================================================
-- Profile management
-- ============================================================

ns.GetProfileList = function()
    if not db or not db.profiles then return {} end
    local list = {}
    for k, p in pairs(db.profiles) do
        list[#list + 1] = { key = k, name = p.name or k, active = (k == db.activeProfile) }
    end
    table.sort(list, function(a, b)
        if a.key == "default" then return true end
        if b.key == "default" then return false end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

ns.SwitchProfile = function(key)
    if not db or not db.profiles or not db.profiles[key] then return false end
    db.activeProfile = key
    db.zoneOverrides = db.profiles[key].zoneOverrides
    db.customPacks   = db.profiles[key].customPacks
    ns.ForceCheckZone()
    return true
end

ns.CreateProfile = function(name)
    if not db then return nil end
    local key = "prof_" .. time()
    db.profiles[key] = { name = name or "New Profile", zoneOverrides = {}, customPacks = {} }
    return key
end

ns.RenameProfile = function(key, newName)
    if db and db.profiles and db.profiles[key] then
        db.profiles[key].name = newName
    end
end

ns.DeleteProfile = function(key)
    if key == "default" then return false, "Cannot delete the Default profile" end
    if not db or not db.profiles or not db.profiles[key] then return false, "Profile not found" end
    db.profiles[key] = nil
    if db.activeProfile == key then
        ns.SwitchProfile("default")
    end
    return true
end

-- ============================================================
-- Events
-- ============================================================

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        EchoesOfQuelThalasDB = EchoesOfQuelThalasDB or { enabled = true, verbose = false }
        db = EchoesOfQuelThalasDB
        if db.verbose == nil then db.verbose = false end
        if db.silenceGap == nil then db.silenceGap = 4 end
        if db.packOverrides == nil then db.packOverrides = {} end

        -- Migrate flat zoneOverrides/customPacks into profile structure
        if db.profiles == nil then
            db.profiles = {
                default = {
                    name          = "Default",
                    zoneOverrides = db.zoneOverrides or {},
                    customPacks   = db.customPacks   or {},
                }
            }
            db.activeProfile = "default"
            db.zoneOverrides = nil
            db.customPacks   = nil
        end
        if not db.activeProfile or not db.profiles[db.activeProfile] then
            db.activeProfile = "default"
        end
        if not db.profiles.default then
            db.profiles.default = { name = "Default", zoneOverrides = {}, customPacks = {} }
        end
        -- Sync shortcuts so all existing call sites keep working
        db.zoneOverrides = db.profiles[db.activeProfile].zoneOverrides
        db.customPacks   = db.profiles[db.activeProfile].customPacks

        enabled = db.enabled
        ns.db = db

        if ns.InitOptions then
            ns.InitOptions()
        end
        return
    end

    if event == "PLAYER_LOGOUT" then
        CancelTimers()
        StopMusic()
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        loadingScreenEnded = true
    end

    if event == "CVAR_UPDATE" then
        if arg1 ~= "Sound_EnableMusic" then
            return
        end
    end

    if not db then return end
    ScheduleCheck()
end)

-- ============================================================
-- Slash command: /eoqt [on|off|zones|now]
-- ============================================================

SLASH_ECHOESOFQUELTHALAS1 = "/eoqt"
SlashCmdList["ECHOESOFQUELTHALAS"] = function(msg)
    msg = msg:lower():trim()

    if msg == "on" then
        enabled = true
        db.enabled = true
        print(PREFIX .. "Enabled.")
        ScheduleCheck()

    elseif msg == "off" then
        enabled = false
        db.enabled = false
        StopCurrentMusic()
        print(PREFIX .. "Disabled.")

    elseif msg == "zones" then
        local L = ns.L
        print(PREFIX .. "Configured zones:")
        for mapId, zoneEntry in pairs(ZONES) do
            local packConfig = zoneEntry.pack and GetPack(zoneEntry.pack)
            local n = packConfig and #BuildPool(packConfig) or 0
            local subs = zoneEntry.subzones and 0 or nil
            if zoneEntry.subzones then
                for _ in pairs(zoneEntry.subzones) do subs = subs + 1 end
            end
            local packLabel = packConfig and packConfig.label or "?"
            local line = "  " .. L[zoneEntry.nameKey] .. "  (mapId " .. mapId .. ")  \xe2\x80\x94 " .. packLabel .. " (" .. n .. " tracks)"
            if subs and subs > 0 then
                line = line .. ", " .. subs .. " subzones"
            end
            print(line)
        end

    elseif msg == "now" then
        local L = ns.L
        local mapId = C_Map.GetBestMapForUnit("player")
        local subzoneText = GetSubZoneText() or ""
        local zoneId, zoneConfig = ResolveZone(mapId)

        -- Map parent chain
        local chain = {}
        local walkId = mapId
        for _ = 1, MAX_DEPTH + 2 do
            if not walkId or walkId == 0 then break end
            local info = C_Map.GetMapInfo(walkId)
            if not info then break end
            chain[#chain + 1] = info.name .. " (" .. walkId .. ")"
            walkId = info.parentMapID
        end

        print(PREFIX .. "subzone=\"" .. subzoneText .. "\"  zone=\"" .. GetZoneText() .. "\"")
        print(PREFIX .. "map chain: " .. table.concat(chain, " > "))

        if zoneId and zoneConfig then
            local effectiveConfig, subKey, groupKey = ResolveConfig(zoneId, zoneConfig)
            local trackCount = effectiveConfig and #BuildPool(effectiveConfig) or 0
            local zoneName = (zoneConfig.nameKey and L[zoneConfig.nameKey]) or ("zone " .. zoneId)
            local groupStr = groupKey and ("  group=\"" .. groupKey .. "\"") or ""
            if subKey then
                print(PREFIX .. "Mapped: " .. zoneName
                      .. " > " .. subKey .. "  (" .. trackCount .. " tracks)" .. groupStr)
            else
                print(PREFIX .. "Mapped: " .. zoneName
                      .. "  [zone defaults]  (" .. trackCount .. " tracks)" .. groupStr)
            end
            if subzoneText ~= "" and not subKey then
                local knownKey = ns.SubzoneKeys[subzoneText]
                if knownKey then
                    print(PREFIX .. "Note: subzone key " .. knownKey .. " exists in Locale but has no music in Zones.lua")
                else
                    print(PREFIX .. "Unmapped subzone — to add it, give me: \"" .. subzoneText .. "\"")
                end
            end
        else
            print(PREFIX .. "No music configured for this location.")
        end

    elseif msg == "options" or msg == "config" then
        if ns.settingsCategoryID then
            Settings.OpenToCategory(ns.settingsCategoryID)
        else
            print(PREFIX .. "Settings panel not ready yet.")
        end

    elseif msg == "verbose" then
        db.verbose = not db.verbose
        if db.verbose then
            print(PREFIX .. "Verbose mode on.")
        else
            print(PREFIX .. "Verbose mode off.")
        end

    elseif msg == "export" then
        local str, err = ns.ExportProfile()
        if not str then
            print(PREFIX .. "Export failed: " .. (err or "nothing to export"))
            return
        end
        local CHUNK = 200
        local total = math.ceil(#str / CHUNK)
        print(PREFIX .. "Profile export (" .. #str .. " chars, " .. total .. " message(s)):")
        for i = 1, total do
            local chunk = str:sub((i - 1) * CHUNK + 1, i * CHUNK)
            DEFAULT_CHAT_FRAME:AddMessage(
                string.format("[EoQT %d/%d] %s", i, total, chunk))
        end

    elseif msg == "" then
        enabled = not enabled
        db.enabled = enabled
        if enabled then
            print(PREFIX .. "Enabled.")
            ScheduleCheck()
        else
            StopCurrentMusic()
            print(PREFIX .. "Disabled.")
        end

    else
        print(PREFIX .. "Commands: /eoqt [on|off|zones|now|verbose|options|export]")
    end
end
