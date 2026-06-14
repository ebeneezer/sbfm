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
    property real load: 0
    property real phase: 0
    property bool compact: false
    property real swimProgress: 0
    property real wingProgress: 0

    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real leg: swimmingRight ? travel : travel - 1
    readonly property int animationStep: Math.floor(wingProgress) % 16
    readonly property int frame: animationStep < 4 ? 0 : animationStep < 8 ? 1 : animationStep < 12 ? 2 : 1
    readonly property real duckWidth: Math.max(18, aquariumHeight * (compact ? 0.46 : 0.22))
    readonly property real bob: Math.sin(wingProgress * 0.35) * aquariumHeight * 0.018
    readonly property real waterlineSpriteOffset: 14 / 17
    readonly property real floatingY: waterSurfaceY - height * waterlineSpriteOffset + bob
    readonly property real leftOutX: -width
    readonly property real rightOutX: aquariumWidth
    readonly property real span: aquariumWidth + width
    readonly property real swimX: swimmingRight ? leftOutX + leg * span : rightOutX - leg * span

    source: Qt.resolvedUrl("../images/original-ducks.png")
    sourceX: frame * 18
    sourceY: 0
    sourceWidth: 18
    sourceHeight: 17
    pixelScale: duckWidth / 18
    mirrored: swimmingRight
    x: swimX
    y: Math.max(0, Math.min(aquariumHeight - height, floatingY))

    NumberAnimation on swimProgress {
        from: 0
        to: 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }

    NumberAnimation on wingProgress {
        from: 0
        to: 16
        duration: 2400
        loops: Animation.Infinite
        running: true
    }
}
