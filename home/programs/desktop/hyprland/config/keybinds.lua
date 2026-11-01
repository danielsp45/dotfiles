-- See https://wiki.hypr.land/configuring/core/binds/

local terminal    = "ghostty"
local fileManager = "nemo"
local menu        = "walker"
local browser     = "uwsm app -- chromium --new-window --ozone-platform=wayland"
local webapp      = browser .. " --app"

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local bin     = "~/.local/share/config/bin/"

local function mod(keys)
    return mainMod .. " + " .. keys
end

local function exec(cmd, rules)
    return hl.dsp.exec_cmd(cmd, rules)
end

hl.bind(mod("RETURN"),          exec(terminal))
hl.bind(mod("W"),               hl.dsp.window.close())
hl.bind(mod("F"),               hl.dsp.window.fullscreen())
hl.bind(mod("SPACE"),           exec(menu))
hl.bind(mod("backspace"),       exec(bin .. "lock-screen"))
hl.bind(mod("SHIFT + SPACE"),   exec(bin .. "menu"))
hl.bind(mod("SHIFT + P"),       exec(bin .. "cmd-screenshot"))
hl.bind(mod("SHIFT + U"),       exec(bin .. "dispatch-nixos-update"))
hl.bind(mod("SHIFT + F"),       hl.dsp.window.float({ action = "toggle" }))

hl.bind(mod("SHIFT + M"),       hl.dsp.workspace.move({ monitor = "+1" }))

-- Move focus with mainMod + H/J/K/L
hl.bind(mod("H"), hl.dsp.focus({ direction = "left" }))
hl.bind(mod("L"), hl.dsp.focus({ direction = "right" }))
hl.bind(mod("K"), hl.dsp.focus({ direction = "up" }))
hl.bind(mod("J"), hl.dsp.focus({ direction = "down" }))

-- Applications
local function app(keys, description, cmd, rules)
    hl.bind(mod(keys), exec(cmd, rules), { description = description })
end

app("A",             "Claude",           webapp .. '="https://claude.ai"')
app("B",             "Zen",              "uwsm app -- " .. browser)
app("M",             "Music",            "uwsm app -- spotify")
app("C",             "Calendar",         webapp .. '="https://calendar.google.com/calendar"')
app("N",             "Notion",           webapp .. '="https://www.notion.so"')
app("D",             "Discord",          "uwsm app -- discord")
app("T",             "Btop",             terminal .. " -e btop")
app("equal",         "Fend calculator",  terminal .. " -e fend", { float = true, size = "500 300", center = true })
app("SHIFT + equal", "Math (walker)",    'walker && sleep 0.1 && wtype "="')
app("E",             "Unicode/Emoji (walker)", "walker -m symbols")

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = tostring(i % 10) -- workspace 10 maps to key 0
    hl.bind(mod(key),            hl.dsp.focus({ workspace = i }))
    hl.bind(mod("SHIFT + " .. key), hl.dsp.window.move({ workspace = i }))
end

-- H J K L = left / down / up / right
local resize_step = 30 -- pixels (floating) / ratio step (tiled)
hl.bind(mod("CTRL + H"), hl.dsp.window.resize({ x = -resize_step, y = 0, relative = true }))
hl.bind(mod("CTRL + L"), hl.dsp.window.resize({ x = resize_step, y = 0, relative = true }))
hl.bind(mod("CTRL + K"), hl.dsp.window.resize({ x = 0, y = -resize_step, relative = true }))
hl.bind(mod("CTRL + J"), hl.dsp.window.resize({ x = 0, y = resize_step, relative = true }))

-- Special workspace (scratchpad)
hl.bind(mod("S"),         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod("SHIFT + S"), hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mod("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mod("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod("mouse:273"), hl.dsp.window.resize(), { mouse = true })

hl.bind(mod("SHIFT + H"), hl.dsp.window.move({ direction = "left" }))
hl.bind(mod("SHIFT + L"), hl.dsp.window.move({ direction = "right" }))
hl.bind(mod("SHIFT + K"), hl.dsp.window.move({ direction = "up" }))
hl.bind(mod("SHIFT + J"), hl.dsp.window.move({ direction = "down" }))

-- Laptop multimedia keys for volume and LCD brightness
local held = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("swayosd-client --output-volume 5"), held)
hl.bind("XF86AudioLowerVolume",  exec("swayosd-client --output-volume -5"), held)
hl.bind("XF86AudioMute",         exec("swayosd-client --output-volume mute-toggle"), held)
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), held)
hl.bind("XF86MonBrightnessUp",   exec("swayosd-client --brightness raise"), held)
hl.bind("XF86MonBrightnessDown", exec("swayosd-client --brightness lower"), held)

-- Requires playerctl. media-control routes to the currently-playing player so
-- the keys hit the active audio (e.g. Spotify) instead of a paused browser tab.
hl.bind("XF86AudioNext",  exec(bin .. "media-control next"),       { locked = true })
hl.bind("XF86AudioPause", exec(bin .. "media-control play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  exec(bin .. "media-control play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  exec(bin .. "media-control previous"),   { locked = true })
