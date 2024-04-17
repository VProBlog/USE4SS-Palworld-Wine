local UEHelpers = require("UEHelpers")
local json = require("../libs/json")

local modutil = require("../utils/modutil")
local tTable = require("../libs/tTable")

mutate = {}
mutate_delay = 250
mutate.PalboxPage_Default = 1
mutate.PalboxSlot_Default = 1

local function DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

mutate.command_queue = {}
global_mutate_change = true
total_mutate_commands = 0

---@param additional_context string? Optional extra context to pass to the string, e.g notify_mutation_failed("Check your command!") -> Mutation Failed, Check your command!
local function notify_mutation_failed(additional_context)
    if additional_context == nil or additional_context == "" then
        modutil.warn("Mutation Failed")
    else
        modutil.warn("Mutation Failed, " .. additional_context)
    end
end

-- router
---@param PlayerState APalPlayerState
---@param args string[]
function mutate.route_cmd(PlayerState, args)

    local mutate_change = true

    local slot = tTable.index_kindathesame(args, "slot")
    local page = tTable.index_kindathesame(args, "page")
    if slot and type(slot) == "number" then
        local slots = tonumber(string.match(args[slot], "slot:(%d+)"))
        if slots ~= nil then
            slot = tonumber(slots)
        else
            slot = mutate.PalboxSlot_Default
        end
    else
        slot = mutate.PalboxSlot_Default
    end
    if page and type(page) == "number" then
        local pages = tonumber(string.match(args[page], "page:(%d+)"))
        if pages ~= nil then
            page = tonumber(pages)
        else
            page = mutate.PalboxPage_Default
        end
    else
        page = mutate.PalboxPage_Default
    end

    if string.sub(args[2], 1, 4) == "dupe" then
        local dupe_amount = 1
        local number_after_dupe = tonumber(string.match(args[2], "dupe:(%d+)"))
        if number_after_dupe ~= nil then
            dupe_amount = number_after_dupe
        end

        local iParam = mutate.get_iParam(PlayerState, page, slot)

        -- If there is no Pal in the specified slot & page, abort the command rather than letting it silently fail
        if iParam == nil or not iParam:IsValid() then
            mutate.command_queue = {}
            notify_mutation_failed()
            return
        end

        local sParam_Template = iParam.SaveParameter

        for i = 1, dupe_amount do
            local slot = slot + i
            local iParam = mutate.get_iParam(PlayerState, page, slot)
            if iParam ~= nil and iParam:IsValid() then
                mutate.deep_copy_param(sParam_Template, iParam)
            else
                notify_mutation_failed()
                return
            end
        end
        modutil.info("Mutation Dupe Complete")
    else
        local iParam = mutate.get_iParam(PlayerState, page, slot)

        if iParam == nil or not iParam:IsValid() then
            mutate.command_queue = {}
            notify_mutation_failed()
            return
        end

        if args[2] == "clear" then
            local new_cmd =
                "mutate character:SheepBall gender:m level:1 stars:0 ranks:0 ivs:0 rare:false health:1 stamina:1 hunger:1 sanity:100 skill:empty pass:empty"
            args = modutil.parse_command(new_cmd)
        end

        for i = 2, #args do
            table.insert(mutate.command_queue, args[i])
        end
        global_mutate_change = true
        total_mutate_commands = #mutate.command_queue
        ExecuteWithDelay(mutate_delay, function()
            mutate.delayed_command(PlayerState, iParam)
        end)
    end

    -- -- print(tostring(sParam.CraftSpeed))
    -- -- print(tostring(sParam.CraftSpeedRates.Values))
    -- -- sParam.CraftSpeedRates.Values:ForEach(function(index, craft_speed_rate)
    -- --     print(tostring(craft_speed_rate:get().Key:ToString()))
    -- --     print(tostring(craft_speed_rate:get().Value))
    -- -- end)
    -- -- sParam.CraftSpeeds:ForEach(function(index, craft_speed)
    -- --     print(tostring(craft_speed:get():GetFullName()))
    -- --     print(tostring(craft_speed:get().WorkSuitability) .. " " .. tostring(craft_speed:get().Rank))
    -- -- end)

    -- -- for i = 1, sParam.CraftSpeeds:GetArrayNum() do
    -- --     sParam.CraftSpeeds[i].Rank = 5
    -- --     sParam.CraftSpeeds[i].WorkSuitability = i
    -- -- end

    -- if mutate_change then
    --     modutil.info("Mutation Complete")
    -- else
    --     modutil.warn("Mutation Failed, please check your command")
    -- end
end

---@param PlayerState APalPlayerState
---@param iParam UPalIndividualCharacterParameter
function mutate.delayed_command(PlayerState, iParam)
    if PlayerState == nil or not PlayerState:IsValid() then
        modutil.warn("[ERROR] PlayerState isn't valid, aborting command.")
        return
    end

    local next_command = table.remove(mutate.command_queue, 1)
    if next_command ~= nil then
        modutil.info("Processing Mutate: " .. tostring(total_mutate_commands - #mutate.command_queue) .. "/" ..
                         tostring(total_mutate_commands), mutate_delay + 5)
        local trait, data = string.match(next_command, "(.*):(.*)")
        if not trait then
            trait = next_command
            data = ""
        end
        local res = mutate.trait(PlayerState, iParam, trait, data)
        global_mutate_change = global_mutate_change and res
        ExecuteWithDelay(mutate_delay, function()
            mutate.delayed_command(PlayerState, iParam)
        end)
        return
    end
    if global_mutate_change then
        modutil.info("Mutation Complete")
    else
        notify_mutation_failed("please check your command")
    end
end

---@param PlayerState APalPlayerState
---@param palbox_page number
---@param palbox_slot number
---@return UPalIndividualCharacterParameter
function mutate.get_iParam(PlayerState, palbox_page, palbox_slot)
    local pal_in_storage = PlayerState:GetPalStorage():GetSlot(palbox_page - 1, palbox_slot - 1)
    if pal_in_storage == nil or pal_in_storage.Handle == nil or not pal_in_storage:IsValid() or
        not pal_in_storage.Handle:IsValid() then
        gamelog.log("[ERROR] There is no Pal in Palbox Slot " .. palbox_slot .. " on Page " .. palbox_page .. "!")
        return nil
    end
    local iParam = pal_in_storage.Handle:TryGetIndividualParameter()
    if iParam == nil or not iParam:IsValid() then
        gamelog.log("[ERROR] Something went wrong with getting Pal stats")
        return nil
    end
    return iParam
end

---@param PlayerState APalPlayerState
---@param iParam UPalIndividualCharacterParameter
---@param trait string
---@param data string
function mutate.trait(PlayerState, iParam, trait, data)
    -- print("  '" .. tostring(trait) .. "' '" .. tostring(data) .. "'")
    local change_made = false
    local save_param = iParam.SaveParameter

    if data ~= "" then
        if trait == "character" then
            save_param.CharacterID = UEHelpers.FindOrAddFName(data)
            change_made = true
        elseif trait == "gender" then
            local gender_key = 1
            if data == "f" then
                gender_key = 2
            end
            save_param.Gender = tonumber(gender_key)
            change_made = true
        elseif trait == "level" then
            save_param.Level = tonumber(data)
            change_made = true
        elseif trait == "stars" then
            local stars = tonumber(data)
            if stars < 0 then
                stars = 0
            elseif stars > 4 then
                stars = 4
            end
            save_param.Rank = stars + 1
            change_made = (data ~= nil)
        elseif trait == "rankhp" then
            save_param.Rank_HP = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "rankattack" then
            save_param.Rank_Attack = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "rankdefense" then
            save_param.Rank_Defence = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "rankcraft" then
            save_param.Rank_CraftSpeed = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "ranks" then
            save_param.Rank_HP = tonumber(data)
            save_param.Rank_Attack = tonumber(data)
            save_param.Rank_Defence = tonumber(data)
            save_param.Rank_CraftSpeed = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "ivhp" then
            save_param.Talent_HP = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "ivattack" then
            save_param.Talent_Shot = tonumber(data)
            save_param.Talent_Melee = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "ivdefense" then
            save_param.Talent_Defense = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "ivs" then
            save_param.Talent_HP = tonumber(data)
            save_param.Talent_Shot = tonumber(data)
            save_param.Talent_Melee = tonumber(data)
            save_param.Talent_Defense = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "rare" then
            save_param.IsRarePal = (data == "true")
            change_made = (data ~= nil)
        elseif trait == "health" or trait == "hp" then
            save_param.HP.Value = tonumber(data) * 1000
            save_param.MaxHP.Value = tonumber(data) * 1000
            change_made = (data ~= nil)
        elseif trait == "exp" or trait == "xp" then
            save_param.EXP = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "stamina" or trait == "maxsp" then
            save_param.MaxSP.Value = tonumber(data) * 1000
            change_made = true
        elseif trait == "hunger" or trait == "food" then
            save_param.FullStomach = tonumber(data)
            save_param.MaxFullStomach = tonumber(data)
            change_made = (data ~= nil)
        elseif trait == "sanity" or trait == "san" then
            local new_san = tonumber(data)
            if new_san < 0 then
                new_san = 0
            elseif new_san > 100 then
                new_san = 100
            end
            save_param.SanityValue = new_san
            change_made = (data ~= nil)
        elseif trait == "pass" then
            mutate.alter_passives(iParam, data)
            change_made = true
        elseif trait == "skill" then
            mutate.alter_skills(iParam, data)
            change_made = true
        end
    end

    -- doesnt require data value
    if trait == "perfect" then
        -- stars
        save_param.Rank = 5
        -- souls
        save_param.Rank_HP = 10
        save_param.Rank_Attack = 10
        save_param.Rank_Defence = 10
        save_param.Rank_CraftSpeed = 10
        -- ivs
        save_param.Talent_HP = 100
        save_param.Talent_Shot = 100
        save_param.Talent_Melee = 100
        save_param.Talent_Defense = 100
        -- teach moves
        mutate.add_skill_list(PlayerState, iParam, mutate.all_skills)
        -- empty passives
        save_param.PassiveSkillList:Empty()
        change_made = true
    elseif trait == "allskills" then
        mutate.add_skill_list(PlayerState, iParam, mutate.all_skills)
        change_made = true
    elseif trait == "generalskills" then
        mutate.add_skill_list(PlayerState, iParam, mutate.general_skills)
        change_made = true
    end

    return change_made
end

mutate.all_skills = {1, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29,
                     30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 50, 51, 53, 54, 55, 56,
                     57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 81, 82,
                     83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 106, 110,
                     112, 113, 118, 122, 127, 128, 129, 130, 132, 133, 135, 137, 141, 142, 145}

mutate.general_skills = {1, 10, 11, 12, 22, 33, 35, 36, 37, 38, 39, 40, 42, 43, 48, 50, 51, 53, 54, 55, 57, 58, 59, 60,
                         61, 62, 63, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 78, 79, 81, 83, 84, 85, 86, 87, 88, 90,
                         91, 92, 93, 94, 95, 97, 98, 99, 100, 106, 110, 112, 113}

---@param iParam UPalIndividualCharacterParameter
---@param target_passive string
function mutate.alter_passives(iParam, target_passive)
    if target_passive == "empty" or target_passive == "clear" then
        iParam.SaveParameter.PassiveSkillList:Empty()
    else
        -- load passives into table
        local existing_passives = {}
        iParam.SaveParameter.PassiveSkillList:ForEach(function(index, existing_passive)
            table.insert(existing_passives, existing_passive:get():ToString())
        end)
        -- toggle it
        tTable.toggle(existing_passives, target_passive)
        -- clear and re-add
        iParam.SaveParameter.PassiveSkillList:Empty()
        for i, v in ipairs(existing_passives) do
            -- AddPassiveSkill should guarantee that adding to the array is done safely, it will also prevent more than four passives from being assigned
            iParam:AddPassiveSkill(UEHelpers.FindOrAddFName(v), UEHelpers.FindOrAddFName("None"))
        end
    end
end

---@param iParam UPalIndividualCharacterParameter
---@param target_skill string
function mutate.alter_skills(iParam, target_skill)
    -- array build gets really complex if we allow people to set Equipped Waza
    iParam.SaveParameter.EquipWaza:Empty()
    if target_skill == "empty" or target_skill == "clear" then
        iParam.SaveParameter.MasteredWaza:Empty()
    else
        -- load skills into table
        local existing_skills = {}
        iParam.SaveParameter.MasteredWaza:ForEach(function(index, existing_skill)
            table.insert(existing_skills, tostring(existing_skill:get()))
        end)
        -- toggle it
        tTable.toggle(existing_skills, target_skill)
        -- calculate endcap
        -- #175 => Reserve_81 is our valid backstopper (still not sure why we need to do this to prevent skill eating)
        tTable.removeFirst(existing_skills, "175")
        table.insert(existing_skills, "175")
        -- clear and re-add
        iParam.SaveParameter.MasteredWaza:Empty()
        for i = 1, #existing_skills do
            iParam.SaveParameter.MasteredWaza[i] = 0
        end
        for i, v in ipairs(existing_skills) do
            iParam.SaveParameter.MasteredWaza[i] = tonumber(v)
            -- print("Added " .. tostring(v) .. " to MasteredWaza")
        end
    end
end

---@param PlayerState APalPlayerState
---@param iParam UPalIndividualCharacterParameter
---@param skill_list EPalWazaID[]
function mutate.add_skill_list(PlayerState, iParam, skill_list)
    iParam.SaveParameter.EquipWaza:Empty()
    iParam.SaveParameter.MasteredWaza:Empty()

    -- print("Adding skill " .. tostring(new_skill))
    local existing_skills = {}
    for _, new_skill in ipairs(skill_list) do
        table.insert(existing_skills, tostring(new_skill))
    end
    -- calculate endcap
    -- #175 => Reserve_81 is our valid backstopper (still not sure why we need to do this to prevent skill eating)
    tTable.removeFirst(existing_skills, "175")
    table.insert(existing_skills, "175")
    for i = 1, #existing_skills do
        iParam.SaveParameter.MasteredWaza[i] = 0
    end
    for i, v in ipairs(existing_skills) do
        iParam.SaveParameter.MasteredWaza[i] = tonumber(v)
        -- modutil.log("Added " .. tostring(v) .. " to MasteredWaza")
    end
end

---@param template FPalIndividualCharacterSaveParameter
---@param iParam UPalIndividualCharacterParameter
function mutate.deep_copy_passives(template, iParam)
    iParam.SaveParameter.PassiveSkillList:Empty()
    template:ForEach(function(index, passive)
        iParam:AddPassiveSkill(UEHelpers.FindOrAddFName(passive:get():ToString()), UEHelpers.FindOrAddFName("None"))
    end)
end

function mutate.deep_copy_waza(template, canvas)
    canvas:Empty()
    local maxIndex = 0
    template:ForEach(function(index, waza)
        canvas[index] = 0
        maxIndex = index
    end)
    canvas[maxIndex + 1] = 0
    template:ForEach(function(index, waza)
        canvas[index] = tonumber(waza:get())
    end)
    canvas[maxIndex + 1] = template[maxIndex + 1]
end

---@param template FPalIndividualCharacterSaveParameter
---@param iParam UPalIndividualCharacterParameter
function mutate.deep_copy_param(template, iParam)
    iParam.SaveParameter.CharacterID = template.CharacterID
    -- iParam.SaveParameter.UniqueNPCID = template.UniqueNPCID
    iParam.SaveParameter.Gender = template.Gender
    iParam.SaveParameter.CharacterClass = template.CharacterClass
    iParam.SaveParameter.Level = template.Level
    iParam.SaveParameter.Rank = template.Rank
    iParam.SaveParameter.Rank_HP = template.Rank_HP
    iParam.SaveParameter.Rank_Attack = template.Rank_Attack
    iParam.SaveParameter.Rank_Defence = template.Rank_Defence
    iParam.SaveParameter.Rank_CraftSpeed = template.Rank_CraftSpeed
    iParam.SaveParameter.Exp = template.Exp
    iParam.SaveParameter.NickName = template.NickName
    iParam.SaveParameter.IsRarePal = template.IsRarePal
    iParam.SaveParameter.EquipWaza:Empty() -- ArrayProperty
    template.EquipWaza:Empty() -- ArrayProperty
    mutate.deep_copy_waza(template.MasteredWaza, iParam.SaveParameter.MasteredWaza) -- ArrayProperty
    iParam.SaveParameter.HP.Value = template.HP.Value -- StructProperty
    iParam.SaveParameter.Talent_HP = template.Talent_HP
    iParam.SaveParameter.Talent_Melee = template.Talent_Melee
    iParam.SaveParameter.Talent_Shot = template.Talent_Shot
    iParam.SaveParameter.Talent_Defense = template.Talent_Defense
    iParam.SaveParameter.FullStomach = template.FullStomach
    iParam.SaveParameter.PhysicalHealth = template.PhysicalHealth
    iParam.SaveParameter.WorkerSick = template.WorkerSick
    mutate.deep_copy_passives(template.PassiveSkillList, iParam) -- ArrayProperty
    iParam.SaveParameter.DyingTimer = template.DyingTimer
    iParam.SaveParameter.MP.Value = template.MP.Value -- StructProperty
    iParam.SaveParameter.IsPlayer = template.IsPlayer
    -- iParam.SaveParameter.OwnedTime = template.OwnedTime -- StructProperty
    -- iParam.SaveParameter.OwnerPlayerUId = template.OwnerPlayerUId -- StructProperty
    -- iParam.SaveParameter.OldOwnerPlayerUIds = template.OldOwnerPlayerUIds
    -- iParam.SaveParameter.OldOwnerPlayerUIds = template.OldOwnerPlayerUIds -- ArrayProperty
    iParam.SaveParameter.MaxHP.Value = template.MaxHP.Value -- StructProperty
    iParam.SaveParameter.Support = template.Support
    iParam.SaveParameter.CraftSpeed = template.CraftSpeed
    -- iParam.SaveParameter.CraftSpeeds = template.CraftSpeeds
    -- iParam.SaveParameter.CraftSpeeds = template.CraftSpeeds -- ArrayProperty
    -- iParam.SaveParameter.ShieldHP = template.ShieldHP -- StructProperty
    -- iParam.SaveParameter.ShieldMaxHP = template.ShieldMaxHP -- StructProperty
    iParam.SaveParameter.MaxMP.Value = template.MaxMP.Value -- StructProperty
    iParam.SaveParameter.MaxSP.Value = template.MaxSP.Value -- StructProperty
    iParam.SaveParameter.HungerType = template.HungerType
    iParam.SaveParameter.SanityValue = template.SanityValue
    iParam.SaveParameter.BaseCampWorkerEventType = template.BaseCampWorkerEventType
    iParam.SaveParameter.BaseCampWorkerEventProgressTime = template.BaseCampWorkerEventProgressTime
    -- iParam.SaveParameter.ItemContainerId = template.ItemContainerId -- StructProperty
    -- iParam.SaveParameter.EquipItemContainerId = template.EquipItemContainerId -- StructProperty
    -- iParam.SaveParameter.SlotID = template.SlotID -- StructProperty
    iParam.SaveParameter.MaxFullStomach = template.MaxFullStomach
    iParam.SaveParameter.FullStomachDecreaseRate_Tribe = template.FullStomachDecreaseRate_Tribe
    iParam.SaveParameter.UnusedStatusPoint = template.UnusedStatusPoint
    -- iParam.SaveParameter.GotStatusPointList = template.GotStatusPointList
    -- iParam.SaveParameter.GotStatusPointList = template.GotStatusPointList -- ArrayProperty
    -- iParam.SaveParameter.DecreaseFullStomachRates = template.DecreaseFullStomachRates -- StructProperty
    -- iParam.SaveParameter.AffectSanityRates = template.AffectSanityRates -- StructProperty
    -- iParam.SaveParameter.CraftSpeedRates = template.CraftSpeedRates -- StructProperty
    -- iParam.SaveParameter.LastJumpedLocation = template.LastJumpedLocation -- StructProperty
    iParam.SaveParameter.FoodWithStatusEffect = template.FoodWithStatusEffect
    iParam.SaveParameter.Tiemr_FoodWithStatusEffect = template.Tiemr_FoodWithStatusEffect
    iParam.SaveParameter.CurrentWorkSuitability = template.CurrentWorkSuitability
    iParam.SaveParameter.bAppliedDeathPenarty = template.bAppliedDeathPenarty
    iParam.SaveParameter.PalReviveTimer = template.PalReviveTimer
    iParam.SaveParameter.VoiceID = template.VoiceID
    -- iParam.SaveParameter.Dynamic = template.Dynamic -- StructProperty
end

return mutate

----------------------------
-- List of Available Traits
----------------------------

-- NameProperty: CharacterID
-- NameProperty: UniqueNPCID
-- EnumProperty: Gender
-- ClassProperty: CharacterClass
-- IntProperty: Level
-- IntProperty: Rank
-- IntProperty: Rank_HP
-- IntProperty: Rank_Attack
-- IntProperty: Rank_Defence
-- IntProperty: Rank_CraftSpeed
-- IntProperty: Exp
-- StrProperty: NickName
-- BoolProperty: IsRarePal
-- ArrayProperty: EquipWaza
-- EnumProperty: EquipWaza
-- ArrayProperty: MasteredWaza
-- EnumProperty: MasteredWaza
-- StructProperty: HP
-- IntProperty: Talent_HP
-- IntProperty: Talent_Melee
-- IntProperty: Talent_Shot
-- IntProperty: Talent_Defense
-- FloatProperty: FullStomach
-- EnumProperty: PhysicalHealth
-- EnumProperty: WorkerSick
-- ArrayProperty: PassiveSkillList
-- NameProperty: PassiveSkillList
-- IntProperty: DyingTimer
-- StructProperty: MP
-- BoolProperty: IsPlayer
-- StructProperty: OwnedTime
-- StructProperty: OwnerPlayerUId
-- ArrayProperty: OldOwnerPlayerUIds
-- StructProperty: OldOwnerPlayerUIds
-- StructProperty: MaxHP
-- IntProperty: Support
-- IntProperty: CraftSpeed
-- ArrayProperty: CraftSpeeds
-- StructProperty: CraftSpeeds
-- StructProperty: ShieldHP
-- StructProperty: ShieldMaxHP
-- StructProperty: MaxMP
-- StructProperty: MaxSP
-- EnumProperty: HungerType
-- FloatProperty: SanityValue
-- EnumProperty: BaseCampWorkerEventType
-- FloatProperty: BaseCampWorkerEventProgressTime
-- StructProperty: ItemContainerId
-- StructProperty: EquipItemContainerId
-- StructProperty: SlotID
-- FloatProperty: MaxFullStomach
-- FloatProperty: FullStomachDecreaseRate_Tribe
-- IntProperty: UnusedStatusPoint
-- ArrayProperty: GotStatusPointList
-- StructProperty: GotStatusPointList
-- StructProperty: DecreaseFullStomachRates
-- StructProperty: AffectSanityRates
-- StructProperty: CraftSpeedRates
-- StructProperty: LastJumpedLocation
-- NameProperty: FoodWithStatusEffect
-- IntProperty: Tiemr_FoodWithStatusEffect
-- EnumProperty: CurrentWorkSuitability
-- BoolProperty: bAppliedDeathPenarty
-- FloatProperty: PalReviveTimer
-- IntProperty: VoiceID
-- StructProperty: Dynamic
