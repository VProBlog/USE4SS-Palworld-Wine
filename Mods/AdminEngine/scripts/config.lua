config = {}

-- The name/version of the mod
config.name = "AdminEngine"
config.version = "2.5~beta2"

-- Enable/Disable printing messages
config.print_console_logs = true
config.show_ingame_info = true
config.show_ingame_warnings = true

-- Trigger the stealth command prompt by rapidly crouching
config.enable_trigger_crouch = true
config.crouch_trigger_requirement = 5

-- Trigger the stealth command prompt by pressing a keybind
config.enable_trigger_keybind = true
config.keybind_prompt = Key.F5

-- Enable the Starter Kit for all your new players on the server
-- This kit can be modified in the kits.json file
config.StarterKit = false


-- Specify any commands that require that a user be an admin to execute (multiplayer only)
-- For Co-Op, you can set these to false to allow all players to use the commands
config.remote_command_admin_required = {
    ["mutate"] = true,
    ["time"] = true,
    ['gift'] = true,
    ['tp'] = true, -- this will only limit tp player to someone clients still can teleport to cords
    -- you have no control over the !give, !pick, or !tp commands
    -- until Palworld patches their vulnerable client-side code
    -- ["give"] = true,
    -- ["pick"] = true,
    -- ["tp"] = true,
    -- ["palinfo"] = false,
}

-------------------------------------
-- DO NOT CHANGE ANYTHING BELOW HERE
-------------------------------------

-- This table is for efining execution context
-- Changing this will not magically grant a command the ability to execute
-- Changing this will fuck your context'd calls (ie. pick interlace)
config.command_requires_host_context = {
    ["mutate"] = true,
    ["time"] = true,
    ['gift'] = true,
    ['tp'] = true,
    -- ["give"] = false,
    -- ["pick"] = false,
    -- ["tp"] = false,
    -- ["palinfo"] = false,

}

config.all_commands = {
    "mutate",
    "time",
    "gift",
    "tptm",
    "tptp",
    "give",
    "pick",
    "tp",
    "palinfo",
}

-- Prefix required to trigger a command
config.command_header = "!"

return config