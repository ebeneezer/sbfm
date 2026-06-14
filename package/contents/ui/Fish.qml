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
    property bool compact: false

    readonly property bool leftToRight: seed % 2 === 0
    readonly property real swim: (phase * (0.055 + load * 0.20 + seed * 0.004) + seed * 0.137) % 1
    readonly property real fishLength: Math.max(12, aquariumHeight * (compact ? 0.34 : 0.18) * (0.82 + (seed % 3) * 0.16))
    readonly property color bodyColor: [
        "#ffb04f",
        "#66d9ef",
        "#ff6f91",
        "#a9ef6b",
        "#ffd166",
        "#c792ea"
    ][seed % 6]

    width: fishLength
    height: fishLength * 0.48
    x: leftToRight ? -width + swim * (aquariumWidth + width * 2)
                   : aquariumWidth + width - swim * (aquariumWidth + width * 2)
    y: aquariumHeight * (0.20 + ((seed * 29) % 58) / 100) + Math.sin(phase * 0.65 + seed) * aquariumHeight * 0.035
    transformOrigin: Item.Center
    scale: leftToRight ? 1 : -1
    opacity: 0.74 + load * 0.24

    Rectangle {
        id: tail
        width: parent.width * 0.34
        height: parent.height * 0.70
        x: 0
        y: parent.height * 0.15
        radius: width * 0.16
        color: Qt.darker(root.bodyColor, 1.18)
        transform: [
            Rotation {
                origin.x: tail.width
                origin.y: tail.height / 2
                angle: Math.sin(root.phase * (1.7 + root.load) + root.seed) * (16 + root.load * 16)
            },
            Scale {
                origin.x: tail.width
                origin.y: tail.height / 2
                xScale: 0.70
                yScale: 1.10
            }
        ]
    }

    Rectangle {
        id: body
        x: parent.width * 0.22
        y: parent.height * 0.08
        width: parent.width * 0.68
        height: parent.height * 0.84
        radius: height / 2
        color: root.bodyColor
    }

    Rectangle {
        width: parent.width * 0.09
        height: width
        radius: width / 2
        x: parent.width * 0.74
        y: parent.height * 0.24
        color: "#111820"
    }

    Rectangle {
        width: parent.width * 0.20
        height: Math.max(1, parent.height * 0.08)
        x: parent.width * 0.58
        y: parent.height * 0.65
        radius: height / 2
        color: Qt.rgba(0.1, 0.1, 0.12, 0.35)
    }
}
