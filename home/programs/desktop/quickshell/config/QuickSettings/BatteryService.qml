pragma Singleton
// BatteryService.qml
// Shared battery state, read from sysfs. One poller for the whole shell, so
// every bar's icon and the Quick Settings header stay in sync and the
// low-battery notification fires once (not once per monitor).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: svc

    property bool available: false
    property int percent: 0
    property string status: ""          // Charging | Discharging | Full | Not charging
    readonly property bool charging: status === "Charging" || status === "Full"
    readonly property bool critical: percent < 10 && !charging
    // Charger connected (AC adapter online), even if not actively charging.
    property bool pluggedIn: false

    // Low-battery alert. Raised once when the level drops to lowThreshold
    // while discharging; stays up until acknowledgeLow(). Re-arms after the
    // battery climbs above rearmThreshold (so it fires again next cycle).
    readonly property int lowThreshold: 10
    readonly property int rearmThreshold: 15
    property bool lowAlert: false
    property bool _lowArmed: true

    function acknowledgeLow() { lowAlert = false }

    // Nerd Font glyph for the current level / charge state.
    readonly property string glyph: {
        if (charging) return "󰂄"
        if (percent >= 80) return "󰁹"
        if (percent >= 60) return "󰁾"
        if (percent >= 40) return "󰁽"
        if (percent >= 20) return "󰁼"
        if (percent >= 10) return "󰁻"
        return "󰁺"
    }

    property Process _detect: Process {
        command: ["sh", "-c", "test -d /sys/class/power_supply/BAT0 && echo yes || echo no"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                svc.available = text.trim() === "yes"
                if (svc.available) svc._read.running = true
            }
        }
    }

    property Timer _poll: Timer {
        interval: 2000
        running: svc.available
        repeat: true
        onTriggered: svc._read.running = true
    }

    property Process _read: Process {
        // capacity, status, "now full" charge (or energy), then the AC
        // adapter's online flag (ADP1/AC/ACAD…; prints 0 when no mains supply
        // is found).
        command: ["sh", "-c", "b=/sys/class/power_supply/BAT0; cat $b/capacity $b/status; "
            + "echo $(cat $b/charge_now $b/charge_full 2>/dev/null || cat $b/energy_now $b/energy_full 2>/dev/null); "
            + "for f in /sys/class/power_supply/*/type; do "
            + "[ \"$(cat \"$f\")\" = Mains ] && { cat \"${f%/type}/online\"; exit; }; done; echo 0"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                // Some batteries (the T2 MacBooks) report `capacity` against the
                // design capacity, so a worn battery tops out well below 100%.
                // Use charge relative to the battery's current full capacity.
                const nf = (lines[2] || "").trim().split(/\s+/).map(Number)
                let p = Number(lines[0])
                if (nf.length === 2 && nf[1] > 0 && !isNaN(nf[0]))
                    p = Math.min(100, Math.round(nf[0] / nf[1] * 100))
                if (!isNaN(p)) svc.percent = p
                if (lines.length > 1) svc.status = lines[1].trim()
                // Fall back to the battery status if there's no Mains supply.
                svc.pluggedIn = lines.length > 3 && lines[3].trim() === "1" ? true : svc.charging
                svc._checkLow()
            }
        }
    }

    function _checkLow() {
        if (percent <= lowThreshold && !charging && _lowArmed) {
            _lowArmed = false
            lowAlert = true
        } else if (percent > rearmThreshold && !_lowArmed) {
            _lowArmed = true
        }
    }
}
