#include <cmath>

#include "QPointFUtil.h"

double QPointFUtil::distance(QPointF p1, QPointF p2)
{
    QPointF disp = p2 - p1;
    return sqrt(QPointF::dotProduct(disp, disp));
}

QPointF QPointFUtil::mean(QList<QPointF> points)
{
    double totalX = 0;
    double totalY = 0;
    foreach(QPointF point, points)
    {
        totalX += point.x();
        totalY += point.y();
    }
    return QPointF(totalX/points.size(), totalY/points.size());
}
