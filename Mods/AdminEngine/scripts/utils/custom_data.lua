local json = require("../libs/json")

custom_data = {}

custom_data.save_location = ".\\Mods\\AdminEngine_SaveData"
custom_data.locations_save = ".\\Mods\\AdminEngine_SaveData\\locations.json"
custom_data.kits_save = ".\\Mods\\AdminEngine_SaveData\\kits.json"

custom_data.default_locations = '{"start":"-359890.14417295,268715.51893071,8446.5243362359","sanct1":"-457802.20012442,197136.42267675,15444.275994158","sanct2":"-174743.09060884,-153863.08303514,15451.732724161","sanct3":"168641.79577948,464296.09606568,15448.875068955"}'
custom_data.default_kits = '{"palbox": "wood:8 stone:3 pal_crystal_s","seeds": "BerrySeeds:3 LettuceSeeds:3 TomatoSeeds:3 WheatSeeds:3","StarterKit": "Accessory_CoolResist_2:1 Accessory_HeatResist_2:1 Axe_Tier_01:1 Pickaxe_Tier_01:1 GrapplingGun_2:1 HandGun_Default:1 HandgunBullet:5000 CopperArmorHeat:1 CopperHelmet:1 Shield_02:1 Glider_Good:1 Bandage_Normal:10 Torch:1 Lantern:1 BakedMeat_SheepBall:10 PalSphere_Legend:100"}'

custom_data.locations = {}
custom_data.kits = {}

function custom_data.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    else
        return false
    end
end

function custom_data.setup_savedata()
    -- create folder if it doesn't exist
    if not os.rename(custom_data.save_location, custom_data.save_location) then
        os.execute("mkdir " .. custom_data.save_location)
    end
    
    -- setup locations.json
    if not custom_data.file_exists(custom_data.locations_save) then
        local file = io.open(custom_data.locations_save, "w")
        if file then
            file:write(json.beautify(custom_data.default_locations))
            file:close()
        end
    end
    
    -- setup kits.json
    if not custom_data.file_exists(custom_data.kits_save) then
        local file = io.open(custom_data.kits_save, "w")
        if file then
            file:write(json.beautify(custom_data.default_kits))
            file:close()
        end
    end
end
success, results = pcall(custom_data.setup_savedata)

-- getters
function custom_data.get_locations()
    custom_data.load_locations()
    return custom_data.locations
end
function custom_data.get_kits()
    custom_data.load_locations()
    return custom_data.locations
end

-- locations
function custom_data.load_locations()
    local file = io.open(custom_data.locations_save, "r")
    if file then
        local data = file:read("*a")
        file:close()
        custom_data.locations = json.decode(data)
    end
end
success, results = pcall(custom_data.load_locations)
function custom_data.save_locations()
    local file = io.open(custom_data.locations_save, "w")
    if file then
        file:write(json.beautify(json.encode(custom_data.locations)))
        file:close()
    end
end

-- kits
function custom_data.load_kits()
    local file = io.open(custom_data.kits_save, "r")
    if file then
        local data = file:read("*a")
        file:close()
        custom_data.kits = json.decode(data)
    end
end
success, results = pcall(custom_data.load_kits)
function custom_data.save_kits()
    local file = io.open(custom_data.kits_save, "w")
    if file then
        file:write(json.beautify(json.encode(custom_data.kits)))
        file:close()
    end
end

return custom_data