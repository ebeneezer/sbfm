/*
    SPDX-FileCopyrightText: 2026 Dr. Raus
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    readonly property real cpuLoad: percentSensorToLoad(cpuSensor.value)
    readonly property real memoryLoad: percentSensorToLoad(memorySensor.value)
    readonly property real rawNetworkLoad: clamp((downloadSensor.value + uploadSensor.value) / 10485760, 0, 1)
    property real smoothedNetworkLoad: 0
    readonly property real networkLoad: smoothedNetworkLoad
    readonly property int frameInterval: Math.round(1000 / clamp(Plasmoid.configuration.framesPerSecond || 24, 1, 60))
    readonly property string networkInterface: Plasmoid.configuration.networkInterface || "all"
    readonly property string weatherCondition: Plasmoid.configuration.weatherCondition || "clear"
    readonly property string weatherLocation: Plasmoid.configuration.weatherLocation || ""

    Plasmoid.title: i18n("Super Bubble Fishy Mon")
    Plasmoid.icon: "super-bubble-fishy-mon"
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Super Bubble Fishy Mon")
    toolTipSubText: i18n("CPU %1%   Memory %2%   Net %3 down, %4 up",
                          Math.round(cpuLoad * 100),
                          Math.round(memoryLoad * 100),
                          downloadSensor.formattedValue || "0 B",
                          uploadSensor.formattedValue || "0 B")

    function clamp(value, low, high) {
        if (!Number.isFinite(value)) {
            return low;
        }
        return Math.max(low, Math.min(high, value));
    }

    function percentSensorToLoad(value) {
        const numeric = Number(value);
        if (!Number.isFinite(numeric)) {
            return 0;
        }
        return clamp(numeric <= 1 ? numeric : numeric / 100, 0, 1);
    }

    function enabledByDefault(value) {
        return value !== false;
    }

    Timer {
        interval: 250
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            const target = root.rawNetworkLoad;
            const maxRise = 0.06;
            const maxFall = 0.025;
            const delta = target - root.smoothedNetworkLoad;
            root.smoothedNetworkLoad = clamp(root.smoothedNetworkLoad
                                             + clamp(delta, -maxFall, maxRise) * 0.55,
                                             0, 1);
        }
    }

    compactRepresentation: panelRepresentation
    fullRepresentation: panelRepresentation

    Component {
        id: panelRepresentation

        Item {
            id: panelSquare

            readonly property bool horizontalPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            readonly property bool verticalPanel: Plasmoid.formFactor === PlasmaCore.Types.Vertical
            readonly property int fallbackSize: Kirigami.Units.iconSizes.medium
            readonly property int horizontalSize: Math.max(fallbackSize, height)
            readonly property int verticalSize: Math.max(fallbackSize, width)
            readonly property int squareSize: horizontalPanel ? horizontalSize : verticalPanel ? verticalSize : fallbackSize

            Layout.fillWidth: verticalPanel
            Layout.fillHeight: horizontalPanel

            Layout.minimumWidth: horizontalPanel ? horizontalSize : fallbackSize
            Layout.preferredWidth: horizontalPanel ? horizontalSize : verticalPanel ? fallbackSize : fallbackSize
            Layout.maximumWidth: horizontalPanel ? horizontalSize : Infinity

            Layout.minimumHeight: verticalPanel ? verticalSize : fallbackSize
            Layout.preferredHeight: verticalPanel ? verticalSize : horizontalPanel ? fallbackSize : fallbackSize
            Layout.maximumHeight: verticalPanel ? verticalSize : Infinity

            implicitWidth: squareSize
            implicitHeight: squareSize
            clip: true

            Aquarium {
                id: aquarium
                anchors.centerIn: parent
                width: Math.max(1, Math.min(parent.width || panelSquare.squareSize, parent.height || panelSquare.squareSize))
                height: width
                compact: true
                cpuLoad: root.cpuLoad
                memoryLoad: root.memoryLoad
                networkLoad: root.networkLoad
                downloadText: downloadSensor.formattedValue || i18n("idle")
                uploadText: uploadSensor.formattedValue || i18n("idle")
                showWater: root.enabledByDefault(Plasmoid.configuration.showWater)
                showBubbles: root.enabledByDefault(Plasmoid.configuration.showBubbles)
                showFish: root.enabledByDefault(Plasmoid.configuration.showFish)
                showDuck: root.enabledByDefault(Plasmoid.configuration.showDuck)
                showWeeds: root.enabledByDefault(Plasmoid.configuration.showWeeds)
                weatherCondition: root.weatherCondition
                frameInterval: root.frameInterval
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Qt.openUrlExternally(Plasmoid.configuration.launchUrl || "applications:org.kde.plasma-systemmonitor.desktop")
            }
        }
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: 1000
    }

    Sensors.Sensor {
        id: memorySensor
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: 1500
    }

    Sensors.Sensor {
        id: downloadSensor
        sensorId: "network/" + root.networkInterface + "/download"
        updateRateLimit: 1000
    }

    Sensors.Sensor {
        id: uploadSensor
        sensorId: "network/" + root.networkInterface + "/upload"
        updateRateLimit: 1000
    }
}
