import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: page

    property int year: backend.currentYear
    property var series: []
    property var cats: []
    property var summary: ({ income: 0, expense: 0, net: 0, savingsRate: 0 })
    property real maxVal: 1
    property int focusMonth: 0

    function refresh() {
        series = backend.monthlySeries(year)
        cats = backend.categoryTotals(year, 0)
        summary = backend.yearSummary(year)
        var m = 1
        for (var i = 0; i < series.length; ++i) {
            m = Math.max(m, Number(series[i].income), Number(series[i].expense))
        }
        maxVal = m
        focusMonth = 0
    }

    function shiftYear(d) {
        year += d
        refresh()
    }

    Component.onCompleted: refresh()

    Connections {
        target: backend
        function onDataChanged() { page.refresh() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        anchors.bottomMargin: 18
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            Column {
                spacing: 3
                Text {
                    text: "Analisi"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                }
                Text {
                    text: "Il quadro del tuo anno"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    width: 30; height: 30; radius: 10
                    color: pyHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : "transparent"
                    border.width: 1
                    border.color: pyHover.hovered ? Theme.stroke : Theme.strokeSoft
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                    HoverHandler { id: pyHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.shiftYear(-1) }
                }
                Text {
                    text: page.year
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    width: 46
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: 30; height: 30; radius: 10
                    color: nyHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : "transparent"
                    border.width: 1
                    border.color: nyHover.hovered ? Theme.stroke : Theme.strokeSoft
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                    HoverHandler { id: nyHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: page.shiftYear(1) }
                }
            }
        }

        Item { height: 20 }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            StatCard {
                Layout.fillWidth: true
                label: "Entrate"
                amount: page.summary.income || 0
                accent: Theme.mint
            }
            StatCard {
                Layout.fillWidth: true
                label: "Uscite"
                amount: page.summary.expense || 0
                accent: Theme.red
            }
            StatCard {
                Layout.fillWidth: true
                label: "Netto"
                amount: page.summary.net || 0
                signed: true
                accent: Theme.blue
            }
            StatCard {
                Layout.fillWidth: true
                label: "Tasso di risparmio"
                amount: page.summary.savingsRate || 0
                isPercent: true
                accent: Theme.amber
            }
        }

        Item { height: 14 }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: Theme.surface
                border.width: 1
                border.color: Theme.stroke

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true

                        Column {
                            spacing: 2
                            Text {
                                text: "Flusso mensile"
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: page.focusMonth > 0
                                      ? Theme.monthName(page.focusMonth, false) + "  ·  +" + Theme.money(page.series[page.focusMonth - 1].income, backend.currency, 0)
                                        + "  /  −" + Theme.money(page.series[page.focusMonth - 1].expense, backend.currency, 0)
                                      : "Passa sopra un mese per i dettagli"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            spacing: 12
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.mint; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: "Entrate"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                            Rectangle { width: 6; height: 6; radius: 3; color: Theme.red; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: "Uscite"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }

                    Item { height: 16 }

                    Item {
                        id: chartArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            anchors.bottomMargin: 22
                            color: "transparent"

                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    required property int index
                                    width: parent.width
                                    height: 1
                                    y: (parent.height - 1) * index / 3
                                    color: Theme.withAlpha(Theme.text, index === 3 ? 0.09 : 0.05)
                                }
                            }
                        }

                        Row {
                            id: barsRow
                            anchors.fill: parent
                            anchors.bottomMargin: 22
                            spacing: 0

                            Repeater {
                                model: page.series
                                delegate: Item {
                                    id: col
                                    required property var modelData
                                    required property int index
                                    width: barsRow.width / 12
                                    height: barsRow.height

                                    readonly property real incH: (Number(modelData.income) / page.maxVal) * (height - 8)
                                    readonly property real expH: (Number(modelData.expense) / page.maxVal) * (height - 8)
                                    readonly property bool current: page.year === backend.currentYear && modelData.month === backend.currentMonth

                                    Rectangle {
                                        id: incBar
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.horizontalCenterOffset: -6
                                        width: 9
                                        radius: 3
                                        color: Theme.mint
                                        opacity: col.current ? 1 : 0.72
                                        height: 0
                                        property real target: col.incH
                                        Behavior on height { NumberAnimation { duration: 620; easing.type: Easing.OutCubic } }
                                        Timer {
                                            interval: 50
                                            running: true
                                            onTriggered: incBar.height = incBar.target
                                        }
                                    }

                                    Rectangle {
                                        id: expBar
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.horizontalCenterOffset: 6
                                        width: 9
                                        radius: 3
                                        color: Theme.red
                                        opacity: col.current ? 1 : 0.72
                                        height: 0
                                        property real target: col.expH
                                        Behavior on height { NumberAnimation { duration: 620; easing.type: Easing.OutCubic } }
                                        Timer {
                                            interval: 50
                                            running: true
                                            onTriggered: expBar.height = expBar.target
                                        }
                                    }

                                    Rectangle {
                                        visible: col.current
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: 1
                                        color: Theme.withAlpha(Theme.text, 0.22)
                                    }

                                    Text {
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -18
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Theme.monthName(col.modelData.month, true)
                                        color: col.current ? Theme.text : Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.letterSpacing: 0.8
                                        font.weight: col.current ? Font.Bold : Font.Normal
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: page.focusMonth = col.modelData.month
                                        onExited: page.focusMonth = 0
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 350
                Layout.fillHeight: true
                radius: 18
                color: Theme.surface
                border.width: 1
                border.color: Theme.stroke

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 0

                    Text {
                        text: "Dove vanno i soldi"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Categorie di spesa · " + page.year
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Item { height: 16 }

                    Column {
                        Layout.fillWidth: true
                        spacing: 12

                        Repeater {
                            model: page.cats.slice(0, 6)
                            delegate: Item {
                                id: catRow
                                required property var modelData
                                required property int index
                                width: parent.width
                                height: 38

                                readonly property real pct: page.summary.expense > 0
                                                             ? Number(modelData.total) / page.summary.expense * 100 : 0

                                Text {
                                    text: catRow.modelData.category
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                                Text {
                                    anchors.right: parent.right
                                    text: Theme.money(catRow.modelData.total, backend.currency, 2)
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                    height: 4
                                    radius: 2
                                    color: Theme.withAlpha(Theme.text, 0.05)

                                    Rectangle {
                                        id: catFill
                                        height: parent.height
                                        radius: 2
                                        width: 0
                                        color: Theme.categoryColor(catRow.modelData.category)
                                        opacity: 0.85
                                        property real target: Math.max(3, (catRow.pct / 100) * catRow.width)
                                        Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
                                        Timer {
                                            interval: 60
                                            running: true
                                            onTriggered: catFill.width = catFill.target
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        visible: page.cats.length === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "Nessuna spesa"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "Le categorie compariranno qui."
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.strokeSoft
                    }
                    Item { height: 12 }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Totale uscite"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Item { Layout.fillWidth: true }
                        Money {
                            value: page.summary.expense || 0
                            color: Theme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }
    }
}
