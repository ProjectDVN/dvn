/**
* Copyright (c) 2025 Project DVN
*/
module dvn.gamesettings;

import dvn.meta;
import dvn.events;

mixin CreateCustomException!"GameSettingsException";

public final class GameSettings
{
  public:
  final:
  this() {}

  string[string] fonts;
  string[] backupFonts;
  string defaultFont;
  string defaultTextColor;

  bool muteMusic;
  bool muteSoundEffects;
  int volume;

  string mainScript;
  int textSpeed;
  string title;
  string loadTitle;
  SaveFile[string] saves;

  bool fullScreen;

  string[string] defaultCharacterNameColors;
  string dialoguePanelBackgroundColor;
  string dialoguePanelBorderColor;
  string namePanelBackgroundColor;
  string namePanelBorderColor;

  string loadText;
  string backText;

  string[string] meta;

  string saveButtonText;
  string exitButtonText;
  string settingsButtonText;
  string autoButtonTextOn;
  string autoButtonTextOff;
  string quickSaveButtonText;
  
  string customStartView;

  string videoLoadingScreen;
  string videoLoadingMusic;

  bool disableLoadScreenMusic;
  SettingsImage dialoguePanelImage;
  SettingsImage namePanelImage;

  string loadingMusic;
  string mainMusic;

  string mainBackgroundVideo;

  string buttonTextColor;
  string buttonBackgroundColor;
  string buttonBackgroundBottomColor;
  string buttonBorderColor;
  string dropdownTextColor;
  string dropDownBackgroundColor;
  string dropDownBorderColor;
  string checkBoxBackgroundColor;
  string checkBoxBorderColor;
  string textBoxColor;
  string textBoxTextColor;
  string textBoxBorderColor;

  bool displayOptionsAsButtons;
  bool enableAutoSave;
  bool fadeInText;

  int textMargin;
  int textWrapSize;
  bool fadeInCharacters;
  bool hideSavedLabel;
  bool useLegacySceneButtons;

  int saveFileTextMatchPercentage;

  bool useLegacyCharacters;
  string useLegacyCharacterSplit;

  bool disableSwipeGesture;
  bool disableContinueArrow;
  int autoSpeed;

  bool clickTextBoxtoAdvance;
  int textPanelOpacityLevel;
  bool hideAutoIndicator;
  bool highlightNewText;
  string highlightNewTextColor;

  int windowFadeTime;
}

public final class SettingsImage
{
  public:
  final:
  string path;
  SettingsSize size;
}

public final class SettingsSize
{
  public:
  final:
  int width;
  int height;
}

public final class SaveFile
{
  public:
  final:
  this() {}

  string id;
  string date;
  string originalScene;
  string scene;
  string text;
  string background;
  string music;
  string[string] meta;
  uint seed;
  int calls;
}

private SaveFile[] saveFiles;

void saveGame(GameSettings settings, string id, string originalScene, string scene, string text, string background, string music, uint seed, int calls)
{
  import std.uuid : randomUUID;
  import std.datetime : Clock;
  import std.string : format;

  if (!id || !id.length)
  {
    id = randomUUID().toString;
  }

  auto date = Clock.currTime();
  auto year = date.year;
  auto month = cast(int)date.month;
  auto day = date.day;
  auto hour = date.hour;
  auto min = date.minute;

  SaveFile saveFile;
  if (settings.saves)
  {
    saveFile = settings.saves.get(id, null);
  }

  if (!saveFile)
  {
    saveFile = new SaveFile;
  }

  saveFile.id = id;
  saveFile.date = format("%s-%s-%s %s:%s", year, cast(int)month, day, hour, min);
  saveFile.originalScene = originalScene;
  saveFile.scene = scene;
  saveFile.text = text;
  saveFile.background = background;
  saveFile.music = music;
  saveFile.seed = seed;
  saveFile.calls = calls;

  settings.saves[id] = saveFile;

  DvnEvents.getEvents().savingGame(settings.saves, saveFile);

  if (!settings.hideSavedLabel)
  {
    if (saveFile.id != "auto")
		{
      import dvn.application;
      import dvn.delayedtask;
      import dvn.components;
      import dvn.ui;
      import dvn.views.gameview;

			auto window = getApplication().getRealWindow();

			if (!window) return;

			auto view = window.getActiveView!GameView("GameView");

			if (!view) return;

			auto saveLabel = new Label(window);
      view.addComponent(saveLabel);
      saveLabel.fontName = settings.defaultFont;
      saveLabel.fontSize = 24;
      saveLabel.color = "fff".getColorByHex;
      saveLabel.text = "Saved...";
      saveLabel.shadow = true;
      saveLabel.isLink = false;
      saveLabel.position = IntVector(16, 16);
      saveLabel.updateRect();

			runDelayedTask(2000, {
				saveLabel.hide();

				try { view.removeComponent(saveLabel); }
				catch (Exception e) { }
      });
		}
  }

  updateSaveFiles(settings);
}

void updateSaveFiles(GameSettings settings)
{
  SaveFile[] s = [];

  auto autoSave = settings.saves ? settings.saves.get("auto", null) : null;
  if (autoSave) s ~= autoSave;

  auto quickSave = settings.saves ? settings.saves.get("quick", null) : null;
  if (quickSave) s ~= quickSave;

  foreach (k,v; settings.saves)
  {
    if (k == "auto") continue;
    if (k == "quick") continue;
    s ~= v;
  }

  saveFiles = s;
}

SaveFile[] getSaveFilesPaged(int page)
{
  SaveFile[] s = [];

  int skip = page * 6;
  int take = 6;
    
  foreach (i; skip .. (skip + take))
  {
    if (i >= saveFiles.length) continue;
      
    auto saveFile = saveFiles[i];
    s ~= saveFile;
  }

  return s;
}

private GameSettings _settings;

GameSettings loadGameSettings(string path)
{
  if (_settings || !path || !path.length)
  {
    return _settings;
  }

  import std.file : readText;
  import dvn.json;

  string text = readText(path);
  string[] errorMessages;
  GameSettings settings;
  if (!deserializeJsonSafe!GameSettings(text, settings, errorMessages))
  {
    throw new GameSettingsException(errorMessages[0]);
  }

  _settings = settings;

  if (_settings && _settings.saves)
  {
    updateSaveFiles(_settings);
  }

  return settings;
}

private __gshared GameSettings globalSettings;

void setGlobalSettings(GameSettings settings)
{
  globalSettings = settings;
}

GameSettings getGlobalSettings() { return globalSettings; }

void saveGameSettings(string path)
{
  if (!globalSettings || !path || !path.length)
  {
    return;
  }

  import std.file : write;
  import dvn.json;
  
  string serializedJson;
  if (!serializeJsonSafe(globalSettings, serializedJson, true))
  {
    return;
  }

  write(path, serializedJson);
}