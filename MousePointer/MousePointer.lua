-- Mouse Pointer Tracker
-- Shows a circle indicator at the mouse cursor position

local ADDON_NAME = "MousePointer"

-- Create the main frame
local frame = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent)
frame:SetSize(1, 1)
frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)

-- Create the circle indicator
local circle = CreateFrame("Frame", ADDON_NAME .. "Circle", UIParent)
circle:SetSize(40, 40)
circle:SetFrameStrata("TOOLTIP")
circle:SetFrameLevel(10000)

-- Create circle texture (outer ring)
local outerRing = circle:CreateTexture(nil, "OVERLAY")
outerRing:SetAllPoints()
outerRing:SetTexture("Interface\\AddOns\\MousePointer\\circle")
outerRing:SetVertexColor(1, 1, 0, 0.8)  -- Yellow with transparency

-- If custom texture doesn't exist, create a simple circle using multiple textures
if not outerRing:GetTexture() then
    -- Create a circle using the built-in ring texture
    outerRing:SetTexture("Interface\\Minimap\\Minimap-TrackingBorder")
    outerRing:SetVertexColor(1, 1, 0, 0.9)
end

-- Create inner circle for better visibility
local innerCircle = circle:CreateTexture(nil, "OVERLAY")
innerCircle:SetPoint("CENTER")
innerCircle:SetSize(30, 30)
innerCircle:SetTexture("Interface\\Minimap\\Minimap-TrackingBorder")
innerCircle:SetVertexColor(1, 0.8, 0, 0.6)  -- Slightly darker yellow

-- Create center dot
local centerDot = circle:CreateTexture(nil, "OVERLAY")
centerDot:SetPoint("CENTER")
centerDot:SetSize(4, 4)
centerDot:SetTexture("Interface\\Buttons\\WHITE8X8")
centerDot:SetVertexColor(1, 0, 0, 1)  -- Red center dot

-- Animation for pulsing effect
-- local animGroup = circle:CreateAnimationGroup()
-- local scaleAnim = animGroup:CreateAnimation("Scale")
-- scaleAnim:SetScale(1.3, 1.3)
-- scaleAnim:SetDuration(0.5)
-- scaleAnim:SetSmoothing("IN_OUT")

-- local alphaAnim = animGroup:CreateAnimation("Alpha")
-- alphaAnim:SetFromAlpha(1)
-- alphaAnim:SetToAlpha(0.3)
-- alphaAnim:SetDuration(0.5)
-- alphaAnim:SetSmoothing("IN_OUT")

-- animGroup:SetLooping("BOUNCE")
-- animGroup:Play()

-- Variables for tracking
local isVisible = true
local updateThrottle = 0
local THROTTLE_INTERVAL = 0.01  -- Update every 0.01 seconds (100 fps)

-- Function to update circle position
local function UpdateCirclePosition()
    local scale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale

    -- circle:ClearAllPoints()
    circle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

-- Main update function
frame:SetScript("OnUpdate", function(_, elapsed)
    if not isVisible then return end

    updateThrottle = updateThrottle + elapsed
    if updateThrottle >= THROTTLE_INTERVAL then
        UpdateCirclePosition()
        updateThrottle = 0
    end
end)

-- Handle mouse button events to keep tracking during right-click
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        print("|cFF00FF00" .. ADDON_NAME .. "|r: Mouse pointer tracker loaded! Type /mp to toggle on/off")
    end
end)

-- Slash command to toggle visibility
SLASH_MOUSEPOINTER1 = "/mp"
SLASH_MOUSEPOINTER2 = "/mousepointer"
SlashCmdList["MOUSEPOINTER"] = function(msg)
    isVisible = not isVisible
    if isVisible then
        circle:Show()
        -- animGroup:Play()
        print("|cFF00FF00" .. ADDON_NAME .. "|r: Mouse pointer tracker |cFF00FF00enabled|r")
    else
        circle:Hide()
        -- animGroup:Stop()
        print("|cFF00FF00" .. ADDON_NAME .. "|r: Mouse pointer tracker |cFFFF0000disabled|r")
    end
end

-- Options frame
local optionsFrame = CreateFrame("Frame", ADDON_NAME .. "Options", InterfaceOptionsFramePanelContainer)
optionsFrame.name = "Mouse Pointer Tracker"

local title = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Mouse Pointer Tracker")

local desc = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetText("Shows a circle indicator at your mouse cursor position.")

-- Toggle checkbox
local toggleCheckbox = CreateFrame("CheckButton", ADDON_NAME .. "ToggleCheckbox", optionsFrame, "InterfaceOptionsCheckButtonTemplate")
toggleCheckbox:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
toggleCheckbox.Text:SetText("Enable Mouse Pointer Tracker")
toggleCheckbox:SetChecked(isVisible)
toggleCheckbox:SetScript("OnClick", function(self)
    isVisible = self:GetChecked()
    if isVisible then
        circle:Show()
        -- animGroup:Play()
    else
        circle:Hide()
        -- animGroup:Stop()
    end
end)

-- Size slider
local sizeSlider = CreateFrame("Slider", ADDON_NAME .. "SizeSlider", optionsFrame, "OptionsSliderTemplate")
sizeSlider:SetPoint("TOPLEFT", toggleCheckbox, "BOTTOMLEFT", 16, -32)
sizeSlider:SetMinMaxValues(20, 80)
sizeSlider:SetValue(40)
sizeSlider:SetValueStep(5)
sizeSlider:SetObeyStepOnDrag(true)
getglobal(sizeSlider:GetName() .. 'Low'):SetText('20')
getglobal(sizeSlider:GetName() .. 'High'):SetText('80')
getglobal(sizeSlider:GetName() .. 'Text'):SetText('Circle Size: 40')

sizeSlider:SetScript("OnValueChanged", function(self, value)
    getglobal(self:GetName() .. 'Text'):SetText('Circle Size: ' .. value)
    circle:SetSize(value, value)
    innerCircle:SetSize(value * 0.75, value * 0.75)
end)

-- Register options panel
if Settings and Settings.RegisterCanvasLayoutCategory then
    -- Dragonflight/Retail API
    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsFrame, optionsFrame.name)
    Settings.RegisterAddOnCategory(category)
else
    -- Classic/TBC/Wrath API
    InterfaceOptions_AddCategory(optionsFrame)
end

-- Initial position update
UpdateCirclePosition()
