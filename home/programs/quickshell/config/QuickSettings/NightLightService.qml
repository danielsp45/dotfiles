// NightLightService.qml
// Reflects the real hyprsunset state instead of an optimistic guess. The
// toggle-hyprsunset script starts/kills `hyprsunset`, so "on" == process alive.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: svc

    property bool on: false

    function refresh() { checkProc.running = true }

    function toggle() {
        Quickshell.execDetached(["bash", "-lc",
            "/home/daniel/.local/share/config/bin/toggle-hyprsunset"])
        // The script starts/stops asynchronously; re-check shortly after.
        recheck.restart()
    }

    property Process checkProc: Process {
        command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: svc.on = text.trim() === "on"
        }
    }

    property Timer recheck: Timer {
        interval: 400
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
