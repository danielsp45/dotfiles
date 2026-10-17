// BrightnessService.qml
// Thin wrapper around `brightnessctl`. Self-detects availability: `available`
// stays false (and the brightness slider stays hidden) unless both
// `brightnessctl` and at least one /sys/class/backlight device are present.
import QtQuick
import Quickshell.Io

QtObject {
    id: svc

    property bool available: false
    property real brightness: 0.0   // 0.0 - 1.0
    property int  _max: 0

    function setBrightness(v) {
        if (!available) return
        const pct = Math.max(1, Math.min(100, Math.round(v * 100)))
        setProc.command = ["brightnessctl", "-q", "set", pct + "%"]
        setProc.running = true
        brightness = v
    }

    function refresh() {
        if (available) readProc.running = true
    }

    // Detect backend, then prime the first reading.
    property Process _detect: Process {
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && ls /sys/class/backlight 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                svc.available = text.trim() !== ""
                if (svc.available) readProc.running = true
            }
        }
    }

    property Process setProc: Process { running: false }

    // `brightnessctl -m get,max` -> "name,class,cur,pct%,max"; we parse cur+max.
    property Process readProc: Process {
        command: ["sh", "-c", "echo \"$(brightnessctl get) $(brightnessctl max)\""]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                const cur = Number(parts[0])
                const max = Number(parts[1])
                if (!isNaN(cur) && !isNaN(max) && max > 0) {
                    svc._max = max
                    svc.brightness = cur / max
                }
            }
        }
    }
}
