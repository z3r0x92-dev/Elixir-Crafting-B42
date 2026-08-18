std = "lua51"
codes = true
max_line_length = false
allow_defined_top = true

exclude_files = {
    ".git/**",
    "build/**",
    "dist/**",
    "release/**",
    "releases/**",
}

read_globals = {
    "ArrayList",
    "Events",
    "HaloTextHelper",
    "ISButton",
    "ISLabel",
    "ISPanel",
    "ISRichTextPanel",
    "ISScrollingListBox",
    "ISTextEntryBox",
    "ISUIElement",
    "JoypadState",
    "LuaEventManager",
    "ModData",
    "Perks",
    "SandboxVars",
    "UIFont",
    "UIManager",
    "ZombRand",
    "getCore",
    "getGameTime",
    "getOnlinePlayers",
    "getPlayer",
    "getPlayerByOnlineID",
    "getServerName",
    "getServerOptions",
    "getSoundManager",
    "getSpecificPlayer",
    "getText",
    "getTextManager",
    "getTimestamp",
    "getTimestampMs",
    "getWorld",
    "instanceof",
    "isAdmin",
    "isClient",
    "isDebugEnabled",
    "isServer",
    "sendClientCommand",
    "sendServerCommand",
}
