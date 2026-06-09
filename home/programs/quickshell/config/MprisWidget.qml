// MprisWidget.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell
import Quickshell.Wayland


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

    visible: activePlayer !== null

    // --- pill look ---
    color: "#333333"
    radius: height / 2
    border.width: 0

    implicitHeight: 24

    property int horizontalPadding: 10
    property int spacing: 8

    // Fixed pill width — marquee handles long text
    property int pillWidth: 240
    implicitWidth: pillWidth

    // Combined hover state: pill hover OR popup hover.
    // Driven explicitly to avoid Wayland pointer-leave races.
    property bool pillHovered: false
    property bool popupHovered: false
    property bool popupShown: pillHovered || popupHovered

    onPopupShownChanged: {
        if (popupShown) {
            popupHideTimer.stop()
            hoverPopup._render = true
        } else {
            popupHideTimer.restart()
        }
    }

    // Delay before destroying the window so the hide animation can finish.
    Timer {
        id: popupHideTimer
        interval: 250
        onTriggered: hoverPopup._render = false
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
            color: "#1ED760"
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

        // --- track text (marquee) ---
        Item {
            id: marqueeContainer
            Layout.fillWidth: true
            Layout.preferredHeight: marqueeText.implicitHeight
            clip: true

            property bool needsScroll: marqueeText.implicitWidth > width

            Text {
                id: marqueeText
                color: "white"
                font.pixelSize: 12
                font.bold: true
                y: (marqueeContainer.height - height) / 2

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

            SequentialAnimation {
                running: marqueeContainer.needsScroll
                loops: Animation.Infinite

                PauseAnimation { duration: 2000 }
                NumberAnimation {
                    target: marqueeText
                    property: "x"
                    to: -(marqueeText.implicitWidth - marqueeContainer.width)
                    duration: Math.max(0, marqueeText.implicitWidth - marqueeContainer.width) * 30
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

    // Hover tracking via HoverHandler (unaffected by popup window creation).
    HoverHandler {
        onHoveredChanged: root.pillHovered = hovered
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

    PopupWindow {
        id: hoverPopup
        color: "transparent"

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Top | Edges.HCenter
        anchor.margins.top: 8
        anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide

        // 24px shadow room on all sides; card sits in the centre.
        readonly property int shadowMargin: 24

        property bool _render: false
        visible: _render

        implicitWidth: 400 + shadowMargin * 2
        implicitHeight: 190 + shadowMargin * 2

        // Track hover over the popup itself so moving the mouse from pill
        // to popup doesn't collapse it.
        HoverHandler {
            onHoveredChanged: root.popupHovered = hovered
        }

        Item {
            anchors.fill: parent

            Item {
                id: popupCard
                x: hoverPopup.shadowMargin
                width: 400
                height: 190

                // Slide down from 12px above final position when appearing.
                // Both values are positive so nothing clips at the window edge.
                y: root.popupShown
                    ? hoverPopup.shadowMargin
                    : hoverPopup.shadowMargin - 12
                opacity: root.popupShown ? 1 : 0

                Behavior on y { NumberAnimation { duration: root.popupShown ? 200 : 150; easing.type: root.popupShown ? Easing.OutCubic : Easing.InCubic } }
                Behavior on opacity { NumberAnimation { duration: root.popupShown ? 200 : 140 } }

                MultiEffect {
                    source: popupBg
                    anchors.fill: popupBg
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
                    id: popupBg
                    anchors.fill: parent
                    radius: 16
                    color: "#323232"
                    layer.enabled: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    // Album art
                    Rectangle {
                        Layout.preferredWidth: 150
                        Layout.preferredHeight: 150
                        radius: 12
                        color: "#1a1a1a"
                        clip: true

                        Image {
                            id: art
                            anchors.fill: parent
                            source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            visible: source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "♪"
                            color: "#666"
                            visible: !art.visible
                            font.pixelSize: 48
                        }
                    }

                    // Track information
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        Text {
                            text: root.activePlayer ? root.activePlayer.trackTitle || "Unknown Track" : ""
                            color: "#ffffff"
                            font.pixelSize: 15
                            font.bold: true
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Text {
                            text: root.activePlayer ? root.activePlayer.trackArtist || "Unknown Artist" : ""
                            color: "#b3b3b3"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
