-- See https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_rules   = "",
        kb_options = "ctrl:nocaps,compose:rwin",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.2,
        },
    },
})

-- GNOME-style workspace switching: three-finger horizontal swipe drags
-- between workspaces, following the fingers, and snaps on release.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- GNOME-style overview: the vertical three-finger swipe (up opens, down
-- closes) is NOT bound here. Hyprland only runs a gesture's Lua action once
-- the swipe has ended, so Quickshell reads the swipe from libinput itself and
-- the zoom follows the fingers (quickshell/config/Overview.qml,
-- TouchpadGestures.qml). Binding up/down here too would open it twice.

hl.config({
    gestures = {
        workspace_swipe_cancel_ratio   = 0.15, -- a short flick is enough, like GNOME
        workspace_swipe_direction_lock = true,
    },
})

-- hermes (MacBook Pro T2) built-in trackpad: it's huge and sits right under
-- the palms, so a stray tap followed by a brush turned into a drag that
-- selected text (and the next keystroke replaced it). Click with a physical
-- press or a plain tap only; two-finger click = right click, macOS-style.
hl.device({
    name                 = "apple-inc.-apple-internal-keyboard-/-trackpad-1",
    tap_and_drag         = false,
    clickfinger_behavior = true,
})

-- Example per-device config
-- See https://wiki.hypr.land/configuring/core/devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
