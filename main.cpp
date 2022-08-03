#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QPixmap>
#include <QList>
#include <QMetaType>
#include <QDebug>

#include "KeyboardManager.h"
#include "SentenceManager.h"

#define EXPERIMENT false
#define ENGLISH true

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setOrganizationName("Boston University");
    app.setOrganizationDomain("cs.bu.edu");
    app.setApplicationName("KeyEye");

    int retval;
    ExperimentManager expManager;

    if (EXPERIMENT)
    {
        QQmlApplicationEngine engineSetup;
        engineSetup.load(QUrl(QStringLiteral("qrc:/setup.qml")));

        QObject::connect(engineSetup.rootObjects()[0], SIGNAL(closed(QString, int, QString, bool, bool, bool)), &expManager, SLOT(setup(QString, int, QString, bool, bool, bool)));

        retval = app.exec();

        if (!expManager.isValid()) {
            qDebug() << "No valid participant data provided";
            return 0;
        }
    }

    SentenceManager sentenceManager(expManager.getParticipantDir(), ENGLISH);

    QQmlApplicationEngine engineKeyboard;
    QQmlContext *context = engineKeyboard.rootContext();
    context->setContextProperty("expManager", &expManager);
    engineKeyboard.load(QUrl(QStringLiteral("qrc:/main.qml")));

    qRegisterMetaType<SamplePoint>("SamplePoint");

    QObject *root = engineKeyboard.rootObjects()[0];
    KeyboardManager keyboardManager(root, ENGLISH);

    context->setContextProperty("predictor", &keyboardManager.getPredictor());
    context->setContextProperty("pointerManager", &keyboardManager.getPointerManager());
    QMetaObject::invokeMethod(root, "connectPointerManager");
    root->setProperty("isExperiment", EXPERIMENT);
    root->setProperty("dwellKeyboard", !expManager.usingGestures());
    root->setProperty("showTutorial", expManager.shouldShowTutorial());
    root->setProperty("phoneLayout", expManager.shouldUsePhoneLayout());
    root->setProperty("isEnglish", ENGLISH);
    context->setContextProperty("sentenceManager", &sentenceManager);

    QObject::connect(root, SIGNAL(paused(bool)), &expManager, SLOT(logPaused(bool)));
    QObject::connect(root, SIGNAL(paused(bool)), &keyboardManager, SLOT(toggleConnections(bool)));
    if (!root->property("isPaused").toBool())
    {
        keyboardManager.toggleConnections(false);
    }

    if (EXPERIMENT)
    {
        QObject::connect(&keyboardManager.getPointerManager(), SIGNAL(newSample(QPointF, double)), &expManager, SLOT(logSample(QPointF,double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(toggleGesture(QString, double)), &expManager, SLOT(logToggleGesture(QString, double)));
        QObject::connect(keyboardManager.getTypingManager(), SIGNAL(keystroke(QString)), &expManager, SLOT(logKeystroke(QString)));
        QObject::connect(keyboardManager.getBackspaceKey(), SIGNAL(cancelGesture()), &expManager, SLOT(logGestureCanceled()));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(newWord(QString)), &expManager, SLOT(logNewWord(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(wordDeleted(QString)), &expManager, SLOT(logWordRemoved(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(spaceAdded()), &expManager, SLOT(logSpaceAdded()));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(charAdded(QString)), &expManager, SLOT(logCharAdded(QString)));
        QObject::connect(keyboardManager.getTextField(), SIGNAL(candidateChanged(QString)), &expManager, SLOT(logCandidateChanged(QString)));
        QObject::connect(&keyboardManager.getPredictor(), SIGNAL(newWordCandidates(QStringList)), &expManager, SLOT(logCandidates(QStringList)));
    }

    // Hide cursor
    QPixmap nullCursor(16, 16);
    nullCursor.fill(Qt::transparent);
    app.setOverrideCursor(QCursor(nullCursor));

    retval = app.exec();

    return retval;
}
