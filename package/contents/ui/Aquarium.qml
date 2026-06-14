/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

Item {
    id: root

    property bool compact: false
    property real cpuLoad: 0
    property real memoryLoad: 0
    property real networkLoad: 0
    property string downloadText: ""
    property string uploadText: ""
    property bool showWater: true
    property bool showBubbles: true
    property bool showFish: true
    property bool showDuck: true
    property bool showWeeds: true
    property int frameInterval: 42

    readonly property real loadPulse: 0.5 + cpuLoad * 1.6 + networkLoad * 1.2
    readonly property color waterTop: Qt.rgba(0.05, 0.22 + cpuLoad * 0.12, 0.32 + networkLoad * 0.12, 0.92)
    readonly property color waterBottom: Qt.rgba(0.02, 0.42 + networkLoad * 0.16, 0.50 + cpuLoad * 0.10, 0.96)
    readonly property int bubbleCount: compact ? 7 : 18
    readonly property int fishCount: compact ? 2 : 6
    readonly property real boundedMemoryLoad: clamp(memoryLoad, 0, 1)
    readonly property real waterFraction: clamp(0.10 + boundedMemoryLoad * 0.86, 0.10, 0.96)
    readonly property real waterSurfaceY: height * (1 - waterFraction)

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value))
    }

    Layout.minimumWidth: compact ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 16
    Layout.minimumHeight: compact ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 10
    Layout.preferredWidth: compact ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 22
    Layout.preferredHeight: compact ? Kirigami.Units.iconSizes.medium : Kirigami.Units.gridUnit * 13

    implicitWidth: Layout.preferredWidth
    implicitHeight: Layout.preferredHeight
    clip: true

    Rectangle {
        id: tankBase
        anchors.fill: parent
        radius: Math.max(2, Math.min(width, height) * 0.18)
        color: Qt.rgba(0.02, 0.08, 0.10, 0.92)
        border.width: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))
        border.color: Qt.rgba(0.72, 0.96, 1.0, 0.55)
    }

    Rectangle {
        id: water
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.height * root.waterFraction
        visible: root.showWater
        radius: tankBase.radius
        border.width: tankBase.border.width
        border.color: tankBase.border.color
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.waterTop }
            GradientStop { position: 0.72; color: root.waterBottom }
            GradientStop { position: 1.0; color: Qt.rgba(0.08, 0.12, 0.10, 0.96) }
        }
    }

    Repeater {
        model: root.compact ? 2 : 5

        Rectangle {
            readonly property real band: index / Math.max(1, root.compact ? 2 : 5)

            x: -width * 0.2 + Math.sin(swimClock.phase * 0.35 + index) * width * 0.08
            y: root.waterSurfaceY + water.height * (0.12 + band * 0.14)
            width: root.width * 1.4
            height: Math.max(1, root.height * 0.018)
            radius: height / 2
            color: Qt.rgba(0.85, 1.0, 1.0, 0.06 + root.cpuLoad * 0.06)
            visible: root.showWater
        }
    }

    Repeater {
        model: root.showBubbles ? root.bubbleCount : 0

        Bubble {
            aquariumWidth: root.width
            aquariumHeight: root.height
            waterSurfaceY: root.waterSurfaceY
            seed: index
            load: root.cpuLoad
            phase: swimClock.phase
        }
    }

    Repeater {
        model: root.showFish ? root.fishCount : 0

        Fish {
            aquariumWidth: root.width
            aquariumHeight: root.height
            waterSurfaceY: root.waterSurfaceY
            seed: index
            load: root.networkLoad
            phase: swimClock.phase
            compact: root.compact
        }
    }

    Duck {
        id: duck
        aquariumWidth: root.width
        aquariumHeight: root.height
        waterSurfaceY: root.waterSurfaceY
        load: root.memoryLoad
        phase: swimClock.phase
        compact: root.compact
        visible: root.showDuck
    }

    Item {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: Math.max(2, root.height * (0.08 + root.memoryLoad * 0.08))
        visible: root.showWeeds

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height
            color: Qt.rgba(0.13, 0.20, 0.13, 0.75)
        }

        Repeater {
            model: 8

            OriginalSprite {
                readonly property int frame: Math.floor(swimClock.phase * 0.45 + index) % 8
                readonly property var sprite: [
                    [0, 120],
                    [18, 120],
                    [0, 135],
                    [18, 135],
                    [0, 150],
                    [18, 135],
                    [0, 135],
                    [18, 120]
                ][frame]

                source: Qt.resolvedUrl("../images/original-sprites.png")
                sourceX: sprite[0]
                sourceY: sprite[1]
                sourceWidth: 17
                sourceHeight: 12
                pixelScale: Math.max(1, root.height / 48)
                x: parent.width * ((index + 0.3) / 8)
                y: parent.height - height
                transform: Rotation {
                    origin.x: width / 2
                    origin.y: height
                    angle: Math.sin(swimClock.phase * 0.7 + index) * 9
                }
            }
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing
        visible: !root.compact

        MetricPill {
            label: i18n("CPU")
            value: Math.round(root.cpuLoad * 100) + "%"
            accent: "#8bd6ff"
        }

        MetricPill {
            label: i18n("MEM")
            value: Math.round(root.memoryLoad * 100) + "%"
            accent: "#ffd56f"
        }

        MetricPill {
            label: i18n("NET")
            value: root.downloadText + " / " + root.uploadText
            accent: "#7dff9a"
            Layout.fillWidth: true
        }
    }

    Timer {
        id: swimClock
        readonly property real phase: tick / 10
        property int tick: 0
        interval: Math.max(16, root.frameInterval)
        repeat: true
        running: true
        onTriggered: tick += 1 + Math.round(root.loadPulse)
    }
}
