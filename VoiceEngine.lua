local _, ns = ...

-- ============================================================
-- VoiceEngine.lua — Replaces Midnight-era Blood Elf NPC gossip
-- voices with TBC-era originals.
--
-- 1. On load: MuteSoundFile() every new voice FileDataID.
-- 2. On interaction events: identify the NPC via UnitGUID,
--    check ns.VoiceCreatures, play old voice via PlaySoundFile.
-- 3. On disable: UnmuteSoundFile() to restore new voices.
-- ============================================================

local MUTE_LIST  = ns.VoiceMute
local OLD_VOICES = ns.VoiceOld
local CREATURES  = ns.VoiceCreatures

local muted = false
local lastCreatureID = nil

-- ============================================================
-- Mute / unmute
-- ============================================================

local function ApplyMutes()
    if muted then return end
    for _, fdid in ipairs(MUTE_LIST) do
        MuteSoundFile(fdid)
    end
    muted = true
end

local function RemoveMutes()
    if not muted then return end
    for _, fdid in ipairs(MUTE_LIST) do
        UnmuteSoundFile(fdid)
    end
    muted = false
end

-- ============================================================
-- NPC identification
-- ============================================================

local function GetCreatureID(unit)
    local guid = UnitGUID(unit)
    if not guid then return nil end
    local type, _, _, _, _, id = strsplit("-", guid)
    if type ~= "Creature" and type ~= "Vehicle" then return nil end
    return tonumber(id)
end

-- ============================================================
-- Voice playback
-- ============================================================

local function PlayOldVoice(slot)
    local sex = UnitSex("npc")
    local voices = OLD_VOICES[sex]
    if not voices then return end

    local pool = voices[slot]
    if not pool or #pool == 0 then return end

    local fdid = pool[math.random(#pool)]
    PlaySoundFile(fdid, "Dialog")
end

local function OnGreetingEvent()
    if not muted then return end
    local creatureID = GetCreatureID("npc")
    if not creatureID or not CREATURES[creatureID] then return end
    lastCreatureID = creatureID
    PlayOldVoice("greeting")
end

local function OnFarewellEvent()
    if not muted then return end
    -- "npc" unit may already be cleared when the window closes;
    -- fall back to the creature ID cached from the last greeting.
    local creatureID = GetCreatureID("npc") or lastCreatureID
    lastCreatureID = nil
    if not creatureID or not CREATURES[creatureID] then return end
    PlayOldVoice("farewell")
end

-- ============================================================
-- Event handling
-- ============================================================

local frame = CreateFrame("Frame")

local GREETING_EVENTS = {
    "GOSSIP_SHOW",
    "QUEST_GREETING",
    "QUEST_DETAIL",
    "QUEST_PROGRESS",
    "QUEST_COMPLETE",
    "MERCHANT_SHOW",
}

local FAREWELL_EVENTS = {
    "GOSSIP_CLOSED",
    "QUEST_FINISHED",
    "MERCHANT_CLOSED",
}

local function RegisterEvents()
    for _, ev in ipairs(GREETING_EVENTS) do
        frame:RegisterEvent(ev)
    end
    for _, ev in ipairs(FAREWELL_EVENTS) do
        frame:RegisterEvent(ev)
    end
end

local function UnregisterEvents()
    for _, ev in ipairs(GREETING_EVENTS) do
        frame:UnregisterEvent(ev)
    end
    for _, ev in ipairs(FAREWELL_EVENTS) do
        frame:UnregisterEvent(ev)
    end
end

local greetingSet = {}
for _, ev in ipairs(GREETING_EVENTS) do greetingSet[ev] = true end

local farewellSet = {}
for _, ev in ipairs(FAREWELL_EVENTS) do farewellSet[ev] = true end

frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "EchoesOfQuelThalas" then return end
        frame:UnregisterEvent("ADDON_LOADED")

        -- Wait for ns.db (set by Engine.lua in the same ADDON_LOADED)
        C_Timer.After(0, function()
            local db = ns.db
            if not db then return end
            if db.replaceVoices == nil then
                db.replaceVoices = true
            end
            if db.replaceVoices then
                ApplyMutes()
                RegisterEvents()
            end
        end)
        return
    end

    if greetingSet[event] then
        OnGreetingEvent()
    elseif farewellSet[event] then
        OnFarewellEvent()
    end
end)

-- ============================================================
-- Public API for Options.lua toggle
-- ============================================================

ns.SetReplaceVoices = function(val)
    local db = ns.db
    if db then db.replaceVoices = val end

    if val then
        ApplyMutes()
        RegisterEvents()
    else
        RemoveMutes()
        UnregisterEvents()
    end
end
