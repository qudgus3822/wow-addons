-- 상수 정의
local ADDON_NAME = "SkillBar"
local NUM_BUTTONS = 6
local FRAME_WIDTH = 400
local FRAME_HEIGHT = 50
local BUTTON_SIZE = 40
local BUTTON_SPACING = 50
local BUTTON_PADDING = 10
local UPDATE_INTERVAL = 0.1

-- 데이터베이스 초기화
SkillBarDB = SkillBarDB or {
    buttonSpells = {},
    framePosition = nil
}

-- 프레임 생성
local mainFrame = CreateFrame("Frame", "SkillBarFrame", UIParent)
mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- 프레임 위치 저장
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    SkillBarDB.framePosition = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs
    }
end)

-- 배경
local bg = mainFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(true)
bg:SetColorTexture(0, 0, 0, 0.5)

-- 스킬 버튼을 저장할 테이블
local buttons = {}

-- 스킬 버튼 생성 함수
local function CreateSkillButton(index)
    local button = CreateFrame("Button", "SkillBarButton" .. index, mainFrame, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetPoint("LEFT", mainFrame, "LEFT", BUTTON_PADDING + (index - 1) * BUTTON_SPACING, 0)

    -- 아이콘 텍스처
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(true)
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    -- 테두리
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetAllPoints(true)
    button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.border:SetBlendMode("ADD")

    -- 쿨타임 텍스트
    button.cooldownText = button:CreateFontString(nil, "OVERLAY")
    button.cooldownText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    button.cooldownText:SetPoint("CENTER", 0, 0)
    button.cooldownText:SetTextColor(1, 1, 0)

    -- 쿨타임 스와이프 애니메이션
    button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetDrawEdge(false)

    -- 스킬 ID 저장 변수
    button.spellID = nil

    -- 툴팁 설정
    button:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return button
end

-- 버튼 생성
for i = 1, NUM_BUTTONS do
    buttons[i] = CreateSkillButton(i)
end

-- 쿨타임 업데이트 함수
local function UpdateCooldowns()
    for i, button in ipairs(buttons) do
        if button.spellID then
            -- 안전하게 쿨다운 정보 가져오기
            local cooldownInfo = C_Spell.GetSpellCooldown(button.spellID)

            if cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration then
                if cooldownInfo.startTime > 0 and cooldownInfo.duration > 0 then
                    local remaining = cooldownInfo.duration - (GetTime() - cooldownInfo.startTime)

                    if remaining > 0 then
                        -- 쿨타임 텍스트 표시
                        if remaining > 60 then
                            button.cooldownText:SetText(string.format("%.1fm", remaining / 60))
                        else
                            button.cooldownText:SetText(string.format("%.0f", remaining))
                        end
                        button.cooldownText:Show()

                        -- 쿨타임 스와이프 애니메이션
                        button.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
                    else
                        button.cooldownText:Hide()
                    end
                else
                    button.cooldownText:Hide()
                end
            else
                button.cooldownText:Hide()
            end

            -- 스킬 사용 가능 여부 확인
            local usable = C_Spell.IsSpellUsable(button.spellID)
            if usable then
                button.icon:SetDesaturated(false)
                button.icon:SetAlpha(1.0)
            else
                button.icon:SetDesaturated(true)
                button.icon:SetAlpha(0.5)
            end
        end
    end
end

-- 스킬 설정 함수 (채팅 명령어로 사용)
local function SetButtonSpell(buttonIndex, spellID)
    -- 전투 중인지 확인
    if InCombatLockdown() then
        print("|cffff0000[SkillBar]|r 전투 중에는 스킬을 설정할 수 없습니다.")
        return false
    end

    if not buttons[buttonIndex] then
        print("|cffff0000[SkillBar]|r 잘못된 버튼 번호입니다. (1-" .. NUM_BUTTONS .. ")")
        return false
    end

    -- 스킬 정보 확인
    local spellName = C_Spell.GetSpellName(spellID)
    if not spellName then
        print("|cffff0000[SkillBar]|r 잘못된 스킬 ID입니다: " .. spellID)
        return false
    end

    buttons[buttonIndex].spellID = spellID

    -- 스킬 아이콘 설정
    local spellTexture = C_Spell.GetSpellTexture(spellID)
    if spellTexture then
        buttons[buttonIndex].icon:SetTexture(spellTexture)
    else
        buttons[buttonIndex].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- 클릭 시 스킬 사용 설정
    buttons[buttonIndex]:SetAttribute("type", "spell")
    buttons[buttonIndex]:SetAttribute("spell", spellID)

    -- 데이터베이스에 저장
    SkillBarDB.buttonSpells[buttonIndex] = spellID

    print("|cff00ff00[SkillBar]|r 버튼 " .. buttonIndex .. "에 '" .. spellName .. "' (ID: " .. spellID .. ") 설정됨")
    return true
end

-- 스킬 제거 함수
local function ClearButtonSpell(buttonIndex)
    if InCombatLockdown() then
        print("|cffff0000[SkillBar]|r 전투 중에는 스킬을 제거할 수 없습니다.")
        return false
    end

    if not buttons[buttonIndex] then
        print("|cffff0000[SkillBar]|r 잘못된 버튼 번호입니다. (1-" .. NUM_BUTTONS .. ")")
        return false
    end

    buttons[buttonIndex].spellID = nil
    buttons[buttonIndex].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    buttons[buttonIndex]:SetAttribute("type", nil)
    buttons[buttonIndex]:SetAttribute("spell", nil)

    -- 데이터베이스에서 제거
    SkillBarDB.buttonSpells[buttonIndex] = nil

    print("|cff00ff00[SkillBar]|r 버튼 " .. buttonIndex .. " 초기화됨")
    return true
end

-- 저장된 설정 불러오기
local function LoadSettings()
    -- 프레임 위치 복원
    if SkillBarDB.framePosition and SkillBarDB.framePosition.point and
       SkillBarDB.framePosition.relativePoint and SkillBarDB.framePosition.xOfs and
       SkillBarDB.framePosition.yOfs then
        local pos = SkillBarDB.framePosition
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    end

    -- 버튼 스킬 복원
    for buttonIndex, spellID in pairs(SkillBarDB.buttonSpells) do
        if buttons[buttonIndex] and spellID then
            buttons[buttonIndex].spellID = spellID

            local spellTexture = C_Spell.GetSpellTexture(spellID)
            if spellTexture then
                buttons[buttonIndex].icon:SetTexture(spellTexture)
            end

            buttons[buttonIndex]:SetAttribute("type", "spell")
            buttons[buttonIndex]:SetAttribute("spell", spellID)
        end
    end
end

-- 프레임 업데이트
local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed

    if self.timeSinceLastUpdate >= UPDATE_INTERVAL then
        UpdateCooldowns()
        self.timeSinceLastUpdate = 0
    end
end)

-- 애드온 로드 이벤트
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON_NAME then
        -- 데이터베이스 초기화
        SkillBarDB = SkillBarDB or {
            buttonSpells = {},
            framePosition = nil
        }
    elseif event == "PLAYER_LOGIN" then
        -- 설정 불러오기
        LoadSettings()
        print("|cff00ff00[SkillBar]|r 로드됨! /skb 명령어로 설정하세요")
    end
end)

-- 슬래시 명령어
SLASH_SKILLBAR1 = "/skb"
SLASH_SKILLBAR2 = "/skillbar"
SlashCmdList["SKILLBAR"] = function(msg)
    local command, arg1, arg2 = strsplit(" ", msg)

    if command == "set" then
        local buttonIndex = tonumber(arg1)
        local spellID = tonumber(arg2)

        if buttonIndex and spellID then
            SetButtonSpell(buttonIndex, spellID)
        else
            print("|cffff0000[SkillBar]|r 사용법: /skb set [버튼번호] [스킬ID]")
        end
    elseif command == "clear" then
        local buttonIndex = tonumber(arg1)

        if buttonIndex then
            ClearButtonSpell(buttonIndex)
        else
            print("|cffff0000[SkillBar]|r 사용법: /skb clear [버튼번호]")
        end
    elseif command == "show" then
        mainFrame:Show()
        print("|cff00ff00[SkillBar]|r 바 표시")
    elseif command == "hide" then
        mainFrame:Hide()
        print("|cff00ff00[SkillBar]|r 바 숨김")
    elseif command == "reset" then
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
        SkillBarDB.framePosition = nil
        print("|cff00ff00[SkillBar]|r 위치 초기화됨")
    elseif command == "list" then
        print("|cff00ff00[SkillBar]|r 현재 설정된 스킬:")
        for i = 1, NUM_BUTTONS do
            if buttons[i].spellID then
                local spellName = C_Spell.GetSpellName(buttons[i].spellID)
                print("  버튼 " .. i .. ": " .. (spellName or "알 수 없음") .. " (ID: " .. buttons[i].spellID .. ")")
            else
                print("  버튼 " .. i .. ": 없음")
            end
        end
    else
        print("|cff00ff00[SkillBar]|r 명령어:")
        print("  /skb set [버튼번호] [스킬ID] - 버튼에 스킬 설정")
        print("  /skb clear [버튼번호] - 버튼 스킬 제거")
        print("  /skb list - 현재 설정된 스킬 목록")
        print("  /skb show - 바 표시")
        print("  /skb hide - 바 숨김")
        print("  /skb reset - 위치 초기화")
        print("예: /skb set 1 100 (버튼1에 스킬ID 100 설정)")
    end
end
