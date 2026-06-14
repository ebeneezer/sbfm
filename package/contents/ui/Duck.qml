/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property real load: 0
    property real phase: 0
    property bool compact: false

    readonly property real duckWidth: Math.max(16, aquariumHeight * (compact ? 0.42 : 0.20))
    readonly property real bob: Math.sin(phase * 0.75) * aquariumHeight * 0.018

    width: duckWidth
    height: duckWidth * 0.70
    x: Math.max(0, Math.min(aquariumWidth - width, aquariumWidth * (0.58 + load * 0.22) + Math.sin(phase * 0.22) * aquariumWidth * 0.05))
    y: aquariumHeight * 0.08 + bob

    Rectangle {
        id: body
        x: parent.width * 0.10
        y: parent.height * 0.33
        width: parent.width * 0.72
        height: parent.height * 0.46
        radius: height / 2
        color: "#ffd84d"
        border.width: Math.max(1, parent.width * 0.02)
        border.color: "#e3a72d"
    }

    Rectangle {
        id: head
        x: parent.width * 0.52
        y: parent.height * 0.10
        width: parent.width * 0.34
        height: width
        radius: width / 2
        color: "#ffe178"
        border.width: Math.max(1, parent.width * 0.018)
        border.color: "#e3a72d"
    }

    Rectangle {
        x: parent.width * 0.79
        y: parent.height * 0.27
        width: parent.width * 0.25
        height: parent.height * 0.12
        radius: height / 2
        color: "#ff8c2e"
    }

    Rectangle {
        x: parent.width * 0.72
        y: parent.height * 0.20
        width: parent.width * 0.055
        height: width
        radius: width / 2
        color: "#111820"
    }

    Rectangle {
        x: parent.width * 0.22
        y: parent.height * 0.48
        width: parent.width * (0.16 + load * 0.18)
        height: parent.height * 0.08
        radius: height / 2
        color: Qt.rgba(0.9, 0.65, 0.15, 0.55)
    }
}
