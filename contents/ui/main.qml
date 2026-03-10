/*
 * Copyright 2021  Atul Gopinathan  <leoatul12@gmail.com>
 * Copyright 2026  Anonymous Contributor
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.6
import QtQuick.Layouts 1.1
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0


Item {
    id: main
    anchors.fill: parent

    //height and width, when the widget is placed in desktop
    width: 100
    height: 40

    //height and width, when widget is placed in plasma panel
    Layout.preferredWidth: 80 * units.devicePixelRatio
    Layout.preferredHeight: 40 * units.devicePixelRatio

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    property double power: 0.0
    property double previousEnergy: 0.0
    property double lastUpdateTime: 0.0

    //Returns power usage in Watts based on energy difference
    function getPowerUsage() {
        var energyPath = "/sys/class/powercap/intel-rapl:0/energy_uj"
        var req = new XMLHttpRequest();
        req.open("GET", energyPath, false);
        req.send(null);

        if (req.responseText == "") {
            return 0.0;
        }

        var currentEnergy = parseInt(req.responseText); // in microjoules
        var currentTime = Date.now() / 1000; // in seconds

        if (main.lastUpdateTime == 0.0) {
            main.previousEnergy = currentEnergy;
            main.lastUpdateTime = currentTime;
            return 0.0;
        }

        var energyDifference = currentEnergy - main.previousEnergy; // in microjoules
        var timeDifference = currentTime - main.lastUpdateTime; // in seconds

        if (timeDifference == 0) {
            return 0.0;
        }

        // Convert: microjoules / seconds = microwatts, then divide by 1,000,000 to get watts
        var power = energyDifference / timeDifference / 1000000;

        main.previousEnergy = currentEnergy;
        main.lastUpdateTime = currentTime;

        return Math.round(power * 10) / 10;
    }

    PlasmaComponents.Label {
        id: display

        anchors {
            fill: parent
            margins: Math.round(parent.width * 0.01)
        }

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: {
            if(Number.isInteger(main.power)) {
                return(main.power + ".0 W");
            }
            else {
                return(main.power + " W");
            }
        }

        font.pixelSize: 1000;
        minimumPointSize: theme.smallestFont.pointSize
        fontSizeMode: Text.Fit
        font.bold: plasmoid.configuration.makeFontBold
    }

    Timer {
        interval: plasmoid.configuration.updateInterval * 1000
        running: true
        repeat: true
        onTriggered: {
            main.power = getPowerUsage()
            if(Number.isInteger(main.power)) {
                display.text = main.power + ".0 W";
            }
            else {
                display.text = main.power + " W";
            }
        }
    }
}

