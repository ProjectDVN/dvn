module dvn.views.mainmenuview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;

import zid;

public final class MainMenuView : View
{
	public:
	final:
	this(Window window)
	{
		super(window);
	}

	protected override void onInitialize(bool useCache)
	{
		EXT_DisableKeyboardState();

		if (useCache) return;
		auto window = super.window;
		auto settings = getGlobalSettings();

		auto music = "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

		loadGenerator("data/game/views/mainmenuview.json", "MainMenuViewUI");
		loadTheme("data/game/views/mainmenutheme.json", "default", true);

		UIGenerator generator;
		Label titleLabel;
		Label playLabel;
		Label loadLabel;
		Label settingsLabel;
		Label exitLabel;
		if (tryGetGenerator("MainMenuViewUI", generator))
		{
			generateUI("EN_US", window, this, generator, (component,eventName,componentName)
			{
				switch (componentName)
				{
					case "titleLabel":
						titleLabel = cast(Label)component;
						switch (eventName)
						{
							case "initialize":
								break;

							default: break;
						}
						break;

					case "playLabel":
						playLabel = cast(Label)component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
								playLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
									window.fadeToView("GameView", getColorByName("black"), false, (view) {
										auto gameView = cast(GameView)view;
										gameView.loadGame();

										gameView.initializeGame(settings.mainScript);
									});
								}));
								break;

							default: break;
						}
						break;

					case "loadLabel":
						loadLabel = cast(Label)component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
								loadLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
									window.fadeToView("GameView", getColorByName("black"), false, (view) {
										auto gameView = cast(GameView)view;
										gameView.loadGame();

										gameView.initializeGame(settings.saveScene, settings.saveBackground, settings.saveMusic);
									});
								}));
								break;

							default: break;
						}
						break;

					case "settingsLabel":
						settingsLabel = cast(Label)component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
								settingsLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
									window.fadeToView("SettingsView", getColorByName("black"), false);
								}));
								break;

							default: break;
						}
						break;

					case "exitLabel":
						exitLabel = cast(Label)component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
								exitLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
									getApplication().stop();
								}));
								break;

							default: break;
						}
						break;

					default: break;
				}
			});
		}
	}
}
