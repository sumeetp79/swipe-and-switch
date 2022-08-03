#include <QDebug>

#include "KeyboardManager.h"

KeyboardManager::KeyboardManager(QObject *root, bool isEnglish) :
    QObject(root),
    root(root),
    pointer(root->findChild<QObject*>("pointer")),
    typingManager(root->findChild<QObject*>("typingManager")),
    backspaceKey(root->findChild<QObject*>("backspaceKey")),
    textField(root->findChild<QObject*>("textField")),
    mouseControlling(root->property("isMouseControlling").toBool()),
    pointerManager(root, pointer, !mouseControlling),
    layout(root),
    mouseListener(root, mouseControlling),
    tobiiListener(root, !mouseControlling),
    predictor(root, layout, typingManager, isEnglish),
    drawer(root, predictor),
    input(root)
{
    connect(typingManager, SIGNAL(typingChanged(bool)), &predictor, SLOT(updateTyping(bool)));
}

KeyboardManager::~KeyboardManager()
{
}

WordPredictor& KeyboardManager::getPredictor()
{
    return predictor;
}

PointerManager& KeyboardManager::getPointerManager()
{
    return pointerManager;
}

QObject* KeyboardManager::getTypingManager()
{
    return typingManager;
}

QObject* KeyboardManager::getBackspaceKey()
{
    return backspaceKey;
}

QObject* KeyboardManager::getTextField()
{
    return textField;
}

void KeyboardManager::toggleConnections(bool isPaused)
{
    if (isPaused)
    {
        disconnect(root, SIGNAL(pointerToggled(bool)), &mouseListener, SLOT(controlToggled(bool)));
        disconnect(root, SIGNAL(pointerToggled(bool)), &tobiiListener, SLOT(controlToggled(bool)));
        disconnect(root, SIGNAL(pointerToggled(bool)), &pointerManager, SLOT(setIsMouse(bool)));
        disconnect(&mouseListener, SIGNAL(newMouse(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        disconnect(&tobiiListener, SIGNAL(newGaze(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        disconnect(&pointerManager, SIGNAL(newSample(QPointF, double)), &predictor, SLOT(onNewSample(QPointF, double)));
        disconnect(&pointerManager, SIGNAL(newSample(QPointF, double)), &drawer, SLOT(updateShape(QPointF, double)));
        disconnect(typingManager, SIGNAL(toggleGesture(char, double)), &predictor, SLOT(onGestureToggled(char, double)));
        disconnect(typingManager, SIGNAL(keystroke(QString)), &predictor, SLOT(onKeystroke(QString)));
        disconnect(backspaceKey, SIGNAL(cancelGesture()), &predictor, SLOT(onGestureCanceled()));
        disconnect(textField, SIGNAL(newWord(QString)), &predictor, SLOT(addWordToLexicon(QString)));
        disconnect(textField, SIGNAL(wordDeleted(QString)), &predictor, SLOT(removeWordOccurence(QString)));
        disconnect(&predictor, SIGNAL(newLetter(QChar)), &input, SLOT(addSingleLetter(QChar)));
        disconnect(&predictor, SIGNAL(newWordCandidates(QStringList)), &input, SLOT(addWordCandidates(QStringList)));
    }
    else
    {
        connect(root, SIGNAL(pointerToggled(bool)), &mouseListener, SLOT(controlToggled(bool)));
        connect(root, SIGNAL(pointerToggled(bool)), &tobiiListener, SLOT(controlToggled(bool)));
        connect(root, SIGNAL(pointerToggled(bool)), &pointerManager, SLOT(setIsMouse(bool)));
        connect(&mouseListener, SIGNAL(newMouse(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        connect(&tobiiListener, SIGNAL(newGaze(SamplePoint)), &pointerManager, SLOT(updatePointer(SamplePoint)));
        connect(&pointerManager, SIGNAL(newSample(QPointF, double)), &predictor, SLOT(onNewSample(QPointF, double)));
        connect(&pointerManager, SIGNAL(newSample(QPointF, double)), &drawer, SLOT(updateShape(QPointF, double)));
        connect(typingManager, SIGNAL(toggleGesture(QString, double)), &predictor, SLOT(onGestureToggled(QString, double)));
        connect(typingManager, SIGNAL(keystroke(QString)), &predictor, SLOT(onKeystroke(QString)));
        connect(backspaceKey, SIGNAL(cancelGesture()), &predictor, SLOT(onGestureCanceled()));
        connect(textField, SIGNAL(newWord(QString)), &predictor, SLOT(addWordToLexicon(QString)));
        connect(textField, SIGNAL(wordDeleted(QString)), &predictor, SLOT(removeWordOccurence(QString)));
        connect(&predictor, SIGNAL(newLetter(QChar)), &input, SLOT(addSingleLetter(QChar)));
        connect(&predictor, SIGNAL(newWordCandidates(QStringList)), &input, SLOT(addWordCandidates(QStringList)));
    }
}
