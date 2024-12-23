module dvn.views.loadingview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.mainmenuview;
import dvn.views.gameview;
import dvn.views.settingsview;
import dvn.views.actview;
import dvn.views.loadgameview;
import dvn.views.videoloadingview;
import dvn.views.galleryview;
import dvn.views.photoview;
import dvn.music;
import dvn.events;

import dvn.ui;

public final class LoadingView : View
{
	public:
	final:
	this(Window window)
	{
		super(window);
	}

	protected override void onInitialize(bool useCache)
	{
		DvnEvents.getEvents().loadingGame();

		import std.random : uniform;
		
		EXT_DisableKeyboardState();

		if (useCache) return;
		auto window = super.window;
		auto settings = getGlobalSettings();

		EXT_SetWindowBordered(window.nativeWindow, EXT_bool.SDL_FALSE);

		if (!settings.disableLoadScreenMusic)
		{
			auto music = "data/music/main.mp3";

			if (music && music.length)
			{
				EXT_PlayMusic(music);
			}
		}
		
		auto loadingText = settings.loadTitle;

		{
			import std.conv : to;

			// auto vpath = "data/backgrounds/loading/" ~ uniform(1,4).to!string ~ ".png";
			auto vpath = "data/backgrounds/loading.png";
			auto k = "LoadingBackground";
			auto entryname = "LoadingBackground";
			auto vsizewidth = 800;
			auto vsizeheight = 450;

			window.addSheet(k, vpath, IntVector(vsizewidth, vsizeheight), 1);

			window.addSheetEntry(entryname, k, 0, 0);

			auto bgImage = new Image(window, "LoadingBackground");
			addComponent(bgImage);
			bgImage.position = IntVector(
				(window.width / 2) - (bgImage.width / 2),
				(window.height / 2) - (bgImage.height / 2));
			bgImage.show();
		}

		{
			auto vpath = "data/images/SDL_Logo.png";
			auto k = "SDL_Logo";
			auto entryname = "SDL_Logo";
			auto vsizewidth = 90;
			auto vsizeheight = 50;

			window.addSheet(k, vpath, IntVector(vsizewidth, vsizeheight), 1);

			window.addSheetEntry(entryname, k, 0, 0);

			auto SDLLogo = new Image(window, "SDL_Logo");
			addComponent(SDLLogo);
			SDLLogo.position = IntVector(
				window.width - (vsizewidth + 12),
				12
			);
			SDLLogo.show();
		}

		auto loadingLabel = new Label(window);
		addComponent(loadingLabel);
		loadingLabel.fontName = "Calibri";
		loadingLabel.fontSize = 18;
		loadingLabel.color = getColorByHex("fff");
    	loadingLabel.text = (loadingText ~ " .").to!dstring;
		loadingLabel.position = IntVector(12, 12);
		loadingLabel.shadow = true;
    	loadingLabel.updateRect();
    	loadingLabel.show();

		int counter = 2;
		auto loaded = false;

		runDelayedTask(1250, (d) {
			auto dots = "";
			foreach (_; 0 .. counter)
			{
				dots ~= ".";
			}
			counter++;
			if (counter > 3)
			{
				counter = 1;
			}

			if (loaded)
			{
				loadingLabel.text = (loadingText ~ " ...").to!dstring;
				loadingLabel.updateRect();
				loadingLabel.show();
				return true;
			}

			loadingLabel.text = (loadingText ~ " " ~ dots).to!dstring;
			loadingLabel.updateRect();
			loadingLabel.show();

			return loaded;
		}, true);

		runDelayedTask(4000, {
			auto mainWindow = window.application.createWindow(settings.title, IntVector(1280, 720), settings.fullScreen);
			if (!settings.fullScreen) EXT_HideWindow(mainWindow.nativeWindow);

			void addResources(Resource[string] resources)
			{
				foreach (k,v; resources)
				{
					if (v.randomPath && v.randomPath.length)
					{
						import std.random : uniform;

						v.path = v.randomPath[uniform(0,v.randomPath.length)];
					}

					mainWindow.addSheet(k, v.path, IntVector(v.size.width, v.size.height), v.columns ? v.columns : 1);

					if (v.entries && v.entries.length)
					{
						foreach (entry; v.entries)
						{
							mainWindow.addSheetEntry(entry.name, k, entry.row, entry.col);
						}
					}
					else
					{
						mainWindow.addSheetEntry(k, k, 0, 0);
					}
				}
			}

			auto generalResources = loadResources("data/resources/main.json");
			appendResources(generalResources, "data/game/backgrounds.json");
			appendResources(generalResources, "data/game/characters.json");
			appendResources(generalResources, "data/game/animations.json");
			addResources(generalResources);

			loadMusic("data/game/music.json");

			loaded = true;

			DvnEvents.getEvents().loadedGame();

			loadingLabel.text = (loadingText ~ " ...").to!dstring;
			loadingLabel.updateRect();
			loadingLabel.show();

			mainWindow.backgroundColor = getColorByName("black");

			mainWindow.addView!MainMenuView("MainMenu");
			mainWindow.addView!GameView("GameView");
			mainWindow.addView!SettingsView("SettingsView");
			mainWindow.addView!ActView("ActView");
			mainWindow.addView!LoadGameView("LoadGameView");
			mainWindow.addView!VideoLoadingView("VideoLoadingView");
			mainWindow.addView!GalleryView("GalleryView");
			mainWindow.addView!PhotoView("PhotoView");

			DvnEvents.getEvents().loadingViews(mainWindow);
			
			if (settings.customStartView && settings.customStartView.length)
			{
				mainWindow.fadeToView(settings.customStartView, getColorByName("black"), false);
			}
			else if (settings.videoLoadingScreen && settings.videoLoadingScreen.length)
			{
				mainWindow.fadeToView("VideoLoadingView", getColorByName("black"), false);
			}
			else
			{
				mainWindow.fadeToView("MainMenu", getColorByName("black"), false);
			}

			if (!settings.fullScreen) EXT_ShowWindow(mainWindow.nativeWindow);

			window.remove();
		});
	}
}
