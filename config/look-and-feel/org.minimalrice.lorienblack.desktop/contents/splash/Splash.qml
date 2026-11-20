/*
    Lorien Black splash: the login wallpaper blurred under a near-black veil (as on the SDDM card), a big thin clock
    and a hairline progress bar in the light grey accent. Plasma raises `stage` from 1 to 6 while the session starts.
*/
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#0b0b0b"

    property int stage

    onStageChanged: {
        if (stage == 2) {
            fadeIn.running = true;
        } else if (stage == 6) {
            fadeOut.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: wallpaper
            anchors.fill: parent
            source: "images/background.jpg"
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: -0.4
        }
        Rectangle {               // veil: same near-black as the windows
            anchors.fill: parent
            color: "#0e0e0e"
            opacity: 0.78
        }

        Column {
            anchors.centerIn: parent
            spacing: Kirigami.Units.gridUnit

            Text {
                id: clock
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#e8e8e8"
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.ExtraLight
                font.pixelSize: Kirigami.Units.gridUnit * 6
                text: Qt.formatTime(new Date(), "HH:mm")
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clock.text = Qt.formatTime(new Date(), "HH:mm")
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#8a8a8a"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: Kirigami.Units.gridUnit
                font.letterSpacing: 2
                text: Qt.formatDate(new Date(), "dddd, d MMMM").toLowerCase()
            }

            Item { width: 1; height: Kirigami.Units.gridUnit }

            Rectangle {           // hairline progress: one step per startup stage
                anchors.horizontalCenter: parent.horizontalCenter
                width: Kirigami.Units.gridUnit * 14
                height: 2
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.08)
                Rectangle {
                    height: parent.height
                    radius: 1
                    color: "#dcdcdc"
                    width: parent.width * Math.min(root.stage, 6) / 6
                    Behavior on width {
                        NumberAnimation { duration: Kirigami.Units.longDuration * 2; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    OpacityAnimator {
        id: fadeIn
        target: content
        from: 0; to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
    OpacityAnimator {
        id: fadeOut
        target: content
        from: 1; to: 0
        duration: Kirigami.Units.longDuration
        easing.type: Easing.InOutQuad
    }
}
