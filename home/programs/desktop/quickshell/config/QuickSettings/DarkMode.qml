pragma Singleton
// DarkMode.qml
// Single source of truth for the system-wide dark style. Reads and writes both
// dconf keys apps look at: `gtk-theme` (GTK3, via adw-gtk3) and `color-scheme`
// (GTK4/libadwaita, and Firefox/Electron through the settings portal).
// `on` always mirrors dconf, kept live by `dconf watch`, so Theme.darkMode can't
// drift from what apps actually show.
//
// Auto mode switches to dark at sunset and light at sunrise. Coordinates come from
// the weather widget's saved location, else from IP geolocation. A manual toggle
// holds until the next sunrise/sunset.
import QtQuick
import Quickshell
import Quickshell.Io
import "SunTimes.js" as Sun
import "../WeatherModel.js" as WeatherModel

Singleton {
    id: svc

    property bool on: false
    property bool auto: true

    property var lat: null
    property var lon: null
    readonly property bool hasCoords: lat !== null && lon !== null

    // Night/day as of the last auto check; null until the first one runs, so the
    // first check after startup always applies the current phase.
    property var _lastNight: null

    function refresh() { checkProc.running = true }

    function set(dark) {
        Quickshell.execDetached(["dconf", "write",
            "/org/gnome/desktop/interface/gtk-theme", dark ? "'adw-gtk3-dark'" : "'adw-gtk3'"])
        Quickshell.execDetached(["dconf", "write",
            "/org/gnome/desktop/interface/color-scheme", dark ? "'prefer-dark'" : "'default'"])
    }

    function toggle() { set(!svc.on) }

    function _autoCheck() {
        if (!svc.auto || !svc.hasCoords) return
        const night = Sun.isNight(new Date(), svc.lat, svc.lon)
        if (night === svc._lastNight) return
        svc._lastNight = night
        set(night)
    }

    onHasCoordsChanged: _autoCheck()

    property Process checkProc: Process {
        command: ["dconf", "read", "/org/gnome/desktop/interface/gtk-theme"]
        stdout: StdioCollector {
            onStreamFinished: svc.on = text.includes("dark")
        }
    }

    // Any change under the interface schema (ours or another tool's) re-reads state.
    property Process watchProc: Process {
        command: ["dconf", "watch", "/org/gnome/desktop/interface/"]
        running: true
        stdout: SplitParser { onRead: svc.refresh() }
    }

    property Timer autoTimer: Timer {
        interval: 60 * 1000
        repeat: true
        running: svc.auto
        onTriggered: svc._autoCheck()
    }

    // Same location source as WeatherService: the saved weather location wins.
    property FileView locationFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/quickshell/weather.json"
        watchChanges: true
        printErrors: false
        onLoaded: {
            const loc = WeatherModel.parseLocationFile(text())
            if (loc.latitude === null) return
            svc.lat = loc.latitude
            svc.lon = loc.longitude
        }
        onLoadFailed: if (!svc.hasCoords) ipRetry.start()
    }

    property Process ipProc: Process {
        command: ["curl", "-fsS", "--max-time", "6", "http://ip-api.com/json?fields=city,country,lat,lon"]
        stdout: StdioCollector { id: ipOut; waitForEnd: true }
        onExited: function(exitCode) {
            const loc = exitCode === 0 ? WeatherModel.parseIpLocation(String(ipOut.text || "")) : null
            if (loc && loc.latitude !== null && loc.longitude !== null) {
                svc.lat = loc.latitude
                svc.lon = loc.longitude
                ipRetry.stop()
            }
        }
    }

    // The network may not be up yet at login; keep trying once a minute.
    property Timer ipRetry: Timer {
        interval: 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (svc.hasCoords) { stop(); return }
            if (!svc.ipProc.running) svc.ipProc.running = true
        }
    }

    Component.onCompleted: refresh()
}
