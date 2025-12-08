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

            // try typical playing flags
            if (p.playing === true)
                return p;
            if (p.isPlaying === true)
                return p;

            const status = ((p.playbackStatus || p.playback_state) + "").toLowerCase();
            if (status === "playing")
                return p;
        }

        // nothing is playing, show the most recently created
        return vals[vals.length - 1];
    }

    visible: activePlayer !== null

    // --- pill look ---
    color: "#333333"
    radius: height / 2
    border.width: 0

    implicitHeight: 24

    // pill sizing: just content + padding (Waybar-style)
    property int horizontalPadding: 10
    property int spacing: 8

    // overall width = width of row content + left/right padding
    implicitWidth: row.implicitWidth + horizontalPadding * 2

    // Max length of text (similar to Waybar's title-len)
    property int titleMaxChars: 40

    function clampText(s) {
        if (!s)
            return "";
        if (s.length <= titleMaxChars)
            return s;
        return s.slice(0, titleMaxChars - 1) + "…";
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        spacing: root.spacing

        // --- icon: only Spotify gets the logo ---
        Text {
            id: icon
            text: ""
            color: "white"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignVCenter

            visible: {
                const p = root.activePlayer;
                if (!p) return false;

                const id = (p.identity || "").toLowerCase();
                const desk = (p.desktopEntry || "").toLowerCase();

                return id.indexOf("spotify") !== -1 || desk.indexOf("spotify") !== -1;
            }
        }

        // --- track text ---
        Text {
            id: trackText
            color: "white"
            font.pixelSize: 12
            font.bold: true
            elide: Text.ElideRight   // in case layout squeezes us
            Layout.fillWidth: true   // fill *within* the pill

            text: {
                const p = root.activePlayer;
                if (!p) return "";

                const title  = p.trackTitle  || "";
                const artist = p.trackArtist || "";
                const id     = p.identity    || "";

                let s;
                if (title && artist) s = artist + " • " + title;
                else if (title)      s = title;
                else                 s = id;

                return root.clampText(s);
            }
        }
    }

    // --- click over whole pill ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: (mouse) => {
            const p = root.activePlayer;
            if (!p)
                return;

            if (mouse.button === Qt.LeftButton && p.canTogglePlaying)
                p.togglePlaying();
            else if (mouse.button === Qt.RightButton && p.canGoNext)
                p.next();
            else if (mouse.button === Qt.MiddleButton && p.canGoPrevious)
                p.previous();
        }
    }
}
