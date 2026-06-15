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

    readonly property real pumpkinSize: Math.max(16, aquariumHeight * (compact ? 0.464 : 0.28))
    readonly property real bob: Math.sin(phase * 0.82) * pumpkinSize * 0.032
    readonly property real sway: Math.sin(phase * 0.53) * pumpkinSize * 0.060
    readonly property real rockAngle: Math.sin(phase * 0.50) * 3.0
    readonly property real travel: swimProgress
    readonly property bool swimmingRight: travel < 1
    readonly property real swimLeg: swimmingRight ? travel : travel - 1
    readonly property real leftOutX: -width - pumpkinSize * 0.12
    readonly property real rightOutX: aquariumWidth + pumpkinSize * 0.12
    readonly property real span: rightOutX - leftOutX
    readonly property real swimX: swimmingRight ? leftOutX + swimLeg * span : rightOutX - swimLeg * span
    readonly property int frame: Math.floor(phase * 0.285) % 4
    readonly property real waterlineRatio: 0.52
    readonly property real waterlineInItem: Math.max(0, Math.min(height, waterSurfaceY - y))
    readonly property var normalFrames: [
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-1.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-2.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-3.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-4.png")
    ]
    readonly property var underwaterFrames: [
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-1-underwater.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-2-underwater.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-3-underwater.png"),
        Qt.resolvedUrl("../images/drowning-halloween-pumpkin-4-underwater.png")
    ]

    width: pumpkinSize
    height: pumpkinSize
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
            mirror: root.swimmingRight
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
            mirror: root.swimmingRight
            smooth: true
            mipmap: true
            cache: true
        }
    }
}
