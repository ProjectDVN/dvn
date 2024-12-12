module zid.tools;

import std.datetime : SysTime, Duration, DateTime, UTC, dur;

long timeToTimestamp(SysTime time)
{
    Duration unixTime = time - SysTime(DateTime(1970, 1, 1), UTC());
    
    long milliseconds = unixTime.total!"msecs";
    
    return milliseconds;
}

SysTime timestampToTime(long milliseconds)
{
    auto baseTime = SysTime(DateTime(1970, 1, 1), UTC());
    
    auto time = baseTime + dur!"msecs"(milliseconds);
    
    return time;
}