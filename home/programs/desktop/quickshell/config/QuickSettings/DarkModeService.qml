// DarkModeService.qml
// Reads and writes the system-wide color-scheme via gsettings so the Dark Style
// toggle actually affects GTK/Qt apps. State is fetched on refresh() and after
// each toggle to reflect the real setting rather than an optimistic guess.
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: svc

    property bool on: false

    function refresh() { checkProc.running = true }

    function toggle() {
        const theme = svc.on ? "adw-gtk3" : "adw-gtk3-dark"
        Quickshell.execDetached(["dconf", "write",
            "/org/gnome/desktop/interface/gtk-theme", `'${theme}'`])
        recheck.restart()
    }

    property Process checkProc: Process {
        command: ["dconf", "read", "/org/gnome/desktop/interface/gtk-theme"]
        stdout: StdioCollector {
            onStreamFinished: svc.on = text.includes("dark")
        }
    }

    property Timer recheck: Timer {
        interval: 300
        onTriggered: svc.refresh()
    }

    Component.onCompleted: refresh()
}
