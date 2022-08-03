#include <algorithm>
#include <ctime>
#include <cstdlib>
#include <QTextStream>

#include "SentenceManager.h"

SentenceManager::SentenceManager(QDir participantDir, bool isEnglish, QObject *parent) :
    QObject(parent),
    usedSentencesFile(participantDir.absoluteFilePath("usedSentences.txt"))
{
    QString filename = ":/resources/sentencesEN.txt";
    if (!isEnglish) filename = ":/resources/sentencesPT.txt";
    QFile sentencesFile(filename);
    if (sentencesFile.open(QIODevice::ReadOnly))
    {
        QTextStream in(&sentencesFile);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QString sentence = line.trimmed();
            sentences.append(sentence);
        }
        sentencesFile.close();

        std::srand(unsigned(std::time(0)));
        std::random_shuffle(sentences.begin(), sentences.end());
    }

    if (usedSentencesFile.exists() && usedSentencesFile.open(QIODevice::ReadOnly))
    {
        QTextStream in(&usedSentencesFile);
        while (!in.atEnd())
        {
            QString sentence = in.readLine().trimmed();
            sentences.removeAll(sentence);
        }
    }
    usedSentencesFile.close();
}

SentenceManager::~SentenceManager()
{
    if (usedSentencesFile.open(QIODevice::Append))
    {
        QTextStream out(&usedSentencesFile);
        foreach(QString sentence, usedSentences)
        {
            out << sentence << '\n';
        }
    }
}

QString SentenceManager::randomSentence()
{
    if (sentences.isEmpty()) return "";
    QString sentence = sentences.first();
    sentences.removeFirst();
    usedSentences.push_back(sentence);
    return sentence;
}
