import QtQuick 2.0

KBButton {
    id: keyboardKey
    property bool isStart: false
    property bool isSecondSelect: false
    property color startedColor: Qt.rgba(0.62, 0.98, 1, 1)
    property color secondSelectColor: Qt.rgba(0.62, 0.98, 1, 1)
    fontSize: size / 4
    visibleColor: !enabled ? disabledColor : isSecondSelect ? secondSelectColor : isSelected ? selectedColor : unselectedColor

    signal keySelected(var key);
    signal keyUnselected(var key);

    onCenterXChanged: expManager.logKeyPos(objectName, Qt.point(centerX, centerY), Qt.point(origWidth, origHeight))
    onCenterYChanged: expManager.logKeyPos(objectName, Qt.point(centerX, centerY), Qt.point(origWidth, origHeight))
    onOrigWidthChanged: expManager.logKeyPos(objectName, Qt.point(centerX, centerY), Qt.point(origWidth, origHeight))
    onOrigHeightChanged: expManager.logKeyPos(objectName, Qt.point(centerX, centerY), Qt.point(origWidth, origHeight))
}
