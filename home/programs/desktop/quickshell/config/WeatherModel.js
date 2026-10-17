// WeatherModel.js — pure weather helpers (no I/O, no side effects). Ported from
// omarchy's weather plugin Model.js, trimmed to the Open-Meteo + IP-detect path
// this widget uses (wttr.in parsing and the location editor are omitted).
// Weather glyphs are the Nerd Font "Weather Icons" set (U+E3xx range), present
// in "Symbols Nerd Font". Consumed via `import "WeatherModel.js" as Model`.
.pragma library

function roundedTemp(value) {
  if (value === undefined || value === null || value === "") return ""
  var n = parseFloat(String(value))
  return isNaN(n) ? "" : String(Math.round(n))
}

function celsiusToFahrenheit(value) {
  if (value === undefined || value === null || value === "") return ""
  var n = parseFloat(String(value))
  return isNaN(n) ? "" : (n * 9 / 5) + 32
}

function formatTemp(value, useImperial) {
  if (value === undefined || value === null || value === "") return ""
  return value + "°" + (useImperial ? "F" : "C")
}

function normalizedUnit(value) {
  return String(value || "").replace(/^\s+|\s+$/g, "").toLowerCase()
}

function localeUsesImperial(localeName) {
  var name = String(localeName || "").replace(".", "_")
  return /^en[_-]US($|[_.-])/.test(name) || /^en[_-]LR($|[_.-])/.test(name) || /^my($|[_.-])/.test(name)
}

function countryUsesImperial(countryName) {
  var country = String(countryName || "")
    .replace(/^\s+|\s+$/g, "")
    .replace(/[._-]+/g, " ")
    .toLowerCase()
  if (!country) return null
  if (country === "us" || country === "usa" || country === "united states" || country === "united states of america") return true
  if (country === "liberia" || country === "myanmar" || country === "burma") return true
  return false
}

function shouldUseImperial(unitOverride, localeName, countryName) {
  var unit = normalizedUnit(unitOverride)
  if (unit === "imperial") return true
  if (unit === "metric") return false

  var countryPreference = countryUsesImperial(countryName)
  if (countryPreference !== null) return countryPreference

  return localeUsesImperial(localeName)
}

function dayName(dateString) {
  if (!dateString) return ""
  var d = new Date(dateString + "T12:00:00")
  if (isNaN(d.getTime())) return ""
  return ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][d.getDay()]
}

function isFutureForecastDate(dateString, todayString) {
  if (!dateString) return false
  return String(dateString).slice(0, 10) > String(todayString || "")
}

// ipapi.co/json (or ip-api.com) → { name, country, latitude, longitude }.
function parseIpLocation(raw) {
  var unset = { name: "", country: "", latitude: null, longitude: null }
  try {
    var d = JSON.parse(String(raw || "{}"))
    if (!d || typeof d !== "object") return unset
    var lat = parseFloat(d.latitude !== undefined ? d.latitude : d.lat)
    var lon = parseFloat(d.longitude !== undefined ? d.longitude : d.lon)
    var name = String(d.city || d.town || "").replace(/^\s+|\s+$/g, "")
    var country = String(d.country_name || d.country || "").replace(/^\s+|\s+$/g, "")
    return {
      name: name,
      country: country,
      latitude: isNaN(lat) ? null : lat,
      longitude: isNaN(lon) ? null : lon
    }
  } catch (e) {
    return unset
  }
}

// Open-Meteo current block → a normalized current-conditions object.
function openMeteoCurrentCondition(report) {
  var current = report && report.current ? report.current : null
  if (!current || current.temperature_2m === undefined || current.temperature_2m === null) return null
  return {
    temp_C: roundedTemp(current.temperature_2m),
    temp_F: roundedTemp(celsiusToFahrenheit(current.temperature_2m)),
    FeelsLikeC: roundedTemp(current.apparent_temperature),
    FeelsLikeF: roundedTemp(celsiusToFahrenheit(current.apparent_temperature)),
    windspeedKmph: roundedTemp(current.wind_speed_10m),
    windspeedMiles: roundedTemp(current.wind_speed_10m * 0.621371),
    humidity: roundedTemp(current.relative_humidity_2m),
    openMeteoWeatherCode: current.weather_code,
    isDay: current.is_day
  }
}

// Open-Meteo daily block → up to 3 future forecast days.
function openMeteoForecastDays(report, todayString) {
  var daily = report && report.daily ? report.daily : null
  if (!daily || !daily.time) return []

  var result = []
  for (var i = 0; i < daily.time.length && result.length < 3; ++i) {
    var date = daily.time[i]
    if (!isFutureForecastDate(date, todayString)) continue

    var maxC = daily.temperature_2m_max ? daily.temperature_2m_max[i] : ""
    var minC = daily.temperature_2m_min ? daily.temperature_2m_min[i] : ""
    result.push({
      date: date,
      maxtempC: roundedTemp(maxC),
      mintempC: roundedTemp(minC),
      maxtempF: roundedTemp(celsiusToFahrenheit(maxC)),
      mintempF: roundedTemp(celsiusToFahrenheit(minC)),
      openMeteoWeatherCode: daily.weather_code ? daily.weather_code[i] : null
    })
  }
  return result
}

function currentIcon(current, fallback) {
  if (!current) return fallback || ""
  if (current.openMeteoWeatherCode !== undefined && current.openMeteoWeatherCode !== null)
    return iconForOpenMeteoCode(current.openMeteoWeatherCode, Number(current.isDay) === 0)
  return fallback || ""
}

function dayIcon(day) {
  if (!day) return ""
  if (day.openMeteoWeatherCode !== undefined && day.openMeteoWeatherCode !== null)
    return iconForOpenMeteoCode(day.openMeteoWeatherCode)
  return ""
}

function bareTempForDay(day, kind, useImperial) {
  if (!day) return ""
  var v = useImperial
    ? (kind === "max" ? day.maxtempF : day.mintempF)
    : (kind === "max" ? day.maxtempC : day.mintempC)
  if (v === undefined || v === null || v === "") return ""
  return v + "°"
}

function iconForOpenMeteoCode(code, night) {
  var c = parseInt(String(code || "0"), 10)
  if (c === 0) return iconForCode(113, night)
  if (c === 1 || c === 2) return iconForCode(116, night)
  if (c === 3) return iconForCode(119, night)
  if (c === 45 || c === 48) return iconForCode(143, night)
  if (c === 51 || c === 53 || c === 55 || c === 56 || c === 57 || c === 61) return iconForCode(266, night)
  if (c === 63 || c === 65 || c === 66 || c === 67 || c === 80 || c === 81 || c === 82) return iconForCode(308, night)
  if (c === 71 || c === 73 || c === 75 || c === 77 || c === 85 || c === 86) return iconForCode(338, night)
  if (c === 95 || c === 96 || c === 99) return iconForCode(389, night)
  return iconForCode(119, night)
}

// ~/.local/state/quickshell/weather.json → { name, latitude, longitude }
function parseLocationFile(raw) {
  var unset = { name: "", latitude: null, longitude: null }
  try {
    var d = JSON.parse(String(raw || "{}"))
    if (!d || typeof d !== "object") return unset
    var lat = parseFloat(d.latitude)
    var lon = parseFloat(d.longitude)
    var hasCoords = !isNaN(lat) && !isNaN(lon)
    return { name: String(d.name || ""), latitude: hasCoords ? lat : null, longitude: hasCoords ? lon : null }
  } catch (e) { return unset }
}

// Open-Meteo geocoding API response → array of { name, description, latitude, longitude }
function parseGeocodingResults(raw) {
  try {
    var d = JSON.parse(String(raw || "{}"))
    if (!d || !d.results || !d.results.length) return []
    var out = []
    for (var i = 0; i < d.results.length; i++) {
      var r = d.results[i]
      if (!r.name || r.latitude === undefined || r.longitude === undefined) continue
      var parts = [r.admin1, r.country].filter(function(s) { return s && s.length > 0 })
      out.push({ name: String(r.name), description: parts.join(", "), latitude: r.latitude, longitude: r.longitude })
    }
    return out
  } catch (e) { return [] }
}

function iconForCode(code, night) {
  var c = parseInt(String(code || "0"), 10)
  switch (c) {
    case 113: return night ? "" : ""   // clear
    case 116: return night ? "" : ""   // partly cloudy
    case 119: case 122: return ""            // cloudy / overcast
    case 143: case 248: case 260: return night ? "" : ""   // fog / mist
    case 176: case 263: case 353: return night ? "" : ""   // light rain / showers
    case 179: case 227: case 230: case 323: case 326: case 368: return night ? "" : ""   // light snow
    case 182: case 185: case 281: case 284: case 311: case 314:
    case 317: case 320: case 350: case 362: case 365: case 374: case 377: return ""   // sleet / freezing
    case 200: case 386: case 389: case 392: case 395: return ""   // thunderstorm
    case 266: case 293: case 296: case 299: case 302: case 305: case 308: case 356: case 359: return ""   // rain
    case 329: case 332: case 335: case 338: case 371: return ""   // heavy snow
    default: return ""
  }
}
