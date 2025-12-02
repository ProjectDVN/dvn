/**
* Copyright (c) 2025 Project DVN
*/
module dvn.application;

import dvn.external;
import dvn.meta;
import dvn.fonts;
import dvn.colors;
import dvn.window;
import dvn.delayedtask;
import dvn.events;

import std.concurrency : spawn, thisTid, send, receive, receiveTimeout;
public import std.concurrency : Tid;
import core.thread : dur;

import core.stdc.stdlib : exit;

mixin CreateCustomException!"ApplicationException";

//shared static this()
void initializeExternalApplicationState()
{
  EXT_Initialize();

  import dvn.texttools;
  initializeTextTools();
}

private alias Action = void delegate();

private static void spawnedFunc(Tid uiTid)
{
  Action action = null;

  receive((shared(Action) a){
    action = cast(Action)a;
  });

  if (action)
  {
    action();
  }

  Action message = {
    EXT_EndWait();
  };

  send(uiTid, cast(shared)message);
}

private __gshared Application _app;

public Application getApplication()
{
  return _app;
}

public final class Application
{
  private:
  FontCollection _fonts;
  bool _running;
  Tid _uiTid;
  int _fps;
  Color _defaultWindowColor;
  Window[] _windows;
  bool _allowWASDMovement;
  size_t _concurrencyLevel;
  size_t _messageLevel;
  bool _isDebugMode;

  public:
  final:
  this(int defaultFps = 60)
  {
    this(getColorByName("white"), defaultFps);
  }

  this(Color defaultWindowColor,int defaultFps = 60)
  {
    if (defaultFps <= 0 || defaultFps > 240)
    {
      throw new ApplicationException("Invalid default fps.");
    }

    _defaultWindowColor = defaultWindowColor;
    _fonts = new FontCollection;
    _fps = defaultFps;
    _windows = [];
    _concurrencyLevel = 4;
    _messageLevel = 42;

    if (!_app)
    {
      _app = this;
    }
  }

  @property
  {
    Window[] windows() { return _windows; }

    size_t messageLevel() { return _messageLevel; }
    void messageLevel(size_t newMessageLevel)
    {
      _messageLevel = newMessageLevel;
    }
    
    size_t concurrencyLevel() { return _concurrencyLevel; }
    void concurrencyLevel(size_t newConcurrencyLevel)
    {
      if (newConcurrencyLevel == 0)
      {
        throw new ApplicationException("The concurrency level must be at least 1. It defaults to 4.");
      }

      _concurrencyLevel = newConcurrencyLevel;
    }
    FontCollection fonts() { return _fonts; }
    bool running() { return _running; }
    bool isUIThread() { return _running && _uiTid == thisTid; }
    Color defaultWindowColor() { return _defaultWindowColor; }

    int fps() { return _fps; }
    void fps(int newFps)
    {
      if (newFps <= 0 || newFps > 240)
      {
        throw new ApplicationException("Invalid fps.");
      }

      _fps = newFps;
    }

    bool allowWASDMovement() { return _allowWASDMovement; }
    void allowWASDMovement(bool shouldAllow)
    {
      _allowWASDMovement = shouldAllow;

      if (_allowWASDMovement)
      {
        EXT_AllowWASDMovement();
      }
      else
      {
        EXT_DisallowWASDMovement();
      }
    }

    bool isDebugMode() { return _isDebugMode; }
    void isDebugMode(bool debugMode)
    {
      _isDebugMode = debugMode;
    }
  }

  Window createWindow(string title, IntVector size, bool isFullScreen)
  {
    auto window = new Window(this, title, size, isFullScreen, _defaultWindowColor);

    _windows ~= window;

    return window;
  }

  void updateWindows()
  {
    Window[] newWindows = [];

    foreach (w; _windows)
    {
      if (!w.isRemoved)
      {
        newWindows ~= w;
      }
    }

    _windows = newWindows;
  }

  Window getRealWindow()
  {
    foreach (window; _windows)
    {
      if (!window.isDebugMode)
      {
        return window;
      }
    }

    return _windows[0];
  }

  void enableKeyboardState()
  {
    EXT_EnableKeyboardState();
  }

  void disableKeyboardState()
  {
    EXT_DisableKeyboardState();
  }

  void sleepCurrentThread(uint ms)
  {
    if (ms == 0) return;

    if (isUIThread)
    {
      throw new ApplicationException("Cannot sleep on the UI thread.");
    }

    import core.thread : Thread;

    Thread.sleep(dur!("msecs")(ms));
  }

  bool beginLoad(Action loadingFn, out Tid tid)
  {
    tid = _uiTid;

    if (!loadingFn) return false;

    EXT_BeginWait();

    tid = spawn(&spawnedFunc, _uiTid);

    send(tid, cast(shared)loadingFn);

    return true;
  }

  void sendMessage(Action action)
  {
    send(_uiTid, cast(shared)action);
  }

  private void receiveMessages()
  {
    foreach (_; 0 .. _concurrencyLevel)
    {
      receiveTimeout(
        dur!("nsecs")(-1),
        (shared(Action) a) {
          auto action = cast(Action)a;

          if (action)
          {
            action();
          }
        });
    }
  }

  void start(bool allowTextInput = true)
  {
    _uiTid = thisTid;
    _running = true;

    foreach (window; _windows)
    {
      window.update();
    }

    uint lastTicks = EXT_GetTicksRaw();

    //import std.stdio : writefln;

    if (!allowTextInput)
    {
		  EXT_StopTextInput();
    }

    while (_running && _windows && _windows.length)
    {
      EXT_PreAplicationLoop(_fps);
      DvnEvents.getEvents().preFrameLoop(_windows);

      if (!EXT_ProcessEvents(_windows))
      {
        stop();
        break;
      }

      auto ticks = EXT_GetTicks();

      if ((ticks - lastTicks) >= _messageLevel)
      {
        //writefln("time: %s", (ticks - lastTicks));
        lastTicks = ticks;

        receiveMessages();
        handleDelayedTasks();
      }

      EXT_InitializeKeyboardState();

      foreach (window; _windows)
      {
        window.executePreRender();
      }

      DvnEvents.getEvents().preRenderFrameLoop(_windows);

      foreach (window; _windows)
      {
        window.render();
      }

      DvnEvents.getEvents().postRenderFrameLoop(_windows);

      EXT_PostApplicationLoop(_fps);

      DvnEvents.getEvents().postFrameLoop(_windows);
    }
  }

  void stop()
  {
    _running = false;
    exit(0);
  }
}
