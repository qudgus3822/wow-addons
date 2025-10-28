-- Resource Tracker
-- Tracks class-specific resources (Maelstrom for Elemental Shaman)

-- Locked state
local isLocked = true

-- Initialize SavedVariables
ResourceTrackerDB = ResourceTrackerDB or {
    debugMode = false,
    debugLog = {}
}

-- Debug mode
local DEBUG_MODE = false

local function DebugPrint(...)
    if not DEBUG_MODE then
        return
    end

    local msg = strjoin(" ", tostringall(...))
    print("|cffaaaaaa[RT Debug]|r", msg)

    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local logEntry = string.format("[%s] %s", timestamp, msg)
    table.insert(ResourceTrackerDB.debugLog, logEntry)
end

-- Create main container frame
local container = CreateFrame("Frame", "ResourceTrackerFrame", UIParent)
container:SetSize(180, 20)
container:SetPoint("CENTER", 0, -150)
container:SetMovable(true)
container:EnableMouse(false)
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
-- RESOURCE BAR
-- ========================================

-- Resource progress bar
local resourceBar = CreateFrame("StatusBar", nil, container)
resourceBar:SetSize(180, 20)
resourceBar:SetPoint("CENTER", container, "CENTER", 0, 0)
resourceBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
resourceBar:SetMinMaxValues(0, 100)
resourceBar:SetValue(0)
resourceBar:GetStatusBarTexture():SetHorizTile(false)

-- Resource text (on bar)
local resourceText = resourceBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
resourceText:SetPoint("LEFT", resourceBar, "LEFT", 5, 0)
resourceText:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
resourceText:SetText("0")
resourceText:SetTextColor(1, 1, 1, 1)

-- Resource bar background
local resourceBg = resourceBar:CreateTexture(nil, "BACKGROUND")
resourceBg:SetAllPoints(resourceBar)
resourceBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

-- Threshold lines (will be positioned dynamically)
local threshold1 = resourceBar:CreateTexture(nil, "OVERLAY")
threshold1:SetSize(2, 20)
threshold1:SetColorTexture(1, 1, 1, 0.5)

local threshold2 = resourceBar:CreateTexture(nil, "OVERLAY")
threshold2:SetSize(2, 20)
threshold2:SetColorTexture(1, 1, 1, 0.5)

-- Threshold labels
local label1 = resourceBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label1:SetPoint("BOTTOM", threshold1, "TOP", 0, 1)
label1:SetTextColor(1, 1, 1, 0.6)
label1:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

local label2 = resourceBar:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
label2:SetPoint("BOTTOM", threshold2, "TOP", 0, 1)
label2:SetTextColor(1, 1, 1, 0.6)
label2:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Update resource bar color based on class and value
local function UpdateResourceColor(class, spec, value, max)
    if class == "SHAMAN" and spec == 1 then
        -- Elemental Shaman: Maelstrom (0-100)
        if value >= 90 then
            resourceBar:SetStatusBarColor(1, 0, 1, 1) -- Magenta (90+)
        elseif value >= 60 then
            resourceBar:SetStatusBarColor(0, 1, 1, 1) -- Cyan (60+)
        else
            local r = 0.2 + (value / 100) * 0.3
            local g = 0.5 + (value / 100) * 0.5
            local b = 1.0
            resourceBar:SetStatusBarColor(r, g, b, 1) -- Gradient blue
        end
    elseif class == "WARLOCK" and spec == 3 then
        -- Destruction Warlock: Soul Shards (0-5)
        if value >= 4 then
            resourceBar:SetStatusBarColor(0.8, 0, 1, 1)   -- Purple (4-5)
        elseif value >= 2 then
            resourceBar:SetStatusBarColor(0.5, 0, 0.8, 1) -- Dark purple (2-3)
        else
            resourceBar:SetStatusBarColor(0.3, 0, 0.5, 1) -- Very dark purple (0-1)
        end
    else
        -- Default color
        resourceBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
    end
end

-- ========================================
-- UPDATE FUNCTIONS
-- ========================================

-- Update Resource
local function UpdateResource()
    local _, class = UnitClass("player")
    local spec = GetSpecialization()

    if not class or not spec then
        container:Hide()
        return
    end

    local current, max, powerType, threshold1Val, threshold2Val

    -- Determine power type and thresholds based on class and spec
    if class == "SHAMAN" and spec == 1 then
        -- Elemental Shaman: Maelstrom (0-100)
        powerType = Enum.PowerType.Maelstrom
        threshold1Val = 60
        threshold2Val = 90
    elseif class == "WARLOCK" and spec == 3 then
        -- Destruction Warlock: Soul Shards (0-5)
        powerType = Enum.PowerType.SoulShards
        threshold1Val = 2
        threshold2Val = 4
    else
        -- Unsupported class/spec
        container:Hide()
        return
    end

    -- Show container
    container:Show()

    -- Get resource values
    current = UnitPower("player", powerType)
    max = UnitPowerMax("player", powerType)

    if not current or not max or max == 0 then
        DebugPrint("UpdateResource: Invalid data - current:", current, "max:", max)
        return
    end

    -- Update display
    resourceText:SetText(tostring(current))
    resourceBar:SetValue(current)
    resourceBar:SetMinMaxValues(0, max)
    UpdateResourceColor(class, spec, current, max)

    -- Update threshold positions
    threshold1:ClearAllPoints()
    threshold1:SetPoint("LEFT", resourceBar, "LEFT", (180 * threshold1Val / max), 0)
    label1:SetText(tostring(threshold1Val))

    threshold2:ClearAllPoints()
    threshold2:SetPoint("LEFT", resourceBar, "LEFT", (180 * threshold2Val / max), 0)
    label2:SetText(tostring(threshold2Val))

    DebugPrint("UpdateResource:", class, spec, "=", current, "/", max)
end

-- ========================================
-- EVENT HANDLER
-- ========================================

container:RegisterEvent("UNIT_POWER_UPDATE")
container:RegisterEvent("UNIT_POWER_FREQUENT")
container:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
container:RegisterEvent("PLAYER_ENTERING_WORLD")
container:RegisterEvent("ADDON_LOADED")

container:SetScript("OnEvent", function(_, event, ...)
    DebugPrint("Event:", event, ...)

    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == "ResourceTracker" then
            print("|cff00ff00[Resource Tracker]|r Loaded!")
            print("|cffffff00Use /rt move to unlock and drag the frame.|r")

            -- Restore debug settings
            if ResourceTrackerDB.debugMode then
                DEBUG_MODE = true
                print("|cffffff00[Resource Tracker]|r Debug mode restored")
            end
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
        local unit = ...
        if unit == "player" then
            UpdateResource()
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        UpdateResource()
    end
end)

-- ========================================
-- SLASH COMMANDS
-- ========================================

SLASH_RESOURCETRACKER1 = "/rt"
SLASH_RESOURCETRACKER2 = "/rtracker"
SlashCmdList["RESOURCETRACKER"] = function(msg)
    local command = msg:lower()

    if command == "show" then
        container:Show()
        print("|cff00ff00[Resource Tracker]|r Frame shown.")
    elseif command == "hide" then
        container:Hide()
        print("|cff00ff00[Resource Tracker]|r Frame hidden.")
    elseif command == "reset" then
        container:ClearAllPoints()
        container:SetPoint("CENTER", 0, -150)
        print("|cff00ff00[Resource Tracker]|r Position reset.")
    elseif command == "move" or command == "unlock" then
        isLocked = false
        container:EnableMouse(true)
        dragText:SetText("🔓 Drag to move")
        containerBg:SetColorTexture(0.2, 0.2, 0, 0.8)
        print("|cffffff00[Resource Tracker]|r Frame UNLOCKED. Drag to move.")
    elseif command == "freeze" or command == "lock" then
        isLocked = true
        container:EnableMouse(false)
        dragText:SetText("")
        containerBg:SetColorTexture(0, 0, 0, 0.7)
        print("|cff00ff00[Resource Tracker]|r Frame LOCKED.")
    elseif command == "debug" then
        DEBUG_MODE = not DEBUG_MODE
        ResourceTrackerDB.debugMode = DEBUG_MODE
        if DEBUG_MODE then
            print("|cffffff00[Resource Tracker]|r Debug mode ENABLED")
        else
            print("|cff00ff00[Resource Tracker]|r Debug mode DISABLED")
        end
    elseif command == "clearlog" then
        ResourceTrackerDB.debugLog = {}
        print("|cff00ff00[Resource Tracker]|r Debug log cleared.")
    elseif command == "test" then
        print("|cffffff00[Resource Tracker]|r Running test update...")
        UpdateResource()
        print("|cff00ff00[Resource Tracker]|r Test complete.")
    else
        print("|cff00ff00[Resource Tracker]|r Commands:")
        print("  /rt move - Unlock frame (drag to move)")
        print("  /rt freeze - Lock frame (prevent moving)")
        print("  /rt show - Show frame")
        print("  /rt hide - Hide frame")
        print("  /rt reset - Reset position")
        print("  /rt debug - Toggle debug mode")
        print("  /rt clearlog - Clear debug log")
        print("  /rt test - Force update test")
    end
end
