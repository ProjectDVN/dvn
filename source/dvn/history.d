/**
* Copyright (c) 2025 Project DVN
*/
module dvn.history;

import dvn.meta;

mixin CreateCustomException!"DialogueHistoryException";

public final class DialogueHistory
{
    public:
    final:
    string text;
    string[] options;
    string sceneName;
    string sceneBackground;
    string sceneMusic;
}

private DialogueHistory[] _history;
private bool[string] _historyKeys;

void loadDialogueHistory()
{
    import std.file : readText, exists;
    import dvn.json;

    if (!exists("data/game/history.json"))
    {
        _history = [];
        return;
    }

    string text = readText("data/game/history.json");
    string[] errorMessages;
    DialogueHistory[] history;
    if (!deserializeJsonSafe!(DialogueHistory[])(text, history, errorMessages))
    {
        throw new DialogueHistoryException(errorMessages[0]);
    }

    _history = history;

    foreach (h; _history)
    {
        _historyKeys[h.sceneName] = true;
    }
}

void addDialogueHistory(string text, string[] options, string sceneName, string sceneBackground, string sceneMusic)
{
    if (_historyKeys && (sceneName in _historyKeys))
    {
        return;
    }

    auto history = new DialogueHistory;
    history.text = text;
    history.options = options;
    history.sceneName = sceneName;
    history.sceneBackground = sceneBackground;
    history.sceneMusic = sceneMusic;

    _historyKeys[history.sceneName] = true;
    _history ~= history;

    import std.file : write;
    import dvn.json;

    string serializedJson;
    if (!serializeJsonSafe(_history, serializedJson, true))
    {
        return;
    }

    write("data/game/history.json", serializedJson);
}

DialogueHistory[] searchDialogueHistory(string input)
{
    import std.algorithm : canFind;
    import std.uni : toLower;
    import std.string : strip;

    DialogueHistory[] results = [];

    if (!input || !input.strip.length)
    {
        return _history ? _history : [];
    }

    foreach (h; _history)
    {
        if (h.text && h.text.toLower.canFind(input.toLower))
        {
            results ~= h;
        }
        else if (h.options)
        {
            foreach (o; h.options)
            {
                if (o && o.toLower.canFind(input.toLower))
                {
                    results ~= h;
                    break;
                }
            }
        }
    }

    return results;
}