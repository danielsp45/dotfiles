// TailscaleSubPanel.qml
// Quick Settings sub-view for Tailscale (slides in from the "Tailscale" tile,
// same pattern as WifiSubPanel / BluetoothSubPanel). Pure presentation over a
// TailscaleService passed in as `service`; every action shells back out through
// it.
//
// Feature parity with omarchy's panel: connect/disconnect toggle, account
// switching with an operator-authorization prompt, exit-node selection (tailnet
// peers + Mullvad regions via an inline search picker), and a peer list with a
// per-row copy menu (name / DNS / IPv4 / IPv6). Mouse-driven; the parent card
// handles Escape / click-away.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

ColumnLayout {
    id: root
    signal back()

    property var service: null

    spacing: 8

    // --- derived view state ---
    readonly property bool showConnections: service && (service.accounts.length > 1 || service.accountsAccessDenied)
    readonly property bool showPeers: service && service.active && service.peers.length > 0
    property bool mullvadPickerOpen: false
    property string mullvadQuery: ""

    // Base tint for active/selected rows — distinct from the grey hover fill so
    // "this is the current one" doesn't read the same as "the pointer is here".
    // Matches WifiSubPanel's connected-network row.
    readonly property color activeTint: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)

    readonly property var exitNodeRows: {
        var nodes = []
        if (!service) return nodes
        for (var i = 0; i < service.tailnetExitNodes.length; i++) nodes.push(service.tailnetExitNodes[i])
        for (var j = 0; j < service.mullvadRegions.length; j++)
            if (service.mullvadRegions[j].ExitNode === true) nodes.push(service.mullvadRegions[j])
        if (service.mullvadRegions.length > 0)
            nodes.push({ id: "mullvad:add", AddMullvad: true, DisplayName: "Choose Mullvad region" })
        return nodes
    }
    readonly property bool showExitNodes: service && service.active && exitNodeRows.length > 0

    readonly property var filteredMullvadRegions: {
        var q = String(mullvadQuery || "").trim().toLowerCase()
        var r = []
        if (!service) return r
        for (var i = 0; i < service.mullvadRegions.length; i++) {
            var node = service.mullvadRegions[i]
            var label = (String(node.City || "") + " " + String(node.Country || "")).toLowerCase()
            if (q === "" || label.indexOf(q) !== -1) r.push(node)
        }
        return r
    }

    function chooseExitNode(peer) {
        if (!peer) return
        if (peer.AddMullvad === true) { mullvadPickerOpen = !mullvadPickerOpen; return }
        service.setExitNode(peer)
        mullvadPickerOpen = false
    }

    onVisibleChanged: if (!visible) { mullvadPickerOpen = false; mullvadQuery = "" }

    // --- header ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            Layout.preferredWidth: 28; Layout.preferredHeight: 28
            radius: 14
            color: backTap.pressed ? Theme.surfaceAlt
                : (backHover.hovered ? Theme.surface : "transparent")
            Text {
                anchors.centerIn: parent; text: "󰅁"
                font.family: "Symbols Nerd Font"; font.pixelSize: 16; color: Theme.text
            }
            HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: backTap; onTapped: root.back() }
        }
        Text { text: "Tailscale"; color: Theme.text; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider }

    // --- status + connect toggle ---
    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        TailscaleIcon {
            size: 22
            color: root.service && root.service.needsLogin ? Theme.danger
                 : (root.service && root.service.active ? Theme.accent : Theme.subtext)
            // Ease the state color so the mark, switch track, and knob move as
            // one motion when connecting/disconnecting.
            Behavior on color { ColorAnimation { duration: 120 } }
            Layout.alignment: Qt.AlignVCenter
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 0
            Text {
                text: root.service && root.service.installed ? (root.service.selfName || "Tailscale") : "Tailscale"
                color: Theme.text; font.pixelSize: 13; font.bold: true
                elide: Text.ElideRight; Layout.fillWidth: true
            }
            Text {
                text: {
                    if (!root.service) return ""
                    if (root.service.active && root.service.selfIp !== "")
                        return root.service.statusText + " · " + root.service.selfIp
                    return root.service.statusText
                }
                color: Theme.subtext; font.pixelSize: 11
                elide: Text.ElideRight; Layout.fillWidth: true
            }
        }
        Rectangle {
            Layout.preferredWidth: 44; Layout.preferredHeight: 24; radius: 12
            color: root.service && root.service.active ? Theme.accent : Theme.surfaceAlt
            scale: connectTap.pressed ? 0.92 : 1.0
            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            Rectangle {
                width: 18; height: 18; radius: 9; color: "white"
                anchors.verticalCenter: parent.verticalCenter
                x: root.service && root.service.active ? parent.width - width - 3 : 3
                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor; enabled: root.service && root.service.installed }
            TapHandler { id: connectTap; enabled: root.service && root.service.installed; onTapped: root.service.toggleTailscale() }
        }
    }

    // --- action status / error ---
    Text {
        Layout.fillWidth: true
        visible: root.service && (root.service.actionStatus !== "" || root.service.lastError !== "")
        text: !root.service ? "" : (root.service.actionStatus !== "" ? root.service.actionStatus : root.service.lastError)
        color: (root.service && root.service.lastError !== "" && root.service.actionStatus === "") ? Theme.danger : Theme.subtext
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    Text {
        Layout.fillWidth: true
        visible: root.service && !root.service.installed
        text: "Tailscale CLI is not installed or not on PATH."
        color: Theme.subtext; font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.divider; visible: root.showConnections || root.showExitNodes || root.showPeers }

    // --- scrollable body (connections / exit nodes / machines) ---
    Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(body.implicitHeight, 320)
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: body
            width: parent.width
            spacing: 10

            // ---------------- CONNECTIONS ----------------
            Text {
                visible: root.showConnections
                text: "CONNECTIONS"
                color: Theme.subtext; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
            }

            Rectangle {
                Layout.fillWidth: true
                visible: root.service && root.service.accountsAccessDenied
                implicitHeight: authRow.implicitHeight + 14
                radius: 10
                color: authTap.pressed ? Theme.surfaceAlt
                     : (authHover.hovered ? Theme.surface : "transparent")

                RowLayout {
                    id: authRow
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10; anchors.rightMargin: 10
                    spacing: 10
                    Text {
                        text: "󰒃"; font.family: "Symbols Nerd Font"; font.pixelSize: 18
                        color: Theme.subtext; Layout.alignment: Qt.AlignVCenter
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 1
                        Text { Layout.fillWidth: true; text: "Authorize Tailscale operator"; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: "Allow this user to manage Tailscale without sudo"; color: Theme.subtext; font.pixelSize: 11; elide: Text.ElideRight }
                    }
                }
                HoverHandler { id: authHover; enabled: root.service && !root.service.busy; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: authTap; onTapped: if (root.service) root.service.authorizeTailscaleOperator() }
            }

            Repeater {
                model: root.showConnections && root.service ? root.service.accounts : []
                AccountRow { required property var modelData; Layout.fillWidth: true; account: modelData }
            }

            // ---------------- EXIT NODES ----------------
            Text {
                visible: root.showExitNodes
                text: "EXIT NODES"
                color: Theme.subtext; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
            }

            Repeater {
                model: root.showExitNodes ? root.exitNodeRows : []
                ExitNodeRow { required property var modelData; Layout.fillWidth: true; peer: modelData }
            }

            // inline Mullvad region picker — animated expander. Height and
            // opacity glide together so it unfolds instead of popping. Content is
            // clipped so rows never spill during the animation, and the model
            // stays bound (not gated on `open`) so the picker keeps its full
            // height while collapsing.
            Item {
                id: mullvadPicker
                Layout.fillWidth: true
                clip: true
                readonly property bool open: root.mullvadPickerOpen
                implicitHeight: open ? mullvadPickerCol.implicitHeight : 0
                opacity: open ? 1 : 0
                Behavior on implicitHeight { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }

                ColumnLayout {
                    id: mullvadPickerCol
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 8
                        color: Theme.surface
                        border.color: mullvadSearch.activeFocus ? Theme.accent : Theme.divider
                        border.width: 1
                        TextField {
                            id: mullvadSearch
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            background: null
                            color: Theme.text
                            placeholderText: "Search regions"
                            placeholderTextColor: Theme.subtext
                            font.pixelSize: 13
                            text: root.mullvadQuery
                            onTextChanged: root.mullvadQuery = text
                            Keys.onEscapePressed: root.mullvadPickerOpen = false
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.filteredMullvadRegions.length === 0
                        text: "No Mullvad regions found."
                        color: Theme.subtext; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter
                    }
                    Repeater {
                        model: root.filteredMullvadRegions
                        MullvadRegionRow { required property var modelData; Layout.fillWidth: true; peer: modelData }
                    }
                }
            }

            // ---------------- MACHINES ----------------
            Text {
                visible: root.service && root.service.installed && root.service.active
                text: "MACHINES"
                color: Theme.subtext; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
            }
            Text {
                Layout.fillWidth: true
                visible: root.service && root.service.active && root.service.peers.length === 0
                text: "No machines found on this tailnet."
                color: Theme.subtext; font.pixelSize: 13; horizontalAlignment: Text.AlignHCenter
            }
            Repeater {
                model: root.showPeers ? root.service.peers : []
                PeerRow { required property var modelData; Layout.fillWidth: true; peer: modelData }
            }
        }
    }

    // ============================ row components ============================

    component AccountRow: Rectangle {
        id: accountRow
        property var account: null
        readonly property bool selectedAccount: account && account.selected === true
        readonly property bool switching: account && root.service && root.service.switchingAccountId === String(account.id || "")

        implicitHeight: 36
        radius: 10
        color: acctTap.pressed ? Theme.surfaceAlt
             : (acctHover.hovered ? Theme.surface
             : (selectedAccount ? root.activeTint : "transparent"))

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            spacing: 10
            Text {
                text: accountRow.selectedAccount ? "" : "󰀄"
                font.family: "Symbols Nerd Font"; font.pixelSize: 15
                color: accountRow.selectedAccount ? Theme.accent : Theme.subtext
                opacity: accountRow.switching ? 0.4 : 1.0
                Layout.alignment: Qt.AlignVCenter
                SequentialAnimation on opacity {
                    running: accountRow.switching; loops: Animation.Infinite
                    NumberAnimation { to: 1.0; duration: 420 }
                    NumberAnimation { to: 0.4; duration: 420 }
                }
            }
            Text {
                Layout.fillWidth: true
                text: accountRow.account && root.service ? root.service.accountLabel(accountRow.account) : "Account"
                color: Theme.text; font.pixelSize: 13; font.bold: accountRow.selectedAccount; elide: Text.ElideRight
            }
        }
        HoverHandler { id: acctHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: acctTap; onTapped: if (accountRow.account && root.service) root.service.switchAccount(accountRow.account.id) }
    }

    component ExitNodeRow: Rectangle {
        id: exitRow
        property var peer: null
        readonly property bool addMullvad: peer && peer.AddMullvad === true
        readonly property bool activeExit: peer && peer.ExitNode === true
        readonly property bool settingExit: peer && root.service && root.service.settingExitNodeId === String(peer.id || "")

        readonly property bool highlighted: activeExit || (addMullvad && root.mullvadPickerOpen)

        implicitHeight: 36
        radius: 10
        color: exitTap.pressed ? Theme.surfaceAlt
             : (exitHover.hovered ? Theme.surface
             : (highlighted ? root.activeTint : "transparent"))

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            spacing: 10
            Text {
                text: exitRow.addMullvad ? "󰐕" : (exitRow.peer && exitRow.peer.Mullvad === true ? "󰖂" : "󱇢")
                font.family: "Symbols Nerd Font"; font.pixelSize: 15
                color: (exitRow.activeExit || exitRow.settingExit || exitRow.addMullvad) ? Theme.accent : Theme.subtext
                Layout.alignment: Qt.AlignVCenter
                NumberAnimation on rotation {
                    running: exitRow.settingExit; from: 0; to: 360; duration: 900; loops: Animation.Infinite
                }
                onRotationChanged: if (!exitRow.settingExit && rotation !== 0) rotation = 0
            }
            Text {
                Layout.fillWidth: true
                text: exitRow.peer ? String(exitRow.peer.DisplayName || exitRow.peer.HostName || "Unknown") : "Unknown"
                color: Theme.text; font.pixelSize: 13; font.bold: exitRow.activeExit; elide: Text.ElideRight
            }
            Text {
                visible: exitRow.activeExit
                text: "󰗠"; font.family: "Symbols Nerd Font"; font.pixelSize: 14
                color: Theme.accent; Layout.alignment: Qt.AlignVCenter
            }
        }
        HoverHandler { id: exitHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: exitTap; onTapped: root.chooseExitNode(exitRow.peer) }
    }

    component MullvadRegionRow: Rectangle {
        id: regionRow
        property var peer: null
        readonly property bool activeExit: peer && peer.ExitNode === true

        implicitHeight: 40
        radius: 10
        color: regionTap.pressed ? Theme.surfaceAlt
             : (regionHover.hovered ? Theme.surface
             : (activeExit ? root.activeTint : "transparent"))

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            spacing: 10
            Text {
                text: "󰖂"; font.family: "Symbols Nerd Font"; font.pixelSize: 15
                color: regionRow.activeExit ? Theme.accent : Theme.subtext
                Layout.alignment: Qt.AlignVCenter
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                Text {
                    Layout.fillWidth: true
                    text: regionRow.peer ? String(regionRow.peer.City || regionRow.peer.Country || "Unknown") : "Unknown"
                    color: Theme.text; font.pixelSize: 13; font.bold: regionRow.activeExit; elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true; visible: text !== ""
                    text: regionRow.peer ? String(regionRow.peer.Country || "") : ""
                    color: Theme.subtext; font.pixelSize: 11; elide: Text.ElideRight
                }
            }
        }
        HoverHandler { id: regionHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: regionTap; onTapped: root.chooseExitNode(regionRow.peer) }
    }

    component PeerRow: ColumnLayout {
        id: peerRow
        property var peer: null
        property bool copyOpen: false

        readonly property string peerName: peer ? String(peer.DisplayName || peer.HostName || "Unknown") : "Unknown"
        readonly property string peerIp: peer && peer.TailscaleIPs && peer.TailscaleIPs.length > 0 ? String(peer.TailscaleIPs[0]) : ""
        readonly property string peerIpv6: peer && peer.TailscaleIPv6 && peer.TailscaleIPv6.length > 0 ? String(peer.TailscaleIPv6[0]) : ""
        readonly property string peerDns: peer ? String(peer.DNSName || "") : ""
        readonly property var copyOptions: {
            var o = []
            if (peerName !== "") o.push({ kind: "name", label: peerName })
            if (peerDns !== "") o.push({ kind: "dns", label: peerDns })
            if (peerIpv6 !== "") o.push({ kind: "ipv6", label: peerIpv6 })
            if (peerIp !== "") o.push({ kind: "ip", label: peerIp })
            return o
        }
        function copyOption(kind) {
            if (!root.service) return
            if (kind === "name") root.service.copyPeerName(peer)
            else if (kind === "dns") root.service.copyPeerDnsName(peer)
            else if (kind === "ipv6") root.service.copyToClipboard(peerIpv6, peerName + " IPv6")
            else if (kind === "ip") root.service.copyPeerIp(peer)
            copyOpen = false
        }

        spacing: 2

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: peerInner.implicitHeight + 12
            radius: 10
            color: peerHover.hovered ? Theme.surface : "transparent"

            RowLayout {
                id: peerInner
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10; anchors.rightMargin: 8
                spacing: 10
                Text {
                    text: root.service ? root.service.osIcon(peerRow.peer ? peerRow.peer.OS : "") : "󰟀"
                    font.family: "Symbols Nerd Font"; font.pixelSize: 16
                    color: Theme.text; Layout.alignment: Qt.AlignVCenter
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 1
                    Text { Layout.fillWidth: true; text: peerRow.peerName; color: Theme.text; font.pixelSize: 13; elide: Text.ElideRight }
                    Text {
                        Layout.fillWidth: true
                        text: {
                            var parts = []
                            if (peerRow.peerIp !== "") parts.push(peerRow.peerIp)
                            if (peerRow.peerDns !== "") parts.push(peerRow.peerDns)
                            return parts.join(" · ")
                        }
                        color: Theme.subtext; font.pixelSize: 11; elide: Text.ElideRight
                    }
                }
                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 28; implicitHeight: 28; radius: 8
                    visible: peerRow.copyOptions.length > 0
                    scale: copyTap.pressed ? 0.9 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                    color: (copyBtnHover.hovered || peerRow.copyOpen) ? Theme.surfaceAlt : "transparent"
                    Text {
                        anchors.centerIn: parent; text: "󰆏"
                        font.family: "Symbols Nerd Font"; font.pixelSize: 15; color: Theme.text
                    }
                    HoverHandler { id: copyBtnHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: copyTap; onTapped: peerRow.copyOpen = !peerRow.copyOpen }
                }
            }
            HoverHandler { id: peerHover }
        }

        // inline copy menu — animated expander (unfolds under the peer row).
        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: peerRow.copyOpen ? copyMenuCol.implicitHeight : 0
            opacity: peerRow.copyOpen ? 1 : 0
            Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 110 } }

            ColumnLayout {
                id: copyMenuCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: peerRow.copyOptions
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: 34
                        implicitHeight: 30
                        radius: 8
                        color: choiceTap.pressed ? Theme.surfaceAlt
                             : (choiceHover.hovered ? Theme.surface : "transparent")
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 8
                            Text { Layout.fillWidth: true; text: String(modelData.label || ""); color: Theme.text; font.pixelSize: 12; elide: Text.ElideRight }
                            Text { text: "󰆏"; font.family: "Symbols Nerd Font"; font.pixelSize: 13; color: Theme.subtext }
                        }
                        HoverHandler { id: choiceHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: choiceTap; onTapped: peerRow.copyOption(String(modelData.kind || "")) }
                    }
                }
            }
        }
    }
}
