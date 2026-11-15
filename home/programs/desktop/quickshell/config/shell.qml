import Quickshell
import Quickshell.Io
import QtQuick
import "QuickSettings"

Scope {
  Bar {}
  LowBatteryDialog {}

  // Singletons load lazily; touch DarkMode at startup so auto switching runs
  // even before the Quick Settings panel is first opened.
  Component.onCompleted: DarkMode.refresh()
}
