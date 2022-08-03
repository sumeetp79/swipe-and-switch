#include <QVariant>
#include <QList>
#include <QMetaObject>
#include <QDebug>
#include <QTransform>

#include "KeyboardLayout.h"

// Button

Button::Button() :
    button(NULL),
    valid(false),
    x(-1),
    y(-1),
    width(-1),
    height(-1)
{}

Button::Button(QObject *button) :
    button(button),
    valid(button != NULL),
    rotated(valid ? button->property("rotated").toBool() : false),
    x(valid ? button->property("x").toDouble() : -1),
    y(valid ? button->property("y").toDouble() : -1),
    width(valid ? button->property("width").toDouble() : -1),
    height(valid ? button->property("height").toDouble() : -1),
    text(valid ? button->property("text").toString() : ""),
    gridText(valid ? button->property("gridText").toStringList() : QStringList())
{
}

QPointF Button::center()
{
    return QPointF(x + width / 2, y + height / 2);
}

QPointF Button::letterPos(char letter)
{
    return center();
    QVariant pos;
    QMetaObject::invokeMethod(button, "textPos", Q_RETURN_ARG(QVariant, pos), Q_ARG(QVariant, QString(letter)));
    return pos.toPointF();
}

// KeyboardButton

KeyboardButton::KeyboardButton() : value(0)
{}

KeyboardButton::KeyboardButton(QObject *button, char value) :
    Button(button),
    value(value)
{}

// KeyboardLayout

KeyboardLayout::KeyboardLayout(QObject *root) :
    QObject(root), root(root), pEyeMenu(NULL), updateNeeded(false)
{
    if (root != NULL)
    {
        updateButtons();
        connect(root, SIGNAL(resized()), this, SLOT(setUpdateNeeded()));
    }
}

QList<QPointF> KeyboardLayout::idealPathFor(std::string word)
{
    if (updateNeeded) updateButtons();
    QList<QPointF> points;
    foreach (char c, word)
    {
        points.append(buttons[tolower(c)].letterPos(tolower(c)));
    }
    return points;
}

double KeyboardLayout::keySize()
{
    return root->property("keySize").toDouble();
}

void KeyboardLayout::setUpdateNeeded()
{
    updateNeeded = true;
}

void KeyboardLayout::updateButtons()
{
    QVariantList objs = root->property("keyObjs").toList();
    foreach (QVariant button, objs)
    {
        QObject *btn=button.value<QObject*>();
        if (btn == NULL) continue;
        foreach(QChar c, btn->objectName().left(btn->objectName().length()-3))
        {
            KeyboardButton newButton(btn, c.toLower().toLatin1());
            buttons[newButton.value] = newButton;
            qDebug() << newButton.value << buttons[newButton.value].center();
        }
    }
    pEyeMenu = root->findChild<QObject*>("pEyeMenu");
    updateNeeded = false;
}
