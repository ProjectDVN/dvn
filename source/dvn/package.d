module dvn;

public
{
  import dvn.gamesettings;
  import dvn.resources;
  import dvn.views;
  import dvn.music;
  import dvn.events;

  void displayView(string name)
  {
    import zid;
    
    runDelayedTask(0, {
      getApplication().windows[0].fadeToView(name, getColorByName("black"), false);
    });
  }

  void displayLastSceneView()
  {
    import zid;
    import dvn.views.settingsview : backToScene;

    runDelayedTask(0, {
      getApplication().windows[0].fadeToView("GameView", getColorByName("black"), false, (view) {
          auto gameView = cast(GameView)view;
          gameView.loadGame();

          gameView.initializeGame(backToScene);
      });
    });
  }

  void displayScene(string scene)
  {
    import zid;
    import dvn.views.settingsview : backToScene;

    runDelayedTask(0, {
      getApplication().windows[0].fadeToView("GameView", getColorByName("black"), false, (view) {
          auto gameView = cast(GameView)view;
          gameView.loadGame();

          gameView.initializeGame(scene);
      });
    });
  }

  void runDVN()
  {
    import zid;
    
    auto gameSettings = loadGameSettings("data/settings.json");
    setGlobalSettings(gameSettings);
      
    auto app = new Application;
    app.messageLevel = 15;

    foreach (k,v; gameSettings.fonts)
    {
      app.fonts.load(k, v);
    }

    foreach (backupFont; gameSettings.backupFonts)
    {
      app.fonts.addBackupFont(backupFont);
    }

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

    app.start();
  }
}
