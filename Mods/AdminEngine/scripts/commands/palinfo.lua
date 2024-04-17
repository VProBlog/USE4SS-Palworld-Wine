local modutil = require("../utils/modutil")

---@class UPalUtility
local palUtility = nil

-- This ensures PalUtility is always available and will be cheap to call if palUtility is already set
local function setPalUtility()
    if palUtility == nil or not palUtility:IsValid() then
        palUtility = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
end

local palinfo = {}
palinfo.PalboxPage_Default = 1
palinfo.PalboxSlot_Default = 1

---@param additional_context string? Optional extra context to pass to the string, e.g notify_palinfo_failed("Check your command!") -> Retrieving Info Failed, Check your command!
local function notify_palinfo_failed(additional_context)
    if additional_context == nil or additional_context == "" then
        modutil.warn("Retrieving Info Failed")
    else
        modutil.warn("Retrieving Info Failed, " .. additional_context)
    end
end

-- router
---@param PlayerState APalPlayerState
---@param args string[]
function palinfo.route_cmd(PlayerState, args)
    if #args < 2 then
        modutil.warn("[ERROR] Please enter a trait after !palinfo")
        return
    end
    
    setPalUtility()

    local iParam = mutate.get_iParam(PlayerState, mutate.PalboxPage_Default, mutate.PalboxSlot_Default)

    if iParam == nil then
        notify_palinfo_failed()
        return
    end

    if PlayerState == nil or not PlayerState:IsValid() then
        modutil.warn("[ERROR] PlayerState isn't valid, aborting command.")
        return
    end

    palinfo.print_info(PlayerState, iParam, args[2])
end

---@param PlayerState APalPlayerState
---@param palbox_page number
---@param palbox_slot number
---@return UPalIndividualCharacterParameter
function palinfo.get_iParam(PlayerState, palbox_page, palbox_slot)
    local pal_in_storage = PlayerState:GetPalStorage():GetSlot(palbox_page-1,palbox_slot-1)
    if pal_in_storage == nil or pal_in_storage.Handle == nil or not pal_in_storage:IsValid() or not pal_in_storage.Handle:IsValid() then
        modutil.warn("[ERROR] There is no Pal in Palbox Slot " .. palbox_slot .. " on Page " .. palbox_page .. "!")
        return nil
    end
    local iParam = pal_in_storage.Handle:TryGetIndividualParameter()
    if iParam == nil or not iParam:IsValid() then
        modutil.warn("[ERROR] Something went wrong with getting Pal stats")
        return nil
    end
    return iParam
end

---@param PlayerState APalPlayerState
---@param iParam UPalIndividualCharacterParameter
---@param trait string
function palinfo.print_info(PlayerState, iParam, trait)
    local save_param = iParam.SaveParameter

    modutil.info("ID: " .. save_param.CharacterID:ToString())

    if trait == "ivhp" then
        modutil.info("HP IV: " .. save_param.Talent_HP)
    elseif trait == "ivattack" then
        modutil.info("Attack IV (Shot): " .. save_param.Talent_Shot)
        modutil.info("Attack IV (Melee): " .. save_param.Talent_Melee)
    elseif trait == "ivdefense" then
        modutil.info("Defense IV: " .. save_param.Talent_Defense)
    elseif trait == "ivs" then
        modutil.info("HP IV: " .. save_param.Talent_HP)
        modutil.info("Attack IV (Shot): " .. save_param.Talent_Shot)
        modutil.info("Attack IV (Melee): " .. save_param.Talent_Melee)
        modutil.info("Defense IV: " .. save_param.Talent_Defense)
    elseif trait == "rare" then
        if save_param.IsRarePal == true then
            modutil.info("Is Shiny: Yes")
        else
            modutil.info("Is Shiny: No")
        end
    elseif trait == "stamina" or trait == "maxsp" then
        local stamina_value = 0
        -- Check to avoid dividing by 0
        if save_param.MaxSP.Value ~= 0 then
            stamina_value = save_param.MaxSP.Value / 1000
        end
        modutil.info("Total Stamina: " .. stamina_value)
    else
        modutil.warn("[ERROR] Unknown Trait '" .. trait .. "'")
    end
end

return palinfo