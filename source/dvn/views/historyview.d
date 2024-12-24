module dvn.views.historyview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;
import dvn.history;

import dvn.ui;

public final class HistoryView : View
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

		if (useCache) return;
		auto window = super.window;
		auto settings = getGlobalSettings();

		auto music = settings.mainMusic && settings.mainMusic.length ? settings.mainMusic : "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

        showResults("");
    }

    void showResults(string input)
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

        auto searchTextBox = new TextBox(window);
        addComponent(searchTextBox);
        searchTextBox.fontName = settings.defaultFont;
        searchTextBox.fontSize = 24;
        searchTextBox.size = IntVector((window.width / 100) * 50, 42);
        searchTextBox.position = IntVector(
            (window.width / 2) - (searchTextBox.width / 2),
            42);
        searchTextBox.textColor = "fff".getColorByHex;
        searchTextBox.maxCharacters = 128;
        searchTextBox.textPadding = 8;
        searchTextBox.text = input.to!dstring;

        searchTextBox.restyle();

		auto searchButton = new Button(window);
		addComponent(searchButton);
        searchButton.size = IntVector((window.width / 100) * 50, 42);
        searchButton.position = IntVector(
            (window.width / 2) - (searchButton.width / 2),
            searchTextBox.y + searchTextBox.height + 16);
		searchButton.fontName = settings.defaultFont;
		searchButton.fontSize = 24;
		searchButton.textColor = "000".getColorByHex;
		searchButton.text = "Search";
		searchButton.fitToSize = false;

		searchButton.restyle();

		searchButton.show();

        searchButton.onButtonClick(new MouseButtonEventHandler((b,p) {
            showResults(searchTextBox.text.to!string);
        }));

        auto historyPanel = new Panel(window);
        historyPanel.fillColor = getColorByRGB(0,0,0,150);
        historyPanel.size = IntVector(searchButton.width - 16, window.height - (searchButton.y + searchButton.height + 32));
        historyPanel.position = IntVector(searchButton.x, searchButton.y + searchButton.height + 16);
        addComponent(historyPanel);

        auto scrollbarMessages = new ScrollBar(window, historyPanel);
        addComponent(scrollbarMessages);
        scrollbarMessages.isVertical = true;
        scrollbarMessages.fillColor = getColorByRGB(0,0,0,150);
        scrollbarMessages.borderColor = getColorByRGB(0,0,0,150);
        historyPanel.scrollMargin = IntVector(0,cast(int)((cast(double)historyPanel.height / 3.5) / 2));
        scrollbarMessages.position = IntVector(historyPanel.x + historyPanel.width, historyPanel.y);
        scrollbarMessages.buttonScrollAmount = cast(int)((cast(double)historyPanel.height / 3.5) / 2);
        scrollbarMessages.fontName = settings.defaultFont;
        scrollbarMessages.fontSize = 8;
        scrollbarMessages.buttonTextColor = "fff".getColorByHex;
        scrollbarMessages.createDecrementButton("▲", "◀");
        scrollbarMessages.createIncrementButton("▼", "▶");
        scrollbarMessages.size = IntVector(16, historyPanel.height);
        scrollbarMessages.restyle();
        scrollbarMessages.updateRect(false);

        auto result = searchDialogueHistory(searchTextBox.text.to!string);

        string toMaxCharacters(string s)
        {
            string newS = "";

            foreach (c; s)
            {
                if (newS.length >= 128)
                {
                    newS ~= "...";
                    break;
                }

                newS ~= c;
            }

            return newS;
        }

        int y = 0;
        foreach (history; result)
        {
            auto closure = (Label oLabel, DialogueHistory oHistory) { return () {
                oLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    window.fadeToView("GameView", getColorByName("black"), false, (view) {
                        import std.uuid : randomUUID;
                        
                        auto id = randomUUID().toString;
                        setSaveId(id);

                        auto gameView = cast(GameView)view;
                        gameView.loadGame();

                        gameView.initializeGame(oHistory.sceneName, oHistory.sceneBackground, oHistory.sceneMusic);
                    });
                }));
            };};

            if (history.text)
            {
                auto historyLabel = new Label(window);
                historyLabel.fontName = settings.defaultFont;
                historyLabel.fontSize = 18;
                historyLabel.color = "fff".getColorByHex;
                historyLabel.text = toMaxCharacters(history.text).to!dstring;
                historyLabel.shadow = true;
                historyLabel.isLink = true;
                historyLabel.position = IntVector(8, y);
                historyLabel.wrapText(historyPanel.width - 4);
                historyLabel.updateRect();
                historyPanel.addComponent(historyLabel);

                closure(historyLabel, history)();

                y += historyLabel.height + 8;
            }
            else if (history.options)
            {
                foreach (o; history.options)
                {
                    auto historyLabel = new Label(window);
                    historyLabel.fontName = settings.defaultFont;
                    historyLabel.fontSize = 18;
                    historyLabel.color = "fff".getColorByHex;
                    historyLabel.text = ("[" ~ toMaxCharacters(o) ~ "]").to!dstring;
                    historyLabel.shadow = true;
                    historyLabel.isLink = true;
                    historyLabel.position = IntVector(8, y);
                    historyLabel.wrapText(historyPanel.width - 4);
                    historyLabel.updateRect();
                    historyPanel.addComponent(historyLabel);

                    closure(historyLabel, history)();

                    y += historyLabel.height + 8;
                }
            }
        }
        
        scrollbarMessages.restyle();
        scrollbarMessages.updateRect(false);
    }
}