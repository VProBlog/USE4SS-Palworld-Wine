local UEHelpers = require("UEHelpers")

local kismetSys = StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
local lineTraceSingleFunc = StaticFindObject("/Script/Engine.KismetSystemLibrary:LineTraceSingle")

local config = require("../config")
local modutil = require("utils/modutil")
local custom_data = require("utils/custom_data")

tp = {}

tp_step = 462.962962963
tp_airdrop_altitude = 100000.00000000
vertical_offset = 500

-- router
function tp.tpall(Player)
    local PlayersList = FindAllOf("PalPlayerCharacter")
    for index, MPlayer in ipairs(PlayersList) do
        if MPlayer ~= nil and MPlayer and Player:IsValid() and MPlayer.PlayerState.PlayerNamePrivate:ToString() ~= Player.PlayerNamePrivate:ToString() then
            modutil:GetPalUtil():Teleport(MPlayer, Player.PawnPrivate:K2_GetActorLocation(),
                Player.PawnPrivate:K2_GetActorRotation(), true, false)
        end
    end
end

function tp.route_cmd(Player, args)
    if #args == 1 then
        export_coords(Player)
        return
    elseif prep_coords(args) then
        teleport(Player, args)
        return
    elseif args[2] == "save" then
        local Location = get_coords(Player)
        -- append to custom locations
        custom_data.locations[args[3]] = Location.X .. "," .. Location.Y .. "," .. Location.Z
        custom_data.save_locations()
        modutil.info("Coordinates saved => " .. args[3])
        return
    end
    if not modutil:IsServerSide() then
        return
    end
    if string.lower(args[2]) == "all" then
        if type(args[3]) == "string" then
            _, Player = modutil.FindPlayerByName(Player, args[3])
            if not Player then
                return
            end
        end
        tp.tpall(Player.PlayerState)

    elseif args[2] then
        local APlayer = Player.Pawn

        local _, TPlayer = modutil.FindPlayerByName(Player, args[2])

        if not TPlayer then
            return
        end
        if args[3] and type(args[3]) == "string" then
            APlayer = TPlayer
            _, TPlayer = modutil.FindPlayerByName(Player, args[3])
            if not APlayer or not TPlayer then
                return
            end
        end
        modutil:GetPalUtil():Teleport(APlayer, TPlayer:K2_GetActorLocation(), TPlayer:K2_GetActorRotation(), true, false)
        -- modutil:GetPalUtil():Teleport(Player.Pawn, MPlayer.Pawn:K2_GetActorLocation(), MPlayer.Pawn:K2_GetActorRotation(), true, false)
    end
end

function get_coords(Player)
    return Player.Pawn:K2_GetActorLocation()
end

function export_coords(Player)
    local Location = get_coords(Player)
    cords = Location.X .. "," .. Location.Y .. "," .. Location.Z
    modutil.log("Current Coordinates => " .. cords)
    modutil.clipboard(cords)
    modutil.info("Coordinates copied to clipboard")
end

function prep_coords(args)
    local search = args[2]
    local Location = {}

    -- check custom location (file)
    custom_data.load_locations()
    if custom_data.locations[search] then
        local targetLoc = custom_data.locations[search]
        local x, y, z = string.match(targetLoc, "([^,]+),([^,]+),([^,]+)")
        Location = {
            X = tonumber(x),
            Y = tonumber(y),
            Z = tonumber(z) + vertical_offset
        }
        return Location
    end

    -- try raw coords
    local x, y, z = string.match(args[2], "([^,]+),([^,]+),([^,]+)")
    if x and y and z then
        Location = {
            X = tonumber(x),
            Y = tonumber(y),
            Z = tonumber(z) + vertical_offset
        }
        return Location
    end

    -- try map coords
    local x, y = string.match(args[2], "([^,]+),([^,]+)")
    if x and y then
        local x_loc = tp_step * tonumber(y) - 123467.1611767
        local y_loc = tp_step * tonumber(x) + 157664.55791065
        modutil.log("Airdroping => " .. x .. "," .. y .. " => " .. x_loc .. "," .. y_loc .. "," .. tp_airdrop_altitude)
        Location = {
            X = tonumber(x_loc),
            Y = tonumber(y_loc),
            Z = tonumber(tp_airdrop_altitude)
        }
        return Location
    end

    return nil
end

local function loadLocation(Location)
    local Player = modutil.GetLocalPlayerController()
    if Location and Player and Player:IsValid() then
        local tp = Player.Transmitter.Player:RegisterRespawnLocation_ToServer(Player:GetPlayerUId(), Location)
        Player:TeleportToSafePoint_ToServer()
    end
end

function teleport(Player, args)
    local location = prep_coords(args)
    if not location then
        modutil.info("Invalid Coordinates")
        return
    end

    if args[3] == "airdrop" or args[3] == "a" then
        local tp = Player.Transmitter.Player:RegisterRespawnLocation_ToServer(Player:GetPlayerUId(), location)
        local PlayerHP = Player.Pawn.CharacterParameterComponent:GetHP()
        local PState = Player.PlayerState:RequestRespawn()
        Player.Pawn:ReviveCharacter_ToServer(PlayerHP)
        return
    end

    loadLocation(location)
end

return tp
