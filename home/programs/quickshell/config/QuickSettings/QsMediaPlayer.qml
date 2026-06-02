// QsMediaPlayer.qml
// MPRIS media row: album art, title/artist, prev/playPause/next.
// Active-player selection mirrors MprisWidget.qml (prefer a playing player,
// else the most recent).
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

RowLayout {
    id: root

    property var activePlayer: {
        const vals = Mpris.players.values
        if (!vals || vals.length === 0) return null
        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i]
            if (!p) continue
            if (p.playbackState === MprisPlaybackState.Playing) return p
        }
        return vals[vals.length - 1]
    }

    readonly property bool isPlaying: activePlayer
        && activePlayer.playbackState === MprisPlaybackState.Playing

    spacing: 12
    implicitHeight: 44

    // album art (circular)
    Rectangle {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 20
        color: Theme.surface
        clip: true

        Image {
            id: art
            anchors.fill: parent
            source: root.activePlayer ? (root.activePlayer.trackArtUrl || "") : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: source !== ""
        }
        Text {
            anchors.centerIn: parent
            text: "󰝚"
            font.family: "Symbols Nerd Font"
            font.pixelSize: 20
            color: Theme.subtext
            visible: !art.visible
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Text {
            text: root.activePlayer ? (root.activePlayer.trackTitle || "Unknown") : ""
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        Text {
            text: root.activePlayer ? (root.activePlayer.trackArtist || "") : ""
            color: Theme.subtext
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text !== ""
        }
    }

    // transport controls
    Repeater {
        model: [
            { glyph: "󰒮", act: "previous" },
            { glyph: "", act: "playPause" },
            { glyph: "󰒭", act: "next" }
        ]
        delegate: Rectangle {
            required property var modelData
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 15
            color: ctlTap.pressed ? Theme.surfaceAlt
                : (ctlHover.hovered ? Theme.surface : "transparent")

            Text {
                anchors.centerIn: parent
                font.family: "Symbols Nerd Font"
                font.pixelSize: 16
                color: Theme.text
                text: modelData.act === "playPause"
                    ? (root.isPlaying ? "󰏤" : "󰐊")   // pause / play
                    : modelData.glyph
            }

            HoverHandler { id: ctlHover }
            TapHandler {
                id: ctlTap
                onTapped: {
                    const p = root.activePlayer
                    if (!p) return
                    if (modelData.act === "previous" && p.canGoPrevious) p.previous()
                    else if (modelData.act === "next" && p.canGoNext) p.next()
                    else if (modelData.act === "playPause" && p.canTogglePlaying) p.togglePlaying()
                }
            }
        }
    }
}
