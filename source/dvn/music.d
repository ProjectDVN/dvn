/**
* Copyright (c) 2025 Project DVN
*/
module dvn.music;

import std.file : dirEntries, SpanMode;
import std.path : baseName, CaseSensitive;

import dvn.meta;

mixin CreateCustomException!"MusicException";

private string[string] _music;

void loadMusic(string path)
{
    if (!path || !path.length)
    {
        return;
    }

    import std.file : readText;
    import dvn.json;

    string text = readText(path);
    string[] errorMessages;
    string[string] music;
    if (!deserializeJsonSafe!(string[string])(text, music, errorMessages))
    {
        throw new MusicException(errorMessages[0]);
    }

    _music = music;
}

string getMusicPath(string music)
{
    if (!music)
    {
        return "";
    }

    return _music.get(music, "");
}