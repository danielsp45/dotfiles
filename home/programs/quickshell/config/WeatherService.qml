// WeatherService.qml — the engine behind the center weather widget. Detects the
// location once from the IP address (ipapi.co) unless a saved location file exists
// at ~/.local/state/quickshell/weather.json. Supports live geocoding search via
// Open-Meteo geocoding API; selected cities are persisted to the file.
// Then polls Open-Meteo for current conditions + a 3-day forecast.
// Parsing is delegated to WeatherModel.js (pure functions); this file only does I/O.
import QtQuick
import Quickshell
import Quickshell.Io
import "WeatherModel.js" as Model

Item {
    id: root

    // --- config ---
    readonly property int refreshMinutes: 15
    // "" = auto (locale/country), "metric", or "imperial".
    property string unitOverride: ""

    // --- saved location (file-backed) ---
    readonly property string locationFilePath: Quickshell.env("HOME") + "/.local/state/quickshell/weather.json"
    property var savedLocation: ({ name: "", latitude: null, longitude: null })

    // --- location (IP-detected or file-loaded, cached) ---
    property string locationName: ""
    property string locationCountry: ""
    property var lat: null
    property var lon: null
    readonly property bool hasCoords: !isNaN(parseFloat(String(lat))) && !isNaN(parseFloat(String(lon)))

    // --- geocoding (used by popup search field) ---
    property var locationSuggestions: []
    property bool isGeocoding: false
    property string _geocodePending: ""
    property string _geocodeActive: ""

    // --- weather state ---
    property var report: null            // parsed Open-Meteo response (kept on failure)
    property string lastError: ""

    readonly property var current: Model.openMeteoCurrentCondition(report)
    readonly property var forecastDays: Model.openMeteoForecastDays(report, todayString())
    readonly property bool available: current !== null

    readonly property bool useImperial: Model.shouldUseImperial(unitOverride, Qt.locale().name, locationCountry)
    readonly property string tempUnit: "°" + (useImperial ? "F" : "C")

    readonly property string iconGlyph: Model.currentIcon(current, "")
    readonly property string tempNum: current ? String(useImperial ? current.temp_F : current.temp_C) : ""
    readonly property string tempText: current ? tempNum + "°" : ""
    readonly property string feelsText: current ? Model.formatTemp(useImperial ? current.FeelsLikeF : current.FeelsLikeC, useImperial) : ""
    readonly property string windText: current ? (useImperial ? (current.windspeedMiles + " mph") : (current.windspeedKmph + " km/h")) : ""
    readonly property string humidityText: current ? (current.humidity + "%") : ""

    function todayString() {
        var d = new Date()
        return d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2)
    }

    function refresh() {
        if (!hasCoords) {
            if (savedLocation.latitude !== null) {
                root.locationName = savedLocation.name
                root.lat = savedLocation.latitude
                root.lon = savedLocation.longitude
                fetchForecast()
            } else {
                if (!ipProc.running) ipProc.running = true
            }
            return
        }
        fetchForecast()
    }

    function fetchForecast() {
        if (!hasCoords || forecastProc.running) return
        var url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + encodeURIComponent(String(lat))
            + "&longitude=" + encodeURIComponent(String(lon))
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            + "&forecast_days=4"
            + "&timezone=auto"
        forecastProc.command = ["curl", "-fsS", "--max-time", "6", url]
        forecastProc.running = true
    }

    // Debounced geocoding search — call on every keystroke from the popup.
    function requestGeocode(query) {
        var q = String(query || "").trim()
        if (q.length < 2) {
            root.locationSuggestions = []
            geocodeDebounce.stop()
            return
        }
        root._geocodePending = q
        geocodeDebounce.restart()
    }

    function _startGeocode() {
        if (geocodeProc.running) return
        root._geocodeActive = root._geocodePending
        root.isGeocoding = true
        geocodeProc.command = ["curl", "-fsS", "--max-time", "5",
            "https://geocoding-api.open-meteo.com/v1/search?name="
            + encodeURIComponent(root._geocodeActive) + "&count=5&language=en&format=json"]
        geocodeProc.running = true
    }

    // Called by the popup when the user picks a suggestion from the list.
    function pickSuggestion(suggestion) {
        root.locationSuggestions = []
        root.locationName = suggestion.name
        root.locationCountry = ""
        root.lat = suggestion.latitude
        root.lon = suggestion.longitude
        _saveLocation(suggestion.name, suggestion.latitude, suggestion.longitude)
        fetchForecast()
    }

    function _saveLocation(name, latitude, longitude) {
        var content = JSON.stringify({ name: name, latitude: latitude, longitude: longitude })
        var dir = root.locationFilePath.substring(0, root.locationFilePath.lastIndexOf("/"))
        // Pass content and paths as shell positional args to avoid escaping issues.
        locationSaveProc.command = ["sh", "-c",
            "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"",
            "sh", dir, content, root.locationFilePath]
        locationSaveProc.running = true
    }

    // Settings file — watches for external changes too.
    FileView {
        id: locationFile
        path: root.locationFilePath
        watchChanges: true
        printErrors: false
        onLoaded: {
            var loc = Model.parseLocationFile(text())
            root.savedLocation = loc
            if (loc.latitude !== null) {
                root.locationName = loc.name
                root.locationCountry = ""
                root.lat = loc.latitude
                root.lon = loc.longitude
            }
        }
        onLoadFailed: {
            root.savedLocation = ({ name: "", latitude: null, longitude: null })
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshMinutes * 60 * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // If the very first detect/fetch fails (e.g. network not up at login), retry
    // a few times a minute apart before falling back to the slow periodic timer.
    Timer {
        id: retryTimer
        interval: 60 * 1000
        repeat: true
        running: true
        property int ticks: 0
        onTriggered: {
            ticks += 1
            if (root.available || ticks >= 5) { running = false; return }
            root.refresh()
        }
    }

    Timer {
        id: geocodeDebounce
        interval: 300
        repeat: false
        onTriggered: root._startGeocode()
    }

    // IP geolocation → city + country + coordinates. Runs once as fallback when
    // no saved location file exists. Uses ip-api.com (generous rate limits, free).
    Process {
        id: ipProc
        running: false
        command: ["curl", "-fsS", "--max-time", "6", "http://ip-api.com/json?fields=city,country,lat,lon"]
        stdout: StdioCollector { id: ipOut; waitForEnd: true }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                var loc = Model.parseIpLocation(String(ipOut.text || ""))
                if (loc.latitude !== null && loc.longitude !== null) {
                    root.locationName = loc.name
                    root.locationCountry = loc.country
                    root.lat = loc.latitude
                    root.lon = loc.longitude
                    root.fetchForecast()
                    return
                }
            }
            root.lastError = "Could not detect location"
        }
    }

    Process {
        id: forecastProc
        running: false
        command: []
        stdout: StdioCollector { id: forecastOut; waitForEnd: true }
        stderr: StdioCollector { id: forecastErr; waitForEnd: true }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.lastError = String(forecastErr.text || "Weather fetch failed").trim()
                return
            }
            try {
                root.report = JSON.parse(String(forecastOut.text || "{}"))
                root.lastError = ""
            } catch (e) {
                root.lastError = "Could not parse weather data"
            }
        }
    }

    Process {
        id: geocodeProc
        running: false
        command: []
        stdout: StdioCollector { id: geocodeOut; waitForEnd: true }
        onExited: function(exitCode) {
            root.isGeocoding = false
            if (exitCode === 0)
                root.locationSuggestions = Model.parseGeocodingResults(String(geocodeOut.text || ""))
            // If a new query arrived while this one was running, kick off the next one.
            if (root._geocodePending !== root._geocodeActive)
                root._startGeocode()
        }
    }

    Process {
        id: locationSaveProc
        running: false
        command: []
    }
}
