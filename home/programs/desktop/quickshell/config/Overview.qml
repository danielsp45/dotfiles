// Overview.qml
// GNOME Activities-style workspace overview: a full-screen layer on the
// focused monitor showing that monitor's workspaces as live thumbnails.
//
//   • three-finger swipe up opens it, swipe down closes it. The zoom follows
//     the fingers (touchpad events come from TouchpadGestures.qml via
//     libinput). On release it settles open or closed depending on how far
//     and how fast the swipe went.
//   • open/close/toggle over IPC (timed animation):  qs ipc call overview toggle
//   • many workspaces wrap into a grid instead of one ever-smaller row
//   • click a workspace to switch to it, click a window to focus it
//   • the dashed slot at the end opens a new, empty workspace
//   • Esc or a click on the background closes it
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "QuickSettings"

Scope {
    id: overview

    // Logical state (drives the animations) and the monitor it's shown on.
    property bool shown: false
    property string screenName: ""
    // Workspace the overview zooms out of on open and into on close.
    property int zoomWs: -1

    function open() {
        if (shown) return;
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        screenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        zoomWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        shown = true;
    }
    // wsId: the workspace being switched to, so closing zooms into it.
    function close(wsId) {
        if (wsId !== undefined) zoomWs = wsId;
        else if (Hyprland.focusedWorkspace) zoomWs = Hyprland.focusedWorkspace.id;
        shown = false;
    }
    function toggle() { shown ? close() : open(); }

    // Removes a workspace from the overview, closing its windows. Hyprland has
    // no "delete workspace": one disappears once it is empty and not shown. So
    // if it's the one on screen, switch to the previous workspace on this
    // monitor (the next one if it's the first), then politely close every
    // window on it (like SUPER+W; apps may still ask to save, and the
    // workspace stays until they're gone).
    // list: this monitor's workspaces, in display order.
    function removeWorkspace(ws, list) {
        const idx = list.indexOf(ws);
        if (idx < 0 || list.length < 2) return;
        const target = list[idx > 0 ? idx - 1 : idx + 1];

        if (ws.active || ws.focused) {
            Hyprland.dispatch("hl.dsp.focus({ workspace = " + target.id + " })");
            if (zoomWs === ws.id) zoomWs = target.id;
        }
        const tops = ws.toplevels.values;
        for (let i = 0; i < tops.length; ++i) {
            let a = tops[i].address + "";
            if (!a.startsWith("0x")) a = "0x" + a;
            Hyprland.dispatch('hl.dsp.window.close({ window = "address:' + a + '" })');
        }
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    // Hyprland won't move focus to a window while a layer surface holds
    // exclusive keyboard focus, so close first and focus once it's released.
    property string pendingWindow: ""
    function focusWindow(address, wsId) {
        let a = address + "";
        if (!a.startsWith("0x")) a = "0x" + a;
        pendingWindow = a;
        close(wsId);
        focusTimer.restart();
    }
    Timer {
        id: focusTimer
        interval: 60
        onTriggered: {
            if (overview.pendingWindow !== "")
                Hyprland.dispatch('hl.dsp.focus({ window = "address:' + overview.pendingWindow + '" })');
            overview.pendingWindow = "";
        }
    }

    IpcHandler {
        target: "overview"
        function open(): void { overview.cancelGesture(); overview.open() }
        function close(): void { overview.cancelGesture(); overview.close() }
        function toggle(): void { overview.cancelGesture(); overview.toggle() }
    }

    // ---- three-finger vertical swipe, tracked 1:1 -----------------------
    // Tuning (libinput units, roughly touchpad pixels after acceleration).
    readonly property int swipeFingers: 3
    readonly property real swipeDistance: 300   // travel for a full open/close
    readonly property real lockThreshold: 12    // travel before the axis is decided
    readonly property real flickVelocity: 0.6   // units/ms; faster release commits
    readonly property int settleMs: 320         // settle duration for a full 0→1

    // idle | deciding | tracking | ignored
    property string phase: "idle"
    property bool startShown: false
    property real p0: 0                // progress when the swipe began
    property real accX: 0
    property real accY: 0              // positive = fingers moved up
    property real velocity: 0          // smoothed, units/ms, positive = up
    property real lastTime: 0
    // Progress the swiped window should show while tracking.
    property real gestureProgress: 0
    // True only while open()/close() run on behalf of a finished swipe, so the
    // window settles from where the fingers left it instead of restarting.
    property bool gestureCommit: false

    // Asks the swiped window to animate to `target` (0 or 1) from where it is.
    signal settle(real target)

    function windowProgress() {
        for (let i = 0; i < windows.instances.length; ++i) {
            const w = windows.instances[i];
            if (w.modelData.name === screenName) return w.progress;
        }
        return shown ? 1 : 0;
    }

    // Abandons a swipe in progress (an IPC call takes over).
    function cancelGesture() {
        if (phase === "tracking") settle(startShown ? 1 : 0);
        if (phase !== "idle") phase = "ignored";
    }

    TouchpadGestures {
        onSwipeBegin: (fingers, time) => {
            if (fingers !== overview.swipeFingers) { overview.phase = "ignored"; return; }
            overview.phase = "deciding";
            overview.accX = 0;
            overview.accY = 0;
            overview.velocity = 0;
            overview.lastTime = time;
        }

        onSwipeUpdate: (fingers, dx, dy, time) => {
            if (overview.phase === "idle" || overview.phase === "ignored") return;

            const dt = time - overview.lastTime;
            overview.lastTime = time;
            if (dt > 0)
                overview.velocity = 0.6 * overview.velocity + 0.4 * (-dy / dt);
            overview.accX += dx;
            overview.accY -= dy;

            if (overview.phase === "deciding") {
                if (Math.hypot(overview.accX, overview.accY) < overview.lockThreshold) return;
                if (Math.abs(overview.accX) > Math.abs(overview.accY)) {
                    // Horizontal: Hyprland's workspace swipe owns it.
                    overview.phase = "ignored";
                    return;
                }
                overview.startShown = overview.shown;
                if (!overview.shown) {
                    Hyprland.refreshMonitors();
                    Hyprland.refreshWorkspaces();
                    Hyprland.refreshToplevels();
                    overview.screenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
                }
                overview.zoomWs = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
                overview.p0 = overview.windowProgress();
                overview.phase = "tracking";
            }

            overview.gestureProgress = Math.max(0, Math.min(1,
                overview.p0 + overview.accY / overview.swipeDistance));
        }

        onSwipeEnd: (fingers, cancelled, time) => {
            const phase = overview.phase;
            overview.phase = "idle";
            if (phase !== "tracking") return;

            const p = overview.gestureProgress;
            const v = overview.velocity;
            const flick = overview.flickVelocity;
            // Opening: commit past halfway or on an upward flick; a flick back
            // down cancels. Closing mirrors that.
            const commit = cancelled ? false
                : overview.startShown
                    ? (v < -flick || (p < 0.5 && v <= flick)) && p < 1
                    : (v > flick || (p > 0.5 && v >= -flick)) && p > 0;

            if (commit) {
                overview.gestureCommit = true;
                if (overview.startShown) overview.close();
                else overview.open();
                overview.gestureCommit = false;
            } else {
                overview.settle(overview.startShown ? 1 : 0);
            }
        }
    }

    Variants {
        id: windows
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            readonly property bool active: overview.shown && overview.screenName === modelData.name
            readonly property var monitor: Hyprland.monitorFor(modelData)

            // 0 = closed (current workspace full-screen), 1 = overview.
            property real progress: 0
            // Mapped from the moment it opens until the close animation ends.
            property bool mapped: false
            visible: mapped

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            // This window is the one a swipe is driving.
            readonly property bool swiped: overview.screenName === modelData.name
            readonly property bool tracking: swiped && overview.phase === "tracking"

            function animateTo(target, duration, easing) {
                startTimer.stop();
                anim.stop();
                anim.to = target;
                anim.duration = duration;
                anim.easing.type = easing;
                anim.start();
            }
            // Finish a swipe: carry on from the current position, taking as
            // long as the remaining distance needs.
            function settleTo(target) {
                const remaining = Math.abs(target - progress);
                animateTo(target, Math.max(120, overview.settleMs * remaining), Easing.OutCubic);
            }

            onTrackingChanged: if (tracking) { startTimer.stop(); anim.stop(); }
            Connections {
                target: overview
                function onGestureProgressChanged() {
                    if (!win.tracking) return;
                    win.progress = overview.gestureProgress;
                    // Map lazily, so a swipe towards the state we're already
                    // in (e.g. down while closed) shows nothing at all.
                    if (win.progress > 0) win.mapped = true;
                }
                function onSettle(target) {
                    if (win.swiped && win.mapped) win.settleTo(target);
                }
            }

            onActiveChanged: {
                if (active) {
                    mapped = true;
                    content.forceActiveFocus();
                    if (overview.gestureCommit) {
                        settleTo(1);
                    } else {
                        // Let the surface map and the thumbnails build first, so
                        // the animation doesn't stutter on its first frames.
                        startTimer.restart();
                    }
                } else if (overview.gestureCommit) {
                    settleTo(0);
                } else {
                    animateTo(0, 400, Easing.InOutCubic);
                }
            }
            Timer {
                id: startTimer
                interval: 40
                onTriggered: win.animateTo(1, 320, Easing.OutCubic)
            }
            NumberAnimation {
                id: anim
                target: win
                property: "progress"
                easing.type: Easing.OutCubic
                onStopped: if (!win.active && win.progress === 0) win.mapped = false
            }

            Item {
                id: content
                anchors.fill: parent
                focus: true
                // Cross-fade from the real desktop over the first part of the zoom.
                opacity: Math.min(1, win.progress * 3)

                Keys.onEscapePressed: overview.close()

                // Dimmed, blurred-looking backdrop: the wallpaper, darkened.
                Image {
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.wallpaper"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }
                Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.55 }

                MouseArea {
                    anchors.fill: parent
                    onClicked: overview.close()
                }

                // Only build the live thumbnails while the overview is up.
                Loader {
                    anchors.fill: parent
                    active: win.mapped
                    sourceComponent: workspaceRow
                }
            }

            Component {
                id: workspaceRow

                Item {
                    id: rowRoot

                    // This monitor's regular workspaces, in order, plus one
                    // empty slot for a new workspace (like GNOME).
                    readonly property var workspaces: {
                        const all = Hyprland.workspaces.values;
                        const list = [];
                        for (let i = 0; i < all.length; ++i) {
                            const ws = all[i];
                            if (ws && ws.id > 0 && ws.monitor === win.monitor)
                                list.push(ws);
                        }
                        list.sort((a, b) => a.id - b.id);
                        return list;
                    }
                    readonly property int nextId: {
                        let max = 0;
                        const all = Hyprland.workspaces.values;
                        for (let i = 0; i < all.length; ++i)
                            if (all[i] && all[i].id > max) max = all[i].id;
                        return max + 1;
                    }
                    readonly property int slots: workspaces.length + 1

                    // Card geometry: same aspect ratio as the screen, as large
                    // as fits (capped, so a single workspace isn't huge). One
                    // row while the cards stay big enough, otherwise the fewest
                    // balanced rows that keep them so.
                    readonly property real gap: 28
                    readonly property real labelH: 28   // label + its margin, below each card
                    readonly property real maxCardFrac: 0.32
                    readonly property real minCardFrac: 0.18
                    readonly property real screenW: win.modelData.width
                    readonly property real screenH: win.modelData.height
                    // Cards show the work area: the screen minus what the bar
                    // (and other exclusive zones) reserve, so tiled windows
                    // don't sit under an empty strip. Fullscreen windows lose
                    // their top bar-height slice in the thumbnail.
                    // Hyprland: reserved = [left, top, right, bottom].
                    readonly property var reserved: {
                        const r = win.monitor && win.monitor.lastIpcObject
                            ? win.monitor.lastIpcObject.reserved : null;
                        return r && r.length === 4 ? r : [0, 0, 0, 0];
                    }
                    readonly property real resL: reserved[0]
                    readonly property real resT: reserved[1]
                    readonly property real workW: Math.max(1, screenW - reserved[0] - reserved[2])
                    readonly property real workH: Math.max(1, screenH - reserved[1] - reserved[3])
                    readonly property var grid: {
                        const availW = width * 0.92, availH = height * 0.8;
                        const fit = rows => {
                            const cols = Math.ceil(slots / rows);
                            const byW = (availW - gap * (cols - 1)) / cols;
                            const byH = ((availH - gap * (rows - 1)) / rows - labelH) * workW / workH;
                            return { rows: rows, cols: cols,
                                     cardW: Math.max(1, Math.min(screenW * maxCardFrac, byW, byH)) };
                        };
                        let best = fit(1);
                        for (let rows = 1; rows <= slots; ++rows) {
                            const g = fit(rows);
                            if (g.cardW >= screenW * minCardFrac) return g;
                            if (g.cardW > best.cardW) best = g;
                        }
                        return best;
                    }
                    readonly property real cardW: grid.cardW
                    readonly property real cardH: cardW * workH / workW
                    readonly property real s: cardW / workW

                    // Card positions (labels hang below the cards). Every row
                    // is centred, including a shorter last one.
                    readonly property real rowH: cardH + labelH
                    readonly property real gridH: grid.rows * rowH + (grid.rows - 1) * gap
                    readonly property real cardY: (height - gridH) / 2
                    // Slot under the pointer (-1 = none). The blue ring marks it, or
                    // the current workspace when nothing is hovered.
                    property int hoveredIndex: -1
                    function setHovered(i, on) {
                        if (on) hoveredIndex = i;
                        else if (hoveredIndex === i) hoveredIndex = -1;
                    }
                    function slotX(i) {
                        const row = Math.floor(i / grid.cols);
                        const inRow = Math.min(grid.cols, slots - row * grid.cols);
                        const rowW = inRow * cardW + (inRow - 1) * gap;
                        return (width - rowW) / 2 + (i % grid.cols) * (cardW + gap);
                    }
                    function slotY(i) { return cardY + Math.floor(i / grid.cols) * (rowH + gap); }

                    // --- zoom: the card of zoomWs grows to fill the screen ---
                    readonly property int zoomIndex: {
                        for (let i = 0; i < workspaces.length; ++i)
                            if (workspaces[i].id === overview.zoomWs) return i;
                        return overview.zoomWs === nextId ? slots - 1 : 0;
                    }
                    readonly property real f: 1 - win.progress
                    readonly property real ax: slotX(zoomIndex)
                    readonly property real ay: slotY(zoomIndex)
                    // Fully zoomed, the card covers the work area exactly, so
                    // its windows land where they really are.
                    readonly property real zs: (cardW + (workW - cardW) * f) / cardW
                    transform: [
                        Scale { xScale: rowRoot.zs; yScale: rowRoot.zs },
                        Translate {
                            x: rowRoot.ax * (1 - rowRoot.f) + rowRoot.resL * rowRoot.f - rowRoot.zs * rowRoot.ax
                            y: rowRoot.ay * (1 - rowRoot.f) + rowRoot.resT * rowRoot.f - rowRoot.zs * rowRoot.ay
                        }
                    ]

                    Item {
                        anchors.fill: parent

                        Repeater {
                            model: rowRoot.workspaces

                            Item {
                                id: card
                                required property var modelData
                                required property int index
                                readonly property var ws: modelData
                                x: rowRoot.slotX(index)
                                y: rowRoot.slotY(index)
                                width: rowRoot.cardW
                                height: rowRoot.cardH + label.height + 10

                                // Neighbours glide into place when a workspace
                                // is removed (only while the overview is up, so
                                // the zoom itself is never disturbed).
                                Behavior on x { enabled: win.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                Behavior on y { enabled: win.active; NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                HoverHandler { id: cardHover }
                                readonly property bool canRemove: rowRoot.workspaces.length > 1
                                readonly property bool showClose: canRemove && win.active
                                    && win.progress > 0.98 && (cardHover.hovered || closeHover.hovered)

                                Rectangle {
                                    id: frame
                                    width: rowRoot.cardW
                                    height: rowRoot.cardH
                                    radius: 12 * win.progress
                                    color: "#202020"
                                    clip: true

                                    // Clip everything inside to the rounded card shape
                                    // (plain clip only cuts a square).
                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: frameMask
                                        maskThresholdMin: 0.5
                                        maskSpreadAtMin: 1.0
                                    }
                                    Rectangle {
                                        id: frameMask
                                        anchors.fill: parent
                                        radius: parent.radius
                                        visible: false
                                        layer.enabled: true
                                    }

                                    // Highlight ring, drawn above the window thumbnails.
                                    Rectangle {
                                        anchors.fill: parent
                                        z: 10
                                        radius: parent.radius
                                        color: "transparent"
                                        opacity: win.progress
                                        border.width: (rowRoot.hoveredIndex === card.index
                                            || (rowRoot.hoveredIndex === -1 && card.ws.active)) ? 3 : 0
                                        border.color: Theme.accent
                                    }

                                    Image {
                                        anchors.fill: parent
                                        source: "file://" + Quickshell.env("HOME") + "/.wallpaper"
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: rowRoot.cardW * 2
                                    }

                                    // Click on the workspace background → switch to it.
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            card.ws.activate();
                                            overview.close(card.ws.id);
                                        }
                                    }
                                    // Covers the window previews too (handlers see hover on children).
                                    HoverHandler {
                                        onHoveredChanged: rowRoot.setHovered(card.index, hovered)
                                    }

                                    Repeater {
                                        model: card.ws.toplevels

                                        Item {
                                            id: thumb
                                            required property var modelData
                                            readonly property var ipc: modelData.lastIpcObject || ({})
                                            readonly property var at: ipc.at || [0, 0]
                                            readonly property var size: ipc.size || [0, 0]
                                            readonly property real monX: win.monitor ? win.monitor.x : 0
                                            readonly property real monY: win.monitor ? win.monitor.y : 0

                                            visible: size[0] > 0 && size[1] > 0
                                            x: (at[0] - monX - rowRoot.resL) * rowRoot.s
                                            y: (at[1] - monY - rowRoot.resT) * rowRoot.s
                                            width: size[0] * rowRoot.s
                                            height: size[1] * rowRoot.s
                                            z: ipc.floating ? 1 : 0

                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskEnabled: true
                                                maskSource: thumbMask
                                                maskThresholdMin: 0.5
                                                maskSpreadAtMin: 1.0
                                            }
                                            Rectangle {
                                                id: thumbMask
                                                anchors.fill: parent
                                                radius: 6
                                                visible: false
                                                layer.enabled: true
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 6
                                                color: "#2b2b2b"
                                                visible: !shot.hasContent

                                                Text {
                                                    anchors.centerIn: parent
                                                    width: parent.width - 8
                                                    horizontalAlignment: Text.AlignHCenter
                                                    elide: Text.ElideRight
                                                    text: thumb.ipc.class || thumb.modelData.title || ""
                                                    color: "#cccccc"
                                                    font.pixelSize: 10
                                                }
                                            }

                                            ScreencopyView {
                                                id: shot
                                                anchors.fill: parent
                                                captureSource: thumb.modelData.wayland
                                                live: true
                                                constraintSize: Qt.size(thumb.width * 2, thumb.height * 2)
                                            }


                                            // Click a window → focus it (switches workspace too).
                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: overview.focusWindow(thumb.modelData.address, card.ws.id)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    id: label
                                    anchors.top: frame.bottom
                                    anchors.topMargin: 10
                                    anchors.horizontalCenter: frame.horizontalCenter
                                    text: card.ws.name || card.ws.id
                                    color: card.ws.active ? "#ffffff" : "#bbbbbb"
                                    font.pixelSize: 13
                                    font.bold: card.ws.active
                                    opacity: win.progress
                                }

                                // GNOME-style close button: a round, dark,
                                // slightly translucent disc with a thin white ×,
                                // straddling the card's top-right corner. It
                                // fades and grows in while the card is hovered.
                                // Removing closes the workspace's windows.
                                Item {
                                    id: closeBtn
                                    readonly property real size: 28
                                    width: size
                                    height: size
                                    x: frame.width - size * 0.62
                                    y: -size * 0.38
                                    z: 20
                                    visible: opacity > 0
                                    opacity: card.showClose ? 1 : 0
                                    scale: card.showClose ? 1 : 0.85
                                    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                                    Rectangle {
                                        id: disc
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: closeArea.pressed ? "#ee262626"
                                             : closeHover.hovered ? "#ee505050" : "#ee383838"
                                        border.width: 1
                                        border.color: "#22ffffff"
                                        Behavior on color { ColorAnimation { duration: 120 } }

                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowColor: "#80000000"
                                            shadowBlur: 0.4
                                            shadowVerticalOffset: 1
                                        }
                                    }

                                    // The × (window-close-symbolic): two thin
                                    // rounded strokes.
                                    Repeater {
                                        model: [45, -45]
                                        Rectangle {
                                            required property var modelData
                                            anchors.centerIn: parent
                                            width: 11
                                            height: 2
                                            radius: 1
                                            antialiasing: true
                                            color: "#f2f2f2"
                                            rotation: modelData
                                        }
                                    }

                                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        enabled: card.showClose
                                        onClicked: overview.removeWorkspace(card.ws, rowRoot.workspaces)
                                    }
                                }
                            }
                        }

                        // Empty slot → new workspace.
                        Item {
                            x: rowRoot.slotX(rowRoot.slots - 1)
                            y: rowRoot.slotY(rowRoot.slots - 1)
                            width: rowRoot.cardW
                            height: rowRoot.cardH + 10 + 18

                            Rectangle {
                                width: rowRoot.cardW
                                height: rowRoot.cardH
                                radius: 12
                                color: newHover.hovered ? "#30ffffff" : "#18ffffff"
                                border.width: newHover.hovered ? 3 : 2
                                border.color: newHover.hovered ? Theme.accent : "#40ffffff"

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: "#bbbbbb"
                                    font.pixelSize: rowRoot.cardH * 0.25
                                }

                                HoverHandler {
                                    id: newHover
                                    onHoveredChanged: rowRoot.setHovered(rowRoot.slots - 1, hovered)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + rowRoot.nextId + " })");
                                        overview.close(rowRoot.nextId);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
