// TailscaleIcon.qml
// The official Tailscale mark, drawn natively as a 3×3 dot grid with the
// inactive dots faded — the same silhouette as the brand SVG. Drawing it with
// Rectangles (rather than an SVG or font glyph) keeps it crisp in tiny tile/bar
// slots and needs no qtsvg plugin or bundled asset. Ported from omarchy's
// TailscaleIcon, de-framework'd (plain color, no Style/Color singletons).
import QtQuick

Item {
    id: root

    property real size: 18
    property color color: "white"

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    readonly property real dotSize: Math.max(2, size * 0.24)
    readonly property real mid: (size - dotSize) / 2
    readonly property real end: size - dotSize

    Dot { x: 0;        y: 0;        opacity: 0.24 }
    Dot { x: root.mid; y: 0;        opacity: 0.24 }
    Dot { x: root.end; y: 0;        opacity: 0.24 }
    Dot { x: 0;        y: root.mid; opacity: 1.0 }
    Dot { x: root.mid; y: root.mid; opacity: 1.0 }
    Dot { x: root.end; y: root.mid; opacity: 1.0 }
    Dot { x: 0;        y: root.end; opacity: 0.24 }
    Dot { x: root.mid; y: root.end; opacity: 1.0 }
    Dot { x: root.end; y: root.end; opacity: 0.24 }

    component Dot: Rectangle {
        width: root.dotSize
        height: root.dotSize
        radius: width / 2
        color: root.color
        antialiasing: true
    }
}
