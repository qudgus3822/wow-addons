-- Combined Resource and Health Tracker
-- Shows Health and Maelstrom in one movable frame

local addonName = "CombinedTracker"

-- Locked state
local isLocked = true

-- Settings
-- local showHealthBar = false  -- Health Bar 기본값: 꺼짐

-- Initialize SavedVariables
CombinedTrackerDB = CombinedTrackerDB or {
    debugMode = false,
    debugLog = {}
}

-- Debug mode (set to true to see debug messages)
local DEBUG_MODE = false

local function DebugPrint(...)
    if not DEBUG_MODE then
        return
    end

    -- 채팅창에 출력
    local msg = strjoin(" ", tostringall(...))
    print("|cffaaaaaa[CT Debug]|r", msg)

    -- SavedVariables에 로그 저장
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, msg)
    table.insert(CombinedTrackerDB.debugLog, logEntry)
end

-- Create main container frame
local container = CreateFrame("Frame", "CombinedTrackerFrame", UIParent)
container:SetSize(200, 40)
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
healthBar:SetSize(180, 20)
healthBar:SetPoint("TOP", container, "TOP", 0, -10)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)
healthBar:GetStatusBarTexture():SetHorizTile(false)
healthBar:SetStatusBarColor(0, 0.8, 0, 1) -- Green (default color)

-- Health bar background
local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints(healthBar)
healthBg:SetColorTexture(0.1, 0.1, 0.1, 0.9)

-- Health percentage text (center) - REMOVED
-- local healthPercent = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
-- healthPercent:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
-- healthPercent:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
-- healthPercent:SetText("100%")

-- Health detail text (left) - REMOVED
-- local healthDetail = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- healthDetail:SetPoint("LEFT", healthBar, "LEFT", 5, 0)
-- healthDetail:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
-- healthDetail:SetText("HP")
-- healthDetail:SetTextColor(0.8, 0.8, 0.8, 1)

-- ========================================
-- MAELSTROM BAR (only for Elemental Shaman)
-- ========================================

-- Maelstrom frame
local maelstromFrame = CreateFrame("Frame", nil, container)
maelstromFrame:SetSize(180, 20)
maelstromFrame:SetPoint("TOP", healthBar, "BOTTOM", 0, -5)

-- Maelstrom progress bar (bigger, on top)
local maelstromBar = CreateFrame("StatusBar", nil, maelstromFrame)
maelstromBar:SetSize(180, 20)
maelstromBar:SetPoint("TOP", maelstromFrame, "TOP", 0, 0)
maelstromBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
maelstromBar:SetMinMaxValues(0, 100)
maelstromBar:SetValue(0)
maelstromBar:GetStatusBarTexture():SetHorizTile(false)

-- Maelstrom text (on bar)
local maelstromText = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
maelstromText:SetPoint("LEFT", maelstromBar, "LEFT", 5, 0)
maelstromText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
maelstromText:SetText("0")

-- Maelstrom label (below bar)
-- local maelstromLabel = maelstromFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
-- maelstromLabel:SetPoint("TOP", maelstromBar, "BOTTOM", 0, -2)
-- maelstromLabel:SetText("Maelstrom")
-- maelstromLabel:SetTextColor(0.5, 0.8, 1, 1)

-- Maelstrom bar background
local maelstromBg = maelstromBar:CreateTexture(nil, "BACKGROUND")
maelstromBg:SetAllPoints(maelstromBar)
maelstromBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

-- Threshold lines for Maelstrom (60 and 90)
local threshold60 = maelstromBar:CreateTexture(nil, "OVERLAY")
threshold60:SetSize(2, 20)
threshold60:SetColorTexture(1, 1, 1, 0.5)

local threshold90 = maelstromBar:CreateTexture(nil, "OVERLAY")
threshold90:SetSize(2, 20)
threshold90:SetColorTexture(1, 1, 1, 0.5)

-- Threshold labels
local label60 = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label60:SetPoint("BOTTOM", threshold60, "TOP", 0, 1)
label60:SetText("60")
label60:SetTextColor(1, 1, 1, 0.6)
label60:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

local label90 = maelstromBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label90:SetPoint("BOTTOM", threshold90, "TOP", 0, 1)
label90:SetText("90")
label90:SetTextColor(1, 1, 1, 0.6)
label90:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

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
    if value >= 90 then
        maelstromBar:SetStatusBarColor(1, 0, 1, 1) -- Magenta (90+)
    elseif value >= 60 then
        maelstromBar:SetStatusBarColor(0, 1, 1, 1) -- Cyan (60+)
    else
        local r = 0.2 + (value / 100) * 0.3
        local g = 0.5 + (value / 100) * 0.5
        local b = 1.0
        maelstromBar:SetStatusBarColor(r, g, b, 1) -- Gradient blue (below 60)
    end
end

-- ========================================
-- UPDATE FUNCTIONS
-- ========================================

-- Throttle 변수
local lastHealthUpdate = 0
local HEALTH_UPDATE_THROTTLE = 0.15 -- 0.15초마다 한 번만 업데이트

-- Update Health
local function UpdateHealth()
    local current = UnitHealth("player")
    local max = UnitHealthMax("player")

    -- Nil check for safety during early initialization
    if not current or not max or max == 0 then
        DebugPrint("UpdateHealth: Invalid data - current:", current, "max:", max)
        return
    end

    -- Throttle 체크 (데이터 검증 후에 수행)
    local now = GetTime()
    if now - lastHealthUpdate < HEALTH_UPDATE_THROTTLE then
        return
    end
    lastHealthUpdate = now

    local percent = (current / max) * 100
    DebugPrint("UpdateHealth: HP =", current, "/", max, string.format("(%.1f%%)", percent))

    -- Update bar
    healthBar:SetMinMaxValues(0, max)
    healthBar:SetValue(current)
end

-- Update Maelstrom
local function UpdateMaelstrom()
    -- Check if player is Shaman
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        maelstromFrame:Hide()
        container:SetSize(180, 20) -- Smaller size without Maelstrom
        containerBg:SetSize(180, 20)
        containerBg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
        return
    end

    -- Check if Elemental spec (1=Elemental, 2=Enhancement, 3=Restoration)
    local spec = GetSpecialization()
    if not spec or spec ~= 1 then
        maelstromFrame:Hide()
        container:SetSize(180, 20) -- Smaller size without Maelstrom
        containerBg:SetSize(180, 20)
        containerBg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
        return
    end

    -- Show Maelstrom frame
    maelstromFrame:Show()
    container:SetSize(180, 45) -- Full size with Maelstrom
    containerBg:SetSize(180, 45)
    containerBg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)

    -- Get Maelstrom
    local current = UnitPower("player", Enum.PowerType.Maelstrom)
    local max = UnitPowerMax("player", Enum.PowerType.Maelstrom)

    -- Update display
    maelstromText:SetText(current)
    maelstromBar:SetValue(current)
    maelstromBar:SetMinMaxValues(0, max)
    UpdateMaelstromColor(current)

    -- Update threshold positions based on max value
    if max > 0 then
        threshold60:ClearAllPoints()
        threshold60:SetPoint("LEFT", maelstromBar, "LEFT", (180 * 60 / max), 0)

        threshold90:ClearAllPoints()
        threshold90:SetPoint("LEFT", maelstromBar, "LEFT", (180 * 90 / max), 0)
    end

    -- Keep text color white
    maelstromText:SetTextColor(1, 1, 1, 1)
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
container:RegisterEvent("PLAYER_ALIVE")
container:RegisterEvent("PLAYER_DEAD")
container:RegisterEvent("PLAYER_REGEN_DISABLED")  -- 전투 시작
container:RegisterEvent("PLAYER_REGEN_ENABLED")   -- 전투 종료
container:RegisterEvent("ADDON_LOADED")

container:SetScript("OnEvent", function(self, event, ...)
    DebugPrint("Event:", event, ...)

    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "CombinedTracker" then
            print("|cff00ff00[Combined Tracker]|r Loaded!")
            print("|cffffff00Use /ct move to unlock and drag the frame.|r")

            -- 저장된 디버그 설정 복원
            if CombinedTrackerDB.debugMode then
                DEBUG_MODE = true
                print("|cffffff00[Combined Tracker]|r Debug mode restored from saved settings")
            end
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Safe initialization point - all player data is ready
        DebugPrint("Initializing on PLAYER_ENTERING_WORLD")
        UpdateAll()
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ALIVE" then
        UpdateAll()
    elseif event == "PLAYER_DEAD" then
        UpdateAll()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        -- 전투 시작/종료 시 강제 업데이트 (throttle 무시)
        DebugPrint("Combat state changed, forcing update")
        lastHealthUpdate = 0
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
        print("|cffffff00[Combined Tracker]|r Frame UNLOCKED. Drag to move.")
    elseif command == "freeze" or command == "lock" then
        isLocked = true
        container:EnableMouse(false)
        dragText:SetText("")
        print("|cff00ff00[Combined Tracker]|r Frame LOCKED.")
    elseif command == "debug" then
        DEBUG_MODE = not DEBUG_MODE
        CombinedTrackerDB.debugMode = DEBUG_MODE
        if DEBUG_MODE then
            print("|cffffff00[Combined Tracker]|r Debug mode ENABLED")
            print("|cffffff00[Combined Tracker]|r Logs will be saved to: WTF\\Account\\[ACCOUNT]\\SavedVariables\\ResourceTracker.lua")
        else
            print("|cff00ff00[Combined Tracker]|r Debug mode DISABLED")
        end
    elseif command == "clearlog" then
        CombinedTrackerDB.debugLog = {}
        print("|cff00ff00[Combined Tracker]|r Debug log cleared.")
    elseif command == "test" then
        print("|cffffff00[Combined Tracker]|r Running test update...")
        lastHealthUpdate = 0  -- Reset throttle
        UpdateAll()
        print("|cff00ff00[Combined Tracker]|r Test complete.")
    else
        print("|cff00ff00[Combined Tracker]|r Commands:")
        print("  /ct move - Unlock frame (drag to move)")
        print("  /ct freeze - Lock frame (prevent moving)")
        print("  /ct show - Show frame")
        print("  /ct hide - Hide frame")
        print("  /ct reset - Reset position")
        print("  /ct debug - Toggle debug messages (saved to file)")
        print("  /ct clearlog - Clear debug log")
        print("  /ct test - Force update test")
    end
end

-- Initialize - removed unsafe top-level call
-- UpdateAll() will be called on PLAYER_ENTERING_WORLD event
