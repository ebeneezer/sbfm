/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

OriginalSprite {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property real waterSurfaceY: 0
    property int seed: 0
    property real load: 0
    property real phase: 0

    readonly property real speedVariance: [0.58, 0.72, 0.86, 1.0, 0.64, 0.78, 0.92][seed % 7]
    readonly property real speed: (0.18 + load * 0.58 + ((seed * 13) % 11) / 70) * 0.112 * speedVariance
    readonly property real cyclePosition: phase * speed + seed * 0.173
    readonly property int cycle: Math.floor(cyclePosition)
    readonly property real cycleTravel: cyclePosition - cycle
    readonly property real activeSpan: Math.max(0.12, Math.min(0.86, 0.14 + load * 0.66))
    readonly property bool active: cycleTravel < activeSpan
    readonly property real travel: active ? cycleTravel / activeSpan : 1
    readonly property real lane: ((seed * 37 + cycle * 53) % 100) / 100
    readonly property int frame: Math.max(0, Math.min(4, Math.floor(travel * 5)))
    readonly property real waterDepth: Math.max(1, aquariumHeight - waterSurfaceY)
    readonly property real visualScale: 0.81
    readonly property real growthScale: 1 - travel * 0.37
    readonly property real ringSize: Math.max(3, (Math.max(width, height) + 1 + travel * 1.89) * visualScale)
    readonly property real sway: Math.sin(phase * 1.2 + seed + cycle * 0.67) * aquariumWidth * (0.012 + travel * 0.018)
    readonly property var sprite: [
        [33, 196, 1, 1],
        [27, 202, 2, 2],
        [27, 196, 3, 3],
        [19, 204, 5, 3],
        [19, 196, 5, 5]
    ][frame]

    source: Qt.resolvedUrl("../images/original-sprites.png")
    sourceX: sprite[0]
    sourceY: sprite[1]
    sourceWidth: sprite[2]
    sourceHeight: sprite[3]
    pixelScale: Math.max(1, aquariumHeight / 38) * (0.75 + travel * 0.70 + load * 0.45) * growthScale * visualScale
    x: Math.max(0, Math.min(aquariumWidth - width, aquariumWidth * (0.08 + lane * 0.82) + sway))
    y: waterSurfaceY + waterDepth * (0.92 - travel * 0.90)
    z: 4
    visible: active
    opacity: 0.58 + load * 0.34

    Rectangle {
        anchors.centerIn: parent
        width: root.ringSize
        height: width
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, root.pixelScale * 0.28)
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.66)
    }
}
