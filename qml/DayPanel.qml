import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: root
    property bool open: false
    property string isoDate: ""
    property var txs: []

    signal closeRequested()
    signal addRequested()
    signal deleteRequested(string id)

    visible: panel.x < panel.width - 0.5 || open
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180 } }

    readonly property real income: {
        var s = 0
        for (var i = 0; i < txs.length; ++i)
            if (txs[i].type === "income") s += Number(txs[i].amount)
        return s
    }
    readonly property real expense: {
        var s = 0
        for (var i = 0; i < txs.length; ++i)
            if (txs[i].type === "expense") s += Number(txs[i].amount)
        return s
    }

    Rectangle {
        anchors.fill: parent
        color: "#CC000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        MouseArea {
            anchors.fill: parent
            enabled: root.open
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        id: panel
        width: Math.min(410, root.width * 0.9)
        height: root.height
        anchors.right: parent.right
        x: root.open ? 0 : width + 24
        color: Theme.bgLift
        border.width: 0

        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        Rectangle {
            width: 42
            height: parent.height
            x: -41
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 1.0; color: "#66000000" }
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Theme.stroke
            anchors.left: parent.left
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 22
            anchors.bottomMargin: 22
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 3
                    Text {
                        text: root.isoDate !== "" ? Theme.dayLabel(root.isoDate) : ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: root.txs.length === 0 ? "Nessun movimento"
                              : root.txs.length + (root.txs.length === 1 ? " movimento" : " movimenti")
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.letterSpacing: 0.3
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: closeHover.hovered ? Theme.withAlpha(Theme.text, 0.08) : Theme.withAlpha(Theme.text, 0.035)
                    border.width: 1
                    border.color: Theme.stroke
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: Theme.textDim
                        font.pixelSize: 12
                        font.family: Theme.fontFamily
                    }
                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.closeRequested() }
                }
            }

            Item { height: 18 }

            Text {
                text: "NETTO DEL GIORNO"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.letterSpacing: 1.5
                font.weight: Font.DemiBold
            }

            Money {
                Layout.topMargin: 6
                value: root.income - root.expense
                signed: true
                colorBySign: true
                font.pixelSize: 34
                font.weight: Font.DemiBold
                font.letterSpacing: 0
            }

            Item { height: 16 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 12
                    color: Theme.withAlpha(Theme.mint, 0.06)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.mint, 0.16)

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: "ENTRATE"
                            color: Theme.withAlpha(Theme.mint, 0.75)
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            font.letterSpacing: 1.3
                            font.weight: Font.Bold
                        }
                        Money {
                            value: root.income
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 12
                    color: Theme.withAlpha(Theme.red, 0.06)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.red, 0.16)

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Text {
                            text: "USCITE"
                            color: Theme.withAlpha(Theme.red, 0.8)
                            font.family: Theme.fontFamily
                            font.pixelSize: 8
                            font.letterSpacing: 1.3
                            font.weight: Font.Bold
                        }
                        Money {
                            value: root.expense
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Item { height: 20 }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.strokeSoft
            }

            Item { height: 16 }

            Text {
                text: "MOVIMENTI"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 9
                font.letterSpacing: 1.5
                font.weight: Font.DemiBold
            }

            Item { height: 10 }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.txs
                visible: root.txs.length > 0
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width - 8
                    height: 60
                    radius: 12
                    color: rowHover.hovered ? Theme.surface3 : Theme.surface2
                    border.width: 1
                    border.color: rowHover.hovered ? Theme.withAlpha(Theme.text, 0.10) : Theme.strokeSoft
                    Behavior on color { ColorAnimation { duration: 140 } }

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        anchors.left: parent.left
                        anchors.leftMargin: 13
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.categoryColor(row.modelData.category)
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 29
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 120
                        spacing: 2
                        Text {
                            text: row.modelData.category
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: row.modelData.note !== "" ? row.modelData.note
                                  : (row.modelData.type === "income" ? "Entrata" : "Spesa")
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Money {
                            value: row.modelData.type === "income" ? row.modelData.amount : -row.modelData.amount
                            signed: true
                            colorBySign: true
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            opacity: rowHover.hovered ? 1 : 0
                            color: delHover.hovered ? Theme.withAlpha(Theme.red, 0.18) : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: delHover.hovered ? Theme.red : Theme.textFaint
                                font.pixelSize: 10
                                font.family: Theme.fontFamily
                            }
                            HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.deleteRequested(row.modelData.id) }
                        }
                    }

                    HoverHandler { id: rowHover }

                    opacity: 0
                    transform: Translate { id: rowShift; y: 6 }
                    ParallelAnimation {
                        id: rowIn
                        NumberAnimation { target: row; property: "opacity"; from: 0; to: 1; duration: 260 }
                        NumberAnimation { target: rowShift; property: "y"; from: 6; to: 0; duration: 320; easing.type: Easing.OutCubic }
                    }
                    Component.onCompleted: {
                        rowIn.start()
                    }
                }
            }

            Column {
                visible: root.txs.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Item { width: 1; height: 26 }

                Rectangle {
                    width: 46
                    height: 46
                    radius: 23
                    color: Theme.withAlpha(Theme.text, 0.03)
                    border.width: 1
                    border.color: Theme.stroke
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                    }
                }
                Text {
                    text: "Questo giorno è ancora vuoto"
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Aggiungi un'entrata o una spesa."
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Item { height: 14 }

            Rectangle {
                id: addBtn
                Layout.fillWidth: true
                height: 46
                radius: 12
                color: addHover.hovered ? "#79F2C9" : Theme.mint
                Behavior on color { ColorAnimation { duration: 160 } }
                scale: addPress.pressed ? 0.985 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "Aggiungi movimento"
                    color: "#06231A"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.letterSpacing: 0.2
                }
                HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: addPress; onTapped: root.addRequested() }
            }
        }
    }
}
