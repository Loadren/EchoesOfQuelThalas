local addonName, ns = ...

-- ============================================================
-- Options.lua — Settings panel (Options > AddOns) and
-- zone-to-music-pack mapping UI.
--
-- Section 1: General settings  (vertical layout — native controls)
-- Section 2: Zone mapping      (canvas subcategory — custom frame)
-- ============================================================

local PACKS      = ns.MusicPacks
local PACK_ORDER = ns.MusicPackOrder
local ZONES      = ns.ZoneMusic
local L          = ns.L
local PREFIX     = "|cffFFD700Echoes of Quel'Thalas:|r "

local ROW_HEIGHT = 24
local INDENT     = 20

-- ============================================================
-- 1. General Settings (Vertical Layout)
--
-- Category is registered at file scope (load time) so the
-- settings panel sees it immediately. Controls are added later
-- from ns.InitOptions(), called synchronously by Engine.lua
-- inside its ADDON_LOADED handler once ns.db is ready.
--
-- Uses the 11.0.2+ Settings API:
--   Settings.RegisterAddOnSetting(category, variable, variableKey,
--       variableTbl, varType, name, defaultValue)
--   setting:SetValueChangedCallback(fn)
-- ============================================================

local category = Settings.RegisterVerticalLayoutCategory("Echoes of Quel'Thalas")

-- ============================================================
-- 2. Zone Mapping (Canvas Subcategory)
-- ============================================================

local mapperFrame, scrollChild
local rowPool = {}
local activeRows = {}

-- ----- helpers ------------------------------------------------

local function GetPackLabel(key, defaultPackKey)
    if key == "NONE" then return "|cffFF4444None|r" end
    if not key or key == "DEFAULT" then
        if defaultPackKey then
            local pack = PACKS[defaultPackKey]
            return "|cff88cc88" .. (pack and pack.label or defaultPackKey) .. "|r"
        end
        return "|cff888888—|r"
    end
    local pack = PACKS[key]
    return pack and pack.label or key
end

local function PackDropdownOptions(includeDefault, defaultPackKey)
    local items = {}
    if includeDefault then
        local hint = "Default"
        if defaultPackKey then
            local pack = PACKS[defaultPackKey]
            hint = "Default (" .. (pack and pack.label or defaultPackKey) .. ")"
        end
        items[#items + 1] = { key = "DEFAULT", label = hint }
    end
    for _, k in ipairs(PACK_ORDER) do
        items[#items + 1] = { key = k, label = PACKS[k].label }
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

        row.packBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.packBtn:SetSize(160, 22)
        row.packBtn:SetPoint("RIGHT", row, "RIGHT", -32, 0)

        row.actionBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.actionBtn:SetSize(24, 22)
        row.actionBtn:SetPoint("LEFT", row.packBtn, "RIGHT", 4, 0)
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
    local y = 0

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
        local mapId = entry.mapId
        local zoneConfig = ZONES[mapId]
        local ov = db.zoneOverrides and db.zoneOverrides[mapId]
        local isCustom = entry.isCustom

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
            local sKey = sub.key
            local subRow = AcquireRow(scrollChild)
            subRow:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", INDENT, -y)
            subRow:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

            local subName = (ns.SubzoneNames and ns.SubzoneNames[sKey]) or sKey
            subRow.label:SetPoint("LEFT", 4, 0)
            subRow.label:SetText(subName)
            subRow.label:SetFontObject(GameFontHighlightSmall)

            local subPackKey = (ov and ov.subzones and ov.subzones[sKey]) or "DEFAULT"
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
                    -- Clean up empty override entries
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

        -- "+ Add Subzone" button
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

StaticPopupDialogs["EOQT_ADD_ZONE_ID"] = {
    text = "Enter UiMapID (use /eoqt now in-game to find it):",
    button1 = "Add",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local text = self.editBox:GetText():trim()
        local mapId = tonumber(text)
        if not mapId then
            print(PREFIX .. "Invalid map ID: " .. text)
            return
        end
        local db = ns.db
        if not db then return end
        if ZONES[mapId] or (db.zoneOverrides[mapId] and db.zoneOverrides[mapId].isCustom) then
            print(PREFIX .. "Zone " .. mapId .. " already exists.")
            return
        end
        local info = C_Map.GetMapInfo(mapId)
        local name = info and info.name or ("Zone " .. mapId)
        db.zoneOverrides[mapId] = {
            isCustom = true,
            name = name,
            pack = "EVERSONG",
            subzones = {},
        }
        print(PREFIX .. "Added zone: " .. name .. " (" .. mapId .. ")")
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

    -- Title
    local title = mapperFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Zone Music Mapping")

    local desc = mapperFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetText("Assign music packs to zones and subzones. Use /eoqt now to find map IDs and subzone names.")
    desc:SetWidth(540)
    desc:SetJustifyH("LEFT")

    -- Top buttons
    local btnAddCurrent = CreateFrame("Button", nil, mapperFrame, "UIPanelButtonTemplate")
    btnAddCurrent:SetSize(160, 24)
    btnAddCurrent:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
    btnAddCurrent:SetText("+ Add Current Zone")
    btnAddCurrent:SetScript("OnClick", function()
        local db = ns.db
        if not db then return end
        local mapId = C_Map.GetBestMapForUnit("player")
        if not mapId then
            print(PREFIX .. "Cannot determine current zone.")
            return
        end
        if ZONES[mapId] or (db.zoneOverrides[mapId] and db.zoneOverrides[mapId].isCustom) then
            print(PREFIX .. "Zone " .. mapId .. " is already configured.")
            return
        end
        local info = C_Map.GetMapInfo(mapId)
        local name = info and info.name or ("Zone " .. mapId)
        db.zoneOverrides[mapId] = {
            isCustom = true,
            name = name,
            pack = "EVERSONG",
            subzones = {},
        }
        print(PREFIX .. "Added zone: " .. name .. " (" .. mapId .. ")")
        ns.ForceCheckZone()
        RefreshMapper()
    end)

    local btnAddById = CreateFrame("Button", nil, mapperFrame, "UIPanelButtonTemplate")
    btnAddById:SetSize(140, 24)
    btnAddById:SetPoint("LEFT", btnAddCurrent, "RIGHT", 8, 0)
    btnAddById:SetText("+ Add Zone by ID")
    btnAddById:SetScript("OnClick", function()
        StaticPopup_Show("EOQT_ADD_ZONE_ID")
    end)

    local btnAddSubzone = CreateFrame("Button", nil, mapperFrame, "UIPanelButtonTemplate")
    btnAddSubzone:SetSize(170, 24)
    btnAddSubzone:SetPoint("LEFT", btnAddById, "RIGHT", 8, 0)
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

    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "EoQT_ZoneMapperScroll", mapperFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", btnAddCurrent, "BOTTOMLEFT", 0, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", mapperFrame, "BOTTOMRIGHT", -26, 8)

    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth() or 560)
    scrollFrame:SetScrollChild(scrollChild)

    -- Resize the scroll child width when the scroll frame resizes
    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        scrollChild:SetWidth(w)
    end)

    mapperFrame:SetScript("OnShow", function()
        RefreshMapper()
    end)

    local subCategory = Settings.RegisterCanvasLayoutSubcategory(category, mapperFrame, "Zone Mapping")
    subCategory.ID = subCategory:GetID()
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

    -- Crossfade Duration
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "EOQT_CROSSFADE", "crossfadeSec", db,
            Settings.VarType.Number, "Crossfade Duration (seconds)", 3)
        local options = Settings.CreateSliderOptions(1, 5, 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, setting, options,
            "How long the fade-to-silence transition lasts when leaving a configured zone.")
    end

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategoryID = category:GetID()

    InitZoneMapper()
end
