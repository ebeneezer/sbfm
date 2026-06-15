/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick

Item {
    id: root

    property real aquariumWidth: 1
    property real aquariumHeight: 1
    property real waterSurfaceY: 0
    property real phase: 0
    property bool compact: false
    property real swimProgress: 0
    property bool swimAnimationRunning: true

    readonly property real bunnySize: Math.max(16, aquariumHeight * (compact ? 0.58 : 0.35))
    readonly property real bob: Math.sin(phase * 0.76) * bunnySize * 0.030
    readonly property real sway: Math.sin(phase * 0.50) * bunnySize * 0.055
    readonly property real rockAngle: Math.sin(phase * 0.45) * 2.7
    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real swimLeg: swimmingRight ? travel : travel - 1
    readonly property real leftOutX: -width - bunnySize * 0.12
    readonly property real rightOutX: aquariumWidth + bunnySize * 0.12
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: swimmingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property int frame: Math.floor(phase * 0.95) % 4
    readonly property real waterlineRatio: 0.58
    readonly property real waterlineInItem: Math.max(0, Math.min(height, waterSurfaceY - y))
    readonly property var rightFrames: [
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-1.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-2.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-3.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-4.png")
    ]
    readonly property var leftFrames: [
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-1.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-2.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-3.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-4.png")
    ]
    readonly property var rightUnderwaterFrames: [
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-1-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-2-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-3-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-right-4-underwater.png")
    ]
    readonly property var leftUnderwaterFrames: [
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-1-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-2-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-3-underwater.png"),
        Qt.resolvedUrl("../images/drowning-easter-bunny-left-4-underwater.png")
    ]
    readonly property var activeFrames: swimmingRight ? leftFrames : rightFrames
    readonly property var activeUnderwaterFrames: swimmingRight ? leftUnderwaterFrames : rightUnderwaterFrames

    width: bunnySize
    height: bunnySize
    x: swimX + sway
    y: Math.max(0, Math.min(aquariumHeight - height, waterSurfaceY - height * waterlineRatio + bob))
    opacity: 0.96

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height * root.waterlineRatio
        angle: root.rockAngle
    }

    NumberAnimation on swimProgress {
        from: 0
        to: 2
        duration: 90000
        loops: Animation.Infinite
        running: root.swimAnimationRunning
    }

    Item {
        id: aboveWaterClip

        x: 0
        y: 0
        width: root.width
        height: root.waterlineInItem
        clip: true

        Image {
            width: root.width
            height: root.height
            source: root.activeFrames[root.frame]
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: true
        }
    }

    Item {
        id: underwaterClip

        x: 0
        y: root.waterlineInItem
        width: root.width
        height: root.height - y
        clip: true

        Image {
            y: -underwaterClip.y
            width: root.width
            height: root.height
            source: root.activeUnderwaterFrames[root.frame]
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: true
        }
    }
}
