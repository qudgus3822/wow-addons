-- Resource Tracker for Elemental Shaman
-- Tracks Maelstrom resource

local addonName = "ResourceTracker"

-- Frame creation
local frame = CreateFrame("Frame", "MaelstromTrackerFrame", UIParent)
frame:SetSize(200, 80)
frame:SetPoint("CENTER", 0, -200)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Background
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(frame)
bg:SetColorTexture(0, 0, 0, 0.7)

-- Maelstrom text
local maelstromText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
maelstromText:SetPoint("CENTER", 0, 10)
maelstromText:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
maelstromText:SetText("0")

-- Label
local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
label:SetPoint("TOP", maelstromText, "BOTTOM", 0, -5)
label:SetText("Maelstrom")
label:SetTextColor(0.5, 0.8, 1, 1)

-- Progress bar
local progressBar = CreateFrame("StatusBar", nil, frame)
progressBar:SetSize(180, 20)
progressBar:SetPoint("BOTTOM", frame, "BOTTOM", 0, 10)
progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
progressBar:SetMinMaxValues(0, 100)
progressBar:SetValue(0)
progressBar:GetStatusBarTexture():SetHorizTile(false)

-- Progress bar background
local barBg = progressBar:CreateTexture(nil, "BACKGROUND")
barBg:SetAllPoints(progressBar)
barBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

-- Color gradient for progress bar (blue to bright blue)
local function UpdateBarColor(value)
    local r = 0.2 + (value / 100) * 0.3
    local g = 0.5 + (value / 100) * 0.5
    local b = 1.0
    progressBar:SetStatusBarColor(r, g, b, 1)
end

-- Update function
local function UpdateMaelstrom()
    -- Check if player is Elemental Shaman
    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        frame:Hide()
        return
    end

    -- Get specialization (1=Elemental, 2=Enhancement, 3=Restoration)
    local spec = GetSpecialization()
    if spec ~= 1 then
        frame:Hide()
        return
    end

    frame:Show()

    -- Get Maelstrom (PowerType 11)
    local current = UnitPower("player", Enum.PowerType.Maelstrom)
    local max = UnitPowerMax("player", Enum.PowerType.Maelstrom)

    -- Update display
    maelstromText:SetText(current)
    progressBar:SetValue(current)
    progressBar:SetMinMaxValues(0, max)
    UpdateBarColor(current)

    -- Change text color based on amount
    if current >= 60 then
        maelstromText:SetTextColor(0, 1, 1, 1)       -- Cyan (ready for big spell)
    elseif current >= 30 then
        maelstromText:SetTextColor(0.5, 0.8, 1, 1)   -- Light blue
    else
        maelstromText:SetTextColor(0.3, 0.5, 0.7, 1) -- Dark blue (low)
    end
end

-- Event handler
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_POWER_FREQUENT")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            print("|cff00ff00[" .. addonName .. "]|r Loaded! Tracking Maelstrom.")
            print("|cffffff00Drag the frame to move it.|r")
            UpdateMaelstrom()
        end
    elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" then
        local unit, powerType = ...
        if unit == "player" and powerType == "MAELSTROM" then
            UpdateMaelstrom()
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        UpdateMaelstrom()
    end
end)

-- Slash commands
SLASH_RESOURCETRACKER1 = "/rt"
SLASH_RESOURCETRACKER2 = "/maelstrom"
SlashCmdList["RESOURCETRACKER"] = function(msg)
    local command = msg:lower()

    if command == "show" then
        frame:Show()
        print("|cff00ff00[" .. addonName .. "]|r Frame shown.")
    elseif command == "hide" then
        frame:Hide()
        print("|cff00ff00[" .. addonName .. "]|r Frame hidden.")
    elseif command == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", 0, -200)
        print("|cff00ff00[" .. addonName .. "]|r Position reset.")
    else
        print("|cff00ff00[" .. addonName .. "]|r Commands:")
        print("  /rt show - Show frame")
        print("  /rt hide - Hide frame")
        print("  /rt reset - Reset position")
    end
end

-- Initialize
UpdateMaelstrom()
