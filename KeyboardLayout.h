#ifndef KEYBOARDLAYOUT_H
#define KEYBOARDLAYOUT_H

#include <QObject>
#include <QStringList>
#include <QPointF>
#include <QMap>
#include <string>

struct Button
{
    Button();
    Button(QObject *button);
    QObject *button;
    bool valid, rotated;
    double x, y, width, height;
    QString text;
    QStringList gridText;

    QPointF center();
    QPointF letterPos(char letter);
};

struct KeyboardButton : public Button
{
    KeyboardButton();
    KeyboardButton(QObject *button, char value);
    char value;
};

class KeyboardLayout : public QObject
{
    Q_OBJECT
public:
    KeyboardLayout(QObject *root);
    QList<QPointF> idealPathFor(std::string word);
    double keySize();

private slots:
    void setUpdateNeeded();

private:
    QObject *root;
    QObject *pEyeMenu;
    QMap<char, KeyboardButton> buttons;
    bool updateNeeded;

    void updateButtons();
};

#endif // KEYBOARDLAYOUT_H
