/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.panel;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;
import dvn.events;
import dvn.components.scrollbar;

/// 
public class Panel : Component
{
  private:
  IntVector _scrollPosition;
  IntVector _scrollMargin;

  public:
/// 
  protected override void renderNativeComponent()
  {
    renderChildren();
  }

  final:
  package(dvn) ScrollBar scrollBar;

/// 
  this(Window window)
  {
    super(window, true);
  }

/// 
  void makeScrollableWithWheel()
  {
    onMouseWheel(new MouseWheelEventHandler((a,p) {
      if (!scrollBar || (scrollBar.isVertical ? (_scrollMargin.y <= 0) : (_scrollMargin.x <= 0)) || a == 0) return true;

      bool hover = super.intersectsWith(p);

      if (!hover) return true;
      
      bool decrement = a < 0;
      if (a < 0) a = -a;

      if (decrement)
      {
        foreach (_; 0 .. a)
        {
          scrollBar.scrollIncrement();
        }
      }
      else
      {
        foreach (_; 0 .. a)
        {
          scrollBar.scrollDecrement();
        }
      }

      return false;
    }));

    if (scrollBar)
    {
      scrollBar.makeScrollableWithWheel();
    }
  }

  @property
  {
/// 
    IntVector scrollMargin() { return _scrollMargin; }
/// 
    void scrollMargin(IntVector margin)
    {
      _scrollMargin = margin;
    }

/// 
    IntVector scrollPosition() { return _scrollPosition; }

/// 
    int minScrollVertical()
    {
      return 0;
    }

    import std.algorithm : max;

/// 
    int maxScrollVertical()
    {
      int bottom = 0;

      foreach (child; super.children)
      {
        auto childBottom = child.y + child.height;
        bottom = max(bottom, childBottom);
      }

      int raw = bottom - super.height + _scrollMargin.y;
      return max(0, raw);
    }

/// 
    int minScrollHorizontal()
    {
      return 0;
    }

/// 
    int maxScrollHorizontal()
    {
      int right = 0;

      foreach (child; super.children)
      {
        auto childRight = child.x + child.width;
        right = max(right, childRight);
      }

      int raw = right - super.width + _scrollMargin.x;
      return max(0, raw);
    }
  }

/// 
  void scroll(int x, int y)
  {
    _scrollPosition = IntVector(_scrollPosition.x + x, _scrollPosition.y + y);

    setScrollPosition(_scrollPosition);
  }

/// 
  void scrollTo(int x, int y)
  {
    _scrollPosition = IntVector(x,y);

    setScrollPosition(_scrollPosition);
  }

/// 
  void scrollX(int x)
  {
    scroll(x, 0);
  }

/// 
  void scrollY(int y)
  {
    scroll(0, y);
  }

/// 
  override void repaint()
  {
  }
}
