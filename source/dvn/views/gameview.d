module dvn.views.gameview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.music;
import dvn.views.settingsview : backToScene;
import dvn.views.actview;
import dvn.events;
import dvn.history;

import dvn.ui;

private int _customSceneIdCounter;

public final class SceneEntry
{
	public:
	final:
	string name;
	string act;
	string actContinueButton;
	string music;
	string sound;
	string background;
	SceneLabel[] labels;
	SceneCharacter[] characters;
	SceneCharacterName[] characterNames;
	SceneImage[] images;
	SceneVideo[] videos;
	SceneAnimation[] animations;
	string textColor;
	string textFont;
	string text;
	string nextScene;
	SceneOption[] options;
	string view;
	bool hideDialogue;
	bool hideButtons;

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

private string _saveId;

void setSaveId(string id)
{
	_saveId = id;
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

private bool isAuto;
private string _lastScene;

public string getLastScene()
{
	return _lastScene;
}

public final class GameView : View
{
	public:
	final:
	this(Window window)
	{
		super(window);
	}

	protected override void onInitialize(bool useCache)
	{
		EXT_EnableKeyboardState();
	}

    void loadGame()
    {
		import std.file : dirEntries, SpanMode, readText;
		import std.string : strip;
		import std.array : replace, split;

		DvnEvents.getEvents().loadingGameScripts();
		
		auto settings = getGlobalSettings();

		auto scriptFiles = dirEntries("data/game/scripts","*.{vns}",SpanMode.depth);
		foreach (scriptFile; scriptFiles)
		{
			auto scriptText = readText(scriptFile);

			auto lines = scriptText
				.replace("\r", "")
				.split("\n");

			SceneEntry entry;
			SceneEntry lastEntry;
			SceneCharacter character;
			SceneCharacterName charName;
			SceneCharacterName[] charNames = [];

			string textColor = settings.defaultTextColor && settings.defaultTextColor.length ? settings.defaultTextColor : "fff";
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
					entry = new SceneEntry;
					entry.name = line[1 .. $-1];
					character = null;
					charName = null;
					charNames = [];
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

							default: break;
						}
						continue;
					}

					auto keyData = kv[0].split(":");
					auto key = keyData[0];
					auto value = kv[1];

					switch (key)
					{
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
							
							_customSceneIdCounter++;

							if (lastEntry && lastEntry.text && lastEntry.text.length)
							{
								lastEntry.nextScene = "??????????-" ~ _customSceneIdCounter.to!string;

								entry = new SceneEntry;
								entry.name = "??????????-" ~ _customSceneIdCounter.to!string;

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

							entry.characterNames = charNames;
							charNames = [];
							
							entry.text = value;
							if (keyData.length == 2)
							{
								entry.nextScene = keyData[1];
							}
							else
							{
								entry.nextScene = "??????????-" ~ _customSceneIdCounter.to!string;
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
							option.text = value;
							option.nextScene = keyData[1];
							entry.options ~= option;
							break;

						case "view":
							entry.view = value;
							break;

						default: break;
					}
				}
			}
		}

		DvnEvents.getEvents().loadedGameScripts(_scenes);
    }

    void initializeGame(string sceneName, string loadBackground = "", string loadMusic = "")
    {
		DvnEvents.getEvents().beginGameView(sceneName, loadBackground, loadMusic);

		auto window = super.window;
		auto settings = getGlobalSettings();

		if (!_scenes)
		{
			DvnEvents.getEvents().endGameView();
			
			return;
		}

		auto scene = _scenes.get(sceneName, null);

		if (!scene)
		{
			DvnEvents.getEvents().endGameView();
			
			return;
		}

		clean();

		auto nextScene = _scenes.get(scene.nextScene, null);

		bool isEnding = scene.nextScene == "end";

		DvnEvents.getEvents().beginHandleScene(scene, nextScene, isEnding);

		if (scene.music && scene.music.length)
		{
			_lastMusic = scene.music;

			auto music = getMusicPath(scene.music);

			if (music && music.length)
			{
				EXT_PlayMusic(music);

				DvnEvents.getEvents().playingMusic(music);
			}
		}
		else if (loadMusic && loadMusic.length)
		{
			_lastMusic = loadMusic;

			auto music = getMusicPath(loadMusic);

			if (music && music.length)
			{
				EXT_PlayMusic(music);

				DvnEvents.getEvents().playingMusic(music);
			}
		}
		else if (_lastMusic && _lastMusic.length)
		{
			auto music = getMusicPath(_lastMusic);

			if (music && music.length)
			{
				EXT_PlayMusic(music);

				DvnEvents.getEvents().playingMusic(music);
			}
		}

		if (scene.sound && scene.sound.length)
		{
			auto sound = getMusicPath(scene.sound);

			if (sound && sound.length)
			{
				EXT_PlaySound(sound);

				DvnEvents.getEvents().playingSound(sound);
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
		overlay.show();

		DvnEvents.getEvents().renderGameViewOverplayBegin(overlay);

		auto backgroundSource = (scene.background ?
			scene.background : ((loadBackground && loadBackground.length) ?
				loadBackground : _lastBackgroundSource));

		auto bgImage = new Image(window, backgroundSource);
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

		DvnEvents.getEvents().renderGameViewBackground(bgImage);

		_lastBackgroundSource = backgroundSource;

		if (scene.characters)
		{
			foreach (character; scene.characters)
			{
				if (character.image && character.position)
				{
					auto chImage = new Image(window, character.image);
					addComponent(chImage);

					if (character.characterFadeIn)
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

			DvnEvents.getEvents().renderGameViewDialoguePanelImage(rawImage);
		}

		auto textPanel = new Panel(window);
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
		if (scene.hideDialogue)
		{
			textPanel.hide();
		}

		DvnEvents.getEvents().renderGameViewDialoguePanel(textPanel);

		if (settings.dialoguePanelImage)
		{
			textPanel.fillColor = textPanel.fillColor.changeAlpha(0);
			textPanel.borderColor = textPanel.borderColor.changeAlpha(0);
		}

		foreach (charNameAndPos; scene.characterNames)
		{
			auto charNameLabel = new Label(window);
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
			if (!gameSettings.buttonTextColor ||
				!gameSettings.buttonBackgroundColor ||
				!gameSettings.buttonBackgroundBottomColor ||
				!gameSettings.buttonBorderColor)
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

			saveGame(settings, idToSave, scene.name, _lastBackgroundSource, _lastMusic);

			saveGameSettings("data/settings.json");
		}

		if (scene.text)
		{
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

			addDialogueHistory(historyText, null, scene.name, _lastBackgroundSource, _lastMusic);

			textLabel = new Label(window);
			textPanel.addComponent(textLabel);
			textLabel.fontName = settings.defaultFont;
			if (scene.textFont && scene.textFont.length)
			{
				textLabel.fontName = scene.textFont;
			}
			textLabel.fontSize = 22;
			textLabel.color = scene.textColor.getColorByHex;
			textLabel.text = "";
			textLabel.shadow = true;
			textLabel.wrapText(textPanel.width - 16);
			textLabel.position = IntVector(16, 16);
			textLabel.updateRect();

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

			addDialogueHistory(null, optionHistory, scene.name, _lastBackgroundSource, _lastMusic);

			if (settings.displayOptionsAsButtons)
			{
				if (!scene.text)
				{
					textPanel.hide();
				}

				int lastY = 168;
				foreach (option; scene.options)
				{
					auto optionButton = new Button(window);
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
					auto optionLabel = new Label(window);
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

		Component[] safeComponents = [saveButton, exitButton, settingsButton, autoButton, quickSaveButton];

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

				if (settings.enableAutoSave)
				{
					runDelayedTask(0, {
						saveCurrentScene("auto");
					});
				}
			}
		}));

		DvnEvents.getEvents().renderGameViewOverplayEnd(overlay);

		DvnEvents.getEvents().endGameView();
    }
}
