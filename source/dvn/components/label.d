/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.label;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.fonts;
import dvn.colors;
import dvn.texttools;
import dvn.events;

public final class Label : Component
{
  private:
  dstring _text;
  dstring _textString;
  Color _color;
  string _fontName;
  size_t _fontSize;
  bool _wrapText;
  size_t _wrapWidth;
  bool _shadow;
  bool _isLink;
  Color _shadowColor;
  int _lineSpacing;

  EXT_TextEntry[] _entries;
  EXT_TextEntry[] _shadowEntries;

  bool _hasMouseHover;

  public:
  final:
  this(Window window)
  {
    super(window, false);

    super.size = IntVector(window.width, window.height);

    onMouseMove(new MouseMoveEventHandler((p) {
      _hasMouseHover = super.intersectsWith(p);

      if (_isLink && _hasMouseHover && super.isEnabled)
      {
        EXT_SetHandCursor();
      }
      else
      {
        EXT_ResetCursor();
      }

      return !_hasMouseHover;
    }));

    _shadowColor = "000".getColorByHex;
    _lineSpacing = 0;
  }

  @property
  {
    int lineSpacing() { return _lineSpacing; }
    void lineSpacing(int value)
    {
      _lineSpacing = value;
    }
    bool isLink() { return _isLink; }
    void isLink(bool newIsLink)
    {
      _isLink = newIsLink;
    }
    dstring text() { return _textString; }
    void text(dstring newText)
    {
      _textString = newText;

      updateRect(true);
    }

    bool shadow() { return _shadow; }
    void shadow(bool useShadow)
    {
      _shadow = useShadow;

      updateRect(true);
    }

    Color color() { return _color; }
    void color(Color newColor)
    {
      _color = newColor;

      updateRect(true);
    }

    Color shadowColor() { return _shadowColor; }
    void shadowColor(Color newColor)
    {
      _shadowColor = newColor;

      updateRect(true);
    }

    string fontName() { return _fontName; }
    void fontName(string newFontName)
    {
      _fontName = newFontName;

      updateRect(true);
    }

    size_t fontSize() { return _fontSize; }
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;

      updateRect(true);
    }
  }

  void wrapText(size_t wrapWidth)
  {
    _wrapWidth = wrapWidth;
    _wrapText = wrapWidth > 0;

    updateRect(true);
  }

  private dstring wrapableText(dstring text)
  {
    if (!text || !text.length)
    {
      return "";
    }

    import std.uni : isWhite;
    import std.conv : to;

    auto width = _wrapWidth;

    width -= (_fontSize / 2);

    Font runtimeFont;
    if (!super.window.application.fonts.tryGetWithFallback(_fontName, text, runtimeFont))
    {
      return "";
    }

    bool[] splitIndexes = new bool[text.length];
    bool[] includeSplitters = new bool[text.length];

    dstring calculateText = "";

    ptrdiff_t lastWhiteIndex = -1;
    bool hasForeignCharacters = false;

    auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);

    if (!rawFont)
    {
      throw new Exception("No raw font.");
    }

    foreach (ref i; 0 .. text.length)
    {
      dchar c = text[i];
      bool isForeign = c.isForeignCharacter;

      if (!hasForeignCharacters && isForeign)
      {
        width -= cast(size_t)(cast(double)_fontSize * 1.2);

        hasForeignCharacters = true;
      }

      if (c.isWhite || isForeign)
      {
        lastWhiteIndex = i;
      }

      calculateText ~= c;

      int w;
      int h;
      wstring utf16String = (calculateText.to!wstring);
      ushort[] utf16Buffer = [];
      foreach (utfc16c; utf16String)
      {
        utf16Buffer ~= utfc16c;
      }

      utf16Buffer ~= cast(ushort)'\0';

      if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
      {
        throw new Exception("Failed to get size");
      }

      size_t textWidth = cast(size_t)w;

      // auto textInstance = new ExternalText;
      // textInstance.setFont(font);
      // textInstance.setString(calculateText);
      // textInstance.setCharacterSize(fontSize);
      //
      // auto textWidth = textInstance.bounds.x;

      if (textWidth >= width && lastWhiteIndex >= 0)
      {
        splitIndexes[lastWhiteIndex] = true;
        includeSplitters[lastWhiteIndex] = isForeign;
        calculateText = "";

        i = lastWhiteIndex + 1;
      }
    }

    calculateText = "";

    foreach (i; 0 .. text.length)
    {
      dchar c = text[i];

      if (splitIndexes[i])
      {
        if (includeSplitters[i])
        {
          calculateText ~= c ~ to!dstring("\r\n");
        }
        else
        {
          calculateText ~= "\r\n";
        }
      }
      else
      {
        calculateText ~= c;
      }
    }

    return calculateText;
  }

  override void repaint()
  {
    import std.array : replace, split;
    import std.conv : to;
    import std.string : toStringz;

    if (!_fontName || !_fontName.length || _fontSize == 0)
    {
      return;
    }

    if (!_textString)
    {
      _textString = "";
    }

    if (_wrapText && _wrapWidth > 0)
    {
      _text = wrapableText(_textString);
    }
    else
    {
      _text = _textString;
    }

    dstring[] lines = _text.replace("\r", "").split("\n");

    if (_shadow)
    {
      if (_shadowEntries && _shadowEntries.length)
      {
        foreach (entry; _shadowEntries)
        {
          EXT_DestroyTexture(entry._texture);
          entry._texture = null;
        }
      }

      _shadowEntries = [];
    }

    if (_entries && _entries.length)
    {
      foreach (entry; _entries)
      {
        EXT_DestroyTexture(entry._texture);
        entry._texture = null;
      }
    }

  	_entries = [];

    auto screen = super.window.nativeScreen;

    auto _textWidth = 0;
    auto _textHeight = 0;

  	foreach (l; lines)
  	{
  		auto line = l;

  		if (!line || !line.length)
  		{
  			line = " "; // Weird workaround to TTF not handling empty strings properly.
  		}

      Font runtimeFont;
      if (!super.window.application.fonts.tryGetWithFallback(_fontName, line, runtimeFont))
      {
        return;
      }

      auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);

  		if (!rawFont)
  		{
  			throw new Exception("No raw font.");
  		}

      wstring utf16String = (line.to!wstring);
      ushort[] utf16Buffer = [];
      foreach (c; utf16String)
      {
        utf16Buffer ~= c;
      }

      utf16Buffer ~= cast(ushort)'\0';

  		EXT_Surface textSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _color);

  		if (!textSurface)
  		{
  			throw new Exception("could not create surface");
  		}

  		auto text = new EXT_TextEntry;
  		text._texture = EXT_CreateTextureFromSurface(screen, textSurface);

  		if (!text._texture)
  		{
  			throw new Exception("could not create texture");
  		}

  		_textWidth = textSurface.w > _textWidth ? textSurface.w : _textWidth;

  		_textHeight += textSurface.h;

      auto rect = super.clientRect;

      import std.math : fmin,fmax;

      text._rect = EXT_CreateEmptyRectangle();
  		text._rect.x = rect.x;
  		text._rect.y = cast(int)(rect.y + (_textHeight - textSurface.h));
  		text._rect.w = textSurface.w;
  		text._rect.h = textSurface.h;

      if (_shadow)
      {
        EXT_Surface shadowSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _shadowColor.changeAlpha(_color.a));

        if (!shadowSurface)
        {
          throw new Exception("could not create shadow surface");
        }

        auto shadowText = new EXT_TextEntry;
  		  shadowText._texture = EXT_CreateTextureFromSurface(screen, shadowSurface);

        if (!shadowText._texture)
        {
          throw new Exception("could not create shadow texture");
        }

        shadowText._rect = EXT_CreateEmptyRectangle();
        shadowText._rect.x = rect.x + 1;
        shadowText._rect.y = (cast(int)(rect.y + (_textHeight - shadowSurface.h))) + 1;
        shadowText._rect.w = shadowSurface.w;
        shadowText._rect.h = shadowSurface.h;

        if (shadowSurface)
        {
          EXT_FreeSurface(shadowSurface);
        }

        _shadowEntries ~= shadowText;

        _textHeight += _lineSpacing;
      }

  		if (textSurface)
  		{
  			EXT_FreeSurface(textSurface);
  		}

  		_entries ~= text;
  	}
  }

  protected override bool measureComponentSize(out IntVector size)
  {
    size = super.size;

    import std.array : replace, split;
    import std.conv : to;
    import std.string : toStringz;

    if (!_fontName || !_fontName.length || _fontSize == 0)
    {
      size = IntVector(0,0);
      return true;
    }

    auto text = _textString;

    if (!text)
    {
      text = "";
    }

    if (_wrapText && _wrapWidth > 0)
    {
      text = wrapableText(text);
    }

    dstring[] lines = text.replace("\r", "").split("\n");

    auto screen = super.window.nativeScreen;

    auto _textWidth = 0;
    auto _textHeight = 0;

  	foreach (l; lines)
  	{
  		auto line = l;

  		if (!line || !line.length)
  		{
  			line = " "; // Weird workaround to TTF not handling empty strings properly.
  		}

      Font runtimeFont;
      if (!super.window.application.fonts.tryGetWithFallback(_fontName, line, runtimeFont))
      {
        return true;
      }

      auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);

  		if (!rawFont)
  		{
  			throw new Exception("No raw font.");
  		}

      int w;
      int h;
      wstring utf16String = (line.to!wstring);
      ushort[] utf16Buffer = [];
      foreach (c; utf16String)
      {
        utf16Buffer ~= c;
      }

      utf16Buffer ~= cast(ushort)'\0';

      if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
      {
        throw new Exception("Failed to get size");
      }

      _textWidth = w > _textWidth ? w : _textWidth;
      _textHeight += h + _lineSpacing;
  	}

    size = IntVector(_textWidth, _textHeight);
    return true;
  }

  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_shadowEntries)
    {
      foreach (texture; _shadowEntries)
			{
        if (texture._texture)
        {
          if (EXT_RenderCopy(screen, texture._texture, null, texture._rect) != 0)
          {
            import std.conv : to;

            throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
          }
        }
			}
    }

    if (_entries)
		{
			foreach (texture; _entries)
			{
        if (texture._texture)
        {
          if (EXT_RenderCopy(screen, texture._texture, null, texture._rect) != 0)
          {
            import std.conv : to;

            throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
          }
        }
			}
		}
  }

  override void clean()
  {
    if (_shadowEntries && _shadowEntries.length)
    {
      foreach (entry; _shadowEntries)
      {
        EXT_DestroyTexture(entry._texture);

        entry._texture = null;
      }
    }

    if (_entries && _entries.length)
    {
      foreach (entry; _entries)
      {
        EXT_DestroyTexture(entry._texture);

        entry._texture = null;
      }
    }

    _text = "";
    super.clean();
  }
}
