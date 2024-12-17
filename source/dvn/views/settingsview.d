module dvn.views.settingsview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;

import zid;

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

		auto music = "data/music/main.mp3";

		if (music && music.length)
		{
			EXT_PlayMusic(music);
		}

        auto bgImage = new Image(window, "MainMenuBackground");
        addComponent(bgImage);
        bgImage.position = IntVector(
            (window.width / 2) - (bgImage.width / 2),
            (window.height / 2) - (bgImage.height / 2));
        bgImage.show();

        void saveSettings()
        {
            saveGameSettings("data/settings.json");
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

        int nextY = backLabel.y + backLabel.height + 16;
        int settingsOffsetY = 104;
        int settingsOffsetYSmall = 52;

        // full screen
        {
            auto label = new Label(window);
            addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "fff".getColorByHex;
			label.text = "Full screen?";
			label.shadow = true;
			label.position = IntVector(260, nextY + 3);
			label.updateRect();

            auto checkbox = new CheckBox(window);
            checkbox.fillColor = "e5e7e9".getColorByHex;
            checkbox.borderColor = "000".getColorByHex;
            addComponent(checkbox);
            
            DvnEvents.getEvents().renderSettingsCheckBox(checkbox);

            checkbox.size = IntVector(24, 24);
            checkbox.position = IntVector(
                window.width - (checkbox.width + 260),
                nextY
            );
            checkbox.initialize();
            checkbox.checked = settings.fullScreen;
            checkbox.updateRect();
            checkbox.onChanged({
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
            });
            
            nextY += settingsOffsetYSmall + checkbox.height;
        }

        // mute music
        {
            auto label = new Label(window);
            addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "fff".getColorByHex;
			label.text = "Mute music?";
			label.shadow = true;
			label.position = IntVector(260, nextY + 3);
			label.updateRect();

            auto checkbox = new CheckBox(window);
            checkbox.fillColor = "e5e7e9".getColorByHex;
            checkbox.borderColor = "000".getColorByHex;
            addComponent(checkbox);
            
            DvnEvents.getEvents().renderSettingsCheckBox(checkbox);

            checkbox.size = IntVector(24, 24);
            checkbox.position = IntVector(
                window.width - (checkbox.width + 260),
                nextY
            );
            checkbox.initialize();
            checkbox.checked = settings.muteMusic;
            checkbox.updateRect();
            checkbox.onChanged({
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
            });
            
            nextY += settingsOffsetYSmall + checkbox.height;
        }
        
        // mute sound effects
        {
            auto label = new Label(window);
            addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "fff".getColorByHex;
			label.text = "Mute sound effects?";
			label.shadow = true;
			label.position = IntVector(260, nextY + 3);
			label.updateRect();

            auto checkbox = new CheckBox(window);
            checkbox.fillColor = "e5e7e9".getColorByHex;
            checkbox.borderColor = "000".getColorByHex;
            addComponent(checkbox);
            
            DvnEvents.getEvents().renderSettingsCheckBox(checkbox);

            checkbox.size = IntVector(24, 24);
            checkbox.position = IntVector(
                window.width - (checkbox.width + 260),
                nextY
            );
            checkbox.initialize();
            checkbox.checked = settings.muteSoundEffects;
            checkbox.updateRect();
            checkbox.onChanged({
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
            });
            
            nextY += settingsOffsetYSmall + checkbox.height;
        }

        // volume
        {
            auto label = new Label(window);
            addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "fff".getColorByHex;
			label.text = "Volume";
			label.shadow = true;
			label.position = IntVector(260, nextY + 3);
			label.updateRect();

            auto dropdown = new DropDown(window);
            addComponent(dropdown);
            dropdown.size = IntVector(190, 24);
            dropdown.position = IntVector(
                window.width - (dropdown.width + 260),
                nextY
            );
            dropdown.fontName = settings.defaultFont;
            dropdown.fontSize = 18;
            dropdown.textColor = "000".getColorByHex;

            DvnEvents.getEvents().renderSettingsDropDown(dropdown);
            dropdown.restyle();

            dropdown.addItem("10", 10);
            dropdown.addItem("20", 20);
            dropdown.addItem("30", 30);
            dropdown.addItem("40", 40);
            dropdown.addItem("50", 50);
            dropdown.addItem("60", 60);
            dropdown.addItem("70", 70);
            dropdown.addItem("80", 80);
            dropdown.addItem("90", 90);
            dropdown.addItem("100", 100);
            dropdown.setItem(settings.volume.to!dstring);

            dropdown.show();

            dropdown.onItemChanged((value)
            {
                settings.volume = value.to!int;
                saveSettings();
                EXT_SetSoundVolume(settings.volume);
                EXT_StopMusic();
                EXT_PlayLastMusic();
            });

            nextY += settingsOffsetY + dropdown.height;
        }

        // text speed
        {
            auto label = new Label(window);
            addComponent(label);
			label.fontName = settings.defaultFont;
			label.fontSize = 18;
			label.color = "fff".getColorByHex;
			label.text = "Dialogue Text Speed";
			label.shadow = true;
			label.position = IntVector(260, nextY + 3);
			label.updateRect();

            auto dropdown = new DropDown(window);
            addComponent(dropdown);
            dropdown.size = IntVector(190, 24);
            dropdown.position = IntVector(
                window.width - (dropdown.width + 260),
                nextY
            );
            dropdown.fontName = settings.defaultFont;
            dropdown.fontSize = 18;
            dropdown.textColor = "000".getColorByHex;

            DvnEvents.getEvents().renderSettingsDropDown(dropdown);
            dropdown.restyle();

            dropdown.addItem("32", 32);
            dropdown.addItem("64", 64);
            dropdown.addItem("128", 128);
            dropdown.addItem("256", 256);
            dropdown.addItem("512", 512);
            dropdown.setItem(settings.textSpeed.to!dstring);

            dropdown.show();

            dropdown.onItemChanged((value)
            {
                settings.textSpeed = value.to!int;
                saveSettings();
            });

            nextY += settingsOffsetY + dropdown.height;
        }
    }
}