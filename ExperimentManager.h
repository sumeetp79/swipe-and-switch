#ifndef EXPERIMENTMANAGER_H
#define EXPERIMENTMANAGER_H

#include <QObject>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QPointF>

class ExperimentManager : public QObject
{
    Q_OBJECT
public:
    ExperimentManager(QObject *parent = 0);
    ~ExperimentManager();
    bool isValid();
    bool shouldUsePhoneLayout();
    bool shouldShowTutorial();
    QDir getParticipantDir();
    Q_INVOKABLE void startExperiment();
    Q_INVOKABLE void stopExperiment();
    Q_INVOKABLE double getTimestamp();
    bool usingGestures();
    Q_INVOKABLE double sessionEllapsedTime();
    Q_INVOKABLE int getCurrentSessionID();
    Q_INVOKABLE int getTotalSessions();
    Q_INVOKABLE bool ended();
    Q_INVOKABLE bool shouldShowCandidate();

public slots:
    void setup(QString dataFolder, int sessions, QString pid, bool useGestures, bool showTutorial, bool showCandidate);
    void logSample(QPointF sample, double timestamp);
    void logKeyPos(QString key, QPointF pos, QPointF size);
    void logKeySelected(QString key);
    void logKeyClicked(QString key);
    void logKeyOut(QString key);
    void logToggleGesture(QString letter, double timestamp);
    void logKeystroke(QString letter);
    void logGestureCanceled();
    void logNewWord(QString newWord);
    void logWordRemoved(QString removedWord);
    void logCandidates(QStringList candidates);
    void logSpaceAdded();
    void logCharAdded(QString newChar);
    void logCandidateChanged(QString newCandidate);
    void logExpectedSentence(QString expectedSentence);
    void logTypedSentence(QString typedSentence);
    void logUsingDwell(bool usingDwell);
    void logPaused(bool isPaused);
    void newSession();

private:
    QString dataFolder;
    QString pid;
    QDir participantDir;
    QDir sessionsDir;
    QDir modeDir;
    QDir currentSessionDir;
    QFile sessionCreations;
    QFile gazeLog;
    QTextStream gazeLogStream;
    QFile keyPosLog;
    QTextStream keyPosLogStream;
    QFile eventLog;
    QTextStream eventLogStream;
    bool started;
    bool useGestures;
    bool usePhone;
    bool showTutorial;
    bool showCandidate;
    double t0;
    double pausedT0;
    double pausedTime;
    int totalSessions;
    int sessionCount;

    void openAndSetStream(QString path, QFile &file, QTextStream &stream);
    void logEvent(QString eventID, double timestamp, QString data = "");
    void closeLogFiles();
    double getPausedTime();
};

#endif // EXPERIMENTMANAGER_H
