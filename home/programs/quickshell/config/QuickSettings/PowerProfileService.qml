// PowerProfileService.qml
// Thin wrapper around `powerprofilesctl`. Self-detects availability so the
// Power Saver toggle hides on machines without power-profiles-daemon.
import QtQuick
import Quickshell.Io

QtObject {
    id: svc

    property bool available: false
    property string activeProfile: "balanced"   // performance | balanced | power-saver

    readonly property bool powerSaver: activeProfile === "power-saver"

    // Toggle between power-saver and balanced (GNOME-style single switch).
    function toggleSaver() {
        setProfile(powerSaver ? "balanced" : "power-saver")
    }

    function setProfile(p) {
        if (!available) return
        setProc.command = ["powerprofilesctl", "set", p]
        setProc.running = true
        activeProfile = p
    }

    function refresh() {
        if (available) readProc.running = true
    }

    property Process _detect: Process {
        command: ["sh", "-c", "command -v powerprofilesctl >/dev/null && echo yes || echo no"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                svc.available = text.trim() === "yes"
                if (svc.available) readProc.running = true
            }
        }
    }

    property Process setProc: Process { running: false }

    property Process readProc: Process {
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) svc.activeProfile = p
            }
        }
    }
}
