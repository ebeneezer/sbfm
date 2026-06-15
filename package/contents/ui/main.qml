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

import "../imports/org/mraus/kop/backend" as KopBackend

PlasmoidItem {
    id: root

    readonly property real cpuLoad: percentSensorToLoad(cpuSensor.value)
    readonly property real systemLoad: sensorNumber(loadAverageSensor.value) + 4
    readonly property real memoryLoad: clamp(percentSensorToLoad(memorySensor.value) + 0.40, 0, 1)
    readonly property real swapLoad: percentSensorPercentToLoad(swapSensor.value)
    readonly property real rawNetworkLoad: clamp((downloadSensor.value + uploadSensor.value) / 10485760, 0, 1)
    property real smoothedNetworkLoad: 0
    readonly property real networkLoad: smoothedNetworkLoad
    readonly property int frameInterval: Math.round(1000 / clamp(Plasmoid.configuration.framesPerSecond || 24, 1, 60))
    readonly property string networkInterface: Plasmoid.configuration.networkInterface || "all"
    readonly property string weatherCondition: Plasmoid.configuration.weatherCondition || "clear"
    readonly property string weatherLocation: Plasmoid.configuration.weatherLocation || ""
    readonly property string weatherLocationLabel: Plasmoid.configuration.weatherLocationLabel || ""
    readonly property bool weatherLookupEnabled: weatherLocation.trim().length > 0
    readonly property bool liveWeatherActive: liveWeatherCondition.length > 0
    readonly property string effectiveWeatherCondition: liveWeatherActive ? liveWeatherCondition : weatherCondition
    readonly property real effectiveWeatherCloudCover: liveWeatherActive
        ? liveWeatherCloudCover
        : fallbackCloudCover(weatherCondition)
    readonly property real effectiveWeatherPrecipitation: liveWeatherActive
        ? liveWeatherPrecipitation
        : fallbackPrecipitation(weatherCondition)
    readonly property real effectiveWeatherSnowfall: liveWeatherActive ? liveWeatherSnowfall : fallbackSnowfall(weatherCondition)
    property string liveWeatherCondition: ""
    property string liveWeatherResolvedLocation: ""
    property string liveWeatherError: ""
    property int liveWeatherCode: -1
    property int weatherRequestSerial: 0
    property real liveWeatherCloudCover: 0
    property real liveWeatherPrecipitation: 0
    property real liveWeatherSnowfall: 0

    Plasmoid.title: i18n("Super Bubble Fishy Mon")
    Plasmoid.icon: "super-bubble-fishy-mon"
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    activationTogglesExpanded: false
    preferredRepresentation: compactRepresentation
    toolTipMainText: i18n("Super Bubble Fishy Mon")
    toolTipSubText: i18n("CPU %1%   Memory %2%   Net %3 down, %4 up%5",
                          Math.round(cpuLoad * 100),
                          Math.round(memoryLoad * 100),
                          downloadSensor.formattedValue || "0 B",
                          uploadSensor.formattedValue || "0 B",
                          liveWeatherResolvedLocation.length > 0
                              ? i18n("   Weather %1", liveWeatherResolvedLocation)
                              : "")

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

    function percentSensorPercentToLoad(value) {
        const numeric = Number(value);
        if (!Number.isFinite(numeric)) {
            return 0;
        }
        return clamp(numeric / 100, 0, 1);
    }

    function sensorNumber(value) {
        const numeric = Number(value);
        if (!Number.isFinite(numeric)) {
            return 0;
        }
        return Math.max(0, numeric);
    }

    function parseCoordinates(location) {
        const match = /^\s*(-?\d+(?:\.\d+)?)\s*[,; ]\s*(-?\d+(?:\.\d+)?)\s*$/.exec(location);
        if (!match) {
            return null;
        }

        const latitude = Number(match[1]);
        const longitude = Number(match[2]);
        if (!Number.isFinite(latitude) || !Number.isFinite(longitude)
                || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
            return null;
        }
        return {
            latitude: latitude,
            longitude: longitude,
            label: weatherLocationLabel.length > 0 ? weatherLocationLabel : latitude.toFixed(3) + ", " + longitude.toFixed(3)
        };
    }

    function conditionFromWeather(code, cloudCover, precipitation, snowfall) {
        if (code >= 95) {
            return "thunderstorm";
        }
        if ((code >= 71 && code <= 77) || code === 85 || code === 86 || snowfall > 0) {
            return "snow";
        }
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || precipitation > 0.05) {
            return "rain";
        }
        if (code === 45 || code === 48) {
            return "fog";
        }
        if ((code >= 1 && code <= 3) || cloudCover >= 55) {
            return "cloudy";
        }
        return "clear";
    }

    function fallbackCloudCover(condition) {
        if (condition === "thunderstorm" || condition === "rain" || condition === "snow") {
            return 0.92;
        }
        if (condition === "fog") {
            return 0.70;
        }
        if (condition === "cloudy") {
            return 0.78;
        }
        return 0;
    }

    function fallbackPrecipitation(condition) {
        if (condition === "thunderstorm") {
            return 1.4;
        }
        if (condition === "rain") {
            return 0.55;
        }
        return 0;
    }

    function fallbackSnowfall(condition) {
        return condition === "snow" ? 0.45 : 0;
    }

    function displayLocation(place) {
        const parts = [place.name];
        if (place.admin1 && place.admin1 !== place.name) {
            parts.push(place.admin1);
        }
        if (place.country) {
            parts.push(place.country);
        } else if (place.country_code) {
            parts.push(place.country_code);
        }
        return parts.join(", ");
    }

    function fetchJson(url, callback) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== 4) {
                return;
            }

            if (xhr.status < 200 || xhr.status >= 300) {
                callback(null, i18n("HTTP %1", xhr.status));
                return;
            }

            try {
                callback(JSON.parse(xhr.responseText), "");
            } catch (error) {
                callback(null, String(error));
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function resetLiveWeather(errorText) {
        liveWeatherCondition = "";
        liveWeatherResolvedLocation = "";
        liveWeatherError = errorText || "";
        liveWeatherCode = -1;
        liveWeatherCloudCover = 0;
        liveWeatherPrecipitation = 0;
        liveWeatherSnowfall = 0;
    }

    function fetchWeatherFor(latitude, longitude, label, serial) {
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + encodeURIComponent(latitude)
            + "&longitude=" + encodeURIComponent(longitude)
            + "&current=weather_code,cloud_cover,precipitation,rain,showers,snowfall,is_day"
            + "&timezone=auto";
        fetchJson(url, function(payload, errorText) {
            if (serial !== weatherRequestSerial) {
                return;
            }
            if (!payload || !payload.current) {
                resetLiveWeather(errorText || i18n("No weather data"));
                return;
            }

            const current = payload.current;
            const code = Number(current.weather_code);
            const cloudCover = clamp(Number(current.cloud_cover) / 100, 0, 1);
            const precipitation = Math.max(0, Number(current.precipitation) || 0,
                                           Number(current.rain) || 0,
                                           Number(current.showers) || 0);
            const snowfall = Math.max(0, Number(current.snowfall) || 0);
            liveWeatherCode = Number.isFinite(code) ? code : -1;
            liveWeatherCloudCover = cloudCover;
            liveWeatherPrecipitation = precipitation;
            liveWeatherSnowfall = snowfall;
            liveWeatherCondition = conditionFromWeather(liveWeatherCode, cloudCover * 100, precipitation, snowfall);
            liveWeatherResolvedLocation = label;
            liveWeatherError = "";
        });
    }

    function refreshWeather() {
        const location = weatherLocation.trim();
        weatherRequestSerial += 1;
        const serial = weatherRequestSerial;
        if (location.length === 0) {
            resetLiveWeather("");
            return;
        }

        const coordinates = parseCoordinates(location);
        if (coordinates) {
            fetchWeatherFor(coordinates.latitude, coordinates.longitude, coordinates.label, serial);
            return;
        }

        const url = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(location)
            + "&count=10&language=de&format=json";
        fetchJson(url, function(payload, errorText) {
            if (serial !== weatherRequestSerial) {
                return;
            }
            if (!payload || !payload.results || payload.results.length < 1) {
                resetLiveWeather(errorText || i18n("Location not found"));
                return;
            }

            const place = payload.results[0];
            fetchWeatherFor(place.latitude, place.longitude, displayLocation(place), serial);
        });
    }
    function enabledByDefault(value) {
        return value !== false;
    }

    function desktopId(launcher) {
        if (!launcher) {
            return "";
        }
        if (launcher.startsWith("applications://")) {
            return launcher.substring("applications://".length);
        }
        if (launcher.startsWith("applications:")) {
            return launcher.substring("applications:".length);
        }
        return launcher;
    }

    KopBackend.ProcessSource {
        id: launchBackend

        showOnClick: root.desktopId(Plasmoid.configuration.launchUrl || "org.kde.plasma-systemmonitor.desktop")

        Component.onCompleted: reloadApplications()
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

    Timer {
        id: weatherRefreshTimer

        interval: 900000
        repeat: true
        running: root.weatherLookupEnabled
        triggeredOnStart: true
        onTriggered: root.refreshWeather()
    }

    onWeatherLocationChanged: root.refreshWeather()

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
                systemLoad: root.systemLoad
                memoryLoad: root.memoryLoad
                swapLoad: root.swapLoad
                networkLoad: root.networkLoad
                downloadText: downloadSensor.formattedValue || i18n("idle")
                uploadText: uploadSensor.formattedValue || i18n("idle")
                showWater: root.enabledByDefault(Plasmoid.configuration.showWater)
                showBubbles: root.enabledByDefault(Plasmoid.configuration.showBubbles)
                showFish: root.enabledByDefault(Plasmoid.configuration.showFish)
                showDuck: root.enabledByDefault(Plasmoid.configuration.showDuck)
                showWeeds: root.enabledByDefault(Plasmoid.configuration.showWeeds)
                weatherCondition: root.effectiveWeatherCondition
                weatherCloudCover: root.effectiveWeatherCloudCover
                weatherPrecipitation: root.effectiveWeatherPrecipitation
                weatherSnowfall: root.effectiveWeatherSnowfall
                frameInterval: root.frameInterval
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: launchBackend.toggleConfiguredApplication()
            }
        }
    }

    Sensors.Sensor {
        id: cpuSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: 1000
    }

    Sensors.Sensor {
        id: loadAverageSensor
        sensorId: "cpu/loadaverages/loadaverage1"
        updateRateLimit: 1500
    }

    Sensors.Sensor {
        id: memorySensor
        sensorId: "memory/physical/usedPercent"
        updateRateLimit: 1500
    }

    Sensors.Sensor {
        id: swapSensor
        sensorId: "memory/swap/usedPercent"
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
