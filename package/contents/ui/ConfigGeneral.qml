/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQml
import Qt.labs.folderlistmodel

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

import "../imports/org/mraus/kop/backend" as KopBackend

KCM.SimpleKCM {
    id: root

    title: i18n("Super Bubble Fishy Mon")

    property string cfg_launchUrl: cfg_launchUrlDefault
    property alias cfg_showWater: showWaterCheck.checked
    property alias cfg_showBubbles: showBubblesCheck.checked
    property alias cfg_showFish: showFishCheck.checked
    property alias cfg_showDuck: showDuckCheck.checked
    property alias cfg_showWeeds: showWeedsCheck.checked
    property string cfg_weatherCondition: "clear"
    property string cfg_weatherLocation: cfg_weatherLocationDefault
    property string cfg_weatherLocationLabel: cfg_weatherLocationLabelDefault
    property int cfg_framesPerSecond: 24
    property string cfg_networkInterface: "all"
    property string cfg_launchUrlDefault: "org.kde.plasma-systemmonitor.desktop"
    property bool cfg_showWaterDefault: true
    property bool cfg_showBubblesDefault: true
    property bool cfg_showFishDefault: true
    property bool cfg_showDuckDefault: true
    property bool cfg_showWeedsDefault: true
    property string cfg_weatherConditionDefault: "clear"
    property string cfg_weatherLocationDefault: ""
    property string cfg_weatherLocationLabelDefault: ""
    property int cfg_framesPerSecondDefault: 24
    property string cfg_networkInterfaceDefault: "all"
    property var appChoices: []
    property var locationChoices: []
    property string locationSearchStatus: ""
    property real locationLatitude: 0
    property real locationLongitude: 0
    property int locationSearchSerial: 0
    property bool initialized: false
    property var networkInterfaceChoices: [{ id: "all", name: i18n("All interfaces") }]
    property var weatherChoices: [
        { text: i18n("Clear"), value: "clear" },
        { text: i18n("Cloudy"), value: "cloudy" },
        { text: i18n("Rain"), value: "rain" },
        { text: i18n("Snow"), value: "snow" },
        { text: i18n("Fog"), value: "fog" },
        { text: i18n("Thunderstorm"), value: "thunderstorm" }
    ]

    signal configurationChanged

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

    function rebuildAppChoices() {
        appChoices = [{ id: "", name: i18n("None"), icon: "application-x-executable" }].concat(configBackend.appModel);
        syncLaunchCombo();
    }

    function syncLaunchCombo() {
        const selectedId = desktopId(cfg_launchUrl);
        for (let i = 0; i < appChoices.length; ++i) {
            if (appChoices[i].id === selectedId) {
                clickAppCombo.currentIndex = i;
                return;
            }
        }

        clickAppCombo.currentIndex = 0;
    }

    function displayInterface(iface) {
        return iface === "all" ? i18n("All interfaces") : iface;
    }

    function rebuildNetworkInterfaces() {
        const interfaces = [{ id: "all", name: i18n("All interfaces") }];
        for (let i = 0; i < networkFolderModel.count; ++i) {
            const iface = networkFolderModel.get(i, "fileName");
            if (iface && iface.length > 0) {
                interfaces.push({ id: iface, name: displayInterface(iface) });
            }
        }
        interfaces.sort((left, right) => left.id === "all" ? -1 : right.id === "all" ? 1 : left.name.localeCompare(right.name));
        networkInterfaceChoices = interfaces;
        syncNetworkCombo();
    }

    function syncNetworkCombo() {
        for (let row = 0; row < networkInterfaceChoices.length; ++row) {
            if (networkInterfaceChoices[row].id === cfg_networkInterface) {
                networkInterfaceCombo.currentIndex = row;
                return;
            }
        }
        networkInterfaceCombo.currentIndex = 0;
    }

    function syncWeatherCombo() {
        for (let row = 0; row < weatherChoices.length; ++row) {
            if (weatherChoices[row].value === cfg_weatherCondition) {
                weatherConditionCombo.currentIndex = row;
                return;
            }
        }
        weatherConditionCombo.currentIndex = 0;
    }

    function coordinatesValue(latitude, longitude) {
        return Number(latitude).toFixed(4) + "," + Number(longitude).toFixed(4);
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
            value: coordinatesValue(latitude, longitude)
        };
    }

    function setLocationPreview(latitude, longitude) {
        locationLatitude = Number.isFinite(Number(latitude)) ? Number(latitude) : 0;
        locationLongitude = Number.isFinite(Number(longitude)) ? Number(longitude) : 0;
    }

    function setLocationNotFound() {
        setLocationPreview(0, 0);
    }

    function previewLocationChoice(row) {
        if (row < 0 || row >= locationChoices.length) {
            setLocationNotFound();
            return;
        }
        const choice = locationChoices[row];
        setLocationPreview(choice.latitude, choice.longitude);
    }

    function syncLocationPreviewFromConfig() {
        const coordinates = parseCoordinates(cfg_weatherLocation);
        if (coordinates) {
            setLocationPreview(coordinates.latitude, coordinates.longitude);
            return;
        }
        setLocationNotFound();
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

    function locationChoiceText(row) {
        if (row < 0 || row >= locationChoices.length) {
            return "";
        }
        return locationChoices[row].text || "";
    }

    function compareLocationChoices(left, right) {
        if (left.exactName !== right.exactName) {
            return left.exactName ? -1 : 1;
        }
        if (left.countryCode === "DE" && right.countryCode !== "DE") {
            return -1;
        }
        if (left.countryCode !== "DE" && right.countryCode === "DE") {
            return 1;
        }
        return right.population - left.population;
    }

    function fetchJson(url, callback) {
        try {
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
                    callback(null, i18n("JSON error: %1", String(error)));
                }
            };
            xhr.onerror = function() {
                callback(null, i18n("Network error"));
            };
            xhr.open("GET", url);
            xhr.send();
        } catch (error) {
            callback(null, i18n("Request error: %1", String(error)));
        }
    }

    function searchWeatherLocations(query) {
        const trimmed = query.trim();
        locationSearchSerial += 1;
        const serial = locationSearchSerial;
        if (trimmed.length < 2) {
            locationChoices = [];
            locationSearchStatus = trimmed.length === 0 ? i18n("No location configured") : i18n("Enter at least 2 characters");
            setLocationNotFound();
            return;
        }

        const coordinates = parseCoordinates(trimmed);
        if (coordinates) {
            locationChoices = [{
                text: trimmed,
                value: coordinates.value,
                label: trimmed,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            }];
            locationSearchStatus = i18n("Coordinates recognized");
            setLocationPreview(coordinates.latitude, coordinates.longitude);
            return;
        }

        locationSearchStatus = i18n("Searching for %1...", trimmed);
        setLocationNotFound();
        const url = "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(trimmed)
            + "&count=10&language=de&format=json";
        fetchJson(url, function(payload, errorText) {
            if (serial !== locationSearchSerial) {
                return;
            }
            if (!payload || !payload.results) {
                locationChoices = [];
                locationSearchStatus = errorText.length > 0 ? i18n("Lookup failed: %1", errorText) : i18n("No matches found");
                setLocationNotFound();
                return;
            }

            const choices = [];
            const normalizedQuery = trimmed.toLocaleLowerCase();
            for (let i = 0; i < payload.results.length; ++i) {
                const place = payload.results[i];
                if (!Number.isFinite(Number(place.latitude)) || !Number.isFinite(Number(place.longitude))) {
                    continue;
                }
                const label = displayLocation(place);
                const latitude = Number(place.latitude);
                const longitude = Number(place.longitude);
                choices.push({
                    text: label,
                    value: coordinatesValue(latitude, longitude),
                    label: label,
                    latitude: latitude,
                    longitude: longitude,
                    countryCode: place.country_code || "",
                    exactName: String(place.name || "").toLocaleLowerCase() === normalizedQuery,
                    population: Number(place.population) || 0
                });
            }
            choices.sort(compareLocationChoices);
            locationChoices = choices;
            if (choices.length > 0) {
                locationCombo.currentIndex = 0;
                previewLocationChoice(0);
                locationSearchStatus = i18np("1 match found: %2", "%1 matches found: %2", choices.length, choices[0].label);
            } else {
                locationSearchStatus = i18n("No matches found");
                setLocationNotFound();
            }
        });
    }

    function syncLocationField() {
        const text = cfg_weatherLocationLabel.length > 0 ? cfg_weatherLocationLabel : cfg_weatherLocation;
        if (weatherLocationField.text !== text && !weatherLocationField.activeFocus) {
            weatherLocationField.text = text;
        }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        RowLayout {
            Kirigami.FormData.label: i18n("Click app:")
            Layout.fillWidth: true

            QQC2.ComboBox {
                id: clickAppCombo

                Layout.fillWidth: true
                model: root.appChoices
                textRole: "name"
                valueRole: "id"

                onActivated: {
                    root.cfg_launchUrl = currentValue;
                    root.configurationChanged();
                }
            }

            QQC2.Button {
                icon.name: "view-refresh-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh applications")
                onClicked: configBackend.reloadApplications()
            }
        }

        QQC2.CheckBox {
            id: showWaterCheck

            Kirigami.FormData.label: i18n("Show:")
            checked: true
            text: i18n("Water")
            onToggled: root.configurationChanged()
        }

        QQC2.CheckBox {
            id: showBubblesCheck

            checked: true
            text: i18n("Bubbles")
            onToggled: root.configurationChanged()
        }

        QQC2.CheckBox {
            id: showFishCheck

            checked: true
            text: i18n("Fish")
            onToggled: root.configurationChanged()
        }

        QQC2.CheckBox {
            id: showDuckCheck

            checked: true
            text: i18n("Duck")
            onToggled: root.configurationChanged()
        }

        QQC2.CheckBox {
            id: showWeedsCheck

            checked: true
            text: i18n("Water plants")
            onToggled: root.configurationChanged()
        }

        QQC2.ComboBox {
            id: weatherConditionCombo

            Kirigami.FormData.label: i18n("Weather fallback:")
            Layout.fillWidth: true
            model: root.weatherChoices
            textRole: "text"
            valueRole: "value"
            onActivated: {
                root.cfg_weatherCondition = currentValue;
                root.configurationChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Location:")
            Layout.fillWidth: true

            QQC2.TextField {
                id: weatherLocationField

                Layout.fillWidth: true
                placeholderText: i18n("City or latitude, longitude")
                onTextEdited: {
                    root.cfg_weatherLocation = text;
                    root.cfg_weatherLocationLabel = "";
                    root.locationChoices = [];
                    root.locationSearchStatus = text.trim().length >= 2 ? i18n("Searching for %1...", text.trim()) : "";
                    root.setLocationNotFound();
                    root.configurationChanged();
                    locationSearchTimer.restart();
                }
                onAccepted: root.searchWeatherLocations(text)
            }

            QQC2.Button {
                icon.name: "edit-find-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Search location")
                onClicked: root.searchWeatherLocations(weatherLocationField.text)
            }
        }

        QQC2.ComboBox {
            id: locationCombo

            Kirigami.FormData.label: i18n("Matches:")
            Layout.fillWidth: true
            visible: root.locationChoices.length > 0
            model: root.locationChoices.length
            displayText: root.locationChoiceText(currentIndex)

            delegate: QQC2.ItemDelegate {
                width: locationCombo.width
                text: root.locationChoiceText(index)
            }

            onCurrentIndexChanged: root.previewLocationChoice(currentIndex)

            onActivated: row => {
                const choice = root.locationChoices[row];
                if (!choice) {
                    return;
                }
                root.cfg_weatherLocation = choice.value;
                root.cfg_weatherLocationLabel = choice.label;
                weatherLocationField.text = choice.label;
                root.locationChoices = [];
                root.locationSearchStatus = i18n("Selected: %1", choice.label);
                root.setLocationPreview(choice.latitude, choice.longitude);
                root.configurationChanged();
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Coordinates:")
            Layout.fillWidth: true

            QQC2.TextField {
                Layout.fillWidth: true
                readOnly: true
                text: root.locationLatitude.toFixed(4)
            }

            QQC2.TextField {
                Layout.fillWidth: true
                readOnly: true
                text: root.locationLongitude.toFixed(4)
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Location status:")
            Layout.fillWidth: true
            visible: root.locationSearchStatus.length > 0
            text: root.locationSearchStatus
            wrapMode: Text.WordWrap
            color: Kirigami.Theme.disabledTextColor
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Frames/sec:")
            Layout.fillWidth: true

            QQC2.Slider {
                id: fpsSlider

                Layout.fillWidth: true
                from: 1
                to: 60
                stepSize: 1
                snapMode: QQC2.Slider.SnapAlways
                value: root.cfg_framesPerSecond
                onMoved: {
                    root.cfg_framesPerSecond = Math.round(value);
                    root.configurationChanged();
                }
            }

            QQC2.Label {
                text: Math.round(fpsSlider.value)
                horizontalAlignment: Text.AlignRight
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2
            }
        }

        QQC2.ComboBox {
            id: networkInterfaceCombo

            Kirigami.FormData.label: i18n("WiFish interface:")
            Layout.fillWidth: true
            model: root.networkInterfaceChoices
            textRole: "name"
            valueRole: "id"

            displayText: currentIndex >= 0
                ? root.networkInterfaceChoices[currentIndex].name
                : root.displayInterface(root.cfg_networkInterface)

            delegate: QQC2.ItemDelegate {
                width: networkInterfaceCombo.width
                text: modelData.name
            }

            onActivated: row => {
                if (row < 0 || row >= root.networkInterfaceChoices.length) {
                    return;
                }
                root.cfg_networkInterface = root.networkInterfaceChoices[row].id;
                root.configurationChanged();
            }
        }
    }

    KopBackend.ProcessSource {
        id: configBackend

        Component.onCompleted: {
            reloadApplications();
            root.rebuildAppChoices();
        }
        onAppModelChanged: root.rebuildAppChoices()
    }

    FolderListModel {
        id: networkFolderModel

        folder: "file:///sys/class/net"
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onCountChanged: root.rebuildNetworkInterfaces()
    }

    Timer {
        id: locationSearchTimer

        interval: 450
        repeat: false
        onTriggered: root.searchWeatherLocations(weatherLocationField.text)
    }

    Component.onCompleted: {
        fpsSlider.value = cfg_framesPerSecond;
        syncLocationField();
        syncLocationPreviewFromConfig();
        locationSearchStatus = weatherLocationField.text.trim().length > 0
            ? i18n("Ready to search: %1", weatherLocationField.text.trim())
            : i18n("No location configured");
        syncWeatherCombo();
        rebuildNetworkInterfaces();
        syncLaunchCombo();
        initialized = true;
        if (weatherLocationField.text.trim().length >= 2) {
            locationSearchTimer.restart();
        }
    }

    onCfg_launchUrlChanged: syncLaunchCombo()
    onCfg_weatherConditionChanged: syncWeatherCombo()
    onCfg_weatherLocationChanged: {
        syncLocationField();
        syncLocationPreviewFromConfig();
        if (initialized && weatherLocationField.text.trim().length >= 2) {
            locationSearchTimer.restart();
        }
    }
    onCfg_weatherLocationLabelChanged: syncLocationField()
    onCfg_framesPerSecondChanged: fpsSlider.value = cfg_framesPerSecond
    onCfg_networkInterfaceChanged: syncNetworkCombo()
}
