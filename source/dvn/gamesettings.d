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

  bool dialogueHistory;
  
  string customStartView;

  string videoLoadingScreen;
  string videoLoadingMusic;

  bool disableLoadScreenMusic;
}

public final class SaveFile
{
  public:
  final:
  this() {}

  string id;
  string date;
  string scene;
  string background;
  string music;
  string[string] meta;
}

private SaveFile[] saveFiles;

void saveGame(GameSettings settings, string id, string scene, string background, string music)
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
  saveFile.scene = scene;
  saveFile.background = background;
  saveFile.music = music;

  settings.saves[id] = saveFile;

  DvnEvents.getEvents().savingGame(settings.saves, saveFile);

  updateSaveFiles(settings);
}

void updateSaveFiles(GameSettings settings)
{
  SaveFile[] s = [];

  foreach (k,v; settings.saves)
  {
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