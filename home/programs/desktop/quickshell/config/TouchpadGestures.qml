// TouchpadGestures.qml
// Streams touchpad swipe gestures (begin / every update / end) into QML.
//
// Hyprland only runs a gesture's Lua action once the swipe has ended, which
// is too late for anything that should follow the fingers. So this reads
// libinput directly, through `libinput debug-events` (pkgs.libinput, see
// quickshell.nix). That needs read access to /dev/input/event*, i.e. the user
// must be in the `input` group. The output is filtered to swipe lines before it
// reaches the shell, so keystrokes and pointer motion never get here.
//
// If libinput can't run, nothing breaks: the signals just never fire, and
// the reader is retried with a growing back-off.
import Quickshell
import Quickshell.Io
import QtQuick
import "GestureParser.js" as GestureParser

Scope {
    id: root

    // dx / dy: accelerated libinput deltas; positive dy = fingers moving
    // down the touchpad. time: libinput event time in ms.
    signal swipeBegin(int fingers, real time)
    signal swipeUpdate(int fingers, real dx, real dy, real time)
    signal swipeEnd(int fingers, bool cancelled, real time)

    property int retryMs: 2000
    property bool warnedInvalid: false

    Process {
        id: reader
        running: true
        command: ["sh", "-c",
            "exec libinput debug-events 2>/dev/null | grep --line-buffered GESTURE_SWIPE_"]

        stdout: SplitParser {
            onRead: data => {
                const ev = GestureParser.parse(data);
                if (!ev) return;
                switch (ev.type) {
                case "begin":  root.swipeBegin(ev.fingers, ev.time); break;
                case "update": root.swipeUpdate(ev.fingers, ev.dx, ev.dy, ev.time); break;
                case "end":    root.swipeEnd(ev.fingers, ev.cancelled, ev.time); break;
                default:
                    if (!root.warnedInvalid) {
                        root.warnedInvalid = true;
                        console.warn("TouchpadGestures: unrecognised libinput line:", data);
                    }
                    return;
                }
                root.retryMs = 2000; // it works; reset the back-off
            }
        }

        onRunningChanged: {
            if (running) return;
            console.warn("TouchpadGestures: libinput reader stopped, retrying in",
                root.retryMs / 1000, "s");
            retry.interval = root.retryMs;
            retry.restart();
            root.retryMs = Math.min(root.retryMs * 2, 10000);
        }
    }

    Timer {
        id: retry
        onTriggered: reader.running = true
    }
}
