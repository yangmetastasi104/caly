cmake_minimum_required(VERSION 3.21)
project(Caly VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(caly
    src/main.cpp
    src/backend.h
    src/backend.cpp
)

qt_add_qml_module(caly
    URI Caly
    VERSION 1.0
    RESOURCES
        assets/caly-logo.png
    QML_FILES
        qml/Main.qml
        qml/Onboarding.qml
        qml/CalendarPage.qml
        qml/DayCell.qml
        qml/DayPanel.qml
        qml/TransactionDialog.qml
        qml/ConfirmDelete.qml
        qml/TransactionsPage.qml
        qml/InsightsPage.qml
        qml/SettingsPage.qml
        qml/Toast.qml
        qml/Money.qml
        qml/NavTab.qml
        qml/StatCard.qml
        qml/theme.js
)

target_link_libraries(caly PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

target_compile_options(caly PRIVATE
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
)

install(TARGETS caly
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

install(FILES assets/caly-512.png
    DESTINATION share/icons/hicolor/512x512/apps
    RENAME caly.png
)
install(FILES packaging/caly.desktop
    DESTINATION share/applications
)
