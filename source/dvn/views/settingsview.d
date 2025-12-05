/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.settingsview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;

import dvn.ui;

public string backToScene;

public final class SettingsView : View
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

        void saveSettings()
        {
            saveGameSettings("data/settings.json");
        }

        void restyleCheckbox(CheckBox checkbox, GameSettings gameSettings)
        {
            if (!gameSettings.checkBoxBackgroundColor ||
                !gameSettings.checkBoxBorderColor)
            {
                return;
            }

            auto checkBoxBackgroundColor = gameSettings.checkBoxBackgroundColor;
            auto checkBoxBorderColor = gameSettings.checkBoxBorderColor;

            checkbox.fillColor = checkBoxBackgroundColor.getColorByHex;
            checkbox.borderColor = checkBoxBorderColor.getColorByHex;
        }

        void restyleButton(Button button, GameSettings gameSettings)
        {
			if (!gameSettings.buttonTextColor ||
				!gameSettings.buttonBackgroundColor ||
				!gameSettings.buttonBackgroundBottomColor ||
				!gameSettings.buttonBorderColor)
			{
				return;
			}

			auto buttonTextColor = gameSettings.buttonTextColor;
			auto buttonBackgroundColor = gameSettings.buttonBackgroundColor;
			auto buttonBackgroundBottomColor = gameSettings.buttonBackgroundBottomColor;
			auto buttonBorderColor = gameSettings.buttonBorderColor;

			button.textColor = buttonTextColor.getColorByHex;

            button.defaultPaint.backgroundColor = buttonBackgroundColor.getColorByHex;
            button.defaultPaint.backgroundBottomColor = buttonBackgroundBottomColor.getColorByHex;
            button.defaultPaint.borderColor = buttonBorderColor.getColorByHex;
            button.defaultPaint.shadowColor = buttonBackgroundColor.getColorByHex;

            button.hoverPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(220);
            button.hoverPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(220);
            button.hoverPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(220);
            button.hoverPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(220);

            button.clickPaint.backgroundColor = button.defaultPaint.backgroundColor.changeAlpha(240);
            button.clickPaint.backgroundBottomColor = button.defaultPaint.backgroundBottomColor.changeAlpha(240);
            button.clickPaint.borderColor = button.defaultPaint.borderColor.changeAlpha(240);
            button.clickPaint.shadowColor = buttonBackgroundColor.getColorByHex.changeAlpha(240);

            button.restyle();

            button.show();
        }

		auto music = settings.mainMusic && settings.mainMusic.length ? settings.mainMusic : "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

        DvnEvents.getEvents().renderSettingsViewStart();

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
            if (!backToScene || !backToScene.length)
            {
                window.fadeToView("MainMenu", getColorByName("black"), false);
                return;
            }

            window.fadeToView("GameView", getColorByName("black"), false, (view) {
                auto gameView = cast(GameView)view;
                gameView.loadGame();

                gameView.initializeGame(backToScene);
            });
        }));

		auto settingsPanel = new Panel(window);
		addComponent(settingsPanel);
        settingsPanel.fillColor = "fff".getColorByHex.changeAlpha(150);
        settingsPanel.borderColor = "fff".getColorByHex;
		settingsPanel.size = IntVector(cast(int)(cast(float)window.width * 0.75), cast(int)(cast(float)window.height * 0.9));
		settingsPanel.position = IntVector(
            ((window.width / 2) - (settingsPanel.width / 2)) - 16,
            (window.height /2) - (settingsPanel.height / 2)
        );
		settingsPanel.show();
        
        auto scrollbarSettings = new ScrollBar(window, settingsPanel);
        addComponent(scrollbarSettings);
        scrollbarSettings.isVertical = true;
        scrollbarSettings.fillColor = getColorByRGB(0,0,0,150);
        scrollbarSettings.borderColor = getColorByRGB(0,0,0,150);
        settingsPanel.scrollMargin = IntVector(0,cast(int)((cast(double)settingsPanel.height / 3.5) / 2));
        scrollbarSettings.position = IntVector(settingsPanel.x + settingsPanel.width, settingsPanel.y);
        scrollbarSettings.buttonScrollAmount = cast(int)((cast(double)settingsPanel.height / 3.5) / 2);
        scrollbarSettings.fontName = settings.defaultFont;
        scrollbarSettings.fontSize = 8;
        scrollbarSettings.buttonTextColor = "fff".getColorByHex;
        scrollbarSettings.createDecrementButton("▲", "◀");
        scrollbarSettings.createIncrementButton("▼", "▶");
        scrollbarSettings.size = IntVector(16, settingsPanel.height+1);
        scrollbarSettings.restyle();
        scrollbarSettings.updateRect(false);

        int nextY = 16;

        void renderSection(dstring title)
        {
            auto sectionHeader = new Label(window);
            sectionHeader.fontName = settings.defaultFont;
            sectionHeader.fontSize = 28;
            sectionHeader.color = "cornflowerblue".getColorByName;
            sectionHeader.text = title;
            sectionHeader.shadow = true;
            sectionHeader.isLink = false;
            sectionHeader.position = IntVector(16, nextY);
            sectionHeader.updateRect();
            settingsPanel.addComponent(sectionHeader);

            nextY += sectionHeader.height + 16;

            auto splitter = new Panel(window);
            settingsPanel.addComponent(splitter);
            splitter.fillColor = "444".getColorByHex.changeAlpha(150);
            splitter.borderColor = "666".getColorByHex;
            splitter.size = IntVector(cast(int)(cast(float)settingsPanel.width * 0.8), 4);
            splitter.position = IntVector(
                sectionHeader.x,
                nextY
            );
            splitter.show();

            nextY += sectionHeader.height + 16;
        }

        void renderToggleSetting(dstring text, void delegate(CheckBox) handler, bool delegate() checkedHandler)
        {
            auto label = new Label(window);
            settingsPanel.addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "cornflowerblue".getColorByName;
			label.text = text;
			label.shadow = true;
			label.position = IntVector(16, nextY);
			label.updateRect();

            auto splitter = new Label(window);
            settingsPanel.addComponent(splitter);
			splitter.fontName = settings.defaultFont;
			splitter.fontSize = 18;
			splitter.color = "cornflowerblue".getColorByName;
			splitter.text = " | ";
			splitter.shadow = true;
			splitter.position = IntVector(128, nextY);
			splitter.updateRect();

            auto checkbox = new CheckBox(window);
            checkbox.fillColor = "e5e7e9".getColorByHex;
            checkbox.borderColor = "000".getColorByHex;
            checkbox.size = IntVector(16, 16);
			checkbox.position = IntVector(splitter.x + splitter.width + 14, nextY);
            checkbox.initialize();
            checkbox.checked = checkedHandler();
            settingsPanel.addComponent(checkbox);
            checkbox.onChanged({
                handler(checkbox);
            });
            restyleCheckbox(checkbox, settings);
            checkbox.updateRect();

            DvnEvents.getEvents().renderSettingsCheckBox(checkbox);

            nextY += label.height + 16;
        }

        void renderValueSelector(
            dstring text,
            int value,
            int delegate(int) incrementor, int delegate(int) decrementor,
            dstring leftText, dstring rightText,
            void delegate(int) changed)
        {
            auto label = new Label(window);
            settingsPanel.addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "cornflowerblue".getColorByName;
			label.text = text;
			label.shadow = true;
			label.position = IntVector(16, nextY);
			label.updateRect();

            auto splitter = new Label(window);
            settingsPanel.addComponent(splitter);
			splitter.fontName = settings.defaultFont;
			splitter.fontSize = 18;
			splitter.color = "cornflowerblue".getColorByName;
			splitter.text = " | ";
			splitter.shadow = true;
			splitter.position = IntVector(128, nextY);
			splitter.updateRect();

            auto leftButton = new Button(window);
            settingsPanel.addComponent(leftButton);
            leftButton.size = IntVector(32,24);
            leftButton.position = IntVector(splitter.x + splitter.width + 14, nextY);
            leftButton.fontName = settings.defaultFont;
            leftButton.fontSize = 22;
            leftButton.textColor = "000".getColorByHex;
            leftButton.text = leftText;
            leftButton.fitToSize = false;
            leftButton.restyle();
            leftButton.show();
            restyleButton(leftButton, settings);
            leftButton.updateRect();
            
            auto valueLabel = new Label(window);
            settingsPanel.addComponent(valueLabel);
			valueLabel.fontName = settings.defaultFont;
			valueLabel.fontSize = 18;
			valueLabel.color = "cornflowerblue".getColorByName;
			valueLabel.text = value.to!dstring;
			valueLabel.shadow = true;
			valueLabel.position = IntVector(leftButton.x + leftButton.width + 14, nextY + 3);
			valueLabel.updateRect();
            
            auto rightButton = new Button(window);
            settingsPanel.addComponent(rightButton);
            rightButton.size = IntVector(32,24);
            rightButton.position = IntVector(valueLabel.x + valueLabel.width + 14, nextY);
            rightButton.fontName = settings.defaultFont;
            rightButton.fontSize = 22;
            rightButton.textColor = "000".getColorByHex;
            rightButton.text = rightText;
            rightButton.fitToSize = false;
            rightButton.restyle();
            rightButton.show();
            restyleButton(rightButton, settings);
            rightButton.updateRect();

            int savedY = nextY;

            nextY += label.height + 16;

            leftButton.onButtonClick(new MouseButtonEventHandler((b,p) {
                value = decrementor(value);

                valueLabel.text = value.to!dstring;

                changed(value);

                rightButton.position = IntVector(valueLabel.x + valueLabel.width + 14, savedY);
            }));

            rightButton.onButtonClick(new MouseButtonEventHandler((b,p) {
                value = incrementor(value);

                valueLabel.text = value.to!dstring;

                changed(value);

                rightButton.position = IntVector(valueLabel.x + valueLabel.width + 14, savedY);
            }));

            DvnEvents.getEvents().renderSettingsButton(leftButton);
            DvnEvents.getEvents().renderSettingsButton(rightButton);
        }

        renderSection("VIDEO");

        renderToggleSetting("Full Screen", (checkbox) {
            if (checkbox.checked)
            {
                settings.fullScreen = true;
                saveSettings();
                EXT_SetWindowFullscreen(window.nativeWindow, 1);

            }
            else
            {
                settings.fullScreen = false;
                saveSettings();
                EXT_SetWindowFullscreen(window.nativeWindow, 0);
            }
        }, () { return settings.fullScreen; });

        renderToggleSetting("Character Fade", (checkbox) {
            if (checkbox.checked)
            {
                settings.fadeInCharacters = true;
                saveSettings();

            }
            else
            {
                settings.fadeInCharacters = false;
                saveSettings();
            }
        }, () { return settings.fadeInCharacters; });

        nextY += 16;

        renderSection("AUDIO");

        renderValueSelector("Volume", settings.volume, (value)
        {
            if (value >= 100) return 100;

            return value + 10;
        }, (value)
        {
            if (value <= 0) return value;

            return value - 10;
        }, "-", "+", (value)
        {
            settings.volume = value;

            saveSettings();

            EXT_SetSoundVolume(settings.volume);
            EXT_StopMusic();
            EXT_PlayLastMusic();
        });

        renderToggleSetting("Mute BGM", (checkbox) {
            if (checkbox.checked)
            {
                settings.muteMusic = true;
                saveSettings();
                EXT_DisableMusic();

            }
            else
            {
                settings.muteMusic = false;
                saveSettings();
                EXT_EnableMusic();
                EXT_PlayLastMusic();
            }
        }, () { return settings.muteMusic; });
        
        renderToggleSetting("Mute SFX", (checkbox) {
            if (checkbox.checked)
            {
                settings.muteSoundEffects = true;
                saveSettings();
                EXT_DisableSoundEffects();
            }
            else
            {
                settings.muteSoundEffects = false;
                saveSettings();
                EXT_EnableSoundEffects();
            }
        }, () { return settings.muteSoundEffects; });

        nextY += 16;

        renderSection("GAMEPLAY");
        
        renderToggleSetting("Auto Save", (checkbox) {
            if (checkbox.checked)
            {
                settings.enableAutoSave = true;
                saveSettings();
            }
            else
            {
                settings.enableAutoSave = false;
                saveSettings();
            }
        }, () { return settings.enableAutoSave; });
        
        renderValueSelector("Text Speed", settings.textSpeed, (value)
        {
            if (value >= 512) return 512;

            return value * 2;
        }, (value)
        {
            if (value <= 32) return 32;

            return value / 2;
        }, "-", "+", (value)
        {
            settings.textSpeed = value;

            saveSettings();
        });
        
        scrollbarSettings.restyle();
        scrollbarSettings.updateRect(false);
        settingsPanel.makeScrollableWithWheel();
        DvnEvents.getEvents().renderSettingsViewEnd();
    }
}