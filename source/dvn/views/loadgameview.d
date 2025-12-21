/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.loadgameview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;

import dvn.ui;

/// 
public final class LoadGameView : View
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

        renderLoadPage();
    }

    private int page = 0;

/// 
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

        if (settings.mainBackgroundVideo && settings.mainBackgroundVideo.length)
        {
            auto video = new Video(window, settings.mainBackgroundVideo);
            addComponent(video);
            video.size = IntVector(1280, 720);
            video.position = IntVector(0, 0);
        }
        
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

        DvnEvents.getEvents().renderLoadGameViewBackLabel(backLabel);

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

        void movePreviousPage()
        {
            page -= 1;
            if (page <= 0)
            {
                page = 0;
            }

            renderLoadPage();
        }

        void moveNextPage()
        {
            page += 1;
            if (page >= 100)
            {
                page = 100;
            }

            renderLoadPage();
        }

        prevLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            movePreviousPage();
        }));

        DvnEvents.getEvents().renderLoadGameViewPrevLabel(prevLabel);

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
            moveNextPage();
        }));

        DvnEvents.getEvents().renderLoadGameViewNextLabel(nextLabel);

        auto saveFiles = getSaveFilesPaged(page);

        int saveIndex = 0;
        int saveX = 0;
        int saveY = 125;

        foreach (y; 0 .. 2)
        {
            saveX = 120;

            foreach (x; 0 .. 3)
            {
                if (saveIndex >= saveFiles.length)
                {
                    break;
                }

                auto saveFile = saveFiles[saveIndex];

                auto rawImage = new Image(window, "data/game/saves/" ~ saveFile.id ~ ".png", true);
                addComponent(rawImage);
                rawImage.size = IntVector(340, 196);
                rawImage.position = IntVector(saveX, saveY);
                
                auto saveLabel = new Label(window);
                addComponent(saveLabel);
                saveLabel.fontName = settings.defaultFont;
                saveLabel.fontSize = 24;
                saveLabel.color = "fff".getColorByHex;

                auto loadingText = settings.loadText ~ saveFile.date;

                if (saveFile.id == "auto")
                {
                    loadingText = "(A) " ~ loadingText;
                }
                else if (saveFile.id == "quick")
                {
                    loadingText = "(Q) " ~ loadingText;
                }

                saveLabel.text = (loadingText).to!dstring;
                saveLabel.shadow = true;
                saveLabel.isLink = true;
                saveLabel.position = IntVector(
                    rawImage.x + ((rawImage.width / 2) - (saveLabel.width / 2)),
                    rawImage.y + rawImage.height + 6
                );
                saveLabel.updateRect();

                auto closure = (Label oLabel, Image oImage, SaveFile sFile) { return () {
                    oLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                        window.fadeToView("GameView", getColorByName("black"), false, (view) {
                            EXT_StopMusic();

                            if (sFile.id == "auto" || sFile.id == "quick")
                            {
                                import std.uuid : randomUUID;
											
                                auto id = randomUUID().toString;
                                setSaveState(id, sFile.seed);
                            }
                            else
                            {
                                setSaveState(sFile.id, sFile.seed);
                            }

                            auto gameView = cast(GameView)view;
                            gameView.loadGame(sFile);

                            gameView.initializeGame(sFile.scene, sFile.background, sFile.music, sFile.originalScene, sFile.text);
                        });
                    }));

                    oImage.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                        window.fadeToView("GameView", getColorByName("black"), false, (view) {
                            EXT_StopMusic();

                            if (sFile.id == "auto" || sFile.id == "quick")
                            {
                                import std.uuid : randomUUID;
											
                                auto id = randomUUID().toString;
                                setSaveState(id, sFile.seed);
                            }
                            else
                            {
                                setSaveState(sFile.id, sFile.seed);
                            }

                            auto gameView = cast(GameView)view;
                            gameView.loadGame(sFile);

                            gameView.initializeGame(sFile.scene, sFile.background, sFile.music, sFile.originalScene, sFile.text);
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

                closure(saveLabel, rawImage, saveFile)();

                DvnEvents.getEvents().renderLoadGameViewLoadEntry(saveFile, rawImage, saveLabel);

                saveIndex++;
                saveX += 340 + 16;
            }

            saveY += 196 + 16 + 30;
        }

        if (!settings.disableSwipeGesture)
        {
            auto overlay = new Panel(window);
            addComponent(overlay);
		    overlay.isInputComponent = true;
            overlay.size = IntVector(window.width, window.height);
            overlay.position = IntVector(0,0);
            overlay.enableSwiping((b,d,p)
            {
                if (d != SwipeDirection.left &&
                    d != SwipeDirection.right)
                {
                    return true;
                }

                if (d == SwipeDirection.left)
                {
                    moveNextPage();
                }
                else
                {
                    movePreviousPage();
                }

                return false;
            });
            overlay.show();
        }
    }
}