import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: page

    property int viewYear: backend.currentYear
    property int viewMonth: backend.currentMonth
    property var days: []
    property var summary: ({ income: 0, expense: 0, net: 0, count: 0 })
    property real maxAbs: 0
    property string selectedIso: ""
    property bool panelOpen: false
    property var dayTxs: []
    property bool animateGrid: true

    signal toastRequested(string message, bool danger)
    signal addRequested(string isoDate)

    function refresh(animate) {
        animateGrid = animate === true
        days = backend.monthDays(viewYear, viewMonth)
        summary = backend.monthSummary(viewYear, viewMonth)
        var m = 0
        for (var i = 0; i < days.length; ++i) {
            var a = Math.abs(Number(days[i].net || 0))
            if (a > m) m = a
        }
        maxAbs = m
        if (selectedIso !== "")
            dayTxs = backend.transactionsForDay(selectedIso)
        animateReset.restart()
    }

    function changeMonth(delta) {
        var m = viewMonth + delta
        var y = viewYear
        if (m < 1) { m = 12; y -= 1 }
        if (m > 12) { m = 1; y += 1 }
        viewMonth = m
        viewYear = y
        selectedIso = ""
        panelOpen = false
        refresh(true)
        titleIn.restart()
    }

    function goToday() {
        viewYear = backend.currentYear
        viewMonth = backend.currentMonth
        selectedIso = backend.todayIso
        dayTxs = backend.transactionsForDay(selectedIso)
        refresh(true)
        panelOpen = true
        titleIn.restart()
    }

    function openDay(iso) {
        if (!iso || iso === "")
            return
        selectedIso = iso
        dayTxs = backend.transactionsForDay(iso)
        panelOpen = true
    }

    Component.onCompleted: {
        refresh(true)
        if (startupDay)
            openDay(backend.todayIso)
        if (startupAutoDelete) {
            var all = backend.allTransactions()
            if (all.length > 0)
                confirmDelete.ask(all[0].id, all[0].category + " · verifica")
        }
    }

    Connections {
        target: backend
        function onDataChanged() {
            if (page.panelOpen)
                page.dayTxs = backend.transactionsForDay(page.selectedIso)
            page.refresh(false)
        }
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
            spacing: 14

            Row {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                Item {
                    id: titleGroup
                    width: titleRow.implicitWidth
                    height: titleRow.implicitHeight
                    transform: Translate { id: titleShift }

                    Row {
                        id: titleRow
                        spacing: 9
                        Text {
                            id: titleText
                            text: Theme.monthName(page.viewMonth, false)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.DemiBold
                            font.letterSpacing: -0.4
                        }
                        Text {
                            text: page.viewYear
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            font.weight: Font.Light
                            anchors.baseline: titleText.baseline
                        }
                    }
                }

                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 30; height: 30; radius: 10
                        color: leftHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : "transparent"
                        border.width: 1
                        border.color: leftHover.hovered ? Theme.stroke : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }
                        HoverHandler { id: leftHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: page.changeMonth(-1) }
                    }
                    Rectangle {
                        width: 30; height: 30; radius: 10
                        color: rightHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : "transparent"
                        border.width: 1
                        border.color: rightHover.hovered ? Theme.stroke : "transparent"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }
                        HoverHandler { id: rightHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: page.changeMonth(1) }
                    }
                    Rectangle {
                        width: 54; height: 30; radius: 10
                        color: todayHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : "transparent"
                        border.width: 1
                        border.color: todayHover.hovered ? Theme.stroke : Theme.strokeSoft
                        Behavior on color { ColorAnimation { duration: 140 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Oggi"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        HoverHandler { id: todayHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: page.goToday() }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 26
                Layout.alignment: Qt.AlignVCenter

                Column {
                    spacing: 3
                    Text {
                        text: "ENTRATE"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.weight: Font.DemiBold
                    }
                    Money {
                        value: page.summary.income || 0
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
                Column {
                    spacing: 3
                    Text {
                        text: "USCITE"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.weight: Font.DemiBold
                    }
                    Money {
                        value: page.summary.expense || 0
                        color: Theme.text
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
                Column {
                    spacing: 3
                    Text {
                        text: "NETTO"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.weight: Font.DemiBold
                    }
                    Money {
                        value: page.summary.net || 0
                        signed: true
                        colorBySign: true
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                }
                Rectangle {
                    width: 1
                    height: 34
                    color: Theme.strokeSoft
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    width: addW.implicitWidth + 30
                    height: 36
                    radius: 11
                    color: headAddHover.hovered ? "#79F2C9" : Theme.mint
                    anchors.verticalCenter: parent.verticalCenter
                    scale: headAddPress.pressed ? 0.97 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110 } }

                    Row {
                        id: addW
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "+"
                            color: "#06231A"
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Movimento"
                            color: "#06231A"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    HoverHandler { id: headAddHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: headAddPress; onTapped: page.addRequested(page.selectedIso !== "" ? page.selectedIso : backend.todayIso) }
                }
            }
        }

        Item { height: 18 }

        Row {
            Layout.fillWidth: true
            height: 24
            spacing: 0

            Repeater {
                model: 7
                delegate: Item {
                    required property int index
                    width: parent.width / 7
                    height: 24
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.weekdayShort(index)
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.4
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Item { height: 8 }

        Rectangle {
            id: gridCard
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Theme.strokeSoft
            border.width: 1
            border.color: Theme.stroke
            clip: true

            readonly property int rows: Math.max(1, Math.ceil(page.days.length / 7))
            readonly property real gap: 4
            readonly property real cellW: (width - gap * 6) / 7
            readonly property real cellH: Math.max(72, (height - gap * (rows - 1)) / rows)

            Grid {
                id: dayGrid
                x: 0
                y: 0
                columns: 7
                spacing: gridCard.gap
                width: parent.width
                height: parent.height

                Repeater {
                    model: page.days
                    delegate: DayCell {
                        required property var modelData
                        required property int index
                        width: gridCard.cellW
                        height: gridCard.cellH
                        cell: modelData
                        index: index
                        maxAbs: page.maxAbs
                        isToday: modelData.inMonth && modelData.iso === backend.todayIso
                        isSelected: modelData.inMonth && modelData.iso === page.selectedIso
                        animated: page.animateGrid
                        onClicked: page.openDay(modelData.iso)
                    }
                }
            }
        }

        Item { height: 10 }

        RowLayout {
            Layout.fillWidth: true

            Row {
                spacing: 7
                Text {
                    text: "Clicca un giorno per vedere i dettagli"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
                Text {
                    visible: page.summary.count === 0
                    text: "·  Nessun movimento questo mese"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 14
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
    }

    ParallelAnimation {
        id: titleIn
        NumberAnimation { target: titleGroup; property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        NumberAnimation { target: titleShift; property: "y"; from: 7; to: 0; duration: 340; easing.type: Easing.OutCubic }
    }

    Timer {
        id: animateReset
        interval: 80
        onTriggered: page.animateGrid = true
    }

    DayPanel {
        anchors.fill: parent
        z: 20
        open: page.panelOpen
        isoDate: page.selectedIso
        txs: page.dayTxs
        onCloseRequested: page.panelOpen = false
        onAddRequested: page.addRequested(page.selectedIso)
        onDeleteRequested: function(id) {
            var label = "movimento"
            for (var i = 0; i < page.dayTxs.length; ++i) {
                if (page.dayTxs[i].id === id) {
                    var t = page.dayTxs[i]
                    label = t.category + (t.note !== "" ? " · " + t.note : "")
                    break
                }
            }
            confirmDelete.ask(id, label)
        }
    }

    ConfirmDelete {
        id: confirmDelete
        anchors.fill: parent
        onConfirmed: function(id) {
            if (backend.removeTransaction(id))
                page.toastRequested("Movimento eliminato", true)
        }
    }
}
