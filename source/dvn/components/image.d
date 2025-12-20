/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.image;

import dvn.component;
import dvn.external;
import dvn.window;

/// 
public final class Image : Component
{
  private:
  string _name;
  EXT_SheetRender* _sheetRender;
  string _renderName;
  bool _coverMode;
  int _opacity;
  EXT_Rectangle _rect;
  EXT_Rectangle _originalRect;
  double _scale;

  bool _isFilePath;
  EXT_RectangleNative* _rect1;
  EXT_RectangleNative* _rect2;
  EXT_Surface _temp;
  EXT_Texture _texture;
  bool _cleaned;

  bool hasOriginalRect;

  public:
  final:
/// 
  this(Window window, string name, bool isFilePath = false)
  {
    super(window, false);

    _name = name;
    _renderName = "";
    _coverMode = false;
    _isFilePath = isFilePath;

    if (_isFilePath)
    {
      import std.string : toStringz;

      auto path = name;
      _temp = EXT_IMG_Load(path.toStringz);
      _texture = EXT_CreateTextureFromSurface(window.nativeScreen, _temp);
      auto originalSize = EXT_QueryTextureSize(_texture);

      _rect1 = new EXT_RectangleNative;
      _rect1.x = 0;
      _rect1.y = 0;
      _rect1.w = originalSize.x;
      _rect1.h = originalSize.y;
    }
    else
    {
      EXT_SheetRender* sheetRender;
      if (super.window.getSheetEntry(_name, sheetRender))
      {
        _sheetRender = sheetRender;
      }
    }

    _rect = EXT_CreateRectangle(Rectangle(0,0,0,0));
    _originalRect = _rect;
    
    opacity = 255;
  }

/// 
  this(Window window, EXT_SheetRender* sheetRender)
  {
    super(window, false);

    _sheetRender = sheetRender;
  }

  @property
  {
    /// 
    int fileWidth() { return _rect1.w; }
    /// 
    int fileHeight() { return _rect1.h; }
    /// 
    bool isFilePath() { return _isFilePath; }
    /// 
    double scale() { return _scale; }
    /// 
    void scale(double newScale)
    {
      auto size = IntVector(cast(int)(_originalRect.w * newScale), cast(int)(_originalRect.h * newScale));
      if (_isFilePath)
      {
        _rect.x = _rect2.x;
        _rect.y = _rect2.y;
      }
      else if (_sheetRender)
      {
        _rect.x = _sheetRender.entry.rect.x;
        _rect.y = _sheetRender.entry.rect.y;
      }
      _rect.w = size.x;
      _rect.h = size.y;
      _scale = newScale;
    }
/// 
    string name() { return _name; }
/// 
    void name(string newName)
    {
      _name = newName;

      updateRect(true);
    }

/// 
    int opacity() { return _opacity; }
/// 
    void opacity(int newOpacity)
    {
      if (!_isFilePath)
      {
        if (!_sheetRender)
        {
          return;
        }

        if (!_sheetRender.texture)
        {
          return;
        }
      }

      if (newOpacity >= 255)
      {
        newOpacity = 255;
      }

      _opacity = newOpacity;
    }
  }

/// 
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

/// 
  void unmakeCover()
  {
    _coverMode = false;

    updateRect(true);
  }

/// 
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

    if (!_sheetRender || _isFilePath)
    {
      size = super.size;
    }
    else
    {
      size = IntVector(_sheetRender.size.x, _sheetRender.size.y);
    }

    if (!hasOriginalRect && (size.x || size.y))
    {
      auto rect = super.clientRect;
      hasOriginalRect = true;
      _rect = EXT_CreateRectangle(Rectangle(rect.x,rect.y,size.x,size.y));
      _originalRect = _rect;
    }

    return true;
  }

/// 
  void setRawPosition(IntVector position)
  {
    if (_sheetRender)
    {
      _sheetRender.entry.rect.x = cast(int)position.x;
      _sheetRender.entry.rect.y = cast(int)position.y;
    }
    else if (_isFilePath)
    {
      _rect1.x = cast(int)position.x;
      _rect1.y = cast(int)position.y;
    }

    _rect.x = cast(int)position.x;
    _rect.y = cast(int)position.y;
  }

/// 
  override void repaint()
  {
    auto rect = super.clientRect;
    //rect = Rectangle(rect.x, rect.y, super.width, super.height);

    if (_isFilePath)
    {
        _rect2 = new EXT_RectangleNative;
        _rect2.x = rect.x;
        _rect2.y = rect.y;
        _rect2.w = super.width;
        _rect2.h = super.height;

        _rect.x = rect.x;
        _rect.y = rect.y;
        return;
    }

    if (_name == _renderName && _sheetRender !is null)
    {
      _sheetRender.entry.rect.x = cast(int)rect.x;
      _sheetRender.entry.rect.y = cast(int)rect.y;
      if (_coverMode)
      {
        _sheetRender.entry.rect.w = cast(int)rect.w;
        _sheetRender.entry.rect.h = cast(int)rect.h;
      }

      _rect.x = _sheetRender.entry.rect.x;
      _rect.y = _sheetRender.entry.rect.y;
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
      
        _rect.x = _sheetRender.entry.rect.x;
        _rect.y = _sheetRender.entry.rect.y;
      }
    }
  }

/// 
  override void clean()
  {
    if (_cleaned)
    {
      return;
    }

    if (_texture) EXT_DestroyTexture(_texture);
    if (_temp) EXT_FreeSurface(_temp);

    _cleaned = true;

    super.clean();
  }

/// 
  override void renderNativeComponent()
  {
    auto screen = super.window.nativeScreen;

    if (_isFilePath)
    {
      if (!_texture || _cleaned)
      {
          return;
      }
      
      EXT_SetTextureAlphaMod(_texture, cast(ubyte)_opacity);
      
      if (_scale >= 2 || _scale < 1)
      {
        EXT_RenderCopy(window.nativeScreen, _texture, _rect1, _rect);
      }
      else
      {
        EXT_RenderCopy(window.nativeScreen, _texture, _rect1, _rect2);
      }
    }
    else if (_sheetRender && _sheetRender.texture)
    {
      EXT_SetTextureAlphaMod(_sheetRender.texture, cast(ubyte)_opacity);
      if (_scale >= 2 || _scale < 1)
      {
        EXT_RenderCopy(screen, _sheetRender.texture, _sheetRender.entry.textureRect, _rect);
      }
      else 
      {
        EXT_RenderCopy(screen, _sheetRender.texture, _sheetRender.entry.textureRect, _sheetRender.entry.rect);
      }
    }
  }
}
