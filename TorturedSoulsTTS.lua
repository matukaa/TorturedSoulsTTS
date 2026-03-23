-- ============================================================
--  TorturedSoulsTTS — by Matukaa
--  TTS alerts on Vessel of Tortured Souls orb spawn/pickup
-- ============================================================

-- ── Orb-pickup buff spell ID ────────────────────────────────
local ORB_PICKUP_SPELL_ID = 1265566
local ORB_SPAWNED_SPELL_ID = 1265513

-- ── Defaults ───────────────────────────────────────────────
local DEFAULTS = {
    voiceIndex  = 1,             -- index into C_VoiceChat.GetTtsVoices()
    spawnText   = "Orb spawned",
    pickupText  = "Orb picked up",
    spawnEnabled = true,
    pickupEnabled = true,
    spawnRate   = 0,
    spawnVolume = 100,
    pickupRate  = 0,
    pickupVolume = 100,
}

-- ── SavedVariables initialization ──────────────────────────
local function InitDB()
    if not TorturedSoulsTTSDB then TorturedSoulsTTSDB = {} end
    for k, v in pairs(DEFAULTS) do
        if TorturedSoulsTTSDB[k] == nil then
            TorturedSoulsTTSDB[k] = v
        end
    end
end

-- ── Speak via TTS ──────────────────────────────────────────
local function SpeakText(text, rate, volume)
    local voices = C_VoiceChat.GetTtsVoices()
    if not voices or #voices == 0 then return end
    local vi    = TorturedSoulsTTSDB.voiceIndex or 1
    local voice = voices[vi] or voices[1]
    C_VoiceChat.SpeakText(voice.voiceID, text,
        rate or 0,
        volume or 100,
        true)
end

local function PlaySpawnSound()
    if not TorturedSoulsTTSDB.spawnEnabled then return end
    SpeakText(
        TorturedSoulsTTSDB.spawnText or "Orb spawned",
        TorturedSoulsTTSDB.spawnRate or 0,
        TorturedSoulsTTSDB.spawnVolume or 100
    )
end

local function PlayPickupSound()
    if not TorturedSoulsTTSDB.pickupEnabled then return end
    SpeakText(
        TorturedSoulsTTSDB.pickupText or "Orb picked up",
        TorturedSoulsTTSDB.pickupRate or 0,
        TorturedSoulsTTSDB.pickupVolume or 100
    )
end

-- ═══════════════════════════════════════════════════════════
--  Helper: scrollable picker
--  getList  : function() -> { {label, value}, ... }
--  onSelect : function(value)
-- ═══════════════════════════════════════════════════════════
local function CreateScrollPicker(parent, width, getList, onSelect)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 22)
    btn:GetFontString():SetJustifyH("LEFT")
    btn:GetFontString():SetPoint("LEFT", btn, "LEFT", 6, 0)

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(16, 16)
    arrow:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

    local popup = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    popup:SetSize(width, 200)
    popup:Hide()

    local sf = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",     popup, "TOPLEFT",     4,   -4)
    sf:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -24,  4)

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(width - 28)
    sf:SetScrollChild(content)

    local ROW_H = 20
    local rows  = {}

    local function Populate(list)
        for _, r in ipairs(rows) do r:Hide() end
        wipe(rows)
        content:SetHeight(#list * ROW_H + 4)

        for i, entry in ipairs(list) do
            local row = CreateFrame("Button", nil, content)
            row:SetSize(width - 28, ROW_H)
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i - 1) * ROW_H)

            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(1, 1, 1, 0.15)

            local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            label:SetPoint("LEFT", row, "LEFT", 4, 0)
            label:SetText(entry.label)
            label:SetWordWrap(false)

            row:SetScript("OnClick", function()
                onSelect(entry.value)
                btn:SetText(entry.label)
                popup:Hide()
            end)

            rows[i] = row
        end
    end

    btn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
            return
        end
        Populate(getList())
        sf:SetVerticalScroll(0)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
        popup:Show()
    end)

    local closer = CreateFrame("Frame", nil, UIParent)
    closer:SetAllPoints(UIParent)
    closer:SetFrameStrata("FULLSCREEN")
    closer:EnableMouse(true)
    closer:Hide()
    closer:SetScript("OnMouseDown", function()
        popup:Hide()
        closer:Hide()
    end)
    popup:SetScript("OnShow", function() closer:Show() end)
    popup:SetScript("OnHide", function() closer:Hide() end)

    function btn:SetSelection(label)
        self:SetText(label)
    end

    return btn
end

-- ═══════════════════════════════════════════════════════════
--  Main configuration panel
-- ═══════════════════════════════════════════════════════════
local function ClampVolume(value, fallback)
    return math.max(0, math.min(100, tonumber(value) or fallback))
end

local function CreateConfigPanel()
    local panel = CreateFrame("Frame", "TorturedSoulsTTSConfigPanel", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(420, 390)
    panel:SetPoint("CENTER")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop",  panel.StopMovingOrSizing)
    panel:Hide()

    panel.TitleText:SetText("TorturedSoulsTTS — Configuration")

    local inset = panel.InsetBg
    local PAD   = 14

    -- ── TTS Voice ──────────────────────────────────────────
    local voiceLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    voiceLabel:SetPoint("TOPLEFT", inset, "TOPLEFT", PAD, -PAD)
    voiceLabel:SetText("TTS voice:")

    local voicePicker = CreateScrollPicker(panel, 370,
        function()
            local voices = C_VoiceChat.GetTtsVoices()
            local list = {}
            for i, v in ipairs(voices or {}) do
                list[i] = { label = v.name, value = i }
            end
            if #list == 0 then
                list[1] = { label = "(no voices available)", value = 1 }
            end
            return list
        end,
        function(index)
            TorturedSoulsTTSDB.voiceIndex = index
        end
    )
    voicePicker:SetPoint("TOPLEFT", voiceLabel, "BOTTOMLEFT", 0, -6)
    do
        local voices = C_VoiceChat.GetTtsVoices()
        local vi = TorturedSoulsTTSDB.voiceIndex or 1
        voicePicker:SetSelection((voices and voices[vi] and voices[vi].name) or "(default)")
    end

    -- ── Orb spawn text ─────────────────────────────────────
    local spawnLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spawnLabel:SetPoint("TOPLEFT", voicePicker, "BOTTOMLEFT", 0, -12)
    spawnLabel:SetText("Orb spawn text:")

    local spawnEnabledCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    spawnEnabledCheck:SetPoint("LEFT", spawnLabel, "RIGHT", 8, 0)
    spawnEnabledCheck:SetChecked(TorturedSoulsTTSDB.spawnEnabled)
    spawnEnabledCheck:SetScript("OnClick", function(self)
        TorturedSoulsTTSDB.spawnEnabled = self:GetChecked() and true or false
    end)

    local spawnEnabledText = spawnEnabledCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spawnEnabledText:SetPoint("LEFT", spawnEnabledCheck, "RIGHT", 2, 0)
    spawnEnabledText:SetText("Enable alert")

    local spawnBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    spawnBox:SetSize(280, 22)
    spawnBox:SetPoint("TOPLEFT", spawnLabel, "BOTTOMLEFT", 0, -4)
    spawnBox:SetAutoFocus(false)
    spawnBox:SetText(TorturedSoulsTTSDB.spawnText or "Orb spawned")
    spawnBox:SetScript("OnEditFocusLost", function(self) TorturedSoulsTTSDB.spawnText = self:GetText() end)
    spawnBox:SetScript("OnEnterPressed",  function(self) TorturedSoulsTTSDB.spawnText = self:GetText(); self:ClearFocus() end)

    local testSpawnBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testSpawnBtn:SetSize(70, 22)
    testSpawnBtn:SetPoint("LEFT", spawnBox, "RIGHT", 6, 0)
    testSpawnBtn:SetText("Test")
    testSpawnBtn:SetScript("OnClick", function()
        TorturedSoulsTTSDB.spawnText = spawnBox:GetText()
        PlaySpawnSound()
    end)

    local spawnRateLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spawnRateLabel:SetPoint("TOPLEFT", spawnBox, "BOTTOMLEFT", 0, -12)
    spawnRateLabel:SetText("Spawn rate:")

    local spawnRateBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    spawnRateBox:SetSize(55, 22)
    spawnRateBox:SetPoint("LEFT", spawnRateLabel, "RIGHT", 6, 0)
    spawnRateBox:SetAutoFocus(false)
    spawnRateBox:SetText(tostring(TorturedSoulsTTSDB.spawnRate or 0))
    spawnRateBox:SetScript("OnEditFocusLost", function(self)
        TorturedSoulsTTSDB.spawnRate = tonumber(self:GetText()) or 0
        self:SetText(tostring(TorturedSoulsTTSDB.spawnRate))
    end)
    spawnRateBox:SetScript("OnEnterPressed", function(self)
        TorturedSoulsTTSDB.spawnRate = tonumber(self:GetText()) or 0
        self:SetText(tostring(TorturedSoulsTTSDB.spawnRate))
        self:ClearFocus()
    end)

    local spawnVolLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    spawnVolLabel:SetPoint("LEFT", spawnRateBox, "RIGHT", 20, 0)
    spawnVolLabel:SetText("Spawn volume:")

    local spawnVolBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    spawnVolBox:SetSize(55, 22)
    spawnVolBox:SetPoint("LEFT", spawnVolLabel, "RIGHT", 6, 0)
    spawnVolBox:SetAutoFocus(false)
    spawnVolBox:SetNumeric(true)
    spawnVolBox:SetText(tostring(TorturedSoulsTTSDB.spawnVolume or 100))
    spawnVolBox:SetScript("OnEditFocusLost", function(self)
        TorturedSoulsTTSDB.spawnVolume = ClampVolume(self:GetText(), 100)
        self:SetText(tostring(TorturedSoulsTTSDB.spawnVolume))
    end)
    spawnVolBox:SetScript("OnEnterPressed", function(self)
        TorturedSoulsTTSDB.spawnVolume = ClampVolume(self:GetText(), 100)
        self:SetText(tostring(TorturedSoulsTTSDB.spawnVolume))
        self:ClearFocus()
    end)

    -- ── Orb pickup text ────────────────────────────────────
    local pickupLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pickupLabel:SetPoint("TOPLEFT", spawnRateLabel, "BOTTOMLEFT", 0, -12)
    pickupLabel:SetText("Orb pickup text:")

    local pickupEnabledCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    pickupEnabledCheck:SetPoint("LEFT", pickupLabel, "RIGHT", 8, 0)
    pickupEnabledCheck:SetChecked(TorturedSoulsTTSDB.pickupEnabled)
    pickupEnabledCheck:SetScript("OnClick", function(self)
        TorturedSoulsTTSDB.pickupEnabled = self:GetChecked() and true or false
    end)

    local pickupEnabledText = pickupEnabledCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pickupEnabledText:SetPoint("LEFT", pickupEnabledCheck, "RIGHT", 2, 0)
    pickupEnabledText:SetText("Enable alert")

    local pickupBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    pickupBox:SetSize(280, 22)
    pickupBox:SetPoint("TOPLEFT", pickupLabel, "BOTTOMLEFT", 0, -4)
    pickupBox:SetAutoFocus(false)
    pickupBox:SetText(TorturedSoulsTTSDB.pickupText or "Orb picked up")
    pickupBox:SetScript("OnEditFocusLost", function(self) TorturedSoulsTTSDB.pickupText = self:GetText() end)
    pickupBox:SetScript("OnEnterPressed",  function(self) TorturedSoulsTTSDB.pickupText = self:GetText(); self:ClearFocus() end)

    local testPickupBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testPickupBtn:SetSize(70, 22)
    testPickupBtn:SetPoint("LEFT", pickupBox, "RIGHT", 6, 0)
    testPickupBtn:SetText("Test")
    testPickupBtn:SetScript("OnClick", function()
        TorturedSoulsTTSDB.pickupText = pickupBox:GetText()
        PlayPickupSound()
    end)

    local pickupRateLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pickupRateLabel:SetPoint("TOPLEFT", pickupBox, "BOTTOMLEFT", 0, -12)
    pickupRateLabel:SetText("Pickup rate:")

    local pickupRateBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    pickupRateBox:SetSize(55, 22)
    pickupRateBox:SetPoint("LEFT", pickupRateLabel, "RIGHT", 6, 0)
    pickupRateBox:SetAutoFocus(false)
    pickupRateBox:SetText(tostring(TorturedSoulsTTSDB.pickupRate or 0))
    pickupRateBox:SetScript("OnEditFocusLost", function(self)
        TorturedSoulsTTSDB.pickupRate = tonumber(self:GetText()) or 0
        self:SetText(tostring(TorturedSoulsTTSDB.pickupRate))
    end)
    pickupRateBox:SetScript("OnEnterPressed", function(self)
        TorturedSoulsTTSDB.pickupRate = tonumber(self:GetText()) or 0
        self:SetText(tostring(TorturedSoulsTTSDB.pickupRate))
        self:ClearFocus()
    end)

    local pickupVolLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pickupVolLabel:SetPoint("LEFT", pickupRateBox, "RIGHT", 20, 0)
    pickupVolLabel:SetText("Pickup volume:")

    local pickupVolBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    pickupVolBox:SetSize(55, 22)
    pickupVolBox:SetPoint("LEFT", pickupVolLabel, "RIGHT", 6, 0)
    pickupVolBox:SetAutoFocus(false)
    pickupVolBox:SetNumeric(true)
    pickupVolBox:SetText(tostring(TorturedSoulsTTSDB.pickupVolume or 100))
    pickupVolBox:SetScript("OnEditFocusLost", function(self)
        TorturedSoulsTTSDB.pickupVolume = ClampVolume(self:GetText(), 100)
        self:SetText(tostring(TorturedSoulsTTSDB.pickupVolume))
    end)
    pickupVolBox:SetScript("OnEnterPressed", function(self)
        TorturedSoulsTTSDB.pickupVolume = ClampVolume(self:GetText(), 100)
        self:SetText(tostring(TorturedSoulsTTSDB.pickupVolume))
        self:ClearFocus()
    end)

    return panel
end

-- ── Main events ────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")

local configPanel

eventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "TorturedSoulsTTS" then
        InitDB()
        configPanel = CreateConfigPanel()
        return
    end

    if event == "SPELL_UPDATE_COOLDOWN" then
        local spellID, baseSpellID = arg1, ...
        if spellID == ORB_SPAWNED_SPELL_ID or baseSpellID == ORB_SPAWNED_SPELL_ID then
            PlaySpawnSound()
        end
        if spellID == ORB_PICKUP_SPELL_ID or baseSpellID == ORB_PICKUP_SPELL_ID then
            PlayPickupSound()
        end
    end
end)

-- ── Slash commands ─────────────────────────────────────────
SLASH_TORTUREDSOULSTTS1 = "/vtstts"
SLASH_TORTUREDSOULSTTS2 = "/vts"
SlashCmdList["TORTUREDSOULSTTS"] = function()
    if configPanel then
        if configPanel:IsShown() then
            configPanel:Hide()
        else
            configPanel:Show()
        end
    end
end
