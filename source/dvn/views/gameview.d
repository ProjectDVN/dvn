module dvn.views.gameview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.music;
import dvn.views.settingsview : backToScene;
import dvn.views.actview;
import dvn.events;

import zid;

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
	SceneAnimation[] animations;
	string textColor;
	string textFont;
	string text;
	string nextScene;
	SceneOption[] options;
	string view;
	bool hideDialogue;
	bool hideButtons;
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
			SceneCharacter character;
			SceneCharacterName charName;
			string textColor = "fff";
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
					textColor = "fff";
					entry.textColor = "fff";

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
							entry.background = value;
							break;

						case "music":
							entry.music = value;
							break;

						case "sound":
							entry.sound = value;
							break;

						case "char":
							character = new SceneCharacter;
							character.image = value;
							character.position = "bottomCenter";
							entry.characters ~= character;
							break;

						case "charName":
							charName = new SceneCharacterName;
							charName.name = value;
							charName.color = "fff";
							if (settings.defaultCharacterNameColors)
							{
								charName.color = settings.defaultCharacterNameColors.get(charName.name, "fff");
							}
							charName.position = "left";
							entry.characterNames ~= charName;
							break;

						case "charColor":
							charName.color = value;
							break;

						case "charPos":
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
							charName.position = value;
							break;

						case "textColor":
							entry.textColor = value;
							break;

						case "image":
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

						case "animation":
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
							entry.textFont = value;
							break;

						case "text":
							entry.text = value;
							entry.nextScene = keyData[1];
							break;

						case "act":
							entry.act = value;
							entry.nextScene = keyData[1];
							entry.actContinueButton = keyData[2];
							break;

						case "option":
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

					switch (character.position)
					{
						case "center":
							chImage.position = IntVector(
								(window.width / 2) - (chImage.width / 2),
								(window.height / 2) - (chImage.height / 2));
							break;

						case "left":
							chImage.position = IntVector(
								0,
								(window.height / 2) - (chImage.height / 2));
							break;
							
						case "right":
							chImage.position = IntVector(
								(window.width - chImage.width),
								(window.height / 2) - (chImage.height / 2));
							break;

						case "bottomCenter":
							chImage.position = IntVector(
								(window.width / 2) - (chImage.width / 2),
								(window.height - chImage.height));
							break;

						case "bottomRight":
							chImage.position = IntVector(
								(window.width - chImage.width),
								(window.height - chImage.height));
							break;

						case "bottomLeft":
							chImage.position = IntVector(
								0,
								(window.height - chImage.height));
							break;

						case "topCenter":
							chImage.position = IntVector(
								(window.width / 2) - (chImage.width / 2),
								0);
							break;

						case "topRight":
							chImage.position = IntVector(
								(window.width - chImage.width),
								0);
							break;

						case "topLeft":
							chImage.position = IntVector(
								0,
								0);
							break;

						case "topSlightLeft":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								0);
							break;
						case "topSlightRight":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								0);
							break;
						case "slightLeft":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								(window.height / 2) - (chImage.height / 2));
							break;
						case "slightRight":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								(window.height / 2) - (chImage.height / 2));
							break;
						case "bottomSlightLeft":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) -
								chImage.width / 2,
								window.height - chImage.height);
							break;
						case "bottomSlightRight":
							chImage.position = IntVector(
								((window.width / 2) - (chImage.width / 2)) +
								chImage.width / 2,
								window.height - chImage.height);
							break;

						default:
							if (character.position == "")
							{
								chImage.position = IntVector(character.x, character.y);
							}
							break;
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

			DvnEvents.getEvents().renderGameViewCharacterName(charNameAndPos, charNameLabel, charNamePanel);
		}

		bool hasOptions = false;

		dstring finalText = scene.text ? scene.text.to!dstring : "".to!dstring;
		dstring currentText = "";
		size_t _offset = 0;
		
		Label textLabel;

		bool loaded = false;
		bool switchingScene = false;

		bool disableEvents = false;

		if (scene.text)
		{
			if (settings.dialogueHistory && _saveId && _saveId.length)
			{
				import std.file : exists, mkdir, append;
				import std.array : join;

				if (!exists("data/history"))
				{
					mkdir("data/history");
				}

				auto historyText = scene.text;

				if (scene.characterNames && scene.characterNames.length)
				{
					string[] names = [];

					foreach (name; scene.characterNames)
					{
						names ~= name.name;
					}

					historyText = names.join(",") ~ ": " ~ historyText;
				}

				append("data/history/" ~ _saveId ~ ".txt", historyText ~ "\r\n");
			}

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
		else if (scene.options && scene.options.length)
		{
			hasOptions = true;

			if (settings.dialogueHistory && _saveId && _saveId.length)
			{
				import std.file : exists, mkdir, append;
				import std.array : join;

				if (!exists("data/history"))
				{
					mkdir("data/history");
				}

				string[] optionHistory = ["----"];

				foreach (option; scene.options)
				{
					optionHistory ~= "<" ~ option.text ~ ">";
				}

				optionHistory ~= "----";

				auto historyText = optionHistory.join("\r\n");

				append("data/history/" ~ _saveId ~ ".txt", historyText ~ "\r\n");
			}

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
							if (nScene.background == scene.background)
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
			//settings.saveScene = scene.name;
			//settings.saveBackground = _lastBackgroundSource;
			//settings.saveMusic = _lastMusic;

			saveGame(settings, _saveId, scene.name, _lastBackgroundSource, _lastMusic);

			saveGameSettings("data/settings.json");
			return false;
		}));

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

		DvnEvents.getEvents().renderGameViewAutoButton(autoButton);

		if (scene.hideButtons) autoButton.hide();

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

					DvnEvents.getEvents().renderGameViewTextFinished(textLabel);
				}
			}
		}), true);

		Component[] safeComponents = [saveButton, exitButton, settingsButton, autoButton];

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
			}
		}));

		DvnEvents.getEvents().renderGameViewOverplayEnd(overlay);

		DvnEvents.getEvents().endGameView();
    }
}
