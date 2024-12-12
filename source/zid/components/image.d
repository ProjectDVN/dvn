module zid.components.image;

import zid.component;
import zid.external;
import zid.window;

public final class Image : Component
{
  private:
  string _name;
  EXT_SheetRender* _sheetRender;
  string _renderName;
  bool _coverMode;

  public:
  final:
  this(Window window, string name)
  {
    super(window, false);

    _name = name;
    _renderName = "";
    _coverMode = false;

    EXT_SheetRender* sheetRender;
    if (super.window.getSheetEntry(_name, sheetRender))
    {
      _sheetRender = sheetRender;
    }
  }

  this(Window window, EXT_SheetRender* sheetRender)
  {
    super(window, false);

    _sheetRender = sheetRender;
  }

  @property
  {
    string name() { return _name; }
    void name(string newName)
    {
      _name = newName;

      updateRect(true);
    }
  }

  void makeCover()
  {
    _coverMode = true;

    if (super.parent)
    {
      auto parent = super.parent;

      int wp = ((parent.width / 100) * 2);
      int hp = ((parent.height / 100) * 2);

      int x = parent.x-wp;
      int y = parent.y-hp;
      int w = parent.width + (wp * 2);
      int h = parent.height + (hp * 2);

      super.position = IntVector(x, y);
    }
    else
    {
      auto parent = super.window;

      int wp = ((parent.width / 100) * 2);
      int hp = ((parent.height / 100) * 2);

      int x = -wp;
      int y = -hp;
      int w = parent.width + (wp * 2);
      int h = parent.height + (hp * 2);

      super.position = IntVector(x, y);
    }
  }

  void unmakeCover()
  {
    _coverMode = false;

    updateRect(true);
  }

  protected override bool measureComponentSize(out IntVector size)
  {
    if (_coverMode)
    {
      if (super.parent)
      {
        auto parent = super.parent;

        int wp = ((parent.width / 100) * 2);
        int hp = ((parent.height / 100) * 2);

        int x = parent.x-wp;
        int y = parent.y-hp;
        int w = parent.width + (wp * 2);
        int h = parent.height + (hp * 2);

        size = IntVector(w, h);
      }
      else
      {
        auto parent = super.window;

        int wp = ((parent.width / 100) * 2);
        int hp = ((parent.height / 100) * 2);

        int x = -wp;
        int y = -hp;
        int w = parent.width + (wp * 2);
        int h = parent.height + (hp * 2);

        size = IntVector(w, h);
      }

      return true;
    }

    if (!_sheetRender)
    {
      size = super.size;
    }
    else
    {
      size = IntVector(_sheetRender.size.x, _sheetRender.size.y);
    }

    return true;
  }

  void setRawPosition(IntVector position)
  {
    if (!_sheetRender) return;

    _sheetRender.entry.rect.x = cast(int)position.x;
    _sheetRender.entry.rect.y = cast(int)position.y;
  }

  override void repaint()
  {
    auto rect = super.clientRect;
    //rect = Rectangle(rect.x, rect.y, super.width, super.height);

    if (_name == _renderName && _sheetRender !is null)
    {
      _sheetRender.entry.rect.x = cast(int)rect.x;
      _sheetRender.entry.rect.y = cast(int)rect.y;
      if (_coverMode)
      {
        _sheetRender.entry.rect.w = cast(int)rect.w;
        _sheetRender.entry.rect.h = cast(int)rect.h;
      }
      return;
    }
    _renderName = _name;

    EXT_SheetRender* sheetRender;
    if (super.window.getSheetEntry(_name, sheetRender))
    {
      _sheetRender = sheetRender;

      if (_sheetRender !is null)
      {
        _sheetRender.entry.rect.x = cast(int)rect.x;
        _sheetRender.entry.rect.y = cast(int)rect.y;
        
        if (_coverMode)
        {
          _sheetRender.entry.rect.w = cast(int)rect.w;
          _sheetRender.entry.rect.h = cast(int)rect.h;
        }
      }
    }
  }

  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_sheetRender && _sheetRender.texture)
    {
      EXT_RenderCopy(screen, _sheetRender.texture, _sheetRender.entry.textureRect, _sheetRender.entry.rect);
    }
  }
}
