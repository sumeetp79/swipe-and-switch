import QtQuick 2.3
import QtQuick.Controls 1.2

ApplicationWindow {
    id: win
    visible: true
    color: "white"
    visibility: "Maximized"
    width: 640
    height: 480
    property bool isExperiment: true // Set this to false to access the keyboard with extra options
    property bool experimentStarted: false
    property bool experimentFinished: false
    property bool showArrows: true
    property bool isPaused: isExperiment
    property bool dwellKeyboard: false
    property bool phoneLayout: false
    property bool showTutorial: true
    property bool keysLogged: false
    property bool isEnglish: true
    property double sessionDuration: 10 * 60 * 1000
    property int sessionCount: expManager ? expManager.getCurrentSessionID() : 1
    property int totalSessions: expManager ? expManager.getTotalSessions() : 3
    property double kb_max_height: 5 * height / 9 //height - candidates.y - 1.5 * textField.height
    property double kb_max_width: 0.9 * width//width - 20
    property double kb_height: 0.436363636 * width // 4yStep + keySize
    property double kb_width: isExperiment ? 0.9 * width : width // 11 * xStep
    property double kb_scale: Math.min(kb_max_height / kb_height, kb_max_width / kb_width, 1)
    property double keySize: 0.072727273 * width * kb_scale
    //property double kb_top: 0.311978609 * height * kb_scale
    //property double kb_top: kb_scale == 1 ? (height + candidateRepeater.itemAt(0).y + textField.height - 3 * yStep - keySize) / 2 : 3 * height / 9
    property double kb_top: kb_scale == 1 ? height - (4 * yStep + 1 * keySize) : height - kb_height * kb_scale
    property double kb_left: phoneLayout ? (width - 9 * xStep) / 2 : isExperiment ? (width - 10 * xStep) / 2 : (width - 11 * xStep) / 2
    property double xStep: phoneLayout ? keySize : 0.090909091 * width * kb_scale
    property double yStep: phoneLayout ? xStep : 0.090909091 * width * kb_scale
    //property double yStep: 0.117647059 * width * kb_scale
    property double xShift: phoneLayout ? xStep : 0.042663636 * width * kb_scale
    property double textFontSize: 0.6855331123388582 * height / 20
    property bool isMouseControlling: false
    property variant keyObjs: getKeys()
    property variant candObjs: getCandidatesKeys()
    property variant menus: [keysPEyeMenu, candidatesPEyeMenu, spacePEyeMenu, backspacePEyeMenu, modePEyeMenu, punctPEyeMenu]
    title: qsTr("KeyEye")

    function connectPointerManager() {
        Qt.createQmlObject(
        "import QtQuick 2.3;
         Connections {
             target: pointerManager;
             onNewSample: {
                 if (win.isPaused) return;
                 var s = sample;
                 var t = tstamp;
                 win.menus.forEach(function (menu, idx, arr) {
                    menu.onNewSample(s, t);
                 });
                 dwellTimeSelection.onNewSample(s, t);
             }
         }",
         win, "main");
    }

    function startExperiment() {
        experimentStarted = true;
        expManager.startExperiment();
        showNextSentence();
        win.isPaused = false;

        if (!keysLogged) {
            keyObjs.forEach(function (key) {
                expManager.logKeyPos(key.objectName, Qt.point(key.centerX, key.centerY), Qt.point(key.origWidth, key.origHeight))
            });
            candObjs.forEach(function (key) {
                expManager.logKeyPos(key.objectName, Qt.point(key.centerX, key.centerY), Qt.point(key.origWidth, key.origHeight))
            });
            var keysToLog = [punctKey, spaceKey, backspaceKey, modeKey, pEyeSelectCandidate, pEyeSpace, pEyeMode].concat(keysPEyeMenu.buttons).concat(punctPEyeMenu.buttons).concat(backspacePEyeMenu.buttons);
            keysToLog.forEach(function (key) {
                expManager.logKeyPos(key.objectName, Qt.point(key.centerX, key.centerY), Qt.point(key.origWidth, key.origHeight))
            });
            keysLogged = true;
        }
    }

    function sentenceTyped() {
        if (!isExperiment) return;
        expManager.logTypedSentence(textField.typedText);
        if (expManager.sessionEllapsedTime() > sessionDuration) {
            expManager.stopExperiment();
            sessionCount = expManager.getCurrentSessionID();
            if (expManager.ended()) experimentFinished = true;
            experimentStarted = false;
        }
        else showNextSentence();
    }

    function showNextSentence() {
        if (!experimentStarted) return;

        textField.clear();
        sentenceToType.text = sentenceManager.randomSentence();
        expManager.logExpectedSentence(sentenceToType.text);
    }

    // Colors
    property string pointerColor: Qt.rgba(59/255., 102/255., 255/255.)
    property string wordSelectionColor: Qt.rgba(115/255., 161/255., 126/255.)
    property string keyUnselectedColor: "white"
    property string keySelectedColor: "light gray"
    property string keyStartedColor: Qt.rgba(128/255., 183/255., 189/255.)
    property string keyBorderColor: "black"
    property string gestureUnselectedColor: Qt.rgba(183/255., 255/255., 201/255.)
    property string gestureSelectedColor: Qt.rgba(115/255., 161/255., 126/255.)
    property string keystrokeUnselectedColor: gestureUnselectedColor
    property string keystrokeSelectedColor: gestureSelectedColor
    property string actionUnselectedColor: Qt.rgba(186/255., 119/255., 148/255.)
    property string actionSelectedColor: Qt.rgba(161/255., 103/255., 128/255.)
    property string candidateUnselectedColor: actionUnselectedColor
    property string candidateSelectedColor: actionSelectedColor
    property string menuBorderColor: "black"
    function pathColor(alpha) {
        return Qt.rgba(59/255., 102/255., 255/255., alpha);
    }

    signal pointerToggled(bool isMouse);
    signal resized();
    signal paused(bool isPaused);

    onWidthChanged: resized();
    onHeightChanged: resized();
    onIsPausedChanged: paused(isPaused)

    function mapToWindow(point) {
        return Qt.point(point.x - win.x, point.y - win.y);
    }

    function getKeys() {
        var allKeys = [];
        for (var i = 0; i < keyRepeater.count; i++) {
            for (var j = 0; j < keyRepeater.itemAt(i).count; j++) {
                allKeys.push(keyRepeater.itemAt(i).itemAt(j));
            }
        }
        return allKeys;
    }

    function getCandidatesKeys() {
        var allKeys = [];
        for (var i = 0; i < candidateRepeater.count; i++) {
            allKeys.push(candidateRepeater.itemAt(i));
        }
        return allKeys;
    }

    property var translations: {
        "Thank you!": "Obrigado!",
        "Session ": "Sessao ",
        "\nPress <Space> to start": "\nPressione <Espaco> para comecar",
        "Paused": "Parado",
        "Select": "Selecionar",
        "Add space": "Adicionar espaco",
        "Cancel": "Cancelar",
        "Delete word": "Remover palavra",
        "Delete character": "Remover caractere",
        "Continuous": "Continuo",
        "Single": "Caractere",
        "Start": "Comecar",
        "No word found": "Palavra nao encontrada",
        "End": "Fim"
    }

    function tr(str) {
        if (!isEnglish && str in translations) return translations[str];
        return str;
    }

    Text {
        anchors.centerIn: parent
        text: tr("Paused")
        font.pointSize: 30
        visible: isPaused && !gestureTutorial.active && !dwellTutorial.active
        z: 150
    }

    Rectangle {
        visible: isExperiment && !experimentStarted && !gestureTutorial.active && !dwellTutorial.active
        color: "white"
        anchors.fill: parent
        z: 200

        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: experimentFinished ? tr("Thank you!") : tr("Session ") + sessionCount + tr("\nPress <Space> to start")
            font.pixelSize: 40
        }
    }

    GestureTutorial {
        id: gestureTutorial
        active: isExperiment && !dwellKeyboard && showTutorial
        onStarted: {
            active = true;
            dwellTutorial.active = false;
        }
        //onEnded: startExperiment()
    }

    DwellTutorial {
        id: dwellTutorial
        active: isExperiment && dwellKeyboard && showTutorial
        onStarted: {
            active = true;
            gestureTutorial.active = false;
        }
        //onEnded: startExperiment()
    }

    Item {
        focus: true
        Keys.onPressed: {
            if (gestureTutorial.active && gestureTutorial.processKeys(event)) return;
            if (dwellTutorial.active && dwellTutorial.processKeys(event)) return;

            if (event.key === Qt.Key_T) {
                isMouseControlling = !isMouseControlling;
                pointerToggled(isMouseControlling);
            }
            else if (event.key === Qt.Key_S) {
                pointer.visible = !pointer.visible;
            }
            else if (event.key === Qt.Key_C) {
                canvas.visible = !canvas.visible;
            }
            else if (event.key === Qt.Key_Q && (event.modifiers & Qt.ControlModifier)) {
                Qt.quit();
            }
            else if (event.key === Qt.Key_P) {
                textField.t0 = new Date().valueOf();
                wpmText.visible = !wpmText.visible;
            }
            else if (event.key === Qt.Key_M) {
                showArrows = !showArrows;
            }
            else if (event.key === Qt.Key_Space) {
                if (experimentFinished) Qt.quit();
                else if (experimentStarted) isPaused = !isPaused;
                else startExperiment();
            }
        }
    }

    Rectangle {
        id: pointer
        objectName: "pointer"
        width: 10
        height: 10
        property int centerX: 5
        property int centerY: 5
        property bool active: !isPaused
        x: centerX - width/2
        y: centerY - height/2
        z: 100
        color: pointerColor
        visible: false
        radius: 5
    }

    Canvas {
        id: canvas
        z: 99
        objectName: "shape"
        anchors.fill: parent
        visible: true
        property variant points: []
        onPaint: {
            var ctx = canvas.getContext('2d');
            ctx.clearRect(canvas.x, canvas.y, canvas.width, canvas.height);
            if (points.length <= 1) return;
            var alpha = 0;
            var alphaStep = 0.8 / (points.length - 1);
            var width = 0;
            var widthStep = 5.0 / (points.length - 1);
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            points.slice(1, points.length).forEach(function(p) {
                alpha += alphaStep;
                width += widthStep;
                ctx.strokeStyle = pathColor(alpha);
                ctx.lineWidth = width;
                ctx.lineTo(p.x, p.y);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(p.x, p.y);
            });
            points.forEach(function(p) {
                ctx.fillStyle = Qt.rgba(255, 0, 0, 255);
                ctx.beginPath();
                ctx.arc(p.x, p.y, 4, 0, 2*Math.PI);
                ctx.fill();
            });
        }
        onPointsChanged: requestPaint()
    }

    Canvas {
        id: filteredShape
        z: 100
        objectName: "filteredShape"
        anchors.fill: parent
        visible: true
        property variant points: []
        onPaint: {
            var ctx = filteredShape.getContext('2d');
            ctx.clearRect(filteredShape.x, filteredShape.y, filteredShape.width, filteredShape.height);
            if (points.length <= 1) return;
            var width = 0;
            var widthStep = 5.0 / (points.length - 1);
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            points.slice(1, points.length).forEach(function(p) {
                width += widthStep;
                ctx.strokeStyle = Qt.rgba(255, 0, 0, 255);
                ctx.lineWidth = width;
                ctx.lineTo(p.x, p.y);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(p.x, p.y);
            });
            points.forEach(function(p) {
                ctx.fillStyle = Qt.rgba(0, 0, 255, 255);
                ctx.beginPath();
                ctx.arc(p.x, p.y, 4, 0, 2*Math.PI);
                ctx.fill();
            });
        }
        onPointsChanged: requestPaint()
    }

    Canvas {
        id: idealPath
        z: 100
        objectName: "idealPath"
        anchors.fill: parent
        visible: true
        property variant points: []
        onPaint: {
            var ctx = idealPath.getContext('2d');
            ctx.clearRect(idealPath.x, idealPath.y, idealPath.width, idealPath.height);
            if (points.length <= 1) return;
            var width = 0;
            var widthStep = 5.0 / (points.length - 1);
            ctx.beginPath();
            ctx.moveTo(points[0].x, points[0].y);
            points.slice(1, points.length).forEach(function(p) {
                width += widthStep;
                ctx.strokeStyle = Qt.rgba(255, 255, 0, 255);
                ctx.lineWidth = width;
                ctx.lineTo(p.x, p.y);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(p.x, p.y);
            });
            points.forEach(function(p) {
                ctx.fillStyle = Qt.rgba(0, 255, 255, 255);
                ctx.beginPath();
                ctx.arc(p.x, p.y, 4, 0, 2*Math.PI);
                ctx.fill();
            });
        }
        onPointsChanged: requestPaint()
    }

    SmartTextField {
        id: textField
        objectName: "textField"
        radius: height / 8
        x: height
        y: 1.5 * height
        width: parent.width - 2 * height
        wordSelectionColor: win.wordSelectionColor
        fontSize: textFontSize
        showCandidates: !dwellKeyboard
        charByChar: dwellKeyboard
        fontScale: sentenceToType.fontScale
    }

    Text {
        id: sentenceToType
        x: textField.x + textField.textXOffset
        y: textField.y - 1 * textField.height
        font.pixelSize: textFontSize * fontScale
        property double fontScale: paintedWidth > textField.width * 0.9 ? (textField.width * 0.9 / paintedWidth) : 1
    }

    Text {
        id: wpmText
        text: "Current: " + formatWPM(textField.wpm) + "Highest: " + formatWPM(textField.highestWPM)
        visible: false
        font.pixelSize: 20
        x: 10
        y: 10

        function formatWPM(value) {
            return parseFloat(Math.round(value * 100) / 100).toFixed(2) + " wpm";
        }
    }

    Repeater {
        id: candidateRepeater
        model: numberOfButtons
        property int numberOfButtons: 5
        property double spacing: textField.width / 100
        Key {
            objectName: "candidate"+index
            size: origHeight
            origWidth: (textField.width - (candidateRepeater.numberOfButtons - 1) * candidateRepeater.spacing) / candidateRepeater.numberOfButtons
            origHeight: keySize
            centerX: textField.x + origWidth / 2 + index * (origWidth + candidateRepeater.spacing)
            centerY: 4.25 * textField.height + origHeight / 2
            fontSize: textFontSize
            radiusRatio: 1 / 6
            text: ""
            visible: text.length > 0 & typingManager.isStart
        }
    }

    Item {
        id: dwellTimeSelection
        property bool active: dwellKeyboard

        onActiveChanged: expManager.logUsingDwell(active)

        function onNewSample(sample, tstamp) {
            if (!active) return;
            keyObjs.forEach(function (key) {
                key.onNewSample(sample, tstamp);
            });
            spaceKey.onNewSample(sample, tstamp);
            backspaceKey.onNewSample(sample, tstamp);
        }
    }

    Item {
        id: typingManager
        objectName: "typingManager"
        property bool isStart: true

        signal toggleGesture(string letter, double timestamp)
        signal typingChanged(bool isTyping)
        signal keystroke(string letter)

        onIsStartChanged: {
            typingChanged(!isStart);
        }

        function toggle() {
            isStart = !isStart;
        }
    }

    function getRepeaterGestureButtons() {
        var allButtons = [];
        for (var i = 0; i < keysPEyeGestureRepeater.count; i++) {
            allButtons.push(keysPEyeGestureRepeater.itemAt(i));
        }
        return allButtons;
    }

    function getRepeaterKeystrokeButtons() {
        var allButtons = [];
        for (var i = 0; i < keysPEyeKeystrokeRepeater.count; i++) {
            allButtons.push(keysPEyeKeystrokeRepeater.itemAt(i));
        }
        return allButtons;
    }

    PEyeMenu {
        id: keysPEyeMenu
        showArrows: win.showArrows
        objectName: "keysPEyeMenu"
        mainButtons: keyObjs
        active: !dwellKeyboard && !menus.some(function(menu) { return menu === keysPEyeMenu ? false : menu.buttonsVisible; })
        buttons: [pEyeGesture, pEyeKeystroke].concat(getRepeaterGestureButtons()).concat(getRepeaterKeystrokeButtons())
        property variant gestureButtons: [pEyeGesture].concat(getRepeaterGestureButtons())
        onDisplayed: {
            if (typingManager.isStart) {
                if (phoneLayout) {
                    getRepeaterGestureButtons().forEach(function(gesBut) {
                        var idx = gridIdxFromPosition(gesBut.position, currentButton.rotated);
                        if (idx < 0) return;
                        gesBut.text = currentButton.gridText[idx];
                    });
                }
                else pEyeGesture.text = tr("Start");
            }
            else {
                if (expManager && expManager.shouldShowCandidate()) {
                    gestureButtons.forEach(function(gesBut) {
                        var letter;
                        if (phoneLayout)
                            letter = currentButton.gridText[gridIdxFromPosition(gesBut.position, currentButton.rotated)];
                        else
                            letter = currentButton.text;
                        var candidates = [];
                        if (letter.length > 0) {
                            candidates = predictor.getCandidates(letter, enterTimestamp);
                        }
                        if (candidates.length > 0) gesBut.text = candidates[0];
                        else gesBut.text = tr("No word found");
                    });
                }
                else {
                    pEyeGesture.text = tr("End");
                    getRepeaterGestureButtons().forEach(function(gesBut) {
                        gesBut.text = tr("End");
                    });
                }
            }

            pEyeKeystroke.text = currentButton.text;
            getRepeaterKeystrokeButtons().forEach(function(strBut) {
                if (phoneLayout) {
                    var pos = gridIdxFromPosition(strBut.position, currentButton.rotated);
                    if (pos < 0) return;
                    strBut.text = currentButton.gridText[pos];
                }
                else
                    strBut.text = currentButton.text;
            });
        }

        function gridIdxFromPosition(pos, rotated) {
            var convert = [0, 1, 2, 5, 8, 7, 6, 3];
            convert = [0, 4, 2, 5, 8, 7, 6, 3];

            if (rotated) {
                pos -= 1;
                if (pos < 0) pos += 8;
            }
            return convert[pos];
        }

        PEyeButton {
            id: pEyeGesture
            objectName: "pEyeGesture"
            fontSize: textFontSize
            size: keySize
            selectedColor: typingManager.isStart ? actionSelectedColor : (expManager.shouldShowCandidate() ? gestureSelectedColor : actionSelectedColor)
            unselectedColor: typingManager.isStart ? actionUnselectedColor : (expManager.shouldShowCandidate() ? gestureUnselectedColor : actionUnselectedColor)
            borderColor: menuBorderColor
            position: 1
            visible: false

            onClick: {
                typingManager.toggle();
                typingManager.toggleGesture(button.text[0], timestamp);
            }

            function show() {
                visible = modeKey.isGesture && !phoneLayout;
            }
        }

        PEyeButton {
            id: pEyeKeystroke
            objectName: "pEyeKeystroke"
            fontSize: textFontSize
            size: keySize
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            position: 1
            visible: false

            onClick: {
                typingManager.keystroke(button.text[0]);
            }

            function show() {
                visible = !modeKey.isGesture && !phoneLayout;
            }
        }

        Repeater {
            id: keysPEyeGestureRepeater
            model: 4

            PEyeButton {
                objectName: "pEyeGesture"+(index+1)
                fontSize: textFontSize
                size: keySize
                selectedColor: typingManager.isStart ? actionSelectedColor : (expManager.shouldShowCandidate() ? gestureSelectedColor : actionSelectedColor)
                unselectedColor: typingManager.isStart ? actionUnselectedColor : (expManager.shouldShowCandidate() ? gestureUnselectedColor : actionUnselectedColor)
                borderColor: menuBorderColor
                position: (2*index)+1
                visible: false

                onClick: {
                    var idx=keysPEyeMenu.gridIdxFromPosition(position, button.rotated);
                    if (idx < 0) return;
                    typingManager.toggle();
                    typingManager.toggleGesture(button.gridText[idx], timestamp);
                }

                function show() {
                    var idx=keysPEyeMenu.gridIdxFromPosition(position, keysPEyeMenu.currentButton.rotated);
                    var txt="";
                    if (idx >= 0) txt=keysPEyeMenu.currentButton.gridText[idx];
                    visible = modeKey.isGesture && phoneLayout && txt.length > 0;
                }
            }
        }

        Repeater {
            id: keysPEyeKeystrokeRepeater
            model: 4

            PEyeButton {
                objectName: "pEyeKeystroke"+(index+1)
                fontSize: textFontSize
                size: keySize
                selectedColor: keystrokeSelectedColor
                unselectedColor: keystrokeUnselectedColor
                borderColor: menuBorderColor
                position: (2*index)+1
                visible: false

                onClick: {
                    var idx=keysPEyeMenu.gridIdxFromPosition(position, button.rotated);
                    typingManager.keystroke(button.gridText[idx]);
                }

                function show() {
                    var idx=keysPEyeMenu.gridIdxFromPosition(position, keysPEyeMenu.currentButton.rotated);
                    var txt=keysPEyeMenu.currentButton.gridText[idx];
                    visible = !modeKey.isGesture && phoneLayout && txt.length > 0;
                }
            }
        }
    }

    PEyeMenu {
        id: candidatesPEyeMenu
        showArrows: win.showArrows
        mainButtons: candObjs
        active: !keysPEyeMenu.buttonsVisible && typingManager.isStart && !dwellKeyboard && !backspacePEyeMenu.buttonsVisible && !modePEyeMenu.buttonsVisible
        buttons: [pEyeSelectCandidate]

        PEyeButton {
            id: pEyeSelectCandidate
            objectName: "pEyeSelectCandidate"
            size: candObjs[0].size
            fontSize: textFontSize
            origWidth: candObjs[0].width
            origHeight: candObjs[0].height
            selectedColor: candidateSelectedColor
            unselectedColor: candidateUnselectedColor
            borderColor: menuBorderColor
            text: tr("Select")
            position: 1
            visible: false

            onClick: {
                textField.changeCandidate(candidatesPEyeMenu.currentButton.text);
            }
        }
    }

    Repeater {
        id: keyRepeater
        model: phoneLayout ?
                [[" qw", "ert", "yui", "op "],
                 ["asd", "fgh", "jkl"],
                 [" zx", "cvb", "nm "]] :
                [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
                 ["a", "s", "d", "f", "g", "h", "j", "k", "l"],
                 ["z", "x", "c", "v", "b", "n", "m", "'"]]
        Repeater {
            model: modelData
            property int rowIndex: index
            Key {
                id: curKey
                objectName: modelData.trim() + "Key"
                size: keySize
                selectedColor: keySelectedColor
                unselectedColor: keyUnselectedColor
                startedColor: keyStartedColor
                borderColor: keyBorderColor
                centerX: kb_left + (phoneLayout ? 2 : 1) * index * xStep + rowIndex * xShift + keySize / 2
                centerY: kb_top + rowIndex * yStep + keySize / 2
                text: modelData.length <= 1 ? modelData.toUpperCase() : ""
                gridText: modelData.length >= 3 ? ["","","",modelData[0].trim().toUpperCase(),modelData[1].trim().toUpperCase(),modelData[2].trim().toUpperCase(),"","",""] : ["","","","","","","","",""]
                onClick: typingManager.keystroke(curKey.text[0])
                active: !punctPEyeMenu.buttonsVisible
                clickingEnabled: dwellKeyboard
            }
        }
    }

    Key {
        id: punctKey
        objectName: "punctKey"
        size: keySize
        selectedColor: keySelectedColor
        unselectedColor: keyUnselectedColor
        startedColor: keyStartedColor
        borderColor: keyBorderColor
        centerX: kb_left + 8 * xStep + 2 * xShift + keySize / 2
        centerY: kb_top + 2 * yStep + keySize / 2
        text: ".,?!"
    }

    PEyeMenu {
        id: punctPEyeMenu
        showArrows: win.showArrows
        mainButtons: [punctKey]
        buttons: [pEyeDot, pEyeComma, pEyeExclamation, pEyeQuestion]
        active: !keysPEyeMenu.buttonsVisible && typingManager.isStart

        PEyeButton {
            id: pEyeDot
            objectName: "pEyeDot"
            size: punctKey.size
            fontSize: textFontSize
            origWidth: punctKey.width
            origHeight: punctKey.height
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            text: "."
            position: 1
            visible: false
            clickingEnabled: dwellKeyboard

            onClick: {
                textField.addPunct(text);
                sentenceTyped();
            }
        }

        PEyeButton {
            id: pEyeComma
            objectName: "pEyeComma"
            size: punctKey.size
            fontSize: textFontSize
            origWidth: punctKey.width
            origHeight: punctKey.height
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            text: ","
            position: 3
            visible: false
            clickingEnabled: dwellKeyboard

            onClick: {
                textField.addPunct(text);
            }

            function show() {
                visible = !isExperiment;
            }
        }

        PEyeButton {
            id: pEyeExclamation
            objectName: "pEyeExclamation"
            size: punctKey.size
            fontSize: textFontSize
            origWidth: punctKey.width
            origHeight: punctKey.height
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            text: "!"
            position: 5
            visible: false
            clickingEnabled: dwellKeyboard

            onClick: {
                textField.addPunct(text);
                sentenceTyped();
            }
        }

        PEyeButton {
            id: pEyeQuestion
            objectName: "pEyeQuestion"
            size: punctKey.size
            fontSize: textFontSize
            origWidth: punctKey.width
            origHeight: punctKey.height
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            text: "?"
            position: 7
            visible: false
            clickingEnabled: dwellKeyboard

            onClick: {
                textField.addPunct(text);
                sentenceTyped();
            }
        }
    }

    Key {
        id: spaceKey
        objectName: "spaceKey"
        size: keySize
        origWidth: (phoneLayout ? 3 : 7) * xStep + keySize
        selectedColor: keySelectedColor
        unselectedColor: keyUnselectedColor
        startedColor: keyStartedColor
        borderColor: keyBorderColor
        centerX: kb_left + (phoneLayout ? 1 : 3) * xShift + origWidth / 2
        centerY: kb_top + (phoneLayout ? 3 : 3.5) * yStep + origHeight / 2
        text: "___"
        clickingEnabled: dwellKeyboard
        onClick: textField.addSpace()
        visible: !isExperiment || dwellTimeSelection.active;
    }

    PEyeMenu {
        id: spacePEyeMenu
        showArrows: win.showArrows
        mainButtons: [spaceKey]
        buttons: [pEyeSpace]
        active: !keysPEyeMenu.buttonsVisible && !punctPEyeMenu.buttonsVisible && !dwellKeyboard && typingManager.isStart

        PEyeButton {
            id: pEyeSpace
            objectName: "pEyeSpace"
            size: spaceKey.size
            fontSize: textFontSize
            origWidth: spaceKey.width
            origHeight: spaceKey.height
            selectedColor: keystrokeSelectedColor
            unselectedColor: keystrokeUnselectedColor
            borderColor: menuBorderColor
            text: tr("Add space")
            position: 1
            visible: false

            onClick: {
                textField.addSpace();
            }
        }
    }

    Key {
        id: backspaceKey
        objectName: "backspaceKey"
        origWidth: xStep + keySize
        origHeight: keySize
        centerX: kb_left + (phoneLayout ? 6 : 9) * xStep + keySize - origWidth / 2
        centerY: Math.min(textField.y + 3 * textField.height + keySize + origHeight / 2, kb_top - origHeight / 2)
        selectedColor: keySelectedColor
        unselectedColor: keyUnselectedColor
        borderColor: keyBorderColor
        text: "\u2190"
        clickingEnabled: dwellKeyboard
        onClick: textField.deleteChar()

        signal cancelGesture()
    }

    PEyeMenu {
        id: backspacePEyeMenu
        showArrows: win.showArrows
        mainButtons: [backspaceKey]
        buttons: [pEyeBackspaceWord, pEyeBackspaceChar]
        active: !spacePEyeMenu.buttonsVisible && !keysPEyeMenu.buttonsVisible && !punctPEyeMenu.buttonsVisible && !dwellKeyboard

        PEyeButton {
            id: pEyeBackspaceWord
            objectName: "pEyeBackspaceWord"
            size: backspaceKey.size
            fontSize: modeKey.fontSize
            origWidth: backspaceKey.width
            origHeight: backspaceKey.height
            offsetY: 1.5 * backspaceKey.height
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            borderColor: menuBorderColor
            text: isCancel ? tr("Cancel") : tr("Delete word")
            position: 1
            visible: false
            property bool isCancel: !typingManager.isStart

            onClick: {
                if (isCancel) {
                    typingManager.toggle();
                    backspaceKey.cancelGesture();
                }
                else {
                    textField.deleteWord();
                }
            }
        }

        PEyeButton {
            id: pEyeBackspaceChar
            objectName: "pEyeBackspaceChar"
            size: backspaceKey.size
            fontSize: pEyeBackspaceWord.fontSize
            origWidth: backspaceKey.width
            origHeight: backspaceKey.height
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            borderColor: menuBorderColor
            text: tr("Delete character")
            position: 5
            visible: false
            property bool isCancel: !typingManager.isStart

            onClick: {
                textField.deleteChar();
                if (!typingManager.isStart) {
                    typingManager.toggle();
                    backspaceKey.cancelGesture();
                }
            }

            function show() {
                visible = !isExperiment && !isCancel;
            }
        }
    }

    Key {
        id: modeKey
        objectName: "modeKey"
        origWidth: backspaceKey.origWidth
        origHeight: backspaceKey.origHeight
        centerX: backspaceKey.x - origWidth / 2 - xStep + keySize
        centerY: backspaceKey.centerY
        selectedColor: keySelectedColor
        unselectedColor: keyUnselectedColor
        borderColor: keyBorderColor
        text: modeName(isGesture)
        visible: !dwellKeyboard && !isExperiment
        property bool isGesture: true

        signal cancelGesture()

        function modeName(isGesture) {
            return isGesture ? tr("Continuous") : tr("Single")
        }
    }

    PEyeMenu {
        id: modePEyeMenu
        showArrows: win.showArrows
        mainButtons: [modeKey]
        buttons: [pEyeMode]
        active: !spacePEyeMenu.buttonsVisible && !keysPEyeMenu.buttonsVisible && !punctPEyeMenu.buttonsVisible && !dwellKeyboard && modeKey.visible

        PEyeButton {
            id: pEyeMode
            objectName: "pEyeMode"
            size: modeKey.size
            fontSize: modeKey.fontSize
            origWidth: modeKey.width
            origHeight: modeKey.height
            offsetY: 1.5 * modeKey.height
            selectedColor: actionSelectedColor
            unselectedColor: actionUnselectedColor
            borderColor: menuBorderColor
            text: modeKey.modeName(!modeKey.isGesture)
            position: 1
            visible: false

            onClick: modeKey.isGesture = !modeKey.isGesture
        }
    }
}
