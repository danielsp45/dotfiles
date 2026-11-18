# Design

## Context

- Hyprland 0.57 (Lua config). `hl.gesture` supports built-in actions (`workspace`, etc.) and a Lua `function` action. The function runs **once, at gesture end**. `hl.on` has no gesture events (see `HL.EventName` in `share/hypr/stubs/hl.meta.lua`), so neither Lua nor IPC can see a swipe while it is in progress.
- `Overview.qml` already models the transition as one scalar, `win.progress` (0 = desktop, 1 = overview). The zoom transform, opacity, ring and label all derive from it, and a `NumberAnimation` (`anim`) drives it. `mapped` keeps the layer surface alive until the close animation ends, and `active` grants exclusive keyboard focus.
- The user is in the `input` group on every host, so an unprivileged process can open `/dev/input/event*`.
- Touchpad uses `natural_scroll = true`.

## Goals / Non-Goals

**Goals:**
- 1:1 finger tracking of `progress` for the vertical three-finger swipe, then a velocity-aware settle animation.
- Keep a single source of truth (`progress`), so the IPC path and the gesture path share every visual.

**Non-Goals:**
- Changing the horizontal workspace swipe (Hyprland-native, already interactive).
- Swiping horizontally *inside* the open overview to scroll workspaces.
- Touchscreen gestures.
- A Hyprland C++ plugin.

## Decisions

### 1. Gesture source: `libinput debug-events` run from Quickshell
Quickshell starts `libinput debug-events` as a `Process` and parses the `GESTURE_SWIPE_BEGIN / UPDATE / END` lines from its stdout with a `SplitParser`. An UPDATE line carries the finger count and an accelerated `dx/dy`. END carries `cancelled` when libinput aborted the swipe.

*Alternatives:*
- **Hyprland plugin** exposing gesture progress over IPC. It would be first-class, but means C++, rebuilds on every Hyprland bump, and pinning to Hyprland's headers on Nix. Too heavy for a dotfiles repo.
- **Keep `hl.gesture` and fake progress** by starting the animation at gesture begin. Impossible: there is no begin callback either.
- **A small Python/C evdev reader.** It would need its own gesture recognition (libinput already does this, with palm/thumb handling). Rejected.

`libinput debug-events` output is human-oriented and not a stable API. That risk is accepted and mitigated by isolating the parsing in one component (see Risks). Key events in that stream are obfuscated by default (no `--show-keycodes`), so no keystrokes reach the shell.

### 2. Component split
- `TouchpadGestures.qml` (new, non-visual): owns the process and parsing. It emits `swipeBegin(fingers)`, `swipeUpdate(fingers, dx, dy)` and `swipeEnd(fingers, cancelled)`, and restarts the process with a back-off timer (e.g. 5 s) when it exits. It is reusable for future gestures.
- `Overview.qml`: instantiates it and adds a small gesture state machine. Each `PanelWindow` keeps its own `progress`. The scope tracks which screen is being swiped (`screenName`, captured at swipe begin from `Hyprland.focusedMonitor`).

### 3. Gesture state machine (in `Overview`)
`idle → deciding → tracking(open|close) → settling → idle`

- **begin** (3 fingers): reset the accumulators. Once the swipe locks to vertical, record `startShown = shown`. When the overview is closed, also capture `screenName` and `zoomWs` and refresh workspaces and toplevels. The surface is mapped lazily, the first time progress goes above 0. A horizontal swipe, or a downward swipe while the overview is closed, therefore never maps a full-screen overlay.
- **deciding**: accumulate `dx, dy` until `|d| > ~12 px`. If `|dx| > |dy|`, ignore the rest of this swipe, because it belongs to Hyprland's workspace swipe. Otherwise lock to vertical.
- **tracking**: `progress = clamp(p0 - dy / SWIPE_DISTANCE, 0, 1)`, where `p0` is the progress at begin. Negative `dy` = fingers up (libinput reports physical motion; natural scroll does not invert raw gesture deltas), so up raises progress. A gesture toward the current state just clamps (no-op). `SWIPE_DISTANCE` ≈ 300 libinput units, tuned on hermes.
- **end**: velocity = an exponentially smoothed `dy / dt` from the last few updates. Commit when `progress` moved past 0.5 of the way from `p0`, or when velocity exceeds a flick threshold in the target direction. Then call the existing `open()` / `close()` path, which sets `shown` and focus. The settle reuses `anim` with `from = progress` and a duration scaled by the remaining distance (`~320 ms * remaining`, min 120 ms) and `Easing.OutCubic`, so the motion continues from the fingers rather than restarting.
- **cancelled / reverse**: animate back to `p0`. If that is 0, unmap the surface when the animation ends (the existing `onStopped` logic).
- During tracking `anim` is stopped and the 40 ms `startTimer` is bypassed. `startTimer` stays only for the IPC path.

Keyboard focus (`WlrKeyboardFocus.Exclusive`) is granted only once the opening commits. If it were granted at swipe begin, a cancelled swipe would steal focus from the focused window.

### 3b. Grid layout for many workspaces
The row layout is generalised to a grid: for `rows = 1..slots`, compute `cols = ceil(slots / rows)` and the largest card that fits `cols` cards across (92% width) and `rows` cards plus labels down (80% height), capped at 32% of the screen width. Use the fewest rows whose card is at least `minCardFrac` (18%) of the screen width. If no row count reaches that, use the row count with the largest card. Every row is centred, including a shorter last row. The zoom transform already maps a card at `(ax, ay)` to full screen. It just needs `slotY(zoomIndex)` instead of the single-row `cardY`.

*Alternative:* always choose the layout with the largest cards. Rejected: that wraps even two or three workspaces into two rows, which changes today's look for the common case.

### 3c. Removing a workspace
Hyprland has no "delete workspace": a workspace is destroyed once it is empty and not shown. Removal therefore switches away first if the workspace is the visible one (`hl.dsp.focus({ workspace = N })`, where N is the previous card, or the next card for the first one). It then sends every toplevel `hl.dsp.window.close({ window = "address:…" })`, the same polite close as SUPER+W. Apps with unsaved work can still prompt, and the workspace then lingers until they're closed. Moving the windows to a neighbour instead was tried first and dropped at the user's request. The button lives outside the card's rounded mask, so it can straddle the corner the way GNOME's close buttons do. Card `x`/`y` get a 250 ms OutCubic `Behavior`, enabled only while the overview is active, so the reflow after a removal glides without affecting the zoom.

### 4. Hyprland config
Remove the `direction = "up"` and `"down"` `hl.gesture` entries. If they stayed, Hyprland would fire `qs ipc call overview open` at gesture end, on top of the interactive path. The horizontal `workspace` gesture and `workspace_swipe_direction_lock` stay, and they also stop a vertical swipe from leaking into a workspace switch.

### 5. Packaging
Add `pkgs.libinput` to `home.packages` in `quickshell.nix` and call `libinput` by name. *Alternative:* interpolate the absolute store path into QML. Rejected, because the QML lives in a mutable `mkSymlink` directory and isn't Nix-templated.

## Risks / Trade-offs

- **[Unstable text format of `libinput debug-events`]** → keep all parsing in `TouchpadGestures.qml` behind a regex with a format check. On unparseable lines, log once and ignore them. The overview still works over IPC.
- **[Two libinput contexts read the same device]** (Hyprland's and ours) → this is supported (no grab), and it costs one extra lightweight process that wakes only on input events.
- **[Hyprland may also forward the vertical swipe to the focused client]** via pointer-gestures → in practice few apps act on three-finger vertical swipes, so this is accepted. Verify with Firefox, which uses horizontal swipes only.
- **[Thumbnail build cost at swipe begin]** could stutter the first frames → the `Loader` already builds lazily. If needed, defer `ScreencopyView.live` until progress > 0.05.
- **[Device hot-plug]** → libinput's udev backend picks up new devices automatically.
- **[Tuning feel]** (distance, flick speed, durations) is subjective → constants live at the top of `Overview.qml`, to be tuned on hermes.

## Migration Plan

Apply via home-manager switch, reload Hyprland (picks up `input.lua`), and restart Quickshell. Rollback: revert the commit. The old `hl.gesture` bindings come back and the overview reverts to triggered animations.

## Open Questions

- Exact values for `SWIPE_DISTANCE`, the flick threshold and settle durations. These are tuned by hand on the hermes trackpad and change nothing structurally.
