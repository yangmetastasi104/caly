import QtQuick
import "theme.js" as Theme

Item {
    id: root
    property string label
    property bool active: false
    property bool hovered: hover.hovered
    signal clicked()

    implicitWidth: tabText.implicitWidth + 26
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.active ? Theme.withAlpha(Theme.text, 0.08)
                           : (hover.hovered ? Theme.withAlpha(Theme.text, 0.045) : "transparent")
        border.width: 1
        border.color: root.active ? Theme.withAlpha(Theme.text, 0.10) : "transparent"
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Text {
        id: tabText
        anchors.centerIn: parent
        text: root.label
        color: root.active ? Theme.text : (hover.hovered ? Theme.text : Theme.textDim)
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: root.active ? Font.DemiBold : Font.Medium
        font.letterSpacing: 0.2
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.clicked() }
}
