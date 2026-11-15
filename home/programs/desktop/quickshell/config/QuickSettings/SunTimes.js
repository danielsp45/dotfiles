.pragma library
// SunTimes.js — pure sunrise/sunset math (NOAA "sunrise equation"), no I/O.
// Accurate to about a minute, which is plenty for switching the color scheme.

var RAD = Math.PI / 180

function _toJulian(ms) { return ms / 86400000 + 2440587.5 }
function _fromJulian(j) { return new Date((j - 2440587.5) * 86400000) }

// Sunrise and sunset for the local calendar day of `date` at (lat, lon), east positive.
// Returns { sunrise: Date, sunset: Date }, or { polar: "day" | "night" } when the sun
// never sets or never rises that day.
function sunTimes(date, lat, lon) {
  var noonUtc = Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), 12)
  var n = Math.round(_toJulian(noonUtc) - 2451545.0 + 0.0008)
  var meanNoon = n - lon / 360

  var M = (357.5291 + 0.98560028 * meanNoon) % 360
  var C = 1.9148 * Math.sin(M * RAD) + 0.0200 * Math.sin(2 * M * RAD) + 0.0003 * Math.sin(3 * M * RAD)
  var eclipticLon = (M + C + 180 + 102.9372) % 360
  var transit = 2451545.0 + meanNoon + 0.0053 * Math.sin(M * RAD) - 0.0069 * Math.sin(2 * eclipticLon * RAD)

  var sinDecl = Math.sin(eclipticLon * RAD) * Math.sin(23.4397 * RAD)
  var cosDecl = Math.cos(Math.asin(sinDecl))
  var cosHourAngle = (Math.sin(-0.833 * RAD) - Math.sin(lat * RAD) * sinDecl) / (Math.cos(lat * RAD) * cosDecl)

  if (cosHourAngle > 1) return { polar: "night" }
  if (cosHourAngle < -1) return { polar: "day" }

  var hourAngle = Math.acos(cosHourAngle) / RAD
  return {
    sunrise: _fromJulian(transit - hourAngle / 360),
    sunset: _fromJulian(transit + hourAngle / 360)
  }
}

// True when `date` falls between sunset and the next sunrise at (lat, lon).
function isNight(date, lat, lon) {
  var t = sunTimes(date, lat, lon)
  if (t.polar) return t.polar === "night"
  return date < t.sunrise || date >= t.sunset
}
