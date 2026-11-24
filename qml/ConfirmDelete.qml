import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: root
    property bool open: false
    property string pendingId: ""
    property string pendingLabel: ""

    signal confirmed(string id)

    visible: open || hideTimer.running
    z: 300

    onOpenChanged: if (!open) hideTimer.start()

    Timer { id: hideTimer; interval: 190 }

    function ask(id, label) {
        pendingId = id
        pendingLabel = label
        open = true
    }

    function accept() {
        if (pendingId === "")
            return
        const id = pendingId
        pendingId = ""
        open = false
        root.confirmed(id)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha("#000000", 0.55)
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 170 } }
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    Rectangle {
        width: 400
        height: 190
        radius: 18
        anchors.centerIn: parent
        color: "#0C1117"
        border.width: 1
        border.color: Theme.stroke
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 0

            Text {
                text: "Eliminare il movimento?"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Item { height: 6 }

            Text {
                Layout.fillWidth: true
                text: root.pendingLabel
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 110
                    height: 40
                    radius: 11
                    color: cancelHover.hovered ? Theme.withAlpha(Theme.text, 0.08) : Theme.withAlpha(Theme.text, 0.04)
                    border.width: 1
                    border.color: Theme.strokeSoft
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Annulla"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }
                    HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.open = false }
                }

                Rectangle {
                    width: 120
                    height: 40
                    radius: 11
                    color: delHover.hovered ? "#FF8291" : Theme.red
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Elimina"
                        color: "#2A070C"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
                    HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.accept() }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.open = false
    }

    Shortcut {
        sequence: "Return"
        enabled: root.open
        onActivated: root.accept()
    }
}
