import QtQuick 2.0

Item {
    id: menu
    property var mainButtons: []
    property var currentButton: null
    property double dwellReference: 0
    property double timeoutReference: 0
    property double inMenuButNoButtonTime: 800 // milliseconds
    property double timeoutTime: 300 // milliseconds
    property double enterTimestamp: 0
    property double curTstamp: 0
    property double t0: new Date().valueOf()
    property bool active: false
    property var lastFocusedButton: null
    property var buttons: []
    property bool buttonsVisible: buttons.some(function(button, idx, arr) { return button.visible; })
    property bool showArrows: false
    property double menuTransparency: 0.2
    z: 98

    signal displayed()

    onActiveChanged: {
        if (active) {
            timer.restart();
        }
        else {
            hide();
            timer.stop();
        }
    }

    Repeater {
        model: buttons
        Arrow {
            id: arrow
            fromX: menu.currentButton ? menu.currentButton.centerX : 0
            fromY: menu.currentButton ? menu.currentButton.centerY : 0
            toX: modelData.centerX
            toY: modelData.centerY
            offsetBefore: menu.currentButton ? menu.currentButton.size / 2 : 0
            offsetAfter: modelData.size / 2
            visible: modelData.visible && showArrows
            inverted: modelData.isSelected
            z: 80
        }
    }

    Timer {
        id: timer
        interval: 30
        repeat: true
        onTriggered: {
            var dt = new Date().valueOf() - t0;
            buttons.forEach(function (button) {
                button.updateSensitiveReg(dt);
            });
            if (currentButton) currentButton.updateSensitiveReg(dt);
        }
    }

    Repeater {
        model: mainButtons
        Item {
            Connections {
                target: modelData
                onSelected: {
                    if (!active) {
                        if (buttonsVisible) hide();
                        return;
                    }

                    if (buttonsVisible) {
                        if (lastFocusedButton && !lastFocusedButton.clickingEnabled) {
                            lastFocusedButton.click(currentButton, enterTimestamp);
                            hide();
                        }
                    }
                    else {
                        resetT0();
                        enterTimestamp = curTstamp
                        currentButton = button;
                        show();
                    }
                }
            }
        }
    }
    Repeater {
        model: buttons
        Item {
            Connections {
                target: modelData
                onSelected: {
                    if (buttonsVisible) {
                        if (currentButton) currentButton.isSecondSelect = true;
                        lastFocusedButton = button;
                        buttons.forEach(function (button) {
                            if (button !== lastFocusedButton) {
                                button.mouseOut(button);
                            }
                        });
                    }
                }
                onClick: {
                    if (buttonsVisible) {
                        hide();
                    }
                }
            }
        }
    }

    function resetT0() {
        t0 = new Date().valueOf();
    }

    function show() {
        displayed();
        menu.opacity = menuTransparency;
        buttons.forEach(function (button, idx, arr) {
            button.refX = currentButton.centerX;
            button.refY = currentButton.centerY;
            button.show();
        });
    }

    function hide() {
        buttons.forEach(function (button, idx, arr) {
            button.visible = false;
            button.mouseOut(button);
        });
        mainButtons.forEach(function(button) {
            button.resetTimeRefs();
            button.mouseOut(button);
        });
        if (currentButton) currentButton.isSecondSelect = false;
        lastFocusedButton = null;
        currentButton = null;
    }

    function contains(point) {
        if (!currentButton) return false;
        var minX, maxX, minY, maxY;
        var someRegionContains = false;
        buttons.forEach(function (button, idx, arr) {
            minX = Math.min(button.x, currentButton.x);
            maxX = Math.max(button.x + button.width, currentButton.x + currentButton.width);
            minY = Math.min(button.y, currentButton.y);
            maxY = Math.max(button.y + button.height, currentButton.y + currentButton.height);
            if (button.visible && point.x >= minX && point.x <= maxX && point.y >= minY && point.y <= maxY) someRegionContains = true;
        });
        return someRegionContains;
    }

    function onNewSample(sample, tstamp) {
        curTstamp = tstamp;
        if (!active) return;
        if (buttonsVisible) {
            if (currentButton.visuallyContainsPoint(sample) ||
                (lastFocusedButton && lastFocusedButton.visuallyContainsPoint(sample))) {
                resetT0();
                dwellReference = tstamp;
            }
            var selecteStateChanged = false;
            buttons.forEach(function (button, idx, arr) {
                if (button.visible) {
                    var prev = button.isSelected;
                    button.onNewSample(sample, tstamp);
                    if (prev !== button.isSelected) {
                        menu.opacity = (button.isSelected ? 1 : menuTransparency)
                        selecteStateChanged = true;
                    }
                }
            });
            if (currentButton) currentButton.onNewSample(sample, tstamp);
            if ((currentButton && currentButton.containsPoint(sample)) || selecteStateChanged) {
                timeoutReference = tstamp;
            }
            else if (tstamp - timeoutReference > (contains(sample) ? 1.5 : 1) * timeoutTime) {
                hide();
            }
            if (tstamp - dwellReference > inMenuButNoButtonTime) {
                hide();
            }
        }
        else {
            mainButtons.forEach(function(button) {
                if (button.visible) button.onNewSample(sample, tstamp);
            });
        }
    }
}
