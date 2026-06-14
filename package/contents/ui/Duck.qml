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
    property bool upsideDown: false

    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real leg: swimmingRight ? travel : travel - 1
    readonly property int animationStep: Math.floor(wingProgress) % 16
    readonly property int frame: animationStep < 4 ? 0 : animationStep < 8 ? 1 : animationStep < 12 ? 2 : 1
    readonly property real duckWidth: Math.max(18, aquariumHeight * (compact ? 0.46 : 0.22))
    readonly property real bob: Math.sin(wingProgress * 0.35) * aquariumHeight * 0.018
    readonly property real waterlineSpriteOffset: 14 / 17
    readonly property real normalFloatingY: waterSurfaceY - height * waterlineSpriteOffset + bob
    readonly property real diveOffset: upsideDown ? height * 10 / 17 : 0
    readonly property real floatingY: normalFloatingY + diveOffset
    readonly property real leftOutX: -width
    readonly property real rightOutX: aquariumWidth
    readonly property real span: aquariumWidth + width
    readonly property real swimX: swimmingRight ? leftOutX + leg * span : rightOutX - leg * span

    function updateDiveState() {
        if (aquariumHeight <= 0) {
            return;
        }

        const posY = waterSurfaceY / aquariumHeight * 56 - 14;
        if (!upsideDown && posY < 2) {
            upsideDown = true;
        } else if (upsideDown && posY > 5) {
            upsideDown = false;
        }
    }

    source: Qt.resolvedUrl("../images/original-ducks.png")
    sourceX: frame * 18
    sourceY: 0
    sourceWidth: 18
    sourceHeight: 17
    pixelScale: duckWidth / 18
    mirrored: swimmingRight
    flipped: upsideDown
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

    Component.onCompleted: updateDiveState()
    onWaterSurfaceYChanged: updateDiveState()
    onAquariumHeightChanged: updateDiveState()
}
