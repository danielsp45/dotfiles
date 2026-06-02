# Quick Settings panel

A GNOME-style quick-settings dropdown for the Quickshell bar. Click the status
cluster (volume · network · battery) on the right of the bar to open it, or:

```sh
qs ipc call quickSettings toggle
```

(bind that to a key in Hyprland if you like).

## Layout

- **Header** — avatar, username, lock, and a power menu (Log Out / Suspend /
  Reboot / Shutdown).
- **Wired banner** — when an Ethernet device is connected, a non-toggle
  "Wired / <connection>" row appears above the grid (the Wi-Fi tile stays put);
  tapping it opens network settings. Hidden when nothing is plugged in.
- **Toggle grid** — Wi-Fi and Bluetooth (chevron opens a sliding sub-panel for
  picking networks/devices), Dark Style, Night Light, Airplane Mode, Power Saver,
  LocalSend (starts/stops `localsend_app` in the background for receiving).
- **Sliders** — volume (click the icon to mute) and brightness.
- **Media** — MPRIS controls, shown only when a player is active.

## Data sources

Native Quickshell singletons (no polling): `Quickshell.Networking` (Wi-Fi),
`Quickshell.Bluetooth` (BlueZ), `Quickshell.Services.Pipewire` (audio),
`Quickshell.Services.Mpris` (media). Brightness and power-profiles use the small
Process-backed `BrightnessService` / `PowerProfileService`.

## Optional dependencies (features hide themselves if missing)

| Tool | Powers | If missing |
| --- | --- | --- |
| `brightnessctl` (+ `/sys/class/backlight`) | Brightness slider | slider hidden |
| `powerprofilesctl` | Power Saver toggle | tile hidden |
| `nm-connection-editor` | "Wi-Fi Settings" button | button opens nothing |
| `blueman-manager` | "Bluetooth Settings" button | button opens nothing |
| `toggle-hyprsunset` script | Night Light toggle | no-op |
| `localsend_app` | LocalSend toggle | toggle does nothing |
| Symbols Nerd Font | all icons | tofu glyphs |

Lock uses `~/.local/share/config/bin/lock-screen`. To enable the header gear,
set `UserHeader.settingsCommand` (no `gnome-control-center` is installed here).

## Theming

`Theme.qml` is a singleton palette; flip `Theme.darkMode` (the Dark Style tile
does this) to switch between the dark palette and an Adwaita-Light variant.
