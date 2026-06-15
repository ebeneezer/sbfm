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
    property bool wanted: true
    property bool present: wanted
    property var appearanceSerialProvider: null
    property int appearanceSerial: 0
    property real swimProgress: (seed * 0.137) % 1

    readonly property bool leftToRight: seed % 2 === 0
    readonly property real swim: swimProgress
    readonly property real swimSpeed: 0.018 + load * 0.10 + seed * 0.002
    readonly property int frame: [0, 2, 4, 2][Math.floor(phase * (1.2 + load * 2.8) + seed) % 4]
    readonly property int spriteIndex: (leftToRight ? 1 : 0) + frame
    readonly property real scaleBase: Math.max(0.60, aquariumHeight / (compact ? 48 : 86))
    readonly property real sizeVariance: [0.62, 0.76, 0.92, 1.08, 0.68, 0.84][seed % 6]
    readonly property real waterDepth: Math.max(1, aquariumHeight - waterSurfaceY)
    readonly property real swimY: waterSurfaceY + waterDepth * (0.18 + ((seed * 29) % 58) / 100) + Math.sin(phase * 0.65 + seed) * waterDepth * 0.035
    readonly property bool offscreen: swimProgress < 0.02 || swimProgress > 0.98
    readonly property bool skeletonFish: appearanceSerial > 0 && appearanceSerial % 50 === 0

    source: Qt.resolvedUrl(skeletonFish ? "../images/skeleton-fish-sprites.png" : "../images/original-sprites.png")
    sourceX: leftToRight ? 18 : 0
    sourceY: Math.floor(spriteIndex / 2) * 15
    sourceWidth: 17
    sourceHeight: 14
    pixelScale: scaleBase * sizeVariance
    x: leftToRight ? -width + swim * (aquariumWidth + width * 2)
                   : aquariumWidth + width - swim * (aquariumWidth + width * 2)
    y: Math.max(waterSurfaceY, Math.min(aquariumHeight - height, swimY))
    visible: present
    opacity: 0.74 + load * 0.24

    function assignAppearanceSerial() {
        if (appearanceSerialProvider) {
            appearanceSerial = appearanceSerialProvider();
        }
    }

    onWantedChanged: {
        if (wanted && !present) {
            swimProgress = 0;
            assignAppearanceSerial();
            present = true;
        }
    }

    Component.onCompleted: {
        present = wanted;
        if (present) {
            assignAppearanceSerial();
        }
    }

    Timer {
        interval: 80
        repeat: true
        running: root.present
        onTriggered: {
            root.swimProgress = (root.swimProgress + root.swimSpeed * interval / 1000) % 1;
            if (!root.wanted && root.offscreen) {
                root.present = false;
            }
        }
    }
}
