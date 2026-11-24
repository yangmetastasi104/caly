import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: page

    property string nameValue: ""
    property string currencyValue: "€"
    property string targetText: ""
    property string goalText: ""
    property bool confirmReset: false

    signal toastRequested(string message, bool danger)

    readonly property var currencies: [
        { symbol: "€", code: "EUR" },
        { symbol: "$", code: "USD" },
        { symbol: "£", code: "GBP" },
        { symbol: "CHF", code: "CHF" }
    ]

    function loadProfile() {
        nameValue = backend.userName
        currencyValue = backend.currency
        targetText = backend.monthlyTarget > 0 ? Number(backend.monthlyTarget).toFixed(0) : ""
        goalText = backend.savingsGoal > 0 ? Number(backend.savingsGoal).toFixed(0) : ""
        nameField.text = nameValue
        targetField.text = targetText
        goalField.text = goalText
    }

    function parseNum(raw) {
        var cleaned = String(raw).trim().replace(/\s/g, "")
        if (cleaned.indexOf(",") >= 0)
            cleaned = cleaned.replace(/\./g, "").replace(",", ".")
        var v = Number(cleaned)
        return isFinite(v) && v >= 0 ? v : 0
    }

    function saveProfile() {
        backend.updateProfile(nameField.text, currencyValue, parseNum(targetField.text), parseNum(goalField.text))
        page.toastRequested("Impostazioni salvate", false)
    }

    Component.onCompleted: loadProfile()

    Connections {
        target: backend
        function onProfileChanged() { page.loadProfile() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        anchors.bottomMargin: 18
        spacing: 0

        Column {
            spacing: 3
            Text {
                text: "Impostazioni"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 28
                font.weight: Font.DemiBold
                font.letterSpacing: -0.4
            }
            Text {
                text: "Profilo, obiettivi e dati locali"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Item { height: 20 }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: profileCol.implicitHeight + 44
                height: implicitHeight
                radius: 18
                color: Theme.surface
                border.width: 1
                border.color: Theme.stroke

                ColumnLayout {
                    id: profileCol
                    width: parent.width - 44
                    x: 22
                    y: 22
                    spacing: 0

                    Text {
                        text: "Profilo"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: "Come vuoi essere chiamato e quali sono i tuoi obiettivi."
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Item { height: 20 }

                    Text {
                        text: "NOME"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.5
                        font.weight: Font.DemiBold
                    }
                    TextField {
                        id: nameField
                        Layout.fillWidth: true
                        Layout.topMargin: 7
                        placeholderText: "Il tuo nome"
                        placeholderTextColor: Theme.textFaint
                        color: Theme.text
                        selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                        selectedTextColor: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        padding: 12
                        background: Rectangle {
                            height: 40
                            radius: 10
                            color: Theme.bgLift
                            border.width: 1
                            border.color: nameField.activeFocus ? Theme.withAlpha(Theme.text, 0.18) : Theme.strokeSoft
                        }
                    }

                    Item { height: 18 }

                    Text {
                        text: "VALUTA"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.5
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        spacing: 8

                        Repeater {
                            model: page.currencies
                            delegate: Rectangle {
                                id: cur
                                required property var modelData
                                Layout.fillWidth: true
                                height: 54
                                radius: 11
                                color: page.currencyValue === cur.modelData.symbol
                                       ? Theme.withAlpha(Theme.mint, 0.10)
                                       : Theme.withAlpha(Theme.text, 0.03)
                                border.width: 1
                                border.color: page.currencyValue === cur.modelData.symbol
                                              ? Theme.withAlpha(Theme.mint, 0.45)
                                              : Theme.strokeSoft
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    Text {
                                        text: cur.modelData.symbol
                                        color: page.currencyValue === cur.modelData.symbol ? Theme.text : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 16
                                        font.weight: Font.DemiBold
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: cur.modelData.code
                                        color: Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        font.letterSpacing: 1
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: page.currencyValue = cur.modelData.symbol }
                            }
                        }
                    }

                    Item { height: 18 }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "OBIETTIVO ENTRATE / MESE"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.letterSpacing: 1.4
                                font.weight: Font.DemiBold
                            }
                            TextField {
                                id: targetField
                                Layout.fillWidth: true
                                Layout.topMargin: 7
                                placeholderText: "0"
                                placeholderTextColor: Theme.textFaint
                                color: Theme.text
                                selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                                selectedTextColor: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                padding: 12
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                background: Rectangle {
                                    height: 40
                                    radius: 10
                                    color: Theme.bgLift
                                    border.width: 1
                                    border.color: targetField.activeFocus ? Theme.withAlpha(Theme.text, 0.18) : Theme.strokeSoft
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "RISPARMIO / MESE"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.letterSpacing: 1.4
                                font.weight: Font.DemiBold
                            }
                            TextField {
                                id: goalField
                                Layout.fillWidth: true
                                Layout.topMargin: 7
                                placeholderText: "0"
                                placeholderTextColor: Theme.textFaint
                                color: Theme.text
                                selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                                selectedTextColor: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                padding: 12
                                inputMethodHints: Qt.ImhFormattedNumbersOnly
                                background: Rectangle {
                                    height: 40
                                    radius: 10
                                    color: Theme.bgLift
                                    border.width: 1
                                    border.color: goalField.activeFocus ? Theme.withAlpha(Theme.text, 0.18) : Theme.strokeSoft
                                }
                            }
                        }
                    }

                    Item { height: 24 }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 118
                        radius: 12
                        color: Theme.withAlpha(Theme.text, 0.025)
                        border.width: 1
                        border.color: Theme.strokeSoft

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 9

                            Text {
                                text: "SCORCIATOIE"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                                font.weight: Font.DemiBold
                            }

                            Row {
                                width: parent.width
                                spacing: 10

                                Rectangle {
                                    width: 54; height: 22; radius: 6
                                    color: Theme.bgLift
                                    border.width: 1
                                    border.color: Theme.strokeSoft
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Ctrl 1–4"
                                        color: Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                    }
                                }
                                Text {
                                    text: "Cambia sezione"
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: 10

                                Rectangle {
                                    width: 54; height: 22; radius: 6
                                    color: Theme.bgLift
                                    border.width: 1
                                    border.color: Theme.strokeSoft
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Ctrl N"
                                        color: Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                    }
                                }
                                Text {
                                    text: "Nuovo movimento"
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    Item { height: 18 }

                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 150
                            height: 42
                            radius: 11
                            color: saveHover.hovered ? "#79F2C9" : Theme.mint
                            scale: savePress.pressed ? 0.985 : 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 110 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Salva"
                                color: "#06231A"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                            HoverHandler { id: saveHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: savePress; onTapped: page.saveProfile() }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 18
                color: Theme.surface
                border.width: 1
                border.color: Theme.stroke

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 10

                    Text {
                        text: "COME FUNZIONA"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.5
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Rectangle {
                            width: 22; height: 22; radius: 7
                            color: Theme.withAlpha(Theme.mint, 0.10)
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.mint, 0.25)
                            Text {
                                anchors.centerIn: parent
                                text: "1"
                                color: Theme.mint
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Clicca un giorno sul calendario per vedere e aggiungere movimenti."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Rectangle {
                            width: 22; height: 22; radius: 7
                            color: Theme.withAlpha(Theme.blue, 0.10)
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.blue, 0.25)
                            Text {
                                anchors.centerIn: parent
                                text: "2"
                                color: Theme.blue
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Ogni giorno mostra il netto: verde se hai guadagnato, rosso se hai speso."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Rectangle {
                            width: 22; height: 22; radius: 7
                            color: Theme.withAlpha(Theme.text, 0.06)
                            border.width: 1
                            border.color: Theme.strokeSoft
                            Text {
                                anchors.centerIn: parent
                                text: "3"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Analisi somma l'anno, Impostazioni esporta tutto in JSON."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
            }

            ColumnLayout {
                Layout.preferredWidth: 380
                Layout.minimumWidth: 380
                Layout.maximumWidth: 380
                Layout.fillHeight: true
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 252
                    radius: 18
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.stroke

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 0

                        Text {
                            text: "Dati"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Tutto vive in un file sul tuo computer."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Item { height: 14 }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 9
                            color: Theme.bgLift
                            border.width: 1
                            border.color: Theme.strokeSoft

                            Text {
                                anchors.fill: parent
                                anchors.margins: 11
                                text: backend.dataPath
                                color: Theme.textDim
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                elide: Text.ElideMiddle
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Item { height: 12 }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: exportHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : Theme.withAlpha(Theme.text, 0.03)
                            border.width: 1
                            border.color: Theme.stroke
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Esporta in JSON"
                                color: Theme.textDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                            HoverHandler { id: exportHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    var p = backend.exportJson()
                                    if (p !== "")
                                        page.toastRequested("Esportato in Documenti", false)
                                    else
                                        page.toastRequested("Esportazione non riuscita", true)
                                }
                            }
                        }

                        Item { height: 10 }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            radius: 10
                            color: resetHover.hovered ? Theme.withAlpha(Theme.red, 0.12) : Theme.withAlpha(Theme.red, 0.05)
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.red, 0.25)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: "Cancella tutti i dati"
                                color: Theme.red
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                            HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: page.confirmReset = true }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "Nessun account. Nessun cloud. Solo il tuo file."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 18
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.stroke

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 22
                        spacing: 0

                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 10
                                color: Theme.withAlpha(Theme.mint, 0.10)
                                border.width: 1
                                border.color: Theme.withAlpha(Theme.mint, 0.25)
                                Text {
                                    anchors.centerIn: parent
                                    text: "C"
                                    color: Theme.mint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text {
                                    text: "Caly"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "Versione 1.0"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                }
                            }
                        }

                        Item { height: 18 }

                        Text {
                            text: "Un calendario del denaro per Linux. Entrate, spese e andamento mensile in un colpo d'occhio. Costruito con Qt 6 e QML, animazioni comprese."
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            lineHeight: 1.35
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "I tuoi dati non lasciano mai questa macchina."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        z: 50
        color: "#B8000000"
        visible: opacity > 0.001
        opacity: page.confirmReset ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        MouseArea {
            anchors.fill: parent
            onClicked: page.confirmReset = false
        }

        Rectangle {
            width: 400
            height: 210
            radius: 18
            anchors.centerIn: parent
            color: "#0F141B"
            border.width: 1
            border.color: Theme.withAlpha(Theme.red, 0.3)
            scale: page.confirmReset ? 1 : 0.96
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 0

                Text {
                    text: "Cancellare tutti i dati?"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
                Item { height: 8 }
                Text {
                    text: "Movimenti, profilo e obiettivi verranno rimossi. Il file locale resta vuoto e l'app riparte dal benvenuto. L'operazione non si può annullare."
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    lineHeight: 1.3
                }
                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: Theme.withAlpha(Theme.text, 0.04)
                        border.width: 1
                        border.color: Theme.stroke
                        Text {
                            anchors.centerIn: parent
                            text: "Annulla"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: page.confirmReset = false }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: resetYesHover.hovered ? "#FF8593" : Theme.red
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancella tutto"
                            color: "#2A060B"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }
                        HoverHandler { id: resetYesHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: {
                                page.confirmReset = false
                                backend.resetAll()
                            }
                        }
                    }
                }
            }
        }
    }
}
