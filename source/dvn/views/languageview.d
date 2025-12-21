/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.languageview;

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
import dvn.views.historyview;
import dvn.views.creditsview;
import dvn.views.emptyview;
import dvn.music;
import dvn.events;
import dvn.history;
import dvn.bundling;
import dvn.ui;
import dvn.characters;
import dvn.resourcemanager;

/// 
public final class LanguageView : View
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

        {
			import std.conv : to;

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

        auto languagePanel = new ListPanel(window, 12, true);
		addComponent(languagePanel);
        languagePanel.fillColor = "000".getColorByHex.changeAlpha(150);
		languagePanel.size = IntVector(window.width - 16, window.height);
		languagePanel.position = IntVector(0, 0);
		languagePanel.show();
        
        auto scrollbarLanguages = new ScrollBar(window, languagePanel);
        addComponent(scrollbarLanguages);
        scrollbarLanguages.isVertical = true;
        scrollbarLanguages.fillColor = getColorByRGB(0,0,0,150);
        scrollbarLanguages.borderColor = getColorByRGB(0,0,0,150);
        languagePanel.scrollMargin = IntVector(0,cast(int)((cast(double)languagePanel.height / 3.5) / 2));
        scrollbarLanguages.position = IntVector(languagePanel.x + languagePanel.width, languagePanel.y);
        scrollbarLanguages.buttonScrollAmount = cast(int)((cast(double)languagePanel.height / 3.5) / 2);
        scrollbarLanguages.fontName = settings.defaultFont;
        scrollbarLanguages.fontSize = 8;
        scrollbarLanguages.buttonTextColor = "fff".getColorByHex;
        scrollbarLanguages.createDecrementButton("▲", "◀");
        scrollbarLanguages.createIncrementButton("▼", "▶");
        scrollbarLanguages.size = IntVector(16, languagePanel.height+1);
        scrollbarLanguages.restyle();
        scrollbarLanguages.updateRect(false);

        auto selectLanguageLabel = new Label(window);
        selectLanguageLabel.fontName = settings.defaultFont;
        selectLanguageLabel.fontSize = 22;
        selectLanguageLabel.color = getColorByHex("fff");
        selectLanguageLabel.text = "SELECT LANGUAGE";
        selectLanguageLabel.isLink = false;
        selectLanguageLabel.shadow = true;
        languagePanel.addComponent(selectLanguageLabel);
        selectLanguageLabel.updateRect();
        selectLanguageLabel.show();

        foreach (k,v; settings.languages)
        {
            import std.conv : to;
            
            auto languageLabel = new Label(window);
			languageLabel.fontName = settings.defaultFont;
			languageLabel.fontSize = 22;
			languageLabel.color = getColorByHex("fff");
			languageLabel.text = v.to!dstring;
			languageLabel.isLink = true;
			languageLabel.shadow = true;
			languagePanel.addComponent(languageLabel);
			languageLabel.updateRect();
			languageLabel.show();

            auto closure = (Label oLabel, string selectedLanguage) { return () {
                oLabel.onMouseButtonUp(new MouseButtonEventHandler((b,p) {
                    settings.language = selectedLanguage;

                    saveGameSettings("data/settings.json");

                    window.fadeToView("Loading", getColorByName("black"), false);
                }));
            };};

            closure(languageLabel, k)();
        }

        scrollbarLanguages.restyle();
        scrollbarLanguages.updateRect(false);
        languagePanel.makeScrollableWithWheel();
    }
}