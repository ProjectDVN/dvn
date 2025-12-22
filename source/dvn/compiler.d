module dvn.compiler;

import dvn.views.consoleview;
import dvn.scenegraph;
import dvn.gamesettings;
import dvn.events;

import std.string : strip, stripLeft, stripRight, format;
import std.array : replace, split, array;
import std.algorithm : canFind, startsWith, filter, countUntil, map;
import std.path : baseName;
import std.conv : to;

/// 
public struct ScriptLine
{
    public:
	/// 
    string text;
	/// 
    string file;
	/// 
    int lineNumber;
}

ScriptLine[] preprocess(ScriptLine[] scripts)
{
    string[string] sceneContent;

    foreach (scriptText; scripts)
    {
        auto lines = scriptText
            .text
            .replace("\r", "")
            .split("\n");
            
        string sceneName = "";
        string currentScene = "";

        foreach (l; lines)
        {
            if (!l || !l.strip.length)
            {
                continue;
            }

            auto line = l.strip;

            if (line[0] == '#')
            {
                continue;
            }

            if (line[0] == '[' && line[$-1] == ']')
            {
                if (currentScene && currentScene.length)
                {
                    sceneContent[sceneName] = currentScene;
                    currentScene = "";
                }
                sceneName = line[1 .. $-1];
            }
            else if (sceneName && sceneName.length)
            {
                currentScene ~= l ~ "\r\n";
            }
        }

        if (currentScene && currentScene.length)
        {
            sceneContent[sceneName] = currentScene;
            currentScene = "";
        }
    }

    ScriptLine[] finalText = [];

    foreach (scriptFile; scripts)
    {
        auto scriptText = scriptFile.text;

        auto lines = scriptText
            .replace("\r", "")
            .split("\n");

        int currentLineCount = 0;
        foreach (l; lines)
        {
            currentLineCount++;
            if (!l || !l.strip.length)
            {
                continue;
            }

            auto line = l.strip;

            if (line.startsWith("@"))
            {
                auto sceneToInclude = line.split("@")[1];
                auto sceneLines = sceneContent[sceneToInclude].replace("\r", "").split("\n");

                foreach (sceneLine; sceneLines)
                {
                    finalText ~= ScriptLine(sceneLine, scriptFile.file, currentLineCount);
                }
            }
            else
            {
                auto text = l ~ "\r\n";

                finalText ~= ScriptLine(text, scriptFile.file, currentLineCount);
            }
        }
    }

    return finalText;
}

SceneEntry[string] compileFromText(string script, string filepath = "data/scripts.dvn")
{
    auto settings = getGlobalSettings();
    if (!settings)
    {
        settings = new GameSettings;
    }

    auto scriptLines = preprocess([ScriptLine(script, filepath, 0)]);
    
    string lastScriptFile = "";
    int lineCount = 0;
    SceneEntry lastEntry;
    SceneEntry[string] scenes;

    compile(settings, scriptLines, scenes, lastEntry, lineCount, lastScriptFile);

    return scenes;
}

void compile(GameSettings settings, ScriptLine[] scriptText, ref SceneEntry[string] scenes, ref SceneEntry lastEntry, ref int lineCount, ref string lastScriptFile)
{
    auto lines = scriptText;
        //.replace("\r", "")
        //.split("\n");

    SceneEntry entry;
    SceneCharacter character;
    SceneCharacterName charName;
    SceneCharacterName[] charNames = [];
    lastEntry = null;
    bool isNarrator = false;
    int narratorX = 0;
    int narratorY = 0;
    SceneCharacter[] characters = [];

    string textColor = settings.defaultTextColor && settings.defaultTextColor.length ? settings.defaultTextColor : "fff";
    lineCount = 0;
    int chance = 100;
    string original = "";
    int customSceneIdCounter = 0;
    string voice;
    string lastCharacterName;

    foreach (scriptLine; lines)
    {
        auto scriptFile = scriptLine.file;
        auto scriptBaseName = baseName(scriptFile).split(".")[0];
        
        auto l = scriptLine.text;
        lineCount = scriptLine.lineNumber;
        //lineCount++;
        if (!l || !l.strip.length)
        {
            continue;
        }

        auto line = l
            .replace("[*", "[" ~ scriptBaseName)
            .replace(":*", ":" ~ scriptBaseName)
            .replace("->*", "->" ~ scriptBaseName)
            .strip;

        if (line[0] == '#')
        {
            continue;
        }

        string nextBackground;
        string nextMusic;

        if (line[0] == '[' && line[$-1] == ')')
        {
            auto bracketEnd = line.countUntil("]");

            auto sceneData = line[bracketEnd+1 .. $].strip;
            sceneData = sceneData[1 .. $-1].strip;

            auto sceneDataEntries = sceneData.split(",").map!(a => a.strip).array;

            if (sceneDataEntries.length >= 1)
            {
                nextBackground = sceneDataEntries[0];
            }

            if (sceneDataEntries.length > 1)
            {
                nextMusic = sceneDataEntries[1];
            }

            line = line[0 .. bracketEnd+1];
        }

        if (line[0] == '[' && line[$-1] == ']')
        {
            if (entry && entry.nextScene && entry.nextScene == "~")
            {
                entry.nextScene = line[1 .. $-1];
            }

            entry = new SceneEntry;

            if (nextBackground)
            {
                entry.background = nextBackground;
            }

            if (nextMusic)
            {
                entry.music = nextMusic;
            }

            chance = 100;
            entry.hasRuby = settings.displayRuby;
            entry.chance = chance;
            entry.name = line[1 .. $-1];
            original = entry.name;
            entry.original = original;
            customSceneIdCounter = 0;
            character = null;
            charName = null;
            charNames = [];
            isNarrator = false;
            voice = null;
            narratorX = 0;
            narratorY = 0;
            lastEntry = entry;
            textColor = settings.defaultTextColor && settings.defaultTextColor.length ? settings.defaultTextColor : "fff";
            entry.textColor = settings.defaultTextColor && settings.defaultTextColor.length ? settings.defaultTextColor : "fff";
            lastCharacterName = null;

            scenes[entry.name] = entry;
        }
        else
        {
            if (!entry)
            {
                throw new Exception("Missing scene entry.");
            }

            auto kv = line.split("=");

            if (!line.canFind("=") && line.canFind("->"))
            {
                auto optionData = line.split("->");

                if (line.startsWith("->"))
                {
                    if (line == "->")
                    {
                        line = "then=~";
                    }
                    else
                    {
                        line = "then=" ~ optionData[1];
                    }
                }
                else
                {
                    line = "o:" ~ optionData[0].strip ~ "=" ~ optionData[1].stripLeft;
                }

                kv = line.split("=");
            }

            if (kv.length != 2)
            {
                switch (line)
                {
                    case "ruby":
                        entry.hasRuby = true;
                        continue;
                    case "hideDialogue":
                        entry.hideDialogue = true;
                        continue;

                    case "hideButtons":
                        entry.hideButtons = true;
                        continue;

                    case "characterFadeIn":
                    case "cf":
                        character.characterFadeIn = true;
                        continue;

                    case "stopMusic":
                        entry.stopMusic = true;
                        continue;

                    case "stopSound":
                        entry.stopSound = true;
                        continue;

                    case "fadeMusic":
                        entry.fadeMusic = true;
                        continue;

                    default:
                        if (!line.canFind("="))
                        {
                            line = "t=" ~ l.stripRight;

                            kv = line.split("=");
                        }
                        break;
                }
            }

            auto keyData = kv[0].split(":");
            string key = keyData && keyData.length ? keyData[0].strip : "";
            auto value = kv[1];

            switch (key)
            {
                case "characterZIndex":
                case "cz":
                    character.zIndex = value.to!int;
                    break;
                case "continue":
                case "then":
                case "next":
                    if (lastEntry)
                    {
                        lastEntry.nextScene = value;
                    }
                    break;
                case "removeCharacter":
                case "rc":
                    entry.characters = entry.characters.filter!(c => c.name != value).array;
                    break;
                case "meta":
                    entry.meta ~= value;
                    break;

                case "delay":
                case "d":
                    entry.delay = value.to!int;
                    break;
                case "chance":
                    chance = value.to!int;
                    break;
                case "narrator":
                    isNarrator = true;
                    auto narratorXY = value.split(",");
                    narratorX = narratorXY[0].to!int;
                    narratorY = narratorXY[1].to!int;
                    break;

                case "background":
                case "bg":
                    entry.background = value;
                    break;

                case "music":
                case "m":
                    entry.music = value;
                    break;

                case "sound":
                case "s":
                    entry.sound = value;
                    break;

                case "voice":
                    voice = value;
                    break;

                case "effect":
                case "e":
                    auto effect = new SceneEffect;
                    if (keyData && keyData.length > 1)
                    {
                        effect.render = keyData[1];
                    }
                    auto effectValues = value.split(",");
                    effect.id = effectValues[0];
                    if (effectValues.length > 1)
                    {
                        effect.values = effectValues[1 .. $];
                    }
                    entry.effects ~= effect;
                    break;

                case "char":
                case "c":
                    character = new SceneCharacter;
                    character.image = value;
                    if (settings.useLegacyCharacters)
                    {
                        if (settings.useLegacyCharacterSplit && settings.useLegacyCharacterSplit.length)
                        {
                            character.name = value.split(settings.useLegacyCharacterSplit)[0].strip;
                        }
                        else
                        {
                            character.name = value;
                        }
                    }
                    else
                    {
                        character.name = value.split(",")[0].strip;
                    }
                    character.position = "bottomCenter";
                    characters ~= character;
                    break;

                case "charMovement":
                case "cm":
                    character.movement = value;
                    character.movementSpeed  = 42;
                    break;

                case "charMovementSpeed":
                case "cms":
                    character.movementSpeed = value.to!int;
                    break;

                case "charName":
                case "n":
                    charName = new SceneCharacterName;
                    charName.name = value;
                    charName.color = "fff";
                    if (settings.defaultCharacterNameColors)
                    {
                        charName.color = settings.defaultCharacterNameColors.get(charName.name, "fff");
                    }
                    charName.position = "left";
                    charNames ~= charName;
                    lastCharacterName = value;
                    break;

                case "charColor":
                case "cc":
                    charName.color = value;
                    break;

                case "charPos":
                case "cp":
                    character.position = value;
                    auto charXYPos = value.split(",");
                    
                    if (charXYPos.length == 2)
                    {
                        character.position = "";
                        character.x = charXYPos[0].to!int;
                        character.y = charXYPos[1].to!int;
                    }
                    break;

                case "charNamePos":
                case "np":
                    charName.position = value;
                    break;

                case "textColor":
                case "tc":
                    entry.textColor = value;
                    break;

                case "image":
                case "i":
                    auto image = new SceneImage;
                    image.source = value;
                    auto imagePos = keyData[1].split(",");
                    image.x = imagePos[0].to!int;
                    image.y = imagePos[1].to!int;

                    if (keyData.length == 3)
                    {
                        image.position = keyData[2];
                    }

                    entry.images ~= image;
                    break;

                case "video":
                case "v":
                    auto video = new SceneVideo;
                    video.source = value;
                    auto videoPos = keyData[1].split(",");
                    video.x = videoPos[0].to!int;
                    video.y = videoPos[1].to!int;

                    auto videoSize = keyData[2].split(",");
                    video.width = videoSize[0].to!int;
                    video.height = videoSize[1].to!int;

                    if (keyData.length == 4)
                    {
                        video.position = keyData[3];
                    }

                    entry.videos ~= video;
                    break;

                case "animation":
                case "ani":
                    auto animation = new SceneAnimation;
                    animation.source = value;
                    auto aniPos = keyData[1].split(",");
                    animation.x = aniPos[0].to!int;
                    animation.y = aniPos[1].to!int;

                    if (keyData.length >= 3)
                    {
                        animation.repeat = keyData[2].to!bool;
                    }
                    if (keyData.length >= 4)
                    {
                        animation.position = keyData[3];
                    }

                    entry.animations ~= animation;
                    break;
                    
                case "label":
                case "l":
                    auto label = new SceneLabel;
                    label.text = value;
                    label.fontSize = keyData[1].to!size_t;
                    auto labelPosition = keyData[2].split(",");
                    label.x = labelPosition[0].to!int;
                    label.y = labelPosition[1].to!int;
                    label.color = keyData[3];

                    entry.labels ~= label;
                    break;

                case "font":
                case "f":
                    entry.textFont = value;
                    break;

                case "text":
                case "t":
                    import std.conv : to;
                    
                    customSceneIdCounter++;

                    lastCharacterName = null;

                    if (lastEntry && lastEntry.text && lastEntry.text.length)
                    {
                        lastEntry.nextScene = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

                        entry = new SceneEntry;
                        entry.original = original;
                        entry.chance = chance;
                        chance = 100;
                        entry.name = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

                        entry.music = lastEntry.music;
                        entry.hasRuby = lastEntry.hasRuby;
                        //entry.sound = lastEntry.sound;
                        entry.background = lastEntry.background;
                        entry.labels = lastEntry.labels;
                        entry.characters = lastEntry.copyCharacters;
                        //entry.characterNames = lastEntry.characterNames;
                        entry.images = lastEntry.images;
                        entry.videos = lastEntry.videos;
                        entry.animations = lastEntry.animations;
                        entry.textColor = lastEntry.textColor;
                        entry.textFont = lastEntry.textFont;
                        entry.hideDialogue = lastEntry.hideDialogue;
                        entry.hideButtons = lastEntry.hideButtons;

                        lastEntry = entry;

                        scenes[entry.name] = entry;
                    }
                    else
                    {
                        entry.chance = chance;
                        chance = 100;
                    }

                    entry.characters ~= characters;
                    characters = [];

                    entry.voice = voice;
                    entry.characterNames = charNames;
                    entry.isNarrator = isNarrator;
                    entry.narratorX = narratorX;
                    entry.narratorY = narratorY;
                    charNames = [];
                    isNarrator = false;
                    narratorX = 0;
                    narratorY = 0;
                    
                    entry.text = value;

                    if (keyData.length == 2)
                    {
                        entry.nextScene = keyData[1];
                    }
                    else
                    {
                        entry.nextScene = original ~ "-??????????-" ~ customSceneIdCounter.to!string;
                    }
                    break;

                case "act":
                case "a":
                    entry.act = value;
                    entry.nextScene = keyData[1];
                    entry.actContinueButton = keyData[2];
                    break;

                case "option":
                case "o":
                    auto option = new SceneOption;
                    option.chance = chance;
                    option.text = value;
                    option.nextScene = keyData[1];
                    entry.options ~= option;
                    chance = 100;
                    break;

                case "view":
                    entry.view = value;
                    break;

                default:
                    if (!DvnEvents.getEvents().injectGameScript(entry, key, keyData, value))
                    {
                        break;
                    }

                    // name=text, we have a key, but we need to check if we have a value
                    if (value && value.length)
                    {
                        if ((key && key.length) || (lastCharacterName && lastCharacterName.length))
                        {
                            charName = new SceneCharacterName;
                            charName.name = key && key.length ? key : lastCharacterName;
                            lastCharacterName = charName.name;
                            charName.color = "fff";
                            if (settings.defaultCharacterNameColors)
                            {
                                charName.color = settings.defaultCharacterNameColors.get(charName.name, "fff");
                            }
                            charName.position = "left";
                            charNames ~= charName;
                        }
                        
                        import std.conv : to;
                        
                        customSceneIdCounter++;

                        if (lastEntry && lastEntry.text && lastEntry.text.length)
                        {
                            lastEntry.nextScene = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

                            entry = new SceneEntry;
                            entry.original = original;
                            entry.chance = chance;
                            chance = 100;
                            entry.name = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

                            entry.music = lastEntry.music;
                            entry.hasRuby = lastEntry.hasRuby;
                            //entry.sound = lastEntry.sound;
                            entry.background = lastEntry.background;
                            entry.labels = lastEntry.labels;
                            entry.characters = lastEntry.copyCharacters;
                            //entry.characterNames = lastEntry.characterNames;
                            entry.images = lastEntry.images;
                            entry.videos = lastEntry.videos;
                            entry.animations = lastEntry.animations;
                            entry.textColor = lastEntry.textColor;
                            entry.textFont = lastEntry.textFont;
                            entry.hideDialogue = lastEntry.hideDialogue;
                            entry.hideButtons = lastEntry.hideButtons;

                            lastEntry = entry;

                            scenes[entry.name] = entry;
                        }
                        else
                        {
                            entry.chance = chance;
                            chance = 100;
                        }

                        entry.characters ~= characters;
                        characters = [];

                        entry.voice = voice;
                        entry.characterNames = charNames;
                        entry.isNarrator = isNarrator;
                        entry.narratorX = narratorX;
                        entry.narratorY = narratorY;
                        charNames = [];
                        isNarrator = false;
                        narratorX = 0;
                        narratorY = 0;
                        
                        entry.text = value;
                        if (keyData.length == 2)
                        {
                            entry.nextScene = keyData[1];
                        }
                        else
                        {
                            entry.nextScene = original ~ "-??????????-" ~ customSceneIdCounter.to!string;
                        }
                    }
                    else
                    {
                        logScriptError(scriptFile, lineCount,
                            format("Unknown command \"%s\"", key),
                            entry);
                    }
                    break;
            }
        }
    }
}

private void logScriptError(string scriptFile, int line, string message, SceneEntry entry = null)
{
    if (entry)
    {
        logError("Script error in \"%s\" (%s: line %d): %s",
            entry.name, scriptFile, line, message);
    }
    else
    {
        logError("Script error in (%s: line %d): %s",
            scriptFile, line, message);
    }
}

unittest
{
    import dvn.testing;

    {
        auto scenes = compileFromText(`
[main] (background)
`);
        assert(scenes.length == 1);
        auto scene = scenes.get("main", null);
        assert(scene !is null);
        assert(scene.name == "main");
        assert(scene.background == "background");
    }

    {
        auto scenes = compileFromText(`
[main] (background,music)
`);
        assert(scenes.length == 1);
        auto scene = scenes.get("main", null);
        assert(scene !is null);
        assert(scene.name == "main");
        assert(scene.background == "background");
        assert(scene.music == "music");
    }

    {
        auto scenes = compileFromText(`
[main] (,music)
`);
        assert(scenes.length == 1);
        auto scene = scenes.get("main", null);
        assert(scene !is null);
        assert(scene.name == "main");
        assert(!scene.background || !scene.background.length);
        assert(scene.music == "music");
    }

    {
        assert(willThrow({
            compileFromText(`[main`);
        }));
    }

    {
        assert(willThrow({
            compileFromText("This should throw.");
        }));
    }

    {
        auto scenes = compileFromText(`
[main]
meta=hello
meta=world
`);
        assert(scenes.length == 1);
        auto scene = scenes.get("main", null);
        assert(scene !is null);
        assert(scene.meta.length == 2);
        assert(scene.meta[0] == "hello");
        assert(scene.meta[1] == "world");
    }

    {
        auto scenes = compileFromText(`
[main]
Text 1
Text 2
`);
        assert(scenes.length == 2);
    }

    // TODO: test all scene node types.
}