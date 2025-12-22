/**
* Copyright (c) 2025 Project DVN
*/
module dvn.i18n;

import dvn.meta;

/// 
mixin CreateCustomException!"LocalizationException";

private alias STRING_MAP = string[string];
private alias LocalizationMap = STRING_MAP[string];

private LocalizationMap[string] _languageMaps;
private LocalizationMap _defaultMap;

/// 
void loadLanguageMap(string path, string name, bool isDefault = false)
{
  if (!path || !path.length || !name || !name.length)
  {
    return;
  }

  import std.file : readText;
  import dvn.json;

  string text = readText(path);
  string[] errorMessages;
  LocalizationMap localizationMap;
  if (!deserializeJsonSafe!(LocalizationMap)(text, localizationMap, errorMessages))
  {
    throw new LocalizationException(errorMessages[0]);
  }

  if (!localizationMap || !localizationMap.length)
  {
    return;
  }

  if (_defaultMap)
  {
    LocalizationMap temp;

    foreach (k,v; _defaultMap)
    {
      foreach (kk,vv; v)
      {
        temp[k][kk] = vv;
      }
    }

    foreach (k,v; localizationMap)
    {
      foreach (kk,vv; v)
      {
        temp[k][kk] = vv;
      }
    }

    localizationMap = temp;
  }

  if (isDefault)
  {
    _defaultMap = localizationMap;
  }

  _languageMaps[name] = localizationMap;
}

/// 
bool tryGetLocalizationEntry(string language, string key, string value, out string result)
{
  result = null;

  auto languageMap = _languageMaps.get(language, null);

  if (!languageMap || !languageMap.length)
  {
    return false;
  }

  auto localizedResult = languageMap.get(key, null);

  if (!localizedResult || !localizedResult.length)
  {
    return false;
  }

  auto localizedValue = localizedResult.get(value, null);

  if (!localizedValue || !localizedValue.length)
  {
    return false;
  }

  result = parseLocalizedString(language, localizedValue);

  return true;
}

/// 
string parseLocalizedString(string language, string s)
{
  import std.conv : to;
  import std.array : split;

  string currentResult = "";

  string currentEntry = "";
  bool parseEntryValue = false;
  foreach (ref i; 0 .. s.length)
  {
    auto c = s[i];
    auto next = (s.length > 1 && i < (s.length - 1)) ? s[i + 1] : '\0';

    if (c == '{' && next == '{')
    {
      if (currentEntry && currentEntry.length)
      {
        currentResult ~= currentEntry;
        currentEntry = "";
      }

      parseEntryValue = true;
      i++;
    }
    else if (c == '}' && next == '}')
    {
      if (currentEntry && currentEntry.length)
      {
        auto entryData = currentEntry.split("|");
        auto keyValue = entryData[0].split("::");
        auto key = keyValue[0];
        auto value = keyValue[1];
        string[] functions = entryData.length == 2 ? entryData[1].split(";") : [];

        string result;
        if (tryGetLocalizationEntry(language, key, value, result))
        {
          // auto resultData = result.split("|"); -- keeping this commented out, not sure why we did this in the first place, so keeping it just in case...

          if (functions && functions.length)
          {
            import std.uni : toUpper,toLower;

            foreach (fn; functions)
            {
              switch (fn)
              {
                case "uppercase": result = result.toUpper; break;
                case "lowercase": result = result.toLower; break;
                default:break;
              }
            }
          }

          currentResult ~= result;
          currentEntry = "";
          result = "";
        }
      }

      parseEntryValue = false;
      i++;
    }
    else
    {
      currentEntry ~= c.to!string;
    }
  }

  if (currentEntry && currentEntry.length)
  {
    currentResult ~= currentEntry;
  }

  return currentResult;
}
