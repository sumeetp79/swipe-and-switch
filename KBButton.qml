import QtQuick 2.0
import QtMultimedia 5.0

Rectangle {
    id: kbButton
    property double size: 100
    property double centerX: origWidth / 2
    property double centerY: origHeight / 2
    property double radiusRatio: 1 / 8
    x: centerX - width / 2
    y: centerY - height / 2
    width: origWidth
    height: origHeight
    property double origWidth: size
    property double origHeight: size
    property double sensitiveWidth: size
    property double sensitiveHeight: size
    property double sensDecayTime: 500 // milliseconds
    property double dwellTime: 600 // milliseconds
    property double selectionTime: 100 // milliseconds
    property double timeoutTime: 50    // milliseconds
    property bool rotated: false
    property bool clickingEnabled: false
    property bool active: visible
    property bool enabled: true
    property double dwellRef: 0
    property double timeOutRef: 0
    property bool mouseWasIn: false
    property string text: "a"
    // 0 1 2
    // 3 4 5
    // 6 7 8
    property var gridText: ["","","","","","","","",""]
    property double fontSize: size / 4
    property bool isSelected: false
    property color unselectedColor: "white"
    property color selectedColor: "light gray"
    property color disabledColor: "light gray"
    property color borderColor: "black"
    property double visibPercent: 1
    property color visibleColor: !enabled ? disabledColor : isSelected ? selectedColor : unselectedColor
    property double fontScale: label.scale
    color: "transparent";

    onOrigWidthChanged: width = origWidth;
    onOrigHeightChanged: height = origHeight;

    signal click(var button, double timestamp)
    signal mouseOut(var button)
    signal selected(var button)

    onActiveChanged: resetTimeRefs()

    SoundEffect {
        id: clickSound
        source: "resources/ClickSound.wav"
    }

    onClick: {
        isSelected = false;
        expManager.logKeyClicked(objectName)
        clickSound.play();
    }

    onMouseOut: {
        if (isSelected) expManager.logKeyOut(objectName);
        isSelected = false;
        resetSensitiveReg();
        resetTimeRefs();
        dwellAnimation.stop();
        innerRect.reset();
    }

    onSelected: {
        if (!isSelected) expManager.logKeySelected(objectName)
        isSelected = true;
    }

    Rectangle {
        id: outerRect
        anchors.centerIn: parent;
        width: parent.width * visibPercent;
        height: parent.height * visibPercent;
        color: "transparent"
        border.color: borderColor
        radius: height * radiusRatio
        rotation: rotated ? 45 : 0

        Rectangle {
            id: innerRect
            anchors.centerIn: outerRect
            property double origWidth: outerRect.width - 2;
            property double origHeight: outerRect.height - 2;
            width: origWidth
            height: origHeight
            color: visibleColor
            radius: height * radiusRatio

            function reset() {
                width = origWidth;
                height = origHeight;
            }
        }

        Grid {
            id: grid
            columns: 3
            anchors.centerIn: outerRect
            property double scale: 0.8
            width: outerRect.width * scale
            height: outerRect.height * scale

            Repeater {
                model: 9
                Text {
                    width: grid.width/3
                    height: grid.height/3
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    rotation: -outerRect.rotation
                    text: gridText[index]
                    font.pixelSize: height
                }
            }
        }
    }

    Text {
        id: label
        text: kbButton.text;
        font.pixelSize: kbButton.fontSize;
        anchors.centerIn: outerRect;
        scale: paintedWidth > outerRect.width * 0.8 ? (outerRect.width * 0.8 / paintedWidth) : 1
        color: kbButton.enabled ? "black" : "gray"
    }

    MouseArea {
        anchors.fill: parent
        onPressed: isSelected = true;
        onReleased: isSelected = false;
    }

    function show() {
        visible = true;
    }

    function textPos(txt) {
        var center = Qt.point(centerX, centerY);
        for (var i = 0; i < gridText.length; i++) {
            if (gridText[i].indexOf(txt) > -1) {
                var pos = Qt.point(x + (i%3+0.5)*width/3, y + (Math.floor(i/3)+0.5)*height/3);
                if (rotated) {
                    pos.x -= center.x;
                    pos.y -= center.y;
                    var sqrt22 = Math.sqrt(2)/2;
                    pos = Qt.point(pos.x*sqrt22-pos.y*sqrt22+center.x, pos.x*sqrt22+pos.y*sqrt22+center.y);
                }
                return pos
            }
        }
        return center;
    }

    function containsPoint(point) {
        var x0 = centerX - sensitiveWidth / 2;
        var x1 = centerX + sensitiveWidth / 2;
        var y0 = centerY - sensitiveHeight / 2;
        var y1 = centerY + sensitiveHeight / 2;
        return x0 <= point.x && point.x < x1 &&
               y0 <= point.y && point.y < y1
    }

    function visuallyContainsPoint(point) {
        var x0 = centerX - origWidth / 2;
        var x1 = centerX + origWidth / 2;
        var y0 = centerY - origHeight / 2;
        var y1 = centerY + origHeight / 2;
        return x0 <= point.x && point.x < x1 &&
               y0 <= point.y && point.y < y1
    }

    function resetSensitiveReg() {
        updateSensitiveReg(sensDecayTime);
    }

    function updateSensitiveReg(dt) {
        var incrRatio = 1;
        if (dt <= sensDecayTime) incrRatio = 1 + (1 - dt / sensDecayTime) * 0.5;
        sensitiveWidth = incrRatio * origWidth;
        sensitiveHeight = incrRatio * origHeight;
        if (false) {
            width = sensitiveWidth;
            height = sensitiveHeight;
        }
    }

    function onNewSample(sample, tstamp) {
        if (!active || !enabled) {
            dwellRef = tstamp;
            return;
        }
        if (containsPoint(sample)) {
            timeOutRef = tstamp;
            mouseWasIn = true;
        }

        if (tstamp - timeOutRef >= timeoutTime) {
            dwellRef = tstamp;
            if (mouseWasIn) {
                mouseWasIn = false;
                if (clickingEnabled) mouseOut(kbButton);
            }
        }
        else if (clickingEnabled && tstamp - dwellRef >= dwellTime) {
            click(kbButton, dwellRef);
            innerRect.reset();
            dwellRef = tstamp;
        }
        else if (tstamp - dwellRef >= selectionTime && (!clickingEnabled || !isSelected)) {
            selected(kbButton);
            if (clickingEnabled) {
                if (!dwellAnimation.running) dwellAnimation.start();
            }
            else dwellRef = tstamp;
        }
    }

    Timer {
        id: dwellAnimation
        repeat: true
        interval: 30
        onTriggered: {
            var sizeDecay = (dwellTime - (expManager.getTimestamp() - dwellRef)) / dwellTime;
            innerRect.width = sizeDecay * innerRect.origWidth;
            innerRect.height = sizeDecay * innerRect.origHeight;
            if (innerRect.width <= 0 || innerRect.height <= 0) {
                innerRect.width = 0;
                innerRect.height = 0;
                stop();
            }
        }
    }

    function resetTimeRefs() {
        mouseWasIn = false;
        timeOutRef = 0;
    }
}
