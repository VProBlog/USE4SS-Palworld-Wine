local UEHelpers = require("UEHelpers")

gamelog = {}

gamelog.widget_lifespan = 5*1000
gamelog.skip_amount = 0

gamelog.widgetref_simple = "/Game/Pal/Blueprint/UI/Log/WBP_SimpleLog.WBP_SimpleLog_C"
gamelog.widgetref_notice = "/Game/Pal/Blueprint/UI/Log/WBP_NoticeLog.WBP_NoticeLog_C"
gamelog.widgetref_blinked = "/Game/Pal/Blueprint/UI/Log/WBP_BlinkedLog.WBP_BlinkedLog_C"

gamelog.createdComponents = {}

---@class UPalLogManager
local palLogManager = nil
-- Bool to turn on/off the old logging system with creating widgets
-- I've switched to using the in-game log manager since it's more efficient
local useLegacyGamelog = false

-- This ensures LogManager is always available and will be cheap to call if palLogManager is already set
local function setLogManager()
    if palLogManager == nil or not palLogManager:IsValid() then
        palLogManager = FindFirstOf("BP_PalLogManager_C")
    end
end

function gamelog.log(message, gamelogPopup, lifespan)
    if useLegacyGamelog == true then
        if gamelogPopup == nil then
            return
        end
        if lifespan == nil then
            lifespan = gamelog.widget_lifespan
        end
    
        gamelogPopup:AddToViewport(99)
        gamelogPopup:SetLogText(FText(message))
        gamelogPopup:SetRenderTranslation({ X = 30, Y = 300 })
        
        table.insert(gamelog.createdComponents, gamelogPopup)
        ExecuteWithDelay(lifespan, gamelog.popGameLog)
    else
        setLogManager()
        if palLogManager ~= nil and palLogManager:IsValid() then
            palLogManager:AddLog(1, FText(message), {})
        end
    end
end

function gamelog.simple(message, lifespan)
    if useLegacyGamelog == true then
        gamelogPopup = StaticConstructObject(StaticFindObject(gamelog.widgetref_simple), FindFirstOf("GameInstance"))
        gamelog.log(message, gamelogPopup, lifespan)
    else
        setLogManager()
        if palLogManager ~= nil and palLogManager:IsValid() then
            palLogManager:AddLog(1, FText(message), {})
        end
    end
end

function gamelog.blinked(message)
    if useLegacyGamelog == true then
        gamelogPopup = StaticConstructObject(StaticFindObject(gamelog.widgetref_blinked), FindFirstOf("GameInstance"))
        gamelog.log(message, gamelogPopup)
    else
        setLogManager()
        if palLogManager ~= nil and palLogManager:IsValid() then
            local guid = palLogManager:AddLog(3, FText(message), {})
            ExecuteWithDelay(gamelog.widget_lifespan, function ()
                if palLogManager ~= nil and palLogManager:IsValid() then
                    palLogManager:RemoveVeryImportantLog(guid)
                end
            end)
        end
    end
end

function gamelog.popGameLog()
    if useLegacyGamelog == true then
        if #gamelog.createdComponents > 0 then
            gamelog.createdComponents[1]:RemoveFromViewport()
            table.remove(gamelog.createdComponents, 1)
        end
    end
end


return gamelog