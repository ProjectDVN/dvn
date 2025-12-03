/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.button;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.events;
import dvn.colors;
import dvn.painting;
import dvn.components.label;

/// 
public final class ButtonPaint
{
  private:
  Color _backgroundColor;
  Color _backgroundBottomColor;
  Color _borderColor;
  Color _shadowColor;

  final:
  this()
  {
    _backgroundColor = getColorByName("transparent");
    _backgroundBottomColor = _backgroundColor;
    _borderColor = _backgroundColor;
    _shadowColor = _backgroundColor;
  }

  public:
  @property
  {
    /// 
    Color backgroundColor() { return _backgroundColor; }
    /// 
    void backgroundColor(Color color)
    {
      _backgroundColor = color;
    }

    /// 
    Color backgroundBottomColor() { return _backgroundBottomColor; }
    /// 
    void backgroundBottomColor(Color color)
    {
      _backgroundBottomColor = color;
    }

    /// 
    Color borderColor() { return _borderColor; }
    /// 
    void borderColor(Color color)
    {
      _borderColor = color;
    }

    /// 
    Color shadowColor() { return _shadowColor; }
    /// 
    void shadowColor(Color color)
    {
      _shadowColor = color;
    }
  }
}

/// 
public alias DrawButtonDelegate = void delegate(string name, Painting painting, Color backgroundColor, Color backgroundBottomColor, Color borderColor, Color shadowColor);

/// 
public final class Button : Component
{
  private:
  string _defaultName;
  EXT_SheetRender* _defaultSheetRender;
  string _defaultRenderName;

  string _clickName;
  EXT_SheetRender* _clickSheetRender;
  string _clickRenderName;

  string _hoverName;
  EXT_SheetRender* _hoverSheetRender;
  string _hoverRenderName;

  EXT_SheetRender* _activeRender;

  bool _hasMouseDown;
  bool _hasMouseHover;

  MouseButtonEventHandler[] _buttonClickEvents;

  Label _textLabel;
  dstring _text;
  Color _textColor;
  string _fontName;
  size_t _fontSize;
  IntVector _textPosition;
  bool _fitToSize;
  bool _fitted;
  size_t _fontSizeForced;
  DrawButtonDelegate _customButtonDraw;

  ButtonPaint _defaultPaint;
  ButtonPaint _hoverPaint;
  ButtonPaint _clickPaint;

  EXT_Surface _temp;
  EXT_Texture _texture;
  EXT_RectangleNative* _rect1;
  EXT_RectangleNative* _rect2;

  EXT_Surface _tempHover;
  EXT_Texture _textureHover;
  EXT_RectangleNative* _rect1Hover;
    EXT_RectangleNative* _rect2Hover;

  bool _cleaned;
  bool _isImageRender;

  alias VERIFY_CLICK_DELGATE = bool delegate();

  VERIFY_CLICK_DELGATE[] _verifyClicks;

  void drawButton(string name, Color backgroundColor, Color backgroundBottomColor, Color borderColor, Color shadowColor)
  {
    auto painting = super.beginPainting(name);

    if (_customButtonDraw)
    {
      _customButtonDraw(name, painting, backgroundColor, backgroundBottomColor, borderColor, shadowColor);
      return;
    }

    painting.paintBackground(
			backgroundColor,
			FloatVector(0f,0f),
			FloatVector(1f,1f)
		);

    painting.paintBackground(
			backgroundBottomColor,
			FloatVector(0.02f,0.51f),
			FloatVector(0.97f,0.46f)
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

  void drawDefaultButton()
  {
    if (!_defaultPaint)
    {
      _defaultPaint = new ButtonPaint;
      _defaultPaint.backgroundColor = "EAEDED".getColorByHex;
      _defaultPaint.backgroundBottomColor = "D5DBDB".getColorByHex;
      _defaultPaint.borderColor = "5F6A6A".getColorByHex;
    }

    drawButton("default",
      _defaultPaint.backgroundColor,
      _defaultPaint.backgroundBottomColor,
      _defaultPaint.borderColor,
      _defaultPaint.shadowColor);
  }

  void drawHoverButton()
  {
    if (!_hoverPaint)
    {
      _hoverPaint = new ButtonPaint;
      _hoverPaint.backgroundColor = "F2F3F4".getColorByHex;
      _hoverPaint.backgroundBottomColor = "E5E7E9".getColorByHex;
      _hoverPaint.borderColor = "797D7F".getColorByHex;
    }

    drawButton("hover",
      _hoverPaint.backgroundColor,
      _hoverPaint.backgroundBottomColor,
      _hoverPaint.borderColor,
      _hoverPaint.shadowColor);
  }

  void drawClickButton()
  {
    if (!_clickPaint)
    {
      _clickPaint = new ButtonPaint;
      _clickPaint.backgroundColor = "D5DBDB".getColorByHex;
      _clickPaint.backgroundBottomColor = "D5DBDB".getColorByHex;
      _clickPaint.borderColor = "797D7F".getColorByHex;
      _clickPaint.shadowColor = "BFC9CA".getColorByHex;
    }

    drawButton("click",
      _clickPaint.backgroundColor,
      _clickPaint.backgroundBottomColor,
      _clickPaint.borderColor,
      _clickPaint.shadowColor);
  }

  public:
  final:
  /// 
  this(Window window)
  {
    this(window, null, null, null);
  }

  /// 
  this(Window window, string defaultName, string clickName, string hoverName)
  {
    super(window, false);

    _defaultName = defaultName;
    _defaultRenderName = "";

    _clickName = clickName;
    _clickRenderName = "";

    _hoverName = hoverName;
    _hoverRenderName = "";

    _buttonClickEvents = [];

    _isImageRender = false;

    onMouseButtonDown(new MouseButtonEventHandler((b,p) {
      if (super.isDisabled)
      {
        return true;
      }

      if (_verifyClicks)
      {
        foreach (verifyClick; _verifyClicks)
        {
          if (!verifyClick()) return true;
        }
      }

      _hasMouseDown = true;

      if (_clickSheetRender)
      {
        _activeRender = _clickSheetRender;
      }

      setActivePainting("click");
      EXT_SetHandCursor();

      return false;
    }));

    onMouseButtonUp(new MouseButtonEventHandler((b,p) {
      if (super.isDisabled)
      {
        return true;
      }

      if (_verifyClicks)
      {
        foreach (verifyClick; _verifyClicks)
        {
          if (!verifyClick()) return true;
        }
      }

      _hasMouseDown = false;

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
        EXT_SetHandCursor();
      }
      else
      {
        setActivePainting("default");
        EXT_ResetCursor();
      }

      if (!intersectsWith(p))
      {
        loseFocus();

        return true;
      }

      if (_buttonClickEvents)
      {
        foreach (buttonClickEvent; _buttonClickEvents)
        {
          buttonClickEvent(b,p);
        }
        
        EXT_ResetCursor();
      }

      return false;
    }), true);

    onMouseMove(new MouseMoveEventHandler((p) {
      _hasMouseHover = super.intersectsWith(p);

      if (_verifyClicks)
      {
        foreach (verifyClick; _verifyClicks)
        {
          if (!verifyClick()) return true;
        }
      }

      if (!_hasMouseDown)
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
          EXT_SetHandCursor();
        }
        else
        {
          _activeRender = _defaultSheetRender;
          setActivePainting("default");
          EXT_ResetCursor();
        }
      }

      return !_hasMouseHover;
    }));

    restyle();
  }

  /// 
  void renderButtonImage(string path, IntVector imageSize, string hoverPath, IntVector imageSizeHover)
  {
    import std.string : toStringz;

    _isImageRender = true;

    _temp = EXT_IMG_Load(path.toStringz);
    _texture = EXT_CreateTextureFromSurface(window.nativeScreen, _temp);

    _rect1 = new EXT_RectangleNative;
    _rect1.x = 0;
    _rect1.y = 0;
    _rect1.w = imageSize.x;
    _rect1.h = imageSize.y;

    _rect2 = new EXT_RectangleNative;
    _rect2.x = super.x;
    _rect2.y = super.y;
    _rect2.w = super.width;
    _rect2.h = super.height;
    
    _tempHover = EXT_IMG_Load(hoverPath.toStringz);
    _textureHover = EXT_CreateTextureFromSurface(window.nativeScreen, _tempHover);

    _rect1Hover = new EXT_RectangleNative;
    _rect1Hover.x = 0;
    _rect1Hover.y = 0;
    _rect1Hover.w = imageSizeHover.x;
    _rect1Hover.h = imageSizeHover.y;
    
    _rect2Hover = new EXT_RectangleNative;
    _rect2Hover.x = super.x;
    _rect2Hover.y = super.y;
    _rect2Hover.w = super.width;
    _rect2Hover.h = super.height;
    
    defaultPaint.backgroundColor = defaultPaint.backgroundColor.changeAlpha(0);
		defaultPaint.backgroundBottomColor = defaultPaint.backgroundColor;
		defaultPaint.borderColor = defaultPaint.backgroundColor;
		defaultPaint.shadowColor = defaultPaint.backgroundColor;

		hoverPaint.backgroundColor = defaultPaint.backgroundColor;
		hoverPaint.backgroundBottomColor = defaultPaint.backgroundColor;
		hoverPaint.borderColor = defaultPaint.backgroundColor;
		hoverPaint.shadowColor = defaultPaint.backgroundColor;

		clickPaint.backgroundColor = defaultPaint.backgroundColor;
		clickPaint.backgroundBottomColor = defaultPaint.backgroundColor;
		clickPaint.borderColor = defaultPaint.backgroundColor;
		clickPaint.shadowColor = defaultPaint.backgroundColor;

    restyle();
    show();
  }

  private void updateLabel()
  {
    if (!_textLabel)
    {
      auto label = new Label(super.window);
      super.addComponent(label, true);
      label.color = _textColor;
      label.text = _text;
      label.fontName = _fontName;
      label.fontSize = _fontSizeForced;
      label.isLink = true;

      _textLabel = label;

      updateRect(true);
    }
    else
    {
      _textLabel.color = _textColor;
      _textLabel.text = _text;
      _textLabel.fontName = _fontName;

      if (_fitToSize && !_fitted)
      {
        _fitted = true;

        //auto rect = super.clientRect;
        auto rect = Rectangle(super.x, super.y, super.width, super.height);
        rect = Rectangle(rect.x, rect.y, rect.w - (rect.w / 3), rect.h - (rect.h / 3));

        _textLabel.fontSize = _fontSize;

        while (_textLabel.width > rect.w && rect.w > 0 && _textLabel.fontSize > 4)
        {
          _textLabel.fontSize = _textLabel.fontSize - 2;

          _textPosition = IntVector(0,0);
        }

        _fontSizeForced = _textLabel.fontSize;
      }
      else if (_fontSizeForced == 0)
      {
        _fontSizeForced = _fontSize;
      }

      _textLabel.fontSize = _fontSizeForced;
    }
  }

  @property
  {
    /// 
    string defaultName() { return _defaultName; }
    /// 
    void defaultName(string newName)
    {
      _defaultName = newName;

      updateRect(true);
    }

    /// 
    string clickName() { return _clickName; }
    /// 
    void clickName(string newName)
    {
      _clickName = newName;

      updateRect(true);
    }

    /// 
    string hoverName() { return _hoverName; }
    /// 
    void hoverName(string newName)
    {
      _hoverName = newName;

      updateRect(true);
    }

    /// 
    dstring text() { return _text; }
    /// 
    void text(dstring newText)
    {
      _text = newText;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    /// 
    Color textColor() { return _textColor; }
    /// 
    void textColor(Color newColor)
    {
      _textColor = newColor;

      updateLabel();
    }

    /// 
    string fontName() { return _fontName; }

    /// 
    void fontName(string newFontName)
    {
      _fontName = newFontName;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    /// 
    size_t fontSize() { return _fontSize; }
    /// 
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }
    
    /// 
    bool fitToSize() { return _fitToSize; }
    /// 
    void fitToSize(bool shouldFitToSize)
    {
      _fitToSize = shouldFitToSize;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    /// 
    ButtonPaint defaultPaint() { return _defaultPaint; }
    /// 
    ButtonPaint hoverPaint() { return _hoverPaint; }
    /// 
    ButtonPaint clickPaint() { return _clickPaint; }
  }
  /// 
  void verifyClick(VERIFY_CLICK_DELGATE verification)
  {
    _verifyClicks ~= verification;
  }
  /// 
  void onButtonClick(MouseButtonEventHandler eventHandler)
  {
    _buttonClickEvents ~= eventHandler;
  }
  /// 
  void fireButtonClick()
  {
    if (!_buttonClickEvents)
    {
      return;
    }

    foreach (event; _buttonClickEvents)
    {
      event(MouseButton.left, IntVector(x, y));
    }
  }
  /// 
  void setCustomButtonDraw(DrawButtonDelegate customButtonDraw)
  {
    _customButtonDraw = customButtonDraw;

    restyle();
  }
  /// 
  void removeCustomButtonDraw()
  {
    _customButtonDraw = null;

    restyle();
  }
  /// 
  void restyle()
  {
    drawDefaultButton();
    drawHoverButton();
    drawClickButton();

    updateRect(true);
  }
  /// 
  override void repaint()
  {
    auto rect = super.clientRect;
    bool isEnabled = super.isEnabled;

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

    if (_clickName == _clickRenderName && _clickSheetRender !is null)
    {
      _clickSheetRender.entry.rect.x = cast(int)rect.x;
      _clickSheetRender.entry.rect.y = cast(int)rect.y;
      _clickSheetRender.entry.rect.w = cast(int)rect.w;
      _clickSheetRender.entry.rect.h = cast(int)rect.h;
    }
    else if (_clickName && _clickName.length)
    {
      _clickRenderName = _clickName;

      EXT_SheetRender* sheetRender;
      if (super.window.getSheetEntry(_clickName, sheetRender))
      {
        _clickSheetRender = sheetRender;

        if (_clickSheetRender !is null)
        {
          _clickSheetRender.entry.rect.x = cast(int)rect.x;
          _clickSheetRender.entry.rect.y = cast(int)rect.y;
          _clickSheetRender.entry.rect.w = cast(int)rect.w;
          _clickSheetRender.entry.rect.h = cast(int)rect.h;
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

    if (_hasMouseDown && _clickSheetRender && isEnabled)
    {
      _activeRender = _clickSheetRender;
    }
    else if (_hasMouseHover && _hoverSheetRender && isEnabled)
    {
      _activeRender = _hoverSheetRender;
    }
    else
    {
      _activeRender = _defaultSheetRender;
    }

    if (_hasMouseDown && isEnabled)
    {
      setActivePainting("click");
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
      int centerX = (rect.w / 2) - ((_textLabel.width) / 2);
      int centerY = (rect.h / 2) - ((_textLabel.height) / 2);

      _textPosition = IntVector(centerX,centerY);
      _textLabel.position = _textPosition;
    }
  }

  override void clean()
  {
    if (_isImageRender)
    {
      EXT_DestroyTexture(_texture);
      EXT_FreeSurface(_temp);
    }

    _cleaned = true;

    super.clean();
  }

  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_isImageRender)
    {
      if (!_texture || !_textureHover || _cleaned)
      {
        return;
      }
      
      if (_hasMouseHover)
      {
        EXT_RenderCopy(screen, _textureHover, _rect1Hover, _rect2Hover);
      }
      else
      {
        EXT_RenderCopy(screen, _texture, _rect1, _rect2);
      }
    }
    else if (_activeRender && _activeRender.texture)
    {
      EXT_RenderCopy(screen, _activeRender.texture, _activeRender.entry.textureRect, _activeRender.entry.rect);
    }

    renderChildren();
  }
}
