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
    property bool compact: false

    readonly property bool leftToRight: seed % 2 === 0
    readonly property real swim: (phase * (0.045 + load * 0.22 + seed * 0.004) + seed * 0.137) % 1
    readonly property int frame: [0, 2, 4, 2][Math.floor(phase * (1.2 + load * 2.8) + seed) % 4]
    readonly property int spriteIndex: (leftToRight ? 1 : 0) + frame
    readonly property real scaleBase: Math.max(0.60, aquariumHeight / (compact ? 48 : 86))
    readonly property real waterDepth: Math.max(1, aquariumHeight - waterSurfaceY)
    readonly property real swimY: waterSurfaceY + waterDepth * (0.18 + ((seed * 29) % 58) / 100) + Math.sin(phase * 0.65 + seed) * waterDepth * 0.035

    source: Qt.resolvedUrl("../images/original-sprites.png")
    sourceX: leftToRight ? 18 : 0
    sourceY: Math.floor(spriteIndex / 2) * 15
    sourceWidth: 17
    sourceHeight: 14
    pixelScale: scaleBase * (0.78 + (seed % 3) * 0.08)
    x: leftToRight ? -width + swim * (aquariumWidth + width * 2)
                   : aquariumWidth + width - swim * (aquariumWidth + width * 2)
    y: Math.max(waterSurfaceY, Math.min(aquariumHeight - height, swimY))
    opacity: 0.74 + load * 0.24
}
