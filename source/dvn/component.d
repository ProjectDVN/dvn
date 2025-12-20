/**
* Copyright (c) 2025 Project DVN
*/
module dvn.component;

import dvn.external;
import dvn.meta;
import dvn.view;
import dvn.window;
import dvn.events;
import dvn.painting;
import dvn.layout;

/// 
mixin CreateCustomException!"ComponentException";

private
{
  size_t _componentId;

  bool intersectsWith(int x1, int y1, int x2, int y2, int w2, int h2)
  {
    return (x1 > x2) &&
      (x1 < (x2 + w2)) &&
      (y1 > y2) &&
      (y1 < (y2 + h2));
  }

  Component _focusComponent;

  EXT_Rectangle[] _nativeRects;
  ptrdiff_t _nativeRectOffset = -1;

  void pushNativeRect(EXT_Screen screen, EXT_Rectangle rect)
  {
    if (!_nativeRects)
    {
      _nativeRects = new EXT_Rectangle[256];
    }

    _nativeRectOffset++;
    _nativeRects[_nativeRectOffset] = rect;

    EXT_SetRenderRectangle(screen, _nativeRects[_nativeRectOffset]);
  }

  void popNativeRect(EXT_Screen screen)
  {
    _nativeRectOffset--;
    if (_nativeRectOffset == -1)
    {
      EXT_SetRenderRectangle(screen, null);
    }
    else
    {
      EXT_SetRenderRectangle(screen, _nativeRects[_nativeRectOffset]);
    }
  }
}

public abstract class Component : ILayout
{
  private:
  bool _hasFullRepaint;
  bool _isRenderVisible;
  bool _isHidden;
  Rectangle _rect;
  IntVector _size;
  IntVector _position;
  Component _parent;
  Window _window;
  Component[] _components;
  Component[] _renderComponents;
  size_t _id;
  MouseButtonEventHandler[] _onMouseButtonDown;
  MouseButtonEventHandler[] _onMouseButtonUp;
  MouseMoveEventHandler[] _onMouseMove;
  TextInputEventHandler[] _onTextInput;
  KeyboardEventHandler[] _onKeyboardDown;
  KeyboardEventHandler[] _onKeyboardUp;
  MouseWheelEventHandler[] _onMouseWheel;
  IntVector _scrollPosition;
  bool _allowChildren;
  EXT_Rectangle _nativeRect;
  bool _focus;
  Rectangle _boundsRectangle;
  Rectangle _renderRect;
  View _view;
  bool _cleaned;
  Color _fillColor;
  Color _borderColor;
  Color _topColor;
  EXT_Rectangle _nativeRenderRectangle;
  Rectangle _clientRect;
  Painting[string] _paintings;
  Painting[] _paintingsAll;
  Painting _currentPainting;
  bool _disabled;
  ulong _dataId;
  Anchor _anchor;
  bool _isInputComponent;

  package(dvn) void updateEvents()
  {
    if (_cleaned) return;

    if (!isHidden && !_disabled)
    {
      auto events = _window.events;

      foreach (component; _renderComponents)
      {
        component.update();
      }

      if (_onMouseButtonDown)
      {
        foreach (onMouseButtonDown; _onMouseButtonDown)
        {
          events.attachMouseButtonDownEvent(onMouseButtonDown);
        }
      }

      if (_onMouseButtonUp)
      {
        foreach (onMouseButtonUp; _onMouseButtonUp)
        {
          events.attachMouseButtonUpEvent(onMouseButtonUp);
        }
      }

      if (_onMouseMove)
      {
        foreach (onMouseMove; _onMouseMove)
        {
          events.attachMouseMoveEvent(onMouseMove);
        }
      }

      if (_onTextInput)
      {
        foreach (onTextInput; _onTextInput)
        {
          events.attachTextInputEvent(onTextInput);
        }
      }

      if (_onKeyboardDown)
      {
        foreach (onKeyboardDown; _onKeyboardDown)
        {
          events.attachKeyboardDownEvent(onKeyboardDown);
        }
      }

      if (_onKeyboardUp)
      {
        foreach (onKeyboardUp; _onKeyboardUp)
        {
          events.attachKeyboardUpEvent(onKeyboardUp);
        }
      }

      if (_onMouseWheel)
      {
        foreach (onMouseWheel; _onMouseWheel)
        {
          events.attachMouseWheelEvent(onMouseWheel);
        }
      }
    }
  }

/// 
  public void fireMouseButtonDown(MouseButton button, IntVector mousePosition)
  {
    if (!_onMouseButtonDown)
    {
      return;
    }

    foreach (event; _onMouseButtonDown)
    {
      event(button, mousePosition);
    }
  }

/// 
  public void fireMouseButtonUp(MouseButton button, IntVector mousePosition)
  {
    if (!_onMouseButtonUp)
    {
      return;
    }

    foreach (event; _onMouseButtonUp)
    {
      event(button, mousePosition);
    }
  }

/// 
  public void fireMouseMove(IntVector mousePosition)
  {
    if (!_onMouseMove)
    {
      return;
    }

    foreach (event; _onMouseMove)
    {
      event(mousePosition);
    }
  }

/// 
  public void fireTextInput(dchar c)
  {
    import std.conv : to;

    if (!_onTextInput)
    {
      return;
    }

    foreach (event; _onTextInput)
    {
      event(c, c.to!dstring);
    }
  }

/// 
  public void fireKeyboardDown(KeyboardKey key)
  {
    if (!_onKeyboardDown)
    {
      return;
    }

    foreach (event; _onKeyboardDown)
    {
      event(key);
    }
  }

/// 
  public void fireKeyboardUp(KeyboardKey key)
  {
    if (!_onKeyboardUp)
    {
      return;
    }

    foreach (event; _onKeyboardUp)
    {
      event(key);
    }
  }

/// 
  public void fireMouseWheel(int amount, IntVector position)
  {
    if (!_onMouseWheel)
    {
      return;
    }

    foreach (event; _onMouseWheel)
    {
      event(amount,position);
    }
  }

/// 
  public void update()
  {
    if (_cleaned) return;

    _renderComponents = [];
    if (_components)
    {
      foreach (component; _components)
      {
        if (!component.isHidden && !isHidden)
        {
          _renderComponents ~= component;
        }
      }
    }

    updateEvents();
  }

/// 
  public void updateRect(bool updateParent)
  {
    if (_cleaned || _forceRender)
    {
      return;
    }

    IntVector measuredSize;
    if (measureComponentSize(measuredSize))
    {
      _size = measuredSize;
    }

    void renderDefault()
    {
      _clientRect = Rectangle(0,0,0,0);
      _boundsRectangle = Rectangle(0,0,0,0);
      _renderRect = _boundsRectangle;
      _isRenderVisible = false;

      if (_paintingsAll)
      {
        foreach (paintingParent; _paintingsAll)
        {
          foreach (painting; paintingParent.bottomPaintings)
          {
            painting.rect = null;
          }

          foreach (painting; paintingParent.topPaintings)
          {
            painting.rect = null;
          }
        }
      }

      if (_currentPainting)
      {
        foreach (painting; _currentPainting.bottomPaintings)
        {
          painting.rect = null;
        }

        foreach (painting; _currentPainting.topPaintings)
        {
          painting.rect = null;
        }
      }

      repaint();

      update();

      if (_parent && updateParent)
      {
        _parent.update();
      }
    }

    if (_parent && (!_parent._isRenderVisible || _parent.isHidden))
    {
      renderDefault();
      return;
    }

    int rawParentX = 0;
    int rawParentY = 0;
    int parentX = 0;
    int parentY = 0;
    int offsetX = 0;
    int offsetY = 0;
    int parentWidth = 0;
    int parentHeight = 0;

    int max(int a, int b) { return a > b ? a : b; }

    if (_parent)
    {
      auto scrollPosition = _parent._scrollPosition;
      offsetX = -scrollPosition.x;
      offsetY = -scrollPosition.y;

      auto parentClientRect = _parent.clientRect;

      rawParentX = parentClientRect.x + offsetX;
      rawParentY = parentClientRect.y + offsetY;

      auto parentBoundsRectangle = _parent._boundsRectangle;

      parentX = parentBoundsRectangle.x;
      parentY = parentBoundsRectangle.y;
      parentWidth = parentBoundsRectangle.w;
      parentHeight = parentBoundsRectangle.h;
    }
    else if (_window)
    {
      parentX = 0;
      parentY = 0;
      rawParentX = 0;
      rawParentY = 0;
      parentWidth = _window.width;
      parentHeight = window.height;
    }

    if (parentWidth == 0 || parentHeight == 0)
    {
      renderDefault();
      return;
    }

    _clientRect = Rectangle(_position.x + rawParentX, _position.y + rawParentY, _size.x, _size.y);

    if (_paintingsAll)
    {
      foreach (paintingParent; _paintingsAll)
      {
        foreach (painting; paintingParent.bottomPaintings)
        {
          auto paintingRect = Rectangle(_position.x + rawParentX + cast(int)((_clientRect.w * painting.position.x)), _position.y + rawParentY + cast(int)(_clientRect.h * painting.position.y), cast(int)(_clientRect.w * painting.size.x), cast(int)(_clientRect.h * painting.size.y));
          paintingRect = paintingRect.minimumSize();
          painting.rect = EXT_CreateRectangle(paintingRect);
        }

        foreach (painting; paintingParent.topPaintings)
        {
          auto paintingRect = Rectangle(_position.x + rawParentX + cast(int)((_clientRect.w * painting.position.x)), _position.y + rawParentY + cast(int)(_clientRect.h * painting.position.y), cast(int)(_clientRect.w * painting.size.x), cast(int)(_clientRect.h * painting.size.y));
          paintingRect = paintingRect.minimumSize();
          painting.rect = EXT_CreateRectangle(paintingRect);
        }
      }
    }

    int x = parentX + _position.x + offsetX;
    int y = parentY + _position.y + offsetY;
    int w = _size.x;
    int h = _size.y;

    int right = x + w;
    int parentRight = parentX + parentWidth;

    int maxRight = right - parentRight;

    if (maxRight > 0)
    {
      w -= maxRight;
    }

    int bottom = y + h;
    int parentBottom = parentY + parentHeight;

    int maxBottom = bottom - parentBottom;

    if (maxBottom > 0)
    {
      h -= maxBottom;
    }

    if (w <= 0 || h <= 0 || ((w + x) <= 0) || ((h + y) <= 0 || ((w + x) > parentRight) || ((h + y) > parentBottom)))
    {
      renderDefault();
      return;
    }

    _boundsRectangle = Rectangle(x, y, w, h);
    auto parentRect = Rectangle(parentX, parentY, parentWidth, parentHeight);

    _renderRect = _boundsRectangle;
    auto screenRectangle = intersectRectangle(parentRect, _renderRect);
    _boundsRectangle = screenRectangle;

    _isRenderVisible = screenRectangle.w > 0 && screenRectangle.h > 0;

    if (_isRenderVisible)
    {
      _nativeRect = EXT_CreateRectangle(screenRectangle);
    }

    _nativeRenderRectangle = EXT_CreateRectangle(_renderRect);

    repaint();

    if (_components)
    {
      foreach (component; _components)
      {
        component.updateRect(false);
      }
    }

    if (updateParent)
    {
      if (_parent)
      {
        _parent.update();
      }
      else
      {
        update();
      }

      if (_window)
      {
        _window.update();
      }
    }
    else
    {
      update();
    }
  }

/// 
  public void updateRect()
  {
    updateRect(true);
  }

  public:
  /// 
    void show()
    {
      _isHidden = false;
      updateRect(true);
    }

    /// 
    void addComponent(Component component)
    {
      addComponent(component, false);
    }
    
  final
  {
/// 
    void enableSwiping(bool delegate(MouseButton,SwipeDirection,IntVector) swipe, int tolerance = 150)
    {
      bool isHoldingDown = false;
      IntVector startPosition;
      IntVector endPosition;

      onMouseButtonDown(new MouseButtonEventHandler((b,p)
      {
        isHoldingDown = true;
        startPosition = p;
        endPosition = p;

        return true;
      }));

      onMouseButtonUp(new MouseButtonEventHandler((b,p)
      {
        if (!isHoldingDown)
            return true;

        isHoldingDown = false;

        endPosition = p;

        int dx = endPosition.x - startPosition.x;
        int dy = endPosition.y - startPosition.y;

        long distSq = cast(long)dx * dx + cast(long)dy * dy;
        long toleranceSq = cast(long)tolerance * tolerance;

        if (distSq < toleranceSq)
            return true;

        SwipeDirection dir;

        int absDx = dx < 0 ? -dx : dx;
        int absDy = dy < 0 ? -dy : dy;

        if (absDx > absDy)
        {
            if (dx > 0)
                dir = SwipeDirection.right;
            else
                dir = SwipeDirection.left;
        }
        else
        {
            if (dy > 0)
                dir = SwipeDirection.down;
            else
                dir = SwipeDirection.up;
        }

        return swipe(b, dir, p);
      }));

      onMouseMove(new MouseMoveEventHandler((p)
      {
        if (!isHoldingDown) return true;

        endPosition = p;
        return true;
      }));
    }

/// 
    void hide()
    {
      _isHidden = true;
      updateRect(true);
    }

/// 
    protected void addComponent(Component component, bool forceAddComponent = false)
    {
      if (!_allowChildren && !forceAddComponent)
      {
        throw new ComponentException("This component does not allow children.");
      }

      if (!component)
      {
        throw new ArgumentException("Invalid component.");
      }

      if (component._parent)
      {
        throw new ComponentException("Component already has parent.");
      }

      _components ~= component;

      component._parent = this;
      component._view = component._parent.view;
      component._window = component._parent.window;

      component.updateRect(false);

      if (_window) _window.update();
      else update();
    }

/// 
    void removeComponent(Component component, bool updateRect = true)
    {
      if (!component)
      {
        throw new ArgumentException("Invalid component.");
      }

      import std.algorithm : filter;
      import std.array : array;

      if (component._parent is null || component._parent._id != _id)
      {
        throw new ComponentException("Component isn't child of this component.");
      }

      _components = _components.filter!(c => c._id != component._id).array;

      component._parent = null;
      component._view = null;
      component._window = null;
      
      if (updateRect) component.updateRect(false);

      if (_window) _window.update();
      else update();
    }

/// 
    void clearComponents()
    {
      if (!_components)
      {
        return;
      }

      foreach (comp; _components.dup)
      {
        removeComponent(comp, false);
      }

      _components = [];
      _renderComponents = [];
      update();
    }

/// 
    void onMouseButtonDown(MouseButtonEventHandler handler, bool ignoreIntersection = false)
    {
      if (ignoreIntersection)
      {
        _onMouseButtonDown ~= handler;
      }
      else
      {
        _onMouseButtonDown ~= new MouseButtonEventHandler((b,p)
        {
          if (!intersectsWith(p))
          {
            loseFocus();

            return true;
          }

          return handler(b,p);
        });
      }

      if (_window) _window.update();
      else update();
    }

/// 
    void onMouseButtonUp(MouseButtonEventHandler handler, bool ignoreIntersection = false)
    {
      if (ignoreIntersection)
      {
        _onMouseButtonUp ~= handler;
      }
      else
      {
        _onMouseButtonUp ~= new MouseButtonEventHandler((b,p)
        {
          if (!intersectsWith(p))
          {
            loseFocus();

            return true;
          }

          return handler(b,p);
        });
      }

      if (_window) _window.update();
      else update();
    }

/// 
    void onKeyboardDown(KeyboardEventHandler handler, bool ignoreFocus = false)
    {
      if (ignoreFocus)
      {
        _onKeyboardDown ~= handler;
      }
      else
      {
        _onKeyboardDown ~= new KeyboardEventHandler((k)
        {
          if (!_focus)
          {
            return true;
          }

          return handler(k);
        });
      }

      if (_window) _window.update();
      else update();
    }

/// 
    void onKeyboardUp(KeyboardEventHandler handler, bool ignoreFocus = false)
    {
      if (ignoreFocus)
      {
        _onKeyboardUp ~= handler;
      }
      else
      {
        _onKeyboardUp ~= new KeyboardEventHandler((k)
        {
          if (!_focus)
          {
            return true;
          }

          return handler(k);
        });
      }

      if (_window) _window.update();
      else update();
    }

/// 
    void onMouseMove(MouseMoveEventHandler handler)
    {
      _onMouseMove ~= handler;
    }

/// 
    void onTextInput(TextInputEventHandler handler, bool ignoreFocus = false)
    {
      _onTextInput ~= new TextInputEventHandler((c,s)
      {
        if (!_focus && !ignoreFocus)
        {
          return true;
        }

        return handler(c,s);
      });

      if (_window) _window.update();
      else update();
    }

/// 
    void onMouseWheel(MouseWheelEventHandler handler, bool ignoreIntersection = false)
    {
      if (ignoreIntersection)
      {
        _onMouseWheel ~= handler;
      }
      else
      {
        _onMouseWheel ~= new MouseWheelEventHandler((a,p)
        {
          if (!intersectsWith(p))
          {
            return true;
          }

          return handler(a,p);
        });
      }

      if (_window) _window.update();
      else update();
    }

/// 
    bool intersectsWith(IntVector position)
    {
      return _boundsRectangle.w > 0 && _boundsRectangle.h > 0 && .intersectsWith(position.x, position.y, _boundsRectangle.x, _boundsRectangle.y, _boundsRectangle.w, _boundsRectangle.h);
    }

    package(dvn) IntVector getScrollPosition()
    {
      return _scrollPosition;
    }

    package(dvn) void setScrollPosition(IntVector scrollPosition)
    {
      _scrollPosition = scrollPosition;

      updateRect(true);
    }

/// 
    void gainFocus()
    {
      if (_focus) return;

      if (_focusComponent)
      {
        _focusComponent.loseFocus();
      }

      _focus = true;
      _focusComponent = this;

      version (Windows)
      {
        import dvn.delayedtask;
        runDelayedTask(100, {
            import dvn.external;
            // auto flags = EXT_GetWindowFlags(window.nativeWindow);

            // bool hasKeyboardFocus = (flags & EXT_WINDOW_INPUT_FOCUS) != 0;
            
            // if (!hasKeyboardFocus)
            {
                EXT_RaiseWindow(window.nativeWindow);
                EXT_SetWindowInputFocus(window.nativeWindow);
            }
        });
      }

      updateRect(true);
    }

/// 
    void loseFocus()
    {
      if (!_focus) return;

      _focus = false;

      updateRect(true);
    }

/// 
    void clearPaintings()
    {
      if (_paintingsAll)
      {
        foreach (paintingParent; _paintingsAll)
        {
          foreach (painting; paintingParent.bottomPaintings)
          {
            painting.rect = null;
          }

          foreach (painting; paintingParent.topPaintings)
          {
            painting.rect = null;
          }
        }
      }

      if (_currentPainting)
      {
        foreach (painting; _currentPainting.bottomPaintings)
        {
          painting.rect = null;
        }

        foreach (painting; _currentPainting.topPaintings)
        {
          painting.rect = null;
        }
      }

      if (_paintings)
      {
        _paintings.clear();
      }

      _paintingsAll = [];
      _currentPainting = null;

      updateRect(true);
    }

/// 
    Painting beginPainting(string paintingName)
    {
      auto painting = _paintings.get(paintingName, null);

      if (!painting)
      {
        painting = new Painting(paintingName, this);
        _paintingsAll ~= painting;
        _paintings[paintingName] = painting;
      }
      else
      {
        painting.clearBackgroundPaint();
        painting.clearForegroundPaint();
      }

      if (!_currentPainting)
      {
        _currentPainting = painting;

        updateRect(true);
      }

      return painting;
    }

/// 
    void setActivePainting(string paintingName)
    {
      if (!_paintings)
      {
        return;
      }

      auto painting = _paintings.get(paintingName, null);

      if (!painting)
      {
        return;
      }

      if (!_currentPainting)
      {
        _currentPainting = painting;

        updateRect(true);
      }
      else
      {
        _currentPainting = painting;
      }
    }

/// 
    void enable()
    {
      _disabled = false;
    }

/// 
    void disable()
    {
      _disabled = true;
    }
  }

/// 
  void clean()
  {
    _cleaned = true;
    _isRenderVisible = false;

    if (_components)
    {
      foreach (component; _components)
      {
        component.clean();
      }
    }
    
    _components = [];

    update();
  }

  @property
  {
    final
    {
      /// 
      bool isInputComponent() { return _isInputComponent; }
      ///
      void isInputComponent(bool isInput)
      {
        _isInputComponent = isInput;
      }
/// 
      ulong dataId() { return _dataId; }
/// 
      void dataId(ulong newDataId)
      {
        _dataId = newDataId;
      }
      
/// 
      Painting currentPainting() { return _currentPainting; }

/// 
      package(dvn) bool allowChildren() { return _allowChildren; }

/// 
      size_t id() { return _id; }

/// 
      protected Rectangle clientRect() { return _clientRect; }

/// 
      bool isHidden() { return _isHidden || !_isRenderVisible; }

/// 
      bool hasFocus() { return _focus; }

/// 
      bool isDisabled() { return _disabled; }

/// 
      bool isEnabled() { return !_disabled; }

/// 
      Color fillColor() { return _fillColor; }
/// 
      void fillColor(Color color)
      {
        _fillColor = color;
      }
/// 
      Color borderColor() { return _borderColor; }
/// 
      void borderColor(Color color)
      {
        _borderColor = color;
      }

/// 
      Color topcolor() { return _topColor; }
/// 
      void topColor(Color color)
      {
        _topColor = color;
      }

/// 
      IntVector size() { return _size; }
/// 
      void size(IntVector newSize)
      {
        _size = newSize;

        updateRect(true);
      }

/// 
      int width() { return _size.x; }
/// 
      int height() { return _size.y; }

/// 
      IntVector position() { return _position; }
/// 
      void position(IntVector newPosition)
      {
        _position = newPosition;

        updateRect(true);
      }

/// 
      int x() { return _position.x; }
/// 
      int y() { return _position.y; }

/// 
      Component parent() { return _parent; }

/// 
      Window window() { return _window; }
/// 
      View view() { return _view; }
/// 
      package(dvn) void view(View newView)
      {
        _view = newView;
      }

/// 
      size_t componentsLength() { return _components ? _components.length : 0; }
/// 
      size_t visibleComponentsLength() { return _renderComponents ? _renderComponents.length : 0; }

/// 
      public Component[] children() { return _components ? _components : []; }

/// 
      Anchor anchor() { return _anchor; }

/// 
      void anchor(Anchor anchor)
      {
        _anchor = anchor;

        ILayout parent;
        if (_parent) parent = _parent;
        else if (_view) parent = view;
        else return;

        int x;
        int y;
        final switch (_anchor)
        {
            case Anchor.topLeft:
                x = parent.x;
                y = parent.y;
                break;

            case Anchor.top:
                x = parent.x + (parent.width - this.width) / 2;
                y = parent.y;
                break;

            case Anchor.topRight:
                x = parent.x + parent.width - this.width;
                y = parent.y;
                break;

            case Anchor.left:
                x = parent.x;
                y = parent.y + (parent.height - this.height) / 2;
                break;

            case Anchor.center:
                x = parent.x + (parent.width - this.width) / 2;
                y = parent.y + (parent.height - this.height) / 2;
                break;

            case Anchor.right:
                x = parent.x + parent.width - this.width;
                y = parent.y + (parent.height - this.height) / 2;
                break;

            case Anchor.bottomLeft:
                x = parent.x;
                y = parent.y + parent.height - this.height;
                break;

            case Anchor.bottom:
                x = parent.x + (parent.width - this.width) / 2;
                y = parent.y + parent.height - this.height;
                break;

            case Anchor.bottomRight:
                x = parent.x + parent.width - this.width;
                y = parent.y + parent.height - this.height;
                break;
        }

        this.position = IntVector(x, y);
      }
    }
  }

/// 
  void moveBelow(Component other, int spacing = 0, bool center = false)
  {
      const y = other.y + other.height + spacing;

      int x;
      if (center)
      {
          x = other.x + (other.width - this.width) / 2;
      }
      else
      {
          x = other.x;
      }

      position = IntVector(x, y);
  }

/// 
  void moveAbove(Component other, int spacing = 0, bool center = false)
  {
      const y = other.y - this.height - spacing;

      int x;
      if (center)
      {
          x = other.x + (other.width - this.width) / 2;
      }
      else
      {
          x = other.x;
      }

      position = IntVector(x, y);
  }

/// 
  void moveRightOf(Component other, int spacing = 0, bool center = false)
  {
      const x = other.x + other.width + spacing;

      int y;
      if (center)
      {
          y = other.y + (other.height - this.height) / 2;
      }
      else
      {
          y = other.y;
      }

      position = IntVector(x, y);
  }

/// 
  void moveLeftOf(Component other, int spacing = 0, bool center = false)
  {
      const x = other.x - this.width - spacing;

      int y;
      if (center)
      {
          y = other.y + (other.height - this.height) / 2;
      }
      else
      {
          y = other.y;
      }

      position = IntVector(x, y);
  }


  private bool _forceRender = false;
  private bool _skipForceRender = false;

/// 
  void forceRender()
  {
    _forceRender = true;
    _skipForceRender = false;
  }

/// 
  void skipForceRender()
  {
    _skipForceRender = true;
  }

  
  /// Update the native component - use rect() to determine viewport
  abstract void repaint();

/// 
  bool measureComponentSize(out IntVector size)
  {
    size = _size;
    return false;
  }


  protected:
/// 
  this(Window window, bool allowChildren)
  {
    if (!window)
    {
      throw new ComponentException("Missing window.");
    }

    _allowChildren = allowChildren;
    _window = window;
    _size = IntVector(0,0);
    _position = IntVector(0,0);
    _scrollPosition = IntVector(0,0);
    _isHidden = false;
    _isRenderVisible = false;
    _components = [];
    _renderComponents = [];

    _onMouseButtonDown = [];
    _onMouseButtonUp = [];
    _onMouseMove = [];
    _onTextInput = [];
    _onKeyboardDown = [];
    _onKeyboardUp = [];

    _paintingsAll = [];

    _disabled = false;

    _id = ++_componentId;
  }

  /// Render to screen
  abstract void renderNativeComponent();

  package(dvn)
  {
    void render()
    {
      if (_isInputComponent)
      {
        return;
      }
      if (_forceRender)
      {
        if (!_skipForceRender) renderNativeComponent();
        return;
      }
      if (isHidden)
      {
        return;
      }

      if (_fillColor.a > 0)
      {
        EXT_SetScreenDrawColor(_window.nativeScreen, _fillColor);

        EXT_FillRectangle(_window.nativeScreen, _nativeRenderRectangle);
      }

      if (_currentPainting)
      {
        foreach (painting; _currentPainting.bottomPaintings)
        {
          EXT_SetScreenDrawColor(_window.nativeScreen, painting.color);

          EXT_FillRectangle(_window.nativeScreen, painting.rect);
        }
      }

      renderNativeComponent();

      if (_borderColor.a > 0)
      {
        EXT_SetScreenDrawColor(_window.nativeScreen, _borderColor);

        EXT_DrawRectangle(_window.nativeScreen, _nativeRenderRectangle);
      }

      if (_currentPainting)
      {
        foreach (painting; _currentPainting.topPaintings)
        {
          EXT_SetScreenDrawColor(_window.nativeScreen, painting.color);

          EXT_FillRectangle(_window.nativeScreen, painting.rect);
        }
      }

      if (_topColor.a > 0)
      {
        EXT_SetScreenDrawColor(_window.nativeScreen, _topColor);

        EXT_FillRectangle(_window.nativeScreen, _nativeRenderRectangle);
      }
    }

    void renderChildren()
    {
      pushNativeRect(_window.nativeScreen, _nativeRect);

      if (_renderComponents)
      {
        foreach (component; _renderComponents)
        {
          component.render();
        }
      }

      popNativeRect(_window.nativeScreen);
    }
  }
}
