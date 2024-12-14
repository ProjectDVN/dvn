module dvn.views.gameview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.music;
import dvn.views.settingsview : backToScene;
import dvn.views.actview;

import zid;

public final class SceneEntry
{
	string name;
	string act;
	string actContinueButton;
	string music;
	string sound;
	string background;
	SceneCharacter[] characters;
	SceneCharacterName[] characterNames;
	SceneImage[] images;
	SceneAnimation[] animations;
	string textColor;
	string text;
	string nextScene;
	SceneOption[] options;
}

public final class SceneCharacter
{
	string image;
	string position;
}

public final class SceneCharacterName
{
	string name;
	string color;
	string position;
}

public final class SceneOption
{
	string text;
	string nextScene;
}

public final class SceneImage
{
	string source;
	int x;
	int y;
	string position;
}

public final class SceneAnimation
{
	string source;
	int x;
	int y;
	string position;
	bool repeat;
}

private SceneEntry[string] _scenes;

private string _lastBackgroundSource;
private string _lastMusic;

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
							charName.position = "left";
							entry.characterNames ~= charName;
							break;

						case "charColor":
							charName.color = value;
							break;

						case "charPos":
							character.position = value;
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

						default: break;
					}
				}
			}
		}
    }

    void initializeGame(string sceneName, string loadBackground = "", string loadMusic = "")
    {
		auto window = super.window;
		auto settings = getGlobalSettings();

		if (!_scenes)
		{
			return;
		}

		auto scene = _scenes.get(sceneName, null);

		if (!scene)
		{
			return;
		}

		clean();

		auto nextScene = _scenes.get(scene.nextScene, null);

		bool isEnding = scene.nextScene == "end";

		if (scene.music && scene.music.length)
		{
			_lastMusic = scene.music;

			auto music = getMusicPath(scene.music);

			if (music && music.length)
			{
				EXT_PlayMusic(music);
			}
		}
		else if (loadMusic && loadMusic.length)
		{
			_lastMusic = loadMusic;

			auto music = getMusicPath(loadMusic);

			if (music && music.length)
			{
				EXT_PlayMusic(music);
			}
		}

		if (scene.sound && scene.sound.length)
		{
			auto sound = getMusicPath(scene.sound);

			if (sound && sound.length)
			{
				EXT_PlaySound(sound);
			}
		}

		if (scene.act && scene.act.length)
		{
			runDelayedTask(0, {
                window.fadeToView("ActView", getColorByName("black"), false, (view) {
                    auto actView = cast(ActView)view;

                    actView.initialzieAct(scene.act, scene.actContinueButton, scene.background, scene.nextScene);
                });
            });
			return;
		}

		auto overlay = new Panel(window);
		addComponent(overlay);
		overlay.size = IntVector(window.width, window.height);
		overlay.position = IntVector(0,0);
		overlay.show();

		auto backgroundSource = (scene.background ?
			scene.background : (_lastBackgroundSource ?
				_lastBackgroundSource : loadBackground));

		auto bgImage = new Image(window, backgroundSource);
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

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

						default: break;
					}

					chImage.show();
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
			}
		}

		auto textPanel = new Panel(window);
		addComponent(textPanel);
		textPanel.fillColor = "000".getColorByHex.changeAlpha(150);
		textPanel.borderColor = "000".getColorByHex;
		textPanel.size = IntVector(
			(window.width / 100) * 90,
			(window.height / 100) * 33);
		textPanel.position = IntVector(
			((window.width / 2) - (textPanel.width / 2)),
			window.height - (textPanel.height + 14)
		);
		textPanel.show();

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
			charNamePanel.fillColor = "000".getColorByHex.changeAlpha(150);
			charNamePanel.borderColor = "000".getColorByHex;
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
		}

		bool hasOptions = false;

		dstring finalText = scene.text ? scene.text.to!dstring : "".to!dstring;
		dstring currentText = "";
		size_t _offset = 0;
		
		Label textLabel;

		bool loaded = false;
		bool switchingScene = false;

		if (scene.text)
		{
			textLabel = new Label(window);
			textPanel.addComponent(textLabel);
			textLabel.fontName = settings.defaultFont;
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

				return loaded;
			}, true);
		}
		else if (scene.options && scene.options.length)
		{
			hasOptions = true;

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
			}
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
		saveButton.text = "Save";
		saveButton.fitToSize = false;

		saveButton.restyle();

		saveButton.show();

		saveButton.onButtonClick(new MouseButtonEventHandler((p,b) {
			settings.saveScene = scene.name;
			settings.saveBackground = _lastBackgroundSource;
			settings.saveMusic = _lastMusic;
			saveGameSettings("data/settings.json");
			return false;
		}));

		auto exitButton = new Button(window);
		addComponent(exitButton);
		exitButton.size = IntVector(64, 28);
		exitButton.position = IntVector(
			(saveButton.x + saveButton.width) - exitButton.width,
			saveButton.y + saveButton.height + 12);
		exitButton.fontName = settings.defaultFont;
		exitButton.fontSize = 18;
		exitButton.textColor = "000".getColorByHex;
		exitButton.text = "Exit";
		exitButton.fitToSize = false;

		exitButton.restyle();

		exitButton.show();

		exitButton.onButtonClick(new MouseButtonEventHandler((p,b) {
			backToScene = "";
			window.fadeToView("MainMenu", getColorByName("black"), false);
			return false;
		}));

		auto settingsButton = new Button(window);
		addComponent(settingsButton);
		settingsButton.size = IntVector(92, 28);
		settingsButton.position = IntVector(
			saveButton.x,
			saveButton.y + saveButton.height + 12);
		settingsButton.fontName = settings.defaultFont;
		settingsButton.fontSize = 18;
		settingsButton.textColor = "000".getColorByHex;
		settingsButton.text = "Settings";
		settingsButton.fitToSize = false;

		settingsButton.restyle();

		settingsButton.show();

		settingsButton.onButtonClick(new MouseButtonEventHandler((p,b) {
			backToScene = scene.name;
			window.fadeToView("SettingsView", getColorByName("black"), false);
			return false;
		}));

		bool intersectsWith(int x1, int y1, int x2, int y2, int w2, int h2)
		{
			return (x1 > x2) &&
				(x1 < (x2 + w2)) &&
				(y1 > y2) &&
				(y1 < (y2 + h2));
		}
		

		overlay.onKeyboardUp(new KeyboardEventHandler((k) {
			if (switchingScene || hasOptions)
			{
				return;
			}
			
			if (k == KeyboardKey.returnKey)
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
			}
		}), true);

		overlay.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
			if (switchingScene || hasOptions)
			{
				return;
			}

			if (intersectsWith(p.x, p.y, saveButton.x, saveButton.y, saveButton.width, saveButton.height))
			{
				return;
			}

			if (intersectsWith(p.x, p.y, exitButton.x, exitButton.y, exitButton.width, exitButton.height))
			{
				return;
			}

			if (intersectsWith(p.x, p.y, settingsButton.x, settingsButton.y, settingsButton.width, settingsButton.height))
			{
				return;
			}

			if (loaded)
			{
				switchingScene = true;
				
				if (isEnding)
				{
					window.fadeToView("MainMenu", getColorByName("black"), false);
				}
				else if (nextScene)
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
			}
			else
			{
				loaded = true;
				textLabel.text = finalText;
			}
		}));
    }
}
