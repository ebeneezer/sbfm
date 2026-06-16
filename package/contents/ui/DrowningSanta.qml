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

    readonly property real santaSize: Math.max(16, aquariumHeight * (compact ? 0.56 : 0.34))
    readonly property real bob: Math.sin(phase * 0.9) * santaSize * 0.035
    readonly property real sway: Math.sin(phase * 0.58) * santaSize * 0.065
    readonly property real rockAngle: Math.sin(phase * 0.52) * 3.2
    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real swimLeg: swimmingRight ? travel : travel - 1
    readonly property real leftOutX: -width - santaSize * 0.12
    readonly property real rightOutX: aquariumWidth + santaSize * 0.12
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: swimmingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property int frame: Math.floor(phase * 0.705) % 4
    readonly property real waterlineRatio: 0.46
    readonly property real waterlineInItem: Math.max(0, Math.min(height, waterSurfaceY - y))
    readonly property var normalFrames: [
        Qt.resolvedUrl("../images/drowning-santa-1.png"),
        Qt.resolvedUrl("../images/drowning-santa-2.png"),
        Qt.resolvedUrl("../images/drowning-santa-3.png"),
        Qt.resolvedUrl("../images/drowning-santa-4.png")
    ]
    readonly property var underwaterFrames: [
        Qt.resolvedUrl("../images/drowning-santa-1-underwater.png"),
        Qt.resolvedUrl("../images/drowning-santa-2-underwater.png"),
        Qt.resolvedUrl("../images/drowning-santa-3-underwater.png"),
        Qt.resolvedUrl("../images/drowning-santa-4-underwater.png")
    ]

    width: santaSize
    height: santaSize
    x: swimX + sway
    y: waterSurfaceY - height * waterlineRatio + bob
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
            source: root.normalFrames[root.frame]
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
            source: root.underwaterFrames[root.frame]
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            cache: true
        }
    }
}
