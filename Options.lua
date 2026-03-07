local addonName, ns = ...

-- ============================================================
-- Options.lua — Settings panel (Options > AddOns) and
-- zone-to-music-pack mapping UI.
--
-- Section 1: General settings  (vertical layout — native controls)
-- Section 2: Zone mapping      (canvas subcategory — custom frame)
-- Section 3: Music Packs       (canvas subcategory — custom frame)
-- ============================================================

local PACKS      = ns.MusicPacks
local PACK_ORDER = ns.MusicPackOrder
local ZONES      = ns.ZoneMusic
local DURATIONS  = ns.TrackDurations
local L          = ns.L
local PREFIX     = "|cffFFD700Echoes of Quel'Thalas:|r "

local ROW_HEIGHT   = 24
local INDENT       = 20
local TRACK_ROW_H  = 22
local PACK_HDR_H   = 26

-- Reverse lookup: FileDataID → track name constant
local TRACK_NAMES = {}
for name, id in pairs(ns.Tracks) do
    TRACK_NAMES[id] = name
end

-- ============================================================
-- 1. General Settings (Vertical Layout)
--
-- Category is registered at file scope (load time) so the
-- settings panel sees it immediately. Controls are added later
-- from ns.InitOptions(), called synchronously by Engine.lua
-- inside its ADDON_LOADED handler once ns.db is ready.
-- ============================================================

local category = Settings.RegisterVerticalLayoutCategory("Echoes of Quel'Thalas")

-- ============================================================
-- 2. Zone Mapping (Canvas Subcategory)
-- ============================================================

local mapperFrame, scrollChild
local rowPool    = {}
local activeRows = {}

-- ----- helpers ------------------------------------------------

local function GetPackLabel(key, defaultPackKey)
    if key == "NONE" then return "|cffFF4444None|r" end
    if not key or key == "DEFAULT" then
        if defaultPackKey then
            local pack = (ns.GetPack and ns.GetPack(defaultPackKey)) or PACKS[defaultPackKey]
            return "|cff88cc88" .. (pack and pack.label or defaultPackKey) .. "|r"
        end
        return "|cff888888—|r"
    end
    local pack = (ns.GetPack and ns.GetPack(key)) or PACKS[key]
    return pack and pack.label or key
end

local function PackDropdownOptions(includeDefault, defaultPackKey)
    local items = {}
    if includeDefault then
        local hint = "Default"
        if defaultPackKey then
            local pack = ns.GetPack and ns.GetPack(defaultPackKey) or PACKS[defaultPackKey]
            hint = "Default (" .. (pack and pack.label or defaultPackKey) .. ")"
        end
        items[#items + 1] = { key = "DEFAULT", label = hint }
    end
    for _, k in ipairs(PACK_ORDER) do
        items[#items + 1] = { key = k, label = PACKS[k].label }
    end
    -- Custom packs from SavedVariables
    if ns.db and ns.db.customPacks then
        for k, pack in pairs(ns.db.customPacks) do
            items[#items + 1] = { key = k, label = (pack.label or k) .. " *" }
        end
    end
    items[#items + 1] = { key = "NONE", label = "None (disabled)" }
    return items
end

local function ZoneDisplayName(mapId, zoneConfig, ov)
    if ov and ov.name then return ov.name end
    if zoneConfig and zoneConfig.nameKey then
        return L[zoneConfig.nameKey] or ("Zone " .. mapId)
    end
    local info = C_Map.GetMapInfo(mapId)
    return info and info.name or ("Zone " .. mapId)
end

-- ----- row recycling ------------------------------------------

local function AcquireRow(parent)
    local row = tremove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(ROW_HEIGHT)

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetJustifyH("LEFT")

        row.actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.actionBtn:SetSize(24, 22)
        row.actionBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

        row.packBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.packBtn:SetSize(160, 22)
        row.packBtn:SetPoint("RIGHT", row.actionBtn, "LEFT", -4, 0)
    end
    row:SetParent(parent)
    row:Show()
    return row
end

local function ReleaseRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:ClearAllPoints()
        row:EnableMouse(false)
        row:SetScript("OnMouseUp", nil)
        row.packBtn:SetScript("OnClick", nil)
        row.packBtn:Show()
        row.actionBtn:SetScript("OnClick", nil)
        row.actionBtn:Show()
        rowPool[#rowPool + 1] = row
    end
    wipe(activeRows)
end

-- ----- pack dropdown via MenuUtil -----------------------------

local function ShowPackMenu(anchorFrame, currentKey, includeDefault, defaultPackKey, onSelect)
    MenuUtil.CreateContextMenu(anchorFrame, function(_, rootDescription)
        local options = PackDropdownOptions(includeDefault, defaultPackKey)
        for _, opt in ipairs(options) do
            local isSelected = function() return opt.key == currentKey end
            local setSelected = function() onSelect(opt.key) end
            rootDescription:CreateRadio(opt.label, isSelected, setSelected)
        end
    end)
end

-- ----- build the zone list ------------------------------------

local function RefreshMapper()
    if not scrollChild or not ns.db then return end
    ReleaseRows()

    local db = ns.db
    local y  = 0

    -- Gather all mapIds: defaults + user custom
    local allZones = {}
    local seen = {}
    for mapId in pairs(ZONES) do
        allZones[#allZones + 1] = { mapId = mapId, isCustom = false }
        seen[mapId] = true
    end
    if db.zoneOverrides then
        for mapId, ov in pairs(db.zoneOverrides) do
            if ov.isCustom and not seen[mapId] then
                allZones[#allZones + 1] = { mapId = mapId, isCustom = true }
                seen[mapId] = true
            end
        end
    end
    table.sort(allZones, function(a, b) return a.mapId < b.mapId end)

    for _, entry in ipairs(allZones) do
        local mapId     = entry.mapId
        local zoneConfig = ZONES[mapId]
        local ov        = db.zoneOverrides and db.zoneOverrides[mapId]
        local isCustom  = entry.isCustom

        -- Zone header row
        local row = AcquireRow(scrollChild)
        row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -y)
        row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

        local displayName = ZoneDisplayName(mapId, zoneConfig, ov)
        row.label:SetPoint("LEFT", 4, 0)
        row.label:SetText(displayName .. "  |cff666666(" .. mapId .. ")|r")
        row.label:SetFontObject(GameFontNormal)

        local currentPack = (ov and ov.pack) or "DEFAULT"
        local defaultPack = zoneConfig and zoneConfig.pack
        row.packBtn:SetText(GetPackLabel(currentPack, defaultPack))
        row.packBtn:SetScript("OnClick", function(self)
            ShowPackMenu(self, currentPack, not isCustom, defaultPack, function(key)
                if not db.zoneOverrides[mapId] then
                    db.zoneOverrides[mapId] = { isCustom = isCustom }
                end
                db.zoneOverrides[mapId].pack = (key ~= "DEFAULT") and key or nil
                if not db.zoneOverrides[mapId].pack and not db.zoneOverrides[mapId].subzones and not isCustom then
                    db.zoneOverrides[mapId] = nil
                end
                ns.ForceCheckZone()
                RefreshMapper()
            end)
        end)

        if isCustom then
            row.actionBtn:SetText("X")
            row.actionBtn:Show()
            row.actionBtn:SetScript("OnClick", function()
                db.zoneOverrides[mapId] = nil
                ns.ForceCheckZone()
                RefreshMapper()
            end)
        elseif ov and ov.pack then
            row.actionBtn:SetText("R")
            row.actionBtn:Show()
            row.actionBtn:SetScript("OnClick", function()
                if ov then ov.pack = nil end
                if ov and not next(ov.subzones or {}) and not ov.isCustom then
                    db.zoneOverrides[mapId] = nil
                end
                ns.ForceCheckZone()
                RefreshMapper()
            end)
        else
            row.actionBtn:Hide()
        end

        activeRows[#activeRows + 1] = row
        y = y + ROW_HEIGHT

        -- Subzone rows (from Zones.lua defaults + overrides)
        local subKeys = {}
        local subSeen = {}
        if zoneConfig and zoneConfig.subzones then
            for key in pairs(zoneConfig.subzones) do
                subKeys[#subKeys + 1] = { key = key, isCustom = false }
                subSeen[key] = true
            end
        end
        if ov and ov.subzones then
            for key in pairs(ov.subzones) do
                if not subSeen[key] then
                    subKeys[#subKeys + 1] = { key = key, isCustom = true }
                    subSeen[key] = true
                end
            end
        end
        table.sort(subKeys, function(a, b) return a.key < b.key end)

        for _, sub in ipairs(subKeys) do
            local sKey   = sub.key
            local subRow = AcquireRow(scrollChild)
            subRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", INDENT, -y)
            subRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

            local subName = (ns.SubzoneNames and ns.SubzoneNames[sKey]) or sKey
            subRow.label:SetPoint("LEFT", 4, 0)
            subRow.label:SetText(subName)
            subRow.label:SetFontObject(GameFontHighlightSmall)

            local subPackKey    = (ov and ov.subzones and ov.subzones[sKey]) or "DEFAULT"
            local defaultSubPack = zoneConfig and zoneConfig.subzones and zoneConfig.subzones[sKey]
            subRow.packBtn:SetText(GetPackLabel(subPackKey, defaultSubPack))
            subRow.packBtn:SetScript("OnClick", function(self)
                ShowPackMenu(self, subPackKey, not sub.isCustom, defaultSubPack, function(key)
                    if not db.zoneOverrides[mapId] then
                        db.zoneOverrides[mapId] = { isCustom = isCustom }
                    end
                    if not db.zoneOverrides[mapId].subzones then
                        db.zoneOverrides[mapId].subzones = {}
                    end
                    if key == "DEFAULT" then
                        db.zoneOverrides[mapId].subzones[sKey] = nil
                    else
                        db.zoneOverrides[mapId].subzones[sKey] = key
                    end
                    if not next(db.zoneOverrides[mapId].subzones) then
                        db.zoneOverrides[mapId].subzones = nil
                    end
                    if not db.zoneOverrides[mapId].pack
                       and not db.zoneOverrides[mapId].subzones
                       and not db.zoneOverrides[mapId].isCustom then
                        db.zoneOverrides[mapId] = nil
                    end
                    ns.ForceCheckZone()
                    RefreshMapper()
                end)
            end)

            if sub.isCustom then
                subRow.actionBtn:SetText("X")
                subRow.actionBtn:Show()
                subRow.actionBtn:SetScript("OnClick", function()
                    if ov and ov.subzones then
                        ov.subzones[sKey] = nil
                        if not next(ov.subzones) then ov.subzones = nil end
                    end
                    if ov and not ov.pack and not ov.subzones and not ov.isCustom then
                        db.zoneOverrides[mapId] = nil
                    end
                    ns.ForceCheckZone()
                    RefreshMapper()
                end)
            elseif ov and ov.subzones and ov.subzones[sKey] then
                subRow.actionBtn:SetText("R")
                subRow.actionBtn:Show()
                subRow.actionBtn:SetScript("OnClick", function()
                    if ov and ov.subzones then
                        ov.subzones[sKey] = nil
                        if not next(ov.subzones) then ov.subzones = nil end
                    end
                    if ov and not ov.pack and not ov.subzones and not ov.isCustom then
                        db.zoneOverrides[mapId] = nil
                    end
                    ns.ForceCheckZone()
                    RefreshMapper()
                end)
            else
                subRow.actionBtn:Hide()
            end

            activeRows[#activeRows + 1] = subRow
            y = y + ROW_HEIGHT
        end

        -- "+ Add Subzone" inline row
        local addSubRow = AcquireRow(scrollChild)
        addSubRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", INDENT, -y)
        addSubRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
        addSubRow.label:SetPoint("LEFT", 4, 0)
        addSubRow.label:SetText("|cff44DD44+ Add Subzone|r")
        addSubRow.label:SetFontObject(GameFontHighlightSmall)
        addSubRow.packBtn:Hide()
        addSubRow.actionBtn:Hide()

        addSubRow:EnableMouse(true)
        addSubRow:SetScript("OnMouseUp", function()
            StaticPopup_Show("EOQT_ADD_SUBZONE", nil, nil, { mapId = mapId, isCustom = isCustom })
        end)

        activeRows[#activeRows + 1] = addSubRow
        y = y + ROW_HEIGHT + 6
    end

    scrollChild:SetHeight(math.max(y, 1))
end

-- ----- static popups ------------------------------------------

StaticPopupDialogs["EOQT_ADD_SUBZONE"] = {
    text = "Enter subzone name (use /eoqt now for the exact text):",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self, data)
        local text = self.editBox:GetText():trim()
        if text == "" then return end
        local db = ns.db
        if not db or not data then return end
        local mapId = data.mapId
        if not db.zoneOverrides[mapId] then
            db.zoneOverrides[mapId] = { isCustom = data.isCustom }
        end
        if not db.zoneOverrides[mapId].subzones then
            db.zoneOverrides[mapId].subzones = {}
        end
        local key = ns.SubzoneKeys[text] or text
        if db.zoneOverrides[mapId].subzones[key] then
            print(PREFIX .. "Subzone already exists: " .. text)
            return
        end
        db.zoneOverrides[mapId].subzones[key] = "EVERSONG"
        print(PREFIX .. "Added subzone: " .. text)
        ns.ForceCheckZone()
        RefreshMapper()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        parent.button1:Click()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- ----- build the canvas frame ---------------------------------

local function InitZoneMapper()
    mapperFrame = CreateFrame("Frame", "EoQT_ZoneMapper", UIParent)

    local title = mapperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Zone Music Mapping")

    local desc = mapperFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetText("Assign music packs to zones and subzones. Use /eoqt now to find map IDs and subzone names.")
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")

    local btnAddSubzone = CreateFrame("Button", nil, mapperFrame, "UIPanelButtonTemplate")
    btnAddSubzone:SetSize(170, 24)
    btnAddSubzone:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    btnAddSubzone:SetText("+ Add Current Subzone")
    btnAddSubzone:SetScript("OnClick", function()
        local db = ns.db
        if not db then return end
        local subzoneText = GetSubZoneText()
        if not subzoneText or subzoneText == "" then
            print(PREFIX .. "No subzone detected at current location.")
            return
        end
        local mapId = C_Map.GetBestMapForUnit("player")
        if not mapId then
            print(PREFIX .. "Cannot determine current zone.")
            return
        end
        local zoneId = ns.ResolveZone and ns.ResolveZone(mapId)
        if not zoneId then
            print(PREFIX .. "Current zone is not configured. Add the zone first.")
            return
        end
        local key = ns.SubzoneKeys and ns.SubzoneKeys[subzoneText] or subzoneText
        local zoneConfig = ZONES[zoneId]
        if zoneConfig and zoneConfig.subzones and zoneConfig.subzones[key] then
            print(PREFIX .. "Subzone \"" .. subzoneText .. "\" already has a default mapping.")
            return
        end
        if not db.zoneOverrides[zoneId] then
            db.zoneOverrides[zoneId] = {}
        end
        if not db.zoneOverrides[zoneId].subzones then
            db.zoneOverrides[zoneId].subzones = {}
        end
        if db.zoneOverrides[zoneId].subzones[key] then
            print(PREFIX .. "Subzone \"" .. subzoneText .. "\" already has an override.")
            return
        end
        db.zoneOverrides[zoneId].subzones[key] = "EVERSONG"
        print(PREFIX .. "Added subzone: " .. subzoneText .. " (zone " .. zoneId .. ")")
        ns.ForceCheckZone()
        RefreshMapper()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "EoQT_ZoneMapperScroll", mapperFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", btnAddSubzone, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", mapperFrame, "BOTTOMRIGHT", -26, 8)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 560)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        scrollChild:SetWidth(w)
    end)

    mapperFrame:SetScript("OnShow", function() RefreshMapper() end)

    local subCategory = Settings.RegisterCanvasLayoutSubcategory(category, mapperFrame, "Zone Mapping")
    subCategory.ID = subCategory:GetID()
end

-- ============================================================
-- 3. Music Packs (Canvas Subcategory)
-- ============================================================

local RefreshPackList  -- forward declaration; defined below

local packListFrame, packScrollChild
local customSectionHdr  -- persistent, never pooled
local packHdrPool    = {}
local packTrkPool    = {}
local customHdrPool  = {}
local customTrkPool  = {}
local activeHdrs     = {}
local activeTrks     = {}
local activeCustomH  = {}
local activeCustomT  = {}
local expandedPacks  = {}
local previewingFdid = nil
local previewBtnRef  = nil

-- ----- track helpers ------------------------------------------

local function GetAllPackTracks(packKey)
    local pack = (ns.GetPack and ns.GetPack(packKey)) or PACKS[packKey]
    if not pack then return {} end
    local seen, tracks = {}, {}
    local function addList(list)
        if not list then return end
        for _, id in ipairs(list) do
            if not seen[id] then seen[id] = true; tracks[#tracks + 1] = id end
        end
    end
    if pack.intro then seen[pack.intro] = true; tracks[#tracks + 1] = pack.intro end
    addList(pack.day)
    addList(pack.night)
    addList(pack.any)
    return tracks
end

-- Returns a sorted list of all known FDIDs with names, grouped by prefix.
local TRACK_GROUPS_CACHE = nil
local function GetAllTracksSorted()
    if TRACK_GROUPS_CACHE then return TRACK_GROUPS_CACHE end
    local list = {}
    for name, id in pairs(ns.Tracks) do
        list[#list + 1] = { id = id, name = name }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    TRACK_GROUPS_CACHE = list
    return list
end

local function StopActivePreview()
    if previewingFdid and ns.StopPreview then ns.StopPreview() end
    if previewBtnRef then previewBtnRef:SetText("Play") end
    previewingFdid = nil
    previewBtnRef  = nil
end

-- ----- pack header row recycling ------------------------------

local function AcquirePackHdr(parent)
    local row = tremove(packHdrPool)
    if not row then
        row = CreateFrame("Button", nil, parent)
        row:SetHeight(PACK_HDR_H)
        row:SetNormalFontObject(GameFontNormal)
        row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")

        row.arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.arrow:SetPoint("LEFT", 4, 0)
        row.arrow:SetWidth(14)
        row.arrow:SetJustifyH("LEFT")

        row.nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nameStr:SetPoint("LEFT", row.arrow, "RIGHT", 2, 0)
        row.nameStr:SetJustifyH("LEFT")

        row.countStr = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.countStr:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.countStr:SetJustifyH("RIGHT")
    end
    row:SetParent(parent)
    row:Show()
    return row
end

local function ReleasePackHdrs()
    for _, row in ipairs(activeHdrs) do
        row:Hide()
        row:ClearAllPoints()
        row:SetScript("OnClick", nil)
        packHdrPool[#packHdrPool + 1] = row
    end
    wipe(activeHdrs)
end

local function ReleaseCustomHdrs()
    for _, row in ipairs(activeCustomH) do
        row:Hide()
        row:ClearAllPoints()
        row:SetScript("OnClick", nil)
        if row.renameBtn then row.renameBtn:SetScript("OnClick", nil) end
        if row.deleteBtn then row.deleteBtn:SetScript("OnClick", nil) end
        customHdrPool[#customHdrPool + 1] = row
    end
    wipe(activeCustomH)
end

local function ReleaseCustomTrks()
    for _, row in ipairs(activeCustomT) do
        row:Hide()
        row:ClearAllPoints()
        if row._isAddBtn then
            row:SetScript("OnClick", nil)
            -- add buttons are not pooled; they are recreated each render
        else
            row.playBtn:SetScript("OnClick", nil)
            row.removeBtn:SetScript("OnClick", nil)
            customTrkPool[#customTrkPool + 1] = row
        end
    end
    wipe(activeCustomT)
end

-- ----- track row recycling ------------------------------------

local function AcquirePackTrk(parent)
    local row = tremove(packTrkPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(TRACK_ROW_H)

        row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.check:SetSize(20, 20)
        row.check:SetPoint("LEFT", 4, 0)

        row.nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameLabel:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
        row.nameLabel:SetWidth(260)
        row.nameLabel:SetJustifyH("LEFT")
        row.nameLabel:SetWordWrap(false)

        row.durLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.durLabel:SetPoint("LEFT", row.nameLabel, "RIGHT", 4, 0)
        row.durLabel:SetWidth(50)
        row.durLabel:SetJustifyH("RIGHT")

        row.playBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.playBtn:SetSize(44, 20)
        row.playBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    end
    row:SetParent(parent)
    row:Show()
    return row
end

local function ReleasePackTrks()
    for _, row in ipairs(activeTrks) do
        row:Hide()
        row:ClearAllPoints()
        row.check:SetScript("OnClick", nil)
        row.playBtn:SetScript("OnClick", nil)
        packTrkPool[#packTrkPool + 1] = row
    end
    wipe(activeTrks)
end

-- Acquire a custom pack header row (has renameBtn + deleteBtn instead of countStr)
local function AcquireCustomHdr(parent)
    local row = tremove(customHdrPool)
    if not row then
        row = CreateFrame("Button", nil, parent)
        row:SetHeight(PACK_HDR_H)
        row:SetNormalFontObject(GameFontNormal)
        row:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")

        row.arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.arrow:SetPoint("LEFT", 4, 0)
        row.arrow:SetWidth(14)
        row.arrow:SetJustifyH("LEFT")

        row.nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nameStr:SetPoint("LEFT", row.arrow, "RIGHT", 2, 0)
        row.nameStr:SetJustifyH("LEFT")

        row.deleteBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.deleteBtn:SetSize(54, 20)
        row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row.deleteBtn:SetText("Delete")

        row.renameBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.renameBtn:SetSize(54, 20)
        row.renameBtn:SetPoint("RIGHT", row.deleteBtn, "LEFT", -4, 0)
        row.renameBtn:SetText("Rename")
    end
    row:SetParent(parent)
    row:Show()
    return row
end

-- Acquire a custom pack track row (no checkbox — all tracks always enabled;
-- has a removeBtn to remove the track from the custom pack)
local function AcquireCustomTrk(parent)
    local row = tremove(customTrkPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(TRACK_ROW_H)

        row.nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.nameLabel:SetPoint("LEFT", 8, 0)
        row.nameLabel:SetWidth(280)
        row.nameLabel:SetJustifyH("LEFT")
        row.nameLabel:SetWordWrap(false)

        row.durLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.durLabel:SetPoint("LEFT", row.nameLabel, "RIGHT", 4, 0)
        row.durLabel:SetWidth(50)
        row.durLabel:SetJustifyH("RIGHT")

        row.playBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.playBtn:SetSize(44, 20)
        row.playBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

        row.removeBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.removeBtn:SetSize(20, 20)
        row.removeBtn:SetPoint("RIGHT", row.playBtn, "LEFT", -4, 0)
        row.removeBtn:SetText("×")
    end
    row:SetParent(parent)
    row:Show()
    return row
end

-- ----- static popup dialogs for custom packs -----------------

StaticPopupDialogs["EOQT_NEW_PACK"] = {
    text        = "Enter a name for the new custom pack:",
    button1     = "Create",
    button2     = "Cancel",
    hasEditBox  = true,
    maxLetters  = 48,
    OnAccept    = function(self)
        local name = self.EditBox:GetText():trim()
        if name == "" then return end
        local key = "cp_" .. time()
        ns.db.customPacks[key] = { label = name, any = {} }
        expandedPacks[key] = true
        RefreshPackList()
    end,
    timeout     = 0,
    whileDead   = true,
    hideOnEscape = true,
}

StaticPopupDialogs["EOQT_RENAME_PACK"] = {
    text        = "New name for this pack:",
    button1     = "Rename",
    button2     = "Cancel",
    hasEditBox  = true,
    maxLetters  = 48,
    OnAccept    = function(self)
        local name = self.EditBox:GetText():trim()
        if name == "" then return end
        local key = self.data
        if ns.db.customPacks[key] then
            ns.db.customPacks[key].label = name
            RefreshPackList()
        end
    end,
    timeout     = 0,
    whileDead   = true,
    hideOnEscape = true,
}

StaticPopupDialogs["EOQT_DELETE_PACK"] = {
    text        = "Delete custom pack \"%s\"? This cannot be undone.",
    button1     = "Delete",
    button2     = "Cancel",
    OnAccept    = function(self)
        local key = self.data
        ns.db.customPacks[key] = nil
        expandedPacks[key] = nil
        RefreshPackList()
    end,
    timeout     = 0,
    whileDead   = true,
    hideOnEscape = true,
}

-- Track picker: a simple scrollable popup listing all tracks not yet in the pack.
local pickerFrame = nil

local function ShowTrackPicker(packKey, onPicked)
    if not pickerFrame then
        pickerFrame = CreateFrame("Frame", "EoQT_TrackPicker", UIParent, "BackdropTemplate")
        pickerFrame:SetSize(400, 380)
        pickerFrame:SetPoint("CENTER")
        pickerFrame:SetFrameStrata("DIALOG")
        pickerFrame:SetBackdrop({
            bgFile   = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            edgeSize = 16,
            insets   = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        pickerFrame:EnableMouse(true)
        pickerFrame:SetMovable(true)
        pickerFrame:RegisterForDrag("LeftButton")
        pickerFrame:SetScript("OnDragStart", pickerFrame.StartMoving)
        pickerFrame:SetScript("OnDragStop",  pickerFrame.StopMovingOrSizing)

        local titleTxt = pickerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        titleTxt:SetPoint("TOP", 0, -12)
        titleTxt:SetText("Add Track")
        pickerFrame.titleTxt = titleTxt

        local closeBtn = CreateFrame("Button", nil, pickerFrame, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        closeBtn:SetScript("OnClick", function() pickerFrame:Hide() end)

        local sf = CreateFrame("ScrollFrame", nil, pickerFrame, "UIPanelScrollFrameTemplate")
        sf:SetPoint("TOPLEFT",     pickerFrame, "TOPLEFT",     8,  -36)
        sf:SetPoint("BOTTOMRIGHT", pickerFrame, "BOTTOMRIGHT", -26,  8)
        pickerFrame.scrollFrame = sf

        local sc = CreateFrame("Frame", nil, sf)
        sc:SetWidth(sf:GetWidth() or 360)
        sf:SetScrollChild(sc)
        sf:SetScript("OnSizeChanged", function(self, w) sc:SetWidth(w) end)
        pickerFrame.scrollChild = sc
    end

    -- Populate the picker with tracks not yet in the pack
    local sc = pickerFrame.scrollChild
    -- Release any previous rows
    for i = sc:GetNumChildren(), 1, -1 do
        local c = select(i, sc:GetChildren())
        if c then c:Hide() end
    end

    local pack = ns.db.customPacks[packKey]
    if not pack then pickerFrame:Hide(); return end

    local existing = {}
    if pack.any then
        for _, id in ipairs(pack.any) do existing[id] = true end
    end

    local allTracks = GetAllTracksSorted()
    local y = 0
    local ROW_H = 22
    for _, entry in ipairs(allTracks) do
        if not existing[entry.id] then
            local btn = CreateFrame("Button", nil, sc)
            btn:SetHeight(ROW_H)
            btn:SetPoint("TOPLEFT", sc, "TOPLEFT", 0, -y)
            btn:SetPoint("RIGHT",   sc, "RIGHT",   0,  0)
            btn:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight", "ADD")

            local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            lbl:SetPoint("LEFT", 8, 0)
            lbl:SetText(entry.name)
            lbl:SetWidth(260)
            lbl:SetJustifyH("LEFT")

            local dur = DURATIONS and DURATIONS[entry.id]
            local durLbl = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            durLbl:SetPoint("RIGHT", -8, 0)
            durLbl:SetText(dur and string.format("%ds", math.floor(dur)) or "?")

            local capturedId = entry.id
            btn:SetScript("OnClick", function()
                onPicked(capturedId)
                pickerFrame:Hide()
            end)

            y = y + ROW_H
        end
    end
    sc:SetHeight(math.max(y, 1))

    pickerFrame:Show()
end

-- ----- main render --------------------------------------------

RefreshPackList = function()
    if not packScrollChild or not ns.db then return end
    StopActivePreview()
    ReleasePackHdrs()
    ReleasePackTrks()
    ReleaseCustomHdrs()
    ReleaseCustomTrks()

    local db = ns.db
    local y  = 0

    -- ---- Built-in packs ----
    for _, packKey in ipairs(PACK_ORDER) do
        local pack   = PACKS[packKey]
        local tracks = GetAllPackTracks(packKey)
        local isOpen = expandedPacks[packKey]

        -- Pack header
        local hdr = AcquirePackHdr(packScrollChild)
        hdr:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", 0, -y)
        hdr:SetPoint("RIGHT",   packScrollChild, "RIGHT",   0,  0)

        hdr.arrow:SetText(isOpen and "▼" or "▶")
        hdr.nameStr:SetText(pack.label)
        hdr.countStr:SetText("|cff888888" .. #tracks .. " track" .. (#tracks == 1 and "" or "s") .. "|r")

        local capturedKey = packKey
        hdr:SetScript("OnClick", function()
            expandedPacks[capturedKey] = not expandedPacks[capturedKey]
            RefreshPackList()
        end)

        activeHdrs[#activeHdrs + 1] = hdr
        y = y + PACK_HDR_H

        if isOpen then
            local disabledTbl = (db.packOverrides and db.packOverrides[packKey] and db.packOverrides[packKey].disabled) or {}
            local dbd         = pack.disabledByDefault

            local function IsTrackDisabled(fdid)
                local v = disabledTbl[fdid]
                if v == true  then return true  end
                if v == false then return false end
                return dbd and dbd[fdid] or false
            end

            for _, fdid in ipairs(tracks) do
                local trow = AcquirePackTrk(packScrollChild)
                trow:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", INDENT, -y)
                trow:SetPoint("RIGHT",   packScrollChild, "RIGHT",    0,      0)

                local trackName = TRACK_NAMES[fdid] or tostring(fdid)
                local dur       = DURATIONS and DURATIONS[fdid]
                trow.nameLabel:SetText(trackName)
                trow.durLabel:SetText(dur and string.format("%ds", math.floor(dur)) or "?")

                trow.check:SetChecked(not IsTrackDisabled(fdid))
                trow.check:SetScript("OnClick", function(self)
                    if not db.packOverrides[packKey] then
                        db.packOverrides[packKey] = { disabled = {} }
                    end
                    if not db.packOverrides[packKey].disabled then
                        db.packOverrides[packKey].disabled = {}
                    end
                    local dis = db.packOverrides[packKey].disabled
                    if self:GetChecked() then
                        if dbd and dbd[fdid] then
                            dis[fdid] = false
                        else
                            dis[fdid] = nil
                        end
                    else
                        if dis[fdid] == false then
                            dis[fdid] = nil
                        else
                            dis[fdid] = true
                        end
                    end
                    if not next(dis) then
                        db.packOverrides[packKey] = nil
                    end
                end)

                local localFdid = fdid
                trow.playBtn:SetText("Play")
                trow.playBtn:SetScript("OnClick", function(self)
                    if previewingFdid == localFdid then
                        StopActivePreview()
                    else
                        StopActivePreview()
                        previewingFdid = localFdid
                        previewBtnRef  = self
                        self:SetText("Stop")
                        if ns.PreviewTrack then ns.PreviewTrack(localFdid) end
                    end
                end)

                activeTrks[#activeTrks + 1] = trow
                y = y + TRACK_ROW_H
            end

            y = y + 4
        end
    end

    -- ---- Custom packs section header (persistent frame, never pooled) ----
    y = y + 8

    customSectionHdr:SetParent(packScrollChild)
    customSectionHdr:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", 0, -y)
    customSectionHdr:SetPoint("RIGHT",   packScrollChild, "RIGHT",   0,  0)
    customSectionHdr:Show()
    y = y + PACK_HDR_H

    -- ---- Custom pack entries ----
    local hasCustom = false
    -- Sort by label for stable ordering
    local customList = {}
    for k, cp in pairs(db.customPacks) do
        customList[#customList + 1] = { key = k, pack = cp }
    end
    table.sort(customList, function(a, b)
        return (a.pack.label or a.key) < (b.pack.label or b.key)
    end)

    for _, entry in ipairs(customList) do
        hasCustom = true
        local cpKey  = entry.key
        local cp     = entry.pack
        local isOpen = expandedPacks[cpKey]
        local anyList = cp.any or {}

        local hdr = AcquireCustomHdr(packScrollChild)
        hdr:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", 0, -y)
        hdr:SetPoint("RIGHT",   packScrollChild, "RIGHT",   0,  0)
        hdr.arrow:SetText(isOpen and "▼" or "▶")
        hdr.nameStr:SetText(cp.label or cpKey)

        local capturedKey = cpKey
        hdr:SetScript("OnClick", function()
            expandedPacks[capturedKey] = not expandedPacks[capturedKey]
            RefreshPackList()
        end)
        hdr.renameBtn:SetScript("OnClick", function()
            local dlg = StaticPopup_Show("EOQT_RENAME_PACK")
            if dlg then
                dlg.data = capturedKey
                dlg.EditBox:SetText(ns.db.customPacks[capturedKey].label or "")
                dlg.EditBox:HighlightText()
            end
        end)
        hdr.deleteBtn:SetScript("OnClick", function()
            local dlg = StaticPopup_Show("EOQT_DELETE_PACK",
                ns.db.customPacks[capturedKey] and ns.db.customPacks[capturedKey].label or capturedKey)
            if dlg then dlg.data = capturedKey end
        end)

        activeCustomH[#activeCustomH + 1] = hdr
        y = y + PACK_HDR_H

        if isOpen then
            -- Existing tracks in the custom pack
            for i, fdid in ipairs(anyList) do
                local trow = AcquireCustomTrk(packScrollChild)
                trow:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", INDENT, -y)
                trow:SetPoint("RIGHT",   packScrollChild, "RIGHT",    0,      0)

                local trackName = TRACK_NAMES[fdid] or tostring(fdid)
                local dur = DURATIONS and DURATIONS[fdid]
                trow.nameLabel:SetText(trackName)
                trow.durLabel:SetText(dur and string.format("%ds", math.floor(dur)) or "?")

                trow.playBtn:SetText("Play")
                local localFdid = fdid
                trow.playBtn:SetScript("OnClick", function(self)
                    if previewingFdid == localFdid then
                        StopActivePreview()
                    else
                        StopActivePreview()
                        previewingFdid = localFdid
                        previewBtnRef  = self
                        self:SetText("Stop")
                        if ns.PreviewTrack then ns.PreviewTrack(localFdid) end
                    end
                end)

                local localIdx = i
                local localKey = cpKey
                trow.removeBtn:SetScript("OnClick", function()
                    local list = ns.db.customPacks[localKey] and ns.db.customPacks[localKey].any
                    if list then
                        tremove(list, localIdx)
                        RefreshPackList()
                    end
                end)

                activeCustomT[#activeCustomT + 1] = trow
                y = y + TRACK_ROW_H
            end

            -- "+ Add Track" button
            local addBtn = CreateFrame("Button", nil, packScrollChild, "UIPanelButtonTemplate")
            addBtn:SetSize(90, 20)
            addBtn:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", INDENT, -y)
            addBtn:SetText("+ Add Track")
            local localKey = cpKey
            addBtn:SetScript("OnClick", function()
                ShowTrackPicker(localKey, function(fdid)
                    if not ns.db.customPacks[localKey] then return end
                    ns.db.customPacks[localKey].any = ns.db.customPacks[localKey].any or {}
                    table.insert(ns.db.customPacks[localKey].any, fdid)
                    RefreshPackList()
                end)
            end)
            -- Store add button ref so ReleaseCustomTrks can hide it
            addBtn._isAddBtn = true
            activeCustomT[#activeCustomT + 1] = addBtn
            y = y + TRACK_ROW_H + 4
        end
    end

    if not hasCustom then
        -- Placeholder text if no custom packs exist
        local none = AcquirePackHdr(packScrollChild)
        none:SetPoint("TOPLEFT", packScrollChild, "TOPLEFT", INDENT, -y)
        none:SetPoint("RIGHT",   packScrollChild, "RIGHT",   0,  0)
        none.arrow:SetText("")
        none.nameStr:SetText("|cff888888No custom packs yet. Click + New Pack to create one.|r")
        none.countStr:SetText("")
        none:SetScript("OnClick", nil)
        activeHdrs[#activeHdrs + 1] = none
        y = y + PACK_HDR_H
    end

    packScrollChild:SetHeight(math.max(y, 1))
end

-- ----- build the canvas frame ---------------------------------

local function InitPacksPanel()
    packListFrame = CreateFrame("Frame", "EoQT_PacksPanel", UIParent)

    local title = packListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Music Packs")

    local desc = packListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetText("Enable or disable individual tracks per pack, and preview them in-game. Click a pack name to expand it.")
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")

    local scrollFrame = CreateFrame("ScrollFrame", "EoQT_PacksPanelScroll", packListFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     desc,          "BOTTOMLEFT",  0, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", packListFrame, "BOTTOMRIGHT", -26,  8)

    packScrollChild = CreateFrame("Frame", nil, scrollFrame)
    packScrollChild:SetWidth(scrollFrame:GetWidth() or 560)
    scrollFrame:SetScrollChild(packScrollChild)
    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        packScrollChild:SetWidth(w)
    end)

    -- Build the persistent Custom Packs section header once
    customSectionHdr = CreateFrame("Frame", nil, packScrollChild)
    customSectionHdr:SetHeight(PACK_HDR_H)

    local cshLabel = customSectionHdr:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cshLabel:SetPoint("LEFT", 4, 0)
    cshLabel:SetText("|cffFFD700Custom Packs|r")

    local newPackBtn = CreateFrame("Button", nil, customSectionHdr, "UIPanelButtonTemplate")
    newPackBtn:SetSize(80, 20)
    newPackBtn:SetPoint("RIGHT", customSectionHdr, "RIGHT", -4, 0)
    newPackBtn:SetText("+ New Pack")
    newPackBtn:SetScript("OnClick", function()
        StaticPopup_Show("EOQT_NEW_PACK")
    end)

    packListFrame:SetScript("OnShow", function() RefreshPackList() end)
    packListFrame:SetScript("OnHide", function()
        StopActivePreview()
        if pickerFrame then pickerFrame:Hide() end
        if customSectionHdr then customSectionHdr:Hide() end
    end)

    local subCategory = Settings.RegisterCanvasLayoutSubcategory(category, packListFrame, "Music Packs")
    subCategory.ID = subCategory:GetID()
end

-- ============================================================
-- Profiles panel — named profiles, export / import
-- ============================================================

StaticPopupDialogs["EOQT_RENAME_PROFILE"] = {
    text        = "New name for this profile:",
    button1     = "Rename",
    button2     = "Cancel",
    hasEditBox  = true,
    maxLetters  = 48,
    OnAccept    = function(self)
        local name = self.EditBox:GetText():trim()
        if name == "" then return end
        ns.RenameProfile(self.data.key, name)
        if self.data.refresh then self.data.refresh() end
    end,
    timeout     = 0,
    whileDead   = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["EOQT_IMPORT_NEW_PROFILE"] = {
    text        = "Name for the new profile:",
    button1     = "Import",
    button2     = "Cancel",
    hasEditBox  = true,
    maxLetters  = 48,
    OnAccept    = function(self)
        local name = self.EditBox:GetText():trim()
        if name == "" then name = "Imported Profile" end
        local ok, result = ns.ImportIntoNewProfile(self.data.str, name)
        if ok then
            print(self.data.prefix .. "Profile \"" .. name .. "\" created successfully.")
            if self.data.refresh then self.data.refresh() end
        else
            print(self.data.prefix .. "Import failed: " .. (result or "unknown error"))
        end
    end,
    timeout     = 0,
    whileDead   = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function InitProfilesPanel()
    local PREFIX = "|cffFFD700Echoes of Quel'Thalas:|r "

    local profileFrame = CreateFrame("Frame", "EoQT_ProfilesPanel", UIParent)

    -- ---- Profile List section ----

    local profileListTitle = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    profileListTitle:SetPoint("TOPLEFT", 16, -16)
    profileListTitle:SetText("Profiles")

    local profileListDesc = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profileListDesc:SetPoint("TOPLEFT", profileListTitle, "BOTTOMLEFT", 0, -4)
    profileListDesc:SetText("Switch between named configurations. Each profile has its own zone mapping and music packs.")
    profileListDesc:SetWidth(520)
    profileListDesc:SetJustifyH("LEFT")

    local profileListContainer = CreateFrame("Frame", nil, profileFrame)
    profileListContainer:SetPoint("TOPLEFT", profileListDesc, "BOTTOMLEFT", 0, -10)
    profileListContainer:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT", -16, 0)
    profileListContainer:SetHeight(10)

    local btnNewProfile = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    btnNewProfile:SetSize(130, 24)
    btnNewProfile:SetText("+ New Profile")

    local ROW_H = 28
    local profileRows = {}

    local function RefreshProfileList()
        for _, row in ipairs(profileRows) do row:Hide() end
        profileRows = {}

        local list = ns.GetProfileList and ns.GetProfileList() or {}
        local totalH = 0

        for i, entry in ipairs(list) do
            local row = CreateFrame("Frame", nil, profileListContainer)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
            row:SetPoint("TOPRIGHT", profileListContainer, "TOPRIGHT", 0, -(i - 1) * ROW_H)
            row:SetHeight(ROW_H)

            local nameLabel = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameLabel:SetPoint("LEFT", 4, 0)
            nameLabel:SetText(entry.active and ("|cffFFD700" .. entry.name .. "|r  (active)") or entry.name)

            local capturedKey = entry.key
            local lastLeftBtn = nil

            local btnRename = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            btnRename:SetSize(70, 22)
            btnRename:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            btnRename:SetText("Rename")
            btnRename:SetScript("OnClick", function()
                local dlg = StaticPopup_Show("EOQT_RENAME_PROFILE")
                if dlg then
                    dlg.data = { key = capturedKey, refresh = RefreshProfileList }
                    dlg.EditBox:SetText(entry.name)
                    dlg.EditBox:HighlightText()
                end
            end)
            lastLeftBtn = btnRename

            if not entry.active then
                local btnSwitch = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                btnSwitch:SetSize(60, 22)
                btnSwitch:SetPoint("RIGHT", btnRename, "LEFT", -4, 0)
                btnSwitch:SetText("Switch")
                btnSwitch:SetScript("OnClick", function()
                    ns.SwitchProfile(capturedKey)
                    RefreshMapper()
                    RefreshPackList()
                    RefreshProfileList()
                end)
                lastLeftBtn = btnSwitch
            end

            if entry.key ~= "default" then
                local btnDelete = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
                btnDelete:SetSize(60, 22)
                btnDelete:SetPoint("RIGHT", lastLeftBtn, "LEFT", -4, 0)
                btnDelete:SetText("Delete")
                btnDelete:SetScript("OnClick", function()
                    local ok, err = ns.DeleteProfile(capturedKey)
                    if ok then
                        RefreshMapper()
                        RefreshPackList()
                        RefreshProfileList()
                    else
                        print(PREFIX .. (err or "Could not delete profile."))
                    end
                end)
            end

            profileRows[#profileRows + 1] = row
            totalH = i * ROW_H
        end

        profileListContainer:SetHeight(math.max(totalH, 10))
        btnNewProfile:SetPoint("TOPLEFT", profileListContainer, "BOTTOMLEFT", 0, -8)
    end

    btnNewProfile:SetScript("OnClick", function()
        local key = ns.CreateProfile("New Profile")
        RefreshProfileList()
        local dlg = StaticPopup_Show("EOQT_RENAME_PROFILE")
        if dlg then
            dlg.data = { key = key, refresh = RefreshProfileList }
            dlg.EditBox:SetText("New Profile")
            dlg.EditBox:HighlightText()
        end
    end)

    profileFrame:SetScript("OnShow", RefreshProfileList)

    -- ---- Export section ----

    local exportTitle = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    exportTitle:SetPoint("TOPLEFT", btnNewProfile, "BOTTOMLEFT", 0, -20)
    exportTitle:SetText("Export")

    local exportDesc = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    exportDesc:SetPoint("TOPLEFT", exportTitle, "BOTTOMLEFT", 0, -4)
    exportDesc:SetText("Generate a compact string of your active profile to share with others.")
    exportDesc:SetWidth(520)
    exportDesc:SetJustifyH("LEFT")

    local btnExport = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    btnExport:SetSize(150, 24)
    btnExport:SetPoint("TOPLEFT", exportDesc, "BOTTOMLEFT", 0, -10)
    btnExport:SetText("Export to String")

    local btnPrintChat = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    btnPrintChat:SetSize(130, 24)
    btnPrintChat:SetPoint("LEFT", btnExport, "RIGHT", 8, 0)
    btnPrintChat:SetText("Print to Chat")

    local exportSF = CreateFrame("ScrollFrame", nil, profileFrame, "UIPanelScrollFrameTemplate")
    exportSF:SetPoint("TOPLEFT",    btnExport,    "BOTTOMLEFT",  0,  -8)
    exportSF:SetPoint("TOPRIGHT",   profileFrame, "TOPRIGHT",  -26,   0)
    exportSF:SetHeight(80)

    local exportSC = CreateFrame("Frame", nil, exportSF)
    exportSF:SetScrollChild(exportSC)
    exportSC:SetHeight(76)

    local exportEB = CreateFrame("EditBox", nil, exportSC)
    exportEB:SetMultiLine(true)
    exportEB:SetMaxLetters(0)
    exportEB:SetFontObject(ChatFontNormal)
    exportEB:SetHeight(76)
    exportEB:SetPoint("TOPLEFT")
    exportEB:SetAutoFocus(false)
    exportEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    exportSF:SetScript("OnSizeChanged", function(self, w)
        exportSC:SetWidth(w)
        exportEB:SetWidth(w)
    end)

    btnExport:SetScript("OnClick", function()
        local str, err = ns.ExportProfile()
        if str then
            exportEB:SetText(str)
            exportEB:HighlightText()
            exportEB:SetFocus()
        else
            exportEB:SetText("Error: " .. (err or "nothing to export"))
        end
    end)

    btnPrintChat:SetScript("OnClick", function()
        local str = exportEB:GetText()
        if not str or str == "" then
            str = ns.ExportProfile()
        end
        if not str then
            print(PREFIX .. "Nothing to export.")
            return
        end
        local CHUNK = 200
        local total = math.ceil(#str / CHUNK)
        print(PREFIX .. "Profile export (" .. #str .. " chars, " .. total .. " message(s)):")
        for i = 1, total do
            DEFAULT_CHAT_FRAME:AddMessage(
                string.format("[EoQT %d/%d] %s", i, total, str:sub((i - 1) * CHUNK + 1, i * CHUNK)))
        end
    end)

    -- ---- Import section ----

    local importTitle = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    importTitle:SetPoint("TOPLEFT", exportSF, "BOTTOMLEFT", 0, -20)
    importTitle:SetText("Import")

    local importDesc = profileFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    importDesc:SetPoint("TOPLEFT", importTitle, "BOTTOMLEFT", 0, -4)
    importDesc:SetText("Paste a profile string below, then choose how to import it.")
    importDesc:SetWidth(520)
    importDesc:SetJustifyH("LEFT")

    local importSF = CreateFrame("ScrollFrame", nil, profileFrame, "UIPanelScrollFrameTemplate")
    importSF:SetPoint("TOPLEFT",  importDesc,   "BOTTOMLEFT", 0,  -8)
    importSF:SetPoint("TOPRIGHT", profileFrame, "TOPRIGHT",  -26,  0)
    importSF:SetHeight(80)

    local importSC = CreateFrame("Frame", nil, importSF)
    importSF:SetScrollChild(importSC)
    importSC:SetHeight(76)

    local importEB = CreateFrame("EditBox", nil, importSC)
    importEB:SetMultiLine(true)
    importEB:SetMaxLetters(0)
    importEB:SetFontObject(ChatFontNormal)
    importEB:SetHeight(76)
    importEB:SetPoint("TOPLEFT")
    importEB:SetAutoFocus(false)
    importEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    importSF:SetScript("OnSizeChanged", function(self, w)
        importSC:SetWidth(w)
        importEB:SetWidth(w)
    end)

    -- ---- Merge / Replace / Cancel choice popup ----

    local choiceFrame
    local function ShowImportChoice(str)
        if not choiceFrame then
            choiceFrame = CreateFrame("Frame", "EoQT_ImportChoice", UIParent, "BackdropTemplate")
            choiceFrame:SetSize(380, 150)
            choiceFrame:SetPoint("CENTER")
            choiceFrame:SetFrameStrata("DIALOG")
            choiceFrame:SetBackdrop({
                bgFile   = "Interface/DialogFrame/UI-DialogBox-Background",
                edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
                edgeSize = 16,
                insets   = { left = 4, right = 4, top = 4, bottom = 4 },
            })
            choiceFrame:EnableMouse(true)

            local titleTxt = choiceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            titleTxt:SetPoint("TOP", 0, -14)
            titleTxt:SetText("Import into Current Profile")

            local bodyTxt = choiceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            bodyTxt:SetPoint("TOP", titleTxt, "BOTTOM", 0, -10)
            bodyTxt:SetText("How would you like to apply this profile?")
            bodyTxt:SetWidth(340)
            bodyTxt:SetJustifyH("CENTER")

            local hintTxt = choiceFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            hintTxt:SetPoint("TOP", bodyTxt, "BOTTOM", 0, -6)
            hintTxt:SetText("|cff888888Merge adds only zones not already configured.\nReplace overwrites your entire zone mapping.|r")
            hintTxt:SetWidth(340)
            hintTxt:SetJustifyH("CENTER")

            local btnMerge = CreateFrame("Button", nil, choiceFrame, "UIPanelButtonTemplate")
            btnMerge:SetSize(100, 24)
            btnMerge:SetPoint("BOTTOMLEFT", choiceFrame, "BOTTOMLEFT", 16, 14)
            btnMerge:SetText("Merge")
            btnMerge:SetScript("OnClick", function()
                choiceFrame:Hide()
                local ok, err = ns.ImportProfile(choiceFrame.pendingStr, "merge")
                if ok then
                    print(PREFIX .. "Profile merged successfully.")
                    RefreshMapper()
                    RefreshPackList()
                else
                    print(PREFIX .. "Import failed: " .. (err or "unknown error"))
                end
            end)

            local btnReplace = CreateFrame("Button", nil, choiceFrame, "UIPanelButtonTemplate")
            btnReplace:SetSize(100, 24)
            btnReplace:SetPoint("BOTTOM", choiceFrame, "BOTTOM", 0, 14)
            btnReplace:SetText("Replace")
            btnReplace:SetScript("OnClick", function()
                choiceFrame:Hide()
                local ok, err = ns.ImportProfile(choiceFrame.pendingStr, "replace")
                if ok then
                    print(PREFIX .. "Profile replaced successfully.")
                    RefreshMapper()
                    RefreshPackList()
                else
                    print(PREFIX .. "Import failed: " .. (err or "unknown error"))
                end
            end)

            local btnCancel = CreateFrame("Button", nil, choiceFrame, "UIPanelButtonTemplate")
            btnCancel:SetSize(100, 24)
            btnCancel:SetPoint("BOTTOMRIGHT", choiceFrame, "BOTTOMRIGHT", -16, 14)
            btnCancel:SetText("Cancel")
            btnCancel:SetScript("OnClick", function() choiceFrame:Hide() end)
        end

        choiceFrame.pendingStr = str
        choiceFrame:Show()
    end

    -- ---- Import buttons ----

    local btnImportCurrent = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    btnImportCurrent:SetSize(190, 24)
    btnImportCurrent:SetPoint("TOPLEFT", importSF, "BOTTOMLEFT", 0, -8)
    btnImportCurrent:SetText("Import into current profile")
    btnImportCurrent:SetScript("OnClick", function()
        local str = importEB:GetText():gsub("%s+", "")
        if str == "" then
            print(PREFIX .. "Paste a profile string first.")
            return
        end
        ShowImportChoice(str)
    end)

    local btnImportNew = CreateFrame("Button", nil, profileFrame, "UIPanelButtonTemplate")
    btnImportNew:SetSize(180, 24)
    btnImportNew:SetPoint("LEFT", btnImportCurrent, "RIGHT", 8, 0)
    btnImportNew:SetText("Import as new profile")
    btnImportNew:SetScript("OnClick", function()
        local str = importEB:GetText():gsub("%s+", "")
        if str == "" then
            print(PREFIX .. "Paste a profile string first.")
            return
        end
        local dlg = StaticPopup_Show("EOQT_IMPORT_NEW_PROFILE")
        if dlg then
            dlg.data = { str = str, prefix = PREFIX, refresh = RefreshProfileList }
            dlg.EditBox:SetText("Imported Profile")
            dlg.EditBox:HighlightText()
        end
    end)

    Settings.RegisterCanvasLayoutSubcategory(category, profileFrame, "Profiles")
end

-- ============================================================
-- ns.InitOptions — called synchronously from Engine.lua's
-- ADDON_LOADED handler once ns.db is ready.
-- ============================================================

function ns.InitOptions()
    local db = ns.db
    if not db then return end

    -- Enable
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "EOQT_ENABLED", "enabled", db,
            Settings.VarType.Boolean, "Enable Addon", true)
        setting:SetValueChangedCallback(function(_, val)
            ns.SetEnabled(val)
        end)
        Settings.CreateCheckbox(category, setting,
            "Toggle custom music playback on or off.")
    end

    -- Verbose
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "EOQT_VERBOSE", "verbose", db,
            Settings.VarType.Boolean, "Verbose Mode", false)
        setting:SetValueChangedCallback(function(_, val)
            db.verbose = val
        end)
        Settings.CreateCheckbox(category, setting,
            "Print the current track name and duration in chat each time a new track starts.")
    end

    -- Silence Gap
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "EOQT_SILENCE_GAP", "silenceGap", db,
            Settings.VarType.Number, "Silence Gap (seconds)", 4)
        local options = Settings.CreateSliderOptions(0, 10, 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, setting, options,
            "Duration of silence between tracks (0 = no gap).")
    end

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategoryID = category:GetID()

    InitZoneMapper()
    InitPacksPanel()
    InitProfilesPanel()
end
