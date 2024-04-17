local modutil = require("utils/modutil")

---@class UWBP_Title_WorldSelect_OverlayWindow_InputCode_C
local WidgetClass = nil

---@class UPalGameInstance
local GameInstance = nil

---@class UWidgetBlueprintLibrary
local WidgetBPL = nil

---@class APalPlayerController
local PlayerController = nil

local prompt = {}

function prompt.open(callback_user_input)
    prompt.spawnPopup(callback_user_input)
end

--global vars
local widgetref_full = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C"
local hookref_button_submit = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C:BndEvt__WBP_Title_WorldSelect_OverlayWindow_InputCode_WBP_Title_SettingsButton_K2Node_ComponentBoundEvent_0_OnClicked__DelegateSignature"
local hookref_button_close = "/Game/Pal/Blueprint/UI/UserInterface/Title/WBP_Title_WorldSelect_OverlayWindow_InputCode.WBP_Title_WorldSelect_OverlayWindow_InputCode_C:BndEvt__WBP_Buildup_Player_WBP_Menu_btn_Close_K2Node_ComponentBoundEvent_2_OnButtonClicked__DelegateSignature"
local hookref_menu_open = "/Game/Pal/Blueprint/UI/InGameMainMenu/WBP_InGameMainMenu.WBP_InGameMainMenu_C:Construct"
local hookref_menu_close = "/Game/Pal/Blueprint/UI/InGameMainMenu/WBP_InGameMainMenu.WBP_InGameMainMenu_C:Destruct"

---@class UWBP_Ingame_Chat_C Cached ChatWidget
local ChatWidget = nil

-- state management
local popup_open = false

local cmdPopup = nil

-- Container for all the popups so we don't need to call FindAllOf
local cmdPopups = {}

local hookIdpre_button_submit = nil
local hookIdpost_button_submit = nil

local hookIdpre_button_close = nil
local hookIdpost_button_close = nil

local hookIdpre_menu_open = nil
local hookIdpost_menu_open = nil

local hookIdpre_menu_close = nil
local hookIdpost_menu_close = nil

function prompt.trim(input)
    return input:gsub("^%s*(.-)%s*$", "%1")
end

function prompt.filter_ascii(input)
    local filtered = ""
    for i = 1, #input do
        local c = input:sub(i,i)
        local b = string.byte(c)
        if b >= 32 and b <= 126 then
            filtered = filtered .. c
        end
    end
    return filtered
end

function prompt.spawnPopup(callback_user_input)
    if popup_open then
        return
    end

    if ChatWidget == nil or not ChatWidget:IsValid() or not ChatWidget.InputVisualBox:IsValid()  then
        ---@class UWBP_Ingame_Chat_C
        local chatwtemp = FindAllOf("WBP_Ingame_Chat_C")
        for i = 1,#chatwtemp do
            if chatwtemp[i]:IsValid() and chatwtemp[i].InputVisualBox:IsValid() then
                ChatWidget = chatwtemp[i]
                break
            end
        end
    end
    if ChatWidget:IsValid() then
        if ChatWidget.InputVisualBox:IsVisible() then
            return
        end
    end
    popup_open = true
    modutil.log("Spawning Prompt...")

    if WidgetClass == nil or not WidgetClass:IsValid() then
        WidgetClass = StaticFindObject(widgetref_full)
    end
    
    if GameInstance == nil or not GameInstance:IsValid() then
        GameInstance = FindFirstOf("GameInstance")
    end

    if WidgetBPL == nil or not WidgetBPL:IsValid() then
        WidgetBPL = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
    end

    if PlayerController == nil or not PlayerController:IsValid() then
        PlayerController = modutil.GetLocalPlayerController()
    end

    cmdPopup = WidgetBPL:Create(GameInstance, WidgetClass, PlayerController)
    cmdPopup:AddToViewport(99)

    cmdPopup.BP_PalTextBlock_C_166:SetText(FText("Please enter a command"))
    cmdPopup.EditableTextBox_Code:SetText(FText(""))
    cmdPopup.Text_Title:SetText(FText(""))
    cmdPopup.Text_Caution:SetText(FText(""))
    cmdPopup.WBP_Title_SettingsButton.Text_Main:SetText(FText("Execute"))

    PlayerController.bShowMouseCursor = true
    cmdPopup.EditableTextBox_Code:SetKeyboardFocus()

    WidgetBPL:SetInputMode_GameAndUIEx(PlayerController, cmdPopup.EditableTextBox_Code, 0, false, false)

    table.insert(cmdPopups, cmdPopup)
    
    modutil.log("Prompt Spawned")

    hookIdpre_button_submit, hookIdpost_button_submit = RegisterHook(hookref_button_submit, function()
        if cmdPopup ~= nil and cmdPopup:IsValid() then
            local input = cmdPopup.EditableTextBox_Code:GetText():ToString()
            modutil.log("Raw Input: " .. tostring(input))
            input = prompt.trim(prompt.filter_ascii(input))
            modutil.log("Clean Input: " .. tostring(input))
    
            prompt.destroyPopup()

            WidgetBPL:SetInputMode_GameOnly(PlayerController, false)
    
            callback_user_input(input)
        else
            cmdPopup = nil
        end
    end)

    hookIdpre_button_close, hookIdpost_button_close = RegisterHook(hookref_button_close, function()
        prompt.destroyPopup()

        WidgetBPL:SetInputMode_GameOnly(PlayerController, false)
    end)

    hookIdpre_menu_open, hookIdpost_menu_open = RegisterHook(hookref_menu_open, function()
        prompt.destroyPopup()

        WidgetBPL:SetInputMode_GameOnly(PlayerController, false)
    end)

    hookIdpre_menu_close, hookIdpost_menu_close = RegisterHook(hookref_menu_close, function()
        prompt.destroyPopup()

        WidgetBPL:SetInputMode_GameOnly(PlayerController, false)
    end)

    modutil.log("Prompt Hooks Successful")
end

function prompt.destroyPopup()
    modutil.log("Destroying Prompt...")

    do
        for _, popup in ipairs(cmdPopups) do
            if popup:IsValid() then
                popup:RemoveFromViewport()
            end
        end
        cmdPopups = {}
        cmdPopup = nil
    end

    modutil.log("Prompt Destroyed")

    if PlayerController == nil or not PlayerController:IsValid() then
        PlayerController = modutil.GetLocalPlayerController()
    end
    
    PlayerController:ClientForceGarbageCollection()
    PlayerController.bShowMouseCursor = false

    modutil.log("Character Control Adjusted")
    
    UnregisterHook(hookref_button_submit, hookIdpre_button_submit, hookIdpost_button_submit)
    UnregisterHook(hookref_button_close, hookIdpre_button_close, hookIdpost_button_close)
    UnregisterHook(hookref_menu_open, hookIdpre_menu_open, hookIdpost_menu_open)
    UnregisterHook(hookref_menu_close, hookIdpre_menu_close, hookIdpost_menu_close)
    prompt.nilVars()

    modutil.log("Prompt Hooks Removed")
    popup_open = false
end

function prompt.nilVars()
    modutil.log("Clearing globals")
    cmdPopup = nil

    hookIdpre_button_submit = nil
    hookIdpost_button_submit = nil

    hookIdpre_button_close = nil
    hookIdpost_button_close = nil

    hookIdpre_menu_open = nil
    hookIdpost_menu_open = nil

    hookIdpre_menu_close = nil
    hookIdpost_menu_close = nil
end

return prompt
