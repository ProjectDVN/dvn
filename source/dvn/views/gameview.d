/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.gameview;

import std.conv : to;
import std.string : format;
import std.random : Random,uniform;

import dvn.resources;
import dvn.gamesettings;
import dvn.music;
import dvn.views.settingsview : backToScene;
import dvn.views.actview;
import dvn.events;
import dvn.history;
import dvn.views.consoleview;
import dvn.effects;
import dvn.ui;
import dvn.bundling;

public enum SceneComponentId : size_t
{
	none = 0,
	background,
	label,
	character,
	characterName,
	image,
	video,
	animation,
	textPanel,
	text,
	option
}

public final class SceneEntry
{
	public:
	final:
	string original;
	string name;
	string act;
	string actContinueButton;
	string music;
	string sound;
	string voice;
	bool fadeMusic;
	string background;
	SceneLabel[] labels;
	SceneCharacter[] characters;
	SceneCharacterName[] characterNames;
	SceneImage[] images;
	SceneVideo[] videos;
	SceneAnimation[] animations;
	SceneEffect[] effects;
	string textColor;
	string textFont;
	string text;
	string nextScene;
	SceneOption[] options;
	string view;
	bool hideDialogue;
	bool hideButtons;
	bool isNarrator;
	int narratorX;
	int narratorY;
	int chance;
	bool stopMusic;
	bool stopSound;
	int delay;

	SceneCharacter[] copyCharacters()
	{
		SceneCharacter[] chs = [];

		foreach (character; characters)
		{
			auto ch = new SceneCharacter;
			ch.image = character.image;
			ch.position = character.position;
			ch.x = character.x;
			ch.y = character.y;

			chs ~= ch;
		}

		return chs;
	}

	void log()
	{
		string info = "";

		if (text)
		{
			info ~= text ~ " ";
		}

		if (options)
		{
			foreach (option; options)
			{
				info ~= "[" ~ option.text ~ "] ";
			}
		}

		if (info.length)
		{
			logInfo("Scene-Entry: %s", info);
		}
	}
}

public final class SceneEffect
{
	public:
	final:
	string id;
	string[] values;
	string render;
}

public final class SceneLabel
{
	public:
	final:
	string text;
	size_t fontSize;
	int x;
	int y;
	string color;
}

public final class SceneCharacter
{
	public:
	final:
	string image;
	string position;
	int x;
	int y;
	string movement;
	int movementSpeed;
	bool characterFadeIn;

	SceneCharacter copyCharacter()
	{
		auto c = new SceneCharacter();
		c.image = image;
		c.position = position;
		c.x = x;
		c.y = y;
		c.movement = movement;
		c.movementSpeed = movementSpeed;
		c.characterFadeIn = characterFadeIn;
		return c;
	}
}

public final class SceneCharacterName
{
	public:
	final:
	string name;
	string color;
	string position;
}

public final class SceneOption
{
	public:
	final:
	string text;
	string nextScene;
	int chance;
}

public final class SceneImage
{
	public:
	final:
	string source;
	int x;
	int y;
	string position;
}

public final class SceneVideo
{
	public:
	final:
	string source;
	int x;
	int y;
	int width;
	int height;
	string position;
}

public final class SceneAnimation
{
	public:
	final:
	string source;
	int x;
	int y;
	string position;
	bool repeat;
}

private SceneEntry[string] _scenes;

private string _lastBackgroundSource;
private string _lastMusic;
private string _lastCharacter;

private string _saveId;
private uint _seed;
private Random random;
private int _calls;

void setSaveState(string id, uint seed = 0, int calls = 0)
{
	_saveId = id;
	if (seed == 0)
	{
		_seed = getSaveIdSeed();
	}

	random = Random(_seed);
	foreach (_; 0 .. calls)
	{
		uniform(0,100, random);
	}
	_calls = calls;
}

string getCurrentSaveId()
{
	return _saveId;
}

SaveFile getCurrentSaveFile()
{
	auto settings = getGlobalSettings();

	if (!settings.saves)
	{
		return null;
	}

	return settings.saves.get(getCurrentSaveId(), null);
}

uint getSaveIdSeed()
{
    import std.regex : replaceAll, regex;
    import std.conv : to;
    import std.format : format;

	auto id = getCurrentSaveId();

	if (id == "quick")
		return 0xC0FFEEEE;

    if (id == "auto")
        return 0xDEADBEEF;

    auto hex = replaceAll(id, regex("-"), "");

    ulong a = (hex[0 .. 16]).to!ulong(16);
    ulong b = (hex[16 .. 32]).to!ulong(16);

    return cast(uint)(a ^ (b * 0x9E3779B97F4A7C15UL));
}

private bool isAuto;
private string _lastScene;

public string getLastScene()
{
	return _lastScene;
}

public class CoverageNode
{
	public:
	final:
	string name;
	string text;
	bool isOption;
	string[] children;
	CoverageOption[] options;
}

public class CoverageOption
{
	public:
	final:
	string text;
	string scene;
}

public class Coverage
{
	public:
	final:
	CoverageNode[] nodes;
	CoverageNode[] endScenes;
	string[] missingAssets;
}

public final class GameView : View
{
	private:
	int _lastVoiceChannel;
	int[] _soundEffects;

	public:
	final:
	this(Window window)
	{
		super(window);

		_lastVoiceChannel = -1;
		_soundEffects = [];
	}

	protected override void onInitialize(bool useCache)
	{
		EXT_EnableKeyboardState();
	}

    void loadGame(SaveFile saveFile = null)
    {
		string lastScriptFile = "";
		int lineCount = 0;
		SceneEntry lastEntry;
		try
		{
			logInfo("Parsing scripts ...");

			import std.file : dirEntries, SpanMode, readText;
			import std.string : strip;
			import std.array : replace, split;

			DvnEvents.getEvents().loadingGameScripts();
			
			auto settings = getGlobalSettings();

			void compile(string scriptText, string scriptFile)
			{
				auto lines = scriptText
					.replace("\r", "")
					.split("\n");

				SceneEntry entry;
				SceneCharacter character;
				SceneCharacterName charName;
				SceneCharacterName[] charNames = [];
				lastEntry = null;
				bool isNarrator = false;
				int narratorX = 0;
				int narratorY = 0;

				string textColor = settings.defaultTextColor && settings.defaultTextColor.length ? settings.defaultTextColor : "fff";
				lineCount = 0;
				int chance = 100;
				string original = "";
				int customSceneIdCounter = 0;
				string voice;
				foreach (l; lines)
				{
					lineCount++;
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
						entry = new SceneEntry;
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

						_scenes[entry.name] = entry;
					}
					else
					{
						auto kv = line.split("=");

						if (kv.length != 2)
						{
							switch (line)
							{
								case "hideDialogue":
									entry.hideDialogue = true;
									break;

								case "hideButtons":
									entry.hideButtons = true;
									break;

								case "characterFadeIn":
								case "cf":
									character.characterFadeIn = true;
									break;

								case "stopMusic":
									entry.stopMusic = true;
									break;

								case "stopSound":
									entry.stopSound = true;
									break;

								case "fadeMusic":
									entry.fadeMusic = true;
									break;

								default:
									logScriptError(scriptFile, lineCount,
										format("Unknown command \"%s\"", line),
										entry);
									break;
							}
							continue;
						}

						auto keyData = kv[0].split(":");
						auto key = keyData[0];
						auto value = kv[1];

						switch (key)
						{
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
								character.position = "bottomCenter";
								entry.characters ~= character;
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

								if (lastEntry && lastEntry.text && lastEntry.text.length)
								{
									lastEntry.nextScene = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

									entry = new SceneEntry;
									entry.original = original;
									entry.chance = chance;
									chance = 100;
									entry.name = original ~ "-??????????-" ~ customSceneIdCounter.to!string;

									entry.music = lastEntry.music;
									entry.sound = lastEntry.sound;
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

									_scenes[entry.name] = entry;
								}
								else
								{
									entry.chance = chance;
									chance = 100;
								}

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
									charName = new SceneCharacterName;
									charName.name = key;
									charName.color = "fff";
									if (settings.defaultCharacterNameColors)
									{
										charName.color = settings.defaultCharacterNameColors.get(charName.name, "fff");
									}
									charName.position = "left";
									charNames ~= charName;
									
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
										entry.sound = lastEntry.sound;
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

										_scenes[entry.name] = entry;
									}
									else
									{
										entry.chance = chance;
										chance = 100;
									}

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

			if (hasScriptBundle)
			{
				compile(getBundleScript, "data/scripts.dvn");
			}
			else
			{
				auto scriptFiles = dirEntries("data/game/scripts","*.{vns}",SpanMode.depth);

				foreach (scriptFile; scriptFiles)
				{
					lastScriptFile = scriptFile;

					auto scriptText = readText(scriptFile);

					compile(scriptText, scriptFile);
				}
			}

			foreach (k,s; _scenes)
			{
				import std.string : strip;
				import std.array : replace;

				if (!s.text || !s.text.strip.length) continue;

				s.text = s.text.replace("__EQ__", "=");
			}

			DvnEvents.getEvents().loadedGameScripts(_scenes, saveFile);

			logInfo("Parsed scripts ...");
		}
		catch (Throwable t)
		{
			logScriptError(lastScriptFile, lineCount,
				format("Exception thrown: \"%s\"", t.msg),
				lastEntry);
		}
    }

	void coverageTest()
	{
		import std.file : exists, readText, write;
		import std.string : strip, toLower;

		auto window = super.window;

		if (!exists("coverage.txt"))
		{
			logInfo("Skipping coverage ...");
			return;
		}
		
		bool isVerbose = readText("coverage.txt").strip().toLower == "verbose";

		logInfo("Running coverage [Verbose: %s]...", isVerbose);

		loadGame();

		auto settings = getGlobalSettings();

		auto main = _scenes[settings.mainScript && settings.mainScript.length ? settings.mainScript : "main"];

		CoverageNode[] endScenes;
		CoverageNode[] nodes;
		string[] missingAssets;

		bool[string] visited;

		CoverageNode traverseScene(SceneEntry scene)
		{
			auto node = new CoverageNode;
			node.text = scene.text;
			node.isOption = false;
			node.children = [];
			node.name = scene.name;

			if (visited && scene.name in visited)
			{
				return null;
			}

			if (scene.animations && scene.animations.length)
			{
				foreach (ani; scene.animations)
				{
					if (!window.hasSheetEntry(ani.source))
					{
						missingAssets ~= ani.source;
					}
				}
			}

			if (scene.images && scene.images.length)
			{
				foreach (image; scene.images)
				{
					if (!window.hasSheetEntry(image.source))
					{
						missingAssets ~= image.source;
					}
				}
			}

			if (scene.characters && scene.characters.length)
			{
				foreach (character; scene.characters)
				{
					if (!window.hasSheetEntry(character.image))
					{
						missingAssets ~= character.image;
					}
				}
			}

			if (scene.background)
			{
				if (!window.hasSheetEntry(scene.background))
				{
					missingAssets ~= scene.background;
				}
			}

			visited[scene.name] = true;
			nodes ~= node;

			if (scene.options)
			{
				node.options = [];
				
				foreach (option; scene.options)
				{
					auto optionNode = new CoverageNode;
					optionNode.name = node.name;
					optionNode.text = option.text;
					optionNode.isOption = false;
					auto ochild = traverseScene(_scenes[option.nextScene]);
					if (ochild && ochild.text && ochild.text.length)
					{
						optionNode.children = [ochild.name && ochild.name.length ? ochild.name : ochild.text];
					}

					node.children ~= optionNode.text;
					auto o = new CoverageOption;
					o.text = optionNode.text;
					o.scene = option.nextScene;
					node.options ~= o;
				}
			}
			else
			{
				if (scene.nextScene && scene.nextScene.length)
				{
					auto child = traverseScene(_scenes[scene.nextScene]);
					
					if (child && child.name && child.name.length)
					{
						node.children ~= child.name;
					}
					else if (child && child.text && child.text.length)
					{
						node.children ~= child.text;
					}
				}
				else
				{
					endScenes ~= node;
				}
			}

			return node;
		}

		auto cov = new Coverage;
		traverseScene(main);
		cov.nodes = nodes;
		if (!isVerbose)
		{
			cov.nodes = null;
		}
		cov.endScenes = endScenes;
		cov.missingAssets = missingAssets;

		import dvn.json;

		string serializedJson;
		if (!serializeJsonSafe(cov, serializedJson, true))
		{
			return;
		}

		write("coverage.json", serializedJson);

		logInfo("Finished coverage ...");
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

    void initializeGame(string sceneName, string loadBackground = "", string loadMusic = "", string originalSceneName = "", string sceneText = "", bool forceRender = false)
    {
		logInfo("Loading scene: '%s' | '%s' | '%s'", sceneName, loadBackground, loadMusic);

		DvnEvents.getEvents().beginGameView(sceneName, loadBackground, loadMusic);

		auto window = super.window;
		auto settings = getGlobalSettings();
		auto application = getApplication();

		void stopVoice()
		{
			if (_lastVoiceChannel >= 0)
			{
				EXT_StopSound(_lastVoiceChannel);
				EXT_RemoveSoundFinishedCallback(_lastVoiceChannel);
				EXT_ControlSoundVolume(settings.volume);
				_lastVoiceChannel = -1;
			}
		}

		void stopSoundEffects()
		{
			foreach (soundEffect; _soundEffects)
			{
				EXT_StopSound(soundEffect);
			}

			_soundEffects = [];
		}

		stopVoice();

		if (!_scenes)
		{
			logError("Scenes not found.");

			DvnEvents.getEvents().endGameView();
			
			return;
		}

		auto scene = _scenes.get(sceneName, null);

		if (!scene)
		{
			logError("Scene not found: %s", sceneName);

			DvnEvents.getEvents().endGameView();
			
			return;
		}

		if (scene.stopSound)
		{
			stopSoundEffects();
		}

		if (originalSceneName && originalSceneName.length &&
			sceneText && sceneText.length)
		{
			auto similarity = levenshteinSimilarity(sceneText, scene.text);

			auto saveFileTextMatchPercentage = settings.saveFileTextMatchPercentage >= 1 ? settings.saveFileTextMatchPercentage : 90;

			if (similarity < (cast(double)saveFileTextMatchPercentage / 100))
			{
				scene = _scenes.get(originalSceneName, null);

				if (!scene)
				{
					logError("Scene not found: %s", originalSceneName);

					DvnEvents.getEvents().endGameView();
					
					return;
				}
			}
		}

		scene.log();

		clean();

		auto nextScene = _scenes.get(scene.nextScene, null);

		bool isEnding = scene.nextScene == "end";

		DvnEvents.getEvents().beginHandleScene(scene, nextScene, isEnding, _scenes);

		if (scene.stopMusic)
		{
			EXT_StopMusic();
			application.audio.stopFade();
			_lastMusic = "";
		}
		else if (scene.music && scene.music.length)
		{
			_lastMusic = scene.music;

			auto music = getMusicPath(scene.music);

			if (music && music.length)
			{
				EXT_PlayMusic(music, !scene.fadeMusic);
				if (scene.fadeMusic) application.audio.beginFade(0, settings.volume);

				DvnEvents.getEvents().playingMusic(music);
			}
		}
		else if (loadMusic && loadMusic.length)
		{
			_lastMusic = loadMusic;

			auto music = getMusicPath(loadMusic);

			if (music && music.length)
			{
				EXT_PlayMusic(music, true);

				DvnEvents.getEvents().playingMusic(music);
			}
		}
		else if (_lastMusic && _lastMusic.length)
		{
			auto music = getMusicPath(_lastMusic);

			if (music && music.length)
			{
				EXT_PlayMusic(music, true);

				DvnEvents.getEvents().playingMusic(music);
			}
		}

		if (scene.sound && scene.sound.length)
		{
			auto sound = getMusicPath(scene.sound);

			if (sound && sound.length)
			{
				auto channel = EXT_PlaySound(sound);

				if (channel >= 0)
				{
					_soundEffects ~= channel;
				}

				DvnEvents.getEvents().playingSound(sound);
			}
		}

		if (scene.voice && scene.voice.length)
		{
			auto voice = getMusicPath(scene.voice);

			if (voice && voice.length)
			{
				_lastVoiceChannel = EXT_PlaySound(voice);

				int previousVolume = settings.volume;

				application.audio.stopFade(false);

				EXT_ControlSoundVolume(previousVolume / 2);

				EXT_SoundFinished((c)
				{
					application.sendMessage({
						EXT_RemoveSoundFinishedCallback(c);
						EXT_ControlSoundVolume(previousVolume);
					});
				}, _lastVoiceChannel);

				DvnEvents.getEvents().playingVoice(voice);
			}
		}

		if (scene.act && scene.act.length)
		{
			DvnEvents.getEvents().endGameView();

			runDelayedTask(0, {
                window.fadeToView("ActView", getColorByName("black"), false, (view) {
                    auto actView = cast(ActView)view;

                    actView.initialzieAct(scene.act, scene.actContinueButton, scene.background, scene.nextScene);
                });
            });
			return;
		}

		if (scene.view && scene.view.length)
		{
			import dvn : displayView;
			
			DvnEvents.getEvents().endGameView();
			
			displayView(scene.view);
			return;
		}

		auto overlay = new Panel(window);
		addComponent(overlay);
		overlay.size = IntVector(window.width, window.height);
		overlay.position = IntVector(0,0);
		overlay.hide();

		DvnEvents.getEvents().renderGameViewOverplayBegin(overlay);

		auto backgroundSource = (scene.background ?
			scene.background : ((loadBackground && loadBackground.length) ?
				loadBackground : _lastBackgroundSource));

		if (backgroundSource && backgroundSource.length)
		{
			auto bgImage = new Image(window, backgroundSource);
			addComponent(bgImage);
			bgImage.position = IntVector(
				(window.width / 2) - (bgImage.width / 2),
				(window.height / 2) - (bgImage.height / 2));
			bgImage.show();
			bgImage.dataId = SceneComponentId.background;

			DvnEvents.getEvents().renderGameViewBackground(bgImage);
		}
		else
		{
			auto background = new Panel(window);
			addComponent(background);
			background.fillColor = "000".getColorByHex;
			background.size = IntVector(window.width, window.height);
			background.position = IntVector(0,0);
			background.show();
		}

		overlay.show();

		if (scene.effects && (!scene.delay || !forceRender))
		{
			foreach (effect; scene.effects)
			{
				if (effect.render && effect.render != "pre") continue;
				auto e = getEffect(effect.id);
				if (e) e.handle(effect.values);
				DvnEvents.getEvents().onEffectPre(effect);
			}
		}
		
		if (scene.delay && !forceRender)
		{
			runDelayedTask(scene.delay, {
				initializeGame(sceneName, loadBackground, loadMusic, originalSceneName, sceneText, true);
			});
			return;
		}

		_lastBackgroundSource = backgroundSource;

		if (scene.characters)
		{
			foreach (character; scene.characters)
			{
				if (character.image && character.position)
				{
					auto chImage = new Image(window, character.image);
					chImage.dataId = SceneComponentId.character;
					addComponent(chImage);

					auto shouldFadeIn = false;

					if (settings.fadeInCharacters)
					{
						shouldFadeIn = !_lastCharacter || !_lastCharacter.length || _lastCharacter != character.image;
					}

					_lastCharacter = character.image;

					if (character.characterFadeIn || shouldFadeIn)
					{
						chImage.opacity = 0;

						bool faded = false;

						runDelayedTask(32, (d) {
							if (faded)
							{
								return true;
							}

							chImage.opacity = chImage.opacity + 12;

							faded = chImage.opacity >= 255;

							return faded;
						}, true);
					}

					IntVector charPosition;

					switch (character.position)
					{
						case "center":
							charPosition = IntVector(
								(window.width / 2) - (chImage.width / 2),
								(window.height / 2) - (chImage.height / 2));
							break;

						case "left":
							charPosition = IntVector(
								0,
								(window.height / 2) - (chImage.height / 2));
							break;
							
						case "right":
							charPosition = IntVector(
								(window.width - chImage.width),
								(window.height / 2) - (chImage.height / 2));
							break;

						case "bottomCenter":
							charPosition = IntVector(
								(window.width / 2) - (chImage.width / 2),
								(window.height - chImage.height));
							break;

						case "bottomRight":
							charPosition = IntVector(
								(window.width - chImage.width),
								(window.height - chImage.height));
							break;

						case "bottomLeft":
							charPosition = IntVector(
								0,
								(window.height - chImage.height));
							break;

						case "topCenter":
							charPosition = IntVector(
								(window.width / 2) - (chImage.width / 2),
								0);
							break;

						case "topRight":
							charPosition = IntVector(
								(window.width - chImage.width),
								0);
							break;

						case "topLeft":
							charPosition = IntVector(
								0,
								0);
							break;

						case "topSlightLeft":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								0);
							break;
						case "topSlightRight":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								0);
							break;
						case "slightLeft":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								(window.height / 2) - (chImage.height / 2));
							break;
						case "slightRight":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								(window.height / 2) - (chImage.height / 2));
							break;
						case "bottomSlightLeft":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								window.height - chImage.height);
							break;
						case "bottomSlightRight":
							charPosition = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								window.height - chImage.height);
							break;

						default:
							if (character.position == "")
							{
								charPosition = IntVector(character.x, character.y);
							}
							break;
					}

					if (character.movement && character.movement.length)
					{
						bool moved = false;
						int movementSpeed = character.movementSpeed;
						switch (character.movement)
						{
							case "top":
								chImage.position = IntVector(charPosition.x, 0 - chImage.height);
								break;

							case "bottom":
								chImage.position = IntVector(charPosition.x, window.height + chImage.height);
								break;

							case "left":
								chImage.position = IntVector(0 - chImage.width, charPosition.y);
								break;

							case "right":
								chImage.position = IntVector(window.width + chImage.width, charPosition.y);
								break;

							default:
								chImage.position = charPosition;
								break;
						}

						runDelayedTask(32, (d) {
							if (moved)
							{
								return true;
							}

							switch (character.movement)
							{
								case "top":
									chImage.position = IntVector(charPosition.x, chImage.y + movementSpeed);
									
									if (chImage.y >= charPosition.y)
									{
										chImage.position = IntVector(charPosition.x, charPosition.y);
									}
									break;

								case "bottom":
									chImage.position = IntVector(charPosition.x, chImage.y - movementSpeed);
									
									if (chImage.y <= charPosition.y)
									{
										chImage.position = IntVector(charPosition.x, charPosition.y);
									}
									break;

								case "left":
									chImage.position = IntVector(chImage.x + movementSpeed, charPosition.y);

									if (chImage.x >= charPosition.x)
									{
										chImage.position = IntVector(charPosition.x, charPosition.y);
									}
									break;

								case "right":
									chImage.position = IntVector(chImage.x - movementSpeed, charPosition.y);

									if (chImage.x <= charPosition.x)
									{
										chImage.position = IntVector(charPosition.x, charPosition.y);
									}
									break;

								default:
									chImage.position = charPosition;
									break;
							}
							
							moved = chImage.x == charPosition.x &&
								chImage.y == charPosition.y;

							return moved;
						}, true);
					}
					else
					{
						chImage.position = charPosition;
					}

					chImage.show();

					DvnEvents.getEvents().renderGameViewCharacter(character, chImage);
				}
			}
		}

		if (scene.images && scene.images.length)
		{
			foreach (image; scene.images)
			{
				auto imageComponent = new Image(window, image.source);
				imageComponent.dataId = SceneComponentId.image;
				addComponent(imageComponent);
				imageComponent.position = IntVector(image.x, image.y);

				if (image.position && image.position.length)
				{
					switch (image.position)
					{
						case "center":
							imageComponent.position = IntVector(
								(window.width / 2) - (imageComponent.width / 2),
								(window.height / 2) - (imageComponent.height / 2));
							break;

						case "left":
							imageComponent.position = IntVector(
								0,
								(window.height / 2) - (imageComponent.height / 2));
							break;
							
						case "right":
							imageComponent.position = IntVector(
								(window.width - imageComponent.width),
								(window.height / 2) - (imageComponent.height / 2));
							break;

						case "bottomCenter":
							imageComponent.position = IntVector(
								(window.width / 2) - (imageComponent.width / 2),
								(window.height - imageComponent.height));
							break;

						case "bottomRight":
							imageComponent.position = IntVector(
								(window.width - imageComponent.width),
								(window.height - imageComponent.height));
							break;

						case "bottomLeft":
							imageComponent.position = IntVector(
								0,
								(window.height - imageComponent.height));
							break;

						case "topCenter":
							imageComponent.position = IntVector(
								(window.width / 2) - (imageComponent.width / 2),
								0);
							break;

						case "topRight":
							imageComponent.position = IntVector(
								(window.width - imageComponent.width),
								0);
							break;

						case "topLeft":
							imageComponent.position = IntVector(
								0,
								0);
							break;

						default: break;
					}
				}

				imageComponent.show();

				DvnEvents.getEvents().renderGameViewImage(image, imageComponent);
			}
		}

		if (scene.videos && scene.videos.length)
		{
			foreach (video; scene.videos)
			{
				auto videoComponent = new Video(window, video.source, true);
				videoComponent.dataId = SceneComponentId.video;
				addComponent(videoComponent);
				videoComponent.position = IntVector(video.x, video.y);
				videoComponent.size = IntVector(video.width, video.height);

				if (video.position && video.position.length)
				{
					switch (video.position)
					{
						case "center":
							videoComponent.position = IntVector(
								(window.width / 2) - (videoComponent.width / 2),
								(window.height / 2) - (videoComponent.height / 2));
							break;

						case "left":
							videoComponent.position = IntVector(
								0,
								(window.height / 2) - (videoComponent.height / 2));
							break;
							
						case "right":
							videoComponent.position = IntVector(
								(window.width - videoComponent.width),
								(window.height / 2) - (videoComponent.height / 2));
							break;

						case "bottomCenter":
							videoComponent.position = IntVector(
								(window.width / 2) - (videoComponent.width / 2),
								(window.height - videoComponent.height));
							break;

						case "bottomRight":
							videoComponent.position = IntVector(
								(window.width - videoComponent.width),
								(window.height - videoComponent.height));
							break;

						case "bottomLeft":
							videoComponent.position = IntVector(
								0,
								(window.height - videoComponent.height));
							break;

						case "topCenter":
							videoComponent.position = IntVector(
								(window.width / 2) - (videoComponent.width / 2),
								0);
							break;

						case "topRight":
							videoComponent.position = IntVector(
								(window.width - videoComponent.width),
								0);
							break;

						case "topLeft":
							videoComponent.position = IntVector(
								0,
								0);
							break;

						default: break;
					}
				}

				videoComponent.show();

				DvnEvents.getEvents().renderGameViewVideo(video, videoComponent);
			}
		}

		if (scene.animations && scene.animations.length)
		{
			foreach (animation; scene.animations)
			{
				auto ani = new Animation(window, animation.source, !animation.repeat);
				ani.dataId = SceneComponentId.animation;
				addComponent(ani);
				ani.position = IntVector(animation.x, animation.y);

				if (animation.position && animation.position.length)
				{
					switch (animation.position)
					{
						case "center":
							ani.position = IntVector(
								(window.width / 2) - (ani.width / 2),
								(window.height / 2) - (ani.height / 2));
							break;

						case "left":
							ani.position = IntVector(
								0,
								(window.height / 2) - (ani.height / 2));
							break;
							
						case "right":
							ani.position = IntVector(
								(window.width - ani.width),
								(window.height / 2) - (ani.height / 2));
							break;

						case "bottomCenter":
							ani.position = IntVector(
								(window.width / 2) - (ani.width / 2),
								(window.height - ani.height));
							break;

						case "bottomRight":
							ani.position = IntVector(
								(window.width - ani.width),
								(window.height - ani.height));
							break;

						case "bottomLeft":
							ani.position = IntVector(
								0,
								(window.height - ani.height));
							break;

						case "topCenter":
							ani.position = IntVector(
								(window.width / 2) - (ani.width / 2),
								0);
							break;

						case "topRight":
							ani.position = IntVector(
								(window.width - ani.width),
								0);
							break;

						case "topLeft":
							ani.position = IntVector(
								0,
								0);
							break;

						default: break;
					}
				}

				ani.show();

				DvnEvents.getEvents().renderGameViewAnimation(animation, ani);
			}
		}

		if (scene.labels && scene.labels.length)
		{
			foreach (label; scene.labels)
			{
				auto sceneLabel = new Label(window);
				sceneLabel.dataId = SceneComponentId.label;
				addComponent(sceneLabel);
				sceneLabel.fontName = settings.defaultFont;
				sceneLabel.fontSize = label.fontSize;
				sceneLabel.color = label.color.getColorByHex;
				sceneLabel.text = label.text.to!dstring;
				sceneLabel.shadow = true;
				sceneLabel.position = IntVector(label.x, label.y);
				sceneLabel.updateRect();
				sceneLabel.show();

				DvnEvents.getEvents().renderGameViewLabel(label, sceneLabel);
			}
		}

		if (settings.dialoguePanelImage)
		{
			auto rawImage = new RawImage(window,
				settings.dialoguePanelImage.path,
				IntVector(settings.dialoguePanelImage.size.width,
					settings.dialoguePanelImage.size.height));
			addComponent(rawImage);
			rawImage.size = IntVector(
				(window.width / 100) * 90,
				(window.height / 100) * 33);
			rawImage.position = IntVector(
				((window.width / 2) - (rawImage.width / 2)),
				window.height - (rawImage.height + 14)
			);

			if (scene.hideDialogue || scene.isNarrator)
			{
				rawImage.hide();
			}

			DvnEvents.getEvents().renderGameViewDialoguePanelImage(rawImage);
		}

		auto textPanel = new Panel(window);
		textPanel.dataId = SceneComponentId.textPanel;
		addComponent(textPanel);
		textPanel.fillColor = settings.dialoguePanelBackgroundColor.getColorByHex.changeAlpha(150);
		textPanel.borderColor = settings.dialoguePanelBorderColor.getColorByHex;
		textPanel.size = IntVector(
			(window.width / 100) * 90,
			(window.height / 100) * 33);
		textPanel.position = IntVector(
			((window.width / 2) - (textPanel.width / 2)),
			window.height - (textPanel.height + 14)
		);
		textPanel.show();
		if (scene.hideDialogue || scene.isNarrator)
		{
			textPanel.hide();
		}

		DvnEvents.getEvents().renderGameViewDialoguePanel(textPanel);

		if (settings.dialoguePanelImage)
		{
			textPanel.fillColor = textPanel.fillColor.changeAlpha(0);
			textPanel.borderColor = textPanel.borderColor.changeAlpha(0);
		}

		if (!scene.isNarrator || !scene.hideDialogue)
		{
			foreach (charNameAndPos; scene.characterNames)
			{
				auto charNameLabel = new Label(window);
				charNameLabel.dataId = SceneComponentId.characterName;
				charNameLabel.fontName = settings.defaultFont;
				charNameLabel.fontSize = 22;
				charNameLabel.color = charNameAndPos.color.getColorByHex;
				charNameLabel.text = charNameAndPos.name.to!dstring;
				charNameLabel.shadow = true;
				charNameLabel.position = IntVector(16, 4);
				charNameLabel.updateRect();

				RawImage namePanelImage;
				if (settings.namePanelImage)
				{
					auto rawImage = new RawImage(window,
						settings.namePanelImage.path,
						IntVector(settings.namePanelImage.size.width,
							settings.namePanelImage.size.height));
					addComponent(rawImage);
					rawImage.size = IntVector(charNameLabel.width + 32, charNameLabel.height + 8);
					namePanelImage = rawImage;
				}

				auto charNamePanel = new Panel(window);
				addComponent(charNamePanel);
				charNamePanel.fillColor = settings.namePanelBackgroundColor.getColorByHex.changeAlpha(150);
				charNamePanel.borderColor = settings.namePanelBorderColor.getColorByHex;
				charNamePanel.size = IntVector(charNameLabel.width + 32, charNameLabel.height + 8);
				
				switch (charNameAndPos.position)
				{
					case "center":
						charNamePanel.position = IntVector(
							((window.width / 2) - (charNamePanel.width / 2)),
							(textPanel.y - charNamePanel.height) + 1
						);
						break;

					case "right":
						charNamePanel.position = IntVector(
							(textPanel.x + textPanel.width) - charNamePanel.width,
							(textPanel.y - charNamePanel.height) + 1
						);
						break;

					case "left":
					default:
						charNamePanel.position = IntVector(
							textPanel.x,
							(textPanel.y - charNamePanel.height) + 1
						);
						break;
				}

				charNamePanel.addComponent(charNameLabel);
				charNamePanel.show();
				
				if (settings.namePanelImage)
				{
					charNamePanel.fillColor = charNamePanel.fillColor.changeAlpha(0);
					charNamePanel.borderColor = charNamePanel.borderColor.changeAlpha(0);

					namePanelImage.position = IntVector(charNamePanel.x, charNamePanel.y - 1);
				}

				DvnEvents.getEvents().renderGameViewCharacterName(charNameAndPos, charNameLabel, charNamePanel, namePanelImage);
			}
		}

		bool hasOptions = false;

		dstring finalText = scene.text ? scene.text.to!dstring : "".to!dstring;
		dstring currentText = "";
		size_t _offset = 0;
		
		Label textLabel;

		bool loaded = false;
		bool switchingScene = false;

		bool disableEvents = false;

		void restyleButton(Button button, GameSettings gameSettings)
        {
			if (!gameSettings.buttonTextColor || !gameSettings.buttonTextColor.length ||
				!gameSettings.buttonBackgroundColor || !gameSettings.buttonBackgroundColor.length ||
				!gameSettings.buttonBackgroundBottomColor || !gameSettings.buttonBackgroundBottomColor.length ||
				!gameSettings.buttonBorderColor ||  !gameSettings.buttonBorderColor.length)
			{
				return;
			}

			auto buttonTextColor = gameSettings.buttonTextColor;
			auto buttonBackgroundColor = gameSettings.buttonBackgroundColor;
			auto buttonBackgroundBottomColor = gameSettings.buttonBackgroundBottomColor;
			auto buttonBorderColor = gameSettings.buttonBorderColor;

			button.textColor = buttonTextColor.getColorByHex;

            button.defaultPaint.backgroundColor = buttonBackgroundColor.getColorByHex;
            button.defaultPaint.backgroundBottomColor = buttonBackgroundBottomColor.getColorByHex;
            button.defaultPaint.borderColor = buttonBorderColor.getColorByHex;
            button.defaultPaint.shadowColor = buttonBackgroundColor.getColorByHex;

            button.hoverPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(220);
            button.hoverPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(220);
            button.hoverPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(220);
            button.hoverPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(220);

            button.clickPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(240);
            button.clickPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(240);
            button.clickPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(240);
            button.clickPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(240);

            button.restyle();

            button.show();
        }
		
		void saveCurrentScene(string idToSave)
		{
			import std.file : exists, mkdir, remove;

			if (!exists("data/game/saves"))
			{
				mkdir("data/game/saves");
			}
			else if (exists("data/game/saves/" ~ idToSave ~ ".png"))
			{
				remove("data/game/saves/" ~ idToSave ~ ".png");
			}

			takeScreenshot(window, "data/game/saves/" ~ idToSave ~ ".png");

			saveGame(settings, idToSave, scene.original, scene.name, scene.text ? scene.text : "", _lastBackgroundSource, _lastMusic, _seed, _calls);

			saveGameSettings("data/settings.json");
		}

		if (scene.text)
		{
			if (uniform(0,100, random) > scene.chance)
			{
				_calls++;
				if (nextScene)
				{
					if (nextScene.background == scene.background || !nextScene.background || !nextScene.background.length)
					{
						initializeGame(nextScene.name);
					}
					else
					{
						runDelayedTask(0, {
							window.fadeToView("GameView", getColorByName("black"), false, (view) {
								auto gameView = cast(GameView)view;

								gameView.initializeGame(nextScene.name);
							});
						});
					}
				}
				return;
			}

			_calls++;

			auto historyText = scene.text;

			if (scene.characterNames && scene.characterNames.length)
			{
				import std.array : join;
				
				string[] names = [];

				foreach (name; scene.characterNames)
				{
					names ~= name.name;
				}

				historyText = names.join(",") ~ ": " ~ historyText;
			}

			addDialogueHistory(historyText, null, scene.name, _lastBackgroundSource, _lastMusic, scene.original);

			textLabel = new Label(window);
			textLabel.dataId = SceneComponentId.text;

			if (scene.isNarrator)
			{
				addComponent(textLabel);
			}
			else
			{
				textPanel.addComponent(textLabel);
			}

			textLabel.fontName = settings.defaultFont;
			if (scene.textFont && scene.textFont.length)
			{
				textLabel.fontName = scene.textFont;
			}
			textLabel.fontSize = 22;
			textLabel.color = scene.textColor.getColorByHex;
			textLabel.text = "";
			textLabel.shadow = true;
			auto textMargin = settings.textMargin > 0 ? settings.textMargin : 16;
			auto textWrapSize = settings.textWrapSize > 0 ? settings.textWrapSize : textPanel.width;
			textLabel.wrapText(textWrapSize - textMargin);
			textLabel.position = IntVector(textMargin, textMargin);

			if (scene.isNarrator)
			{
				textLabel.position = IntVector(scene.narratorX, scene.narratorY);
			}

			textLabel.updateRect();

			DvnEvents.getEvents().renderGameViewTextStart(scene);

			if (settings.fadeInText)
			{
				int textFadeInSpeed = 42;
				auto faded = false;

				textLabel.color = textLabel.color.changeAlpha(0);
				
				runDelayedTask(textFadeInSpeed, (d) {
					if (textLabel.color.a >= 255)
					{
						faded = true;
						return faded;
					}

					int newAlpha = textLabel.color.a + 10;

					if (newAlpha >= 255)
					{
						newAlpha = 255;
					}

					textLabel.color = textLabel.color.changeAlpha(cast(ubyte)newAlpha);

					if (textLabel.color.a >= 255)
					{
						faded = true;
					}

					return faded;
				}, true);
			}

			runDelayedTask(settings.textSpeed, (d) {
				if (loaded)
				{
					return true;
				}

				if (_offset < finalText.length)
				{
					currentText ~= finalText[_offset];
					textLabel.text = currentText;
					_offset++;
				}
				else
				{
					loaded = true;
				}

				if (finalText == textLabel.text)
				{
					loaded = true;
				}

				if (loaded)
				{
					textLabel.color = textLabel.color.changeAlpha(255);

					if (settings.enableAutoSave)
					{
						runDelayedTask(0, {
							saveCurrentScene("auto");
						});
					}
					DvnEvents.getEvents().renderGameViewTextFinished(textLabel);
				}

				if (loaded && isAuto && !isEnding)
				{
					disableEvents = true;

					runDelayedTask(2000, {
						if (nextScene)
						{
							if (nextScene.background == scene.background || !nextScene.background || !nextScene.background.length)
							{
								initializeGame(nextScene.name);
							}
							else
							{
								runDelayedTask(0, {
									window.fadeToView("GameView", getColorByName("black"), false, (view) {
										auto gameView = cast(GameView)view;

										gameView.initializeGame(nextScene.name);
									});
								});
							}
						}
					});
				}

				return loaded;
			}, true);
		}
		if ((!scene.text || settings.displayOptionsAsButtons) && scene.options && scene.options.length)
		{
			hasOptions = true;

			DvnEvents.getEvents().renderGameViewOptionsStart();

			string[] optionHistory = [];

			foreach (option; scene.options)
			{
				optionHistory ~= option.text;
			}

			addDialogueHistory(null, optionHistory, scene.name, _lastBackgroundSource, _lastMusic, scene.original);

			if (settings.displayOptionsAsButtons)
			{
				if (!scene.text)
				{
					textPanel.hide();
				}

				int lastY = 168;
				foreach (option; scene.options)
				{
					if (uniform(0,100,random) > option.chance)
					{
						_calls++;
						continue;
					}
					_calls++;

					auto optionButton = new Button(window);
					optionButton.dataId = SceneComponentId.option;
					addComponent(optionButton);
					optionButton.size = IntVector(window.width / 3, 32);
					optionButton.position = IntVector(
						(window.width / 2) - (optionButton.width / 2),
						lastY);
					optionButton.fontName = settings.defaultFont;
					optionButton.fontSize = 22;
					optionButton.textColor = "000".getColorByHex;
					optionButton.text = option.text.to!dstring;
					optionButton.fitToSize = false;

					optionButton.restyle();

					optionButton.show();

					restyleButton(optionButton, settings);

					auto optionNextScene = _scenes.get(option.nextScene, null);

					auto closure = (Button oButton, SceneEntry nScene, bool isEnding) { return () {
						oButton.onButtonClick(new MouseButtonEventHandler((b,p) {
							if (!DvnEvents.getEvents().onGameViewOptionClick(oButton))
							{
								return false;
							}

							if (switchingScene)
							{
								return false;
							}

							switchingScene = true;

							if (isEnding)
							{
								window.fadeToView("MainMenu", getColorByName("black"), false);
							}
							else if (nScene)
							{
								if (nScene.background == scene.background || !nScene.background || !nScene.background.length)
								{
									initializeGame(nScene.name);
								}
								else
								{
									runDelayedTask(0, {
										window.fadeToView("GameView", getColorByName("black"), false, (view) {
											auto gameView = cast(GameView)view;

											gameView.initializeGame(nScene.name);
										});
									});
								}
							}

							return false;
						}));
					};};

					closure(optionButton, optionNextScene, option.nextScene == "end")();

					lastY += 12 + optionButton.height;

					DvnEvents.getEvents().renderGameViewOption(optionButton);
				}
			}
			else
			{
				int lastY = 50;
				foreach (option; scene.options)
				{
					if (uniform(0,100,random) > option.chance)
					{
						_calls++;
						continue;
					}
					_calls++;
					auto optionLabel = new Label(window);
					optionLabel.dataId = SceneComponentId.option;
					textPanel.addComponent(optionLabel);
					optionLabel.fontName = settings.defaultFont;
					optionLabel.fontSize = 22;
					optionLabel.color = getColorByHex("fff");
					optionLabel.text = option.text.to!dstring;
					optionLabel.position = IntVector(
						((textPanel.width / 2) - (optionLabel.width / 2)),
						lastY);
					optionLabel.isLink = true;
					optionLabel.shadow = true;
					optionLabel.updateRect();

					auto optionNextScene = _scenes.get(option.nextScene, null);

					auto closure = (Label oLabel, SceneEntry nScene, bool isEnding) { return () {
						oLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
							if (!DvnEvents.getEvents().onGameViewOptionClick(oLabel))
							{
								return;
							}

							if (switchingScene)
							{
								return;
							}

							switchingScene = true;

							if (isEnding)
							{
								window.fadeToView("MainMenu", getColorByName("black"), false);
							}
							else if (nScene)
							{
								if (nScene.background == scene.background || !nScene.background || !nScene.background.length)
								{
									initializeGame(nScene.name);
								}
								else
								{
									runDelayedTask(0, {
										window.fadeToView("GameView", getColorByName("black"), false, (view) {
											auto gameView = cast(GameView)view;

											gameView.initializeGame(nScene.name);
										});
									});
								}
							}
						}));
					};};

					closure(optionLabel, optionNextScene, option.nextScene == "end")();

					lastY += 12 + optionLabel.height;

					DvnEvents.getEvents().renderGameViewOption(optionLabel);
				}
			}

			DvnEvents.getEvents().renderGameViewOptionsFinished();
		}

		auto saveButton = new Button(window);
		addComponent(saveButton);
		saveButton.size = IntVector(208, 28);
		saveButton.position = IntVector(
			window.width - (saveButton.width + 16),
			16);
		saveButton.fontName = settings.defaultFont;
		saveButton.fontSize = 18;
		saveButton.textColor = "000".getColorByHex;
		saveButton.text = settings.saveButtonText.to!dstring;
		saveButton.fitToSize = false;

		saveButton.restyle();

		saveButton.show();

		saveButton.onButtonClick(new MouseButtonEventHandler((b,p) {
			saveCurrentScene(_saveId);
			return false;
		}));

		restyleButton(saveButton, settings);

		DvnEvents.getEvents().renderGameViewSaveButton(saveButton);

		if (scene.hideButtons) saveButton.hide();

		auto exitButton = new Button(window);
		addComponent(exitButton);
		exitButton.size = IntVector(64, 28);
		exitButton.position = IntVector(
			(saveButton.x + saveButton.width) - exitButton.width,
			saveButton.y + saveButton.height + 12);
		exitButton.fontName = settings.defaultFont;
		exitButton.fontSize = 18;
		exitButton.textColor = "000".getColorByHex;
		exitButton.text = settings.exitButtonText.to!dstring;
		exitButton.fitToSize = false;

		exitButton.restyle();

		exitButton.show();

		exitButton.onButtonClick(new MouseButtonEventHandler((b,p) {
			backToScene = "";
			stopVoice();
			stopSoundEffects();

			window.fadeToView("MainMenu", getColorByName("black"), false);
			return false;
		}));

		restyleButton(exitButton, settings);

		DvnEvents.getEvents().renderGameViewExitButton(exitButton);

		if (scene.hideButtons) exitButton.hide();

		auto settingsButton = new Button(window);
		addComponent(settingsButton);
		settingsButton.size = IntVector(92, 28);
		settingsButton.position = IntVector(
			saveButton.x,
			saveButton.y + saveButton.height + 12);
		settingsButton.fontName = settings.defaultFont;
		settingsButton.fontSize = 18;
		settingsButton.textColor = "000".getColorByHex;
		settingsButton.text = settings.settingsButtonText.to!dstring;
		settingsButton.fitToSize = false;

		settingsButton.restyle();

		settingsButton.show();

		settingsButton.onButtonClick(new MouseButtonEventHandler((b,p) {
			backToScene = scene.name;
			stopVoice();
			stopSoundEffects();
			
			window.fadeToView("SettingsView", getColorByName("black"), false);
			return false;
		}));

		restyleButton(settingsButton, settings);

		DvnEvents.getEvents().renderGameViewSettingsButton(settingsButton);

		if (scene.hideButtons) settingsButton.hide();

		auto autoButton = new Button(window);
		addComponent(autoButton);
		autoButton.size = IntVector(saveButton.width, saveButton.height);
		autoButton.position = IntVector(
			settingsButton.x,
			settingsButton.y + settingsButton.height + 12);
		autoButton.fontName = settings.defaultFont;
		autoButton.fontSize = 18;
		autoButton.textColor = "000".getColorByHex;
		autoButton.text = (isAuto ? settings.autoButtonTextOn : settings.autoButtonTextOff).to!dstring;
		autoButton.fitToSize = false;

		autoButton.restyle();

		autoButton.show();

		autoButton.onButtonClick(new MouseButtonEventHandler((b,p) {
			isAuto = !isAuto;

			if (isAuto)
			{
				autoButton.text = settings.autoButtonTextOn.to!dstring;
			}
			else
			{
				autoButton.text = settings.autoButtonTextOff.to!dstring;
			}

			return false;
		}));

		restyleButton(autoButton, settings);

		DvnEvents.getEvents().renderGameViewAutoButton(autoButton);

		if (scene.hideButtons) autoButton.hide();

		auto quickSaveButton = new Button(window);
		addComponent(quickSaveButton);
		quickSaveButton.size = IntVector(autoButton.width, autoButton.height);
		quickSaveButton.position = IntVector(
			autoButton.x,
			autoButton.y + autoButton.height + 12);
		quickSaveButton.fontName = settings.defaultFont;
		quickSaveButton.fontSize = 18;
		quickSaveButton.textColor = "000".getColorByHex;
		quickSaveButton.text = (settings.quickSaveButtonText ? settings.quickSaveButtonText : "Q-Save").to!dstring;
		quickSaveButton.fitToSize = false;

		quickSaveButton.restyle();

		quickSaveButton.show();

		quickSaveButton.onButtonClick(new MouseButtonEventHandler((b,p) {
			saveCurrentScene("quick");
			return false;
		}));

		restyleButton(quickSaveButton, settings);

		DvnEvents.getEvents().renderGameViewQuickSaveButton(quickSaveButton);

		if (scene.hideButtons) quickSaveButton.hide();

		Component[] safeComponents = [saveButton, exitButton, settingsButton, autoButton, quickSaveButton];

		if (!settings.useLegacySceneButtons)
		{
			Label saveLabel;
			Label settingsLabel;
			Label autoLabel;
			Label quickSaveLabel;
			Label exitLabel;
			Panel labelPanel;

			saveButton.hide();
			exitButton.hide();
			settingsButton.hide();
			autoButton.hide();
			quickSaveButton.hide();

			auto view = quickSaveButton.view;

			labelPanel = new Panel(window);
			view.addComponent(labelPanel);

			Label[] labels = [];

			saveLabel = new Label(window);
			labelPanel.addComponent(saveLabel);
			saveLabel.fontName = settings.defaultFont;
			saveLabel.fontSize = 18;
			saveLabel.color = "fff".getColorByHex;
			saveLabel.text = saveButton.text;
			saveLabel.shadow = true;
			saveLabel.isLink = true;
			saveLabel.position = IntVector(0, 0);
			saveLabel.updateRect();
			saveLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) { saveButton.fireButtonClick(); }));
			labels ~= saveLabel;
			
			settingsLabel = new Label(window);
			labelPanel.addComponent(settingsLabel);
			settingsLabel.fontName = settings.defaultFont;
			settingsLabel.fontSize = 18;
			settingsLabel.color = "fff".getColorByHex;
			settingsLabel.text = settingsButton.text;
			settingsLabel.shadow = true;
			settingsLabel.isLink = true;
			settingsLabel.position = IntVector(0, 0);
			settingsLabel.updateRect();
			settingsLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) { settingsButton.fireButtonClick(); }));
			labels ~= settingsLabel;
			
			autoLabel = new Label(window);
			labelPanel.addComponent(autoLabel);
			autoLabel.fontName = settings.defaultFont;
			autoLabel.fontSize = 18;
			autoLabel.color = "fff".getColorByHex;
			autoLabel.text = autoButton.text;
			autoLabel.shadow = true;
			autoLabel.isLink = true;
			autoLabel.position = IntVector(0, 0);
			autoLabel.updateRect();
			
			int width = 0;
			int maxHeight = 0;
			int x = 0;

			void updatePanel()
			{
				width = 0;
				maxHeight = 0;
				x = 0;
				foreach (label; labels)
				{
					label.position = IntVector(x, label.y);
					width += label.width + 8;
					if (label.height > maxHeight) maxHeight = label.height;

					x += label.width + 8;

					label.updateRect();
				}

				labelPanel.size = IntVector(width, maxHeight);
				labelPanel.position = IntVector(
					(window.width / 2) - (labelPanel.width / 2),
					window.height - (labelPanel.height + 8)
				);
			}

			autoLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
			{
				autoButton.fireButtonClick();

				autoLabel.text = autoButton.text;
				autoLabel.updateRect();

				updatePanel();
			}));
			labels ~= autoLabel;
			
			quickSaveLabel = new Label(window);
			labelPanel.addComponent(quickSaveLabel);
			quickSaveLabel.fontName = settings.defaultFont;
			quickSaveLabel.fontSize = 18;
			quickSaveLabel.color = "fff".getColorByHex;
			quickSaveLabel.text = quickSaveButton.text;
			quickSaveLabel.shadow = true;
			quickSaveLabel.isLink = true;
			quickSaveLabel.position = IntVector(0, 0);
			quickSaveLabel.updateRect();
			quickSaveLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) { quickSaveButton.fireButtonClick(); }));
			labels ~= quickSaveLabel;
			
			exitLabel = new Label(window);
			labelPanel.addComponent(exitLabel);
			exitLabel.fontName = settings.defaultFont;
			exitLabel.fontSize = 18;
			exitLabel.color = "fff".getColorByHex;
			exitLabel.text = exitButton.text;
			exitLabel.shadow = true;
			exitLabel.isLink = true;
			exitLabel.position = IntVector(0, 0);
			exitLabel.updateRect();
			exitLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) { exitButton.fireButtonClick(); }));
			labels ~= exitLabel;

			updatePanel();

			safeComponents ~= labelPanel;
		}

		bool intersectsWith(int x1, int y1, int x2, int y2, int w2, int h2)
		{
			return (x1 > x2) &&
				(x1 < (x2 + w2)) &&
				(y1 > y2) &&
				(y1 < (y2 + h2));
		}
		
		auto lastTicks = EXT_GetTicks();

		overlay.onKeyboardUp(new KeyboardEventHandler((k) {
			if (switchingScene || hasOptions || disableEvents)
			{
				return;
			}
			
			auto ticks = EXT_GetTicks();

      		if ((ticks - lastTicks) < 256)
			{
				return;
			}

			lastTicks = ticks;
			
			if (k == KeyboardKey.LControl)
			{
				if (loaded)
				{
					switchingScene = true;

					if (isEnding)
					{
						window.fadeToView("MainMenu", getColorByName("black"), false);
					}
					else if (nextScene)
					{
						_lastScene = scene.name;
					
						if (nextScene.background == scene.background || !nextScene.background || !nextScene.background.length)
						{
							initializeGame(nextScene.name);
						}
						else
						{
							runDelayedTask(0, {
								window.fadeToView("GameView", getColorByName("black"), false, (view) {
									auto gameView = cast(GameView)view;

									gameView.initializeGame(nextScene.name);
								});
							});
						}
					}
				}
				else
				{
					loaded = true;
					textLabel.text = finalText;
					textLabel.color = textLabel.color.changeAlpha(255);

					if (settings.enableAutoSave)
					{
						runDelayedTask(0, {
							saveCurrentScene("auto");
						});
					}

					DvnEvents.getEvents().renderGameViewTextFinished(textLabel);
				}
			}
		}), true);

		overlay.onTextInput(new TextInputEventHandler((c,s) {
			if (switchingScene || hasOptions || disableEvents)
			{
				return;
			}
			
			auto ticks = EXT_GetTicks();

      		if ((ticks - lastTicks) < 256)
			{
				return;
			}

			lastTicks = ticks;
			
			if (s == " ")
			{
				if (loaded)
				{
					switchingScene = true;

					if (isEnding)
					{
						window.fadeToView("MainMenu", getColorByName("black"), false);
					}
					else if (nextScene)
					{
						_lastScene = scene.name;
					
						if (nextScene.background == scene.background || !nextScene.background || !nextScene.background.length)
						{
							initializeGame(nextScene.name);
						}
						else
						{
							runDelayedTask(0, {
								window.fadeToView("GameView", getColorByName("black"), false, (view) {
									auto gameView = cast(GameView)view;

									gameView.initializeGame(nextScene.name);
								});
							});
						}
					}
				}
				else
				{
					loaded = true;
					textLabel.text = finalText;
					textLabel.color = textLabel.color.changeAlpha(255);

					if (settings.enableAutoSave)
					{
						runDelayedTask(0, {
							saveCurrentScene("auto");
						});
					}

					DvnEvents.getEvents().renderGameViewTextFinished(textLabel);
				}
			}
			else if (s == "s" || s == "S")
			{
				import std.file : exists, mkdir, remove;

				import std.uuid : randomUUID;
				
				auto photoId = randomUUID().toString;

				if (!exists("data/game/gallery"))
				{
					mkdir("data/game/gallery");
				}
				else if (exists("data/game/gallery/" ~ photoId ~ ".png"))
				{
					remove("data/game/gallery/" ~ photoId ~ ".png");
				}

				takeScreenshot(window, "data/game/gallery/" ~ photoId ~ ".png");
			}
		}), true);

		DvnEvents.getEvents().addClickSafeComponents(safeComponents);

		overlay.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
			if (switchingScene || hasOptions || disableEvents)
			{
				return;
			}

			foreach (component; safeComponents)
			{
				if (intersectsWith(p.x, p.y, component.x, component.y, component.width, component.height))
				{
					return;
				}
			}

			// if (intersectsWith(p.x, p.y, saveButton.x, saveButton.y, saveButton.width, saveButton.height))
			// {
			// 	return;
			// }

			// if (intersectsWith(p.x, p.y, exitButton.x, exitButton.y, exitButton.width, exitButton.height))
			// {
			// 	return;
			// }

			// if (intersectsWith(p.x, p.y, settingsButton.x, settingsButton.y, settingsButton.width, settingsButton.height))
			// {
			// 	return;
			// }

			// if (intersectsWith(p.x, p.y, autoButton.x, autoButton.y, autoButton.width, autoButton.height))
			// {
			// 	return;
			// }
			
			auto ticks = EXT_GetTicks();

      		if ((ticks - lastTicks) < 256)
			{
				return;
			}

			lastTicks = ticks;

			if (loaded)
			{
				switchingScene = true;
				
				if (isEnding)
				{
					window.fadeToView("MainMenu", getColorByName("black"), false);
				}
				else if (nextScene)
				{
					_lastScene = scene.name;

					if (nextScene.background == scene.background || !nextScene.background || !nextScene.background.length)
					{
						initializeGame(nextScene.name);
					}
					else
					{
						runDelayedTask(0, {
							window.fadeToView("GameView", getColorByName("black"), false, (view) {
								auto gameView = cast(GameView)view;

								gameView.initializeGame(nextScene.name);
							});
						});
					}
				}
			}
			else
			{
				loaded = true;
				textLabel.text = finalText;
				textLabel.color = textLabel.color.changeAlpha(255);

				if (settings.enableAutoSave)
				{
					runDelayedTask(0, {
						saveCurrentScene("auto");
					});
				}
			}
		}));

		if (scene.effects)
		{
			foreach (effect; scene.effects)
			{
				if (effect.render && effect.render != "post") continue;
				auto e = getEffect(effect.id);
				if (e) e.handle(effect.values);
				DvnEvents.getEvents().onEffectPost(effect);
			}
		}

		DvnEvents.getEvents().renderGameViewOverplayEnd(overlay);

		DvnEvents.getEvents().endGameView();
    }
}
