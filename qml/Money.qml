import QtQuick
import "theme.js" as Theme

Text {
    id: root

    property real value: 0
    property string symbol: backend.currency
    property int decimals: 2
    property bool signed: false
    property bool compact: false
    property bool colorBySign: false
    property bool animate: true
    property color positiveColor: Theme.mint
    property color negativeColor: Theme.red
    property real displayValue: 0

    Behavior on displayValue {
        enabled: root.animate
        NumberAnimation { duration: 650; easing.type: Easing.OutCubic }
    }

    text: compact ? Theme.moneyShort(displayValue, symbol)
                  : Theme.money(displayValue, symbol, decimals, signed)
    color: colorBySign ? (value < -0.004 ? negativeColor : (value > 0.004 ? positiveColor : Theme.text))
                       : Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: 15
    font.weight: Font.Medium
    font.letterSpacing: 0.2
    renderType: Text.NativeRendering

    onValueChanged: displayValue = value
    Component.onCompleted: displayValue = value
}
