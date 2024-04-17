local UEHelpers = require("UEHelpers")

-- Cached PlayerController
local PlayerController = nil

local config = require("../config")
local gamelog = require("../utils/gamelog")
local welcomedC = 0
modutil = {}

function modutil.hello()
    msg = "[" .. config.name .. "] " .. config.name .. " v" .. config.version .. " Started Successfully! Authors: MaJoRx0, cw0, & Okaetsu"
    print(msg .. "\n")
    modutil.log("Logging Enabled (this can be configured in config.lua)")
end
function modutil.hello_enterworld()
    if welcomedC > 2 then return end
    msg = config.name .. " v" .. config.version .. " Online"
    ExecuteWithDelay(5000, function()  modutil.info(msg) end)
    welcomedC = welcomedC+1
end
function modutil.info(msg, lifespan)
    modutil.log(msg)
    if config.show_ingame_info then
        gamelog.simple(msg, lifespan)
    end
end
function modutil.warn(msg)
    modutil.log(msg)
    if config.show_ingame_warnings then
        gamelog.blinked(msg)
    end
end
function modutil.log(msg)
    if config.print_console_logs then
        print("[" .. config.name .. "] " .. tostring(msg) .. "\n")
    end
end


function modutil.possible_command(msg)
    return msg:sub(1, 1) == config.command_header
end

function modutil.requires_host_command_context(command)
    -- see if we have a table entry for this command
    if config.command_requires_host_context[command] ~= nil then
        return config.command_requires_host_context[command]
    end
    return false
end

function modutil.qualified_remote_command(PlayerState, command)
    -- see if we have a table entry for this command
    if config.remote_command_admin_required[command] ~= nil then
        -- if the command requires admin and the player is not an admin, return false
        if config.remote_command_admin_required[command] and not PlayerState:GetPlayerController().bAdmin then
            return false
        end
    end
    return true
end

function modutil.parse_command(command)
    local args = {}
    for word in command:gmatch("%S+") do
        table.insert(args, word)
    end
    args[1] = string.lower(args[1])
    return args
end

function modutil.GuidToString(guid)
    if not guid then
        return "nil"
    end
    return tostring(guid.A) .. ":" .. tostring(guid.B) .. ":" .. tostring(guid.C) .. ":" .. tostring(guid.D)
end

function modutil.clipboard(msg)
    modutil.GetPalUtil():ClipboardCopy(msg)
end

function modutil.GetPalUtil()
    if not PalUtilities or not PalUtilities:IsValid() then
        PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
    return PalUtilities
end

function modutil.IsServerSide()
    if not PalUtilities or not PalUtilities:IsValid() then
    PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
    if PalUtilities ~=  nil and PalUtilities:IsValid() then 
        IsServerSide = PalUtilities:IsDedicatedServer(PalUtilities) else IsServerSide = false
    end
    return IsServerSide
end

function modutil.FindPlayerByName(source,name)
    local PlayersList = FindAllOf("PalPlayerCharacter")
    for index, Player in ipairs(PlayersList) do
        local PlayerState = Player.PlayerState
        if PlayerState ~= nil and PlayerState:IsValid() then
            local PName = removeAllWeirdCharacters(PlayerState.PlayerNamePrivate:ToString())
            local UIDT = tostring(string.format("%d",PlayerState.PlayerUId.A & 0xffffffff))
            local name = removeAllWeirdCharacters(name)
            if(PName == name or UIDT == name) then
                return PlayerState , Player
            end
        end
    end
    source:SendLog_ToClient(1,FText("Player not found"),{})
    return nil
end

function modutil.GetLocalPlayerController()
    if PalUtilities == nil or not PalUtilities:IsValid() or WorldObject == nil or not WorldObject:IsValid() then
        WorldObject = FindFirstOf("BP_PalMapObjectManager_C")
        PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    end
    if PlayerController == nil or not PlayerController:IsValid() then
        PlayerController = PalUtilities:GetLocalPlayerController(WorldObject)
    end
    if PlayerController ~= nil and PlayerController:IsValid() then
        return PlayerController
    else
        return nil
    end
end

function modutil.TArryToString(TArray)
    local newArray = {}
    local ArrayToString = ""
    for i = 1,#TArray do
        table.insert(newArray,TArray[i]:ToString())
        ArrayToString = string.format("%s %s",ArrayToString,TArray[i]:ToString())
    end
    return newArray,ArrayToString
end

return modutil