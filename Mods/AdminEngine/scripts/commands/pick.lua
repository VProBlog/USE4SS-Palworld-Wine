local modutil = require("utils/modutil")
local config = require("../config")
local UEHelpers = require("UEHelpers")

pick = {}

-- router
function pick.route_cmd(args)
    args[2] = string.lower(args[2])
    if args[2] == "common" then
        scan_pickup_items("PalMapObjectPickupItemOnLevelModel", true) -- skill fruit, stone, wood, etc
        scan_pickup_items("PalMapObjectDropItemModel", true) -- mushrooms, berries, souls, pal_drops, etc
    elseif args[2] == "all" then
        scan_pickup_items("PalMapObjectPickupItemOnLevelModel", true) -- skill fruit, stone, wood, etc
        scan_pickup_items("PalMapObjectDropItemModel", true) -- mushrooms, berries, souls, pal_drops, etc
        scan_pickup_items("PalMapObjectPalEggModel", true)
    elseif args[2] == "eggs" then
        scan_pickup_items("PalMapObjectPalEggModel", true)
    elseif args[2] == "treasure" then
        modutil.warn("treasure is currently disabled")
        -- temporarily disabled while we research
        scan_pickup_treasure(true)
    -- elseif args[2] == "journals" then
    --     -- -- temporarily disabled while we research
    elseif args[2] == "relic" or  args[2] == "relics" then
        source_and_pick_relic()
    -- elseif args[2] == "scan" then
    --     scan_pickup_items("", false)
    elseif args[2] == "journals" or args[2] == "journal" then
        source_and_pick_journal()
    elseif args[2] == "travelpoints" or args[2] == "tp" then
        UnlockAllTravelPoints()
    elseif args[2] == "technology" or args[2] == "tech" then
        UnlockAllTechnologies()
    else
        modutil.warn("Unknown Pick Command")
    end
end

-- processors
function scan_pickup_items(searchKey, bPickup)
    local pickableItems = FindAllOf("PalMapObjectPickableItemModelBase")
    for k, item in pairs(pickableItems) do
        if item:GetFullName():find(searchKey) then
            if bPickup then
                item:RequestPickup()
            else
                modutil.log("Found: " .. tostring(item:GetFullName()))
            end
        end
    end
end

function UnlockAllTravelPoints()
    local PlayerController = UEHelpers:GetPlayerController()
    local Keys = {
        "6E03F8464BAD9E458B843AA30BE1CC8F","DDBBFFAF43D9219AE68DF98744DF0831","603ED0CD4CFB9AFDC9E11F805594CCE5","6282FE1E4029EDCDB14135AA4C171E4C","9FBB93D84811BE424A37C391DBFBB476","979BF2044C8E8FE559B598A95A83EDE3","923B781345D2AB7ECED6BABD6E97ECE8",
        "16C7164C43E2B96BEDCC6696E2E592F7","D27AFCAD472164F000D33A8D8B61FE8B","41727100495D21DC905D309C53989914","6DB6B7B2431CA2EFFFC88EB45805BA6A","74270C2F45B8DCA66B6A1FAAA911D024","DF9FB9CB41B43052A9C74FA79A826A50","8CA5E9774FF1BBC1156ABCA09E616480",
        "15314BE94E2FB8D018D5749BE9A318F0","79C561B747335A7A0A8FBF9FAE280E62","23B9E99C4A454B99220AF7B4A58FD8DE","A1BC65AA445619EF338E0388BC010648","BF8B123244ADB794A06EA8A10503FBDD","F8DF603B4C750B37D943C9AF6A911946","596996B948716D3FD2283C8B5C6E829C",
        "28D514E74B51FD9EB078A891DB0787C2","ACAE5FB04D48DE4197443E9C0993086B","4D2F204549AB656CA1EA4B8E39C484F3","1BDEABA240B1699541C17F83E59E61DF","2BC5E46049E69D3549CFB58948BE3288","91DAC6F34D2A9FD7F01471B5166C6C02","41E36D9A4B2BA79A3AD1B7B83B16F77D",
        "76B000914943BADDC56BCFBAE2BF051E","DC0ECF9241B4410C59EE619F56D1106A","71C4B2B2407F2BBBD77572A20C7FF0F5","EC94023A4CA571FF0FD19E90944F4231","2A2B744B41AC79964DAE6B89CAC51FC3","E0819EFB41581AEAC3A029B0EE2FE195","22095BFA48A46172F8D154B2EBEB7493",
        "7C5E91514F6E84B0C1DEFFB52C7C4DBA","AECFED0D41AFEE11F30B4F9687BC3243","2EC07ACC4505CB726DE38A84246CA999","F8E5CB8143F4FA2F6213E6B454569F87","5F426B49469368B0C131D3A6DB8F7831","A277AE6341EF40D84D711EA52303353F","6231802D40C81C00445379AE238D9F90",
        "F6C005A14B38FE0B57F1C7869FD899CB","7170881D44249E90902F728E240493AF","3E8E504B4A3975FD3862E1BC85A5D4F6","B001852C491FF5E70C4747BFF9972924","2DE1702048A1D4A82126168C49BE51A9","E88379634CB5B6117DA2E7B8810BFE0A","3697999C458BF8A3C7973382969FBDF9",
        "65B10BB14ABDA9C2109167B21901D195","4669582D4081BF550AFB66A05D043A3D","FE90632845114C7FBFA4669D071E285F","5970E8E648D2A83AFDFF7C9151D9BEF5","B639B7ED4EE18A7AA09BA189EA703032","099440764403D1508D9BADADF4848697","B44AA24445864494E7569597ACCAEFC6",
        "3A0F123947BE045BC415C6B061A5285A","F382ADAE4259150BF994FF873ECF242B", "866881DB443444AA7F4E7C8E5DCDAA29", "01ACCA6E4BDAA68220821FB05AB54E4D", "75BD9923489E2A4EBCED5A81175D5928", "513E166044565A0BD3360F94142577E8"
    }
    for i = 1,#Keys do
        PlayerController.Pawn.PlayerState:RequestUnlockFastTravelPoint_ToServer(FName(Keys[i]))
    end
    modutil.warn(string.format("%d TravelPoints have been unlocked",#Keys))
end

function UnlockAllTechnologies()
    modutil.warn("Technologies are not yet implemented")
end

-- -- temporarily disabled while we research
-- function scan_pickup_treasure(bPickup)
--     local pickableItems = FindAllOf("PalMapObjectTreasureBoxModel") -- try the non model version
--     local playerId = modutil.GetPlayerID()
--     for k, item in pairs(pickableItems) do
--         local grade = item:GetTreasureGradeType()
--         if bPickup then
--             modutil.log("Found: [" .. tostring(grade) .. "] " .. tostring(item:GetFullName()))
--             --item.bOpened = true
--             item:RequestOpen_ServerInternal(playerId)
--             --item:TriggerOpen()
--         else
--             modutil.log("Found: " .. tostring(item:GetFullName()))
--         end
--     end
-- end

function source_and_pick_relic()
    local counter = 0
    PlayerController = UEHelpers:GetPlayerController()
    local pickableItems = FindAllOf("PalLevelObjectRelic") -- PalLevelObjectObtainable
    for k, item in pairs(pickableItems) do
        if not item.bPickedInClient then
            counter = counter + 1
            PlayerController.Pawn.PlayerState:RequestObtainLevelObject_ToServer(item)
        end
    end
    modutil.warn(string.format("%d relics have been picked",counter))
end

function source_and_pick_journal()
    local counter = 0
    PlayerController = UEHelpers:GetPlayerController()
    local pickableItems = FindAllOf("PalLevelObjectNote") -- PalLevelObjectObtainable
    for k, item in pairs(pickableItems) do
        if not item.bPickedInClient then
            counter = counter + 1
            PlayerController.Pawn.PlayerState:RequestObtainLevelObject_ToServer(item)
        end
    end
    modutil.warn(string.format("%d journals have been picked",counter))
end
return pick