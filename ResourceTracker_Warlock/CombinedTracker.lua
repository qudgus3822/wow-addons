-- Combined Resource and Health Tracker (Warlock Version)
-- Shows Health and Soul Shards in one movable frame

local addonName = "CombinedTracker_Warlock"

-- Locked state
local isLocked = true

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

-- ========================================
-- SOUL SHARDS BAR (for Warlocks)
-- ========================================

-- Soul Shards frame
local shardsFrame = CreateFrame("Frame", nil, container)
shardsFrame:SetSize(180, 20)
shardsFrame:SetPoint("TOP", healthBar, "BOTTOM", 0, -5)

-- Create individual shard boxes (5 shards total, each can hold 10 fragments)
local MAX_SHARDS = 5
local FRAGMENTS_PER_SHARD = 10
local SHARD_WIDTH = 34  -- (180 - 4*2) / 5 = 34.4, using 34 with gaps
local SHARD_GAP = 2
local shardBoxes = {}

for i = 1, MAX_SHARDS do
    -- Create container for each shard
    local box = CreateFrame("Frame", nil, shardsFrame)
    box:SetSize(SHARD_WIDTH, 20)

    if i == 1 then
        box:SetPoint("LEFT", shardsFrame, "LEFT", 0, 0)
    else
        box:SetPoint("LEFT", shardBoxes[i-1], "RIGHT", SHARD_GAP, 0)
    end

    -- Background (dark)
    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(box)
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Foreground (purple when filled) - StatusBar for partial fill
    local fg = CreateFrame("StatusBar", nil, box)
    fg:SetAllPoints(box)
    fg:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    fg:SetStatusBarColor(0.6, 0, 0.9, 1)
    fg:SetMinMaxValues(0, FRAGMENTS_PER_SHARD)
    fg:SetValue(0)
    fg:GetStatusBarTexture():SetHorizTile(false)
    fg:SetOrientation("HORIZONTAL")

    -- Border
    local border = box:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints(box)
    border:SetColorTexture(0.5, 0.5, 0.5, 0.3)

    -- Store references
    box.bg = bg
    box.fg = fg
    box.border = border

    shardBoxes[i] = box
end

-- Soul Shards text (shows fragment count)
local shardsText = shardsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
shardsText:SetPoint("CENTER", shardsFrame, "CENTER", 0, 0)
shardsText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
shardsText:SetText("0")
shardsText:SetTextColor(1, 1, 1, 1)

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

-- Update Soul Shards boxes (each box represents 1 shard = 10 fragments)
local function UpdateShardsBoxes(fragments)
    for i = 1, MAX_SHARDS do
        local shardStartFragment = (i - 1) * FRAGMENTS_PER_SHARD
        local shardEndFragment = i * FRAGMENTS_PER_SHARD
        local fragmentsInThisShard = math.max(0, math.min(FRAGMENTS_PER_SHARD, fragments - shardStartFragment))

        -- Update the fill level of this shard
        shardBoxes[i].fg:SetValue(fragmentsInThisShard)

        -- Color based on total fragments
        if fragments >= 40 then
            shardBoxes[i].fg:SetStatusBarColor(0.8, 0, 1, 1) -- Bright purple (40-50)
        elseif fragments >= 20 then
            shardBoxes[i].fg:SetStatusBarColor(0.6, 0, 0.9, 1) -- Medium purple (20-39)
        else
            shardBoxes[i].fg:SetStatusBarColor(0.4, 0, 0.6, 1) -- Dark purple (0-19)
        end
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

-- Update Soul Shards
local function UpdateSoulShards()
    -- Check if player is Warlock
    local _, class = UnitClass("player")
    if class ~= "WARLOCK" then
        shardsFrame:Hide()
        container:SetSize(180, 20) -- Smaller size without Soul Shards
        containerBg:SetSize(180, 20)
        containerBg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)
        return
    end

    -- Show Soul Shards frame
    shardsFrame:Show()
    container:SetSize(180, 45) -- Full size with Soul Shards
    containerBg:SetSize(180, 45)
    containerBg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", 0, 0)

    -- Get Soul Shard Fragments (0-50)
    local fragments = UnitPower("player", Enum.PowerType.SoulShards)
    local max = UnitPowerMax("player", Enum.PowerType.SoulShards)

    DebugPrint("UpdateSoulShards: Fragments =", fragments, "/", max)

    -- Update display
    shardsText:SetText(tostring(fragments))
    UpdateShardsBoxes(fragments)

    -- Keep text color white
    shardsText:SetTextColor(1, 1, 1, 1)
end

-- Update all
local function UpdateAll()
    UpdateHealth()
    UpdateSoulShards()
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
        if loadedAddon == "ResourceTracker_Warlock" then
            print("|cff9900ff[Combined Tracker - Warlock]|r Loaded!")
            print("|cffffff00Use /ct move to unlock and drag the frame.|r")

            -- 저장된 디버그 설정 복원
            if CombinedTrackerDB.debugMode then
                DEBUG_MODE = true
                print("|cffffff00[Combined Tracker - Warlock]|r Debug mode restored from saved settings")
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
            UpdateSoulShards()
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
        print("|cff9900ff[Combined Tracker - Warlock]|r Frame shown.")
    elseif command == "hide" then
        container:Hide()
        print("|cff9900ff[Combined Tracker - Warlock]|r Frame hidden.")
    elseif command == "reset" then
        container:ClearAllPoints()
        container:SetPoint("CENTER", 0, -100)
        print("|cff9900ff[Combined Tracker - Warlock]|r Position reset.")
    elseif command == "move" or command == "unlock" then
        isLocked = false
        container:EnableMouse(true)
        dragText:SetText("🔓 Drag to move")
        print("|cffffff00[Combined Tracker - Warlock]|r Frame UNLOCKED. Drag to move.")
    elseif command == "freeze" or command == "lock" then
        isLocked = true
        container:EnableMouse(false)
        dragText:SetText("")
        print("|cff9900ff[Combined Tracker - Warlock]|r Frame LOCKED.")
    elseif command == "debug" then
        DEBUG_MODE = not DEBUG_MODE
        CombinedTrackerDB.debugMode = DEBUG_MODE
        if DEBUG_MODE then
            print("|cffffff00[Combined Tracker - Warlock]|r Debug mode ENABLED")
            print("|cffffff00[Combined Tracker - Warlock]|r Logs will be saved to: WTF\\Account\\[ACCOUNT]\\SavedVariables\\ResourceTracker_Warlock.lua")
        else
            print("|cff9900ff[Combined Tracker - Warlock]|r Debug mode DISABLED")
        end
    elseif command == "clearlog" then
        CombinedTrackerDB.debugLog = {}
        print("|cff9900ff[Combined Tracker - Warlock]|r Debug log cleared.")
    elseif command == "test" then
        print("|cffffff00[Combined Tracker - Warlock]|r Running test update...")
        lastHealthUpdate = 0  -- Reset throttle
        UpdateAll()
        print("|cff9900ff[Combined Tracker - Warlock]|r Test complete.")
    else
        print("|cff9900ff[Combined Tracker - Warlock]|r Commands:")
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
