import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme.js" as Theme

ApplicationWindow {
    id: win
    width: 1320
    height: 860
    minimumWidth: 1080
    minimumHeight: 720
    visible: true
    color: Theme.bg
    title: "Caly — Calendario del denaro"

    property int currentPage: 0
    property var lifetime: ({ income: 0, expense: 0, net: 0, count: 0 })

    Shortcut { sequence: "Ctrl+1"; onActivated: win.currentPage = 0 }
    Shortcut { sequence: "Ctrl+2"; onActivated: win.currentPage = 1 }
    Shortcut { sequence: "Ctrl+3"; onActivated: win.currentPage = 2 }
    Shortcut { sequence: "Ctrl+4"; onActivated: win.currentPage = 3 }

    function refreshLifetime() {
        lifetime = backend.lifetimeSummary()
    }

    Component.onCompleted: {
        refreshLifetime()
        if (startupPage >= 0)
            currentPage = Math.min(3, Math.max(0, startupPage))
    }

    Connections {
        target: backend
        function onDataChanged() { win.refreshLifetime() }
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

            var g1 = ctx.createRadialGradient(w * 0.08, -h * 0.05, 0, w * 0.08, -h * 0.05, w * 0.55)
            g1.addColorStop(0, "rgba(92,233,186,0.075)")
            g1.addColorStop(0.6, "rgba(92,233,186,0.015)")
            g1.addColorStop(1, "rgba(92,233,186,0)")
            ctx.fillStyle = g1
            ctx.fillRect(0, 0, w, h)

            var g2 = ctx.createRadialGradient(w * 1.02, h * 0.18, 0, w * 1.02, h * 0.18, w * 0.48)
            g2.addColorStop(0, "rgba(130,169,255,0.06)")
            g2.addColorStop(1, "rgba(130,169,255,0)")
            ctx.fillStyle = g2
            ctx.fillRect(0, 0, w, h)

            var g3 = ctx.createRadialGradient(w * 0.55, h * 1.1, 0, w * 0.55, h * 1.1, w * 0.5)
            g3.addColorStop(0, "rgba(180,146,255,0.045)")
            g3.addColorStop(1, "rgba(180,146,255,0)")
            ctx.fillStyle = g3
            ctx.fillRect(0, 0, w, h)
        }
    }

    Loader {
        id: rootLoader
        anchors.fill: parent
        asynchronous: false
        opacity: 0
        sourceComponent: backend.onboarded ? shellComponent : onboardingComponent
        onLoaded: fadeIn.start()

        Behavior on opacity { NumberAnimation { duration: 240 } }

        ParallelAnimation {
            id: fadeIn
            NumberAnimation { target: rootLoader; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
        }
    }

    Component {
        id: onboardingComponent
        Onboarding {
        }
    }

    Component {
        id: shellComponent
        Item {
            id: shell

            property string dialogDate: backend.todayIso

            function openNew(dateIso) {
                dialogDate = (dateIso && dateIso !== "") ? dateIso : backend.todayIso
                txDialog.isoDate = dialogDate
                txDialog.open = true
            }

            Shortcut { sequence: "Ctrl+N"; onActivated: shell.openNew(backend.todayIso) }

            Timer {
                interval: 700
                running: startupAutoAdd
                onTriggered: {
                    txDialog.quickSave(12.5, "expense", "Cibo", "verifica automatica")
                    running = false
                }
            }

            Component.onCompleted: {
                if (startupDialog || startupAutoAdd)
                    shell.openNew(backend.todayIso)
            }

            // ── Top bar ───────────────────────────────────────────────────
            Rectangle {
                id: topBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 68
                color: Theme.withAlpha(Theme.bg, 0.55)

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.strokeSoft
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.withAlpha(Theme.text, 0.04)
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 26
                    anchors.rightMargin: 22
                    spacing: 0

                    Row {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

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

                    Item { width: 30 }

                    Row {
                        spacing: 2
                        Layout.alignment: Qt.AlignVCenter

                        NavTab {
                            label: "Calendario"
                            active: win.currentPage === 0
                            onClicked: win.currentPage = 0
                        }
                        NavTab {
                            label: "Movimenti"
                            active: win.currentPage === 1
                            onClicked: win.currentPage = 1
                        }
                        NavTab {
                            label: "Analisi"
                            active: win.currentPage === 2
                            onClicked: win.currentPage = 2
                        }
                        NavTab {
                            label: "Impostazioni"
                            active: win.currentPage === 3
                            onClicked: win.currentPage = 3
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            height: 36
                            radius: 11
                            implicitWidth: saldoRow.implicitWidth + 24
                            Layout.preferredWidth: implicitWidth
                            color: Theme.withAlpha(Theme.text, 0.03)
                            border.width: 1
                            border.color: Theme.stroke

                            Row {
                                id: saldoRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "SALDO"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.letterSpacing: 1.4
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Money {
                                    value: win.lifetime.net || 0
                                    signed: true
                                    colorBySign: true
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 12
                            color: addHover.hovered ? "#79F2C9" : Theme.mint
                            scale: addPress.pressed ? 0.94 : 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale { NumberAnimation { duration: 110 } }
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                color: "#06231A"
                                font.family: Theme.fontFamily
                                font.pixelSize: 20
                                font.weight: Font.Medium
                                anchors.verticalCenterOffset: -1
                            }
                            HoverHandler { id: addHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: addPress; onTapped: shell.openNew(backend.todayIso) }
                        }

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: avatarHover.hovered ? Theme.surface3 : Theme.surface2
                            border.width: 1
                            border.color: avatarHover.hovered ? Theme.withAlpha(Theme.mint, 0.4) : Theme.stroke
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: backend.userName.length > 0 ? backend.userName.charAt(0).toUpperCase() : "C"
                                color: Theme.mint
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                            HoverHandler { id: avatarHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: win.currentPage = 3 }
                        }
                    }
                }
            }

            // ── Pages ─────────────────────────────────────────────────────
            Item {
                id: pageHost
                anchors.top: topBar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                Item {
                    id: wrapCalendar
                    anchors.fill: parent
                    visible: win.currentPage === 0 || opacity > 0.001
                    opacity: win.currentPage === 0 ? 1 : 0
                    enabled: win.currentPage === 0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    transform: Translate { y: win.currentPage === 0 ? 0 : 10; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }

                    CalendarPage {
                        anchors.fill: parent
                        onToastRequested: function(message, danger) { toast.show(message, danger) }
                        onAddRequested: function(iso) { shell.openNew(iso) }
                    }
                }

                Item {
                    id: wrapTransactions
                    anchors.fill: parent
                    visible: win.currentPage === 1 || opacity > 0.001
                    opacity: win.currentPage === 1 ? 1 : 0
                    enabled: win.currentPage === 1
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    transform: Translate { y: win.currentPage === 1 ? 0 : 10; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }

                    TransactionsPage {
                        anchors.fill: parent
                        onToastRequested: function(message, danger) { toast.show(message, danger) }
                    }
                }

                Item {
                    id: wrapInsights
                    anchors.fill: parent
                    visible: win.currentPage === 2 || opacity > 0.001
                    opacity: win.currentPage === 2 ? 1 : 0
                    enabled: win.currentPage === 2
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    transform: Translate { y: win.currentPage === 2 ? 0 : 10; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }

                    InsightsPage {
                        anchors.fill: parent
                    }
                }

                Item {
                    id: wrapSettings
                    anchors.fill: parent
                    visible: win.currentPage === 3 || opacity > 0.001
                    opacity: win.currentPage === 3 ? 1 : 0
                    enabled: win.currentPage === 3
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    transform: Translate { y: win.currentPage === 3 ? 0 : 10; Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } } }

                    SettingsPage {
                        anchors.fill: parent
                        onToastRequested: function(message, danger) { toast.show(message, danger) }
                    }
                }
            }

            TransactionDialog {
                id: txDialog
                anchors.fill: parent
                onSaved: {
                    toast.show("Movimento salvato", false)
                    win.currentPage = 0
                }
            }

            Toast {
                id: toast
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 26
                z: 200
            }
        }
    }
}
