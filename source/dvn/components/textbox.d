/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.textbox;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.events;
import dvn.colors;
import dvn.components.label;
import dvn.painting;

public final class TextBoxPaint
{
  private:
  Color _backgroundColor;
  Color _borderColor;
  Color _shadowColor;

  final:
  this()
  {
    _backgroundColor = getColorByName("transparent");
    _borderColor = _backgroundColor;
    _shadowColor = _backgroundColor;
  }

  public:
  @property
  {
    Color backgroundColor() { return _backgroundColor; }
    void backgroundColor(Color color)
    {
      _backgroundColor = color;
    }

    Color borderColor() { return _borderColor; }
    void borderColor(Color color)
    {
      _borderColor = color;
    }

    Color shadowColor() { return _shadowColor; }
    void shadowColor(Color color)
    {
      _shadowColor = color;
    }
  }
}

public alias DrawTextBoxDelegate = void delegate(string name, Painting painting, Color backgroundColor, Color borderColor, Color shadowColor);

public final class TextBox : Component
{
  private:
  string _defaultName;
  EXT_SheetRender* _defaultSheetRender;
  string _defaultRenderName;

  string _focusName;
  EXT_SheetRender* _focusSheetRender;
  string _focusRenderName;

  string _hoverName;
  EXT_SheetRender* _hoverSheetRender;
  string _hoverRenderName;

  EXT_SheetRender* _activeRender;

  bool _hasMouseHover;

  Label _textLabel;
  dstring _text;
  dstring _textDisplay;
  Color _textColor;
  string _fontName;
  size_t _fontSize;
  IntVector _textPosition;
  bool _centerText;
  int _textPadding;
  dchar _hideCharacter;
  DrawTextBoxDelegate _customTextBoxDraw;
  size_t _maxCharacters;

  TextBoxPaint _defaultPaint;
  TextBoxPaint _hoverPaint;
  TextBoxPaint _focusPaint;

  void drawTextBox(string name, Color backgroundColor, Color borderColor, Color shadowColor)
  {
    auto painting = super.beginPainting(name);

    if (_customTextBoxDraw)
    {
      _customTextBoxDraw(name, painting, backgroundColor, borderColor, shadowColor);
      return;
    }

    painting.paintBackground(
			backgroundColor,
			FloatVector(0f,0f),
			FloatVector(1f,1f)
		);

    if (shadowColor.a > 0)
    {
      painting.paintBackground(
        shadowColor,
        FloatVector(0f,0f),
        FloatVector(1f,0.07f)
      );
    }

    painting.paintForeground(
			borderColor,
			FloatVector(0f,0f),
			FloatVector(1f,0.02f)
		);
    painting.paintForeground(
			borderColor,
			FloatVector(1f,0f),
			FloatVector(0.01f,1f)
		);
    painting.paintForeground(
			borderColor,
			FloatVector(0f,0.99f),
			FloatVector(1f,0.02f)
		);
    painting.paintForeground(
			borderColor,
			FloatVector(0f,0f),
			FloatVector(0.01f,1f)
		);
  }

  void drawDefaultTextBox()
  {
    if (!_defaultPaint)
    {
      _defaultPaint = new TextBoxPaint;
      _defaultPaint.backgroundColor = "EAEDED".getColorByHex;
      _defaultPaint.borderColor = "5F6A6A".getColorByHex;
      _defaultPaint.shadowColor = "D5DBDB".getColorByHex;
    }

    drawTextBox("default",
      _defaultPaint.backgroundColor,
      _defaultPaint.borderColor,
      _defaultPaint.shadowColor);
  }

  void drawHoverTextBox()
  {
    if (!_hoverPaint)
    {
      _hoverPaint = new TextBoxPaint;
      _hoverPaint.backgroundColor = "F2F3F4".getColorByHex;
      _hoverPaint.borderColor = "797D7F".getColorByHex;
      _hoverPaint.shadowColor = "D5DBDB".getColorByHex;
    }

    drawTextBox("hover",
      _hoverPaint.backgroundColor,
      _hoverPaint.borderColor,
      _hoverPaint.shadowColor);
  }

  void drawFocusTextBox()
  {
    if (!_focusPaint)
    {
      _focusPaint = new TextBoxPaint;
      _focusPaint.backgroundColor = "D5DBDB".getColorByHex;
      _focusPaint.borderColor = "797D7F".getColorByHex;
      _focusPaint.shadowColor = "BFC9CA".getColorByHex;
    }

    drawTextBox("focus",
      _focusPaint.backgroundColor,
      _focusPaint.borderColor,
      _focusPaint.shadowColor);
  }

  public:
  final:
  this(Window window)
  {
    this(window, null, null, null);
  }

  this(Window window, string defaultName, string focusName, string hoverName)
  {
    super(window, false);

    _defaultName = defaultName;
    _defaultRenderName = "";

    _focusName = focusName;
    _focusRenderName = "";

    _hoverName = hoverName;
    _hoverRenderName = "";

    _text = "";
    _textDisplay = "";
    _hideCharacter = '\0';

    onKeyboardUp(new KeyboardEventHandler((k) {
      if (super.isDisabled)
      {
        return true;
      }

      if (k == KeyboardKey.backSpace)
      {
        if (_text.length > 1)
        {
          _text = _text[0 .. $-1];

          updateLabelText();

          repaint();
        }
        else
        {
          _text = "";

          updateLabelText();

          repaint();
        }

        return false;
      }

      return true;
    }));

    onTextInput(new TextInputEventHandler((c,s) {
      if (super.isDisabled)
      {
        return;
      }

      import std.conv : to;

      _text ~= c.to!dstring;

      updateLabelText();

      repaint();
    }));

    onMouseButtonUp(new MouseButtonEventHandler((b,p) {
      if (super.isDisabled)
      {
        return true;
      }

      if (_hasMouseHover)
      {
        if (_hoverSheetRender)
        {
          _activeRender = _hoverSheetRender;
        }
        else
        {
          _activeRender = _defaultSheetRender;
        }

        setActivePainting("hover");
        EXT_SetIBeamCursor();
      }
      else
      {
        _activeRender = _defaultSheetRender;
        setActivePainting("default");
        EXT_ResetCursor();
      }

      if (!intersectsWith(p))
      {
        EXT_ResetCursor();
        loseFocus();

        return true;
      }

      gainFocus();

      setActivePainting("focus");
      return false;
    }), true);

    onMouseMove(new MouseMoveEventHandler((p) {
      _hasMouseHover = super.intersectsWith(p);

      if (!super.hasFocus)
      {
        if (_hasMouseHover && super.isEnabled)
        {
          if (_hoverSheetRender)
          {
            _activeRender = _hoverSheetRender;
          }
          else
          {
            _activeRender = _defaultSheetRender;
          }

          setActivePainting("hover");
          EXT_SetIBeamCursor();
        }
        else
        {
          _activeRender = _defaultSheetRender;
          setActivePainting("default");
          EXT_ResetCursor();
        }
      }
      else if (_hasMouseHover)
      {
        EXT_SetIBeamCursor();
      }

      return !_hasMouseHover;
    }));

    restyle();
  }

  private void updateLabelText()
  {
    import std.conv : to;

    if (_text && _text.length > _maxCharacters && _maxCharacters > 0)
    {
      _text = _text[0 .. _maxCharacters];
    }

    if (_textLabel)
    {
      if (_hideCharacter != '\0' && _text && _text.length)
      {
        _textDisplay = "";

        foreach(i; 0 .. _text.length)
        {
          _textDisplay ~= _hideCharacter.to!dstring;
        }
      }
      else
      {
        _textDisplay = _text;
      }

      _textLabel.text = _textDisplay;
    }
  }

  private void updateLabel()
  {
    import std.conv : to;

    if (_hideCharacter != '\0' && _text && _text.length)
    {
      _textDisplay = "";

      foreach(i; 0 .. _text.length)
      {
        _textDisplay ~= _hideCharacter.to!dstring;
      }
    }
    else
    {
      _textDisplay = _text;
    }

    if (!_textLabel)
    {
      auto label = new Label(super.window);
      super.addComponent(label, true);
      label.color = _textColor;
      label.text = _textDisplay;
      label.fontName = _fontName;
      label.fontSize = _fontSize;

      _textLabel = label;

      updateRect(true);
    }
    else
    {
      _textLabel.color = _textColor;
      _textLabel.text = _textDisplay;
      _textLabel.fontName = _fontName;
      _textLabel.fontSize = _fontSize;
    }
  }

  @property
  {
    string defaultName() { return _defaultName; }
    void defaultName(string newName)
    {
      _defaultName = newName;

      updateRect(true);
    }

    string focusName() { return _focusName; }
    void focusName(string newName)
    {
      _focusName = newName;

      updateRect(true);
    }

    string hoverName() { return _hoverName; }
    void hoverName(string newName)
    {
      _hoverName = newName;

      updateRect(true);
    }

    dstring text() { return _text; }
    void text(dstring newText)
    {
      _text = newText;

      updateLabel();
    }

    Color textColor() { return _textColor; }
    void textColor(Color newColor)
    {
      _textColor = newColor;

      updateLabel();
    }

    string fontName() { return _fontName; }
    void fontName(string newFontName)
    {
      _fontName = newFontName;

      updateLabel();
    }

    size_t fontSize() { return _fontSize; }
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;

      updateLabel();
    }

    int textPadding() { return _textPadding; }
    void textPadding(int newPadding)
    {
      _textPadding = newPadding;

      updateLabel();
    }

    bool centerText() { return _centerText; }
    void centerText(bool shouldCenterText)
    {
      _centerText = shouldCenterText;

      updateLabel();
    }

    TextBoxPaint defaultPaint() { return _defaultPaint; }

    TextBoxPaint hoverPaint() { return _hoverPaint; }

    TextBoxPaint focusPaint() { return _focusPaint; }

    dchar hideCharacter() { return _hideCharacter; }
    void hideCharacter(dchar character)
    {
      _hideCharacter = character;

      updateLabel();
    }

    size_t maxCharacters() { return _maxCharacters; }
    void maxCharacters(size_t amount)
    {
      _maxCharacters = amount;

      updateLabel();
    }
  }

  void setCustomTextBoxDraw(DrawTextBoxDelegate customTextBoxDraw)
  {
    _customTextBoxDraw = customTextBoxDraw;

    restyle();
  }

  void removeCustomTextBoxDraw()
  {
    _customTextBoxDraw = null;

    restyle();
  }

  void restyle()
  {
    drawDefaultTextBox();
    drawHoverTextBox();
    drawFocusTextBox();

    updateRect(true);
  }

  override void repaint()
  {
    auto rect = super.clientRect;
    auto isEnabled = super.isEnabled;

    if (_defaultName == _defaultRenderName && _defaultSheetRender !is null)
    {
      _defaultSheetRender.entry.rect.x = cast(int)rect.x;
      _defaultSheetRender.entry.rect.y = cast(int)rect.y;
      _defaultSheetRender.entry.rect.w = cast(int)rect.w;
      _defaultSheetRender.entry.rect.h = cast(int)rect.h;
    }
    else if (_defaultName && _defaultName.length)
    {
      _defaultRenderName = _defaultName;

      EXT_SheetRender* sheetRender;
      if (super.window.getSheetEntry(_defaultName, sheetRender))
      {
        _defaultSheetRender = sheetRender;

        if (_defaultSheetRender !is null)
        {
          _defaultSheetRender.entry.rect.x = cast(int)rect.x;
          _defaultSheetRender.entry.rect.y = cast(int)rect.y;
          _defaultSheetRender.entry.rect.w = cast(int)rect.w;
          _defaultSheetRender.entry.rect.h = cast(int)rect.h;
        }
      }
    }

    if (_focusName == _focusRenderName && _focusSheetRender !is null)
    {
      _focusSheetRender.entry.rect.x = cast(int)rect.x;
      _focusSheetRender.entry.rect.y = cast(int)rect.y;
      _focusSheetRender.entry.rect.w = cast(int)rect.w;
      _focusSheetRender.entry.rect.h = cast(int)rect.h;
    }
    else if (_focusName && _focusName.length)
    {
      _focusRenderName = _focusName;

      EXT_SheetRender* sheetRender;
      if (super.window.getSheetEntry(_focusName, sheetRender))
      {
        _focusSheetRender = sheetRender;

        if (_focusSheetRender !is null)
        {
          _focusSheetRender.entry.rect.x = cast(int)rect.x;
          _focusSheetRender.entry.rect.y = cast(int)rect.y;
          _focusSheetRender.entry.rect.w = cast(int)rect.w;
          _focusSheetRender.entry.rect.h = cast(int)rect.h;
        }
      }
    }

    if (_hoverName == _hoverRenderName && _hoverSheetRender !is null)
    {
      _hoverSheetRender.entry.rect.x = cast(int)rect.x;
      _hoverSheetRender.entry.rect.y = cast(int)rect.y;
      _hoverSheetRender.entry.rect.w = cast(int)rect.w;
      _hoverSheetRender.entry.rect.h = cast(int)rect.h;
    }
    else if (_hoverName && _hoverName.length)
    {
      _hoverRenderName = _hoverName;

      EXT_SheetRender* sheetRender;
      if (super.window.getSheetEntry(_hoverName, sheetRender))
      {
        _hoverSheetRender = sheetRender;

        if (_hoverSheetRender !is null)
        {
          _hoverSheetRender.entry.rect.x = cast(int)rect.x;
          _hoverSheetRender.entry.rect.y = cast(int)rect.y;
          _hoverSheetRender.entry.rect.w = cast(int)rect.w;
          _hoverSheetRender.entry.rect.h = cast(int)rect.h;
        }
      }
    }

    if (super.hasFocus && _focusSheetRender && isEnabled)
    {
      _activeRender = _focusSheetRender;
    }
    else if (_hasMouseHover && _hoverSheetRender && isEnabled)
    {
      _activeRender = _hoverSheetRender;
    }
    else
    {
      _activeRender = _defaultSheetRender;
    }

    if (super.hasFocus && isEnabled)
    {
      setActivePainting("focus");
    }
    else if (_hasMouseHover && isEnabled)
    {
      setActivePainting("hover");
    }
    else
    {
      setActivePainting("default");
    }

    if (_textLabel)
    {
      if (_centerText)
      {
        int centerX = (rect.w / 2) - ((_textLabel.width) / 2);
        int centerY = (rect.h / 2) - ((_textLabel.height) / 2);

        _textPosition = IntVector(centerX,centerY);
        _textLabel.position = _textPosition;
      }
      else
      {
        _textPosition = IntVector(_textPadding,_textPadding);
        _textLabel.position = _textPosition;
      }
    }
  }

  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_activeRender && _activeRender.texture)
    {
      EXT_RenderCopy(screen, _activeRender.texture, _activeRender.entry.textureRect, _activeRender.entry.rect);
    }

    renderChildren();
  }
}
