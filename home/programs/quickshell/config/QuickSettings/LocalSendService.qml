// LocalSendService.qml
// Toggles a background LocalSend instance (the GUI app runs in the tray and
// keeps receiving). "on" == the app process is alive, detected via pgrep, so
// the tile reflects reality even if LocalSend is started/quit elsewhere.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: svc

    property bool on: false

    function refresh() { checkProc.running = true }

    function toggle() {
        if (on) Quickshell.execDetached(["pkill", "-f", "localsend_app"])
        else    Quickshell.execDetached(["localsend_app"])
        // Launch/quit is async; re-check shortly after.
        recheck.restart()
    }

    property Process checkProc: Process {
        // Bracket trick so pgrep doesn't match its own command line.
        command: ["sh", "-c", "pgrep -f '[l]ocalsend_app' >/dev/null && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: svc.on = text.trim() === "on"
        }
    }

    property Timer recheck: Timer {
        interval: 800
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
