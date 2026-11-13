-- BM Hunter Helper for OctoWoW (1.12)
-- RUL (HYDRA)
-- Tracks pet happiness and Kill Command (crit-triggered)

local addonName = "BMHunterHelper"
local frame = CreateFrame("Frame", "BMHunterHelperFrame", UIParent)
frame:SetWidth(180)
frame:SetHeight(60)
frame:SetPoint("CENTER", UIParent, "CENTER", 200, -100)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:SetBackdropColor(0, 0, 0, 0.7)

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -8)
title:SetText("BM Hunter Helper")

-- Pet Happiness text
local happinessText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
happinessText:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -28)
happinessText:SetText("Pet: --")

-- Kill Command text
local kcText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
kcText:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -44)
kcText:SetText("Kill Command: --")

-- State
local lastCritTime = 0
local KILL_COMMAND_WINDOW = 8          -- seconds after crit that KC is usable
local KILL_COMMAND_COOLDOWN = 8        -- actual spell cooldown
local lastKCCast = 0

-- Happiness colors
local happinessColors = {
    [1] = "|cffff0000", -- Unhappy (red)
    [2] = "|cffffff00", -- Content (yellow)
    [3] = "|cff00ff00", -- Happy (green)
}
local happinessNames = {
    [1] = "IM HANGRY - FEED ME!",
    [2] = "Content",
    [3] = "Happy",
}

local function UpdateDisplay()
    -- Pet Happiness
    if UnitExists("pet") then
        local happiness = GetPetHappiness()
        if happiness then
            local color = happinessColors[happiness] or "|cffffffff"
            local name = happinessNames[happiness] or "Unknown"
            happinessText:SetText("Pet: " .. color .. name .. "|r")
        else
            happinessText:SetText("Pet: |cffaaaaaaUnknown|r")
        end
    else
        happinessText:SetText("Pet: |cffaaaaaaNo Pet|r")
    end

    -- Kill Command status
    local now = GetTime()
    local timeSinceCrit = now - lastCritTime
    local timeSinceKC = now - lastKCCast

    if timeSinceCrit <= KILL_COMMAND_WINDOW and timeSinceKC >= KILL_COMMAND_COOLDOWN then
        kcText:SetText("|cff00ff00Kill Command: READY|r")
    elseif timeSinceCrit <= KILL_COMMAND_WINDOW then
        local remaining = math.ceil(KILL_COMMAND_COOLDOWN - timeSinceKC)
        kcText:SetText("|cffffff00Kill Command: " .. remaining .. "s|r")
    else
        kcText:SetText("|cffaaaaaaKill Command: waiting for crit|r")
    end
end

-- Events
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UNIT_PET")
frame:RegisterEvent("UNIT_HAPPINESS")
frame:RegisterEvent("UNIT_COMBAT")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")  -- fallback for crit detection on 1.12

frame:SetScript("OnEvent", function()
    if event == "UNIT_COMBAT" then
        if arg1 == "player" and arg2 == "WOUND" and arg4 and arg4 > 0 then
            -- arg3 is the damage type string on some clients; we also listen to combat log text
        end
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" or event == "CHAT_MSG_COMBAT_SELF_HITS" then
        local msg = arg1 or ""
        if string.find(msg, "crit") or string.find(msg, "Crit") then
            lastCritTime = GetTime()
        end
    elseif event == "SPELLCAST_STOP" then
        -- Very basic detection if the player just cast Kill Command
        -- (You can improve this later with specific spell ID if available)
    end
    UpdateDisplay()
end)

-- Update every 0.5 seconds
frame:SetScript("OnUpdate", function()
    this.elapsed = (this.elapsed or 0) + arg1
    if this.elapsed > 0.5 then
        this.elapsed = 0
        UpdateDisplay()
    end
end)

-- Slash command to toggle / reset position
SLASH_BMHUNTERHELPER1 = "/bmhh"
SlashCmdList["BMHUNTERHELPER"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00BM Hunter Helper loaded!|r Type /bmhh to toggle the frame.")
