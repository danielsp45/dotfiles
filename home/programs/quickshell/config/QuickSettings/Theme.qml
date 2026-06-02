pragma Singleton
// Theme.qml
// Shared palette singleton for the Quick Settings panel. Accessed as `Theme.*`
// from any component. Flip `darkMode` to switch between a Catppuccin-ish dark
// palette and an Adwaita-Light variant matching GNOME.
import QtQuick
import Quickshell

Singleton {
    id: theme

    property bool darkMode: true

    // --- semantic colors (resolve based on darkMode) ---
    // Dark palette mirrors GNOME's Adwaita-dark quick settings: neutral grays for
    // the popover and tiles, GNOME blue only for active/accent details.
    readonly property color background: darkMode ? "#323232" : "#fafafb"
    readonly property color surface:    darkMode ? "#363636" : "#e6e6e8"
    readonly property color surfaceAlt: darkMode ? "#454545" : "#d8d8dc"
    readonly property color accent:     "#3584e4"   // GNOME blue, both modes
    readonly property color accentText: "#ffffff"
    readonly property color text:       darkMode ? "#ffffff" : "#1d1d20"
    readonly property color subtext:    darkMode ? "#b3b3b3" : "#5e5e63"
    readonly property color divider:    darkMode ? "#4d4d4d" : "#cfcfd4"
    readonly property color danger:     "#e25555"

    // --- metrics ---
    readonly property real backgroundOpacity: 1.0
    readonly property int  panelWidth:   360
    readonly property int  radius:       16
    readonly property int  toggleRadius: 28
    readonly property int  rowGap:       12
    readonly property int  colGap:       8
    readonly property int  pad:          16
}
