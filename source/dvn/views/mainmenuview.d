/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.mainmenuview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;

import dvn.ui;

/// 
public final class MainMenuView : View
{
	public:
	final:
/// 
	this(Window window)
	{
		super(window);
	}

/// 
	protected override void onInitialize(bool useCache)
	{
		EXT_DisableKeyboardState();

		if (useCache) return;
		auto window = super.window;
		auto settings = getGlobalSettings();

		auto music = settings.mainMusic && settings.mainMusic.length ? settings.mainMusic : "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

		import std.file : exists, readText;

		auto language = settings.language && settings.language.length ? settings.language : "EN";

		Component titleLabel;
		Component playLabel;
		Component loadLabel;
		Component historyLabel;
		Component settingsLabel;
		Component galleryLabel;
		Component exitLabel;

		generateHtmlUI(
			language,
			readText("data/game/views/mainmenu.html"),
			readText("data/game/views/mainmenu.css"),
			window,
			this, (c, n)
			{
				auto id = n.getAttribute("id");
				if (!id || !id.value || !id.value.length) return;

				auto button = cast(Button)c;

				switch (id.value)
				{
					case "titleLabel":
						titleLabel = c;
						break;
					case "playLabel":
						playLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("GameView", getColorByName("black"), false, (view) {
									EXT_StopMusic();

									import std.uuid : randomUUID;
									
									auto id = randomUUID().toString;
									setSaveState(id);

									auto gameView = cast(GameView)view;
									gameView.loadGame();

									gameView.initializeGame(settings.mainScript);
								});
								return false;
							}));
						}
						else
						{
							playLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("GameView", getColorByName("black"), false, (view) {
									EXT_StopMusic();
									
									import std.uuid : randomUUID;
									
									auto id = randomUUID().toString;
									setSaveState(id);

									auto gameView = cast(GameView)view;
									gameView.loadGame();

									gameView.initializeGame(settings.mainScript);
								});
							}));
						}
						break;
					case "loadLabel":
						loadLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("LoadGameView", getColorByName("black"), false);
								return false;
							}));
						}
						else
						{
							loadLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("LoadGameView", getColorByName("black"), false);
							}));
						}
						break;
					case "historyLabel":
						historyLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("HistoryView", getColorByName("black"), false);
								return false;
							}));
						}
						else
						{
							historyLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("HistoryView", getColorByName("black"), false);
							}));
						}
						break;
					case "settingsLabel":
						settingsLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("SettingsView", getColorByName("black"), false);
								return false;
							}));
						}
						else
						{
							settingsLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("SettingsView", getColorByName("black"), false);
							}));
						}
						break;
					case "galleryLabel":
						galleryLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("GalleryView", getColorByName("black"), false);
								return false;
							}));
						}
						else
						{
							galleryLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								window.fadeToView("GalleryView", getColorByName("black"), false);
							}));
						}
						break;
					case "exitLabel":
						exitLabel = c;
						if (button)
						{
							button.onButtonClick(new MouseButtonEventHandler((b,p)
							{
								getApplication().stop();
								return false;
							}));
						}
						else
						{
							exitLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p)
							{
								getApplication().stop();
							}));
						}
						break;
					default: break;
				}
			}
		);

		DvnEvents.getEvents().renderMainMenuView(window, titleLabel, playLabel, loadLabel, historyLabel, settingsLabel, galleryLabel, exitLabel);
	}
}
