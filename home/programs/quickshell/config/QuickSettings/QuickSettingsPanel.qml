// QuickSettingsPanel.qml
// GNOME-style quick-settings dropdown. A PopupWindow anchored under a bar item;
// the rounded translucent card slides down on open and dismisses on click-away
// (HyprlandFocusGrab). Wi-Fi/Bluetooth tiles expand into sliding sub-panels.
//
// Data sources are Quickshell's native singletons (no polling):
//   Networking (Wi-Fi), Bluetooth (BlueZ), Pipewire (audio), Mpris (media).
// Brightness and power-profiles use the local Process-backed services, which
// hide themselves when their CLI is missing.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth

PopupWindow {
    id: win

    // The bar item to anchor under. Set by the caller.
    property Item anchorItem: null

    // Open state — bound by the bar, which guarantees only one panel is ever
    // open (hence only one focus grab).
    property bool shown: false
    property bool _render: false
    property string view: "main"   // "main" | "wifi" | "bluetooth" | "tailscale"

    // Window the trigger lives in (the bar). Included in the focus grab so that
    // clicking the trigger to close doesn't register as "outside" and reopen.
    property var triggerWindow: null

    // Emitted on click-away / Esc; the bar clears its open state in response.
    signal dismissed()

    color: "transparent"
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.margins.top: 0
    anchor.margins.right: 0
    anchor.adjustment: PopupAdjustment.Slide

    readonly property int shadowMargin: 24
    // Desired gap between the visible card and the screen edge / bar. The card
    // is offset within its window so only this much gutter remains on the
    // top/right; the rest of the gutter (bottom/left) carries the drop shadow.
    readonly property int edgeGap: 1
    readonly property int nudge: shadowMargin - edgeGap
    visible: _render
    implicitWidth: Theme.panelWidth + shadowMargin * 2
    implicitHeight: card.height + shadowMargin * 2

    onShownChanged: {
        if (shown) { view = "main"; _render = true; nightSvc.refresh(); localSendSvc.refresh(); tailscaleSvc.refresh(true); darkSvc.refresh() }
        else hideTimer.restart()
    }
    Timer { id: hideTimer; interval: 170; onTriggered: win._render = false }


    // Keep the Pipewire default sink bound/tracked so volume stays live.
    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

    BrightnessService { id: brightnessSvc }
    PowerProfileService { id: powerSvc }
    NightLightService { id: nightSvc }
    LocalSendService { id: localSendSvc }
    TailscaleService { id: tailscaleSvc }
    DarkModeService { id: darkSvc; onOnChanged: Theme.darkMode = on }

    // Dismiss when the user clicks outside the panel.
    HyprlandFocusGrab {
        windows: win.triggerWindow ? [win, win.triggerWindow] : [win]
        active: win.shown
        onCleared: win.dismissed()
    }

    // --- helpers for tile subtitles ---
    function wifiDevice() {
        const ds = Networking.devices ? Networking.devices.values : []
        for (let i = 0; i < ds.length; ++i)
            if (ds[i] && ds[i].type === DeviceType.Wifi) return ds[i]
        return null
    }
    function wifiSubtitle() {
        if (!Networking.wifiEnabled) return "Off"
        const dev = wifiDevice()
        if (dev) {
            const ns = dev.networks.values
            for (let i = 0; i < ns.length; ++i)
                if (ns[i] && ns[i].connected) return ns[i].name
        }
        return "On"
    }
    function btSubtitle() {
        const a = Bluetooth.defaultAdapter
        if (!a || !a.enabled) return "Off"
        const ds = Bluetooth.devices ? Bluetooth.devices.values : []
        for (let i = 0; i < ds.length; ++i)
            if (ds[i] && ds[i].connected) return ds[i].name || "Connected"
        return "On"
    }
    // First connected wired device, or null. Reactive: re-evaluates when a
    // device's `connected` flag changes.
    readonly property var wiredDevice: {
        const ds = Networking.devices ? Networking.devices.values : []
        for (let i = 0; i < ds.length; ++i)
            if (ds[i] && ds[i].type === DeviceType.Wired && ds[i].connected) return ds[i]
        return null
    }

    // ============================ card ============================
    Item {
        id: cardWrapper
        anchors.fill: parent

        // slide-down + fade driven by `shown`
        Item {
            id: card
            x: win.shadowMargin + win.nudge
            width: Theme.panelWidth
            height: viewport.height + Theme.pad * 2
            y: win.shown ? win.shadowMargin - win.nudge : win.shadowMargin - win.nudge - 16
            opacity: win.shown ? 1 : 0

            Behavior on y {
                NumberAnimation { duration: win.shown ? 200 : 150; easing.type: win.shown ? Easing.OutCubic : Easing.InCubic }
            }
            Behavior on opacity { NumberAnimation { duration: win.shown ? 200 : 140 } }
            // No Behavior on height: card.height is derived from viewport.height,
            // which already animates. Easing it here too would chase a moving
            // target and make resizes feel rubbery — let the card track directly.

            // soft drop shadow — MultiEffect blurs the card behind itself; the
            // crisp opaque card (bg) draws on top, so only the halo shows.
            MultiEffect {
                source: bg
                anchors.fill: bg
                z: -1
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: "#000000"
                shadowOpacity: 0.35
                shadowBlur: 0.45
                shadowVerticalOffset: 3
                shadowHorizontalOffset: 0
            }

            Rectangle {
                id: bg
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.background
                opacity: Theme.backgroundOpacity
                layer.enabled: true   // expose as a texture for MultiEffect
            }

            // Escape closes the panel.
            Item {
                anchors.fill: parent
                focus: win.shown
                Keys.onEscapePressed: win.dismissed()
            }

            // ---------------- sliding viewport (main <-> sub) ----------------
            Item {
                id: viewport
                x: Theme.pad
                y: Theme.pad
                width: Theme.panelWidth - Theme.pad * 2
                height: win.view === "main" ? mainCol.implicitHeight : subContainer.activeHeight
                clip: true

                Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Row {
                    id: slider
                    width: viewport.width * 2
                    height: viewport.height
                    x: win.view === "main" ? 0 : -viewport.width
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    // ===================== MAIN VIEW =====================
                    ColumnLayout {
                        id: mainCol
                        width: viewport.width
                        spacing: Theme.rowGap

                        UserHeader { Layout.fillWidth: true }

                        // Wired connection banner (GNOME shows the active wired
                        // link as a non-toggle status row; the Wi-Fi tile stays
                        // below for when you roam). Visible only when plugged in.
                        Rectangle {
                            Layout.fillWidth: true
                            visible: win.wiredDevice !== null
                            implicitHeight: visible ? 52 : 0
                            radius: Theme.toggleRadius
                            color: wiredHover.hovered ? Theme.surfaceAlt : Theme.surface
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16; anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    text: "󰌗"   // ethernet plug
                                    font.family: "Symbols Nerd Font"; font.pixelSize: 20
                                    color: Theme.accent
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: "Wired"; color: Theme.text; font.pixelSize: 13; font.bold: true }
                                    Text {
                                        text: win.wiredDevice && win.wiredDevice.network
                                            ? (win.wiredDevice.network.name || "Connected") : "Connected"
                                        color: Theme.subtext; font.pixelSize: 11; elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                                Text {
                                    text: "󰅂"   // chevron -> settings
                                    font.family: "Symbols Nerd Font"; font.pixelSize: 12; color: Theme.subtext
                                }
                            }
                            HoverHandler { id: wiredHover }
                            TapHandler { onTapped: Quickshell.execDetached(["nm-connection-editor"]) }
                        }

                        // toggle grid (2 columns)
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: Theme.colGap
                            columnSpacing: Theme.colGap

                            ToggleButton {
                                Layout.fillWidth: true
                                label: "Wi-Fi"; iconName: "󰖩"; hasSubMenu: true
                                checked: Networking.wifiEnabled
                                sublabel: win.wifiSubtitle()
                                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                                onSubMenuRequested: win.view = "wifi"
                            }
                            ToggleButton {
                                Layout.fillWidth: true
                                label: "Bluetooth"; iconName: "󰂯"; hasSubMenu: true
                                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                                sublabel: win.btSubtitle()
                                onToggled: if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                                onSubMenuRequested: win.view = "bluetooth"
                            }
                            ToggleButton {
                                Layout.fillWidth: true
                                label: "Dark Style"; iconName: "󰖔"
                                checked: darkSvc.on
                                sublabel: darkSvc.on ? "On" : "Off"
                                onToggled: darkSvc.toggle()
                            }
                            ToggleButton {
                                Layout.fillWidth: true
                                label: "Night Light"; iconName: "󰽢"
                                checked: nightSvc.on
                                sublabel: nightSvc.on ? "On" : "Off"
                                onToggled: nightSvc.toggle()
                            }
                            ToggleButton {
                                id: tsTile
                                Layout.fillWidth: true
                                label: "Tailscale"; hasSubMenu: true
                                iconComponent: Component {
                                    TailscaleIcon { size: 20; color: tsTile.iconColor }
                                }
                                checked: tailscaleSvc.active
                                sublabel: tailscaleSvc.needsLogin ? "Needs login"
                                        : (tailscaleSvc.active
                                            ? (tailscaleSvc.selfName || "Connected")
                                            : (tailscaleSvc.installed ? "Off" : "Not installed"))
                                onToggled: tailscaleSvc.toggleTailscale()
                                onSubMenuRequested: win.view = "tailscale"
                            }
                            ToggleButton {
                                Layout.fillWidth: true
                                visible: powerSvc.available
                                label: "Power Saver"; iconName: "󰌪"
                                checked: powerSvc.powerSaver
                                sublabel: powerSvc.powerSaver ? "On" : "Off"
                                onToggled: powerSvc.toggleSaver()
                            }
                            ToggleButton {
                                Layout.fillWidth: true
                                label: "LocalSend"; iconName: "󰒖"
                                checked: localSendSvc.on
                                sublabel: localSendSvc.on ? "On" : "Off"
                                onToggled: localSendSvc.toggle()
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

                        // volume
                        SettingsSlider {
                            Layout.fillWidth: true
                            readonly property var sink: Pipewire.defaultAudioSink
                            iconActive: !(sink && sink.audio && sink.audio.muted)
                            iconName: (sink && sink.audio && sink.audio.muted) ? "󰝟" : "󰕾"
                            value: (sink && sink.audio) ? sink.audio.volume : 0
                            onMoved: function(v) {
                                Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(3)])
                            }
                            onIconActivated: {
                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                            }
                        }

                        // brightness (hidden when no backend)
                        SettingsSlider {
                            Layout.fillWidth: true
                            visible: brightnessSvc.available
                            iconName: "󰃠"
                            value: brightnessSvc.brightness
                            onMoved: (v) => brightnessSvc.setBrightness(v)
                        }

                        // media player (only when something is loaded)
                        Loader {
                            Layout.fillWidth: true
                            active: Mpris.players.values.length > 0
                            visible: active
                            sourceComponent: QsMediaPlayer { }
                        }
                    }

                    // ===================== SUB VIEW =====================
                    Item {
                        id: subContainer
                        width: viewport.width
                        height: viewport.height
                        readonly property real activeHeight:
                            win.view === "wifi" ? wifiPanel.implicitHeight
                            : win.view === "bluetooth" ? btPanel.implicitHeight
                            : win.view === "tailscale" ? tsPanel.implicitHeight
                            : 0

                        WifiSubPanel {
                            id: wifiPanel
                            width: parent.width

                            visible: win.view === "wifi"
                            onBack: win.view = "main"
                        }
                        BluetoothSubPanel {
                            id: btPanel
                            width: parent.width

                            visible: win.view === "bluetooth"
                            onBack: win.view = "main"
                        }
                        TailscaleSubPanel {
                            id: tsPanel
                            width: parent.width
                            service: tailscaleSvc

                            visible: win.view === "tailscale"
                            onVisibleChanged: if (visible) tailscaleSvc.refresh(true)
                            onBack: win.view = "main"
                        }
                    }
                }
            }
        }
    }
}
