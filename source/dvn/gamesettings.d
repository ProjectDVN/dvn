module dvn.gamesettings;

import zid.meta;

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
  string saveScene;
  string saveBackground;
  string saveMusic;

  bool fullScreen;

  string[string] defaultCharacterNameColors;
}

private GameSettings _settings;

GameSettings loadGameSettings(string path)
{
  if (_settings || !path || !path.length)
  {
    return _settings;
  }

  import std.file : readText;
  import zid.json;

  string text = readText(path);
  string[] errorMessages;
  GameSettings settings;
  if (!deserializeJsonSafe!GameSettings(text, settings, errorMessages))
  {
    throw new GameSettingsException(errorMessages[0]);
  }

  _settings = settings;
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
  import zid.json;
  
  string serializedJson;
  if (!serializeJsonSafe(globalSettings, serializedJson, true))
  {
    return;
  }

  write(path, serializedJson);
}