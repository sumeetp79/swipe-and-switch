#include <QTextStream>
#include <QDebug>

#include "Trie.h"

// WordOccurences

WordOccurences::WordOccurences(std::string word, long occurences) :
    word(word), occurences(occurences)
{
}

// WordOccurencesList

WordOccurencesList::WordOccurencesList()
{
}

WordOccurencesList::WordOccurencesList(QList<WordOccurences> wordOccurences) :
    wordOccurences(wordOccurences)
{
}

QList<std::string> WordOccurencesList::getWords()
{
    QList<std::string> words;
    foreach (WordOccurences wo, wordOccurences)
    {
        words.append(wo.word);
    }
    return words;
}

long WordOccurencesList::getOccurencesFor(std::string word)
{
    foreach (WordOccurences wo, wordOccurences)
    {
        if (wo.word == word) return wo.occurences;
    }
    return 0;
}

QList<WordOccurences>& WordOccurencesList::getList()
{
    return wordOccurences;
}

// Trie

Trie::Trie() : root(new Node)
{
}

Trie::Trie(QFile &wordList, char delimiter, int wordIdx, int freqIdx) : root(new Node)
{
    if (wordList.fileName().endsWith("csv"))
        loadCsv(wordList, delimiter, wordIdx, freqIdx);
    else
        load(wordList);
}

Trie::~Trie()
{
    delete root;
}

void Trie::load(QFile &wordList)
{
    if (wordList.open(QIODevice::ReadOnly))
    {
        QTextStream in(&wordList);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            addWord(line.trimmed().toStdString());
        }
        wordList.close();
    }
}

void Trie::loadCsv(QFile &wordList, char delimiter, int wordIdx, int freqIdx, bool occurencesOnly)
{
    if (wordList.open(QIODevice::ReadOnly))
    {
        QTextStream in(&wordList);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            QStringList row = line.split(delimiter);
            std::string word = row[wordIdx].trimmed().toStdString();
            if (!occurencesOnly || contains(word))
            {
                addWord(word, row[freqIdx].trimmed().toLong());
            }
        }
        wordList.close();
    }
}

void Trie::addWord(const std::string &word, long occurences)
{
    Node *node = findNodeFor(word, true, true);
    if (node)
    {
        node->addOccurences(occurences);
        node->setWord(true);
    }
}

void Trie::removeOccurence(const std::string &word)
{
    Node *node = findNodeFor(word);
    if (node) node->addOccurences(-1);
}

bool Trie::contains(const std::string &word)
{
    Node *node = findNodeFor(word);
    return node && node->isWord();
}

long Trie::getOccurencesFor(const std::string &word)
{
    Node *node = findNodeFor(word);
    if (node) return node->getOccurences();
    return 0;
}

WordOccurencesList Trie::findWordsWithStartAndEnd(char start, char end)
{
    start = tolower(start);
    end = tolower(end);
    Node *startNode = root->getChildAt(start);
    if (startNode == NULL) return WordOccurencesList();
    QList<WordOccurences> occurences = findWordsWithStartAndEnd(startNode, end, std::string() + start);
    if (start == end && startNode->isWord()) occurences.append(WordOccurences(std::string() + start, startNode->getOccurences()));
    return WordOccurencesList(occurences);
}

QList<WordOccurences> Trie::findWordsWithStartAndEnd(Node *current, char end, std::string word)
{
    QList<WordOccurences> words;
    if (current == NULL) return words;
    QList<char> firstLetters = current->getChildrenFirstLetter();
    foreach (char firstLetter, firstLetters)
    {
        Node *child = current->getChildAt(firstLetter);
        if (child != NULL && child->hasChildWithEnd(end))
        {
            if (child->getValue() == end && child->isWord()) words.append(WordOccurences(word + child->getValue(), child->getOccurences()));
            words.append(findWordsWithStartAndEnd(child, end, word + child->getValue()));
        }
    }
    return words;
}

Trie::Node* Trie::findNodeFor(const std::string &word, bool createIfNotFound, bool addWordEnd)
{
    Node *current = root;
    if (word.length() == 0) return NULL;

    char wordEnd = tolower(*(word.end()-1));
    for (unsigned i = 0; i < word.length(); i++)
    {
        char c = tolower(word[i]);
        Node *child = current->getChildAt(c);
        if (child == NULL)
        {
            if (createIfNotFound)
            {
                child = new Node(c);
                current->addChild(child);
            }
            else
            {
                return NULL;
            }
        }
        else if (!createIfNotFound && !child->hasChildWithEnd(wordEnd)) return NULL;
        if (addWordEnd) child->addWordEnd(wordEnd);
        current = child;
    }
    return current;
}

// Trie::Node

Trie::Node::Node() : word(false), occurences(0)
{}

Trie::Node::Node(char value) : value(value), word(false), occurences(0)
{}

Trie::Node::~Node()
{
    for (auto it = children.cbegin(); it != children.cend();)
    {
        Node *node = it->second;
        children.erase(it++);
        delete node;
    }
}

char Trie::Node::getValue()
{
    return value;
}

void Trie::Node::setWord(bool word)
{
    this->word = word;
}

bool Trie::Node::isWord()
{
    return word;
}

long Trie::Node::getOccurences()
{
    return occurences;
}

Trie::Node *Trie::Node::getChildAt(char pos)
{
    auto it = children.find(pos);
    if (it == children.end()) return NULL;
    return it->second;
}

void Trie::Node::addChild(Trie::Node *child)
{
    children[child->getValue()] = child;
}

void Trie::Node::addWordEnd(char end)
{
    wordEndings.insert(end);
}

void Trie::Node::addOccurences(long occurences)
{
    this->occurences += occurences;
    if (this->occurences < 1) this->occurences = 1;
}

bool Trie::Node::hasChildWithEnd(char end)
{
    return wordEndings.find(end) != wordEndings.end();
}

QList<char> Trie::Node::getChildrenFirstLetter()
{
    QList<char> firstLetters;
    for (auto it = children.begin(); it != children.end(); it++)
    {
        firstLetters.push_back(it->first);
    }
    return firstLetters;
}
