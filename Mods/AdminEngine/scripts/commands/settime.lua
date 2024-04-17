settime = {}

function settime.route_cmd(args)
    local TimeManager = FindFirstOf("PalTimeManager")
    local Hour = tonumber(args[2])
    if Hour ~= nil then
        if type(Hour) == "number" then
            TimeManager:SetGameTime_FixDay(Hour)
        end
    end
end

return settime