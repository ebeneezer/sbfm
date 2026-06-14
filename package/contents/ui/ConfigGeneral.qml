/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtCore
import Qt.labs.folderlistmodel

import org.kde.kcmutils as KCM
import org.kde.kitemmodels as KItemModels
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

KCM.SimpleKCM {
    id: root

    title: i18n("Super Bubble Fishy Mon")

    property string cfg_launchUrl: cfg_launchUrlDefault
    property alias cfg_showWater: showWaterCheck.checked
    property alias cfg_showBubbles: showBubblesCheck.checked
    property alias cfg_showFish: showFishCheck.checked
    property alias cfg_showDuck: showDuckCheck.checked
    property alias cfg_showWeeds: showWeedsCheck.checked
    property int cfg_framesPerSecond: 24
    property string cfg_networkInterface: "all"
    property string cfg_launchUrlDefault: "applications:org.kde.plasma-systemmonitor.desktop"
    property bool cfg_showWaterDefault: true
    property bool cfg_showBubblesDefault: true
    property bool cfg_showFishDefault: true
    property bool cfg_showDuckDefault: true
    property bool cfg_showWeedsDefault: true
    property int cfg_framesPerSecondDefault: 24
    property string cfg_networkInterfaceDefault: "all"
    property var appChoices: []

    signal configurationChanged

    function pathToUrl(path) {
        if (!path || path.length === 0) {
            return "";
        }
        return path.indexOf("file://") === 0 ? path : "file://" + path;
    }

    function unescapeDesktopValue(value) {
        return value.replace(/\\s/g, " ").replace(/\\n/g, "\n").replace(/\\t/g, "\t").replace(/\\\\/g, "\\");
    }

    function desktopValues(content) {
        const values = {};
        const lines = content.split(/\r?\n/);
        let inDesktopEntry = false;

        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i].trim();
            if (line.length === 0 || line[0] === "#") {
                continue;
            }
            if (line[0] === "[" && line[line.length - 1] === "]") {
                inDesktopEntry = line === "[Desktop Entry]";
                continue;
            }
            if (!inDesktopEntry) {
                continue;
            }

            const separator = line.indexOf("=");
            if (separator <= 0) {
                continue;
            }
            values[line.slice(0, separator)] = unescapeDesktopValue(line.slice(separator + 1));
        }

        return values;
    }

    function localizedValue(values, key) {
        const locale = Qt.locale().name;
        const shortLocale = locale.split("_")[0];
        return values[key + "[" + locale + "]"] || values[key + "[" + shortLocale + "]"] || values[key] || "";
    }

    function boolValue(values, key) {
        return (values[key] || "").toLowerCase() === "true";
    }

    function readDesktopFile(url) {
        const request = new XMLHttpRequest();
        request.open("GET", url, false);
        request.send();
        return request.status === 0 || request.status === 200 ? request.responseText : "";
    }

    function entryFromModel(model, row) {
        const fileName = model.get(row, "fileName");
        const fileUrl = model.get(row, "fileUrl") || model.get(row, "fileURL") || pathToUrl(model.get(row, "filePath"));
        const values = desktopValues(readDesktopFile(fileUrl));
        const name = localizedValue(values, "Name");

        if (values.Type !== "Application" || name.length === 0 || !values.Exec
                || boolValue(values, "Hidden") || boolValue(values, "NoDisplay") || boolValue(values, "Terminal")) {
            return null;
        }

        return {
            id: fileName,
            name: name,
            icon: values.Icon || "application-x-executable",
            value: "applications:" + fileName
        };
    }

    function appendAppsFromModel(result, model) {
        for (let row = 0; row < model.count; ++row) {
            const entry = entryFromModel(model, row);
            if (entry !== null) {
                result[entry.id] = entry;
            }
        }
    }

    function rebuildAppChoices() {
        const appsById = {};
        appendAppsFromModel(appsById, systemApplicationsModel);
        appendAppsFromModel(appsById, userApplicationsModel);

        const apps = Object.keys(appsById).map(id => appsById[id]);
        apps.sort((left, right) => left.name.localeCompare(right.name));

        appChoices = [{ id: "__custom__", name: i18n("Custom URL"), icon: "document-edit", value: "__custom__" }].concat(apps);
        syncLaunchCombo();
    }

    function syncLaunchCombo() {
        for (let row = 0; row < appChoices.length; ++row) {
            if (appChoices[row].value === cfg_launchUrl) {
                launchCombo.currentIndex = row;
                return;
            }
        }

        launchCombo.currentIndex = 0;
        launchUrlField.text = cfg_launchUrl || cfg_launchUrlDefault;
    }

    function interfaceFromSensorId(sensorId) {
        const match = /^network\/(.+)\/download$/.exec(sensorId);
        return match ? match[1] : "";
    }

    function displayInterface(iface) {
        return iface === "all" ? i18n("All interfaces") : iface;
    }

    function syncNetworkCombo() {
        for (let row = 0; row < networkSensorsModel.count; ++row) {
            const sensorId = networkSensorsModel.data(networkSensorsModel.index(row, 0), Sensors.SensorTreeModel.SensorId);
            if (interfaceFromSensorId(sensorId) === cfg_networkInterface) {
                networkInterfaceCombo.currentIndex = row;
                return;
            }
        }
        networkInterfaceCombo.currentIndex = -1;
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        RowLayout {
            Kirigami.FormData.label: i18n("Click opens:")
            Layout.fillWidth: true

            QQC2.ComboBox {
                id: launchCombo

                Layout.fillWidth: true
                model: root.appChoices
                textRole: "name"
                valueRole: "value"
                onActivated: {
                    if (currentValue !== "__custom__") {
                        root.cfg_launchUrl = currentValue;
                        root.configurationChanged();
                    } else {
                        launchUrlField.forceActiveFocus();
                    }
                }
            }

            QQC2.Button {
                icon.name: "view-refresh-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh applications")
                onClicked: root.rebuildAppChoices()
            }
        }

        QQC2.TextField {
            id: launchUrlField

            Kirigami.FormData.label: i18n("Custom URL:")
            Layout.fillWidth: true
            visible: launchCombo.currentIndex <= 0
            placeholderText: root.cfg_launchUrlDefault
            onTextEdited: {
                root.cfg_launchUrl = text;
                root.configurationChanged();
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
            model: networkSensorsModel
            textRole: "SensorId"

            displayText: currentIndex >= 0
                ? root.displayInterface(root.interfaceFromSensorId(networkSensorsModel.data(networkSensorsModel.index(currentIndex, 0), Sensors.SensorTreeModel.SensorId)))
                : root.displayInterface(root.cfg_networkInterface)

            delegate: QQC2.ItemDelegate {
                width: networkInterfaceCombo.width
                text: root.displayInterface(root.interfaceFromSensorId(model.SensorId))
            }

            onActivated: row => {
                const sensorId = networkSensorsModel.data(networkSensorsModel.index(row, 0), Sensors.SensorTreeModel.SensorId);
                const iface = root.interfaceFromSensorId(sensorId);
                if (iface.length > 0) {
                    root.cfg_networkInterface = iface;
                    root.configurationChanged();
                }
            }
        }
    }

    Sensors.SensorTreeModel {
        id: sensorTreeModel
    }

    FolderListModel {
        id: systemApplicationsModel

        folder: "file:///usr/share/applications"
        nameFilters: ["*.desktop"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.rebuildAppChoices()
    }

    FolderListModel {
        id: userApplicationsModel

        folder: root.pathToUrl(StandardPaths.writableLocation(StandardPaths.ApplicationsLocation))
        nameFilters: ["*.desktop"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.rebuildAppChoices()
    }

    KItemModels.KSortFilterProxyModel {
        id: networkSensorsModel

        sourceModel: KItemModels.KDescendantsProxyModel {
            model: sensorTreeModel
        }
        sortRoleName: "SensorId"
        sortOrder: Qt.AscendingOrder
        filterRowCallback: function(row, parent) {
            const sensorId = sourceModel.data(sourceModel.index(row, 0, parent), Sensors.SensorTreeModel.SensorId);
            return /^network\/.+\/download$/.test(sensorId);
        }

        onCountChanged: root.syncNetworkCombo()
    }

    Component.onCompleted: {
        fpsSlider.value = cfg_framesPerSecond;
        launchUrlField.text = cfg_launchUrl || cfg_launchUrlDefault;
        rebuildAppChoices();
        syncNetworkCombo();
    }

    onCfg_launchUrlChanged: syncLaunchCombo()
    onCfg_framesPerSecondChanged: fpsSlider.value = cfg_framesPerSecond
    onCfg_networkInterfaceChanged: syncNetworkCombo()
}
