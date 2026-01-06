// ClockWidget.qml
import QtQuick

Text {
  // allow the bar to control sizing
  property int px: 11

  text: Time.time
  font.bold: true
  font.pixelSize: px
}
