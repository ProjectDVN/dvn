module dvn.window;

import dvn.external;
import dvn.meta;
import dvn.component;
import dvn.events;
import dvn.application;
import dvn.view;
import dvn.sheetcollection;
import dvn.colors;

private size_t _windowId;

public final class Window
{
  private:
  string _title;
  IntVector _size;
  bool _isFullScreen;
  EXT_Window _nativeWindow;
  EXT_Screen _nativeScreen;
  Component[] _components;
  Component[] _renderComponents;
  size_t _id;
  Color _backgroundColor;
  EventCollection _events;
  Application _application;
  void delegate(EXT_Window,EXT_Screen) _preRenderHandler;
  void delegate(EXT_Window,EXT_Screen) _renderHandler;
  void delegate(EXT_Window,EXT_Screen) _clearRenderHandler;
  alias CREATE_VIEW_HANDLER = View delegate();
  CREATE_VIEW_HANDLER[string] _viewCreators;

  View[string] _activeViews;
  View _currentView;
  string _currentViewName;

  bool _isFadingOut;
  bool _isFadingIn;
  bool _isFading;
  Color _fadeColor;
  EXT_Rectangle _nativeRectangle;
  void delegate() _fadedOutHandler;
  void delegate() _fadedInHandler;
  SheetCollection _sheetCollection;
  EXT_Rectangle _overlayRectangle;
  Color _overlayColor;
  bool _useOverlay;

  bool _updateDisabled;

  bool _removed;

  package(dvn) void update()
  {
    if (_updateDisabled) return;

    _renderComponents = [];

    _events.clearEvents();

    if (_currentView)
    {
      auto components = _currentView.update();

      if (components)
      {
        _renderComponents ~= components;
      }
    }

    foreach (component; _components)
    {
      component.update();

      if (!component.isHidden)
      {
        _renderComponents ~= component;
      }
    }
  }

  public:
  final:
  package(dvn) this(Application application, string title, IntVector size, bool isFullScreen, Color backgroundColor)
  {
    _application = application;

    _components = [];
    _renderComponents = [];

    _id = ++_windowId;

    _title = title;
    _size = size;
    _isFullScreen = isFullScreen;
    _backgroundColor = backgroundColor;

    _events = new EventCollection;

    _nativeWindow = EXT_CreateWindow(_title, _size, _isFullScreen);

    _nativeScreen = EXT_CreateScreen(_nativeWindow);

    _sheetCollection = new SheetCollection(this);

    _overlayRectangle = EXT_CreateRectangle(Rectangle(0,0,_size.x, _size.y));
  }

  void remove()
  {
    _removed = true;

    EXT_DestroyWindow(nativeWindow);
    
    application.updateWindows();
  }

  @property
  {
    bool isRemoved()
    {
      return _removed;
    }
  }

  void disableUpdate()
  {
    _updateDisabled = true;
  }

  void enableUpdate()
  {
    _updateDisabled = false;

    update();
  }

  @property
  {
    Color overlayColor() { return _overlayColor; }

    void overlayColor(Color newColor)
    {
      _overlayColor = newColor;
    }

    bool useOverlay() { return _useOverlay; }
    void useOverlay(bool shouldUseOverlay)
    {
      _useOverlay = shouldUseOverlay;
    }

    Application application() { return _application; }

    Color backgroundColor() { return _backgroundColor; }

    void backgroundColor(Color newBackgroundColor)
    {
      _backgroundColor = newBackgroundColor;
    }

    size_t id() { return _id; }

    string title() { return _title; }

    IntVector size() { return _size; }

    bool isFullScreen() { return _isFullScreen; }

    int width() { return _size.x; }
    int height() { return _size.y; }

    package(dvn)
    {
      EventCollection events() { return _events; }
    }

    EXT_Window nativeWindow() { return _nativeWindow; }

    EXT_Screen nativeScreen() { return _nativeScreen; }

    size_t componentsLength() { return _components ? _components.length : 0; }
    size_t visibleComponentsLength() { return _renderComponents ? _renderComponents.length : 0; }
  }

  void setCustomPreRender(void delegate(EXT_Window,EXT_Screen) preRenderHandler)
  {
    _preRenderHandler = preRenderHandler;
  }

  package(dvn) void executePreRender()
  {
    if (_preRenderHandler)
    {
      _preRenderHandler(_nativeWindow, _nativeScreen);
    }
  }

  void setCustomRender(void delegate(EXT_Window,EXT_Screen) renderHandler, void delegate(EXT_Window,EXT_Screen) clearRenderHandler)
  {
    _renderHandler = renderHandler;
    _clearRenderHandler = clearRenderHandler;
  }

  void clearCustomRender()
  {
    _renderHandler = null;

    if (_clearRenderHandler)
    {
      auto handler = _clearRenderHandler;
      _clearRenderHandler = null;
      handler(_nativeWindow, _nativeScreen);
    }
  }

  void addSheet(string name, string path, IntVector columnSize, int columnCount)
  {
    _sheetCollection.addSheet(name, path, columnSize, columnCount);
  }

  EXT_Sheet getSheet(string name)
  {
    return _sheetCollection.getSheet(name);
  }

  void addSheetEntry(string name, string sheetName, int row, int col)
  {
    _sheetCollection.addSheetEntry(name, sheetName, row, col);
  }

  bool getSheetEntry(string entryName, out EXT_SheetRender* sheetRender)
  {
    return _sheetCollection.getSheetEntry(entryName, sheetRender);
  }

  bool getSheetEntry(string sheetName, int row, int col, out EXT_SheetRender* sheetRender)
  {
    return _sheetCollection.getSheetEntry(sheetName, row, col, sheetRender);
  }

  bool isCurrentView(T : View)(T view)
  {
    return _currentView && view && _currentView.id == view.id;
  }

  void addView(T : View)(string name)
  {
    auto window = this;

    _viewCreators[name] = { return cast(View)new T(window); };
  }

  T getActiveView(T : View)(string name)
  {
    if (!_activeViews) return T.init;

    auto view = cast(T)_activeViews.get(name, null);

    return view;
  }

  void changeView(string name, bool saveCurrentView = false, void delegate(View) onInitialized = null)
  {
    if (!saveCurrentView)
    {
      if (_currentView)
      {
        _currentView.clean();

        if (_activeViews && _currentViewName && _currentViewName.length)
        {
          _activeViews.remove(_currentViewName);
        }
      }
    }

    if (!_viewCreators) return;
    
    auto view = _activeViews.get(name, null);

    if (!view)
    {
      auto createViewHandler = _viewCreators.get(name, null);

      if (!createViewHandler) return;

      view = createViewHandler();

      _activeViews[name] = view;

      view.initialize(false);
    }
    else
    {
      view.initialize(true);
    }

    if (onInitialized)
    {
      onInitialized(view);
    }

    _currentViewName = name;
    _currentView = view;

    update();
  }

  void fadeToView(string name, Color fadeColor, bool saveCurrentView = false, void delegate(View) onInitialized = null)
  {
    fadeOut(fadeColor,
    {
      changeView(name, saveCurrentView, onInitialized);
      fadeIn();
    });
  }

  void fadeOut(Color fadeColor, void delegate() fadedOutHandler = null)
  {
    if (_isFadingOut) return;

    _events.clearEvents();
    _fadedOutHandler = fadedOutHandler;
    _isFadingIn = false;
    _isFadingOut = true;
    _isFading = true;
    _fadeColor = Color(fadeColor.r, fadeColor.g, fadeColor.b, 0);
    _nativeRectangle = EXT_CreateRectangle(Rectangle(0,0,_size.x, _size.y));
  }

  void fadeIn(void delegate() fadedInHandler = null)
  {
    if (_isFadingIn) return;

    _events.clearEvents();
    _fadedInHandler =
    {
      if (fadedInHandler) fadedInHandler();

      update();
    };
    _isFadingOut = false;
    _isFadingIn = true;
    _isFading = true;
  }

  void addComponent(Component component)
  {
    if (!component)
    {
      throw new ArgumentException("Invalid component.");
    }

    _components ~= component;

    component.updateRect(false);

    update();
  }

  void removeComponent(Component component)
  {
    if (!component)
    {
      throw new ArgumentException("Invalid component.");
    }

    import std.algorithm : filter;
    import std.array : array;

    if (component.window is null || component.window.id != _id)
    {
      throw new ComponentException("Component isn't child of this component.");
    }

    _components = _components.filter!(c => c.id != component.id).array;

    component.updateRect(false);

    update();
  }

  private size_t _lastFadeTime;

  void render()
  {
    EXT_SetRenderRectangle(_nativeScreen, null);

    EXT_SetScreenDrawColor(_nativeScreen, _backgroundColor);

    EXT_ClearScreen(_nativeScreen);

    if (_renderHandler)
    {
      _renderHandler(_nativeWindow, _nativeScreen);
    }

    if (_useOverlay && _overlayRectangle)
    {
      EXT_SetScreenDrawColor(_nativeScreen, _overlayColor); // set overlay color

      EXT_FillRectangle(_nativeScreen, _overlayRectangle); // draw overlay

      EXT_SetScreenDrawColor(_nativeScreen, _backgroundColor); // reset
    }

    if (_renderComponents)
    {
      foreach (component; _renderComponents)
      {
        if (!component.allowChildren)
        {
          EXT_SetRenderRectangle(_nativeScreen, null);
        }

        component.render();
      }
    }

    if (_isFading)
    {
      EXT_SetRenderRectangle(_nativeScreen, null);

      if (_isFadingOut)
      {
        bool canUpdateFade;
        uint current_time = 0;
        if (_fadeColor.a < 255)
        {
          current_time = EXT_GetTicks();

          if (_lastFadeTime > 0)
          {
            auto  delta_time = current_time - _lastFadeTime;

            canUpdateFade = delta_time > 24;
          }
          else
          {
            _lastFadeTime = current_time;
          }
        }
        else
        {
          canUpdateFade = false;
        }

        if (canUpdateFade)
        {
          _lastFadeTime = current_time;

          int a = cast(int)_fadeColor.a;

          a += 12;

          if (a >= 255)
          {
            a = 255;

            if (_fadedOutHandler) _fadedOutHandler();

            _fadedOutHandler = null;
          }

          _fadeColor.a = cast(ubyte)a;
        }
      }
      else if (_isFadingIn)
      {
        bool canUpdateFade;
        uint current_time = 0;
        if (_fadeColor.a > 0)
        {
          current_time = EXT_GetTicks();

          if (_lastFadeTime > 0)
          {
            auto  delta_time = current_time - _lastFadeTime;

            canUpdateFade = delta_time > 40;
          }
          else
          {
            _lastFadeTime = current_time;
          }
        }
        else
        {
          canUpdateFade = false;
        }

        if (canUpdateFade)
        {
          _lastFadeTime = current_time;

          int a = cast(int)_fadeColor.a;

          a -= 12;

          if (a <= 0)
          {
            a = 0;

            if (_fadedInHandler) _fadedInHandler();

            _fadedInHandler = null;
            _fadeColor = Color(0,0,0,0);
            _nativeRectangle = null;
          }
          else
          {
            _fadeColor.a = cast(ubyte)a;
          }
        }
      }

      if (_nativeRectangle)
      {
        EXT_SetScreenDrawColor(_nativeScreen, _fadeColor);

        EXT_FillRectangle(_nativeScreen, _nativeRectangle);
      }
    }

    EXT_PresentScreen(_nativeScreen);
  }
}
