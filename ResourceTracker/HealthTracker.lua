-- Health Tracker - Custom Health Bar
-- Shows health in a clean, customizable format

local addonName = "HealthTracker"

-- Create main frame
local frame = CreateFrame("Frame", "HealthTrackerFrame", UIParent)
frame:SetSize(300, 40)
frame:SetPoint("CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Background
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetColorTexture(0, 0, 0, 0.8)

-- Health bar
local healthBar = CreateFrame("StatusBar", nil, frame)
healthBar:SetSize(280, 25)
healthBar:SetPoint("CENTER", frame, "CENTER", 0, 0)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)
healthBar:GetStatusBarTexture():SetHorizTile(false)

-- Health bar background
local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints(healthBar)
healthBg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

-- Health text (center)
local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
healthText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
healthText:SetText("100%")
healthText:SetTextColor(1, 1, 1, 1)

-- Detailed health text (current/max)
local detailText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
detailText:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
detailText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
detailText:SetText("100k / 100k")
detailText:SetTextColor(0.8, 0.8, 0.8, 1)

-- Name text
local nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
nameText:SetPoint("BOTTOM", healthBar, "TOP", 0, 2)
nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
nameText:SetText(UnitName("player"))
nameText:SetTextColor(1, 1, 1, 1)

-- Format number (K/M format)
local function FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(num)
    end
end

-- Update health display
local function UpdateHealth()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")
    local percent = 0

    if max > 0 then
        percent = (current / max) * 100
    end

    -- Update bar
    healthBar:SetMinMaxValues(0, max)
    healthBar:SetValue(current)

    -- Update texts
    healthText:SetText(string.format("%.0f%%", percent))
    detailText:SetText(string.format("%s / %s", FormatNumber(current), FormatNumber(max)))

    -- Color based on health percentage
    if percent >= 75 then
        healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
    elseif percent >= 50 then
        healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
    elseif percent >= 25 then
        healthBar:SetStatusBarColor(1, 0.5, 0, 1) -- Orange
    else
        healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
    end

    -- Flash when low health
    if percent < 20 and percent > 0 then
        if not frame.flashing then
            frame.flashing = true
            UIFrameFlash(healthBar, 0.5, 0.5, -1, false, 0, 0)
        end
    else
        if frame.flashing then
            frame.flashing = false
            UIFrameFlashStop(healthBar)
        end
    end
end

-- Event handler
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "ResourceTracker" then
            print("|cff00ff00[Health Tracker]|r Loaded!")
            print("|cffffff00Drag the frame to move it.|r")
            UpdateHealth()
        end
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then
            UpdateHealth()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        UpdateHealth()
    end
end)

-- Slash commands
SLASH_HEALTHTRACKER1 = "/ht"
SLASH_HEALTHTRACKER2 = "/health"
SlashCmdList["HEALTHTRACKER"] = function(msg)
    local command = msg:lower()

    if command == "show" then
        frame:Show()
        print("|cff00ff00[Health Tracker]|r Frame shown.")
    elseif command == "hide" then
        frame:Hide()
        print("|cff00ff00[Health Tracker]|r Frame hidden.")
    elseif command == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", 0, 0)
        print("|cff00ff00[Health Tracker]|r Position reset.")
    else
        print("|cff00ff00[Health Tracker]|r Commands:")
        print("  /ht show - Show frame")
        print("  /ht hide - Hide frame")
        print("  /ht reset - Reset position")
    end
end

-- Initialize
UpdateHealth()
