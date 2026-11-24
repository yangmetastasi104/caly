import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

Item {
    id: root

    property string stage: "intro"
    property int step: 0
    property string currency: "€"
    property bool finishing: false
    property bool seedSamples: true

    signal finished()

    Component.onCompleted: {
        if (startupStep >= 0) {
            stage = "setup"
            step = Math.min(3, Math.max(0, startupStep))
        }
        if (startupAutopilot) {
            stage = "setup"
            step = 0
            nameField.text = "Killy"
            incomeField.text = "2400"
            goalField.text = "500"
        }
    }

    Timer {
        interval: 620
        repeat: true
        running: startupAutopilot
        property int ticks: 0
        onTriggered: {
            ticks += 1
            if (ticks <= 3) {
                root.nextStep()
            } else {
                running = false
                root.nextStep()
            }
        }
    }

    function parseNum(raw) {
        var cleaned = String(raw).trim().replace(/\s/g, "")
        if (cleaned.indexOf(",") >= 0)
            cleaned = cleaned.replace(/\./g, "").replace(",", ".")
        var v = Number(cleaned)
        return isFinite(v) && v > 0 ? v : 0
    }

    function canContinue() {
        if (step === 0)
            return nameField.text.trim().length > 0
        return true
    }

    function nextStep() {
        if (finishing)
            return
        if (!canContinue()) {
            nameField.forceActiveFocus()
            return
        }
        if (step < 3) {
            step += 1
            stepIn.restart()
        } else {
            finish()
        }
    }

    function prevStep() {
        if (step > 0) {
            step -= 1
            stepIn.restart()
        }
    }

    function beginSetup() {
        introExit.start()
    }

    function finish() {
        if (finishing)
            return
        finishing = true
        finishAnim.start()
    }

    Shortcut {
        sequence: "Return"
        enabled: root.stage === "setup" && root.step > 0
        onActivated: root.nextStep()
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.stage === "setup" && root.step > 0
        onActivated: root.prevStep()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
    }

    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var w = width, h = height
            var g1 = ctx.createRadialGradient(w * 0.16, h * 0.06, 0, w * 0.16, h * 0.06, Math.max(w, h) * 0.62)
            g1.addColorStop(0, "rgba(92,233,186,0.11)")
            g1.addColorStop(0.55, "rgba(92,233,186,0.025)")
            g1.addColorStop(1, "rgba(92,233,186,0)")
            ctx.fillStyle = g1
            ctx.fillRect(0, 0, w, h)

            var g2 = ctx.createRadialGradient(w * 0.94, h * 0.88, 0, w * 0.94, h * 0.88, Math.max(w, h) * 0.55)
            g2.addColorStop(0, "rgba(130,169,255,0.08)")
            g2.addColorStop(1, "rgba(130,169,255,0)")
            ctx.fillStyle = g2
            ctx.fillRect(0, 0, w, h)

            ctx.strokeStyle = "rgba(255,255,255,0.022)"
            ctx.lineWidth = 1
            for (var x = 64; x < w; x += 64) {
                ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, h); ctx.stroke()
            }
            for (var y = 64; y < h; y += 64) {
                ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(w, y); ctx.stroke()
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 34
        anchors.topMargin: 26
        spacing: 10

        Rectangle {
            width: 30
            height: 30
            radius: 9
            color: Theme.withAlpha(Theme.mint, 0.12)
            border.width: 1
            border.color: Theme.withAlpha(Theme.mint, 0.35)
            Text {
                anchors.centerIn: parent
                text: "C"
                color: Theme.mint
                font.family: Theme.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }
        Text {
            text: "CALY"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Bold
            font.letterSpacing: 3
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 34
        anchors.topMargin: 31
        spacing: 8
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: Theme.mint
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "I tuoi dati restano su questo computer"
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Intro ─────────────────────────────────────────────────────────────
    Item {
        id: intro
        anchors.fill: parent
        visible: root.stage === "intro"
        opacity: 1

        RowLayout {
            anchors.centerIn: parent
            width: Math.min(root.width - 100, 1120)
            spacing: 64

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 560
                spacing: 0

                Row {
                    spacing: 10
                    Rectangle {
                        width: 22
                        height: 1
                        color: Theme.mint
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: Theme.greeting().toUpperCase()
                        color: Theme.mint
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.letterSpacing: 2.4
                        font.weight: Font.Bold
                    }
                }

                Item { height: 18 }

                Text {
                    text: "Il tuo denaro,\ngiorno per giorno."
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 50
                    font.weight: Font.DemiBold
                    font.letterSpacing: -1.4
                    lineHeight: 1.02
                    Layout.fillWidth: true
                }

                Item { height: 18 }

                Text {
                    text: "Caly trasforma entrate e spese in un calendario vivo. Un colpo d'occhio, un mese alla volta, con analisi e obiettivi sempre sotto mano."
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                    Layout.fillWidth: true
                    Layout.maximumWidth: 430
                }

                Item { height: 30 }

                Rectangle {
                    width: 188
                    height: 52
                    radius: 14
                    color: ctaHover.hovered ? "#79F2C9" : Theme.mint
                    scale: ctaPress.pressed ? 0.98 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on scale { NumberAnimation { duration: 110 } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        Text {
                            text: "Iniziamo"
                            color: "#06231A"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "→"
                            color: "#06231A"
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    HoverHandler { id: ctaHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: ctaPress; onTapped: root.beginSetup() }
                }

                Item { height: 14 }

                Text {
                    text: "20 secondi · nessun account · nessun cloud"
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Item {
                Layout.preferredWidth: 430
                Layout.preferredHeight: 420

                Rectangle {
                    anchors.centerIn: parent
                    width: 380
                    height: 340
                    radius: 60
                    color: Theme.withAlpha(Theme.mint, 0.045)
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.6; to: 1.0; duration: 2600; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.0; to: 0.6; duration: 2600; easing.type: Easing.InOutSine }
                    }
                }

                Item {
                    id: preview
                    width: 430
                    height: 372
                    anchors.centerIn: parent
                    transform: Translate { id: previewFloat }

                    SequentialAnimation {
                        loops: Animation.Infinite
                        NumberAnimation { target: previewFloat; property: "y"; from: -5; to: 5; duration: 3200; easing.type: Easing.InOutSine }
                        NumberAnimation { target: previewFloat; property: "y"; from: 5; to: -5; duration: 3200; easing.type: Easing.InOutSine }
                    }

                    Rectangle {
                        anchors.fill: card
                        anchors.topMargin: 14
                        radius: 22
                        color: "#05070A"
                        opacity: 0.55
                    }

                    Rectangle {
                        id: card
                        width: parent.width
                        height: 356
                        radius: 22
                        color: "#0D1218"
                        border.width: 1
                        border.color: Theme.stroke

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 1
                            color: Theme.withAlpha(Theme.text, 0.08)
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 22
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "OTTOBRE 2026"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.letterSpacing: 1.8
                                    font.weight: Font.DemiBold
                                }
                                Item { Layout.fillWidth: true }
                                Row {
                                    spacing: 5
                                    Rectangle {
                                        width: 5; height: 5; radius: 3
                                        color: Theme.mint
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "ANTEPRIMA"
                                        color: Theme.withAlpha(Theme.mint, 0.8)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        font.letterSpacing: 1.4
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Item { height: 10 }

                            Text {
                                text: "+442,32 €"
                                color: Theme.mint
                                font.family: Theme.fontFamily
                                font.pixelSize: 32
                                font.weight: Font.DemiBold
                                font.letterSpacing: -0.6
                            }
                            Text {
                                text: "Netto del mese"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            Item { height: 14 }

                            Grid {
                                Layout.fillWidth: true
                                columns: 7
                                spacing: 4

                                Repeater {
                                    model: 35
                                    delegate: Rectangle {
                                        id: mockCell
                                        required property int index
                                        width: (card.width - 44 - 24) / 7
                                        height: 33
                                        radius: 5
                                        property var info: mockInfo(index)
                                        color: info.tint
                                        border.width: index === 24 ? 1 : 0
                                        border.color: Theme.withAlpha(Theme.mint, 0.5)

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 5
                                            anchors.top: parent.top
                                            anchors.topMargin: 3
                                            text: index + 1 <= 31 ? index + 1 : ""
                                            color: Theme.textFaint
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                        }
                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 5
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 3
                                            text: mockCell.info.label
                                            color: mockCell.info.color
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }

                            Item { height: 12 }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 8
                                    color: Theme.withAlpha(Theme.mint, 0.07)
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.mint, 0.16)
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            text: "ENTRATE"
                                            color: Theme.withAlpha(Theme.mint, 0.75)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 7
                                            font.letterSpacing: 1
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "2.480,00 €"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 34
                                    radius: 8
                                    color: Theme.withAlpha(Theme.red, 0.07)
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.red, 0.16)
                                    Column {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 9
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1
                                        Text {
                                            text: "USCITE"
                                            color: Theme.withAlpha(Theme.red, 0.8)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 7
                                            font.letterSpacing: 1
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            text: "2.037,68 €"
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function mockInfo(index) {
        var vals = { 4: -27.69, 5: 55.32, 6: 414.9, 12: -12.4, 19: 30.0, 24: 120.5, 27: -60.0, 30: -18.2 }
        var v = vals[index]
        if (v === undefined)
            return { tint: "transparent", label: "", color: "transparent" }
        var positive = v > 0
        return {
            tint: positive ? Theme.withAlpha(Theme.mint, 0.10) : Theme.withAlpha(Theme.red, 0.10),
            label: (positive ? "+" : "−") + Math.abs(v).toFixed(0),
            color: positive ? Theme.mint : Theme.red
        }
    }

    // ── Setup ─────────────────────────────────────────────────────────────
    Item {
        id: setup
        anchors.fill: parent
        visible: root.stage === "setup"
        opacity: 0

        onVisibleChanged: {
            if (visible) {
                setupIn.start()
                nameField.forceActiveFocus()
            }
        }

        Rectangle {
            id: setupCard
            width: Math.min(620, root.width - 80)
            height: setupContent.implicitHeight + 64
            anchors.centerIn: parent
            radius: 22
            color: "#0C1117"
            border.width: 1
            border.color: Theme.stroke
            opacity: 0
            scale: 0.98
            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: setupContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 32
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "PASSO " + (root.step + 1) + " DI 4"
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.letterSpacing: 1.6
                        font.weight: Font.DemiBold
                    }

                    Item { Layout.fillWidth: true }

                    Row {
                        spacing: 5
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                width: root.step === index ? 20 : 5
                                height: 5
                                radius: 3
                                color: root.step === index ? Theme.mint
                                       : (index < root.step ? Theme.withAlpha(Theme.mint, 0.4) : Theme.withAlpha(Theme.text, 0.12))
                                Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                        }
                    }
                }

                Item { height: 22 }

                Text {
                    text: {
                        if (root.step === 0) return "Come ti chiami?"
                        if (root.step === 1) return "Scegli la valuta."
                        if (root.step === 2) return "I tuoi obiettivi."
                        return "Tutto pronto, " + (nameField.text.trim() !== "" ? nameField.text.trim() : "amico") + "."
                    }
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                }

                Item { height: 6 }

                Text {
                    text: {
                        if (root.step === 0) return "Lo useremo per salutarti ogni volta che apri Caly."
                        if (root.step === 1) return "Ogni importo verrà mostrato con il simbolo che scegli."
                        if (root.step === 2) return "Solo un riferimento. Potrai cambiarli quando vuoi."
                        return "Il tuo calendario è pronto. Da qui in poi contano solo i numeri."
                    }
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Item { height: 22 }

                Item {
                    id: stepArea
                    Layout.fillWidth: true
                    height: root.step === 0 ? 158 : root.step === 1 ? 108 : root.step === 2 ? 100 : 178
                    transform: Translate { id: stepShift }
                    Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                    // Step 0 — name
                    Column {
                        visible: root.step === 0
                        width: parent.width
                        spacing: 10

                        TextField {
                            id: nameField
                            width: parent.width
                            placeholderText: "Il tuo nome"
                            placeholderTextColor: Theme.textFaint
                            color: Theme.text
                            selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                            selectedTextColor: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            padding: 0
                            background: Item {}
                            onTextChanged: root.canContinue()
                            onAccepted: root.nextStep()
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: nameField.activeFocus ? Theme.withAlpha(Theme.mint, 0.6) : Theme.stroke
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Item { height: 6 }

                        Text {
                            text: "Puoi usare un soprannome, nessuno ti giudica."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }

                        Item { height: 14 }

                        Rectangle {
                            width: parent.width
                            height: 62
                            radius: 12
                            color: Theme.withAlpha(Theme.mint, nameField.text.trim() !== "" ? 0.05 : 0.02)
                            border.width: 1
                            border.color: nameField.text.trim() !== "" ? Theme.withAlpha(Theme.mint, 0.18) : Theme.strokeSoft
                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.color { ColorAnimation { duration: 200 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 13
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 11

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: Theme.withAlpha(Theme.mint, 0.12)
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.mint, 0.3)
                                    Text {
                                        anchors.centerIn: parent
                                        text: nameField.text.trim() !== "" ? nameField.text.trim().charAt(0).toUpperCase() : "A"
                                        color: Theme.mint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                    }
                                }

                                Column {
                                    spacing: 1
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        text: nameField.text.trim() !== "" ? ("Ciao, " + nameField.text.trim() + ".") : "Il tuo saluto qui"
                                        color: nameField.text.trim() !== "" ? Theme.text : Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: "Caly ti accoglierà così, ogni volta."
                                        color: Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }

                    // Step 1 — currency
                    RowLayout {
                        visible: root.step === 1
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 10

                        Repeater {
                            model: [{ symbol: "€", code: "EUR" },
                                    { symbol: "$", code: "USD" },
                                    { symbol: "£", code: "GBP" },
                                    { symbol: "CHF", code: "CHF" }]
                            delegate: Rectangle {
                                id: curTile
                                required property var modelData
                                Layout.fillWidth: true
                                height: 96
                                radius: 14
                                color: root.currency === curTile.modelData.symbol
                                       ? Theme.withAlpha(Theme.mint, 0.10)
                                       : Theme.withAlpha(Theme.text, 0.03)
                                border.width: 1
                                border.color: root.currency === curTile.modelData.symbol
                                              ? Theme.withAlpha(Theme.mint, 0.5)
                                              : Theme.strokeSoft
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 3
                                    Text {
                                        text: curTile.modelData.symbol
                                        color: root.currency === curTile.modelData.symbol ? Theme.text : Theme.textDim
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 26
                                        font.weight: Font.DemiBold
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: curTile.modelData.code
                                        color: Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.letterSpacing: 1.2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.currency = curTile.modelData.symbol }
                            }
                        }
                    }

                    // Step 2 — targets
                    RowLayout {
                        visible: root.step === 2
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "ENTRATE MENSILI"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                                font.weight: Font.DemiBold
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 6
                                Text {
                                    text: root.currency
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    Layout.alignment: Qt.AlignBottom
                                    Layout.bottomMargin: 6
                                }
                                TextField {
                                    id: incomeField
                                    Layout.fillWidth: true
                                    placeholderText: "2.000"
                                    placeholderTextColor: Theme.textFaint
                                    color: Theme.text
                                    selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                                    selectedTextColor: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    padding: 0
                                    background: Item {}
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    onAccepted: root.nextStep()
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: incomeField.activeFocus ? Theme.withAlpha(Theme.mint, 0.6) : Theme.stroke
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "RISPARMIO MENSILE"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.letterSpacing: 1.5
                                font.weight: Font.DemiBold
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 10
                                spacing: 6
                                Text {
                                    text: root.currency
                                    color: Theme.textDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    Layout.alignment: Qt.AlignBottom
                                    Layout.bottomMargin: 6
                                }
                                TextField {
                                    id: goalField
                                    Layout.fillWidth: true
                                    placeholderText: "500"
                                    placeholderTextColor: Theme.textFaint
                                    color: Theme.text
                                    selectionColor: Theme.withAlpha(Theme.mint, 0.3)
                                    selectedTextColor: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    padding: 0
                                    background: Item {}
                                    inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    onAccepted: root.nextStep()
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: goalField.activeFocus ? Theme.withAlpha(Theme.mint, 0.6) : Theme.stroke
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }
                    }

                    // Step 3 — ready
                    Column {
                        visible: root.step === 3
                        width: parent.width
                        spacing: 0

                        Row {
                            width: parent.width
                            spacing: 14

                            Item {
                                width: 58
                                height: 58
                                Rectangle {
                                    id: checkCircle
                                    anchors.centerIn: parent
                                    width: 52
                                    height: 52
                                    radius: 26
                                    color: Theme.withAlpha(Theme.mint, 0.12)
                                    border.width: 1
                                    border.color: Theme.withAlpha(Theme.mint, 0.4)
                                    scale: root.step === 3 ? 1 : 0.6
                                    Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: Theme.mint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 24
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            ColumnLayout {
                                width: parent.width - 72
                                spacing: 2
                                Text {
                                    text: "Profilo creato"
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: (nameField.text.trim() !== "" ? nameField.text.trim() : "Amico")
                                          + " · " + root.currency + " · obiettivo "
                                          + Theme.money(root.parseNum(incomeField.text), root.currency, 0)
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Item { height: 22 }

                        Rectangle {
                            width: parent.width
                            height: 62
                            radius: 12
                            color: Theme.withAlpha(Theme.text, 0.025)
                            border.width: 1
                            border.color: Theme.strokeSoft

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                spacing: 10

                                ColumnLayout {
                                    spacing: 2
                                    Text {
                                        text: "Movimenti di esempio"
                                        color: Theme.text
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: "Tre mesi di dati per vedere subito il calendario vivo."
                                        color: Theme.textFaint
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 42
                                    height: 24
                                    radius: 12
                                    color: root.seedSamples ? Theme.withAlpha(Theme.mint, 0.85) : Theme.withAlpha(Theme.text, 0.10)
                                    Behavior on color { ColorAnimation { duration: 180 } }

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        y: 3
                                        x: root.seedSamples ? 21 : 3
                                        color: root.seedSamples ? "#06231A" : Theme.textDim
                                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    }
                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: root.seedSamples = !root.seedSamples }
                                }
                            }
                        }

                        Item { height: 14 }

                        Text {
                            text: "Potrai aggiungere, modificare e cancellare tutto dal calendario."
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                        }
                    }
                }

                Item { height: 22 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        visible: root.step > 0
                        width: 104
                        height: 46
                        radius: 12
                        color: backHover.hovered ? Theme.withAlpha(Theme.text, 0.07) : Theme.withAlpha(Theme.text, 0.03)
                        border.width: 1
                        border.color: Theme.stroke
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text {
                            anchors.centerIn: parent
                            text: "Indietro"
                            color: Theme.textDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        HoverHandler { id: backHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.prevStep() }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 190
                        height: 46
                        radius: 12
                        enabled: root.canContinue()
                        color: !root.canContinue() ? Theme.withAlpha(Theme.text, 0.06)
                               : (nextHover.hovered ? "#79F2C9" : Theme.mint)
                        scale: nextPress.pressed ? 0.98 : 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 110 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.step === 3 ? "Apri il calendario" : "Continua"
                            color: root.canContinue() ? "#06231A" : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }
                        HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: nextPress; onTapped: root.nextStep() }
                    }
                }
            }
        }

        ParallelAnimation {
            id: setupIn
            NumberAnimation { target: setup; property: "opacity"; from: 0; to: 1; duration: 300 }
            NumberAnimation { target: setupCard; property: "opacity"; from: 0; to: 1; duration: 340 }
            NumberAnimation { target: setupCard; property: "scale"; from: 0.975; to: 1; duration: 420; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: stepIn
            NumberAnimation { target: stepArea; property: "opacity"; from: 0; to: 1; duration: 260 }
            NumberAnimation { target: stepShift; property: "y"; from: 10; to: 0; duration: 320; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: introExit
        NumberAnimation { target: intro; property: "opacity"; from: 1; to: 0; duration: 240 }
        NumberAnimation { target: intro; property: "scale"; from: 1; to: 0.985; duration: 260 }
        ScriptAction { script: { root.stage = "setup" } }
    }

    SequentialAnimation {
        id: finishAnim
        ParallelAnimation {
            NumberAnimation { target: setupCard; property: "opacity"; from: 1; to: 0; duration: 240 }
            NumberAnimation { target: setupCard; property: "scale"; from: 1; to: 0.97; duration: 260; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                backend.completeOnboarding(nameField.text.trim(), root.currency,
                                           root.parseNum(incomeField.text),
                                           root.parseNum(goalField.text),
                                           root.seedSamples)
                root.finished()
            }
        }
    }
}
