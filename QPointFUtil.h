#ifndef QPOINTFUTIL_H
#define QPOINTFUTIL_H

#include <QPointF>
#include <QList>

class QPointFUtil
{
public:
    static double distance(QPointF p1, QPointF p2);
    static QPointF mean(QList<QPointF> points);
};

#endif // QPOINTFUTIL_H
