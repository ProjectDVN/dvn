/**
* Copyright (c) 2025 Project DVN
*/
module dvn.fonts;

import dvn.external;
import dvn.meta;

mixin CreateCustomException!"FontException";

/// 
public final class FontCollection
{
  private:
  Font[string] _fonts;
  string[] _backupFonts;

  public:
  final:
/// 
  this()
  {
    _backupFonts = [];
  }

  @property
  {
/// 
    size_t length() { return _fonts ? _fonts.length : 0; }
  }

/// 
  void addBackupFont(string name)
  {
    if (get(name) is null)
    {
      throw new FontException("Failed to add the backup font. (Not initialized.)");
    }

    _backupFonts ~= name;
  }

/// 
  void load(string name, string path)
  {
    import std.file : exists;

    if (!name || !name.length)
    {
      throw new ArgumentException(name.stringof);
    }

    if (!path || !path.length)
    {
      throw new ArgumentException(path.stringof);
    }

    if (!exists(path))
    {
      throw new FontException("Cannot find the font path: %s".format(path));
    }

    _fonts[name] = new Font(name, path);
  }

/// 
  Font get(string name)
  {
    return _fonts.get(name, null);
  }

/// 
  bool tryGet(string name, out Font font)
  {
    font = _fonts.get(name, null);

    return font !is null;
  }

/// 
  bool supportsChar(string name, dchar c)
	{
		auto runtimeFont = get(name);

    if (runtimeFont is null) return false;

		auto rawFont = EXT_GetFont(runtimeFont.path, 18);

		return EXT_FontGlyphSupport(rawFont, c) > 0;
	}

/// 
	bool supportsText(string name, dstring s)
	{
		foreach (c; s)
		{
			if (!supportsChar(name, c))
			{
				return false;
			}
		}

		return true;
	}

/// 
  Font getWithFallback(string name, dstring text)
  {
    if (!_backupFonts || !_backupFonts.length)
    {
      return get(name);
    }

    auto fonts = [name];
    fonts ~= _backupFonts;

    foreach (font; fonts)
    {
      if (supportsText(font, text))
      {
        return get(font);
      }
    }

    return get(name);
  }

/// 
  bool tryGetWithFallback(string name, dstring text, out Font font)
  {
    font = getWithFallback(name, text);

    return font !is null;
  }

/// 
  void unload(string name)
  {
    if (!_fonts) return;

    _fonts.remove(name);
  }
}

/// 
public final class Font
{
  private:
  string _name;
  string _path;

  public:
  final:
/// 
  this(string name, string path)
  {
    _name = name;
    _path = path;
  }

  @property
  {
/// 
    string name() { return _name; }
/// 
    string path() { return _path; }
  }
}
