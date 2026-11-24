import QtQuick
import "theme.js" as Theme

Item {
    id: root
    property string message: ""
    property bool shown: false
    property bool danger: false

    implicitWidth: pill.width
    implicitHeight: 46
    width: pill.width
    height: 46

    function show(text, isDanger) {
        message = text
        danger = !!isDanger
        shown = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2600
        onTriggered: root.shown = false
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        height: 44
        width: row.implicitWidth + 38
        radius: 22
        color: Theme.surface3
        border.width: 1
        border.color: root.danger ? Theme.withAlpha(Theme.red, 0.45) : Theme.stroke
        opacity: root.shown ? 1 : 0
        y: root.shown ? 0 : 14
        scale: root.shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: root.danger ? Theme.red : Theme.mint
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.message
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
