#ifndef TRIE_H
#define TRIE_H

#include <map>
#include <set>
#include <string>
#include <QFile>
#include <QList>

struct WordOccurences
{
    WordOccurences(std::string word, long occurences);
    std::string word;
    long occurences;
};

class WordOccurencesList
{
public:
    WordOccurencesList();
    WordOccurencesList(QList<WordOccurences> wordOccurences);
    QList<std::string> getWords();
    long getOccurencesFor(std::string word);
    QList<WordOccurences> &getList();

private:
    QList<WordOccurences> wordOccurences;
};

class Trie
{
public:
    Trie();
    Trie(QFile &wordList, char delimiter = ',', int wordIdx = 0, int freqIdx = 1);
    ~Trie();
    void load(QFile &wordList);
    void loadCsv(QFile &wordList, char delimiter = ',', int wordIdx = 0, int freqIdx = 1, bool occurencesOnly = false);
    void addWord(const std::string &word, long occurences = 1);
    void removeOccurence(const std::string &word);
    bool contains(const std::string &word);
    long getOccurencesFor(const std::string &word);
    WordOccurencesList findWordsWithStartAndEnd(char start, char end);
private:
    class Node
    {
    public:
        Node();
        Node(char value);
        ~Node();
        char getValue();
        void setWord(bool word);
        bool isWord();
        long getOccurences();
        Node *getChildAt(char pos);
        void addChild(Node *child);
        void addWordEnd(char end);
        void addOccurences(long occurences);
        bool hasChildWithEnd(char end);
        QList<char> getChildrenFirstLetter();

    private:
        char value;
        bool word;
        long occurences;
        std::map<char, Node*> children;
        std::set<char> wordEndings;
    };

    Node *root;
    QList<WordOccurences> findWordsWithStartAndEnd(Node *current, char end, std::string word);
    Node *findNodeFor(const std::string &word, bool createIfNotFound = false, bool addWordEnd = false);
};

#endif // TRIE_H
