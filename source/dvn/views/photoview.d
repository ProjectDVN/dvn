module dvn.views.photoview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;
import dvn.gallery;

import dvn.ui;

public final class PhotoView : View
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
    }

    void showPhoto(string path)
    {
		auto window = super.window;
		auto settings = getGlobalSettings();

        auto bgImage = new RawImage(window, path, IntVector(1280, 720));
        addComponent(bgImage);
        bgImage.size = IntVector(1280, 720);
        bgImage.position = IntVector(0,0);
        bgImage.show();
        
        auto backLabel = new Label(window);
        addComponent(backLabel);
        backLabel.fontName = settings.defaultFont;
        backLabel.fontSize = 24;
        backLabel.color = "fff".getColorByHex;
        backLabel.text = settings.backText.to!dstring;
        backLabel.shadow = true;
        backLabel.isLink = true;
        backLabel.position = IntVector(16, 16);
        backLabel.updateRect();

        backLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            window.fadeToView("GalleryView", getColorByName("black"), false);
        }));
    }
}