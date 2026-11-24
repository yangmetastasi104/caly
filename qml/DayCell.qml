import QtQuick
import "theme.js" as Theme

Rectangle {
    id: root
    property var cell: ({})
    property bool isToday: false
    property bool isSelected: false
    property real maxAbs: 0
    property int index: 0
    property bool animated: true

    readonly property bool inMonth: cell && cell.inMonth === true
    readonly property real net: cell ? Number(cell.net || 0) : 0
    readonly property int count: cell ? Number(cell.count || 0) : 0
    readonly property real intensity: {
        if (!inMonth || count === 0 || maxAbs <= 0)
            return 0
        return Theme.clamp(Math.abs(net) / maxAbs, 0.15, 1)
    }

    color: {
        var base = inMonth ? Theme.surface : Theme.bgLift
        if (!inMonth)
            return base
        return net > 0.004 ? Theme.withAlpha(Theme.mint, 0.05 + intensity * 0.11)
             : net < -0.004 ? Theme.withAlpha(Theme.red, 0.05 + intensity * 0.11)
             : base
    }
    Behavior on color { ColorAnimation { duration: 220 } }

    border.width: isSelected ? 1.5 : (isToday ? 1.3 : 1)
    border.color: isSelected ? Theme.blue
                : isToday ? Theme.withAlpha(Theme.mint, 0.65)
                : (hover.hovered && inMonth ? Theme.withAlpha(Theme.text, 0.14) : Theme.strokeSoft)
    Behavior on border.color { ColorAnimation { duration: 180 } }

    radius: 10
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.withAlpha(Theme.text, 0.035)
        opacity: hover.hovered && inMonth ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    Text {
        visible: root.inMonth
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12
        text: root.cell ? root.cell.day : ""
        color: root.isToday ? Theme.mint
                            : (root.count > 0 ? Theme.textDim : Theme.textFaint)
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: root.isToday ? Font.DemiBold : Font.Medium
    }

    Rectangle {
        visible: root.isToday
        anchors.right: parent.right
        anchors.rightMargin: 11
        anchors.top: parent.top
        anchors.topMargin: 10
        width: todayText.implicitWidth + 14
        height: 18
        radius: 9
        color: Theme.withAlpha(Theme.mint, 0.12)
        border.width: 1
        border.color: Theme.withAlpha(Theme.mint, 0.22)

        Text {
            id: todayText
            anchors.centerIn: parent
            text: "OGGI"
            color: Theme.mint
            font.family: Theme.fontFamily
            font.pixelSize: 8
            font.letterSpacing: 1.2
            font.weight: Font.Bold
        }
    }

    Money {
        visible: root.inMonth && root.count > 0
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        value: root.net
        signed: true
        colorBySign: true
        animate: root.animated
        font.pixelSize: Math.abs(root.net) >= 10000 ? 12 : 14
        font.weight: Font.DemiBold
        font.letterSpacing: 0
    }

    Text {
        visible: root.inMonth && root.count > 1
        anchors.right: parent.right
        anchors.rightMargin: 13
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 17
        text: root.count + " mov."
        color: Theme.withAlpha(Theme.textDim, 0.75)
        font.family: Theme.fontFamily
        font.pixelSize: 9
        font.letterSpacing: 0.4
    }

    Rectangle {
        visible: root.inMonth
        opacity: hover.hovered ? 1 : 0
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: root.isToday ? 34 : 12
        width: 20
        height: 20
        radius: 10
        color: Theme.withAlpha(Theme.text, 0.07)
        border.width: 1
        border.color: Theme.withAlpha(Theme.text, 0.08)
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: "+"
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            anchors.verticalCenterOffset: -1
        }
    }

    HoverHandler {
        id: hover
        enabled: root.inMonth
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.inMonth
        onTapped: root.clicked()
    }

    signal clicked()

    opacity: 0
    transform: Translate { id: shift; y: 8 }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: shift; property: "y"; from: 8; to: 0; duration: 420; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: {
        if (root.animated) {
            enterTimer.start()
        } else {
            root.opacity = 1
            shift.y = 0
        }
    }

    Timer {
        id: enterTimer
        interval: Math.min(root.index * 9, 220)
        onTriggered: enterAnim.start()
    }
}
