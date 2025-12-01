/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.videoloadingview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;
import dvn.music;

import dvn.ui;

public final class VideoLoadingView : View
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

		if (settings.videoLoadingMusic && settings.videoLoadingMusic.length)
        {
            auto music = getMusicPath(settings.videoLoadingMusic);

            if (music && music.length)
            {
                EXT_PlayMusic(music);
            }
        }

        auto video = new Video(window, settings.videoLoadingScreen);
        addComponent(video);
        video.size = IntVector(1280, 720);
        video.position = IntVector(0, 0);
        video.onFinishedVideo({
            window.fadeToView("MainMenu", getColorByName("black"), false);
        });
        
        video.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
			window.fadeToView("MainMenu", getColorByName("black"), false);
		}));

		video.onKeyboardUp(new KeyboardEventHandler((k) {
			if (k == KeyboardKey.escape)
			{
				window.fadeToView("MainMenu", getColorByName("black"), false);
			}
		}), true);

        DvnEvents.getEvents().renderVideoLoadingView(video);
    }
}