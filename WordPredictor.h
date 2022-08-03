#ifndef WORDPREDICTOR_H
#define WORDPREDICTOR_H

#include <QObject>
#include <QList>

#include "KeyboardLayout.h"
#include "SamplePoint.h"
#include "Trie.h"

class WordPredictor : public QObject
{
    Q_OBJECT
public:
    WordPredictor(QObject *parent, KeyboardLayout &layout, QObject *typingManager, bool isEnglish);
    bool isTyping();

signals:
    void newLetter(QChar letter);
    void newWordCandidates(QStringList string);

public slots:
    void onNewSample(QPointF point, double tstamp);
    void onGestureToggled(QString letter, double timestamp);
    void onKeystroke(QString letter);
    void onGestureCanceled();
    void addWordToLexicon(QString newWord);
    void removeWordOccurence(QString deletedWord);
    Q_INVOKABLE QStringList getCandidates(QString lastLetter, double timestamp, bool debuging = false);
    void updateTyping(bool isTyping);

private:
    KeyboardLayout &layout;
    bool typing;
    Trie trie;
    char startLetter;
    QList<SamplePoint> samples;
    double fixationThreshold;
    QObject *typingManager;
    QObject *filteredShape;
    QObject *idealPath;
    QStringList exceptions;

    QList<QPointF> filterSamples(double timestamp);
    double computeScore(QList<QPointF> &samplePoints, QList<QPointF> &idealPoints);
    char getButtonValue(QObject *button);
    QList<QPointF> subsample(QList<QPointF> points, double step);
};

#endif // WORDPREDICTOR_H
