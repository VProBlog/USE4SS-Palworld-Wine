local UEHelpers = require("UEHelpers")

local config = require("config")
local modutil = require("utils/modutil")
local prompt = require("utils/prompt")
local trigger_crouch = require("utils/trigger_crouch")
local json = require("libs/json")
local gamelog = require("utils/gamelog")

local mutate = require("commands/mutate")
local palinfo = require("commands/palinfo")
local give = require("commands/give")
local tp = require("commands/tp")
local pick = require("commands/pick")
local settime = require("commands/settime")




--[[

        Instance types

            Human (w/ or w/o Admin) [Co-Op Client / Dedicated Client]
                VulnCmd => Local => OnReceivedChat
                VulnCmd => Local => CustomInput
            
            Human w/ Host [Singleplayer / Co-Op Host]
                HostCmd => Local => OnReceivedChat
                VulnCmd => Local => OnReceivedChat
                VulnCmd => Local => CustomInput

            Human w/ Host w/ Multiplayer [Co-Op Host]
                HostCmd => Remote => EnterChat_Receive

            Server w/ Host [Dedicated Host]
                HostCmd => Remote => EnterChat_Receive
                VulnCmd => Remote => EnterChat_Receive

        Default => Enable OnReceivedChat (local, enforce sender)
        IsHost => Enable EnterChat_Receive (remote)

]]

modutil.hello()

IsServer = false

HookData = {}

SetupComplete_General = false
SetupComplete_Local = false
SetupComplete_Remote = false
EnableCoOpMode = false

myuid = nil
SERVER_UID = "server"

-- Various Helper Functions
function clear_setup_flags()
    SetupComplete_General = false
    SetupComplete_Local = false
    SetupComplete_Remote = false
    EnableCoOpMode = false
end

function hook_data_collect(prepostIds)
    local preid = prepostIds[1]
    local postid = prepostIds[2]
    table.insert(HookData, {preid, postid})
end

function hook_data_removeall()
    for k, v in pairs(HookData) do
        success, results = pcall(UnregisterHook, v[1], v[2])
        if success then
            modutil.log("Unregistered Hook: " .. tostring(v[1]) .. " => " .. tostring(v[2]))
        else
            modutil.log("Failed to Unregister Hook: " .. tostring(v[1]) .. " => " .. tostring(v[2]))
        end
    end
    HookData = {}
end

function setup_myuid()
    myuid = modutil.GuidToString(modutil.GetLocalPlayerController().GetPlayerUId())
end

function request_uid()
    success, results = pcall(setup_myuid)
    if not success then
        myuid = SERVER_UID
    end
    modutil.log("myuid: " .. tostring(myuid))
end

function validate_uid(PlayerController)
    return modutil.GuidToString(PlayerController:GetPlayerUId()) == myuid
end

function forward_command_to_server(PlayerController,user_input)
    PlayerController:Debug_CheatCommand_ToServer(user_input.."tbh idk what should i add for a flag so im just gonna leave this here as a flag :D")
end

function kill_tutorial()
    local Tutorials = FindAllOf("WBP_IngameMenu_Task_Tutorial_C")
    for k, v in pairs(Tutorials) do
        v:RemoveFromViewport()
    end
end



function DropInv(PlayerController)
    local PlayerCharacter = PlayerController.Pawn
    local PlayerState = PlayerController.PlayerState
    local PalUtil = modutil:GetPalUtil()
    local DeathManager = PalUtil:GetDeathPenaltyManager(PlayerController)
    DeathManager:DropDeathPenaltyChest(PlayerController.Pawn)
    local tp = PlayerController.Transmitter.Player:RegisterRespawnLocation_ToServer(PlayerController:GetPlayerUId(), PlayerState.PawnPrivate:K2_GetActorLocation())
    local PlayerHP = PlayerController.Pawn.CharacterParameterComponent:GetHP()
    local PState = PlayerController.PlayerState:RequestRespawn()
    PlayerController.Pawn:ReviveCharacter_ToServer(PlayerHP)
end

-- Command Routing
function process_command(PlayerState, args)
    if(PlayerState.ChatCounter ~= nil) then PlayerState.ChatCounter = 0 end
    local PlayerController = PlayerState:GetPlayerController()
    local PlayerCharacter = PlayerController.Pawn
    modutil.log("Raw Command: " .. table.concat(args, " "))
    if args[1] == "mutate" then
        mutate.route_cmd(PlayerState, args)
    elseif args[1] == "palinfo" then
        palinfo.route_cmd(PlayerState, args)
    elseif args[1] == "drop" then
        DropInv(PlayerController)
    elseif args[1] == "give" then
        give.route_cmd(PlayerState, args)
    elseif args[1] == "gift" then
        give.route_cmd(PlayerState, args)
    elseif args[1] == "tp" then
        tp.route_cmd(PlayerState:GetPlayerController(), args)
    elseif args[1] == "pick" then
        pick.route_cmd(args)
    elseif args[1] == "time" then
        settime.route_cmd(args)
    elseif args[1] == "tutorial" then
        kill_tutorial()
    elseif args[1] == "noclip" then
        local isFlying = PlayerCharacter.bSpectatorMode
        PlayerCharacter:SetSpectatorMode(not isFlying)
        PlayerCharacter.CharacterMovement.RunSpeed_Default = isFlying and 350 or 10000 -- idk doesnt seem to work ?
    elseif args[1] == "enablecoop" then
        EnableCoOpMode = true
        modutil.info("Co-Op Mode Enabled")
        SetupModes()
    else
        modutil.log("Unknown Command: " .. args[1])
    end
end

-- Command Processors
function ProcessCommandRoute_Local(PlayerState, user_input, pipe_to_server)
    if modutil.possible_command(user_input) then
        if #user_input <= 20 or pipe_to_server then
            args = modutil.parse_command(user_input:sub(2))
            --if (modutil.requires_host_command_context(args[1]) and HasHostContext) or not modutil.requires_host_command_context(args[1]) then
            if true then
                process_command(PlayerState, args)
                if pipe_to_server then
                    forward_command_to_server(PlayerState:GetPlayerController(), user_input)
                end
            else
                modutil.log("Warning, command requires host context.")
            end
        else
            modutil.warn("Command too long, please use the command prompt. (default F5)")
        end
    end
end

function ProcessCommandRoute_Remote(PlayerState, user_input, promptW)
    PlayerState.ChatCounter = 0
    if #user_input > 20 and promptW ~= true then modutil.warn("Command too long, please use the command prompt. (default F5)") return end 
    if modutil.possible_command(user_input) then
        args = modutil.parse_command(user_input:sub(2))
        if modutil.requires_host_command_context(args[1]) then
            if modutil.qualified_remote_command(PlayerState, args[1]) or EnableCoOpMode then
                    process_command(PlayerState, args)

            else
                if((args[1] == "tp" and args[2] and string.find(args[2],",") or not args[2])) then return end
                modutil.log("Player '" .. tostring(PlayerState.PlayerNamePrivate:ToString()) .. "' is not qualified to command: " .. args[1])
                --modutil.message_player(PlayerState, "You must be an admin to access this command")
            end
        end
    end
end

-- Hook Processors
function HookCommandRoute_Local(context, message)
    local received = message:get()
    local user_input = received.Message:ToString()
    local SenderPlayerUId = modutil.GuidToString(received.SenderPlayerUId)
    -- verify that we are setup to process commands
    if myuid == SERVER_UID or myuid == "0:0:0:0" then
        request_uid()
    end

    -- verify that I only process my own commands
    if SenderPlayerUId ~= myuid then
        return
    end
    local PlayerState = modutil.GetLocalPlayerController().PlayerState

    ProcessCommandRoute_Local(PlayerState, user_input, false)
end

function HookCommandRoute_Remote(context, chatmessage)
    local user_input = chatmessage:get().Message:ToString()
    local PlayerState = context:get()

    ProcessCommandRoute_Remote(PlayerState, user_input)
end

function StarterKit(context)
    local PlayerState = context:get()
    --print(tostring(context:get().PlayerNamePrivate:ToString()))
    give.spawnItemSingle(PlayerState,"StarterKit",true)
end

function HookCommandRoute_RemotePipe(context, chatmessage)
    local user_input = chatmessage:get():ToString()
    local PlayerController = context:get()
    local PlayerState = PlayerController.PlayerState
    local flag = "tbh idk what should i add for a flag so im just gonna leave this here as a flag :D"
    if not string.find(user_input,flag) then return end
    local user_input = string.gsub( user_input,flag,"")
    ProcessCommandRoute_Remote(PlayerState, user_input, true)
end

function SpinLoadGameWorld()
    local PlayerController = modutil.GetLocalPlayerController()
    if PlayerController == nil then
        modutil.log("Waiting for PlayerController to be available.")
        ExecuteWithDelay(1000, SpinLoadGameWorld)
        return
    end
    SetupModes()
    ExecuteWithDelay(5000, modutil.hello_enterworld)
end

function HookPlayerJoinedWorld(context)
    modutil.log("Joining Game World.")
    SpinLoadGameWorld()
end

function HookPlayerLeftWorld(context)
    if validate_uid(context) then
        hook_data_removeall()
        clear_setup_flags()
        modutil.log("Leaving Game World.")
    end
end

-- Stealth Prompt Callbacks
function callback_popup_exited(user_input)
    modutil.log("callback_popup_exited")
    ProcessCommandRoute_Local(modutil.GetLocalPlayerController().PlayerState, user_input, true)
end
function callback_crouch_triggered()
    modutil.log("callback_crouch_triggered")
    prompt.open(callback_popup_exited)
end

-- Hook Registration
function RegisterStealthPrompts()
    if config.enable_trigger_crouch then
        trigger_crouch.register(callback_crouch_triggered)
    end
    if config.enable_trigger_keybind then
        preid, postid = RegisterKeyBind(config.keybind_prompt, function()
            modutil.log("keybind_trigger")
            prompt.open(callback_popup_exited)
        end)
        hook_data_collect({preid, postid})
        modutil.log("Registered Trigger: Keybind => " .. tostring(config.keybind_prompt))
    end
end

function RegisterCommandRoute_Remote()
    preid, postid = RegisterHook("/Script/Pal.PalPlayerState:EnterChat_Receive", HookCommandRoute_Remote)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled Remote Command Routes")
end

function RegisterCommandRoute_RemotePipe()
    preid, postid = RegisterHook("/Script/Pal.PalPlayerController:Debug_CheatCommand_ToServer", HookCommandRoute_RemotePipe)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled Remote Command Route Pipe")
end

function RegisterCommandRoute_Local()
    preid, postid = RegisterHook("/Script/Pal.PalUIChat:OnReceivedChat", HookCommandRoute_Local)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled Local Command Routes")
end

function RegisterStarterKit()
    preid, postid = RegisterHook("/Script/Pal.PalPlayerState:NotifyCompleteInitSelectMap_ToServer", StarterKit)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled StarterKit Hook")
end

function RegisterJoinWorld()
    preid, postid = RegisterHook("/Script/Engine.PlayerController:ClientRestart", HookPlayerJoinedWorld)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled JoinWorld")
end

function RegisterLeaveWorld()
    preid, postid = RegisterHook("/Script/Pal.PalPlayerController:OnDestroyPawn", HookPlayerLeftWorld)
    hook_data_collect({preid, postid})
    modutil.log("Successfully Enabled LeaveWorld")
end

-- Entry point for various hooks and modes depending on the context
function SetupModes()
    local PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    if PalUtilities:IsValid() then 
    IsServer = PalUtilities:IsDedicatedServer(PalUtilities)
    else
        IsServer = false
    end

    request_uid()

    if IsServer or EnableCoOpMode then
        modutil.log("Detected Server Mode")
        if not SetupComplete_Remote then
            SetupComplete_Remote = true

            -- setup remote command routes
            local success, result = pcall(RegisterCommandRoute_Remote)
            if not success then
                modutil.log("Failed to hook remote route, unable to process remote commands.")
            end
            local success, result = pcall(RegisterCommandRoute_RemotePipe)
            if not success then
                modutil.log("Failed to hook remote route, unable to process remote pipe commands.")
            end
            if config.StarterKit then
                local success, result = pcall(RegisterStarterKit)
                if not success then
                    modutil.log("Failed to hook StarterKit.")
                end
            end
        end
    else
        modutil.log("Detected Client Mode")
    end

    if not SetupComplete_Local and myuid ~= SERVER_UID then
        SetupComplete_Local = true

        -- setup local command routes
        local success, result = pcall(RegisterCommandRoute_Local)
        if not success then
            modutil.log("Failed to hook local routes. Local chat commands disabled.")
        end

        -- setup stealth prompts
        local success, result = pcall(RegisterStealthPrompts)
        if not success then
            modutil.log("Failed to hook stealth prompts. Local keybind and crouch disabled.")
        end
    end

    if not SetupComplete_General then
        SetupComplete_General = true

        -- setup joining world
        local success, results = pcall(RegisterJoinWorld)
        if not success then
            modutil.log("Failed to Register Hook => ClientRestart")
        end

        -- setup leaving world
        local success, results = pcall(RegisterLeaveWorld)
        if not success then
            modutil.log("Failed to Register Hook => OnDestroyPawn")
        end
    end 
end

---------------------------------------Better-chat-Testing-----------------------------------
local BetterChatCore = nil
local IsSetupDone = false

function BetterChatCommandHandler(Context, Caller, Command, CommandArgs)
    local Caller, Command, CommandArgs = Caller:get(), string.gsub(Command:get():ToString(), "/", ""), CommandArgs:get()
    if(not tTable.contains(config.all_commands,Command)) then return end

    local CommandArgs,InputInString = modutil.TArryToString(CommandArgs)
    local InputInString = string.gsub(InputInString, "%s", Command.." ", 1)
    table.insert( CommandArgs,1,Command )

    local PlayerState = Caller.PlayerState
    if not PlayerState and not PlayerState:IsValid() then return end

    process_command(PlayerState, CommandArgs)
    if config.command_requires_host_context[Command] then
        --forward_command_to_server(PlayerState:GetPlayerController(), InputInString) -- OnCustomCommand event gets triggerd on server-side only if ur on a server doesnt matter if the mod installed on client or server side
    end

end


function BetterChatInit(Context)
    if IsSetupDone then return end
    
    IsSetupDone = true
    BetterChatCore = Context:get()

    if BetterChatCore and BetterChatCore:IsValid() then
        preid, postid = RegisterHook("/Game/Mods/BetterChat/BP/BP_BetterChatCore.BP_BetterChatCore_C:OnCustomCommand", BetterChatCommandHandler)
        hook_data_collect({preid, postid})
        modutil.log("Successfully hooked BetterChatCommandHandler")

        for i = 1,#config.all_commands do
            BetterChatCore:RegisterCommand(config.all_commands[i])
        end
    end
end

function SetupChatModes()
    preid, postid = RegisterCustomEvent("BetterChat_Reload", BetterChatInit)
    hook_data_collect({preid, postid})
    modutil.log("Successfully hooked BetterChat_Relod")

    preid, postid = RegisterCustomEvent("BetterChat_BeginPlay", BetterChatInit)
    hook_data_collect({preid, postid})
    modutil.log("Successfully hooked BetterChat_BeginPlay")
end





------------------------------------------------------------------------------------------
function SpinWaitPalUtil()
    local PalUtilities = StaticFindObject("/Script/Pal.Default__PalUtility")
    if not PalUtilities:IsValid() then
        ExecuteWithDelay(1000, SpinWaitPalUtil)
        return
    else
    SetupModes()
    --SetupChatModes()
    end
end
SpinWaitPalUtil()





