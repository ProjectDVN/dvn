module dvn.components.dropdown;

import std.variant : Variant;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.events;
import dvn.colors;
import dvn.painting;
import dvn.components.label;
import dvn.components.panel;
import dvn.components.scrollbar;

public final class DropDownPaint
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
    Color backgroundColor() { return _backgroundColor; }
    void backgroundColor(Color color)
    {
      _backgroundColor = color;
    }

    Color backgroundBottomColor() { return _backgroundBottomColor; }
    void backgroundBottomColor(Color color)
    {
      _backgroundBottomColor = color;
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

public alias DrawDropDownDelegate = void delegate(string name, Painting painting, Color backgroundColor, Color borderColor);

private final class DropDownItem
{
  Panel panel;
  Component component;
  dstring text;
  Variant value;
}

public final class DropDown : Component
{
  private:
  string _defaultName;
  EXT_SheetRender* _defaultSheetRender;
  string _defaultRenderName;

  string _hoverName;
  EXT_SheetRender* _hoverSheetRender;
  string _hoverRenderName;

  EXT_SheetRender* _activeRender;

  bool _hasMouseHover;

  DropDownItem[] _dropDownItems;
  DropDownItem[dstring] _dropDownItemsMap;
  dstring _selectedItem;
  DrawDropDownDelegate _customDropDownDraw;

  DropDownPaint _defaultPaint;
  DropDownPaint _hoverPaint;

  dstring _placeholder;
  Label _textLabel;
  dstring _text;
  Color _textColor;
  string _fontName;
  size_t _fontSize;
  IntVector _textPosition;
  bool _fitToSize;
  bool _fitted;
  size_t _fontSizeForced;

  Label _dropDownLabel;

  Panel _itemsPanel;
  ScrollBar _itemsPanelScrollBar;

  bool _showAbove;

  void delegate(dstring) _onItemChanged;

  void drawDropDown(string name, Color backgroundColor, Color borderColor)
  {
    auto painting = super.beginPainting(name);

    if (_customDropDownDraw)
    {
      _customDropDownDraw(name, painting, backgroundColor, borderColor);
      return;
    }

    painting.paintBackground(
			backgroundColor,
			FloatVector(0f,0f),
			FloatVector(1f,1f)
		);

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

  void drawDefaultDropDown()
  {
    if (!_defaultPaint)
    {
      _defaultPaint = new DropDownPaint;
      _defaultPaint.backgroundColor = "EAEDED".getColorByHex;
      _defaultPaint.borderColor = "5F6A6A".getColorByHex;
    }

    drawDropDown("default",
      _defaultPaint.backgroundColor,
      _defaultPaint.borderColor);
  }

  void drawHoverDropDown()
  {
    if (!_hoverPaint)
    {
      _hoverPaint = new DropDownPaint;
      _hoverPaint.backgroundColor = "EAEDED".getColorByHex;
      _hoverPaint.borderColor = "5F6A6A".getColorByHex;
    }

    drawDropDown("hover",
      _hoverPaint.backgroundColor,
      _hoverPaint.borderColor);
  }

  public:
  final:
  this(Window window)
  {
    this(window, null, null);
  }

  this(Window window, string defaultName, string hoverName)
  {
    super(window, false);

    _defaultName = defaultName;
    _defaultRenderName = "";

    _hoverName = hoverName;
    _hoverRenderName = "";

    _dropDownItems = [];

    _onItemChanged = (i){};

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

      if (_itemsPanel.isHidden)
      {
        _dropDownLabel.text = "▲";
        _itemsPanel.show();
        _itemsPanelScrollBar.show();
      }
      else
      {
        _dropDownLabel.text = "▼";
        _itemsPanel.hide();
        _itemsPanelScrollBar.hide();
      }

      return false;
    }), true);

    onMouseMove(new MouseMoveEventHandler((p) {
      _hasMouseHover = super.intersectsWith(p);

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

      return !_hasMouseHover;
    }));

    restyle();
  }

  @property
  {
    bool showAbove() { return _showAbove; }
    void showAbove(bool shouldShowAbove)
    {
      _showAbove = shouldShowAbove;
    }
  }

  void onItemChanged(void delegate(dstring) handler)
  {
    if (!handler)
    {
      return;
    }

    _onItemChanged = handler;
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
    bool showingItems() { return _itemsPanel && !_itemsPanel.isHidden; }

    Variant value()
    {
      if (_selectedItem)
      {
        auto item = _dropDownItemsMap.get(_selectedItem, null);

        if (item)
        {
          return item.value;
        }
      }

      return Variant.init;
    }

    string defaultName() { return _defaultName; }
    void defaultName(string newName)
    {
      _defaultName = newName;

      updateRect(true);
    }

    string hoverName() { return _hoverName; }
    void hoverName(string newName)
    {
      _hoverName = newName;

      updateRect(true);
    }

    dstring selectedItem() { return _selectedItem; }

    dstring text() { return _text; }
    private void text(dstring newText)
    {
      _text = newText;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
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
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    size_t fontSize() { return _fontSize; }
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    bool fitToSize() { return _fitToSize; }
    void fitToSize(bool shouldFitToSize)
    {
      _fitToSize = shouldFitToSize;
      _fitted = false;
      _fontSizeForced = 0;

      updateLabel();

      updateRect(true);
    }

    DropDownPaint defaultPaint() { return _defaultPaint; }

    DropDownPaint hoverPaint() { return _hoverPaint; }
  }

  void setCustomDropDownDraw(DrawDropDownDelegate customDropDownDraw)
  {
    _customDropDownDraw = customDropDownDraw;

    restyle();
  }

  void removeCustomDropDownDraw()
  {
    _customDropDownDraw = null;

    restyle();
  }

  void restyle()
  {
    drawDefaultDropDown();
    drawHoverDropDown();

    updateRect(true);
  }

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

    if (_hasMouseHover && _hoverSheetRender && isEnabled)
    {
      _activeRender = _hoverSheetRender;
    }
    else
    {
      _activeRender = _defaultSheetRender;
    }

    if (_hasMouseHover && isEnabled)
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

  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_activeRender && _activeRender.texture)
    {
      EXT_RenderCopy(screen, _activeRender.texture, _activeRender.entry.textureRect, _activeRender.entry.rect);
    }

    renderChildren();
  }

  void setItem(dstring itemText)
  {
    if (!_dropDownItemsMap)
    {
      return;
    }

    auto item = _dropDownItemsMap.get(itemText, null);

    if (!item)
    {
      return;
    }

    _selectedItem = item.text;

    text = _selectedItem;

    _onItemChanged(text);
  }

  void addItem(T)(dstring itemText, T value = T.init)
  {
    addItem!T(itemText, (panel) {
      auto label = new Label(window);
      panel.addComponent(label);
      label.color = _textColor;
      label.text = itemText;
      label.fontName = _fontName;
      label.fontSize = _fontSize;
      label.position = IntVector((panel.width / 2) - (label.width / 2), (panel.height / 2) - (label.height /2));
      return label;
    }, value);
  }

  private int _lastItemY;

  void addItem(T)(dstring itemText, Component delegate(Panel) componentCreator, T value = T.init)
  {
    Variant variantValue = value;

    auto window = super.window;

    if (!_itemsPanel)
    {
      if (!_dropDownLabel)
      {
        _dropDownLabel = new Label(window);
        addComponent(_dropDownLabel, true);
        _dropDownLabel.color = Color(_textColor.r, _textColor.g, _textColor.b, 118);
        _dropDownLabel.text = "▼";
        _dropDownLabel.fontName = _fontName;
        _dropDownLabel.fontSize = 12;
        _dropDownLabel.position = IntVector(super.width - 16, (super.height / 2) - (_dropDownLabel.height /2));
      }

      _itemsPanel = new Panel(window);
      auto parent = super.parent;

      if (parent) parent.addComponent(_itemsPanel);
      else
      {
        auto view = super.view;
        if (view)
        {
          view.addComponent(_itemsPanel);
        }
        else
        {
          window.addComponent(_itemsPanel);
        }
      }

      _itemsPanel.hide();
      _itemsPanel.size = IntVector(super.width-15, super.height * 4);
      if (_showAbove)
      {
        _itemsPanel.position = IntVector(super.x, (super.y - _itemsPanel.height())-1);
      }
      else
      {
        _itemsPanel.position = IntVector(super.x, (super.y + super.height)-1);
      }
      _itemsPanel.fillColor = defaultPaint.backgroundColor;
      _itemsPanel.borderColor = defaultPaint.borderColor;
      _itemsPanel.scrollMargin = IntVector(0,cast(int)((cast(double)_itemsPanel.height / 3.5) / 2));

      if (!_itemsPanelScrollBar)
      {
      	_itemsPanelScrollBar = new ScrollBar(window, _itemsPanel);
      	_itemsPanelScrollBar.fillColor = defaultPaint.backgroundColor;
      	_itemsPanelScrollBar.borderColor = defaultPaint.borderColor;
        if (parent) parent.addComponent(_itemsPanelScrollBar);
        else
        {
          auto view = super.view;
          if (view)
          {
            view.addComponent(_itemsPanelScrollBar);
          }
          else
          {
            window.addComponent(_itemsPanelScrollBar);
          }
        }
      	_itemsPanelScrollBar.isVertical = true;
      	_itemsPanelScrollBar.size = IntVector(16, _itemsPanel.height);
      	_itemsPanelScrollBar.position = IntVector(_itemsPanel.x + _itemsPanel.width, _itemsPanel.y);
      	_itemsPanelScrollBar.buttonScrollAmount = cast(int)((cast(double)_itemsPanel.height / 3.5) / 2);
      	_itemsPanelScrollBar.fontName = _fontName;
      	_itemsPanelScrollBar.fontSize = 8;
      	_itemsPanelScrollBar.buttonTextColor = _textColor;
      	_itemsPanelScrollBar.createDecrementButton("▲", "◀");
      	_itemsPanelScrollBar.createIncrementButton("▼", "▶");
        _itemsPanelScrollBar.scrollButtonDefaultPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.scrollButtonDefaultPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.scrollButtonDefaultPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.scrollButtonDefaultPaint.shadowColor = _defaultPaint.shadowColor;
        _itemsPanelScrollBar.scrollButtonHoverPaint.backgroundColor = _hoverPaint.backgroundColor;
        _itemsPanelScrollBar.scrollButtonHoverPaint.backgroundBottomColor = _hoverPaint.backgroundBottomColor;
        _itemsPanelScrollBar.scrollButtonHoverPaint.borderColor = _hoverPaint.borderColor;
        _itemsPanelScrollBar.scrollButtonHoverPaint.shadowColor = _hoverPaint.shadowColor;
        _itemsPanelScrollBar.scrollButtonClickPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.scrollButtonClickPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.scrollButtonClickPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.scrollButtonClickPaint.shadowColor = _defaultPaint.shadowColor;

        _itemsPanelScrollBar.decrementButtonDefaultPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.decrementButtonDefaultPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.decrementButtonDefaultPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.decrementButtonDefaultPaint.shadowColor = _defaultPaint.shadowColor;
        _itemsPanelScrollBar.decrementButtonHoverPaint.backgroundColor = _hoverPaint.backgroundColor;
        _itemsPanelScrollBar.decrementButtonHoverPaint.backgroundBottomColor = _hoverPaint.backgroundBottomColor;
        _itemsPanelScrollBar.decrementButtonHoverPaint.borderColor = _hoverPaint.borderColor;
        _itemsPanelScrollBar.decrementButtonHoverPaint.shadowColor = _hoverPaint.shadowColor;
        _itemsPanelScrollBar.decrementButtonClickPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.decrementButtonClickPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.decrementButtonClickPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.decrementButtonClickPaint.shadowColor = _defaultPaint.shadowColor;

        _itemsPanelScrollBar.incrementButtonDefaultPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.incrementButtonDefaultPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.incrementButtonDefaultPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.incrementButtonDefaultPaint.shadowColor = _defaultPaint.shadowColor;
        _itemsPanelScrollBar.incrementButtonHoverPaint.backgroundColor = _hoverPaint.backgroundColor;
        _itemsPanelScrollBar.incrementButtonHoverPaint.backgroundBottomColor = _hoverPaint.backgroundBottomColor;
        _itemsPanelScrollBar.incrementButtonHoverPaint.borderColor = _hoverPaint.borderColor;
        _itemsPanelScrollBar.incrementButtonHoverPaint.shadowColor = _hoverPaint.shadowColor;
        _itemsPanelScrollBar.incrementButtonClickPaint.backgroundColor = _defaultPaint.backgroundColor;
        _itemsPanelScrollBar.incrementButtonClickPaint.backgroundBottomColor = _defaultPaint.backgroundBottomColor;
        _itemsPanelScrollBar.incrementButtonClickPaint.borderColor = _defaultPaint.borderColor;
        _itemsPanelScrollBar.incrementButtonClickPaint.shadowColor = _defaultPaint.shadowColor;
        _itemsPanelScrollBar.hide();
      }
    }

    auto parent = super.parent;

    auto panel = new Panel(window);
    _itemsPanel.addComponent(panel);

    auto height = cast(int)(cast(double)_itemsPanel.height / 3.5);
    panel.position = IntVector(0, _lastItemY);
    _lastItemY += height-1;
    panel.size = IntVector(_itemsPanel.width, height);
    panel.borderColor = defaultPaint.borderColor;

    auto component = componentCreator(panel);

    auto event = new MouseButtonEventHandler((b,p) {
      _itemsPanel.hide();
      _itemsPanelScrollBar.hide();

      _dropDownLabel.text = "▼";

      setItem(itemText);

      return false;
    });

    panel.onMouseButtonUp(event);
    component.onMouseButtonUp(event);

    auto dropDownItem = new DropDownItem;
    dropDownItem.text = itemText;
    dropDownItem.component = component;
    dropDownItem.panel = panel;
    dropDownItem.value = variantValue;
    _dropDownItems ~= dropDownItem;
    _dropDownItemsMap[itemText] = dropDownItem;

    updateRect(true);

    _itemsPanelScrollBar.restyle();
  }
}
