module dvn.views.galleryview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.views.photoview;
import dvn.events;
import dvn.gallery;

import dvn.ui;

public final class GalleryView : View
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

        renderLoadPage();
    }

    private int page = 0;

    void renderLoadPage()
    {
		auto window = super.window;
		auto settings = getGlobalSettings();

        clean();

        auto bgImage = new Image(window, "MainMenuBackground");
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
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
            window.fadeToView("MainMenu", getColorByName("black"), false);
        }));

        auto prevLabel = new Label(window);
        addComponent(prevLabel);
        prevLabel.fontName = settings.defaultFont;
        prevLabel.fontSize = 34;
        prevLabel.color = "fff".getColorByHex;
        prevLabel.text = "<<";
        prevLabel.shadow = true;
        prevLabel.isLink = true;
        prevLabel.position = IntVector(16, (window.height / 2) - (prevLabel.height / 2));
        prevLabel.updateRect();

        prevLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            page -= 1;
            if (page <= 0)
            {
                page = 0;
            }

            renderLoadPage();
        }));

        //DvnEvents.getEvents().renderLoadGameViewPrevLabel(prevLabel);

        auto nextLabel = new Label(window);
        addComponent(nextLabel);
        nextLabel.fontName = settings.defaultFont;
        nextLabel.fontSize = 34;
        nextLabel.color = "fff".getColorByHex;
        nextLabel.text = ">>";
        nextLabel.shadow = true;
        nextLabel.isLink = true;
        nextLabel.position = IntVector(window.width - (nextLabel.width + 16), (window.height / 2) - (nextLabel.height / 2));
        nextLabel.updateRect();

        nextLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            page += 1;
            if (page >= 100)
            {
                page = 100;
            }

            renderLoadPage();
        }));

        //DvnEvents.getEvents().renderLoadGameViewNextLabel(nextLabel);

        auto galleryFiles = getGalleryPaged(page);

        int galleryIndex = 0;
        int galleryX = 0;
        int galleryY = 125 + 15;

        foreach (y; 0 .. 2)
        {
            galleryX = 120;

            foreach (x; 0 .. 3)
            {
                if (galleryIndex >= galleryFiles.length)
                {
                    break;
                }

                auto galleryFile = galleryFiles[galleryIndex];

                auto rawImage = new RawImage(window, galleryFile, IntVector(1280, 720));
                addComponent(rawImage);
                rawImage.size = IntVector(340, 196);
                rawImage.position = IntVector(galleryX, galleryY);
 
                auto closure = (RawImage oImage, string sFile) { return () {
                    oImage.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                        window.fadeToView("PhotoView", getColorByName("black"), false, (view) {
                            auto photoView = cast(PhotoView)view;
                            photoView.showPhoto(sFile);
                        });
                    }));

                    bool rawImageHasMouseHover = false;
                    oImage.onMouseMove(new MouseMoveEventHandler((p) {
                        rawImageHasMouseHover = oImage.intersectsWith(p);

                        if (rawImageHasMouseHover && oImage.isEnabled)
                        {
                            EXT_SetHandCursor();
                        }
                        else
                        {
                            EXT_ResetCursor();
                        }

                        return !rawImageHasMouseHover;
                    }));
                };};

                closure(rawImage, galleryFile)();

                //DvnEvents.getEvents().renderLoadGameViewLoadEntry(saveFile, rawImage, saveLabel);

                galleryIndex++;
                galleryX += 340 + 16;
            }

            galleryY += 196 + 16;
        }
    }
}