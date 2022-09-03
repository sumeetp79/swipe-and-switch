#include <QDebug>
#include <QThread>
#include <QMetaObject>
#include <QVariant>

#include "PointerManager.h"

PointerManager::PointerManager(QObject *root, QObject *pointer, bool filtering) :
    QObject(root), root(root), pointer(pointer), filtering(filtering), dist(0, 50)
{}

PointerManager::~PointerManager()
{}

void PointerManager::updatePointer(SamplePoint newPosition)
{
    newPosition.value = mapToWindow(newPosition.value);
    if (false) newPosition.value += QPointF(dist(generator), dist(generator));
    if (filtering)
    {
        samples.push_back(newPosition);
        QMutableListIterator<SamplePoint> it(samples);
        while (it.hasNext())
        {
            if (newPosition.tstamp - it.next().tstamp > 50) it.remove();
        }
        newPosition.value = filteredSample();
    }
    emit newSample(newPosition.value, newPosition.tstamp);
    if (pointer->property("active").toBool())
    {
        pointer->setProperty("centerX", newPosition.value.x());
        pointer->setProperty("centerY", newPosition.value.y());
    }
}

void PointerManager::setIsMouse(bool isMouse)
{
    filtering = !isMouse;
}

QPointF PointerManager::mapToWindow(QVariant globalPosition)
{
    QVariant windowCursor;
    QMetaObject::invokeMethod(root, "mapToWindow", Q_RETURN_ARG(QVariant, windowCursor), Q_ARG(QVariant, globalPosition));
    return windowCursor.toPointF();
}

QPointF PointerManager::filteredSample()
{
    /*QList<double> xs;
    QList<double> ys;
    foreach (SamplePoint p, samples)
    {
        xs.append(p.value.x());
        ys.append(p.value.y());
    }
    qSort(xs);
    qSort(ys);
    double x, y;
    if (samples.size() % 2 == 0)
    {
        x = (xs[samples.size() / 2] + xs[samples.size() / 2 - 1]) / 2;
        y = (ys[samples.size() / 2] + ys[samples.size() / 2 - 1]) / 2;
    }
    else
    {
        x = xs[samples.size() / 2];
        y = ys[samples.size() / 2];
    }
    return QPointF(x, y);*/
    double x = 0;
    double y = 0;
    foreach (SamplePoint p, samples)
    {
        x += p.value.x();
        y += p.value.y();
    }
    return QPointF(x / samples.size(), y / samples.size());
}
