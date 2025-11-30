module dvn.views.actview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.music;
import dvn.views.settingsview : backToScene;
import dvn.views.gameview;
import dvn.events;
import dvn.views.consoleview;

import dvn.ui;

public final class ActView : View
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

    void initialzieAct(string actName, string continueText, string background, string sceneName)
    {
        logInfo("Act-View: %s", actName);

        DvnEvents.getEvents().beginActView(actName, continueText, background, sceneName);

		auto window = super.window;
		auto settings = getGlobalSettings();

        auto bgImage = new Image(window, background);
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

        DvnEvents.getEvents().renderActBackgroundImage(bgImage);
        
        auto actTitleLabel = new Label(window);
        addComponent(actTitleLabel);
        actTitleLabel.fontName = settings.defaultFont;
        actTitleLabel.fontSize = 48;
        actTitleLabel.color = "fff".getColorByHex;
        actTitleLabel.text = actName.to!dstring;
        actTitleLabel.shadow = true;
        actTitleLabel.position = IntVector(16, 16);
        actTitleLabel.updateRect();

        DvnEvents.getEvents().renderActTitleLabel(actTitleLabel);

        auto beginLabel = new Label(window);
        addComponent(beginLabel);
        beginLabel.fontName = settings.defaultFont;
        beginLabel.fontSize = 48;
        beginLabel.color = "fff".getColorByHex;
        beginLabel.text = continueText.to!dstring;
        beginLabel.shadow = true;
        beginLabel.isLink = true;
        beginLabel.position = IntVector(window.width - (beginLabel.width + 16), window.height - (beginLabel.height + 16));
        beginLabel.updateRect();

        beginLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            runDelayedTask(0, {
                window.fadeToView("GameView", getColorByName("black"), false, (view) {
                    auto gameView = cast(GameView)view;

                    gameView.initializeGame(sceneName);
                });
            });
            return false;
        }));

        DvnEvents.getEvents().renderActBeginLabel(actTitleLabel);

        DvnEvents.getEvents().endActView();
    }
}