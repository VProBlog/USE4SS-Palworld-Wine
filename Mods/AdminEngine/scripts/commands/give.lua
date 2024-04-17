local modutil = require("../utils/modutil")
local tTable = require("../libs/tTable")

give = {}

function removeAllWeirdCharacters(inputString)
    return string.lower(inputString:gsub("[%W]", ""))
end



function give.GiftAllPlayers(args)
    local PlayersList = FindAllOf("PalPlayerCharacter")
    for index, Player in ipairs(PlayersList) do
        local PlayerState = Player.PlayerState
        if PlayerState ~= nil and PlayerState:IsValid() then
            local PName = removeAllWeirdCharacters(PlayerState.PlayerNamePrivate:ToString())
            local UIDT = tostring(string.format("%d",PlayerState.PlayerUId.A & 0xffffffff))
            spawnItems(PlayerState, args, true)   
        end
    end
end

-- router
function give.route_cmd(PlayerState, args)
    if string.find(string.lower(args[1]), "gift") then 
        if not args[2] or not args[3] then modutil.warn("Usage: !gift <PlayerName/PlayerUID> <item>")return end
        if(string.lower(args[2]) == "all") then
            if(not modutil.IsServerSide()) then return end
            return give.GiftAllPlayers(args)
        else
            if(not modutil.IsServerSide()) then return end
            local PlayerState = modutil.FindPlayerByName(PlayerState:GetPlayerController(),tostring(args[2]))
            if(PlayerState == nil) then return end
            return spawnItems(PlayerState, args, true)
        end
    end
    spawnItems(PlayerState, args)
end

-- processors
function spawnItems(PlayerState, args, isServer)
    local x = 2
    if  isServer == nil then isServer = false end
    if isServer and isServer == true or string.lower(args[2]) == "all" then x = 3 end
    for i = x, #args do
        give.spawnItemSingle(PlayerState, args[i], isServer)
    end
end

function give.spawnItemSingle(PlayerState, item, isServer)
    if isServer == nil then isServer = false end
    if string.find(string.lower(item), "relic") then
        modutil.warn("These are not useable Relics, try '!pick relic'")
        return
    end
    if string.find(string.lower(item), "palegg") then
        modutil.warn("These are not useable Eggs, try '!pick eggs'")
        return
    end
    modutil.log("Spawning Item: " .. tostring(item))
    quantity = 1
    if string.find(item, ":") then
        item, quantity = string.match(item, "(.*):(.*)")
    end

    -- check for special items
    custom_data.load_kits()
    local kits = custom_data.kits
    if kits[item] then
        local kitargs = modutil.parse_command(kits[item])
        for i = 1, #kitargs do
            give.spawnItemSingle(PlayerState, kitargs[i],isServer)
        end
        return
    end
    if string.find(item, "techpoint") then
        wire_points(PlayerState, quantity)
        modutil.warn(string.format("%d Tech points have been added to %s",quantity,PlayerState.PlayerNamePrivate:ToString()))
        return
    end
    if string.find(item, "exp") then
        wire_exp(PlayerState, quantity)
        modutil.warn(string.format("%d exp have been added to %s",quantity,PlayerState.PlayerNamePrivate:ToString()))
        
        return
    end
    if string.find(item, "dupe") then
        wire_dupe(PlayerState, quantity)
        return
    end
    if string.find(item, "level") then
        wire_level(PlayerState, quantity)
        return
    end
    --local Player = PlayerState.GetPlayerController()
    --local PalPlayerState = Player.GetPalPlayerState()
    local PalPlayerInventoryData = PlayerState:GetInventoryData()
    if isServer and isServer == true and modutil.IsServerSide() then 
        PalPlayerInventoryData:AddItem_ServerInternal(FName(item), quantity, false)
    else
        PalPlayerInventoryData:RequestAddItem(FName(item), quantity, false)
    end
end

-- todo: grant via PlayerState -- Done baby :D
function wire_points(PlayerState, quantity)
    -- provided by @DecioLuvier
    local TRM = PlayerState:GetPlayerController().Transmitter.Player
    TRM:RequestAddTechnolgyPoint_ToServer(quantity)
end

function wire_exp(PlayerState, quantity)
    -- provided by @MaJoRx0
    PlayerState:GrantExpForParty(quantity)
end

function wire_level(PlayerState, quantity)
    local PlayerController = PlayerState:GetPlayerController()
    local PlayerCharacter = PlayerController.Pawn
    local PalUtil = modutil:GetPalUtil()

    local playerlevel = PlayerCharacter.CharacterParameterComponent:GetLevel()
    local playerexp = PlayerCharacter.CharacterParameterComponent:GetIndividualParameter():GetExp()
    local expDataBase = PalUtil:GetExpDatabase(PlayerController)
    local expnedded = expDataBase:GetTotalExp(playerlevel+quantity,true)
   local expnedded = expnedded - playerexp

    wire_exp(PlayerState, expnedded)
end

function wire_dupe(PlayerState, quantity)
    -- provided by @MaJoRx0
    local inventorydata = PlayerState.GetInventoryData()
    local Slots = inventorydata.InventoryMultiHelper.Containers
    local FirstSlot = Slots[1]:Get(0)
    local SlotID = FirstSlot:GetItemId().StaticId
    local Count = FirstSlot:GetStackCount()
	--inventorydata:RequestAddItem(SlotID, Count, true);
    give.spawnItemSingle(PlayerState,string.format("%s:%s", SlotID:ToString(), quantity))
end
return give