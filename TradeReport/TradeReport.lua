-- TradeReport 애드온
local ADDON_NAME = "TradeReport"

-- 데이터베이스 초기화
TradeReportDB = TradeReportDB or {
    enabled = true,
    showGold = true
}

-- 거래 정보를 저장할 변수
local tradeInfo = {
    targetName = nil,
    itemsReceived = {},
    itemsGiven = {},
    goldReceived = 0,
    goldGiven = 0
}

-- 거래 정보 초기화
local function ResetTradeInfo()
    tradeInfo.targetName = nil
    tradeInfo.itemsReceived = {}
    tradeInfo.itemsGiven = {}
    tradeInfo.goldReceived = 0
    tradeInfo.goldGiven = 0
end

-- 숫자를 골드/실버/코퍼로 변환
local function FormatMoney(amount)
    if amount == 0 then return nil end

    local gold = floor(amount / 10000)
    local silver = floor((amount % 10000) / 100)
    local copper = amount % 100

    local moneyStr = ""
    if gold > 0 then
        moneyStr = moneyStr .. gold .. "골드"
    end
    if silver > 0 then
        if moneyStr ~= "" then moneyStr = moneyStr .. " " end
        moneyStr = moneyStr .. silver .. "실버"
    end
    if copper > 0 or moneyStr == "" then
        if moneyStr ~= "" then moneyStr = moneyStr .. " " end
        moneyStr = moneyStr .. copper .. "코퍼"
    end

    return moneyStr
end

-- 거래 아이템 수집
local function CollectTradeItems()
    -- 상대방 이름 저장
    tradeInfo.targetName = UnitName("NPC")

    -- 받은 아이템 수집 (상대방이 준 것)
    tradeInfo.itemsReceived = {}
    for i = 1, MAX_TRADABLE_ITEMS do
        local name, texture, quantity, quality, isUsable, enchantment = GetTradeTargetItemInfo(i)
        if name then
            local itemLink = GetTradeTargetItemLink(i)
            table.insert(tradeInfo.itemsReceived, {
                name = name,
                link = itemLink or name,
                quantity = quantity or 1
            })
        end
    end

    -- 준 아이템 수집 (내가 준 것)
    tradeInfo.itemsGiven = {}
    for i = 1, MAX_TRADABLE_ITEMS do
        local name, texture, quantity, quality, isUsable, enchantment = GetTradePlayerItemInfo(i)
        if name then
            local itemLink = GetTradePlayerItemLink(i)
            table.insert(tradeInfo.itemsGiven, {
                name = name,
                link = itemLink or name,
                quantity = quantity or 1
            })
        end
    end

    -- 골드 정보 수집
    if TradeReportDB.showGold then
        tradeInfo.goldReceived = GetTargetTradeMoney()
        tradeInfo.goldGiven = GetPlayerTradeMoney()
    end
end

-- 거래 완료 보고
local function ReportTrade()
    if not TradeReportDB.enabled then return end
    if not tradeInfo.targetName then return end

    local hasItems = (#tradeInfo.itemsReceived > 0 or #tradeInfo.itemsGiven > 0)
    local hasGold = (tradeInfo.goldReceived > 0 or tradeInfo.goldGiven > 0)

    -- 아무것도 거래하지 않았으면 출력하지 않음
    if not hasItems and not hasGold then
        ResetTradeInfo()
        return
    end

    print("|cff00ff00[거래 완료]|r " .. tradeInfo.targetName .. "님과의 거래:")

    -- 받은 아이템 출력
    if #tradeInfo.itemsReceived > 0 or tradeInfo.goldReceived > 0 then
        local receivedText = "|cff00ff00받음:|r "
        local items = {}

        for _, item in ipairs(tradeInfo.itemsReceived) do
            local itemText = item.link
            if item.quantity > 1 then
                itemText = itemText .. " x" .. item.quantity
            end
            table.insert(items, itemText)
        end

        if tradeInfo.goldReceived > 0 then
            local moneyStr = FormatMoney(tradeInfo.goldReceived)
            if moneyStr then
                table.insert(items, "|cffffd700" .. moneyStr .. "|r")
            end
        end

        if #items > 0 then
            print("  " .. receivedText .. table.concat(items, ", "))
        end
    end

    -- 준 아이템 출력
    if #tradeInfo.itemsGiven > 0 or tradeInfo.goldGiven > 0 then
        local givenText = "|cffff6b6b줌:|r "
        local items = {}

        for _, item in ipairs(tradeInfo.itemsGiven) do
            local itemText = item.link
            if item.quantity > 1 then
                itemText = itemText .. " x" .. item.quantity
            end
            table.insert(items, itemText)
        end

        if tradeInfo.goldGiven > 0 then
            local moneyStr = FormatMoney(tradeInfo.goldGiven)
            if moneyStr then
                table.insert(items, "|cffffd700" .. moneyStr .. "|r")
            end
        end

        if #items > 0 then
            print("  " .. givenText .. table.concat(items, ", "))
        end
    end

    -- 거래 정보 초기화
    ResetTradeInfo()
end

-- 이벤트 프레임 생성
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("TRADE_SHOW")
eventFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")
eventFrame:RegisterEvent("TRADE_CLOSED")
eventFrame:RegisterEvent("UI_INFO_MESSAGE")

local tradeAccepted = false

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            -- 데이터베이스 초기화
            TradeReportDB = TradeReportDB or {
                enabled = true,
                showGold = true
            }
            print("|cff00ff00[TradeReport]|r 로드됨! /tr 명령어로 설정하세요")
        end
    elseif event == "TRADE_SHOW" then
        -- 거래 창이 열림
        ResetTradeInfo()
        tradeAccepted = false
    elseif event == "TRADE_ACCEPT_UPDATE" then
        -- 플레이어가 수락 버튼을 눌렀을 때
        local playerAccepted, targetAccepted = ...
        if playerAccepted == 1 and targetAccepted == 1 then
            -- 양쪽 모두 수락했을 때 아이템 정보 수집
            tradeAccepted = true
            CollectTradeItems()
        end
    elseif event == "UI_INFO_MESSAGE" then
        -- 거래 완료 메시지 감지
        local messageType, message = ...
        if messageType == 163 then -- LE_GAME_ERR_TRADE_COMPLETE
            if tradeAccepted then
                -- 약간의 지연 후 보고 (아이템 링크가 완전히 로드되도록)
                C_Timer.After(0.1, ReportTrade)
                tradeAccepted = false
            end
        end
    elseif event == "TRADE_CLOSED" then
        -- 거래창이 닫힘 (취소된 경우)
        if not tradeAccepted then
            ResetTradeInfo()
        end
    end
end)

-- 슬래시 명령어
SLASH_TRADEREPORT1 = "/tr"
SLASH_TRADEREPORT2 = "/tradereport"
SlashCmdList["TRADEREPORT"] = function(msg)
    local command = strlower(strtrim(msg))

    if command == "on" or command == "enable" then
        TradeReportDB.enabled = true
        print("|cff00ff00[TradeReport]|r 활성화됨")
    elseif command == "off" or command == "disable" then
        TradeReportDB.enabled = false
        print("|cffff0000[TradeReport]|r 비활성화됨")
    elseif command == "gold" then
        TradeReportDB.showGold = not TradeReportDB.showGold
        if TradeReportDB.showGold then
            print("|cff00ff00[TradeReport]|r 골드 표시 활성화")
        else
            print("|cffff0000[TradeReport]|r 골드 표시 비활성화")
        end
    else
        print("|cff00ff00[TradeReport]|r 명령어:")
        print("  /tr on - 거래 보고 활성화")
        print("  /tr off - 거래 보고 비활성화")
        print("  /tr gold - 골드 표시 토글")
        print("현재 상태: " .. (TradeReportDB.enabled and "|cff00ff00활성화|r" or "|cffff0000비활성화|r"))
        print("골드 표시: " .. (TradeReportDB.showGold and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    end
end
