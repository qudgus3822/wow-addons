-- FindHighestSecondStat Addon
-- 플레이어의 2차 스텟 중 가장 높은 값을 찾아 출력

local addonName = "FindSecondStat"

-- 2차 스텟 ID 정의 (Combat Rating IDs)
local SECONDARY_STATS = {
    CRIT = 9,        -- CR_CRIT_MELEE (치명타, 통합됨)
    HASTE = 18,      -- CR_HASTE_MELEE (가속, 통합됨)
    MASTERY = 26,    -- CR_MASTERY (특화)
    VERSATILITY = 29 -- CR_VERSATILITY_DAMAGE_DONE (유연성)
}

-- 프레임 생성
local frame = CreateFrame("Frame")

-- 툴팁 스캐닝용 숨겨진 프레임 생성
local scanTooltip = CreateFrame("GameTooltip", "FindStatScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- 검사된 파티원 스탯 저장소
local inspectedStats = {}

-- 아이템 스탯 키 매핑
local ITEM_STAT_KEYS = {
    CRIT = "ITEM_MOD_CRIT_RATING_SHORT",
    HASTE = "ITEM_MOD_HASTE_RATING_SHORT",
    MASTERY = "ITEM_MOD_MASTERY_RATING_SHORT",
    VERSATILITY = "ITEM_MOD_VERSATILITY"
}

-- 스탯별 재밌는 문구
local STAT_MESSAGES = {
    CRIT = "한방을 쎄게 때려요! 💥",
    HASTE = "손이 번개같아요! ⚡",
    MASTERY = "전문가에요! 🎯",
    VERSATILITY = "다리를 일자로 찢어요 🌟"
}

-- 툴팁에서 찾을 스탯 패턴 (한글/영문)
local STAT_PATTERNS = {
    CRIT = {
        "치명타 %+?(%d+)",
        "치명타 적중 %+?(%d+)",
        "Critical Strike %+?(%d+)",
        "Crit %+?(%d+)"
    },
    HASTE = {
        "가속 %+?(%d+)",
        "Haste %+?(%d+)"
    },
    MASTERY = {
        "특화 %+?(%d+)",
        "Mastery %+?(%d+)"
    },
    VERSATILITY = {
        "유연성 %+?(%d+)",
        "Versatility %+?(%d+)"
    }
}

-- 툴팁에서 스탯 추출 (인챈트, 보석 포함)
local function GetStatsFromTooltip(itemLink)
    local stats = {
        CRIT = 0,
        HASTE = 0,
        MASTERY = 0,
        VERSATILITY = 0
    }

    if not itemLink then
        return stats
    end

    -- 툴팁 초기화
    scanTooltip:ClearLines()
    scanTooltip:SetHyperlink(itemLink)

    -- 툴팁의 모든 텍스트 라인 스캔
    for i = 1, scanTooltip:NumLines() do
        local leftText = _G["FindStatScanTooltipTextLeft" .. i]
        local rightText = _G["FindStatScanTooltipTextRight" .. i]

        if leftText then
            local text = leftText:GetText()
            if text then
                -- 각 스탯 패턴으로 매칭 시도
                for statName, patterns in pairs(STAT_PATTERNS) do
                    for _, pattern in ipairs(patterns) do
                        local value = text:match(pattern)
                        if value then
                            stats[statName] = stats[statName] + tonumber(value)
                            break
                        end
                    end
                end
            end
        end

        if rightText then
            local text = rightText:GetText()
            if text then
                -- 오른쪽 텍스트도 체크
                for statName, patterns in pairs(STAT_PATTERNS) do
                    for _, pattern in ipairs(patterns) do
                        local value = text:match(pattern)
                        if value then
                            stats[statName] = stats[statName] + tonumber(value)
                            break
                        end
                    end
                end
            end
        end
    end

    return stats
end

-- 장비에서 2차 스탯 추출 (기본 스탯 + 툴팁 파싱)
local function GetStatsFromEquipment(unit)
    local stats = {
        CRIT = 0,
        HASTE = 0,
        MASTERY = 0,
        VERSATILITY = 0
    }

    -- 19개 장비 슬롯 순회
    for slotId = 1, 19 do
        local itemLink = GetInventoryItemLink(unit, slotId)
        if itemLink then
            -- 방법 1: 기본 아이템 스탯 (빠름, 인챈트/보석 제외)
            local itemStats = C_Item.GetItemStats(itemLink)
            if itemStats then
                for statName, statKey in pairs(ITEM_STAT_KEYS) do
                    local value = itemStats[statKey]
                    if value then
                        stats[statName] = stats[statName] + value
                    end
                end
            end

            -- 방법 2: 툴팁 파싱 (느림, 인챈트/보석 포함)
            local tooltipStats = GetStatsFromTooltip(itemLink)
            for statName, _ in pairs(tooltipStats) do
                -- 기본 스탯과 중복되지 않도록 차이만 추가
                -- 툴팁에는 전체 스탯이 표시되므로, 기본 스탯보다 크면 그 차이가 인챈트/보석
                if tooltipStats[statName] > (itemStats and itemStats[ITEM_STAT_KEYS[statName]] or 0) then
                    local baseValue = itemStats and itemStats[ITEM_STAT_KEYS[statName]] or 0
                    stats[statName] = stats[statName] + (tooltipStats[statName] - baseValue)
                end
            end
        end
    end

    return stats
end

-- 유닛 검사 시작
local function InspectUnit(unit)
    if not UnitExists(unit) then
        print(string.format("|cffff0000[검사]|r 유닛 '%s'이(가) 존재하지 않습니다.", unit))
        return false
    end

    if not UnitIsPlayer(unit) then
        print(string.format("|cffff0000[검사]|r '%s'은(는) 플레이어가 아닙니다.", UnitName(unit) or unit))
        return false
    end

    if not CanInspect(unit) then
        print(string.format("|cffff0000[검사]|r '%s'을(를) 검사할 수 없습니다.", UnitName(unit) or unit))
        return false
    end

    if not CheckInteractDistance(unit, 1) then
        print(string.format("|cffff0000[검사]|r '%s'이(가) 너무 멉니다. 가까이 가주세요.", UnitName(unit) or unit))
        return false
    end

    print(string.format("|cff00ff00[검사]|r '%s' 검사 시작...", UnitName(unit) or unit))
    NotifyInspect(unit)
    return true
end

-- 각 파티원의 가장 높은 스탯 찾기
local function GetHighestStatForUnit(stats)
    local highestStatName = nil
    local highestValue = 0

    for statName, value in pairs(stats) do
        if value > highestValue then
            highestValue = value
            highestStatName = statName
        end
    end

    return highestStatName, highestValue
end

-- 검사 완료 이벤트 핸들러
local function OnInspectReady(guid)
    local unit = nil

    -- GUID로 유닛 찾기
    if UnitGUID("player") == guid then
        unit = "player"
    else
        for i = 1, 4 do
            local partyUnit = "party" .. i
            if UnitExists(partyUnit) and UnitGUID(partyUnit) == guid then
                unit = partyUnit
                break
            end
        end

        if not unit and IsInRaid() then
            for i = 1, 40 do
                local raidUnit = "raid" .. i
                if UnitExists(raidUnit) and UnitGUID(raidUnit) == guid then
                    unit = raidUnit
                    break
                end
            end
        end
    end

    if not unit then
        print("|cffff0000[검사]|r 유닛을 찾을 수 없습니다.")
        return
    end

    local unitName = UnitName(unit)
    local stats = GetStatsFromEquipment(unit)

    -- 결과 저장
    inspectedStats[unitName] = {
        unit = unit,
        stats = stats,
        timestamp = time()
    }

    -- 가장 높은 스탯 찾기
    local highestStatName = GetHighestStatForUnit(stats)
    local message = highestStatName and STAT_MESSAGES[highestStatName] or "스탯 정보 없음"

    print(string.format("%s님은 %s", unitName, message))

    ClearInspectPlayer()
end

-- 파티 전체 검사 시작
local function InspectAllPartyMembers()
    print("|cff00ff00========================================|r")
    print("|cff00ff00[파티 검사]|r 시작합니다...")
    print("|cff00ff00========================================|r")

    -- 기존 데이터 초기화
    inspectedStats = {}

    local inspectedCount = 0

    -- 플레이어 자신 (검사 없이 직접 가져오기)
    local playerName = UnitName("player")
    local playerStats = {
        CRIT = GetCombatRating(SECONDARY_STATS.CRIT),
        HASTE = GetCombatRating(SECONDARY_STATS.HASTE),
        MASTERY = GetCombatRating(SECONDARY_STATS.MASTERY),
        VERSATILITY = GetCombatRating(SECONDARY_STATS.VERSATILITY)
    }
    inspectedStats[playerName] = {
        unit = "player",
        stats = playerStats,
        timestamp = time()
    }

    -- 본인의 가장 높은 스탯 출력
    local highestStatName = GetHighestStatForUnit(playerStats)
    local message = highestStatName and STAT_MESSAGES[highestStatName] or "스탯 정보 없음"
    print(string.format("%s님(본인)은 %s", playerName, message))

    -- 파티원들 검사
    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                if InspectUnit(unit) then
                    inspectedCount = inspectedCount + 1
                end
            end
        end
    else
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                if InspectUnit(unit) then
                    inspectedCount = inspectedCount + 1
                end
            end
        end
    end

    if inspectedCount == 0 then
        print("|cffff0000파티원이 없거나 검사할 수 없습니다.|r")
        print("|cffffff00TIP: 파티원이 근처에 있어야 검사할 수 있습니다.|r")
    else
        print(string.format("|cff00ff00%d명의 파티원 검사 요청 완료. 결과를 기다리는 중...|r", inspectedCount))
    end
end


-- 슬래시 커맨드 등록
SLASH_FINDSECONDSTAT1 = "/findstat"
SLASH_FINDSECONDSTAT2 = "/fs"
SlashCmdList["FINDSECONDSTAT"] = function(msg)
    local command = msg:match("%S+")

    if command == "scan" or command == nil or command == "" then
        -- 파티 전체 검사
        InspectAllPartyMembers()
    elseif command == "help" then
        print("|cff00ff00[" .. addonName .. "]|r 사용법:")
        print("  /fs 또는 /fs scan - 파티원 검사 시작 (근처에 있어야 함)")
    else
        print("|cffff0000[" .. addonName .. "]|r 알 수 없는 명령어: " .. command)
        print("사용법: /fs help")
    end
end

-- 이벤트 핸들러
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("INSPECT_READY")
frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        print("|cff00ff00[" .. addonName .. "]|r 로드됨! /fs 명령어를 사용하세요.")
        print("|cffffff00사용법: /fs help|r")
    elseif event == "INSPECT_READY" then
        -- arg1은 GUID
        OnInspectReady(arg1)
    end
end)
