#include <QDateTime>
#include <QDebug>

#include "ExperimentManager.h"
#include "Timer.h"

#define KEY_SELECTED      "SEL"
#define KEY_CLICKED       "CLK"
#define KEY_OUT           "OUT"
#define TOGGLE_GESTURE    "GES"
#define KEYSTROKE         "STR"
#define GESTURE_CANCELED  "CAN"
#define NEW_WORD          "WRD"
#define WORD_REMOVED      "DEL"
#define CANDIDATES        "CND"
#define SPACE_ADDED       "SPC"
#define CHAR_ADDED        "CHR"
#define CANDIDATE_CHANGED "NCD"
#define EXPECTED_SENTENCE "EXP"
#define TYPED_SENTENCE    "TYP"
#define USING_DWELL       "DWL"
#define PAUSED            "PSD"
#define UNPAUSED          "UNP"

ExperimentManager::ExperimentManager(QObject *parent) :
    QObject(parent),
    started(false),
    useGestures(true),
    usePhone(false),
    showCandidate(true),
    t0(Timer::timestamp()),
    totalSessions(3),
    sessionCount(0)
{
}

ExperimentManager::~ExperimentManager()
{
    if (isValid())
    {
        closeLogFiles();
    }
}

bool ExperimentManager::isValid()
{
    return this->dataFolder.length() > 0 && this->pid.length() > 0;
}

bool ExperimentManager::shouldUsePhoneLayout()
{
    return this->usePhone && this->useGestures;
}

bool ExperimentManager::shouldShowTutorial()
{
    return this->showTutorial;
}

QDir ExperimentManager::getParticipantDir()
{
    return participantDir;
}

void ExperimentManager::startExperiment()
{
    newSession();
    started = true;
    t0 = Timer::timestamp();
    pausedT0 = -1;
    pausedTime = 0;
    sessionCount++;
}

void ExperimentManager::stopExperiment()
{
    closeLogFiles();
    started = false;
}

double ExperimentManager::getTimestamp()
{
    return Timer::timestamp();
}

bool ExperimentManager::usingGestures()
{
    return useGestures;
}

double ExperimentManager::sessionEllapsedTime()
{
    if (started) return Timer::timestamp() - t0 - getPausedTime();
    return 0;
}

int ExperimentManager::getCurrentSessionID()
{
    int id = 1;
    while (QDir(modeDir.absoluteFilePath(QString::fromStdString(std::to_string(id)))).exists()) id++;
    return id;
}

int ExperimentManager::getTotalSessions()
{
    return totalSessions;
}

bool ExperimentManager::ended()
{
    return sessionCount >= totalSessions;
}

bool ExperimentManager::shouldShowCandidate()
{
    return showCandidate;
}

void ExperimentManager::setup(QString dataFolder, int sessions, QString pid, bool useGestures, bool showTutorial, bool showCandidate)
{
    this->dataFolder = dataFolder;
    this->pid = pid;
    this->useGestures = useGestures;
    this->showTutorial = showTutorial;
    this->totalSessions = sessions;
    this->showCandidate = showCandidate;

    if (isValid())
    {
        QString mode = "dwell";
        if (useGestures) mode = "gesture";

        QDir data(dataFolder);
        participantDir.setPath(data.absoluteFilePath(pid));
        sessionsDir.setPath(participantDir.absoluteFilePath("sessions"));
        modeDir.setPath(sessionsDir.absoluteFilePath(mode));
        if (!modeDir.exists())
        {
            qDebug() << "Creating" << modeDir.path();
            modeDir.mkpath(".");
        }
    }
}

void ExperimentManager::logSample(QPointF sample, double timestamp)
{
    if (!isValid() || !started) return;
    gazeLogStream << timestamp << "," << sample.x() << "," << sample.y() << "\n";
}

void ExperimentManager::logKeyPos(QString key, QPointF pos, QPointF size)
{
    if (!isValid() || !started) return;
    keyPosLogStream << Timer::timestamp() << "," << key << "," << pos.x() << "," << pos.y() << "," << size.x() << "," << size.y() << "\n";
}

void ExperimentManager::logKeySelected(QString key)
{
    logEvent(KEY_SELECTED, Timer::timestamp(), key);
}

void ExperimentManager::logKeyClicked(QString key)
{
    logEvent(KEY_CLICKED, Timer::timestamp(), key);
}

void ExperimentManager::logKeyOut(QString key)
{
    logEvent(KEY_OUT, Timer::timestamp(), key);
}

void ExperimentManager::logToggleGesture(QString letter, double timestamp)
{
    logEvent(TOGGLE_GESTURE, timestamp, letter.toLower());
}

void ExperimentManager::logKeystroke(QString letter)
{
    logEvent(KEYSTROKE, Timer::timestamp(), letter.toLower());
}

void ExperimentManager::logGestureCanceled()
{
    logEvent(GESTURE_CANCELED, Timer::timestamp());
}

void ExperimentManager::logNewWord(QString newWord)
{
    logEvent(NEW_WORD, Timer::timestamp(), newWord);
}

void ExperimentManager::logWordRemoved(QString removedWord)
{
    logEvent(WORD_REMOVED, Timer::timestamp(), removedWord);
}

void ExperimentManager::logCandidates(QStringList candidates)
{
    logEvent(CANDIDATES, Timer::timestamp(), candidates.join(","));
}

void ExperimentManager::logSpaceAdded()
{
    logEvent(SPACE_ADDED, Timer::timestamp());
}

void ExperimentManager::logCharAdded(QString newChar)
{
    logEvent(CHAR_ADDED, Timer::timestamp(), newChar);
}

void ExperimentManager::logCandidateChanged(QString newCandidate)
{
    logEvent(CANDIDATE_CHANGED, Timer::timestamp(), newCandidate);
}

void ExperimentManager::logExpectedSentence(QString expectedSentence)
{
    logEvent(EXPECTED_SENTENCE, Timer::timestamp(), expectedSentence);
}

void ExperimentManager::logTypedSentence(QString typedSentence)
{
    logEvent(TYPED_SENTENCE, Timer::timestamp(), typedSentence);
}

void ExperimentManager::logUsingDwell(bool usingDwell)
{
    logEvent(USING_DWELL, Timer::timestamp(), usingDwell ? "1" : "0");
}

void ExperimentManager::logPaused(bool isPaused)
{
    double now = Timer::timestamp();
    if (isPaused)
    {
        pausedT0 = now;
        logEvent(PAUSED, now);
    }
    else
    {
        if (pausedT0 >= 0) pausedTime += now - pausedT0;
        pausedT0 = -1;
        logEvent(UNPAUSED, now);
    }
}

void ExperimentManager::newSession()
{
    int sessionID = getCurrentSessionID();
    currentSessionDir.setPath(modeDir.absoluteFilePath(QString::fromStdString(std::to_string(sessionID))));
    qDebug() << "Creating session folder" << currentSessionDir.path();

    sessionCreations.setFileName(sessionsDir.absoluteFilePath("sessions.csv"));
    if (sessionCreations.open(QIODevice::Append))
    {
        QTextStream stream(&sessionCreations);
        stream << QDateTime::currentDateTime().toString("MM-dd-yyyy: hh:mm:ss ") << currentSessionDir.path() << "\n";
    }

    currentSessionDir.mkpath(".");
    openAndSetStream(currentSessionDir.absoluteFilePath("gaze.csv"), gazeLog, gazeLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("keys.csv"), keyPosLog, keyPosLogStream);
    openAndSetStream(currentSessionDir.absoluteFilePath("events.csv"), eventLog, eventLogStream);
}

void ExperimentManager::openAndSetStream(QString path, QFile &file, QTextStream &stream)
{
    file.setFileName(path);
    if (file.open(QIODevice::WriteOnly))
    {
        stream.setDevice(&file);
    }
}

void ExperimentManager::logEvent(QString eventID, double timestamp, QString data)
{
    if (!isValid() || !started) return;
    if (data.length() > 0)
    {
        eventLogStream << timestamp << "," << eventID << "," << data << "\n";
    }
    else
    {
        eventLogStream << timestamp << "," << eventID << "\n";
    }
}

void ExperimentManager::closeLogFiles()
{
    if (gazeLog.isOpen()) gazeLog.close();
    if (keyPosLog.isOpen()) keyPosLog.close();
    if (eventLog.isOpen()) eventLog.close();
}

double ExperimentManager::getPausedTime() {
    if (pausedT0 < 0) return pausedTime;
    return pausedTime + Timer::timestamp() - pausedT0;
}
