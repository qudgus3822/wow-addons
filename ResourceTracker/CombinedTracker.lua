-- Combined Resource and Health Tracker
-- Shows Health and Maelstrom in one movable frame

local addonName = "CombinedTracker"

-- Locked state
local isLocked = true

-- Create main container frame
local container = CreateFrame("Frame", "CombinedTrackerFrame", UIParent)
container:SetSize(300, 130)
container:SetPoint("CENTER", 0, -100)
container:SetMovable(true)
container:EnableMouse(false) -- Start locked
container:RegisterForDrag("LeftButton")
container:SetScript("OnDragStart", function(self)
    if not isLocked then
        self:StartMoving()
    end
end)
container:SetScript("OnDragStop", container.StopMovingOrSizing)

-- Container background
local containerBg = container:CreateTexture(nil, "BACKGROUND")
containerBg:SetAllPoints(container)
containerBg:SetColorTexture(0, 0, 0, 0.7)

-- Drag instruction text (only shown when unlocked)
local dragText = container:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
dragText:SetPoint("BOTTOM", container, "BOTTOM", 0, 2)
dragText:SetText("")
dragText:SetTextColor(1, 1, 0, 1)

-- ========================================
-- HEALTH BAR
-- ========================================

-- Health bar frame
local healthBar = CreateFrame("StatusBar", nil, container)
healthBar:SetSize(280, 40)
healthBar:SetPoint("TOP", container, "TOP", 0, -10)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)
healthBar:GetStatusBarTexture():SetHorizTile(false)

-- Health bar background
local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints(healthBar)
healthBg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

-- Health percentage text (center)
local healthPercent = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
healthPercent:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
healthPercent:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
healthPercent:SetText("100%")

-- Health detail text (left)
local healthDetail = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
healthDetail:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
healthDetail:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
healthDetail:SetText("HP")
healthDetail:SetTextColor(0.8, 0.8, 0.8, 1)

-- ========================================
-- MAELSTROM BAR (only for Elemental Shaman)
-- ========================================

-- Maelstrom frame
local maelstromFrame = CreateFrame("Frame", nil, container)
maelstromFrame:SetSize(280, 60)
maelstromFrame:SetPoint("TOP", healthBar, "BOTTOM", 0, -5)

-- Maelstrom progress bar (bigger, on top)
local maelstromBar = CreateFrame("StatusBar", nil, maelstromFrame)
maelstromBar:SetSize(280, 35)
maelstromBar:SetPoint("TOP", maelstromFrame, "TOP", 0, 0)
maelstromBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
maelstromBar:SetMinMaxValues(0, 100)
maelstromBar:SetValue(0)
maelstromBar:GetStatusBarTexture():SetHorizTile(false)

-- Maelstrom text (on bar)
local maelstromText = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
maelstromText:SetPoint("CENTER", maelstromBar, "CENTER", 0, 0)
maelstromText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
maelstromText:SetText("0")

-- Maelstrom label (below bar)
local maelstromLabel = maelstromFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
maelstromLabel:SetPoint("TOP", maelstromBar, "BOTTOM", 0, -2)
maelstromLabel:SetText("Maelstrom")
maelstromLabel:SetTextColor(0.5, 0.8, 1, 1)

-- Maelstrom bar background
local maelstromBg = maelstromBar:CreateTexture(nil, "BACKGROUND")
maelstromBg:SetAllPoints(maelstromBar)
maelstromBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

-- Threshold lines for Maelstrom (30 and 60)
local threshold30 = maelstromBar:CreateTexture(nil, "OVERLAY")
threshold30:SetSize(2, 35)
threshold30:SetColorTexture(1, 1, 1, 0.5)
threshold30:SetPoint("LEFT", maelstromBar, "LEFT", (280 * 0.3), 0) -- 30% position

local threshold60 = maelstromBar:CreateTexture(nil, "OVERLAY")
threshold60:SetSize(2, 35)
threshold60:SetColorTexture(1, 1, 1, 0.5)
threshold60:SetPoint("LEFT", maelstromBar, "LEFT", (280 * 0.6), 0) -- 60% position

-- Threshold labels
local label30 = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label30:SetPoint("BOTTOM", threshold30, "TOP", 0, 1)
label30:SetText("30")
label30:SetTextColor(1, 1, 1, 0.6)
label30:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

local label60 = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label60:SetPoint("BOTTOM", threshold60, "TOP", 0, 1)
label60:SetText("60")
label60:SetTextColor(1, 1, 1, 0.6)
label60:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

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

-- Update Maelstrom bar color
local function UpdateMaelstromColor(value)
    local r = 0.2 + (value / 100) * 0.3
    local g = 0.5 + (value / 100) * 0.5
    local b = 1.0
    maelstromBar:SetStatusBarColor(r, g, b, 1)
end

-- ========================================
-- UPDATE FUNCTIONS
-- ========================================

-- Update Health
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
    healthPercent:SetText(string.format("%.0f%%", percent))
    healthDetail:SetText(string.format("%s / %s", FormatNumber(current), FormatNumber(max)))

    -- Color based on health percentage
    if percent >= 75 then
        healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green
        healthPercent:SetTextColor(1, 1, 1, 1)
    elseif percent >= 50 then
        healthBar:SetStatusBarColor(1, 1, 0, 1) -- Yellow
        healthPercent:SetTextColor(1, 1, 1, 1)
    elseif percent >= 25 then
        healthBar:SetStatusBarColor(1, 0.5, 0, 1) -- Orange
        healthPercent:SetTextColor(1, 1, 1, 1)
    else
        healthBar:SetStatusBarColor(1, 0, 0, 1) -- Red
        healthPercent:SetTextColor(1, 1, 1, 1)
    end

    -- Flash when low health
    if percent < 20 and percent > 0 then
        if not container.flashing then
            container.flashing = true
            UIFrameFlash(healthBar, 0.5, 0.5, -1, false, 0, 0)
        end
    else
        if container.flashing then
            container.flashing = false
            UIFrameFlashStop(healthBar)
        end
    end
end

-- Update Maelstrom
local function UpdateMaelstrom()
    -- Check if player is Shaman
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        maelstromFrame:Hide()
        container:SetSize(300, 60) -- Smaller size without Maelstrom
        return
    end

    -- Check if Elemental spec (1=Elemental, 2=Enhancement, 3=Restoration)
    local spec = GetSpecialization()
    if spec ~= 1 then
        maelstromFrame:Hide()
        container:SetSize(300, 60) -- Smaller size without Maelstrom
        return
    end

    -- Show Maelstrom frame
    maelstromFrame:Show()
    container:SetSize(300, 130) -- Full size with Maelstrom

    -- Get Maelstrom
    local current = UnitPower("player", Enum.PowerType.Maelstrom)
    local max = UnitPowerMax("player", Enum.PowerType.Maelstrom)

    -- Update display
    maelstromText:SetText(current)
    maelstromBar:SetValue(current)
    maelstromBar:SetMinMaxValues(0, max)
    UpdateMaelstromColor(current)

    -- Change text color based on amount
    if current >= 60 then
        maelstromText:SetTextColor(0, 1, 1, 1)       -- Cyan (ready for big spell)
    elseif current >= 30 then
        maelstromText:SetTextColor(0.5, 0.8, 1, 1)   -- Light blue
    else
        maelstromText:SetTextColor(0.3, 0.5, 0.7, 1) -- Dark blue (low)
    end
end

-- Update all
local function UpdateAll()
    UpdateHealth()
    UpdateMaelstrom()
end

-- ========================================
-- EVENT HANDLER
-- ========================================

container:RegisterEvent("UNIT_HEALTH")
container:RegisterEvent("UNIT_MAXHEALTH")
container:RegisterEvent("UNIT_POWER_UPDATE")
container:RegisterEvent("UNIT_POWER_FREQUENT")
container:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
container:RegisterEvent("PLAYER_ENTERING_WORLD")
container:RegisterEvent("ADDON_LOADED")

container:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "ResourceTracker" then
            print("|cff00ff00[Combined Tracker]|r Loaded!")
            print("|cffffff00Use /ct move to unlock and drag the frame.|r")
            UpdateAll()
        end
    elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        local unit = ...
        if unit == "player" then
            UpdateHealth()
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
        local unit = ...
        if unit == "player" then
            UpdateMaelstrom()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        UpdateAll()
    end
end)

-- ========================================
-- SLASH COMMANDS
-- ========================================

SLASH_COMBINEDTRACKER1 = "/ct"
SLASH_COMBINEDTRACKER2 = "/tracker"
SlashCmdList["COMBINEDTRACKER"] = function(msg)
    local command = msg:lower()

    if command == "show" then
        container:Show()
        print("|cff00ff00[Combined Tracker]|r Frame shown.")
    elseif command == "hide" then
        container:Hide()
        print("|cff00ff00[Combined Tracker]|r Frame hidden.")
    elseif command == "reset" then
        container:ClearAllPoints()
        container:SetPoint("CENTER", 0, -100)
        print("|cff00ff00[Combined Tracker]|r Position reset.")
    elseif command == "move" or command == "unlock" then
        isLocked = false
        container:EnableMouse(true)
        dragText:SetText("🔓 Drag to move")
        containerBg:SetColorTexture(0.2, 0.2, 0, 0.8)
        print("|cffffff00[Combined Tracker]|r Frame UNLOCKED. Drag to move.")
    elseif command == "freeze" or command == "lock" then
        isLocked = true
        container:EnableMouse(false)
        dragText:SetText("")
        containerBg:SetColorTexture(0, 0, 0, 0.7)
        print("|cff00ff00[Combined Tracker]|r Frame LOCKED.")
    else
        print("|cff00ff00[Combined Tracker]|r Commands:")
        print("  /ct move - Unlock frame (drag to move)")
        print("  /ct freeze - Lock frame (prevent moving)")
        print("  /ct show - Show frame")
        print("  /ct hide - Hide frame")
        print("  /ct reset - Reset position")
    end
end

-- Initialize
UpdateAll()
