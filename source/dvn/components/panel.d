module dvn.components.panel;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;

public final class Panel : Component
{
  private:
  IntVector _scrollPosition;
  IntVector _scrollMargin;

  public:
  final:
  this(Window window)
  {
    super(window, true);
  }

  @property
  {
    IntVector scrollMargin() { return _scrollMargin; }
    void scrollMargin(IntVector margin)
    {
      _scrollMargin = margin;
    }

    IntVector scrollPosition() { return _scrollPosition; }

    int minScrollVertical()
    {
      return 0;
    }

    int maxScrollVertical()
    {
      int bottom = 0;

      foreach (child; super.children)
      {
        auto childBottom = child.y + child.height;

        if (childBottom > bottom)
        {
          bottom = childBottom;
        }
      }

      return (bottom - super.height) + _scrollMargin.y;
    }

    int minScrollHorizontal()
    {
      return 0;
    }

    int maxScrollHorizontal()
    {
      int right = 0;

      foreach (child; super.children)
      {
        auto childRight = child.x + child.width;

        if (childRight > right)
        {
          right = childRight;
        }
      }

      return (right - super.width) + _scrollMargin.x;
    }
  }

  void scroll(int x, int y)
  {
    _scrollPosition = IntVector(_scrollPosition.x + x, _scrollPosition.y + y);

    setScrollPosition(_scrollPosition);
  }

  void scrollTo(int x, int y)
  {
    _scrollPosition = IntVector(x,y);

    setScrollPosition(_scrollPosition);
  }

  void scrollX(int x)
  {
    scroll(x, 0);
  }

  void scrollY(int y)
  {
    scroll(0, y);
  }

  override void repaint()
  {
  }

  override void renderNativeComponent()
  {
    renderChildren();
  }
}
