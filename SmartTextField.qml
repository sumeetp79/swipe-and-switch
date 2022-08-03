import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import "TextFieldToken.js" as TFT

Rectangle {
    property color wordSelectionColor: "light gray"
    property string typedText: ""
    property double fontSize: 20
    property var punctuation: ['.', ',', '?', '!']
    property var tokens: []
    property double t0: new Date().valueOf()
    property double wpm: 0
    property double fontScale: 1
    property double textXOffset: input.x
    property double highestWPM: 0
    property bool showCandidates: true
    property bool lockToken: false
    property bool charByChar: false
    property var capitalizedWords: ["John", "Brindle", "Florida", "Dynegy", "Chris", "Foster", "Ava", "Houston", "Mary", "Becky", "Duran", "Greg", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday", "Mike", "Disney", "Jay", "Portland", "Travis", "ENE", "OK", "Stan", "TK", "Natalie"]
    border.color: "black"
    height: fontSize * 1.5

    onShowCandidatesChanged: updateCandidates()

    onT0Changed: timer.restart()

    Timer {
        id: timer
        interval: 1000
        repeat: true
        onTriggered: {
            var dt = (new Date().valueOf() - t0) / 60000;
            wpm = typedText.length / (5 * dt);
            if (wpm > highestWPM) highestWPM = wpm;
        }
    }

    onTypedTextChanged: input.fixTextSize()

    TextInput {
        id: input
        anchors.centerIn: parent
        enabled: false
        width: parent.width * 0.99
        font.pixelSize: fontSize * fontScale
        selectionColor: wordSelectionColor
        cursorVisible: true

        onWidthChanged: fixTextSize()
        onHeightChanged: fixTextSize()
        onFontChanged: fixTextSize()

        function fixTextSize() {
            text = typedText;
            for (var i = 0; contentWidth > width && i < typedText.length; i++) {
                text = typedText.substring(i);
            }
        }
    }

    signal newWord(string word)
    signal wordDeleted(string word)
    signal spaceAdded()
    signal charAdded(string addedChar);
    signal charDeleted();
    signal candidateChanged(string newCandidate);

    function addPunct(punct) {
        if (lockToken) return;
        charAdded(punct);
        if (charByChar) {
            addChar(punct);
            return;
        }

        if (tokens.length == 0 || !tokens[tokens.length - 1].isPunct) {
            verifyNewWord();
            tokens.push(new TFT.Token([punct.trim()], false, 0, true));
        }
        else {
            var token = tokens[tokens.length - 1];
            token.word += punct.trim();
        }
        updateUI();
    }

    function addChar(newChar) {
        if (lockToken) return;
        if (tokens.length == 0 || !tokens[tokens.length - 1].charByChar) {
            tokens.push(new TFT.Token([""], true, 0, false, true));
        }
        tokens[tokens.length - 1].word += newChar;
        updateUI();
        charAdded(newChar);
    }

    function addSingleLetter(letter) {
        if (lockToken) return;
        charAdded(letter);
        if (charByChar) {
            addChar(letter);
            return;
        }

        if (tokens.length == 0 || !tokens[tokens.length - 1].isEditing) {
            verifyNewWord();
            tokens.push(new TFT.Token([letter], true));
        }
        else {
            var token = tokens[tokens.length - 1];
            token.word += letter;
        }
        updateUI();
    }

    function changeCandidate(newCandidate) {
        var changed = true;
        if (tokens.length == 0) {
            addWordCandidates([newCandidate]);
        }
        else {
            var token = tokens[tokens.length - 1];
            if (newCandidate === token.word) {
                changed = false;
            }
            else {
                wordDeleted(token.word);
                token.changeCandidate(newCandidate);
                newWord(newCandidate);
            }
        }
        if (changed) {
            updateUI(true);
            candidateChanged(newCandidate);
        }
    }

    function addSpace() {
        if (lockToken) return;
        spaceAdded();
        if (charByChar) {
            addChar(" ");
            return;
        }

        if (tokens.length == 0) {
            tokens.push(new TFT.Token([""], false, 1));
        }
        else {
            var token = tokens[tokens.length - 1];
            if (token.isEditing) {
                verifyNewWord();
            }
            else {
                token.addExtraSpace();
            }
        }
        updateTypedText();
    }

    function addWordCandidates(words) {
        if (lockToken) return;
        verifyNewWord();
        tokens.push(new TFT.Token(words));
        updateUI(true);
        newWord(words[0]);
    }

    function deleteWord() {
        if (lockToken) return;
        if (tokens.length == 0) return;
        var token = tokens[tokens.length - 1];
        if (token.word.length > 0) {
            if (token.isPunct) {
                wordDeleted("");
            }
            else {
                wordDeleted(token.word);
            }
        }
        removeLastToken();
        updateUI();
    }

    function deleteChar() {
        if (lockToken) return;
        if (tokens.length == 0) return;
        charDeleted();
        var token = tokens[tokens.length - 1];
        if (!token.removeExtraSpace()) {
            if (!token.isEditing) wordDeleted(token.word);
            token.removeLastChar();
        }
        if (token.isEmpty()) {
            removeLastToken();
        }
        updateUI();
    }

    function updateUI(isNew) {
        updateTypedText();
        updateCandidates(isNew);
    }

    function capitalizeIfNeeded(word, capitalize) {
        /*
        for (var i = 0; i < capitalizedWords.length; i++) {
            if (word === capitalizedWords[i].toLowerCase()) return capitalizedWords[i];
        }
        */
        if (capitalize ||
            (word.charAt(0) === 'i' &&
             (word.length === 1 || word.charAt(1) === '\''))) {
            return word.charAt(0).toUpperCase() + word.slice(1);
        }
        return word;
    }

    function updateTypedText() {
        var text = "";
        var isFirst = true;
        var capitalize = true;
        tokens.forEach(function(token) {
            var word = /*token.word;*/capitalizeIfNeeded(token.word, capitalize);
            if (isFirst) {
                capitalize = false;
                isFirst = false;
            }
            else if (token.isPunct) capitalize = token.word !== ",";
            else {
                capitalize = false;
                text += ' ';
            }
            text += word;
            for (var i = 0; i < token.extraSpaces; i++) text += ' ';
        });
        typedText = text;
    }

    function updateCandidates(isNew) {
        var candidates = [];
        if (tokens.length > 0) candidates = tokens[tokens.length - 1].candidates;
        for (var i = 0; i < candidateRepeater.model; i++) {
            if (i < candidates.length && showCandidates && isNew) {
                var candidateButton = candidateRepeater.itemAt(i);
                candidateButton.text = candidates[i];
                if (tokens[tokens.length - 1].word === candidates[i])
                    candidateButton.enabled = false;
                else
                    candidateButton.enabled = true;
            }
            else {
                candidateRepeater.itemAt(i).text = "";
            }
        }
    }

    function verifyNewWord() {
        if (tokens.length == 0) return;
        var token = tokens[tokens.length - 1];
        if (token.isEditing) {
            token.isEditing = false;
            newWord(token.word);
        }
    }

    function removeLastToken() {
        if (tokens.length == 0) return;
        tokens = tokens.slice(0, tokens.length - 1);
    }

    function clear() {
        tokens = [];
        updateUI();
    }
}
