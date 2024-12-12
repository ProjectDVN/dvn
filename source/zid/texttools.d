module zid.texttools;

private static __gshared bool[uint] safeCharacters;

package(zid) void initializeTextTools()
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

bool isForeignCharacter(dchar c)
{
  uint code = cast(uint)c;

  if (code <= 128) return false;

  return safeCharacters && !safeCharacters.get(code, false);
}

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
