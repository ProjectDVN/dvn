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

		auto music = settings.mainMusic && settings.mainMusic.length ? settings.mainMusic : "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

		loadGenerator("data/game/views/mainmenuview.json", "MainMenuViewUI");
		loadTheme("data/game/views/mainmenutheme.json", "default", true);

		UIGenerator generator;
		Component titleLabel;
		Component playLabel;
		Component loadLabel;
		Component historyLabel;
		Component settingsLabel;
		Component galleryLabel;
		Component exitLabel;
		if (tryGetGenerator("MainMenuViewUI", generator))
		{
			generateUI("EN_US", window, this, generator, (component,eventName,componentName)
			{
				auto button = cast(Button)component;
				switch (componentName)
				{
					case "titleLabel":
						titleLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							default: break;
						}
						break;

					case "playLabel":
						playLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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

							default: break;
						}
						break;

					case "loadLabel":
						loadLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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

							default: break;
						}
						break;

					case "historyLabel":
						historyLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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

							default: break;
						}
						break;

					case "settingsLabel":
						settingsLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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

							default: break;
						}
						break;

					case "galleryLabel":
						galleryLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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

							default: break;
						}
						break;

					case "exitLabel":
						exitLabel = component;
						switch (eventName)
						{
							case "initialize":
								break;

							case "mouseUp":
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
						break;

					default: break;
				}
			});
		}

		DvnEvents.getEvents().renderMainMenuView(window, titleLabel, playLabel, loadLabel, historyLabel, settingsLabel, galleryLabel, exitLabel);
	}
}
