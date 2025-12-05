/**
* Copyright (c) 2025 Project DVN
*/
module dvn.tools;

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

import std.algorithm : min, max;
import std.utf : byDchar;
import std.array : array;

int computeLevenshteinDistance(dchar[] s1, dchar[] s2)
{
    size_t len1 = s1.length;
    size_t len2 = s2.length;

    if (len1 == 0) return cast(int)len2;
    if (len2 == 0) return cast(int)len1;

    auto matrix = new int[][](len1 + 1, len2 + 1);

    foreach (i; 0 .. len1 + 1)
        matrix[i][0] = cast(int)i;

    foreach (j; 0 .. len2 + 1)
        matrix[0][j] = cast(int)j;

    foreach (i; 1 .. len1 + 1)
    {
        foreach (j; 1 .. len2 + 1)
        {
            int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;

            int deletion      = matrix[i - 1][j]     + 1;
            int insertion     = matrix[i][j - 1]     + 1;
            int substitution  = matrix[i - 1][j - 1] + cost;

            matrix[i][j] = min(min(deletion, insertion), substitution);
        }
    }

    return matrix[len1][len2];
}

int computeLevenshteinDistance(string source1, string source2)
{
    auto s1 = source1.byDchar.array;
    auto s2 = source2.byDchar.array;

    return computeLevenshteinDistance(s1, s2);
}

double levenshteinSimilarity(string source1, string source2)
{
    if (source1 is null) source1 = "";
    if (source2 is null) source2 = "";

    if (source1 == source2) return 1.0;

    auto s1 = source1.byDchar.array;
    auto s2 = source2.byDchar.array;

    if (s1.length == 0 || s2.length == 0)
        return 0.0;

    int steps = computeLevenshteinDistance(s1, s2);

    auto longest = cast(double) max(s1.length, s2.length);

    return 1.0 - (cast(double)steps / longest);
}

