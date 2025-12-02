/**
* Copyright (c) 2025 Project DVN
*/
module dvn.effects;

import std.conv : to;

import dvn.events;
import dvn.window;
import dvn.component;
import dvn.external;
import dvn.application;
import dvn.views.consoleview;
import dvn.components;

public abstract class Effect
{
  private:
  string _name;

  public:
  this(string name)
  {
    _name = name;
  }

  @property
  {
    string name() { return _name; }
  }

  abstract void handle(string[] values);
}

private Effect[string] _effectHub;

void registerEffect(Effect effect)
{
  _effectHub[effect.name] = effect;
}

Effect getEffect(string name)
{
  if (!_effectHub) return null;

  return _effectHub.get(name, null);
}

public final class ScreenShakeEffect : Effect
{
  private size_t _windowId;
  
  public class ScreenEffectComponent
  {
    public:
    IntVector originalPosition;
    Component component;
  }

  private ScreenEffectComponent[] components;
  private bool isActive;
  private int lastMS;
  private int counter;
  private int duration;
  private int intensity;

  public:
  this()
  {
    super("ScreenShake");

    lastMS = 0;
    int delay = 100;
    bool lastWasNegative = false;

    class ScreenEvents : DvnEvents
    {
      override void preRenderContent(Window window)
      {
        if (!isActive)
        {
          return;
        }
        if (window.id == _windowId)
        {
          auto ms = EXT_GetTicks();

          if (lastMS == 0 || (ms - lastMS) > delay)
          {
            lastMS = ms;

            foreach (component; components)
            {
              IntVector position;
              if (lastWasNegative)
              {
                position = IntVector(component.component.x + intensity, component.component.y);
                lastWasNegative = false;
              }
              else
              {
                position = IntVector(component.component.x - intensity, component.component.y);
                lastWasNegative = true;
              }

              component.component.position = position;
            }

            duration--;
            if (duration <= 0)
            {
              foreach (component; components)
              {
                component.component.position = component.originalPosition;
              }

              isActive = false;
            }
          }
        }
      }
    }

    DvnEvents.setEvents(new ScreenEvents);
  }

  override void handle(string[] values)
  {
    auto window = getApplication().getRealWindow();
    if (!window) return;
    _windowId = window.id;
    auto view = window.getCurrentActiveView();
    if (!view) return;
    auto components = view.getComponents();

    this.components = [];

    foreach (component; components)
    {
      auto sec = new ScreenEffectComponent;
      sec.originalPosition = component.position;
      sec.component = component;
      this.components ~= sec;
    }

    counter = 20;
    lastMS = 0;
    isActive = true;
    
    duration = values.length > 0 ? to!int(values[0]) : 20;
    intensity = values.length > 1 ? to!int(values[1]) : 3;
  }
}

public final class BackgroundMoveZoomEffect : Effect
{
  private:
  size_t _windowId;

  Image _background;

  bool isActive;
  bool hasCapturedInitial;

  IntVector startPosition;
  double startScale;

  int durationMs;
  int elapsedMs;
  int lastMS;

  int movePixels;
  string direction;
  double targetScale;
  bool snap;

  public:
  this()
  {
    super("BackgroundMoveZoom");

    class ScreenEvents : DvnEvents
    {
      override void renderGameViewBackground(Image background)
      {
        if (background is null)
        {
          return;
        }

        _background = background;
        hasCapturedInitial = false;
      }

      override void preRenderContent(Window window)
      {
        if (!isActive)
        {
          return;
        }

        if (!window || window.id != _windowId)
        {
          return;
        }

        if (_background is null)
        {
          return;
        }

        auto ms = EXT_GetTicks();
        if (lastMS == 0)
        {
          lastMS = ms;
        }

        auto delta = cast(int)(ms - lastMS);
        lastMS = ms;
        elapsedMs += delta;

        if (!hasCapturedInitial)
        {
          startPosition = _background.position;
          startScale = _background.scale;
          hasCapturedInitial = true;
        }

        double t = 0;
        if (durationMs > 0)
        {
          t = cast(double)elapsedMs / cast(double)durationMs;
          if (t < 0) t = 0;
          else if (t > 1) t = 1;
        }

        int totalDx = 0;
        int totalDy = 0;

        switch (direction)
        {
          case "LR":
            totalDx = movePixels;
            break;
          case "RL":
            totalDx = -movePixels;
            break;
          case "UD":
            totalDy = movePixels;
            break;
          case "DU":
            totalDy = -movePixels;
            break;
          default:
            break;
        }

        int dx = cast(int)(totalDx * t);
        int dy = cast(int)(totalDy * t);

        _background.position = IntVector(
          startPosition.x + dx,
          startPosition.y + dy
        );

        double s = startScale + (targetScale - startScale) * t;
        _background.scale = s;

        if (elapsedMs >= durationMs)
        {
          if (snap)
          {
            _background.position = startPosition;
            _background.scale = startScale;
          }

          isActive = false;
          hasCapturedInitial = false;
          lastMS = 0;
          elapsedMs = 0;
          _background = null;
        }
      }
    }

    DvnEvents.setEvents(new ScreenEvents);
  }

  override void handle(string[] values)
  {
    auto window = getApplication().getRealWindow();
    if (!window)
    {
      return;
    }
    _windowId = window.id;

    import std.conv : to;

    isActive = false;
    hasCapturedInitial = false;
    lastMS = 0;
    elapsedMs = 0;

    durationMs = values.length > 0 ? to!int(values[0]) : 1000;

    movePixels = values.length > 1 ? to!int(values[1]) : 30;

    if (values.length > 2)
    {
      string dir = values[2];

      switch (dir)
      {
        case "LR", "RL", "UD", "DU":
          direction = dir;
          break;
        default:
          direction = "LR";
          break;
      }
    }
    else
    {
      direction = "LR";
    }

    targetScale = values.length > 3 ? to!double(values[3]) : 1.05;

    snap = values.length > 4 ? to!bool(values[4]) : true;

    isActive = true;
  }
}



void initializeStandardEffects()
{
  registerEffect(new ScreenShakeEffect);
  registerEffect(new BackgroundMoveZoomEffect);
}