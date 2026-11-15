-- See https://wiki.hypr.land/configuring/core/animations/
hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1.0 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
-- Workspaces slide so the three-finger swipe follows the fingers (GNOME-style).
-- Keyboard switches skip the animation via M.instant_workspace() below.
local workspace_anims = {
    { leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" },
    { leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "slide" },
    { leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "slide" },
}
for _, spec in ipairs(workspace_anims) do hl.animation(spec) end

local M = {}

-- Wrap a dispatcher so it runs with workspace animations switched off, i.e. the
-- workspace changes instantly. Used for SUPER+<number>.
--
-- The animation starts on the next frame, not inside dispatch(), so the
-- animations are re-enabled from a timer once the switch has settled. The
-- generation counter keeps an older timer from re-enabling them in the middle
-- of a newer, rapid-fire switch.
local REENABLE_MS = 300 -- longer than the slowest workspace animation
local generation = 0

local function set_workspace_anims(enabled)
    for _, spec in ipairs(workspace_anims) do
        hl.animation(enabled and spec or { leaf = spec.leaf, enabled = false })
    end
end

function M.instant_workspace(dispatcher)
    return function()
        generation = generation + 1
        local mine = generation
        set_workspace_anims(false)
        hl.dispatch(dispatcher)
        hl.timer(function()
            if mine == generation then set_workspace_anims(true) end
        end, { timeout = REENABLE_MS, type = "oneshot" })
    end
end

return M
