module zid.view;

import zid.external;
import zid.meta;
import zid.component;
import zid.window;

private size_t _viewId = 0;

public abstract class View
{
  private:
  Component[] _components;
  Window _window;
  size_t _id;
  bool _updateDisabled;

  package(zid) Component[] update()
  {
    if (_updateDisabled) return null;

    Component[] renderComponents = [];

    foreach (component; _components)
    {
      component.update();

      if (!component.isHidden)
      {
        renderComponents ~= component;
      }
    }

    return renderComponents;
  }

  public:
  final
  {
    @property
    {
      size_t id() { return _id; }
      Window window() { return _window; }

      size_t componentsLength() { return _components ? _components.length : 0; }
    }

    void disableUpdate()
    {
      _updateDisabled = true;
    }

    void enableUpdate()
    {
      _updateDisabled = false;

      update();
      _window.update();
    }

    void addComponent(Component component)
    {
      if (!component)
      {
        throw new ArgumentException("Invalid component.");
      }

      if (component.view)
      {
        throw new ComponentException("Component already has a view.");
      }

      _components ~= component;

      component.view = this;
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

      if (component.view is null || component.view.id != _id)
      {
        throw new ComponentException("Component isn't child of this component.");
      }

      component.view = null;

      _components = _components.filter!(c => c.id != component.id).array;

      component.updateRect(false);

      update();
    }

    void clean()
    {
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
  }

  package(zid) void initialize(bool useCache)
  {
    onInitialize(useCache);
  }

  protected:
  this(Window window)
  {
    _window = window;

    _components = [];

    _id = ++_viewId;
  }

  abstract void onInitialize(bool useCache);
}
