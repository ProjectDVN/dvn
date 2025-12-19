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

import std.conv : to;

public final class Label : Component
{
  private:
  dstring _text;
  dstring _textString;
  Color _color;
  int _opacity;
  string _fontName;
  size_t _fontSize;
  bool _wrapText;
  size_t _wrapWidth;
  bool _shadow;
  bool _isLink;
  Color _shadowColor;
  int _lineSpacing;
  bool _displayRuby;
  double _rubyOffset;
  dchar _rubyStartChar;
  dchar _rubyEndChar;
  bool _displayRubyAbove;
  bool _shadowRuby;

  EXT_TextEntry[] _entries;
  EXT_TextEntry[] _rubyEntries;
  EXT_TextEntry[] _shadowEntries;

  bool _hasMouseHover;

  public:
  final:
/// 
  this(Window window)
  {
    super(window, false);

    _rubyOffset = 1;
    _rubyStartChar = '(';
    _rubyEndChar = ')';

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
    _opacity = 255;
    _lineSpacing = 0;
  }

  @property
  {
///
    bool displayRuby() { return _displayRuby; }
///
    void displayRuby(bool display)
    {
      _displayRuby = display;
    }
///
    double rubyOffset() { return _rubyOffset; }
///
    void rubyOffset(double offset)
    {
      _rubyOffset = offset;
    }
///
    dchar rubyStartChar() { return _rubyStartChar; }
///
    void rubyStartChar(dchar startChar)
    {
      _rubyStartChar = startChar;
    }
///
    dchar rubyEndChar() { return _rubyEndChar; }
///
    void rubyEndChar(dchar endChar)
    {
      _rubyEndChar = endChar;
    }
///
    bool displayRubyAbove() { return _displayRubyAbove; }
///
    void displayRubyAbove(bool display)
    {
      _displayRubyAbove = display;
    }
///
    bool shadowRuby() { return _shadowRuby; }
///
    void shadowRuby(bool shadow)
    {
      _shadowRuby = shadow;
    }
/// 
    int lineSpacing() { return _lineSpacing; }
/// 
    void lineSpacing(int value)
    {
      _lineSpacing = value;
    }
/// 
    bool isLink() { return _isLink; }
/// 
    void isLink(bool newIsLink)
    {
      _isLink = newIsLink;
    }
/// 
    dstring text() { return _textString; }
/// 
    void text(dstring newText)
    {
      _textString = newText;

      updateRect(true);
    }

/// 
    bool shadow() { return _shadow; }
/// 
    void shadow(bool useShadow)
    {
      _shadow = useShadow;

      updateRect(true);
    }

/// 
    Color color() { return _color; }
/// 
    void color(Color newColor)
    {
      auto isSame = (newColor.r == _color.r &&
        newColor.g == _color.g &&
        newColor.b == _color.b);
      _color = newColor;

      _opacity = cast(int)newColor.a;

      if (!isSame) updateRect(true);
    }

/// 
    Color shadowColor() { return _shadowColor; }
/// 
    void shadowColor(Color newColor)
    {
      _shadowColor = newColor;

      updateRect(true);
    }

/// 
    string fontName() { return _fontName; }
/// 
    void fontName(string newFontName)
    {
      _fontName = newFontName;

      updateRect(true);
    }

/// 
    size_t fontSize() { return _fontSize; }
/// 
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;

      updateRect(true);
    }
  }

/// 
  void wrapText(size_t wrapWidth)
  {
    _wrapWidth = wrapWidth;
    _wrapText = wrapWidth > 0;

    updateRect(true);
  }

  private dstring wrapableText(dstring text)
  {
    if (_displayRuby)
    {
      return wrapableTextRuby(text);
    }
    else
    {
      return wrapableTextNormal(text);
    }
  }

  private dstring wrapableTextRuby(dstring text)
  {
      if (!text || !text.length)
          return "";

      import std.uni : isWhite;

      size_t width = _wrapWidth - (_fontSize / 2);

      Font runtimeFont;
      if (!super.window.application.fonts.tryGetWithFallback(_fontName, text, runtimeFont))
          return "";

      auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);
      if (!rawFont)
          throw new Exception("No raw font.");

      struct TextSpan
      {
          dstring text;
          dstring baseText;
          bool isRuby;
      }

      TextSpan[] spans;

      bool inRuby = false;
      dstring spanText = "";
      dstring baseText = "";

      foreach (c; text)
      {
          if (inRuby)
          {
              spanText ~= c;

              if (c == _rubyEndChar)
              {
                  inRuby = false;
                  spans ~= TextSpan(spanText, baseText, true);
                  spanText = "";
                  baseText = "";
              }
              continue;
          }

          if (c == _rubyStartChar)
          {
              if (spanText.length)
              {
                  spans ~= TextSpan(spanText, baseText, false);
                  spanText = "";
                  baseText = "";
              }
              inRuby = true;
              spanText ~= c;
              continue;
          }

          spanText ~= c;
          baseText ~= c;
      }

      if (spanText.length)
          spans ~= TextSpan(spanText, baseText, false);

      dstring result = "";
      size_t lineWidth = 0;

      foreach (span; spans)
      {
          int w, h;
          wstring utf16String = span.baseText.to!wstring;
          ushort[] utf16Buffer;
          foreach (utfc16c; utf16String)
              utf16Buffer ~= utfc16c;
          utf16Buffer ~= cast(ushort)'\0';

          if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
              throw new Exception("Failed to get size");

          size_t spanWidth = cast(size_t)w;

          if (lineWidth + spanWidth > width && lineWidth > 0)
          {
              result ~= "\r\n";
              lineWidth = 0;
          }

          result ~= span.text;
          lineWidth += spanWidth;
      }

      return result;
  }

  private dstring wrapableTextNormal(dstring text)
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

///
  override void repaint()
  {
    if (displayRuby)
    {
      repaintRuby();
    }
    else
    {
      repaintNormal();
    }
  }

  class RubyEntry
  {
    dstring text;
    dstring ruby;
  }

  private void repaintRuby()
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

    if (_rubyEntries && _rubyEntries.length)
    {
      foreach (entry; _rubyEntries)
      {
        EXT_DestroyTexture(entry._texture);
        entry._texture = null;
      }
    }

    _rubyEntries = [];

    auto screen = super.window.nativeScreen;
    
    auto rect = super.clientRect;
    
    int nextY = rect.y;

    foreach (l; lines)
    {
      auto line = l;

  		if (!line || !line.length)
  		{
  			line = " "; // Weird workaround to TTF not handling empty strings properly.
  		}

      RubyEntry[] rubyEntries;
      bool parseRubyText;
      auto current = new RubyEntry;
      bool isNotForeignText = !isForeignCharacter(line[0]);
      foreach (c; line)
      {
        if (parseRubyText)
        {
          if (c == rubyEndChar)
          {
            parseRubyText = false;
            
            rubyEntries ~= current;
            current = new RubyEntry;
          }
          else
          {
            current.ruby ~= c;
          }
        }
        else if (c == rubyStartChar)
        {
          parseRubyText = true;
        }
        else
        {
          auto isForeign = isForeignCharacter(c);
          if (isForeign && isNotForeignText)
          {
            isNotForeignText = false;
            rubyEntries ~= current;
            current = new RubyEntry;
          }
          else if (!isForeign && !isNotForeignText)
          {
            isNotForeignText = true;
            rubyEntries ~= current;
            current = new RubyEntry;
          }

          current.text ~= c;
        }
      }

      if (current && current.text && current.text.length)
      {
        rubyEntries ~= current;
      }

      int nextX = rect.x;
      int maxHeight = 0;

      foreach (rubyEntry; rubyEntries)
      {
        if (!rubyEntry.text || !rubyEntry.text.length)
        {
          rubyEntry.text = " ";
        }
        if (!rubyEntry.ruby || !rubyEntry.ruby.length)
        {
          rubyEntry.ruby = " ";
        }

        Font runtimeTextFont;
        if (!super.window.application.fonts.tryGetWithFallback(_fontName, rubyEntry.text, runtimeTextFont))
        {
          return;
        }

        Font runtimeRubyFont;
        if (!super.window.application.fonts.tryGetWithFallback(_fontName, rubyEntry.ruby, runtimeRubyFont))
        {
          return;
        }

        int textX = 0;
        int textY = 0;
        int textWidth = 0;
        int textHeight = 0;

        {
          auto rawFont = EXT_GetFont(runtimeTextFont.path, _fontSize);

          if (!rawFont)
          {
            throw new Exception("No raw font.");
          }

          wstring utf16String = (rubyEntry.text.to!wstring);
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

          text._rect = EXT_CreateEmptyRectangle();
          text._rect.x = nextX;
          text._rect.y = nextY;
          text._rect.w = textSurface.w;
          text._rect.h = textSurface.h;

          textX = nextX;
          textY = nextY;
          textWidth = textSurface.w;
          textHeight = textSurface.h;

          maxHeight = text._rect.h > maxHeight ? text._rect.h : maxHeight;
          
          nextX += text._rect.w;

          _entries ~= text;

          if (textSurface)
          {
            EXT_FreeSurface(textSurface);
          }

          if (_shadow)
          {
            EXT_Surface shadowSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _shadowColor);

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
            shadowText._rect.x = text._rect.x+1;
            shadowText._rect.y = text._rect.y+1;
            shadowText._rect.w = text._rect.w;
            shadowText._rect.h = text._rect.h;

            if (shadowSurface)
            {
              EXT_FreeSurface(shadowSurface);
            }

            _shadowEntries ~= shadowText;
          }
        }

        {
          auto rawFont = EXT_GetFont(runtimeRubyFont.path, cast(size_t)(_fontSize * 0.5));

          if (!rawFont)
          {
            throw new Exception("No raw font.");
          }

          wstring utf16String = (rubyEntry.ruby.to!wstring);
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

          text._rect = EXT_CreateEmptyRectangle();
          text._rect.x = textX + ((textWidth / 2) - (textSurface.w / 2));

          if (_displayRubyAbove)
          {
            text._rect.y = textY - (cast(int)(textHeight * _rubyOffset));
          }
          else
          {
            text._rect.y = textY + (cast(int)(textHeight * _rubyOffset));
          }

          text._rect.w = textSurface.w;
          text._rect.h = textSurface.h;

          _rubyEntries ~= text;

          if (textSurface)
          {
            EXT_FreeSurface(textSurface);
          }

          if (_shadowRuby)
          {
            EXT_Surface shadowSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _shadowColor);

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
            shadowText._rect.x = text._rect.x+1;
            shadowText._rect.y = text._rect.y+1;
            shadowText._rect.w = text._rect.w;
            shadowText._rect.h = text._rect.h;

            if (shadowSurface)
            {
              EXT_FreeSurface(shadowSurface);
            }

            _shadowEntries ~= shadowText;
          }
        }
      }

      nextY += maxHeight * 2;
    }
  }

  private void repaintNormal()
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
        EXT_Surface shadowSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _shadowColor);

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
      }

      _textHeight += _lineSpacing;

  		if (textSurface)
  		{
  			EXT_FreeSurface(textSurface);
  		}

  		_entries ~= text;
  	}
  }

/// 
  protected override bool measureComponentSize(out IntVector size)
  {
    if (_displayRuby)
    {
      return measureComponentSizeRuby(size);
    }
    else
    {
      return measureComponentSizeNormal(size);
    }
  }

  private bool measureComponentSizeRuby(out IntVector size)
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
    
    auto rect = super.clientRect;
    
    int totalWidth = 0;
    int totalHeight = 0;

    foreach (l; lines)
    {
      auto line = l;

  		if (!line || !line.length)
  		{
  			line = " "; // Weird workaround to TTF not handling empty strings properly.
  		}

      RubyEntry[] rubyEntries;
      bool parseRubyText;
      auto current = new RubyEntry;
      bool isNotForeignText = !isForeignCharacter(line[0]);
      foreach (c; line)
      {
        if (parseRubyText)
        {
          if (c == rubyEndChar)
          {
            parseRubyText = false;
            
            rubyEntries ~= current;
            current = new RubyEntry;
          }
          else
          {
            current.ruby ~= c;
          }
        }
        else if (c == rubyStartChar)
        {
          parseRubyText = true;
        }
        else
        {
          auto isForeign = isForeignCharacter(c);
          if (isForeign && isNotForeignText)
          {
            isNotForeignText = false;
            rubyEntries ~= current;
            current = new RubyEntry;
          }
          else if (!isForeign && !isNotForeignText)
          {
            isNotForeignText = true;
            rubyEntries ~= current;
            current = new RubyEntry;
          }

          current.text ~= c;
        }
      }

      if (current && current.text && current.text.length)
      {
        rubyEntries ~= current;
      }

      int measuredWidth = 0;
      int measuredHeight = 0;

      foreach (rubyEntry; rubyEntries)
      {
        if (!rubyEntry.text || !rubyEntry.text.length)
        {
          rubyEntry.text = " ";
        }
        if (!rubyEntry.ruby || !rubyEntry.ruby.length)
        {
          rubyEntry.ruby = " ";
        }

        Font runtimeTextFont;
        if (!super.window.application.fonts.tryGetWithFallback(_fontName, rubyEntry.text, runtimeTextFont))
        {
          return true;
        }

        Font runtimeRubyFont;
        if (!super.window.application.fonts.tryGetWithFallback(_fontName, rubyEntry.ruby, runtimeRubyFont))
        {
          return true;
        }

        int textWidth = 0;
        int textHeight = 0;

        {
          auto rawFont = EXT_GetFont(runtimeTextFont.path, _fontSize);

          if (!rawFont)
          {
            throw new Exception("No raw font.");
          }

          wstring utf16String = (rubyEntry.text.to!wstring);
          ushort[] utf16Buffer = [];
          foreach (c; utf16String)
          {
            utf16Buffer ~= c;
          }

          utf16Buffer ~= cast(ushort)'\0';

          int w;
          int h;
          if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
          {
            throw new Exception("Failed to get size");
          }

          textWidth = w;
          textHeight = h;
          
          measuredWidth += textWidth;
        }

        {
          auto rawFont = EXT_GetFont(runtimeRubyFont.path, cast(size_t)(_fontSize * 0.5));

          if (!rawFont)
          {
            throw new Exception("No raw font.");
          }

          wstring utf16String = (rubyEntry.ruby.to!wstring);
          ushort[] utf16Buffer = [];
          foreach (c; utf16String)
          {
            utf16Buffer ~= c;
          }

          utf16Buffer ~= cast(ushort)'\0';
          
          int w;
          int h;
          if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
          {
            throw new Exception("Failed to get size");
          }

          measuredHeight = (h + textHeight) > measuredHeight ? (h + textHeight) : measuredHeight;
        }
      }

      if (measuredWidth > totalWidth)
      {
        totalWidth = measuredWidth;
      }

      totalHeight = measuredHeight;
    }

    size = IntVector(totalWidth, totalHeight);
    return true;
  }

  private bool measureComponentSizeNormal(out IntVector size)
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

/// 
  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_shadowEntries)
    {
      foreach (texture; _shadowEntries)
			{
        if (texture._texture)
        {
          EXT_SetTextureAlphaMod(texture._texture, cast(ubyte)_opacity);

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
          EXT_SetTextureAlphaMod(texture._texture, cast(ubyte)_opacity);

          if (EXT_RenderCopy(screen, texture._texture, null, texture._rect) != 0)
          {
            import std.conv : to;

            throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
          }
        }
			}
		}

    if (_rubyEntries)
		{
			foreach (texture; _rubyEntries)
			{
        if (texture._texture)
        {
          EXT_SetTextureAlphaMod(texture._texture, cast(ubyte)_opacity);

          if (EXT_RenderCopy(screen, texture._texture, null, texture._rect) != 0)
          {
            import std.conv : to;

            throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
          }
        }
			}
		}
  }

/// 
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

    if (_rubyEntries && _rubyEntries.length)
    {
      foreach (entry; _rubyEntries)
      {
        EXT_DestroyTexture(entry._texture);

        entry._texture = null;
      }
    }

    _text = "";
    super.clean();
  }
}
