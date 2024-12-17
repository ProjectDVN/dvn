module dvn.views.loadgameview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;

import zid;

public final class LoadGameView : View
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
        backLabel.text = "Back";
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

        auto saveFiles = getSaveFilesPaged(page);

        int saveFileY = 220;

        foreach (saveFile; saveFiles)
        {
            auto saveLabel = new Label(window);
            addComponent(saveLabel);
            saveLabel.fontName = settings.defaultFont;
            saveLabel.fontSize = 24;
            saveLabel.color = "fff".getColorByHex;
            saveLabel.text = (settings.loadText ~ saveFile.date).to!dstring;
            saveLabel.shadow = true;
            saveLabel.isLink = true;
            saveLabel.position = IntVector((window.width / 2) - (saveLabel.width / 2), saveFileY);
            saveLabel.updateRect();

            auto closure = (Label oLabel, SaveFile sFile) { return () {
                oLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    window.fadeToView("GameView", getColorByName("black"), false, (view) {
                        setSaveId(sFile.id);

                    	auto gameView = cast(GameView)view;
                    	gameView.loadGame();

                    	gameView.initializeGame(sFile.scene, sFile.background, sFile.music);
                    });
                }));
            };};

            closure(saveLabel, saveFile)();

            saveFileY += saveLabel.height + 16;
        }
    }
}