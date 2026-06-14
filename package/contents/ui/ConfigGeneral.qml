/*
    SPDX-FileCopyrightText: 2026 Dr. Michael Raus <dr.michael.raus@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kitemmodels as KItemModels
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
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

    signal configurationChanged

    function syncLaunchCombo() {
        for (let row = 0; row < appFilterModel.count; ++row) {
            const launcher = appFilterModel.data(appFilterModel.index(row, 0), "favoriteId");
            if (launcher === cfg_launchUrl) {
                clickAppCombo.currentIndex = row;
                return;
            }
        }

        clickAppCombo.currentIndex = -1;
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
            Kirigami.FormData.label: i18n("Click app:")
            Layout.fillWidth: true

            QQC2.ComboBox {
                id: clickAppCombo

                Layout.fillWidth: true
                model: appFilterModel
                textRole: "display"
                valueRole: "favoriteId"
                displayText: currentIndex >= 0
                    ? appFilterModel.data(appFilterModel.index(currentIndex, 0), "display")
                    : i18n("Select application")

                delegate: QQC2.ItemDelegate {
                    width: clickAppCombo.width
                    text: model.display
                    icon.name: model.decoration || "application-x-executable"
                }

                onActivated: row => {
                    const launcher = appFilterModel.data(appFilterModel.index(row, 0), "favoriteId");
                    if (launcher) {
                        root.cfg_launchUrl = launcher;
                        root.configurationChanged();
                    }
                }
            }

            QQC2.Button {
                icon.name: "view-refresh-symbolic"
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Refresh applications")
                onClicked: appModel.refresh()
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

    Kicker.AppsModel {
        id: appModel

        autoPopulate: true
        flat: true
        sorted: true
        showSeparators: false
        onCountChanged: root.syncLaunchCombo()
    }

    KItemModels.KSortFilterProxyModel {
        id: appFilterModel

        sourceModel: appModel
        sortRoleName: "display"
        sortOrder: Qt.AscendingOrder
        filterRowCallback: function(row, parent) {
            const launcher = sourceModel.data(sourceModel.index(row, 0, parent), "favoriteId");
            return launcher && launcher.length > 0;
        }

        onCountChanged: root.syncLaunchCombo()
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
        syncNetworkCombo();
        appModel.refresh();
        syncLaunchCombo();
    }

    onCfg_launchUrlChanged: syncLaunchCombo()
    onCfg_framesPerSecondChanged: fpsSlider.value = cfg_framesPerSecond
    onCfg_networkInterfaceChanged: syncNetworkCombo()
}
