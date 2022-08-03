#ifndef KEYBOARDMANAGER_H
#define KEYBOARDMANAGER_H

#include <QObject>

#include "PointerManager.h"
#include "MouseListener.h"
#include "TobiiListener.h"
#include "KeyboardLayout.h"
#include "WordPredictor.h"
#include "ShapeDrawer.h"
#include "TextInputManager.h"
#include "ExperimentManager.h"

class KeyboardManager : public QObject
{
    Q_OBJECT
public:
    explicit KeyboardManager(QObject *root, bool isEnglish);
    ~KeyboardManager();

    WordPredictor& getPredictor();
    PointerManager& getPointerManager();
    QObject* getTypingManager();
    QObject* getBackspaceKey();
    QObject* getTextField();

public slots:
    void toggleConnections(bool isPaused);

private:
    QObject *root;
    QObject *pointer;
    QObject *typingManager;
    QObject *backspaceKey;
    QObject *textField;
    bool mouseControlling;
    PointerManager pointerManager;
    KeyboardLayout layout;
    MouseListener mouseListener;
    TobiiListener tobiiListener;
    WordPredictor predictor;
    ShapeDrawer drawer;
    TextInputManager input;
};

#endif // KEYBOARDMANAGER_H
