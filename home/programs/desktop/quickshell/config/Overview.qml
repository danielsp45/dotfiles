// Overview.qml
// GNOME Activities-style workspace overview: a full-screen layer on the
// focused monitor showing that monitor's workspaces as live thumbnails.
//
//   • open/close/toggle over IPC:  qs ipc call overview toggle
//     (bound to a three-finger swipe up / down in hyprland/config/input.lua)
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
        function open(): void { overview.open() }
        function close(): void { overview.close() }
        function toggle(): void { overview.toggle() }
    }

    Variants {
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

            onActiveChanged: {
                if (active) {
                    mapped = true;
                    content.forceActiveFocus();
                    // Let the surface map and the thumbnails build first, so the
                    // animation doesn't stutter on its first frames.
                    startTimer.restart();
                } else {
                    startTimer.stop();
                    anim.stop();
                    anim.to = 0;
                    anim.duration = 400;
                    anim.easing.type = Easing.InOutCubic;
                    anim.start();
                }
            }
            Timer {
                id: startTimer
                interval: 40
                onTriggered: {
                    anim.stop();
                    anim.to = 1;
                    anim.duration = 320;
                    anim.easing.type = Easing.OutCubic;
                    anim.start();
                }
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
                    // as fits (capped, so a single workspace isn't huge).
                    readonly property real gap: 28
                    readonly property real screenW: win.modelData.width
                    readonly property real screenH: win.modelData.height
                    readonly property real cardW: Math.min(screenW * 0.32,
                        (width * 0.92 - gap * (slots - 1)) / slots)
                    readonly property real cardH: cardW * screenH / screenW
                    readonly property real s: cardW / screenW

                    // Card positions (labels hang below the cards).
                    readonly property real rowW: slots * cardW + (slots - 1) * gap
                    readonly property real cardY: (height - cardH) / 2 - 14
                    // Slot under the pointer (-1 = none). The blue ring marks it, or
                    // the current workspace when nothing is hovered.
                    property int hoveredIndex: -1
                    function setHovered(i, on) {
                        if (on) hoveredIndex = i;
                        else if (hoveredIndex === i) hoveredIndex = -1;
                    }
                    function slotX(i) { return (width - rowW) / 2 + i * (cardW + gap); }

                    // --- zoom: the card of zoomWs grows to fill the screen ---
                    readonly property int zoomIndex: {
                        for (let i = 0; i < workspaces.length; ++i)
                            if (workspaces[i].id === overview.zoomWs) return i;
                        return overview.zoomWs === nextId ? slots - 1 : 0;
                    }
                    readonly property real f: 1 - win.progress
                    readonly property real ax: slotX(zoomIndex)
                    readonly property real zs: (cardW + (screenW - cardW) * f) / cardW
                    transform: [
                        Scale { xScale: rowRoot.zs; yScale: rowRoot.zs },
                        Translate {
                            x: rowRoot.ax * (1 - rowRoot.f) - rowRoot.zs * rowRoot.ax
                            y: rowRoot.cardY * (1 - rowRoot.f) - rowRoot.zs * rowRoot.cardY
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
                                y: rowRoot.cardY
                                width: rowRoot.cardW
                                height: rowRoot.cardH + label.height + 10

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
                                            x: (at[0] - monX) * rowRoot.s
                                            y: (at[1] - monY) * rowRoot.s
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
                            }
                        }

                        // Empty slot → new workspace.
                        Item {
                            x: rowRoot.slotX(rowRoot.slots - 1)
                            y: rowRoot.cardY
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
