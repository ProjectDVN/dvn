module dvn.effects;

import std.conv : to;

import dvn.events;
import dvn.window;
import dvn.component;
import dvn.external;
import dvn.application;
import dvn.views.consoleview;

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

void initializeStandardEffects()
{
  registerEffect(new ScreenShakeEffect);
}