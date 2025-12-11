/**
* Copyright (c) 2025 Project DVN
*/
module dvn.window;

import dvn.external;
import dvn.meta;
import dvn.component;
import dvn.events;
import dvn.application;
import dvn.view;
import dvn.sheetcollection;
import dvn.colors;
import dvn.views.consoleview;
import dvn.ui;

private size_t _windowId;

/// 
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
  Panel _debugPanel;
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
  bool _debugMode;

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

    _events.reverseEventOrder();
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

/// 
  void enableDebugPanel()
  {
    _debugPanel = new Panel(this);
    addComponent(_debugPanel);
    _debugPanel.size = IntVector(width / 4, height / 4);
    _debugPanel.position = IntVector(4, 4);
    _debugPanel.fillColor = "000".getColorByHex.changeAlpha(150);
  }

/// 
  bool toggleDebugPanel()
  {
    if (_debugPanel)
    {
      disableDebugPanel();
      return false;
    }
    else
    {
      enableDebugPanel();
      return true;
    }
  }

  private Label[string] _debugLabels;
  private Label _lastLabel;

/// 
  void addDebugInformation(string key, string value)
  {
    if (!_debugPanel) return;

    import dvn.gamesettings : getGlobalSettings;

    import std.conv : to;

    auto settings = getGlobalSettings();

    Label label;
    if (_debugLabels)
    {
      label = _debugLabels.get(key, null);
    }

    if (!label)
    {
      label = new Label(this);
      _debugPanel.addComponent(label);
      _debugLabels[key] = label;
      label.fontName = settings.defaultFont;
      label.fontSize = 14;
      label.color = "fff".getColorByHex;
      label.shadow = true;
      label.isLink = false;
      if (_lastLabel)
      {
        label.moveBelow(_lastLabel, 4);
      }
      else
      {
        label.position = IntVector(4, 4);
      }
      _lastLabel = label;
    }
    
    label.text = (key ~ ": " ~ value).to!dstring;
    label.updateRect();
    label.show();
  }

/// 
  void disableDebugPanel()
  {
    if (_debugPanel)
    {
      removeComponent(_debugPanel);
      _debugPanel = null;
      _lastLabel = null;
      _debugLabels.clear();
    }
  }
/// 
  void giveFocus()
  {
    version (Windows)
    {
        import dvn.external;
        // auto flags = EXT_GetWindowFlags(window.nativeWindow);

        // bool hasKeyboardFocus = (flags & EXT_WINDOW_INPUT_FOCUS) != 0;
        
        // if (!hasKeyboardFocus)
        {
            EXT_RaiseWindow(_nativeWindow);
            EXT_SetWindowInputFocus(_nativeWindow);
        }
    }
  }
/// 
  void remove()
  {
    _removed = true;

    EXT_DestroyWindow(nativeWindow);
    
    application.updateWindows();
  }

/// 
  bool isNativeWindow(EXT_Window window)
  {
    return _nativeWindow == window;
  }

  @property
  {
/// 
    bool isDebugMode() { return _debugMode; }
/// 
    void isDebugMode(bool debugMode)
    {
      _debugMode = debugMode;
    }
/// 
    bool isRemoved()
    {
      return _removed;
    }

/// 
    bool isActive()
    {
        auto flags = EXT_GetWindowFlags(_nativeWindow);

        uint mask =
            EXT_WindowFlags.SDL_WINDOW_INPUT_FOCUS |
            EXT_WindowFlags.SDL_WINDOW_MOUSE_FOCUS;

        bool hasAnyFocus = (flags & mask) != 0;
        bool notMinimized = (flags & EXT_WindowFlags.SDL_WINDOW_MINIMIZED) == 0;

        return hasAnyFocus && notMinimized;
    }
  }

/// 
  void disableUpdate()
  {
    _updateDisabled = true;
  }

/// 
  void enableUpdate()
  {
    _updateDisabled = false;

    update();
  }

  @property
  {
/// 
    Color overlayColor() { return _overlayColor; }

/// 
    void overlayColor(Color newColor)
    {
      _overlayColor = newColor;
    }

/// 
    bool useOverlay() { return _useOverlay; }
/// 
    void useOverlay(bool shouldUseOverlay)
    {
      _useOverlay = shouldUseOverlay;
    }

/// 
    Application application() { return _application; }

/// 
    Color backgroundColor() { return _backgroundColor; }

/// 
    void backgroundColor(Color newBackgroundColor)
    {
      _backgroundColor = newBackgroundColor;
    }

/// 
    size_t id() { return _id; }

/// 
    string title() { return _title; }

/// 
    IntVector size() { return _size; }

/// 
    bool isFullScreen() { return _isFullScreen; }

/// 
    int width() { return _size.x; }
/// 
    int height() { return _size.y; }

    package(dvn)
    {
      EventCollection events() { return _events; }
    }

/// 
    EXT_Window nativeWindow() { return _nativeWindow; }

/// 
    EXT_Screen nativeScreen() { return _nativeScreen; }

/// 
    size_t componentsLength() { return _components ? _components.length : 0; }
/// 
    size_t visibleComponentsLength() { return _renderComponents ? _renderComponents.length : 0; }
  }

/// 
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

/// 
  void setCustomRender(void delegate(EXT_Window,EXT_Screen) renderHandler, void delegate(EXT_Window,EXT_Screen) clearRenderHandler)
  {
    _renderHandler = renderHandler;
    _clearRenderHandler = clearRenderHandler;
  }

/// 
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

/// 
  void addSheet(string name, string path, IntVector columnSize, int columnCount)
  {
    _sheetCollection.addSheet(name, path, columnSize, columnCount);
  }

/// 
  void addSheetBuffer(string name, ubyte[] buffer, IntVector columnSize, int columnCount)
  {
    _sheetCollection.addSheetBuffer(name, buffer, columnSize, columnCount);
  }

/// 
  EXT_Sheet getSheet(string name)
  {
    return _sheetCollection.getSheet(name);
  }

/// 
  void addSheetEntry(string name, string sheetName, int row, int col)
  {
    _sheetCollection.addSheetEntry(name, sheetName, row, col);
  }

/// 
  bool getSheetEntry(string entryName, out EXT_SheetRender* sheetRender)
  {
    return _sheetCollection.getSheetEntry(entryName, sheetRender);
  }

/// 
  bool getSheetEntry(string sheetName, int row, int col, out EXT_SheetRender* sheetRender)
  {
    return _sheetCollection.getSheetEntry(sheetName, row, col, sheetRender);
  }
  
/// 
  bool hasSheetEntry(string entryName)
  {
    return _sheetCollection.hasSheetEntry(entryName);
  }

/// 
  bool isCurrentView(T : View)(T view)
  {
    return _currentView && view && _currentView.id == view.id;
  }

/// 
  void addView(T : View)(string name)
  {
    auto window = this;

    _viewCreators[name] = { return cast(View)new T(window); };
  }

/// 
  T getActiveView(T : View)(string name)
  {
    if (!_activeViews) return T.init;

    auto view = cast(T)_activeViews.get(name, null);

    return view;
  }

/// 
  View getCurrentActiveView()
  {
    if (!_activeViews || !_activeViews.length) return null;

    return _activeViews.values[0];
  }

/// 
  void changeView(string name, bool saveCurrentView = false, void delegate(View) onInitialized = null)
  {
    logInfo("Changing view: %s", name);

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

    DvnEvents.getEvents().onViewChange(_currentView, view, _currentViewName, name);

    if (!view)
    {
      auto createViewHandler = _viewCreators.get(name, null);

      if (!createViewHandler) return;

      view = createViewHandler();

      _activeViews[name] = view;

      _application.audio.stopFade();

      view.initialize(false);
    }
    else
    {
      _application.audio.stopFade();

      view.initialize(true);
    }

    if (onInitialized)
    {
      onInitialized(view);
    }

    _currentViewName = name;
    _currentView = view;

    update();

    EXT_ResetCursor();

    logInfo("Changed view: %s", name);
  }

/// 
  void refreshCurrentView(void delegate(View) onRefreshed)
  {
    auto newView = _currentViewName;

    fadeToView("EmptyView", getColorByName("black"), false, (v) {
      runDelayedTask(1000, {
        fadeToView(newView, getColorByName("black"), false, (view) {
          if (onRefreshed)
          {
            onRefreshed(view);
          }
        });
      });
    });
  }

/// 
  void fadeToView(string name, Color fadeColor, bool saveCurrentView = false, void delegate(View) onInitialized = null)
  {
    fadeOut(fadeColor,
    {
      changeView(name, saveCurrentView, onInitialized);

      fadeIn();
    });
  }

/// 
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
    _lastFadeTime = 0;
  }

/// 
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
    _lastFadeTime = 0;
  }

/// 
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

/// 
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
  private size_t _lastFpsUpdate;

/// 
  void render()
  {
    import dvn.gamesettings : getGlobalSettings;
    auto settings = getGlobalSettings();
    
    EXT_SetRenderRectangle(_nativeScreen, null);

    EXT_SetScreenDrawColor(_nativeScreen, _backgroundColor);

    EXT_ClearScreen(_nativeScreen);

    DvnEvents.getEvents().preRenderContent(this);

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

    if (_debugPanel)
    {
      auto ticks = EXT_GetTicks();
      if ((ticks - _lastFpsUpdate) > 1000)
      {
        import std.conv : to;
        addDebugInformation("FPS", EXT_GetFps().to!string);
        _lastFpsUpdate = ticks;
      }
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
    
    void delegate() tempFadedOutHandler;

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

            canUpdateFade = delta_time > (settings.windowFadeTime ? cast(uint)settings.windowFadeTime : 24);
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

            tempFadedOutHandler = _fadedOutHandler;

            _fadedOutHandler = null;
            _lastFadeTime = 0;
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

            canUpdateFade = delta_time > (settings.windowFadeTime ? cast(uint)settings.windowFadeTime : 24);
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
            _isFadingIn = false;
            _isFading = false;
            _lastFadeTime = 0;
          }
          else
          {
            _fadeColor.a = cast(ubyte)a;
          }
        }
      }

      if (_isFading && _nativeRectangle)
      {
        EXT_SetScreenDrawColor(_nativeScreen, _fadeColor);

        EXT_FillRectangle(_nativeScreen, _nativeRectangle);
      }

      if (tempFadedOutHandler)
      {
        tempFadedOutHandler();
      }
    }

    DvnEvents.getEvents().postRenderContent(this);

    EXT_PresentScreen(_nativeScreen);
  }
}
