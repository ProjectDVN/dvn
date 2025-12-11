/**
* Copyright (c) 2025 Project DVN
*/
module dvn;

public
{
  import dvn.components;
  import dvn.external;
  import dvn.json;

  import dvn.gamesettings;
  import dvn.resources;
  import dvn.views;
  import dvn.music;
  import dvn.events;
  import dvn.gallery;
  import dvn.history;

  import dvn.application;
  import dvn.atlas;
  import dvn.colors;
  import dvn.component;
  import dvn.delayedtask;
  import dvn.events;
  import dvn.fonts;
  import dvn.generator;
  import dvn.i18n;
  import dvn.meta;
  import dvn.painting;
  import dvn.sheetcollection;
  import dvn.surface;
  import dvn.texttools;
  import dvn.tools;
  import dvn.view;
  import dvn.unorderedlist;
  import dvn.window;

  import dvn.network;

  import dvn.css;
  import dvn.dom;
  import dvn.collections;
  import dvn.markdown;

  import dvn.effects;

  import dvn.bundling;

  import dvn.layout;

  import dvn.audio;

  import dvn.characters;
  private string[] _sceneMeta;

/// 
  void clearSceneMeta()
  {
    _sceneMeta = [];
  }
/// 
  void setSceneMeta(string[] meta)
  {
    _sceneMeta = meta;
  }
///
  string[] getLastSceneMeta()
  {
    return _sceneMeta ? _sceneMeta : [];
  }
/// 
  void displayView(string name)
  {
    runDelayedTask(0, {
      getApplication().getRealWindow().fadeToView(name, getColorByName("black"), false);
    });
  }

/// 
  void displayLastSceneView()
  {
    import dvn.views.gameview : getLastScene;

    runDelayedTask(0, {
      getApplication().getRealWindow().fadeToView("GameView", getColorByName("black"), false, (view) {
          auto gameView = cast(GameView)view;
          gameView.loadGame();

          gameView.initializeGame(getLastScene);
      });
    });
  }

/// 
  void displayScene(string scene)
  {
    import dvn.views.settingsview : backToScene;

    runDelayedTask(0, {
      getApplication().getRealWindow().fadeToView("GameView", getColorByName("black"), false, (view) {
          auto gameView = cast(GameView)view;
          gameView.loadGame();

          gameView.initializeGame(scene);
      });
    });
  }

/// 
  void runDVN()
  {
    initializeExternalApplicationState();

    import dvn.extensions;

    registerExtensionEvents();

    DvnEvents.getEvents().loadedExternalApplicationState();

    auto gameSettings = loadGameSettings("data/settings.json");
    DvnEvents.getEvents().loadedSettings(gameSettings);
    setGlobalSettings(gameSettings);
      
    auto app = new Application;
    import std.file : exists;
    app.isDebugMode = exists("debug.txt");
    app.messageLevel = 15;

    foreach (k,v; gameSettings.fonts)
    {
      app.fonts.load(k, v);
    }

    foreach (backupFont; gameSettings.backupFonts)
    {
      app.fonts.addBackupFont(backupFont);
    }

    DvnEvents.getEvents().fontsLoaded(app);

    if (gameSettings.muteMusic) EXT_DisableMusic();
    if (gameSettings.muteSoundEffects) EXT_DisableSoundEffects();
    if (gameSettings.volume > 0)
    {
      EXT_SetSoundVolume(gameSettings.volume);
    }

    auto title = gameSettings.title;

    auto window = app.createWindow(title, IntVector(800, 450), false);
    window.backgroundColor = getColorByName("black");

    window.addView!LoadingView("Loading");
	  window.fadeToView("Loading", getColorByName("black"), false);

    import dvn.views.gameview : GameView;

    if (app.isDebugMode)
    {
      auto consoleWindow = app.createWindow("CONSOLE", IntVector(800, 450), false);
      consoleWindow.isDebugMode = true;
      consoleWindow.backgroundColor = getColorByName("black");

      consoleWindow.addView!ConsoleView("ConsoleView");
      consoleWindow.fadeToView("ConsoleView", getColorByName("black"), false, (v) {
        logInfo("Running in debug mode ...");
      });
    }

    initializeStandardEffects();

    DvnEvents.getEvents().standardEffectsLoaded();

    app.start();
  }
}
