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
    property bool leftToRight: true
    property real swimProgress: (seed * 0.137) % 1
    property bool preyVisible: true
    property bool predatorActive: false
    property bool predatorReturning: false
    property bool predatorLeftToRight: leftToRight
    property real predatorProgress: 0

    readonly property real swim: swimProgress
    readonly property real swimSpeed: 0.104 + load * 0.72 + seed * 0.008
    readonly property real predatorSpeed: swimSpeed * 1.5
    readonly property real predatorStartGap: 0.32
    readonly property real predatorCatchGap: 0.035
    readonly property int frame: [0, 2, 4, 2][Math.floor(phase * (4.8 + load * 11.2) + seed) % 4]
    readonly property var predatorFrameOrder: [4, 3, 2, 1, 2, 3]
    readonly property int predatorFrameIndex: Math.floor(phase * (0.972 + load * 2.268) + seed) % predatorFrameOrder.length
    readonly property int predatorFrameFile: predatorFrameOrder[predatorFrameIndex]
    readonly property int spriteIndex: (leftToRight ? 1 : 0) + frame
    readonly property real scaleBase: Math.max(0.60, aquariumHeight / (compact ? 48 : 86))
    readonly property real sizeVariance: [0.62, 0.76, 0.92, 1.08, 0.68, 0.84][seed % 6]
    readonly property real predatorSize: Math.max(width, height) * 1.65
    readonly property real waterDepth: Math.max(1, aquariumHeight - waterSurfaceY)
    readonly property real swimY: waterSurfaceY + waterDepth * (0.18 + ((seed * 29) % 58) / 100) + Math.sin(phase * 0.65 + seed) * waterDepth * 0.035
    source: Qt.resolvedUrl("../images/original-sprites.png")
    sourceX: leftToRight ? 18 : 0
    sourceY: Math.floor(spriteIndex / 2) * 15
    sourceWidth: 17
    sourceHeight: 14
    pixelScale: scaleBase * sizeVariance
    x: leftToRight ? -width + swim * (aquariumWidth + width * 2)
                   : aquariumWidth + width - swim * (aquariumWidth + width * 2)
    y: Math.max(waterSurfaceY, Math.min(aquariumHeight - height, swimY))
    visible: present
    spriteVisible: preyVisible
    opacity: 0.74 + load * 0.24

    Image {
        id: predatorFish

        readonly property real predatorWorldX: root.worldXForProgress(root.predatorProgress, root.predatorLeftToRight)

        x: predatorWorldX - root.x
        y: (root.height - height) / 2
        width: root.predatorSize
        height: root.predatorSize
        source: Qt.resolvedUrl("../images/predator-skeleton-fish-" + root.predatorFrameFile + ".png")
        fillMode: Image.PreserveAspectFit
        mirror: !root.predatorLeftToRight
        smooth: false
        antialiasing: false
        visible: root.predatorActive && root.present
        opacity: 0.96
        z: 2
    }

    function worldXForProgress(progress, direction) {
        if (direction) {
            return -width + progress * (aquariumWidth + width * 2);
        }
        return aquariumWidth + width - progress * (aquariumWidth + width * 2);
    }

    function progressForWorldX(worldX, direction) {
        const travelWidth = aquariumWidth + width * 2;
        const progress = direction
            ? (worldX + width) / travelWidth
            : (aquariumWidth + width - worldX) / travelWidth;
        return Math.max(0, Math.min(1, progress));
    }

    function assignInitialDirection() {
        leftToRight = Math.floor(Date.now() / 1000) % 2 === 0;
    }

    function startPredator() {
        predatorProgress = Math.max(0, swimProgress - predatorStartGap);
        predatorLeftToRight = leftToRight;
        predatorReturning = false;
        predatorActive = true;
    }

    function startPredatorReturn(catchProgress) {
        const catchWorldX = worldXForProgress(catchProgress, leftToRight);
        predatorLeftToRight = !leftToRight;
        predatorProgress = progressForWorldX(catchWorldX, predatorLeftToRight);
        predatorReturning = true;
        preyVisible = false;
    }

    onWantedChanged: {
        if (wanted && !present) {
            swimProgress = 0;
            assignInitialDirection();
            preyVisible = true;
            predatorActive = false;
            predatorReturning = false;
            present = true;
        } else if (wanted) {
            preyVisible = true;
            predatorActive = false;
            predatorReturning = false;
        } else if (present && !predatorActive) {
            startPredator();
        }
    }

    Component.onCompleted: {
        present = wanted;
        preyVisible = true;
        predatorActive = false;
        predatorReturning = false;
        if (present) {
            assignInitialDirection();
        }
    }

    Timer {
        interval: 80
        repeat: true
        running: root.present
        onTriggered: {
            const nextProgress = root.swimProgress + root.swimSpeed * interval / 1000;
            if (root.predatorActive) {
                const predatorStepSpeed = root.predatorReturning ? root.swimSpeed : root.predatorSpeed;
                root.predatorProgress = Math.min(1, root.predatorProgress + predatorStepSpeed * interval / 1000);

                if (root.predatorReturning) {
                    if (root.predatorProgress >= 1) {
                        root.present = false;
                        root.predatorActive = false;
                        root.predatorReturning = false;
                        root.preyVisible = true;
                    }
                    return;
                }

                if (root.predatorProgress + root.predatorCatchGap >= nextProgress) {
                    root.swimProgress = Math.min(1, nextProgress);
                    root.startPredatorReturn(root.swimProgress);
                    return;
                }
            }

            if (!root.preyVisible) {
                if (!root.predatorActive) {
                    root.present = false;
                }
                return;
            }

            if (nextProgress >= 1) {
                if (!root.wanted) {
                    root.swimProgress = 1;
                    if (root.predatorActive) {
                        root.startPredatorReturn(root.swimProgress);
                    } else {
                        root.present = false;
                        root.predatorActive = false;
                        root.predatorReturning = false;
                        root.preyVisible = true;
                    }
                    return;
                }
                root.swimProgress = 0;
                root.assignInitialDirection();
                root.predatorActive = false;
                root.predatorReturning = false;
                root.preyVisible = true;
                return;
            }

            root.swimProgress = nextProgress;
        }
    }
}
