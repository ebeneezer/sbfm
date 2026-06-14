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
    property var currentTime: new Date()

    readonly property real loadPulse: 0.5 + cpuLoad * 1.6 + networkLoad * 1.2
    readonly property color waterTop: Qt.rgba(0.05, 0.22 + cpuLoad * 0.12, 0.32 + networkLoad * 0.12, 0.92)
    readonly property color waterBottom: Qt.rgba(0.02, 0.42 + networkLoad * 0.16, 0.50 + cpuLoad * 0.10, 0.96)
    readonly property int localHour: currentTime.getHours()
    readonly property bool daytime: localHour >= 6 && localHour < 20
    readonly property int maxBubbleCount: compact ? 7 : 18
    readonly property int bubbleCount: cpuLoad < 0.02 ? 0 : Math.max(1, Math.min(maxBubbleCount, Math.ceil(cpuLoad * maxBubbleCount)))
    readonly property int fishCount: compact ? 2 : 6
    readonly property real boundedMemoryLoad: clamp(memoryLoad, 0, 1)
    readonly property real waterFraction: boundedMemoryLoad
    readonly property real waterDepth: height * waterFraction
    readonly property real waterSurfaceY: height * (1 - waterFraction)
    readonly property int waterColumnCount: compact ? 18 : 56
    readonly property real waterWaveLimit: Math.max(1, height * (compact ? 0.055 : 0.035))
    property var waterLevels: []
    property var waterVelocities: []

    function clamp(value, low, high) {
        return Math.max(low, Math.min(high, value))
    }

    function ensureWaterPhysics() {
        if (waterLevels.length === waterColumnCount && waterVelocities.length === waterColumnCount) {
            return;
        }

        const levels = [];
        const velocities = [];
        for (let i = 0; i < waterColumnCount; ++i) {
            levels.push(waterSurfaceY);
            velocities.push(0);
        }
        waterLevels = levels;
        waterVelocities = velocities;
    }

    function updateWaterPhysics() {
        ensureWaterPhysics();

        const target = waterSurfaceY;
        const levels = waterLevels.slice();
        const velocities = waterVelocities.slice();
        const last = waterColumnCount - 1;
        const speedLimit = Math.max(0.35, height * 0.030);

        levels[0] = target;
        levels[last] = target;
        velocities[0] = 0;
        velocities[last] = 0;

        for (let i = 1; i < last; ++i) {
            const curvature = levels[i - 1] + levels[i + 1] - 2 * levels[i];
            const restore = target - levels[i];
            velocities[i] = clamp((velocities[i] + curvature * 0.18 + restore * 0.026) * 0.88,
                                  -speedLimit, speedLimit);
        }

        for (let j = 1; j < last; ++j) {
            levels[j] = clamp(levels[j] + velocities[j], target - waterWaveLimit, target + waterWaveLimit);
        }

        if (showBubbles && bubbleCount > 0 && swimClock.tick % Math.max(3, Math.round(18 - cpuLoad * 14)) === 0) {
            const column = 1 + ((swimClock.tick * 7) % Math.max(1, waterColumnCount - 2));
            levels[column] = clamp(levels[column] - waterWaveLimit * (0.45 + cpuLoad), target - waterWaveLimit, target + waterWaveLimit);
        }

        waterLevels = levels;
        waterVelocities = velocities;
        water.requestPaint();
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
        color: Qt.rgba(0.05, 0.06, 0.08, 0.94)
        border.width: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))
        border.color: Qt.rgba(0.72, 0.96, 1.0, 0.55)
    }

    Rectangle {
        id: sky

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.waterSurfaceY
        radius: tankBase.radius
        visible: height > 0
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: root.daytime ? Qt.rgba(0.35, 0.78, 1.0, 0.96) : Qt.rgba(0.04, 0.03, 0.16, 0.96)
            }
            GradientStop {
                position: 1.0
                color: root.daytime ? Qt.rgba(0.74, 0.92, 1.0, 0.94) : Qt.rgba(0.12, 0.06, 0.28, 0.96)
            }
        }

        Rectangle {
            id: sun

            readonly property real bodySize: Math.max(4, Math.min(parent.width, root.height) * 0.20)

            x: parent.width * 0.14
            y: Math.max(1, parent.height * 0.18)
            width: bodySize
            height: bodySize
            radius: width / 2
            visible: root.daytime && parent.height > height * 0.8
            color: Qt.rgba(1.0, 0.86, 0.18, 0.95)
            border.width: Math.max(1, Math.round(Kirigami.Units.devicePixelRatio))
            border.color: Qt.rgba(1.0, 1.0, 0.76, 0.78)
        }

        Item {
            id: moon

            readonly property real bodySize: Math.max(4, Math.min(parent.width, root.height) * 0.19)

            x: parent.width * 0.16
            y: Math.max(1, parent.height * 0.16)
            width: bodySize
            height: bodySize
            visible: !root.daytime && parent.height > height * 0.8

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(0.86, 0.91, 1.0, 0.90)
            }

            Rectangle {
                width: parent.width
                height: parent.height
                x: parent.width * 0.34
                y: -parent.height * 0.06
                radius: width / 2
                color: Qt.rgba(0.04, 0.03, 0.16, 0.98)
            }
        }
    }

    Canvas {
        id: water

        anchors.fill: parent
        visible: root.showWater && root.waterFraction > 0

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (!visible || width <= 0 || height <= 0) {
                return;
            }

            root.ensureWaterPhysics();
            const levels = root.waterLevels.length === root.waterColumnCount ? root.waterLevels : [];
            const gradient = ctx.createLinearGradient(0, root.waterSurfaceY - root.waterWaveLimit, 0, height);
            gradient.addColorStop(0.0, root.waterTop);
            gradient.addColorStop(0.72, root.waterBottom);
            gradient.addColorStop(1.0, Qt.rgba(0.08, 0.12, 0.10, 0.96));

            ctx.beginPath();
            ctx.moveTo(0, levels.length > 0 ? levels[0] : root.waterSurfaceY);
            for (let i = 1; i < root.waterColumnCount; ++i) {
                const x = width * i / (root.waterColumnCount - 1);
                const y = levels.length > i ? levels[i] : root.waterSurfaceY;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(width, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fillStyle = gradient;
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(0, levels.length > 0 ? levels[0] : root.waterSurfaceY);
            for (let j = 1; j < root.waterColumnCount; ++j) {
                const sx = width * j / (root.waterColumnCount - 1);
                const sy = levels.length > j ? levels[j] : root.waterSurfaceY;
                ctx.lineTo(sx, sy);
            }
            ctx.lineWidth = Math.max(1, height * 0.018);
            ctx.strokeStyle = Qt.rgba(0.78, 0.98, 1.0, 0.70);
            ctx.stroke();
        }

        Component.onCompleted: {
            root.ensureWaterPhysics();
            requestPaint();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Repeater {
        model: root.compact ? 2 : 5

        Rectangle {
            readonly property real band: index / Math.max(1, root.compact ? 2 : 5)

            x: -width * 0.2 + Math.sin(swimClock.phase * 0.35 + index) * width * 0.08
            y: root.waterSurfaceY + root.waterDepth * (0.12 + band * 0.14)
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
        z: 5
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
        onTriggered: {
            tick += 1 + Math.round(root.loadPulse);
            root.updateWaterPhysics();
        }
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentTime = new Date()
    }

    Rectangle {
        anchors.fill: parent
        z: 10
        radius: tankBase.radius
        color: "transparent"
        border.width: tankBase.border.width
        border.color: tankBase.border.color
    }
}
