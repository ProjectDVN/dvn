module zid.components.animation;

import zid.component;
import zid.external;
import zid.window;

public final class Animation : Component
{
  private:
  EXT_Sheet _sheet;
  string _name;
  alias SheetRenderEntry = EXT_SheetRender*;
  SheetRenderEntry[] _frames;
  size_t _frameIndex;
  uint _lastMS;
  uint _delay;
  int _row;
  bool _singular;
  bool _finished;
  EXT_Rectangle _rect;
  EXT_Rectangle _originalRect;
  double _scale;
  double _angle;
  bool _flip;

  public:
  final:
  this(Window window, string name, bool singular = false, size_t row = 0)
  {
    super(window, false);

    _name = name;
    _lastMS = 0;
    _delay = 100;
    _singular = singular;
    _finished = false;
    _row = cast(int)row;
    _rect = EXT_CreateRectangle(Rectangle(0,0,0,0));
    _originalRect = _rect;
    _angle = 0;
    _flip = false;
  }

  @property
  {
    double scale() { return _scale; }
    void scale(double newScale)
    {
      auto size = IntVector(cast(int)(_originalRect.w * newScale), cast(int)(_originalRect.h * newScale));
      _rect.w = size.x;
      _rect.h = size.y;
    }
    double angle() { return _angle; }
    void angle(double newAngle)
    {
      _angle = newAngle;
    }
    bool flip() { return _flip; }
    void flip(bool shouldFlip)
    {
      _flip = shouldFlip;
    }
    string name() { return _name; }
    void name(string animationName)
    {
      _name = animationName;
      _frames = [];
      _frameIndex = 0;
      _sheet = EXT_Sheet.init;

      updateRect(true);
    }

    uint delay() { return _delay; }
    void delay(uint newDelay)
    {
      _delay = newDelay;
    }

    size_t row() { return _row; }
    void row(size_t newRow)
    {
      _row = cast(int)newRow;
      _frames = [];
      _frameIndex = 0;
      _sheet = EXT_Sheet.init;

      updateRect(true);
    }
  }

  protected override bool measureComponentSize(out IntVector size)
  {
    if (!_sheet.sheet)
    {
      size = super.size;
    }
    else
    {
      size = _sheet.columnSize;
    }

    return true;
  }

  override void repaint()
  {
    auto rect = super.clientRect;
    auto window = super.window;

    _sheet = window.getSheet(_name);

    if (!_sheet.sheet)
    {
      return;
    }

    if (_frames && _frames.length)
    {
      foreach (sheetRender; _frames)
      {
        if (sheetRender !is null)
        {
          sheetRender.entry.rect.x = cast(int)rect.x;
          sheetRender.entry.rect.y = cast(int)rect.y;
          _rect = sheetRender.entry.rect;
          _originalRect = _rect;
          // sheetRender.entry.rect.w = cast(int)rect.w;
          // sheetRender.entry.rect.h = cast(int)rect.h;
        }
      }
    }
    else
    {
      auto frames = _sheet.columnCount;
      _frames = [];

      foreach (frame; 0 .. frames)
      {
        SheetRenderEntry sheetRender;
        if (window.getSheetEntry(_name, _row, frame, sheetRender))
        {
          if (sheetRender !is null)
          {
            sheetRender.entry.rect.x = cast(int)rect.x;
            sheetRender.entry.rect.y = cast(int)rect.y;
            _rect = sheetRender.entry.rect;
            _originalRect = _rect;
            // sheetRender.entry.rect.w = cast(int)rect.w;
            // sheetRender.entry.rect.h = cast(int)rect.h;

            _frames ~= sheetRender;
          }
        }
      }
    }
  }

  override void renderNativeComponent()
  {
    if (!_frames || !_frames.length || _finished)
    {
      return;
    }

    auto ms = EXT_GetTicks();

    if (_lastMS == 0 || (ms - _lastMS) > _delay)
    {
      _lastMS = ms;

      _frameIndex++;

      if (_frameIndex >= _frames.length)
      {
        _frameIndex = 0;
        _finished = _singular;
        if (_finished)
        {
          return;
        }
      }
    }

    auto screen = super.window.nativeScreen;

    auto frame = _frames[_frameIndex];

    if (frame && frame.texture)
    {
      if (_angle >= 1)
      { 
        if (_flip)
        {
          EXT_RenderCopyEx(screen, frame.texture, frame.entry.textureRect, _rect, _angle, null, EXT_RendererFlip.SDL_FLIP_HORIZONTAL);
        }
        else
        {
          EXT_RenderCopyEx(screen, frame.texture, frame.entry.textureRect, _rect, _angle, null, EXT_RendererFlip.SDL_FLIP_NONE);
        }
      }
      else
      {
        EXT_RenderCopy(screen, frame.texture, frame.entry.textureRect, _rect);
      }
    }
  }
}
