-- Hyprland entry point. See https://wiki.hypr.land/configuring/
-- Modules resolve relative to ~/.config/hypr.

-----------------
--- AUTOSTART ---
-----------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dunst")
    hl.exec_cmd("waypaper --restore")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("1password --silent")
    hl.exec_cmd("swayosd-server")
    hl.exec_cmd("qs")
    hl.exec_cmd("walker --gapplication-service")
    hl.exec_cmd("elephant")
end)

-----------------------------
--- ENVIRONMENT VARIABLES ---
-----------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("XCURSOR_SIZE", "24")
hl.env("SSH_AUTH_SOCK", "/home/daniel/.1password/agent.sock")

---------------
--- MODULES ---
---------------

-- Loads a machine-specific (gitignored) module, which may not exist yet on a
-- fresh checkout. Errors inside a module that does exist still propagate.
local function require_optional(module)
    local ok, err = pcall(require, module)
    if ok then
        return true
    end
    if not tostring(err):find("module '" .. module .. "' not found", 1, true) then
        error(err, 0)
    end
    return false
end

require("animations")
require("input")
require("keybinds")
require_optional("local.workspaces")

-- monitors.lua is written by nwg-displays.
if not require_optional("monitors") then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
end

require("windows")
