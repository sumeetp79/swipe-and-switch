#ifndef POINTERCONTROL_H
#define POINTERCONTROL_H

#include <QObject>
#include <QList>
#include <random>

#include "SamplePoint.h"

class PointerManager : public QObject
{
    Q_OBJECT
public:
    PointerManager(QObject *root, QObject *pointer, bool filtering);
    ~PointerManager();

signals:
    void newSample(QPointF sample, double tstamp);

public slots:
    void updatePointer(SamplePoint newPosition);
    void setIsMouse(bool isMouse);

private:
    QObject *root;
    QObject *pointer;
    bool filtering;
    QList<SamplePoint> samples;

    QPointF mapToWindow(QVariant globalPosition);
    QPointF filteredSample();
    std::normal_distribution<double> dist;
    std::default_random_engine generator;
};

#endif // POINTERCONTROL_H
