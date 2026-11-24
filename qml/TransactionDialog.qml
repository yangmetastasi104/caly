import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: root
    property bool open: false
    property string isoDate: backend.todayIso
    property string type: "expense"
    property string category: "Cibo"
    property string errorText: ""

    signal saved()

    visible: open || closeAnim.running
    z: 100

    function categories() {
        return type === "income" ? Theme.incomeCategories : Theme.expenseCategories
    }

    function reset() {
        amountField.text = ""
        noteField.text = ""
        errorText = ""
        type = "expense"
        category = "Cibo"
    }

    function parseAmount(raw) {
        var cleaned = String(raw).trim().replace(/\s/g, "")
        if (cleaned.indexOf(",") >= 0)
            cleaned = cleaned.replace(/\./g, "").replace(",", ".")
        var v = Number(cleaned)
        return isFinite(v) ? v : NaN
    }

    function save() {
        var v = parseAmount(amountField.text)
        if (!isFinite(v) || v <= 0) {
            errorText = "Inserisci un importo maggiore di zero."
            shake.start()
            return
        }
        if (backend.addTransaction(isoDate, v, type, category, noteField.text)) {
            open = false
            saved()
        } else {
            errorText = "Non riesco a salvare. Controlla la data."
            shake.start()
        }
    }

    function shiftDay(delta) {
        var d = new Date(isoDate + "T12:00:00")
        d.setDate(d.getDate() + delta)
        var y = d.getFullYear()
        var m = ("0" + (d.getMonth() + 1)).slice(-2)
        var day = ("0" + d.getDate()).slice(-2)
        isoDate = y + "-" + m + "-" + day
    }

    function quickSave(amount, kind, cat, note) {
        amountField.text = String(amount)
        type = kind
        category = cat
        noteField.text = note
        save()
    }

    onOpenChanged: {
        if (open) {
            reset()
            enterAnim.start()
            amountField.forceActiveFocus()
        } else {
            closeAnim.start()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.open
        onActivated: root.open = false
    }

    Rectangle {
        anchors.fill: parent
        color: "#B8000000"
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }
    }

    Item {
        id: cardWrap
        width: Math.min(500, root.width - 48)
        height: card.height
        anchors.centerIn: parent
        opacity: 0
        scale: 0.96
        transform: Translate { id: cardShift }

        Rectangle {
            anchors.fill: card
            anchors.topMargin: 18
            radius: 20
            color: "#000000"
            opacity: 0.5
        }

        Rectangle {
            id: card
            width: parent.width
            height: content.implicitHeight + 48
            radius: 20
            color: "#0F141B"
            border.width: 1
            border.color: Theme.stroke

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.withAlpha(Theme.text, 0.07)
            }

            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: "Nuovo movimento"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: Theme.dayLabel(root.isoDate)
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: prevHover.hovered ? Theme.withAlpha(Theme.text, 0.08) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "‹"
                                color: Theme.textDim
                                font.pixelSize: 16
                                font.family: Theme.fontFamily
                            }
                            HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.shiftDay(-1) }
                        }
                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: nextHover.hovered ? Theme.withAlpha(Theme.text, 0.08) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "›"
                                color: Theme.textDim
                                font.pixelSize: 16
                                font.family: Theme.fontFamily
                            }
                            HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.shiftDay(1) }
                        }
                        Rectangle {
                            width: 30; height: 30; radius: 15
                            color: closeHover.hovered ? Theme.withAlpha(Theme.text, 0.08) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: Theme.textFaint
                                font.pixelSize: 12
                                font.family: Theme.fontFamily
                            }
                            HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.open = false }
                        }
                    }
                }

                Item { height: 18 }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 11
                    color: Theme.bgLift
                    border.width: 1
                    border.color: Theme.strokeSoft

                    Rectangle {
                        width: parent.width / 2 - 4
                        height: parent.height - 8
                        radius: 8
                        y: 4
                        x: root.type === "expense" ? parent.width / 2 + 0 : 4
                        color: root.type === "expense" ? Theme.withAlpha(Theme.red, 0.14) : Theme.withAlpha(Theme.mint, 0.14)
                        border.width: 1
                        border.color: root.type === "expense" ? Theme.withAlpha(Theme.red, 0.3) : Theme.withAlpha(Theme.mint, 0.3)
                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 0

                        Item {
                            width: parent.width / 2
                            height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: "Entrata"
                                color: root.type === "income" ? Theme.mint : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.type = "income"; root.category = "Stipendio" }
                            }
                        }
                        Item {
                            width: parent.width / 2
                            height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: "Uscita"
                                color: root.type === "expense" ? Theme.red : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.type = "expense"; root.category = "Cibo" }
                            }
                        }
                    }
                }

                Item { height: 20 }

                Text {
                    text: "IMPORTO"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.topMargin: 2

                    Text {
                        text: backend.currency
                        color: root.type === "expense" ? Theme.red : Theme.mint
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                        font.weight: Font.DemiBold
                    }

                    TextField {
                        id: amountField
                        Layout.fillWidth: true
                        placeholderText: "0,00"
                        placeholderTextColor: Theme.textFaint
                        color: Theme.text
                        selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                        selectedTextColor: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.DemiBold
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        background: Item {}
                        padding: 0
                        onTextChanged: root.errorText = ""
                        Keys.onReturnPressed: root.save()
                        Keys.onEnterPressed: root.save()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.errorText !== "" ? Theme.withAlpha(Theme.red, 0.6) : Theme.stroke
                }

                Text {
                    visible: root.errorText !== ""
                    Layout.topMargin: 8
                    text: root.errorText
                    color: Theme.red
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Item { height: 18 }

                Text {
                    text: "CATEGORIA"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    font.weight: Font.DemiBold
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 9
                    spacing: 7

                    Repeater {
                        model: root.categories()
                        delegate: Rectangle {
                            id: chip
                            required property string modelData
                            width: chipText.implicitWidth + 22
                            height: 30
                            radius: 9
                            color: root.category === chip.modelData
                                   ? Theme.withAlpha(Theme.categoryColor(chip.modelData), 0.16)
                                   : Theme.withAlpha(Theme.text, 0.035)
                            border.width: 1
                            border.color: root.category === chip.modelData
                                          ? Theme.withAlpha(Theme.categoryColor(chip.modelData), 0.5)
                                          : Theme.strokeSoft
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: chip.modelData
                                color: root.category === chip.modelData ? Theme.text : Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: root.category === chip.modelData ? Font.DemiBold : Font.Normal
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.category = chip.modelData }
                        }
                    }
                }

                Item { height: 18 }

                Text {
                    text: "NOTA"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    font.weight: Font.DemiBold
                }

                TextField {
                    id: noteField
                    Layout.fillWidth: true
                    Layout.topMargin: 7
                    placeholderText: "Es. spesa settimanale"
                    placeholderTextColor: Theme.textFaint
                    color: Theme.text
                    selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                    selectedTextColor: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    background: Rectangle {
                        height: 40
                        radius: 10
                        color: Theme.bgLift
                        border.width: 1
                        border.color: noteField.activeFocus ? Theme.withAlpha(Theme.text, 0.18) : Theme.strokeSoft
                    }
                    padding: 12
                    leftPadding: 12
                    Keys.onReturnPressed: root.save()
                    Keys.onEnterPressed: root.save()
                }

                Item { height: 22 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 11
                        color: cancelHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : Theme.withAlpha(Theme.text, 0.03)
                        border.width: 1
                        border.color: Theme.stroke
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Annulla"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                        HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.open = false }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: 11
                        color: saveHover.hovered ? "#79F2C9" : Theme.mint
                        scale: savePress.pressed ? 0.985 : 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 110 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Salva movimento"
                            color: "#06231A"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        HoverHandler { id: saveHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: savePress; onTapped: root.save() }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: cardWrap; property: "opacity"; from: 0; to: 1; duration: 220 }
        NumberAnimation { target: cardWrap; property: "scale"; from: 0.96; to: 1; duration: 300; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: cardWrap; property: "opacity"; from: 1; to: 0; duration: 160 }
        NumberAnimation { target: cardWrap; property: "scale"; from: 1; to: 0.97; duration: 160 }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: cardShift; property: "x"; to: -8; duration: 45 }
        NumberAnimation { target: cardShift; property: "x"; to: 8; duration: 70 }
        NumberAnimation { target: cardShift; property: "x"; to: -6; duration: 70 }
        NumberAnimation { target: cardShift; property: "x"; to: 0; duration: 60 }
    }
}
