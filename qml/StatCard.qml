import QtQuick
import "theme.js" as Theme

Item {
    id: root
    property string label: ""
    property real amount: 0
    property bool isPercent: false
    property bool signed: false
    property string hint: ""
    property color accent: Theme.blue

    implicitHeight: 112

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.surface
        border.width: 1
        border.color: Theme.stroke

        Rectangle {
            width: 3
            height: 18
            radius: 2
            color: root.accent
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.top: parent.top
            anchors.topMargin: 20
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 31
            anchors.top: parent.top
            anchors.topMargin: 19
            text: root.label.toUpperCase()
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.letterSpacing: 1.6
            font.weight: Font.DemiBold
        }

        Money {
            visible: !root.isPercent
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            value: root.amount
            signed: root.signed
            colorBySign: root.signed
            font.pixelSize: 24
            font.weight: Font.DemiBold
            font.letterSpacing: 0
        }

        Text {
            visible: root.isPercent
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            text: Number(root.amount).toFixed(1).replace(".", ",") + "%"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }

        Text {
            visible: root.hint !== ""
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20
            text: root.hint
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
}
