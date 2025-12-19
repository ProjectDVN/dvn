/**
* Copyright (c) 2025 Project DVN
*/
module dvn.texttools;

private static __gshared bool[uint] safeCharacters;

package(dvn) void initializeTextTools()
{
  dstring[] safeStrings =
  [
    "abcdefghijklmnopqrstuvwxyz",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "æøåÆØÅ",
    "äëïöüÿÄËÏÖÜ",
    "âêîôûÂÊÎÔÛ",
    "ß"
  ];

  foreach (dstring safeString; safeStrings)
  {
    foreach (dchar c; safeString)
    {
      safeCharacters[cast(uint)c] = true;
    }
  }
}

/// 
bool isForeignCharacter(dchar c)
{
  uint code = cast(uint)c;

  if (code <= 128) return false;

  return safeCharacters && !safeCharacters.get(code, false);
}

/// 
bool isForeignText(dstring s)
{
  foreach (dchar c; s)
  {
    if (c.isForeignCharacter)
    {
      return true;
    }
  }

  return false;
}

bool isKanji(dchar c)
{
            // CJK Unified Ideographs
    return (c >= 0x4E00 && c <= 0x9FFF) ||
            // CJK Unified Ideographs Extension A
           (c >= 0x3400 && c <= 0x4DBF) ||
           // CJK Compatibility Ideographs
           (c >= 0xF900 && c <= 0xFAFF);
}