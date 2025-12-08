/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.scrollbar;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.events;
import dvn.colors;
import dvn.components.panel;
import dvn.components.button;

public final class ScrollBar : Component
{
  private:
  Button _decrementButton;
  Button _scrollButton;
  Button _incrementButton;
  Panel _scrollablePanel;
  size_t _fontSize;
  string _fontName;
  string _defaultName;
  string _clickName;
  string _hoverName;
  dstring _decrementButtonTextVertical;
  dstring _decrementButtonTextHorizontal;
  dstring _incrementButtonTextVertical;
  dstring _incrementButtonTextHorizontal;
  Color _buttonTextColor;
  bool _isVertical;
  int _buttonScrollAmount;

  public:
  final:
  this(Window window, Panel scrollablePanel, string defaultName, string clickName, string hoverName)
  {
    super(window, false);

    _scrollablePanel = scrollablePanel;
    _defaultName = defaultName;
    _clickName = clickName;
    _hoverName = hoverName;

    _fontSize = 10;
    _buttonScrollAmount = 24;

    scrollablePanel.scrollBar = this;
  }

  this(Window window, Panel scrollablePanel)
  {
    this(window, scrollablePanel, null, null, null);
  }

  int minScroll;
  int maxScroll;

  void createDecrementButton(dstring buttonTextVertical, dstring buttonTextHorizontal)
  {
    _decrementButtonTextVertical = buttonTextVertical;
    _decrementButtonTextHorizontal = buttonTextHorizontal;

    createDecrementButton();

    updateRect(true);
  }

  private void createDecrementButton()
  {
    if (!_decrementButtonTextVertical || !_decrementButtonTextVertical.length)
    {
      return;
    }

    if (!_decrementButtonTextHorizontal || !_decrementButtonTextHorizontal.length)
    {
      return;
    }

    auto rect = super.clientRect;

    int width;
    int height;
    dstring buttonText;

    if (_isVertical)
    {
      width = rect.w;
      height = cast(int)((cast(double)rect.h / cast(double)100) * 8);
      buttonText = _decrementButtonTextVertical;
    }
    else
    {
      width = cast(int)((cast(double)rect.w / cast(double)100) * 8);
      height = rect.h;
      buttonText = _decrementButtonTextHorizontal;
    }

    bool exists = _decrementButton !is null;

    if (exists)
    {
      _decrementButton.defaultName = _defaultName;
      _decrementButton.clickName = _clickName;
      _decrementButton.hoverName = _hoverName;
    }
    else
    {
      _decrementButton = new Button(window, _defaultName, _clickName, _hoverName);
      super.addComponent(_decrementButton, true);
    }

    if (_isVertical)
    {
      minScroll = _scrollablePanel.minScrollVertical;
      maxScroll = _scrollablePanel.maxScrollVertical;
    }
    else
    {
      minScroll = _scrollablePanel.minScrollHorizontal;
      maxScroll = _scrollablePanel.maxScrollHorizontal;
    }

    _decrementButton.position = IntVector(0,0);
    _decrementButton.size = IntVector(width, height);
    _decrementButton.text = buttonText;
    _decrementButton.fontName = _fontName;
    _decrementButton.fontSize = _fontSize;
    _decrementButton.fitToSize = true;
    _decrementButton.textColor = _buttonTextColor;
    _decrementButton.restyle();
    _decrementButton.show();
    if (!exists) _decrementButton.onButtonClick(new MouseButtonEventHandler((b,p)
    {
      return scrollDecrement();
    }));

    if (!exists)
    {
      updateRect(false);

      super.window.update();
    }
  }

  void createIncrementButton(dstring buttonTextVertical, dstring buttonTextHorizontal)
  {
    _incrementButtonTextVertical = buttonTextVertical;
    _incrementButtonTextHorizontal = buttonTextHorizontal;

    createIncrementButton();

    updateRect(true);
  }

  private void createIncrementButton()
  {
    if (!_incrementButtonTextVertical || !_incrementButtonTextVertical.length)
    {
      return;
    }

    if (!_incrementButtonTextHorizontal || !_incrementButtonTextHorizontal.length)
    {
      return;
    }

    auto rect = super.clientRect;

    int width;
    int height;
    dstring buttonText;

    if (_isVertical)
    {
      width = rect.w;
      height = cast(int)((cast(double)rect.h / cast(double)100) * 8);
      buttonText = _incrementButtonTextVertical;
    }
    else
    {
      width = cast(int)((cast(double)rect.w / cast(double)100) * 8);
      height = rect.h;
      buttonText = _incrementButtonTextHorizontal;
    }

    bool exists = _incrementButton !is null;

    if (_incrementButton)
    {
      _incrementButton.defaultName = _defaultName;
      _incrementButton.clickName = _clickName;
      _incrementButton.hoverName = _hoverName;
    }
    else
    {
      _incrementButton = new Button(window, _defaultName, _clickName, _hoverName);
      super.addComponent(_incrementButton, true);
    }

    if (_isVertical)
    {
      minScroll = _scrollablePanel.minScrollVertical;
      maxScroll = _scrollablePanel.maxScrollVertical;
    }
    else
    {
      minScroll = _scrollablePanel.minScrollHorizontal;
      maxScroll = _scrollablePanel.maxScrollHorizontal;
    }

    if (_isVertical)
    {
      _incrementButton.position = IntVector(0,rect.h - height);
    }
    else
    {
      _incrementButton.position = IntVector(rect.w - width,0);
    }

    _incrementButton.size = IntVector(width, height);
    _incrementButton.text = buttonText;
    _incrementButton.fontName = _fontName;
    _incrementButton.fontSize = _fontSize;
    _incrementButton.fitToSize = true;
    _incrementButton.textColor = _buttonTextColor;
    _incrementButton.restyle();
    _incrementButton.show();
    if (!exists) _incrementButton.onButtonClick(new MouseButtonEventHandler((b,p)
    {
      return scrollIncrement();
    }));

    if (!exists)
    {
      updateRect(false);

      super.window.update();
    }
  }

  public void scrollToEnd()
  {
    auto scrollPosition = _scrollablePanel.getScrollPosition();

    if (_isVertical)
    {
      if (scrollPosition.y != maxScroll)
      {
        _scrollablePanel.scrollTo(scrollPosition.x, maxScroll);
      }
    }
    else
    {
      if (scrollPosition.x != maxScroll)
      {
        _scrollablePanel.scrollTo(maxScroll, scrollPosition.y);
      }
    }
  }

  package(dvn) bool scrollDecrement()
  {
    auto scrollPosition = _scrollablePanel.getScrollPosition();

    if (_isVertical)
    {
      if (scrollPosition.y == minScroll)
      {
        return false;
      }

      auto scrollToY = scrollPosition.y - _buttonScrollAmount;

      if (scrollToY < minScroll)
      {
        scrollToY = minScroll;
      }

      _scrollablePanel.scrollTo(scrollPosition.x, scrollToY);
      createScrollButton();
    }
    else
    {
      if (scrollPosition.x == minScroll)
      {
        return false;
      }

      auto scrollToX = scrollPosition.x - _buttonScrollAmount;

      if (scrollToX < minScroll)
      {
        scrollToX = minScroll;
      }

      _scrollablePanel.scrollTo(scrollToX, scrollPosition.y);
      createScrollButton();
    }

    return false;
  }

  package(dvn) bool scrollIncrement(bool aboveMaxRun = false)
  {
    if (maxScroll == minScroll || maxScroll <= 0)
    {
      return false;
    }

    auto scrollPosition = _scrollablePanel.getScrollPosition();

    if (_isVertical)
    {
      if (scrollPosition.y == maxScroll)
      {
        return false;
      }

      auto scrollToY = scrollPosition.y + _buttonScrollAmount;

      auto aboveMax = scrollToY > maxScroll;
      if (aboveMax)
      {
        scrollToY = maxScroll;
      }

      _scrollablePanel.scrollTo(scrollPosition.x, scrollToY);
      createScrollButton();

      if (aboveMax && !aboveMaxRun) // Weird hack ... (2024)
      {
        //scrollDecrement();
        //scrollIncrement(true); // We comment this out, idk why it was there to begin with, seems to work (2025)
      }
    }
    else
    {
      if (scrollPosition.x == maxScroll)
      {
        return false;
      }

      auto scrollToX = scrollPosition.x + _buttonScrollAmount;

      auto aboveMax = scrollToX > maxScroll;
      if (aboveMax)
      {
        scrollToX = maxScroll;
      }

      _scrollablePanel.scrollTo(scrollToX, scrollPosition.y);
      createScrollButton();

      if (aboveMax) // Weird hack ... (2024)
      {
        //scrollDecrement();
        //scrollIncrement(true); // See comment with the other weird hack (2025)
      }
    }
    return false;
  }

  package(dvn) void makeScrollableWithWheel()
  {
    onMouseWheel(new MouseWheelEventHandler((a,p) {
      if (_buttonScrollAmount <= 0 || a == 0) return true;

      bool hover = super.intersectsWith(p);

      if (!hover) return true;
      
      bool decrement = a < 0;
      if (a < 0) a = -a;

      if (decrement)
      {
        foreach (_; 0 .. a)
        {
          scrollIncrement();
        }
      }
      else
      {
        foreach (_; 0 .. a)
        {
          scrollDecrement();
        }
      }

      return false;
    }));
  } 

  private void createScrollButton()
  {
    if (!_decrementButton || !_incrementButton)
    {
      return;
    }

    auto rect = super.clientRect;

    int width;
    int height;
    dstring buttonText;

    if (_isVertical)
    {
      width = rect.w;
      height = (_decrementButton.height + _incrementButton.height) / 2;
      buttonText = _incrementButtonTextVertical;
    }
    else
    {
      width = (_decrementButton.width + _incrementButton.width) / 2;
      height = rect.h;
      buttonText = _incrementButtonTextHorizontal;
    }

    bool exists = _scrollButton !is null;

    if (_scrollButton)
    {
      _scrollButton.defaultName = _defaultName;
      _scrollButton.clickName = _defaultName;
      _scrollButton.hoverName = _defaultName;
    }
    else
    {
      _scrollButton = new Button(window, _defaultName, _defaultName, _defaultName);
      _scrollButton.disable();
      super.addComponent(_scrollButton, true);
    }

    auto scrollPosition = _scrollablePanel.getScrollPosition();

    if (_isVertical)
    {
      double percentageScrolled = (cast(double)scrollPosition.y / cast(double)maxScroll) * cast(double)100;
      int percentageScrolledInteger = cast(int)percentageScrolled;
      if (percentageScrolledInteger > 100)
      {
        percentageScrolledInteger = 100;
      }

      int y = cast(int)(((cast(double)super.height - (cast(double)height*3)) / 100) * percentageScrolled);

      if (percentageScrolledInteger == 100)
      {
        y = super.height - (_incrementButton.height + height);
      }
      else
      {
        y += _decrementButton.height;
      }

      _scrollButton.position = IntVector(0,y);
    }
    else
    {
      double percentageScrolled = (cast(double)scrollPosition.x / cast(double)maxScroll) * cast(double)100;
      int percentageScrolledInteger = cast(int)percentageScrolled;
      if (percentageScrolledInteger > 100)
      {
        percentageScrolledInteger = 100;
      }

      int x = cast(int)(((cast(double)super.width - (cast(double)width*3)) / 100) * percentageScrolled);

      if (percentageScrolledInteger == 100)
      {
        x = super.width - (_incrementButton.width + width);
      }
      else
      {
        x += _decrementButton.width;
      }

      _scrollButton.position = IntVector(x,0);
    }

    _scrollButton.size = IntVector(width, height);
    _scrollButton.text = "";
    _scrollButton.fontName = _fontName;
    _scrollButton.fontSize = 4;
    _scrollButton.fitToSize = false;
    _scrollButton.textColor = _buttonTextColor;
    _scrollButton.restyle();
    _scrollButton.show();

    if (!exists)
    {
      updateRect(false);

      super.window.update();
    }
  }

  @property
  {
    size_t fontSize() { return _fontSize; }
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;

      updateRect(true);
    }

    string fontName() { return _fontName; }
    void fontName(string newFontName)
    {
      _fontName = newFontName;

      updateRect(true);
    }

    string defaultName() { return _defaultName; }
    void defaultName(string newName)
    {
      _defaultName = newName;

      updateRect(true);
    }

    string clickName() { return _clickName; }
    void clickName(string newName)
    {
      _clickName = newName;

      updateRect(true);
    }

    string hoverName() { return _hoverName; }
    void hoverName(string newName)
    {
      _hoverName = newName;

      updateRect(true);
    }

    Color buttonTextColor() { return _buttonTextColor; }
    void buttonTextColor(Color newColor)
    {
      _buttonTextColor = newColor;

      updateRect(true);
    }

    dstring decrementButtonTextVertical() { return _decrementButtonTextVertical; }

    dstring decrementButtonTextHorizontal() { return _decrementButtonTextHorizontal; }

    dstring incrementButtonTextVertical() { return _incrementButtonTextVertical; }

    dstring incrementButtonTextHorizontal() { return _incrementButtonTextHorizontal; }

    bool isVertical() { return _isVertical; }
    void isVertical(bool setAsVertical)
    {
      _isVertical = setAsVertical;

      updateRect(true);
    }

    size_t buttonScrollAmount() { return cast(size_t)_buttonScrollAmount; }
    void buttonScrollAmount(size_t newButtonScrollAmount)
    {
      _buttonScrollAmount = cast(int)newButtonScrollAmount;
    }

    ButtonPaint scrollButtonDefaultPaint() { return _scrollButton ? _scrollButton.defaultPaint : null; }

    ButtonPaint scrollButtonHoverPaint() { return _scrollButton ? _scrollButton.hoverPaint : null; }

    ButtonPaint scrollButtonClickPaint() { return _scrollButton ? _scrollButton.clickPaint : null; }

    ButtonPaint decrementButtonDefaultPaint() { return _decrementButton ? _decrementButton.defaultPaint : null; }

    ButtonPaint decrementButtonHoverPaint() { return _decrementButton ? _decrementButton.hoverPaint : null; }

    ButtonPaint decrementButtonClickPaint() { return _decrementButton ? _decrementButton.clickPaint : null; }

    ButtonPaint incrementButtonDefaultPaint() { return _incrementButton ? _incrementButton.defaultPaint : null; }

    ButtonPaint incrementButtonHoverPaint() { return _incrementButton ? _incrementButton.hoverPaint : null; }

    ButtonPaint incrementButtonClickPaint() { return _incrementButton ? _incrementButton.clickPaint : null; }
  }

  void setCustomButtonDraw(DrawButtonDelegate customButtonDraw)
  {
    if (_decrementButton) _decrementButton.setCustomButtonDraw(customButtonDraw);
    if (_incrementButton) _incrementButton.setCustomButtonDraw(customButtonDraw);
  }

  void removeCustomButtonDraw()
  {
    if (_decrementButton) _decrementButton.removeCustomButtonDraw();
    if (_incrementButton) _incrementButton.removeCustomButtonDraw();
  }

  void restyle()
  {
    if (_decrementButton) _decrementButton.restyle();
    if (_incrementButton) _incrementButton.restyle();
  }

  override void repaint()
  {
    auto rect = super.clientRect;

    createDecrementButton();
    createIncrementButton();
    createScrollButton();
  }

  override void renderNativeComponent()
  {
    renderChildren();
  }

  void updateScrollView()
  {
    restyle();
    updateRect(false);
  }
}
