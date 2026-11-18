# Tasks

## 1. Gesture input

- [x] 1.1 Add `pkgs.libinput` to `home.packages` in `home/programs/desktop/quickshell/quickshell.nix`. Verify by running home-manager switch, then confirming `libinput debug-events` prints `GESTURE_SWIPE_*` lines for a 3-finger swipe without sudo, and recording one BEGIN/UPDATE/END sample (including a `cancelled` one) as the parser reference.
- [x] 1.2 Create `home/programs/desktop/quickshell/config/TouchpadGestures.qml`: a `Process` running `libinput debug-events`, a `SplitParser` with a regex for `GESTURE_SWIPE_BEGIN|UPDATE|END` (fingers, dx/dy, `cancelled`), the signals `swipeBegin`, `swipeUpdate` and `swipeEnd`, a log-once fallback for unparseable lines, and a restart-with-backoff `Timer` when the process exits. Verify with a temporary `console.log` handler in `qs` logs that the swipes from 1.1 emit matching signals, and that killing the `libinput` process restarts it after the back-off.

## 2. Interactive overview

- [x] 2.1 In `Overview.qml`, add tuning constants (`swipeDistance`, `lockThreshold`, `flickVelocity`, settle durations) and the gesture state (`idle/deciding/tracking/settling`, `p0`, accumulators, smoothed velocity), and instantiate `TouchpadGestures`. Verify that Quickshell reloads without QML errors.
- [ ] 2.2 Implement swipe begin and the axis decision: capture `startShown`, `screenName` and `zoomWs`, refresh Hyprland workspaces/toplevels, map the target window without granting keyboard focus, lock the axis after `lockThreshold`, and drop horizontal swipes (unmapping again if nothing was shown). Verify that a horizontal 3-finger swipe still switches workspaces and never flashes the overview.
- [ ] 2.3 Implement tracking: stop `anim`/`startTimer`, then set `progress = clamp(p0 - dy/swipeDistance, 0, 1)` on the swiped screen's window. Verify that a held partial swipe up shows a partly zoomed overview that follows finger motion both ways, and that a swipe down while closed shows nothing.
- [ ] 2.4 Implement release and cancel: apply the commit rule (past halfway or flick), settle with `anim` from the current progress over a distance-scaled duration, and on commit go through the existing `open()`/`close()` so `shown`, keyboard focus and unmapping behave as today. Cancelled or reversed swipes return to `p0`. Verify on hermes the spec scenarios "Swipe past the threshold commits", "Short slow swipe cancels", "Fast flick commits", and closing by swipe down onto the current workspace.
- [x] 2.5 Make IPC take over a swipe in progress (reset gesture state in `open`/`close`/`toggle`), and update the header comment of `Overview.qml` to describe the swipe behaviour and its `libinput` dependency. Verify that `qs ipc call overview toggle` still opens and closes with the timed animation, including during a held swipe.

- [x] 2.6 Replace the single-row layout in `Overview.qml` with the grid layout from design 3b (`slotX(i)`/`slotY(i)`, a centred shorter last row, zoom from `slotY(zoomIndex)`). Verify with a layout computation for 3, 5 and 9 slots on the hermes screen size that few workspaces stay in one row and many wrap, and visually that opening with 6+ workspaces shows a grid.

- [x] 2.7 Map cards to the monitor work area (`reserved` from Hyprland: card aspect, thumbnail offsets, zoom target). Verify with a screenshot of the open overview that tiled windows reach the top of each card.

- [ ] 2.8 Add the hover close button (GNOME-style round dark disc with a white ×, fade + scale in) and `removeWorkspace` (switch to a neighbour when removing the visible workspace, close every window on it, glide the remaining cards). Verify by hovering a card to see the button, removing a background workspace and the visible one, and checking with `hyprctl clients`/`hyprctl workspaces` that the windows are gone and the workspace disappeared.

## 3. Hyprland config

- [x] 3.1 Remove the `direction = "up"` and `"down"` `hl.gesture` bindings from `home/programs/desktop/hyprland/config/input.lua`, and update the comment to point to Quickshell owning the vertical swipe. Verify with `hyprctl reload` that there are no config errors and that a full swipe up opens the overview exactly once (no second, IPC-triggered animation at the end).

## 4. Integration checks

- [ ] 4.1 With two monitors (or a headless second output), swipe up while each is focused. Verify the overview appears only on the focused one.
- [x] 4.2 Temporarily make `libinput` unavailable (e.g. remove it from `PATH` for the `qs` process). Verify that Quickshell and the bar keep running, the overview still works over IPC, and no error dialog appears.
- [ ] 4.3 Tune `swipeDistance`, `flickVelocity` and the settle durations on the hermes trackpad until opening and closing feel 1:1 with the fingers, and record the final values with a short comment.

## Workflow follow-up

- Commit the change and archive it with `/opsx:archive` once you're happy with how it feels on hermes.
