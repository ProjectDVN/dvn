/**
* Copyright (c) 2025 Project DVN
*/
module dvn.characters;

import dvn.resources;
import dvn.json;

import std.file : readText;

void loadCharacters(Resource[string] generalResources)
{
    auto text = readText("data/game/characters.json");

    string[] errorMessages;
    string[string][string] result;
    if (!deserializeJsonSafe!(string[string][string])(text, result, errorMessages))
    {
        throw new Exception(errorMessages[0]);
    }

    foreach (characterName,characterPoses; result)
    {
        foreach (poseName, path; characterPoses)
        {
            if (poseName == "default") continue;

            string key = characterName ~ "," ~ poseName;

            auto resource = new Resource;
            resource.path = path;

            generalResources[key] = resource;
        }

        auto defaultEntry = characterPoses.get("default", null);

        if (defaultEntry && defaultEntry.length)
        {
            auto defaultPose = characterPoses.get(defaultEntry, null);

            if (defaultPose && defaultPose.length)
            {
                string key = characterName;

                auto resource = new Resource;
                resource.path = defaultPose;

                generalResources[key] = resource;
            }
        }
    }
}