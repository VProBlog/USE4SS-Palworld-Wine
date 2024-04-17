local UEHelpers = require("UEHelpers")

local config = require("../config")

trigger_crouch = {}

trigger_crouch.trigger_callback = nil
trigger_crouch.hook_func = "/Script/Pal.PalShooterComponent:OnCrouch"

function trigger_crouch.register(callback_triggered)
    trigger_crouch.trigger_callback = callback_triggered
    trigger_crouch.crouchHook()
end

function trigger_crouch.crouchHook()
    local Function = StaticFindObject(trigger_crouch.hook_func)
    if not Function:IsValid() then
        modutil.log("Waiting for valid function to hook.")
        ExecuteWithDelay(3500, crouchHook)
        return
    end
	RegisterHook(trigger_crouch.hook_func, function(Component)
		trigger_crouch.process_crouch(Component)
	end)
    modutil.log("Hook successful!")
end

local rapid_crouch_count = 0
local last_crouch_time = 0
local crouch_threshold = 0.5
local crouch_requirement = config.crouch_trigger_requirement
function trigger_crouch.process_crouch(Component)
    local Triggered_ShooterComponent = Component:get()
    local My_ShooterComponent = UEHelpers:GetPlayerController():GetDefaultPlayerCharacter().ShooterComponent
    if Triggered_ShooterComponent:GetFullName() ~= My_ShooterComponent:GetFullName() then
        return
    end

    local time = os.time()
    if last_crouch_time ~= 0 and time - last_crouch_time < crouch_threshold then
        rapid_crouch_count = rapid_crouch_count + 1
    else
        rapid_crouch_count = 0
    end
    last_crouch_time = time
    if rapid_crouch_count >= crouch_requirement then
        rapid_crouch_count = 0
        trigger_crouch.trigger_callback()
    end
end

return trigger_crouch