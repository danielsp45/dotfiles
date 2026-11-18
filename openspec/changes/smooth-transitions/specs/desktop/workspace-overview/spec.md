# Spec Delta

## Purpose

The workspace overview is a GNOME Activities-style, full-screen view of the focused monitor's workspaces. The user opens and closes it with a three-finger touchpad swipe or over IPC.

## ADDED Requirements

### Requirement: Overview follows a vertical three-finger swipe
While a three-finger vertical touchpad swipe is in progress, the overview's open/close transition SHALL be positioned in proportion to the distance the fingers have travelled. It SHALL update on every swipe update, with no fixed-duration animation in between, and up to a full swipe distance it SHALL move by the same amount for the same finger travel.

#### Scenario: Opening tracks the fingers
- **WHEN** the overview is closed and the user swipes up with three fingers and holds partway
- **THEN** the overview is shown partially zoomed out, in proportion to the distance swiped, and stays there while the fingers stay still

#### Scenario: Reversing direction mid-swipe
- **WHEN** the user swipes up partway and then moves back down without lifting
- **THEN** the overview zooms back in, following the fingers, toward the closed state

#### Scenario: Closing tracks the fingers
- **WHEN** the overview is open and the user swipes down with three fingers
- **THEN** the overview zooms into the workspace it will close onto, in proportion to the distance swiped

#### Scenario: Progress is clamped
- **WHEN** the user swipes further than the full swipe distance in either direction
- **THEN** the transition stays at fully open or fully closed and goes no further

### Requirement: Overview settles on release
When the fingers lift, the overview SHALL animate from its current position to fully open or fully closed and SHALL NOT restart from either end. It SHALL settle on the target state when the swipe passed the commit threshold or the release was a fast flick toward it. Otherwise it SHALL return to the state the swipe started from.

#### Scenario: Swipe past the threshold commits
- **WHEN** the user swipes up past the commit threshold and lifts the fingers
- **THEN** the overview finishes opening from its current position and is interactive (keyboard focus, clicks)

#### Scenario: Short slow swipe cancels
- **WHEN** the user swipes up a short distance below the threshold, slowly, and lifts the fingers
- **THEN** the overview animates back to closed and no workspace or focus changes happen

#### Scenario: Fast flick commits
- **WHEN** the user makes a short but fast upward swipe and lifts the fingers
- **THEN** the overview opens

#### Scenario: Interrupted by the system
- **WHEN** libinput reports the swipe as cancelled (e.g. a finger count change)
- **THEN** the overview returns to the state the swipe started from

### Requirement: Swipe direction maps to overview state
Swiping up SHALL only open the overview, and swiping down SHALL only close it. A swipe toward a state the overview is already in SHALL have no visible effect. A swipe whose motion is mainly horizontal SHALL be ignored by the overview and left to workspace switching.

#### Scenario: Down while closed
- **WHEN** the overview is closed and the user swipes down with three fingers
- **THEN** nothing visible happens

#### Scenario: Horizontal swipe
- **WHEN** the user swipes three fingers mostly horizontally
- **THEN** the overview does not appear or change, and the workspace swipe behaves as before

### Requirement: Swipe follows the natural-scroll direction
The gesture direction SHALL be consistent with the existing touchpad configuration (natural scrolling): fingers moving up the touchpad open the overview.

#### Scenario: Physical direction
- **WHEN** the user's three fingers move toward the top of the touchpad
- **THEN** the overview opens

### Requirement: Overview opens on the focused monitor
A swipe-driven opening SHALL show the overview on the monitor focused when the swipe begins, zooming out of that monitor's active workspace, the same as an IPC-triggered opening.

#### Scenario: Multi-monitor
- **WHEN** two monitors are connected and the user swipes up while monitor B is focused
- **THEN** the overview appears on monitor B only

### Requirement: Workspaces wrap into a grid when there are many
The overview SHALL lay out the workspace cards (plus the new-workspace slot) in a single row while the cards stay reasonably large. When a single row would shrink the cards below a minimum size, it SHALL wrap them into as few balanced rows as needed, using the screen's vertical space. Cards keep the screen's aspect ratio and their order (left to right, top to bottom).

#### Scenario: Few workspaces
- **WHEN** the focused monitor has two or three workspaces
- **THEN** the overview shows them in one centred row, as before

#### Scenario: Many workspaces
- **WHEN** the focused monitor has enough workspaces that a single row would make the cards smaller than the minimum
- **THEN** the cards are arranged in two or more centred rows, larger than they would be in a single row

#### Scenario: Zoom targets the right card in a grid
- **WHEN** the overview opens or closes while the current workspace's card is in the second row
- **THEN** the zoom animation scales out of / into that card's position

### Requirement: Cards show the usable work area
Each workspace card SHALL depict the monitor's work area, meaning the screen minus space reserved by exclusive layers such as the top bar. Tiled windows therefore fill the card without an empty strip where the bar sits. On close, the zoom SHALL land the card exactly on that work area.

#### Scenario: Bar strip is not shown
- **WHEN** the bar reserves 30 px at the top and the overview is open
- **THEN** tiled windows in each card start at the card's top edge (minus normal gaps), with no bar-height empty band

#### Scenario: Fullscreen window
- **WHEN** a workspace has a fullscreen window
- **THEN** its card is filled by that window, with the bar-height top slice cropped

### Requirement: Workspaces can be removed from the overview
While the overview is open and a workspace card is hovered, a GNOME-style round close button SHALL fade in at the card's top-right corner. Clicking it SHALL remove the workspace by closing all of its windows, using a normal close request so apps can still ask to save. If it was the visible workspace, the monitor first switches to the previous workspace (the next one if it is the first). The button SHALL NOT be offered when the monitor has only one workspace.

#### Scenario: Remove a background workspace
- **WHEN** workspaces 1, 2 and 3 exist, the user hovers card 3 and clicks its close button
- **THEN** workspace 3's windows are closed, workspace 3 disappears from the overview, the remaining cards glide into place, and the overview stays open

#### Scenario: Remove the first workspace
- **WHEN** the user removes workspace 1 while it is visible and 1 and 2 exist
- **THEN** the monitor switches to workspace 2 and workspace 1's windows are closed

#### Scenario: Remove the visible workspace
- **WHEN** the user removes the workspace currently shown on the monitor
- **THEN** the monitor switches to the neighbouring workspace and the removed workspace's windows are closed

#### Scenario: Only one workspace
- **WHEN** the monitor has a single workspace
- **THEN** no close button appears on its card

#### Scenario: Button visibility
- **WHEN** the pointer is not over a card, or the overview is still zooming
- **THEN** no close button is shown

### Requirement: IPC control remains available
The overview SHALL keep accepting `open`, `close` and `toggle` over Quickshell IPC (target `overview`), each playing a timed, non-interactive transition. An IPC call during a swipe SHALL end the swipe tracking and take over.

#### Scenario: Keybind toggles
- **WHEN** `qs ipc call overview toggle` runs while the overview is closed
- **THEN** the overview opens with a timed animation

### Requirement: Graceful degradation without gesture input
If touchpad gesture events cannot be read (no touchpad, missing permissions, or the reader process exits), the overview SHALL still work over IPC and the rest of the shell SHALL keep running. A reader that exits SHALL be restarted after a delay.

#### Scenario: Reader unavailable
- **WHEN** the gesture reader cannot open input devices
- **THEN** the overview opens and closes normally over IPC and no error dialog interrupts the user
