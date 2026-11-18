.pragma library

// Parses one line of `libinput debug-events` output (libinput 1.2x/1.3x):
//
//   -event3   GESTURE_SWIPE_BEGIN      +3.456s	3
//    event3   GESTURE_SWIPE_UPDATE   12 +3.470s	3  0.21/-1.42 ( 0.30/-2.03 unaccelerated)
//    event3   GESTURE_SWIPE_END        +3.600s	3 cancelled
//
// (header: device, event type, optional repeat count; then time, finger
// count and, for updates, the accelerated dx/dy.) Positive dy = fingers
// moving towards the bottom of the touchpad, regardless of natural scrolling.
//
// Returns { type: "begin"|"update"|"end", fingers, time (ms), dx, dy,
// cancelled }, null for lines that aren't swipe gestures, or
// { type: "invalid" } for swipe lines this parser doesn't understand.

var LINE = /GESTURE_SWIPE_(BEGIN|UPDATE|END)\s+(?:\d+\s+)?([+-]?\d+(?:\.\d+)?)s\s+(\d+)(.*)$/;
var DELTA = /^\s*(-?\d+(?:\.\d+)?)\/\s*(-?\d+(?:\.\d+)?)/;

function parse(line) {
    if (line.indexOf("GESTURE_SWIPE_") < 0) return null;
    var m = LINE.exec(line);
    if (!m) return { type: "invalid" };

    var ev = {
        type: m[1].toLowerCase(),
        time: parseFloat(m[2]) * 1000,
        fingers: parseInt(m[3], 10),
        dx: 0,
        dy: 0,
        cancelled: false
    };
    var rest = m[4];
    if (ev.type === "update") {
        var d = DELTA.exec(rest);
        if (!d) return { type: "invalid" };
        ev.dx = parseFloat(d[1]);
        ev.dy = parseFloat(d[2]);
    } else if (ev.type === "end") {
        ev.cancelled = /\bcancelled\b/.test(rest);
    }
    return ev;
}

// Lets the same file be unit-tested with node.
if (typeof module !== "undefined") module.exports = { parse: parse };
