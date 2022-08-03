#include <QDebug>
#include <QFile>
#include <math.h>
#include <limits>

#include "WordPredictor.h"
#include "QPointFUtil.h"

WordPredictor::WordPredictor(QObject *parent, KeyboardLayout &layout, QObject *typingManager, bool isEnglish) :
    QObject(parent), layout(layout), typing(false), fixationThreshold(10), typingManager(typingManager), filteredShape(parent->findChild<QObject*>("filteredShape")), idealPath(parent->findChild<QObject*>("idealPath"))
{
    QString wordFilename = ":/resources/words_mck.txt";
    QString wordFreqFilename = ":/resources/wikipedia_wordfreq.csv";
    if (!isEnglish)
    {
        wordFilename = ":/resources/palavras.txt";
        wordFreqFilename = ":/resources/palavras-freq.csv";
    }
    QFile wordList(wordFilename);
    QFile wordFreqList(wordFreqFilename);
    trie.load(wordList);
    trie.loadCsv(wordFreqList, '\t', 0, 1, true);
    exceptions.append("we");
    exceptions.append("yes");
    exceptions.append("let");
    exceptions.append("us");
    exceptions.append("get");
}

bool WordPredictor::isTyping()
{
    return typing;
}

void WordPredictor::onNewSample(QPointF point, double tstamp)
{
    if (typing)
    {
        samples.append(SamplePoint(tstamp, point));
    }
}

struct WordScore
{
    WordScore(WordOccurences wordOccurence, double score) :
        word(wordOccurence.word),
        occurences(wordOccurence.occurences),
        score(score),
        initialized(false)
    {}

    std::string word;
    double occurences;
    double score;
    double occurenceProb;
    double gestureProb;

    void initProbs(double totalOccurences, double totalScores)
    {
        occurenceProb = occurences / totalOccurences;
        gestureProb = score / totalScores;
        initialized = true;
    }

    double prob() const
    {
        if (initialized) return 0.05 * occurenceProb + 0.95 * gestureProb;
        qDebug() << "Score used without initialization:" << QString::fromStdString(word) << score << occurences;
        return 0;
    }

private:
    bool initialized;
};

bool compareScoresByScore(const WordScore &score1, const WordScore &score2)
{
    return score1.score > score2.score;
}

bool compareScoresByProb(const WordScore &score1, const WordScore &score2)
{
    return score1.prob() > score2.prob();
}

void WordPredictor::onGestureToggled(QString letter, double timestamp)
{
    typing = !typingManager->property("isStart").toBool();
    if (typing)
    {
        startLetter = letter[0].toLower().toLatin1();
    }
    else
    {
        QStringList wordCandidates = getCandidates(letter, timestamp, true);
        qDebug() << "";
        if (wordCandidates.length() > 0)
            emit newWordCandidates(wordCandidates);
        samples.clear();
    }
}

void WordPredictor::onKeystroke(QString letter)
{
    emit newLetter(letter[0].toLower());
}

void WordPredictor::onGestureCanceled()
{
    typing = false;
    samples.clear();
}

void WordPredictor::addWordToLexicon(QString newWord)
{
    trie.addWord(newWord.toStdString());
}

void WordPredictor::removeWordOccurence(QString deletedWord)
{
    trie.removeOccurence(deletedWord.toStdString());
}

QStringList WordPredictor::getCandidates(QString lastLetter, double timestamp, bool debuging)
{
    QStringList wordCandidates;
    QList<WordScore> wordScores;
    // Sanity check
    if (samples.length() <= 1) return wordCandidates;

    // Remove samples that occurred after the final timestamp or that are too far from the others (saccade or noise)
    QList<QPointF> samplePoints = filterSamples(timestamp);
    if (debuging)
    {
        /*QVariantList pts;
        foreach (QPointF pt, samplePoints) {
            pts.append(pt);
        }
        filteredShape->setProperty("points", pts);

        QList<QPointF> testingIdealPath = layout.idealPathFor("segments");
        qDebug() << testingIdealPath;
        pts.clear();
        foreach (QPointF pt, testingIdealPath) {
            pts.append(pt);
        }
        idealPath->setProperty("points", pts);*/
    }

    // Test all possible words against the given path
    WordOccurencesList wordOccurences = trie.findWordsWithStartAndEnd(startLetter, lastLetter[0].toLower().toLatin1());
    double subsampleStep = 100;
    samplePoints = subsample(samplePoints, subsampleStep);
    foreach (WordOccurences wordOccurence, wordOccurences.getList())
    {
        QList<QPointF> points = subsample(layout.idealPathFor(wordOccurence.word), subsampleStep);
        wordScores.append(WordScore(wordOccurence, computeScore(samplePoints, points)));
    }
    qSort(wordScores.begin(), wordScores.end(), compareScoresByScore);
    wordScores = wordScores.mid(0, 10);

    // Compute totals from top-10 candidates
    double totalScores = 0;
    long totalOccurences = 0;
    bool isException = false;
    foreach (WordScore wordScore, wordScores)
    {
        if (exceptions.contains(QString::fromStdString(wordScore.word))) isException = true;
        totalScores += wordScore.score;
        totalOccurences += wordScore.occurences;
    }

    // Transform occurences and scores in probabilities
    for (QList<WordScore>::iterator it = wordScores.begin(); it != wordScores.end(); it++)
    {
        it->initProbs(totalOccurences, totalScores);
    }
    // If is exception we only sort by score
    if (!isException) qSort(wordScores.begin(), wordScores.end(), compareScoresByProb);

    foreach (WordScore wordScore, wordScores)
    {
        wordCandidates.append(QString::fromStdString(wordScore.word));
        if (debuging)
        {
            qDebug() << QString::fromStdString(wordScore.word) << wordScore.gestureProb << wordScore.occurenceProb << wordScore.prob();
        }
    }
    return wordCandidates;
}

void WordPredictor::updateTyping(bool isTyping)
{
    typing = isTyping;
}

QList<QPointF> WordPredictor::filterSamples(double timestamp)
{
    QList<QPointF> fixations;
    QList<QPointF> curFix;
    curFix.append(samples[0].value);
    for (int i = 1; i < samples.length(); i++)
    {
        if (samples[i].tstamp > timestamp)
            break;
        QPointF fixCenter = QPointFUtil::mean(curFix);
        if (QPointFUtil::distance(fixCenter, samples[i].value) > fixationThreshold)
        {
            fixations.append(fixCenter);
            curFix.clear();
        }
        curFix.append(samples[i].value);
    }
    fixations.append(QPointFUtil::mean(curFix));

    return fixations;
}

// Based in code from: https://gist.github.com/MaxBareiss/ba2f9441d9455b56fbc9
// From paper: http://www.kr.tuwien.ac.at/staff/eiter/et-archive/cdtr9464.pdf
double c(double **ca, int i, int j, QList<QPointF> &P, QList<QPointF> &Q)
{
    if (ca[i][j] > -1) return ca[i][j];
    else if (i == 0 && j == 0) ca[i][j] = QPointFUtil::distance(P[0],Q[0]);
    else if (i > 0 && j == 0) ca[i][j] = std::max(c(ca,i-1,0,P,Q), QPointFUtil::distance(P[i],Q[0]));
    else if (i == 0 && j > 0) ca[i][j] = std::max(c(ca,0,j-1,P,Q), QPointFUtil::distance(P[0],Q[j]));
    else if (i > 0 && j > 0) ca[i][j] = std::max(std::min(std::min(c(ca,i-1,j,P,Q), c(ca,i-1,j-1,P,Q)), c(ca,i,j-1,P,Q)), QPointFUtil::distance(P[i],Q[j]));
    else ca[i][j] = std::numeric_limits<double>::max();
    return ca[i][j];
}

double WordPredictor::computeScore(QList<QPointF> &samplePoints, QList<QPointF> &idealPoints)
{
    double **ca = new double*[samplePoints.size()];
    for (int i = 0; i < samplePoints.size(); i++)
    {
        ca[i] = new double[idealPoints.size()];
        for (int j = 0; j < idealPoints.size(); j++)
        {
            ca[i][j] = -1;
        }
    }
    double score = 1/(1+c(ca,samplePoints.size()-1,idealPoints.size()-1,samplePoints,idealPoints));

    for (int i = 0; i < samplePoints.size(); i++)
        delete ca[i];
    delete ca;

    return score;
    /*QList<double> dtw;
    double INFTY = std::numeric_limits<double>::max();
    for (int i = 0; i < idealPoints.length() + 1; i++) dtw << INFTY;
    dtw[0] = 0;
    QList<double> dtw1(dtw);
    for (int i = 1; i <= samplePoints.length(); i++)
    {
        dtw1[0] = INFTY;
        for (int j = 1; j <= idealPoints.length(); j++)
        {
            double cost = QPointFUtil::distance(samplePoints[i-1], idealPoints[j-1]);
            dtw1[j] = cost + std::min(std::min(dtw[j],     // insertion
                                               dtw1[j-1]), // deletion
                                               dtw[j-1]);  // match
        }
        dtw = dtw1;
    }
    return 1 / (1 + dtw[idealPoints.length()]);*/
}

char WordPredictor::getButtonValue(QObject *button)
{
    return button->objectName().at(0).toLower().toLatin1();
}

QList<QPointF> WordPredictor::subsample(QList<QPointF> points, double step)
{
    QList<QPointF> subsampled;
    for (int i = 0; i < points.size(); i++)
    {
        QPointF cur = points[i];
        subsampled.append(cur);
        if (i < points.size() - 1)
        {
            QPointF next = points[i+1];
            double dist = QPointFUtil::distance(cur, next);
            QPointF direction = next - cur;
            direction /= dist;
            for (double alpha = step; alpha < dist; alpha += step)
            {
                subsampled.append(cur + direction * alpha);
            }
        }
    }
    return subsampled;
}
