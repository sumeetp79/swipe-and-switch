#ifndef SAMPLEPOINT_H
#define SAMPLEPOINT_H

#include <QPointF>

struct SamplePoint
{
    SamplePoint() : tstamp(-1) {}
    SamplePoint(double tstamp, QPointF value) :
        tstamp(tstamp), value(value) {}
    double tstamp;
    QPointF value;

    SamplePoint& operator+=(const SamplePoint &rhs)
    {
        tstamp = std::min(tstamp, rhs.tstamp);
        value += rhs.value;
        return *this;
    }
    SamplePoint& operator-=(const SamplePoint &rhs)
    {
        tstamp = std::min(tstamp, rhs.tstamp);
        value -= rhs.value;
        return *this;
    }
    SamplePoint& operator/=(const qreal &rhs)
    {
        value /= rhs;
        return *this;
    }
};

inline SamplePoint operator+(SamplePoint lhs, SamplePoint rhs)
{
    return SamplePoint(std::min(lhs.tstamp, rhs.tstamp), lhs.value + rhs.value);
}
inline SamplePoint operator-(SamplePoint lhs, SamplePoint rhs)
{
    return SamplePoint(std::min(lhs.tstamp, rhs.tstamp), lhs.value - rhs.value);
}
inline SamplePoint operator/(SamplePoint lhs, qreal rhs)
{
    return SamplePoint(lhs.tstamp, lhs.value / rhs);
}

#endif // SAMPLEPOINT_H
