/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property int seed: 0
    property real load: 0
    property real phase: 0

    readonly property real lane: ((seed * 37) % 100) / 100
    readonly property real speed: 0.18 + load * 0.58 + ((seed * 13) % 11) / 70
    readonly property real travel: (phase * speed + seed * 0.173) % 1
    readonly property real sizeBase: Math.max(3, aquariumHeight * (0.045 + ((seed * 7) % 6) / 280))

    width: sizeBase * (0.7 + load * 0.8)
    height: width
    x: aquariumWidth * (0.08 + lane * 0.82) + Math.sin(phase * 0.9 + seed) * aquariumWidth * 0.018
    y: aquariumHeight * (0.92 - travel * 0.98)
    opacity: 0.30 + load * 0.50

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, width * 0.12)
        border.color: Qt.rgba(0.88, 1.0, 1.0, 0.72)
    }

    Rectangle {
        width: parent.width * 0.24
        height: width
        radius: width / 2
        x: parent.width * 0.25
        y: parent.height * 0.18
        color: Qt.rgba(1.0, 1.0, 1.0, 0.72)
    }
}
