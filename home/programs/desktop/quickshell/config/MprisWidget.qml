// MprisWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris


Rectangle {
    id: root

    // --- pick the active player ---
    // 1) prefer a player that is actually playing
    // 2) otherwise fall back to the newest player
    property var activePlayer: {
        const vals = Mpris.players.values;
        if (!vals || vals.length === 0)
            return null;

        for (let i = 0; i < vals.length; ++i) {
            const p = vals[i];
            if (!p) continue;

            if (p.playing === true)
                return p;
            if (p.isPlaying === true)
                return p;

            const status = ((p.playbackStatus || p.playback_state) + "").toLowerCase();
            if (status === "playing")
                return p;
        }

        return vals[vals.length - 1];
    }

    // --- source detection: Spotify app, or YouTube in a browser ---
    // Browsers expose the page URL as xesam:url in the MPRIS metadata.
    readonly property string source: {
        const p = activePlayer;
        if (!p) return "";

        const id = (p.identity || "").toLowerCase();
        const desk = (p.desktopEntry || "").toLowerCase();
        if (id.indexOf("spotify") !== -1 || desk.indexOf("spotify") !== -1)
            return "spotify";

        const url = ((p.metadata && p.metadata["xesam:url"]) || "") + "";
        if (/^https?:\/\/([a-z0-9-]+\.)*(youtube\.com|youtu\.be)\//i.test(url))
            return "youtube";

        return "";
    }

    visible: activePlayer !== null

    // --- pill look ---
    color: "#333333"
    radius: height / 2
    border.width: 0

    implicitHeight: 24

    property int horizontalPadding: 10
    property int spacing: 8

    readonly property int maxTextWidth: 200
    implicitWidth: horizontalPadding * 2
        + (icon.visible ? icon.implicitWidth + spacing : 0)
        + Math.min(marqueeText.implicitWidth, maxTextWidth)

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        spacing: root.spacing

        // --- source icon (Spotify / YouTube) ---
        Text {
            id: icon
            visible: root.source !== ""
            text: root.source === "youtube" ? "" : ""
            color: root.source === "youtube" ? "#FF0033" : "#1ED760"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignVCenter
        }

        // --- track text (marquee) ---
        Item {
            id: marqueeContainer
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(marqueeText.implicitWidth, root.maxTextWidth)
            implicitHeight: marqueeText.implicitHeight
            clip: true

            // How far the text has to move so its end lines up with the
            // container's right edge (never more, so no empty space shows).
            readonly property real overflow: Math.max(0, marqueeText.implicitWidth - width)

            Text {
                id: marqueeText
                color: "white"
                font.pixelSize: 12
                font.bold: true
                y: (marqueeContainer.height - height) / 2
                onTextChanged: restartTimer.restart()

                text: {
                    const p = root.activePlayer;
                    if (!p) return "";

                    const title  = p.trackTitle  || "";
                    const artist = p.trackArtist || "";
                    const id     = p.identity    || "";

                    if (title && artist) return artist + " • " + title;
                    else if (title)      return title;
                    else                 return id;
                }
            }

            // Restart from the start whenever the title or available width
            // changes, so a half-finished scroll of a longer title never
            // leaves the new text shifted left.
            function restartScroll() {
                marquee.stop();
                marqueeText.x = 0;
                if (overflow > 1)
                    marquee.start();
            }
            onOverflowChanged: restartTimer.restart()
            Component.onCompleted: restartScroll()

            // Coalesce the bursts of changes when a track switches.
            Timer {
                id: restartTimer
                interval: 50
                onTriggered: marqueeContainer.restartScroll()
            }

            SequentialAnimation {
                id: marquee
                loops: Animation.Infinite

                PauseAnimation { duration: 2000 }
                NumberAnimation {
                    target: marqueeText
                    property: "x"
                    from: 0
                    to: -marqueeContainer.overflow
                    duration: marqueeContainer.overflow * 30
                    easing.type: Easing.Linear
                }
                PauseAnimation { duration: 1500 }
                NumberAnimation {
                    target: marqueeText
                    property: "x"
                    to: 0
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Click handling.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: (mouse) => {
            const p = root.activePlayer;
            if (!p) return;

            if (mouse.button === Qt.LeftButton && p.canTogglePlaying)
                p.togglePlaying();
            else if (mouse.button === Qt.RightButton && p.canGoNext)
                p.next();
            else if (mouse.button === Qt.MiddleButton && p.canGoPrevious)
                p.previous();
        }
    }
}
