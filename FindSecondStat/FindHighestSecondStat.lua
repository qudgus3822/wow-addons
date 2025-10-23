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

local STAT_NAMES = {
    [9] = "치명타",
    [18] = "가속",
    [26] = "특화",
    [29] = "유연성"
}

-- 프레임 생성
local frame = CreateFrame("Frame")

-- 검사된 파티원 스탯 저장소
local inspectedStats = {}

-- 아이템 스탯 키 매핑
local ITEM_STAT_KEYS = {
    CRIT = "ITEM_MOD_CRIT_RATING_SHORT",
    HASTE = "ITEM_MOD_HASTE_RATING_SHORT",
    MASTERY = "ITEM_MOD_MASTERY_RATING_SHORT",
    VERSATILITY = "ITEM_MOD_VERSATILITY"
}

-- 장비에서 2차 스탯 추출
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
            local itemStats = C_Item.GetItemStats(itemLink)
            if itemStats then
                for statName, statKey in pairs(ITEM_STAT_KEYS) do
                    local value = itemStats[statKey]
                    if value then
                        stats[statName] = stats[statName] + value
                    end
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

    print(string.format("|cff00ff00[검사 완료]|r %s - 치명타:%d, 가속:%d, 특화:%d, 유연성:%d",
        unitName,
        stats.CRIT,
        stats.HASTE,
        stats.MASTERY,
        stats.VERSATILITY))

    ClearInspectPlayer()
end

-- 테스트: 특정 유닛의 2차 스탯 가져오기 시도
local function TestGetUnitStats(unit)
    if not UnitExists(unit) then
        print(string.format("|cffff0000[테스트]|r 유닛 '%s'이(가) 존재하지 않습니다.", unit))
        return
    end

    local unitName = UnitName(unit) or "Unknown"
    print(string.format("|cff00ff00[테스트]|r %s (%s) 스탯 조회 시도:", unitName, unit))

    -- GetCombatRating 테스트
    print("\\n1. GetCombatRating() 테스트:")
    for statName, statID in pairs(SECONDARY_STATS) do
        local rating = GetCombatRating(statID)
        local koreanName = STAT_NAMES[statID]
        print(string.format("  %s (ID:%d): %d", koreanName, statID, rating or 0))
    end

    -- GetCombatRatingBonus 테스트
    print("\\n2. GetCombatRatingBonus() 테스트:")
    for statName, statID in pairs(SECONDARY_STATS) do
        local bonus = GetCombatRatingBonus(statID)
        local koreanName = STAT_NAMES[statID]
        print(string.format("  %s (ID:%d): %.2f%%", koreanName, statID, bonus or 0))
    end

    -- UnitStat 테스트 (1차 스탯)
    print("\\n3. UnitStat() 테스트 (1차 스탯):")
    local stats = {
        { name = "힘", index = 1 },
        { name = "민첩", index = 2 },
        { name = "체력", index = 3 },
        { name = "지능", index = 4 }
    }
    for _, stat in ipairs(stats) do
        local base, effective = UnitStat(unit, stat.index)
        if base then
            print(string.format("  %s: 기본=%d, 효과=%d", stat.name, base, effective))
        else
            print(string.format("  %s: |cffff0000조회 실패|r", stat.name))
        end
    end

    print("\\n|cffaaaaaaTIP: player가 아닌 유닛은 대부분의 함수가 작동하지 않습니다.|r")
end

-- 특정 유닛의 2차 스탯을 가져오는 함수
local function GetUnitSecondaryStats(unit)
    local stats = {}

    -- UnitStat으로 기본 스탯 가져오기
    local _, agility = UnitStat(unit, 2)   -- Agility
    local _, intellect = UnitStat(unit, 4) -- Intellect

    -- 타겟된 유닛의 경우 combat rating을 직접 가져올 수 있음
    if unit == "player" then
        for statName, statID in pairs(SECONDARY_STATS) do
            local rating = GetCombatRating(statID)
            stats[statName] = rating
        end
    else
        -- 파티원의 경우 검사 시도
        if UnitIsPlayer(unit) and CheckInteractDistance(unit, 1) then
            -- 근처에 있으면 검사 가능
            for statName, statID in pairs(SECONDARY_STATS) do
                local rating = GetCombatRating(statID) -- 제한적
                stats[statName] = rating
            end
        end
    end

    return stats, agility, intellect
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
    print(string.format("|cff00ff00[본인]|r %s - 치명타:%d, 가속:%d, 특화:%d, 유연성:%d",
        playerName,
        playerStats.CRIT,
        playerStats.HASTE,
        playerStats.MASTERY,
        playerStats.VERSATILITY))

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

-- 파티 전체에서 가장 높은 스탯을 찾는 함수
local function FindPartyHighestStats()
    local partyStats = {}

    -- 검사된 데이터가 있으면 사용
    if next(inspectedStats) then
        for playerName, data in pairs(inspectedStats) do
            partyStats[playerName] = data
        end
    else
        -- 검사된 데이터가 없으면 본인만 표시
        local playerName = UnitName("player")
        local playerStats = {
            CRIT = GetCombatRating(SECONDARY_STATS.CRIT),
            HASTE = GetCombatRating(SECONDARY_STATS.HASTE),
            MASTERY = GetCombatRating(SECONDARY_STATS.MASTERY),
            VERSATILITY = GetCombatRating(SECONDARY_STATS.VERSATILITY)
        }
        partyStats[playerName] = {
            unit = "player",
            stats = playerStats,
            timestamp = time()
        }
    end

    return partyStats
end

-- 각 스탯별로 가장 높은 사람 찾기
local function FindHighestForEachStat(partyStats)
    local results = {}

    -- SECONDARY_STATS의 각 스탯에 대해
    for statKey, statID in pairs(SECONDARY_STATS) do
        local highestName = nil
        local highestValue = 0

        -- 모든 파티원의 해당 스탯 비교
        for playerName, data in pairs(partyStats) do
            local value = data.stats[statKey] or 0
            if value > highestValue then
                highestValue = value
                highestName = playerName
            end
        end

        results[statKey] = {
            playerName = highestName,
            value = highestValue,
            statID = statID
        }
    end

    return results
end

-- 결과 출력 함수
local function PrintHighestStat()
    print("========================================")
    print("|cff00ff00[" .. addonName .. "]|r 파티 2차 스탯 분석")
    print("========================================")

    local partyStats = FindPartyHighestStats()
    local highestStats = FindHighestForEachStat(partyStats)

    -- 파티원 목록과 스탯
    print("\\n|cffffff00파티 구성원 스탯:|r")
    for playerName, data in pairs(partyStats) do
        local stats = data.stats
        local isPlayer = data.unit == "player"
        local nameColor = isPlayer and "|cff00ff00" or "|cffffffff"

        print(string.format("%s%s|r - 치명:%d, 가속:%d, 특화:%d, 유연:%d",
            nameColor,
            playerName,
            stats.CRIT or 0,
            stats.HASTE or 0,
            stats.MASTERY or 0,
            stats.VERSATILITY or 0))
    end

    -- 각 스탯별 최고 보유자
    print("\\n|cffff8800각 스탯별 최고 보유자:|r")
    for statKey, data in pairs(highestStats) do
        local koreanName = STAT_NAMES[data.statID] or statKey
        if data.playerName and data.value > 0 then
            print(string.format("  |cffffff00%s|r: |cff00ff00%s|r (%d)",
                koreanName,
                data.playerName,
                data.value))
        else
            print(string.format("  |cffffff00%s|r: |cffff0000정보 없음|r", koreanName))
        end
    end

    if next(inspectedStats) == nil or (next(inspectedStats) ~= nil and next(inspectedStats, UnitName("player")) == nil) then
        print("\\n|cffaaaaaa* 파티원 스탯을 보려면 /fs scan 명령을 사용하세요.|r")
    end

    print("========================================")
end

-- 슬래시 커맨드 등록
SLASH_FINDSECONDSTAT1 = "/findstat"
SLASH_FINDSECONDSTAT2 = "/fs"
SlashCmdList["FINDSECONDSTAT"] = function(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end

    local command = args[1]

    if command == "scan" or command == "inspect" then
        -- 파티 전체 검사
        InspectAllPartyMembers()
    elseif command == "test" then
        -- 테스트 모드: /fs test <unit>
        local unit = args[2] or "player"
        TestGetUnitStats(unit)
    elseif command == "help" then
        print("|cff00ff00[" .. addonName .. "]|r 사용법:")
        print("  /fs 또는 /findstat - 파티 2차 스탯 분석 결과 표시")
        print("  /fs scan - 파티원 검사 시작 (근처에 있어야 함)")
        print("  /fs test <unit> - 특정 유닛의 스탯 조회 테스트")
        print("    예: /fs test player")
        print("    예: /fs test target")
        print("    예: /fs test party1")
    else
        -- 기본 동작
        PrintHighestStat()
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
