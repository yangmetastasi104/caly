import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: page

    property string filter: "all"
    property string query: ""
    property var rows: []
    property int resultCount: 0
    property int dataTick: 0

    signal toastRequested(string message, bool danger)

    function dayHeader(iso) {
        if (iso === backend.todayIso)
            return "Oggi"
        var y = new Date()
        y.setDate(y.getDate() - 1)
        var yIso = y.getFullYear() + "-" + ("0" + (y.getMonth() + 1)).slice(-2) + "-" + ("0" + y.getDate()).slice(-2)
        if (iso === yIso)
            return "Ieri"
        return Theme.dayLabel(iso) + " " + iso.substring(0, 4)
    }

    function rebuild() {
        var all = backend.allTransactions()
        var q = query.toLowerCase().trim()
        var filtered = []
        for (var i = 0; i < all.length; ++i) {
            var t = all[i]
            if (filter === "income" && t.type !== "income")
                continue
            if (filter === "expense" && t.type !== "expense")
                continue
            if (q !== "") {
                var hay = (t.category + " " + t.note + " " + t.date).toLowerCase()
                if (hay.indexOf(q) < 0)
                    continue
            }
            filtered.push(t)
        }

        var groups = []
        for (var j = 0; j < filtered.length; ++j) {
            var tx = filtered[j]
            if (groups.length === 0 || groups[groups.length - 1].date !== tx.date)
                groups.push({ date: tx.date, txs: [] })
            groups[groups.length - 1].txs.push(tx)
        }

        var out = []
        for (var g = 0; g < groups.length; ++g) {
            var grp = groups[g]
            var net = 0
            for (var k = 0; k < grp.txs.length; ++k)
                net += (grp.txs[k].type === "income" ? 1 : -1) * Number(grp.txs[k].amount)
            out.push({ kind: "header", label: dayHeader(grp.date), net: net, key: "h" + grp.date })
            for (var m = 0; m < grp.txs.length; ++m) {
                var item = grp.txs[m]
                out.push({ kind: "tx", id: item.id, category: item.category, note: item.note,
                           amount: item.amount, type: item.type, date: item.date,
                           key: "t" + item.id })
            }
        }
        rows = out
        resultCount = filtered.length
    }

    Component.onCompleted: rebuild()

    Connections {
        target: backend
        function onDataChanged() { page.rebuild() }
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
            spacing: 16

            Column {
                spacing: 3
                Text {
                    text: "Movimenti"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                }
                Text {
                    text: page.resultCount === 0 ? "Nessun risultato"
                          : page.resultCount + (page.resultCount === 1 ? " movimento" : " movimenti")
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 260
                height: 38
                radius: 11
                color: Theme.surface
                border.width: 1
                border.color: searchField.activeFocus ? Theme.withAlpha(Theme.text, 0.18) : Theme.stroke

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 6

                    Item {
                        width: 14
                        height: 14
                        Rectangle {
                            width: 9
                            height: 9
                            radius: 5
                            color: "transparent"
                            border.width: 1.3
                            border.color: Theme.textFaint
                            x: 1
                            y: 1
                        }
                        Rectangle {
                            width: 5
                            height: 1.3
                            radius: 1
                            color: Theme.textFaint
                            x: 9
                            y: 11
                            rotation: 45
                        }
                    }

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: "Cerca…"
                        placeholderTextColor: Theme.textFaint
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        background: Item {}
                        padding: 0
                        onTextChanged: { page.query = text; page.rebuild() }
                    }
                }
            }

            Rectangle {
                width: filters.implicitWidth + 8
                height: 38
                radius: 11
                color: Theme.surface
                border.width: 1
                border.color: Theme.stroke

                Row {
                    id: filters
                    anchors.centerIn: parent
                    spacing: 2

                    Repeater {
                        model: [{ id: "all", label: "Tutti" },
                                { id: "income", label: "Entrate" },
                                { id: "expense", label: "Uscite" }]
                        delegate: Rectangle {
                            id: fchip
                            required property var modelData
                            width: ftext.implicitWidth + 20
                            height: 30
                            radius: 8
                            color: page.filter === fchip.modelData.id ? Theme.withAlpha(Theme.text, 0.09) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: ftext
                                anchors.centerIn: parent
                                text: fchip.modelData.label
                                color: page.filter === fchip.modelData.id ? Theme.text : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: page.filter === fchip.modelData.id ? Font.DemiBold : Font.Normal
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: { page.filter = fchip.modelData.id; page.rebuild() } }
                        }
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

        Item { height: 6 }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: listColumn.height
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: listColumn
                width: flick.width - 8
                spacing: 0

                Repeater {
                    model: page.rows
                    delegate: Item {
                        id: rowWrap
                        required property var modelData
                        required property int index
                        width: listColumn.width
                        height: modelData.kind === "header" ? 44 : 62

                        // Group header
                        RowLayout {
                            visible: rowWrap.modelData.kind === "header"
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 30

                            Text {
                                text: rowWrap.modelData.kind === "header" ? rowWrap.modelData.label : ""
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.6
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.strokeSoft
                                Layout.leftMargin: 12
                            }

                            Money {
                                visible: rowWrap.modelData.kind === "header"
                                value: rowWrap.modelData.kind === "header" ? rowWrap.modelData.net : 0
                                signed: true
                                colorBySign: true
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                opacity: 0.85
                            }
                        }

                        // Transaction row
                        Rectangle {
                            visible: rowWrap.modelData.kind === "tx"
                            height: 56
                            width: parent.width
                            radius: 12
                            color: txHover.hovered ? Theme.surface2 : "transparent"
                            border.width: 1
                            border.color: txHover.hovered ? Theme.stroke : "transparent"
                            Behavior on color { ColorAnimation { duration: 130 } }
                            Behavior on border.color { ColorAnimation { duration: 130 } }

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: rowWrap.modelData.kind === "tx" ? Theme.categoryColor(rowWrap.modelData.category) : "transparent"
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 32
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 200
                                spacing: 2

                                Text {
                                    text: rowWrap.modelData.kind === "tx" ? rowWrap.modelData.category : ""
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: {
                                        if (rowWrap.modelData.kind !== "tx")
                                            return ""
                                        if (rowWrap.modelData.note !== "")
                                            return rowWrap.modelData.note
                                        return rowWrap.modelData.type === "income" ? "Entrata" : "Spesa"
                                    }
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Money {
                                    value: rowWrap.modelData.kind === "tx"
                                           ? (rowWrap.modelData.type === "income" ? rowWrap.modelData.amount : -rowWrap.modelData.amount) : 0
                                    signed: true
                                    colorBySign: true
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    opacity: txHover.hovered ? 1 : 0
                                    color: delHover.hovered ? Theme.withAlpha(Theme.red, 0.18) : Theme.withAlpha(Theme.text, 0.05)
                                    Behavior on opacity { NumberAnimation { duration: 130 } }
                                    Behavior on color { ColorAnimation { duration: 130 } }
                                    anchors.verticalCenter: parent.verticalCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        color: delHover.hovered ? Theme.red : Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                    HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            if (rowWrap.modelData.kind !== "tx")
                                                return
                                            var m = rowWrap.modelData
                                            confirmDelete.ask(m.id, m.category + (m.note !== "" ? " · " + m.note : ""))
                                        }
                                    }
                                }
                            }

                            HoverHandler { id: txHover }
                        }

                        opacity: 0
                        ParallelAnimation {
                            id: rowIn
                            NumberAnimation { target: rowWrap; property: "opacity"; from: 0; to: 1; duration: 260 }
                        }
                        Timer {
                            interval: Math.min(rowWrap.index * 12, 240)
                            running: true
                            onTriggered: rowIn.start()
                        }
                    }
                }

                Item { height: 30 }

                Column {
                    visible: page.rows.length === 0
                    width: parent.width
                    spacing: 8
                    Item { width: 1; height: 60 }
                    Text {
                        text: "Nessun movimento"
                        color: Theme.textDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: page.query !== "" || page.filter !== "all"
                              ? "Prova a cambiare filtro o ricerca."
                              : "Aggiungi la tua prima entrata o spesa dal calendario."
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
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
