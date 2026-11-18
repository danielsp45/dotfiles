# Proposal

## Why

The three-finger swipe up/down that opens and closes the Quickshell workspace overview only starts animating after the fingers lift. Hyprland calls a Lua `function` gesture action once, when the gesture ends, and that call runs `qs ipc call overview open|close`, which plays a fixed 320 ms / 400 ms animation. The overview therefore lags behind the hand. It should track the fingers the way the horizontal workspace swipe does, GNOME-style.

## What Changes

- The overview's zoom progress (0 = desktop, 1 = overview) follows vertical three-finger touchpad motion while the swipe is in progress, both when opening (swipe up) and when closing (swipe down).
- On release the overview settles open or closed, based on distance travelled and release velocity, animating from wherever the fingers left it rather than restarting from 0 or 1.
- A swipe that goes back the way it came (up, then down again before release) cancels and returns to the starting state.
- Quickshell reads touchpad swipe events itself, through a `libinput debug-events` process, because Hyprland exposes no per-update gesture callback to Lua or IPC.
- **BREAKING (config)**: the two `hl.gesture({ fingers = 3, direction = "up"/"down", action = function … })` bindings are removed from `hyprland/config/input.lua`, because Quickshell now owns the vertical three-finger gesture. The horizontal `workspace` gesture stays.
- The IPC entry points (`qs ipc call overview open|close|toggle`) keep working with their current timed animations, for keybinds and scripts.
- The desktops disposition when in the selectino view shouldn't have all of the desktops linearly when too many desktop environments are being used and the verical space should also be used

## Capabilities

### New Capabilities
- `desktop/workspace-overview`: the Quickshell workspace overview: how it opens and closes, including tracking three-finger touchpad swipes interactively, and how it is triggered over IPC.

### Modified Capabilities
<!-- none: no specs exist yet -->

## Impact

- `home/programs/desktop/quickshell/config/Overview.qml`: progress is driven by gesture updates as well as by the timed animation; it gains release and snap logic.
- New QML component under `home/programs/desktop/quickshell/config/` (e.g. `TouchpadGestures.qml`) that runs and parses `libinput debug-events`.
- `home/programs/desktop/quickshell/quickshell.nix`: adds `pkgs.libinput`, so the `libinput` CLI is on `PATH`.
- `home/programs/desktop/hyprland/config/input.lua`: removes the vertical gesture bindings and updates the comments.
- Depends on the user being in the `input` group, which every host (storm, hermes, trooper, pandora) already sets.
- The horizontal workspace swipe and SUPER+number switching are unaffected.
