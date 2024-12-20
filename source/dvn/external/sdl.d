module dvn.external.sdl;

import dvn.external.core;
import dvn.window;

// TODO: Make it more generic, so the engine itself doesn't reflect 100% SDL terms basically ...

private
{
  import derelict.sdl2.sdl;
  import derelict.sdl2.image;
  import derelict.sdl2.mixer;
  import derelict.sdl2.ttf;
  import derelict.sdl2.net;
}

private bool _initialized;

public alias EXT_GetError = SDL_GetError;

public alias EXT_SetWindowBordered = SDL_SetWindowBordered;
public alias EXT_bool = SDL_bool;

public alias EXT_DestroyWindow = SDL_DestroyWindow;

public alias EXT_HideWindow = SDL_HideWindow;
public alias EXT_ShowWindow = SDL_ShowWindow;

public alias EXT_StopTextInput = SDL_StopTextInput;
public alias EXT_StartTextInput = SDL_StartTextInput;

public alias EXT_SetWindowFullscreen = SDL_SetWindowFullscreen;

void EXT_Initialize()
{
  if (_initialized) return;
  _initialized = true;

	DerelictSDL2.load();
	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();
	DerelictSDL2Net.load();

	TTF_Init();
}

public class EXT_TextEntry
{
  /// _texture
  EXT_Texture _texture;
  /// _rect
  EXT_Rectangle _rect;
}

public class EXT_TextLabel
{
  import dvn.application : Application;

  private:
  EXT_TextEntry _entry;
  EXT_TextEntry _shadowEntry;
  Color _color;
  string _fontName;
  size_t _fontSize;
  dstring _text;
  bool _shadow;
  IntVector _position;
  EXT_Screen screen;
  Application application;
  IntVector _size;
  bool _hidden;

  public:
  final:
  this(EXT_Screen screen, Application application)
  {
    this.screen = screen;
    this.application = application;
  }

  @property
  {
    IntVector position() { return _position; }
    void position(IntVector newPosition)
    {
      _position = newPosition;

      if (_entry)
      {
        _entry._rect.x = _position.x;
        _entry._rect.y = _position.y;
      }

      if (_shadowEntry)
      {
        _shadowEntry._rect.x = _position.x + 1;
        _shadowEntry._rect.y = _position.y + 1;
      }
    }
    int x() { return _position.x; }
    int y() { return _position.y; }

    string fontName() { return _fontName; }
    void fontName(string newFontName)
    {
      _fontName = newFontName;

      update();
    }

    size_t fontSize() { return _fontSize; }
    void fontSize(size_t newFontSize)
    {
      _fontSize = newFontSize;

      update();
    }

    Color color() { return _color; }
    void color(Color newColor)
    {
      _color = newColor;

      update();
    }

    dstring text() { return _text; }
    void text(dstring newText)
    {
      _text = newText;

      update();
    }

    IntVector size() { return _size; }
    int width() { return _size.x; }
    int height() { return _size.y; }

    bool shadow() { return _shadow; }
    void shadow(bool hasShadow)
    {
      _shadow = hasShadow;
    }
  }

  protected bool measureComponentSize(out IntVector size)
  {
    size = IntVector(0,0);

    import dvn.fonts;
    import std.conv : to;

    if (!_fontName || !_fontName.length || _fontSize == 0)
    {
      return true;
    }

    if (!_text)
    {
      _text = "";
    }

    if (_shadowEntry && _shadowEntry._texture)
    {
      EXT_DestroyTexture(_shadowEntry._texture);
    }

    if (_entry && _entry._texture)
    {
      EXT_DestroyTexture(_entry._texture);
    }
    
    auto _textWidth = 0;
    auto _textHeight = 0;

    if (!_text || !_text.length)
    {
      _text = " ";
    }

    Font runtimeFont;
    if (!application.fonts.tryGetWithFallback(_fontName, _text, runtimeFont))
    {
      return true;
    }

    auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);

    if (!rawFont)
    {
      throw new Exception("No raw font.");
    }

    int w;
    int h;
    wstring utf16String = (_text.to!wstring);
    ushort[] utf16Buffer = [];
    foreach (c; utf16String)
    {
      utf16Buffer ~= c;
    }
    utf16Buffer ~= cast(ushort)'\0';

    if (EXT_UnicodeTextSize(rawFont, utf16Buffer.ptr, &w, &h) != 0)
    {
      throw new Exception("Failed to get size");
    }

    _textWidth = w > _textWidth ? w : _textWidth;
    _textHeight += h;

    size = IntVector(_textWidth, _textHeight);

    return true;
  }

  public void update()
  {
    IntVector measuredSize;
    if (measureComponentSize(measuredSize))
    {
      _size = measuredSize;
    }
    
    import dvn.fonts;
    import dvn.colors;
    import std.conv : to;

    if (!_fontName || !_fontName.length || _fontSize == 0)
    {
      return;
    }

    if (!_text)
    {
      _text = "";
    }

    if (_shadowEntry && _shadowEntry._texture)
    {
      EXT_DestroyTexture(_shadowEntry._texture);
    }

    if (_entry && _entry._texture)
    {
      EXT_DestroyTexture(_entry._texture);
    }
    
    auto _textWidth = 0;
    auto _textHeight = 0;

    if (!_text || !_text.length)
    {
      _text = " ";
    }

    Font runtimeFont;
    if (!application.fonts.tryGetWithFallback(_fontName, _text, runtimeFont))
    {
      return;
    }

    auto rawFont = EXT_GetFont(runtimeFont.path, _fontSize);

    if (!rawFont)
    {
      throw new Exception("No raw font.");
    }

    wstring utf16String = (_text.to!wstring);
    ushort[] utf16Buffer = [];
    foreach (c; utf16String)
    {
      utf16Buffer ~= c;
    }
    utf16Buffer ~= cast(ushort)'\0';

    EXT_Surface textSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, _color);

    if (!textSurface)
    {
      throw new Exception("could not create surface");
    }

    auto text = new EXT_TextEntry;
    text._texture = EXT_CreateTextureFromSurface(screen, textSurface);

    if (!text._texture)
    {
      throw new Exception("could not create texture");
    }

    _textWidth = textSurface.w > _textWidth ? textSurface.w : _textWidth;

    _textHeight += textSurface.h;

    text._rect = EXT_CreateEmptyRectangle();
    text._rect.x = _position.x;
    text._rect.y = _position.y;
    text._rect.w = textSurface.w;
    text._rect.h = textSurface.h;

    if (textSurface)
    {
      EXT_FreeSurface(textSurface);
    }

    _entry = text;

    if (_shadow)
    {
      EXT_Surface shadowSurface = EXT_RenderUnicodeText(rawFont, utf16Buffer.ptr, "000".getColorByHex);

      if (!shadowSurface)
      {
        throw new Exception("could not create shadow surface");
      }

      auto shadowText = new EXT_TextEntry;
      shadowText._texture = EXT_CreateTextureFromSurface(screen, shadowSurface);

      if (!shadowText._texture)
      {
        throw new Exception("could not create shadow texture");
      }

      shadowText._rect = EXT_CreateEmptyRectangle();
      shadowText._rect.x = _position.x + 1;
      shadowText._rect.y = _position.y  + 1;
      shadowText._rect.w = shadowSurface.w;
      shadowText._rect.h = shadowSurface.h;

      if (shadowSurface)
      {
        EXT_FreeSurface(shadowSurface);
      }

      _shadowEntry = shadowText;
    }
  }

  void show()
  {
    _hidden = false;
  }

  void hide()
  {
    _hidden = true;
  }

  public void render()
  {
    if (_hidden)
    {
      return;
    }
    
    if (_shadow && _shadowEntry && _shadowEntry._texture)
    {
      if (EXT_RenderCopy(screen, _shadowEntry._texture, null, _shadowEntry._rect) != 0)
      {
        import std.conv : to;

        throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
      }
    }

    if (_entry && _entry._texture)
    {
      if (EXT_RenderCopy(screen, _entry._texture, null, _entry._rect) != 0)
      {
        import std.conv : to;

        throw new Exception("Failed to render ... Error: " ~ EXT_GetError().to!string);
      }
    }
  }

  void clean()
  {
    if (_entry && _entry._texture)
    {
      EXT_DestroyTexture(_entry._texture);
      _entry._texture = null;
    }

    if (_shadowEntry && _shadowEntry._texture)
    {
      EXT_DestroyTexture(_shadowEntry._texture);
      _shadowEntry._texture = null;
    }
  }
}

public class EXT_Panel
{
  import dvn.application : Application;

  private:
  EXT_Rectangle _nativeRenderRectangle;
  Color _fillColor;
  Color _borderColor;
  IntVector _position;
  EXT_Screen screen;
  Application application;
  IntVector _size;
  bool _hidden;

  public:
  final:
  this(EXT_Screen screen, Application application)
  {
    this.screen = screen;
    this.application = application;
  }

  @property
  {
    IntVector position() { return _position; }
    void position(IntVector newPosition)
    {
      _position = newPosition;

      if (_nativeRenderRectangle)
      {
        _nativeRenderRectangle.x = _position.x;
        _nativeRenderRectangle.y = _position.y;
      }
    }
    int x() { return _position.x; }
    int y() { return _position.y; }

    Color fillColor() { return _fillColor; }
    void fillColor(Color newColor)
    {
      _fillColor = newColor;
    }

    Color borderColor() { return _borderColor; }
    void borderColor(Color newColor)
    {
      _borderColor = newColor;
    }

    IntVector size() { return _size; }
    void size(IntVector newSize)
    {
      _size = newSize;

      update();
    }
    int width() { return _size.x; }
    int height() { return _size.y; }
  }

  void update()
  {
    _nativeRenderRectangle = EXT_CreateRectangle(Rectangle(_position.x, _position.y, _size.x, _size.y));
  }

  void show()
  {
    _hidden = false;
  }

  void hide()
  {
    _hidden = true;
  }

  public void render()
  {
    if (_hidden)
    {
      return;
    }

    if (_fillColor.a > 0)
    {
      EXT_SetScreenDrawColor(screen, _fillColor);

      EXT_FillRectangle(screen, _nativeRenderRectangle);
    }

    if (_borderColor.a > 0)
    {
      EXT_SetScreenDrawColor(screen, _borderColor);

      EXT_DrawRectangle(screen, _nativeRenderRectangle);
    }
  }

  void clean()
  {
  }
}

public class EXT_Image
{
  import dvn.application : Application;

  private:
  string _name;
  Window _window;
  EXT_SheetRender* _sheetRender;
  EXT_Rectangle _nativeRenderRectangle;
  Color _fillColor;
  Color _borderColor;
  IntVector _position;
  EXT_Screen screen;
  Application application;
  IntVector _size;
  bool _hidden;

  public:
  final:
  this(Window window, string name)
  {
    _name = name;
    _window = window;
    screen = window.nativeScreen;
    application = window.application;

    EXT_SheetRender* sheetRender;
    if (window.getSheetEntry(_name, sheetRender))
    {
      _sheetRender = sheetRender;

      _size = IntVector(_sheetRender.size.x, _sheetRender.size.y);
    }
  }

  @property
  {
    IntVector position() { return _position; }
    void position(IntVector newPosition)
    {
      _position = newPosition;

      if (_sheetRender && _sheetRender.entry)
      {
        _sheetRender.entry.rect.x = _position.x;
        _sheetRender.entry.rect.y = _position.y;
      }

      if (_nativeRenderRectangle)
      {
        _nativeRenderRectangle.x = _position.x;
        _nativeRenderRectangle.y = _position.y;
      }
    }
    int x() { return _position.x; }
    int y() { return _position.y; }

    Color fillColor() { return _fillColor; }
    void fillColor(Color newColor)
    {
      _fillColor = newColor;
    }

    Color borderColor() { return _borderColor; }
    void borderColor(Color newColor)
    {
      _borderColor = newColor;
    }

    IntVector size() { return _size; }
    int width() { return _size.x; }
    int height() { return _size.y; }

    string name() { return _name; }
    void name(string newName)
    {
      if (_name == newName)
      {
        position = _position;
        return;
      }

      _name = newName;

      EXT_SheetRender* sheetRender;
      if (_window.getSheetEntry(_name, sheetRender))
      {
        _sheetRender = sheetRender;

        _size = IntVector(_sheetRender.size.x, _sheetRender.size.y);
        position = _position;
      }
    }
  }

  void update()
  {
    _nativeRenderRectangle = EXT_CreateRectangle(Rectangle(_position.x, _position.y, _size.x, _size.y));
  }

  void show()
  {
    _hidden = false;
  }

  void hide()
  {
    _hidden = true;
  }

  public void render()
  {
    if (_hidden)
    {
      return;
    }

    if (_fillColor.a > 0)
    {
      EXT_SetScreenDrawColor(screen, _fillColor);

      EXT_FillRectangle(screen, _nativeRenderRectangle);
    }

    if (_borderColor.a > 0)
    {
      EXT_SetScreenDrawColor(screen, _borderColor);

      EXT_DrawRectangle(screen, _nativeRenderRectangle);
    }

    if (_sheetRender && _sheetRender.texture)
    {
      EXT_RenderCopy(screen, _sheetRender.texture, _sheetRender.entry.textureRect, _sheetRender.entry.rect);
    }
  }

  void clean()
  {
  }
}

// struct{r,g,b,a}
public alias Color = SDL_Color;

private ulong _eventLoopStart;

void EXT_PreAplicationLoop(int fps)
{
  if (fps <= 0) return;

  _eventLoopStart = SDL_GetPerformanceCounter();
  EXT_SetTicks();
}

private int _applicationFps = -1;

int EXT_GetApplicationFps()
{
  return _applicationFps;
}

private int _recommendedFps = -1;

int EXT_GetRecommendedMovementFps()
{
  if (_recommendedFps == -1 && _applicationFps > 0)
  {
    _recommendedFps = 35;

    if (_applicationFps <= 20)
    {
      _recommendedFps = 30;
    }
    else if (_applicationFps <= 30)
    {
      _recommendedFps = 32;
    }
    else if (_applicationFps <= 40)
    {
      _recommendedFps = 33;
    }
    else if (_applicationFps <= 50)
    {
      _recommendedFps = 34;
    }
  }
  else
  {
    _recommendedFps = 35;
  }

  return _recommendedFps;
}

void EXT_PostApplicationLoop(int fps)
{
  _applicationFps = fps;

  if (fps <= 0) return;

  EXT_ValidateMusic();

  import std.math : floor;

  auto end = SDL_GetPerformanceCounter();
  double elapsedMS = (end - _eventLoopStart) / cast(double)SDL_GetPerformanceFrequency() * 1000.0f;

  auto frameRateLimit = cast(double)(cast(double)1000 / cast(double)fps);
  auto delayTimeRaw = cast(ptrdiff_t)floor(frameRateLimit - elapsedMS);
  auto delayTime = cast(uint)(delayTimeRaw > 0 ? delayTimeRaw : 1);

  SDL_Delay(delayTime);
}

private IntVector _mousePosition = IntVector(0,0);

IntVector EXT_GetMousePosition()
{
  return _mousePosition;
}

private __gshared bool _eventsDisabled;

void EXT_DisableEvents()
{
  synchronized
  {
    _eventsDisabled = true;
  }
}

void EXT_EnableEvents()
{
  synchronized
  {
    _eventsDisabled = false;
  }
}

bool EXT_ProcessEvents(Window[] windows)
{
  SDL_Event e;
  while (SDL_PollEvent(&e))
  {
    if (_eventsDisabled)
    {
      continue;
    }

    switch (e.type)
    {
      case SDL_EventType.SDL_QUIT: return false;

      case SDL_EventType.SDL_KEYDOWN:
        if (windows)
        {
          auto key = EXT_KeyboardKey(e.key.keysym.sym);

          foreach (window; windows)
          {
            window.events.fireKeyboardDownEvent(key);
          }
        }
        break;

      case SDL_EventType.SDL_KEYUP:
        if (windows)
        {
          auto key = EXT_KeyboardKey(e.key.keysym.sym);

          foreach (window; windows)
          {
            window.events.fireKeyboardUpEvent(key);
          }
        }
        break;

      case SDL_EventType.SDL_MOUSEBUTTONDOWN:
        if (windows)
        {
          auto button = EXT_MouseButton(cast(SDL_D_MouseButton)e.button.button);

          foreach (window; windows)
          {
            window.events.fireMouseButtonDownEvent(button, _mousePosition);
          }
        }
        break;

      case SDL_EventType.SDL_MOUSEBUTTONUP:
        if (windows)
        {
          auto button = EXT_MouseButton(cast(SDL_D_MouseButton)e.button.button);

          foreach (window; windows)
          {
            window.events.fireMouseButtonUpEvent(button, _mousePosition);
          }
        }
        break;

      case SDL_EventType.SDL_MOUSEMOTION:
        _mousePosition = IntVector(cast(int)e.motion.x, cast(int)e.motion.y);

        if (windows)
        {
          foreach (window; windows)
          {
            window.events.fireMouseMoveEvent(_mousePosition);
          }
        }
        break;

      case SDL_EventType.SDL_TEXTINPUT:
        if (windows)
        {
          S cropCString(S)(char[] str)
          {
            import std.conv : to;

            if (!str)
            {
              return null;
            }

            //S s = "";
            size_t cropIndex = 0;
            foreach (size_t i; 0 .. str.length)
            {
              auto c = str[i];

              if (c == '\0')
              {
                cropIndex = i;
                break;
              }
            }

            S s = str[0 .. cropIndex].to!S;

            return s;
          }

          auto eventText = cropCString!dstring(e.text.text);
          auto eventChar = eventText[0];

          foreach (window; windows)
          {
            window.events.fireTextInputEvent(eventChar,eventText);
          }
        }

        break;

      default: break;
    }
  }

  EXT_InitializeKeyboardState();

  return true;
}

MouseButton EXT_MouseButton(SDL_D_MouseButton button)
{
  switch (button)
  {
    case SDL_D_MouseButton.SDL_BUTTON_LEFT:
      return MouseButton.left;

    case SDL_D_MouseButton.SDL_BUTTON_MIDDLE:
      return MouseButton.middle;

    case SDL_D_MouseButton.SDL_BUTTON_RIGHT:
      return MouseButton.right;

    case SDL_D_MouseButton.SDL_BUTTON_X1:
      return MouseButton.extraButton1;

    case SDL_D_MouseButton.SDL_BUTTON_X2:
      return MouseButton.extraButton2;

    default: return cast(MouseButton)-1;
  }
}

KeyboardKey EXT_KeyboardKey(SDL_Keycode keyCode)
{
  switch (keyCode)
  {
    case SDLK_0:
      return KeyboardKey.num0;
    case SDLK_1:
      return KeyboardKey.num1;
    case SDLK_2:
      return KeyboardKey.num2;
    case SDLK_3:
      return KeyboardKey.num3;
    case SDLK_4:
      return KeyboardKey.num4;
    case SDLK_5:
      return KeyboardKey.num5;
    case SDLK_6:
      return KeyboardKey.num6;
    case SDLK_7:
      return KeyboardKey.num7;
    case SDLK_8:
      return KeyboardKey.num8;
    case SDLK_9:
      return KeyboardKey.num9;
    case SDLK_LCTRL:
      return KeyboardKey.LControl;
    case SDLK_LSHIFT:
      return KeyboardKey.LShift;
    case SDLK_LALT:
      return KeyboardKey.LAlt;
    case SDLK_RCTRL:
      return KeyboardKey.RControl;
    case SDLK_RSHIFT:
      return KeyboardKey.RShift;
    case SDLK_RALT:
      return KeyboardKey.RAlt;
    case SDLK_ESCAPE:
      return KeyboardKey.escape;
    case SDLK_RETURN:
      return KeyboardKey.returnKey;
    case SDLK_TAB:
      return KeyboardKey.tab;
    case SDL_Keycode.SDLK_BACKSPACE:
      return KeyboardKey.backSpace;
    case SDL_Keycode.SDLK_DELETE:
      return KeyboardKey.deleteKey;

    default: return KeyboardKey.unknown;
  }
}

public alias EXT_Window = SDL_Window*;
public alias EXT_Screen = SDL_Renderer*;

EXT_Window EXT_CreateWindow(string title, IntVector size, bool isFullScreen)
{
  import std.string : toStringz;

  if (isFullScreen)
  {
    return SDL_CreateWindow(
      title.toStringz,
      SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED,
      cast(int)size.x,
      cast(int)size.y,
      SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN
    );
  }
  else
  {
    return SDL_CreateWindow(
      title.toStringz,
      SDL_WINDOWPOS_UNDEFINED,
      SDL_WINDOWPOS_UNDEFINED,
      cast(int)size.x,
      cast(int)size.y,
      SDL_WINDOW_OPENGL
    );
  }
}

EXT_Screen EXT_CreateScreen(EXT_Window nativeWindow)
{
  auto renderer = SDL_CreateRenderer(nativeWindow, -1, SDL_RENDERER_ACCELERATED);

  SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);

  return renderer;
}

public alias EXT_Rectangle = SDL_Rect*;
public alias EXT_RectangleNative = SDL_Rect;

EXT_Rectangle EXT_CreateEmptyRectangle()
{
  return EXT_CreateRectangle(Rectangle(0,0,0,0));

}
EXT_Rectangle EXT_CreateRectangle(Rectangle rectangle)
{
  auto rect = new SDL_Rect;
  rect.x = rectangle.x;
  rect.y = rectangle.y;
  rect.w = rectangle.w;
  rect.h = rectangle.h;

  return rect;
}

bool EXT_SetScreenDrawColor(EXT_Screen screen, Color color)
{
  return SDL_SetRenderDrawColor(screen, color.r, color.g, color.b, color.a) == 0;
}

bool EXT_FillRectangle(EXT_Screen screen, EXT_Rectangle nativeRectangle)
{
  return SDL_RenderFillRect(screen, nativeRectangle) == 0;
}

bool EXT_DrawRectangle(EXT_Screen screen, EXT_Rectangle nativeRectangle)
{
  return SDL_RenderDrawRect(screen, nativeRectangle) == 0;
}

bool EXT_ClearScreen(EXT_Screen screen)
{
  return SDL_RenderClear(screen) == 0;
}

void EXT_PresentScreen(EXT_Screen screen)
{
  SDL_RenderPresent(screen);
}

alias EXT_Font = TTF_Font*;
private EXT_Font[string] _fonts;

EXT_Font EXT_GetFont(string path, size_t size)
{
  import std.string : toStringz;
  import std.conv : to;

	auto key = path ~ "_" ~ to!string(size);

	auto font = _fonts.get(key, cast(EXT_Font)null);

	if (!font)
	{
		font = TTF_OpenFont(path.toStringz, cast(uint)size);

		if (!font)
		{
			throw new Exception("could not find font");
		}

		_fonts[key] = font;
	}

	return font;
}

public alias EXT_Texture = SDL_Texture*;

public struct EXT_Sheet
{
  EXT_Texture sheet;
  IntVector columnSize;
  int columnCount;
}

EXT_Sheet EXT_CREATE_TILESET(EXT_Screen screen, string path, IntVector columnSize, int columnCount)
{
  auto texture = EXT_CREATE_SHEET(screen, path);

  return EXT_Sheet(texture, columnSize, columnCount);
}

void EXT_CLEAR_TILESET(EXT_Sheet tileset)
{
  if (!tileset.sheet)
  {
    return;
  }

  EXT_DestroyTexture(tileset.sheet);
  tileset.sheet = null;
}

public alias EXT_IMG_Load = IMG_Load;

EXT_Texture EXT_CREATE_SHEET(SDL_Renderer* renderer, string path)
{
  import std.string : toStringz;

	SDL_Surface* temp = EXT_IMG_Load(path.toStringz);
	SDL_Texture* sheet = SDL_CreateTextureFromSurface(renderer, temp);
	SDL_FreeSurface(temp);

	return sheet;
}

struct EXT_SheetEntry
{
	EXT_Rectangle rect;
	EXT_Rectangle textureRect;
}

EXT_SheetEntry EXT_CREATE_SHEET_ENTRY(EXT_Texture sheet, FloatVector position, IntVector size, int row, int columns)
{
	auto rect = new SDL_Rect;
	rect.x = cast(int)position.x;
	rect.y = cast(int)position.y;
	rect.w = cast(int)size.x;
	rect.h = cast(int)size.y;

	auto textureRect = new SDL_Rect;
	textureRect.x = 0;
	textureRect.y = cast(int)(row * size.y);
	textureRect.w = 0;
	textureRect.h = 0;

	SDL_QueryTexture(sheet, null, null, &textureRect.w, &textureRect.h);

	textureRect.w /= columns;
	textureRect.h = size.y;

	return EXT_SheetEntry(rect, textureRect);
}

struct EXT_SheetRender
{
	EXT_SheetEntry* entry; // tile
	EXT_Texture texture; // sheet
	IntVector size; // tile size
}

public alias EXT_RenderCopy = SDL_RenderCopy;
public alias EXT_RenderCopyEx = SDL_RenderCopyEx;
public alias EXT_DestroyTexture = SDL_DestroyTexture;
public alias EXT_FreeSurface = SDL_FreeSurface;

public alias EXT_RendererFlip = SDL_RendererFlip;

public alias EXT_Surface = SDL_Surface*;

public alias EXT_CreateTextureFromSurface = SDL_CreateTextureFromSurface;

public alias EXT_RenderUnicodeText = TTF_RenderUNICODE_Blended;

public alias EXT_UnicodeTextSize = TTF_SizeUNICODE;

public alias EXT_SetRenderRectangle = SDL_RenderSetClipRect;

private uint _ticks;

void EXT_SetTicks()
{
  _ticks = SDL_GetTicks();
}

uint EXT_GetTicks()
{
  return _ticks;
}

uint EXT_GetTicksRaw()
{
  return SDL_GetTicks();
}

private bool _enableKeyboardState = false;
private ubyte* _keyboardState;
private bool _allowWASD = false;

void EXT_AllowWASDMovement()
{
  _allowWASD = true;
}

void EXT_DisallowWASDMovement()
{
  _allowWASD = false;
}

void EXT_EnableKeyboardState()
{
  _enableKeyboardState = true;
}

void EXT_DisableKeyboardState()
{
  _enableKeyboardState = false;
}

void EXT_InitializeKeyboardState()
{
  if (!_enableKeyboardState)
  {
    _keyboardState = null;
    return;
  }

  _keyboardState = SDL_GetKeyboardState(null);
}

bool EXT_HoldsControl()
{
  if (!_enableKeyboardState || !_keyboardState) return false;

  return
    _keyboardState[SDL_Scancode.SDL_SCANCODE_LCTRL] > 0 ||
    _keyboardState[SDL_Scancode.SDL_SCANCODE_RCTRL] > 0;
}

bool EXT_MoveUp()
{
  if (!_enableKeyboardState || !_keyboardState) return false;

  if (_allowWASD)
  {
    return _keyboardState[SDL_Scancode.SDL_SCANCODE_UP] > 0 || _keyboardState[SDL_Scancode.SDL_SCANCODE_W] > 0;
  }

  return _keyboardState[SDL_Scancode.SDL_SCANCODE_UP] > 0;
}

bool EXT_MoveRight()
{
  if (!_enableKeyboardState || !_keyboardState) return false;

  if (_allowWASD)
  {
    return _keyboardState[SDL_Scancode.SDL_SCANCODE_RIGHT] > 0 || _keyboardState[SDL_Scancode.SDL_SCANCODE_D] > 0;
  }

  return _keyboardState[SDL_Scancode.SDL_SCANCODE_RIGHT] > 0;
}

bool EXT_MoveDown()
{
  if (!_enableKeyboardState || !_keyboardState) return false;

  if (_allowWASD)
  {
    return _keyboardState[SDL_Scancode.SDL_SCANCODE_DOWN] > 0 || _keyboardState[SDL_Scancode.SDL_SCANCODE_S] > 0;
  }

  return _keyboardState[SDL_Scancode.SDL_SCANCODE_DOWN] > 0;
}

bool EXT_MoveLeft()
{
  if (!_enableKeyboardState || !_keyboardState) return false;

  if (_allowWASD)
  {
    return _keyboardState[SDL_Scancode.SDL_SCANCODE_LEFT] > 0 || _keyboardState[SDL_Scancode.SDL_SCANCODE_A] > 0;
  }

  return _keyboardState[SDL_Scancode.SDL_SCANCODE_LEFT] > 0;
}

private SDL_Cursor* _defaultCursor;
private SDL_Cursor* _ibeamCursor;
private SDL_Cursor* _handCursor;
private SDL_Cursor* _waitCursor;
private SDL_Cursor* _currentCursor;
private bool _isWaiting = false;

void EXT_CreateCursors()
{
  if (_defaultCursor !is null) return;

  _defaultCursor = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_ARROW);
  _ibeamCursor = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_IBEAM);
  _handCursor = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_HAND);
  _waitCursor = SDL_CreateSystemCursor(SDL_SystemCursor.SDL_SYSTEM_CURSOR_WAIT);
}

void EXT_ResetCursor()
{
  EXT_CreateCursors();

  if (_isWaiting) return;

  if (_currentCursor == _defaultCursor) return;
  _currentCursor = _defaultCursor;

  SDL_SetCursor(_defaultCursor);
}

void EXT_SetIBeamCursor()
{
  EXT_CreateCursors();

  if (_isWaiting) return;

  if (_currentCursor == _ibeamCursor) return;
  _currentCursor = _ibeamCursor;

  SDL_SetCursor(_ibeamCursor);
}

void EXT_SetHandCursor()
{
  EXT_CreateCursors();

  if (_isWaiting) return;

  if (_currentCursor == _handCursor) return;
  _currentCursor = _handCursor;

  SDL_SetCursor(_handCursor);
}

private size_t _waitCount = 0;

void EXT_BeginWait()
{
  EXT_SetWaitCursor();

  _isWaiting = true;
  _waitCount++;
}

void EXT_EndWait()
{
  _waitCount--;
  if (_waitCount > 0) return;

  _isWaiting = false;

  EXT_ResetCursor();
}

void EXT_SetWaitCursor()
{
  EXT_CreateCursors();

  if (_isWaiting) return;

  if (_currentCursor == _waitCursor) return;
  _currentCursor = _waitCursor;

  SDL_SetCursor(_waitCursor);
}

private __gshared long _ping;

void EXT_SetPing(long ping)
{
  _ping = ping;
}

long EXT_GetPing()
{
  return _ping;
}

private bool _musicDisabled;
private bool _soundEffectsDisabled;
private bool _allSoundsDisabled;

void EXT_DisableSound()
{
  _allSoundsDisabled = true;

  EXT_StopMusic();
}

void EXT_EnableSound()
{
  _allSoundsDisabled = false;
}

void EXT_DisableMusic()
{
  _musicDisabled = true;

  EXT_StopMusic();
}

void EXT_EnableMusic()
{
  _musicDisabled = false;
}

void EXT_DisableSoundEffects()
{
  _soundEffectsDisabled = true;
}

void EXT_EnableSoundEffects()
{
  _soundEffectsDisabled = false;
}

private final class EXT_Music
{
  /// _music
  Mix_Music* _music;

  final:
  /// this()
  this()
  {
  }

  /// openFromFile()
  bool openFromFile(string music)
  {
    import std.string : toStringz;

    clean();

    if (!music || !music.length)
    {
      return false;
    }

    int flags = MIX_INIT_MP3 | MIX_INIT_OGG | MIX_INIT_FLAC | MIX_INIT_MOD;

    int initted = Mix_Init(flags);

    if ((initted & flags) != flags)
    {
      return false;
    }

    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) != 0)
    {
      return false;
    }

    _music = Mix_LoadMUS(music.toStringz);

    if (!_music)
    {
      return false;
    }

    _lastMusic = music;

    return true;
  }

  /// play()
  void play()
  {
    if (!_allSoundsDisabled && !_musicDisabled)
    {
      Mix_VolumeMusic(_soundVolume);

      Mix_PlayMusic(_music, 1);
    }
  }

  /// pause()
  void pause()
  {
    if (!_allSoundsDisabled && !_musicDisabled) Mix_PauseMusic();
  }

  /// stop()
  void stop()
  {
    if (_music) Mix_HaltMusic();
  }

  /// clean
  void clean()
  {
    if (_music)
    {
      Mix_FreeMusic(_music);

      _music = null;
    }
  }
}

private EXT_Music _currentMusic;
private string _currentMusicPath;
private int _soundVolume;

void EXT_SetSoundVolume(int volume)
{
  _soundVolume = volume;
}

void EXT_ValidateMusic()
{
  if (!_allSoundsDisabled && !_musicDisabled && _currentMusic && _currentMusicPath && _currentMusicPath.length)
  {
    if (Mix_PlayingMusic() == 0)
    {
      _currentMusic.play();
    }
  }
}

public alias EXT_Delay = SDL_Delay;

private string _lastMusic;

void EXT_PlayLastMusic()
{
  if (!_lastMusic || !_lastMusic.length)
  {
    return;
  }

  EXT_PlayMusic(_lastMusic);
}

void EXT_PlayMusic(string path)
{
  if (_currentMusicPath == path)
  {
    return;
  }

  _lastMusic = path;

  if (_currentMusic)
  {
    _currentMusic.stop();
    _currentMusic.clean();
    _currentMusic = null;
    _currentMusicPath = null;
  }

  auto music = new EXT_Music;
  _currentMusic = music;
  _currentMusicPath = path;

  if (!music.openFromFile(path))
  {
    return;
  }

  music.play();
}

void EXT_PauseMusic()
{
  if (_currentMusic)
  {
    _currentMusic.pause();
  }
}

void EXT_StopMusic()
{
  if (_currentMusic)
  {
    _currentMusic.stop();
    _currentMusic.clean();
    _currentMusic = null;
    _currentMusicPath = null;
  }
}

private alias EXT_SoundChunk = Mix_Chunk*;
private EXT_SoundChunk[string] _soundEffects;

void EXT_PlaySound(string path)
{
  import std.string : toStringz;

  auto sound = _soundEffects.get(path, null);

  if (!sound)
  {
    sound = Mix_LoadWAV(path.toStringz);

    if (!sound)
    {
      return;
    }

    _soundEffects[path] = sound;
  }

  if (!_allSoundsDisabled && !_soundEffectsDisabled)
  {
    Mix_PlayChannel(-1, sound, 0);
  }
}

private uint _lastMS = 0;
private int _frames = 0;
private int _frameCount = 0;

int EXT_GetFps()
{
  auto ticks = EXT_GetTicks();

  if (_lastMS == 0)
  {
    _lastMS = ticks;
  }

  if ((ticks - _lastMS) > 1000)
  {
    _lastMS = 0;
    _frameCount = _frames;
    _frames = 0;
  }
  else
  {
    _frames++;
  }

  return _frameCount;
}

int EXT_FontGlyphSupport(EXT_Font font, dchar c)
{
  import std.conv : to;

  return TTF_GlyphIsProvided(font, cast(ushort)(c.to!wchar));
}

private alias TextureAtlas = EXT_Texture[];
private TextureAtlas[string] _textureAtlases;

void EXT_InitializeTextureAtlas(string name, int pageCount)
{
  _textureAtlases[name] = new EXT_Texture[pageCount];
}

void EXT_AddTextureAtlasPage(EXT_Screen screen, string name, string path, int page)
{
  auto atlas = _textureAtlases.get(name, null);

  if (!atlas)
  {
    return;
  }

  import std.string : toStringz;

  SDL_Surface* tempSurface = IMG_Load(path.toStringz);
  SDL_Texture* texture = SDL_CreateTextureFromSurface(screen, tempSurface);
  SDL_FreeSurface(tempSurface);

  atlas[page] = texture;
}

EXT_Texture EXT_GetTextureAtlas(string name, int page)
{
  auto atlas = _textureAtlases.get(name, null);

  if (!atlas)
  {
    return null;
  }

  return atlas[page];
}

public struct EXT_TextureAsset
{
  EXT_Rectangle[] states;
  EXT_Texture texture;
}

EXT_TextureAsset* EXT_GetTextureAsset(string atlasName, int page, Rectangle location, int columns)
{
  auto texture = EXT_GetTextureAtlas(atlasName, page);

  if (!texture)
  {
    return null;
  }

  auto textureEntry = new EXT_TextureAsset;
  textureEntry.states = new EXT_Rectangle[columns];

  textureEntry.texture = texture;

  auto columnWidth = location.w / columns;

  foreach (col; 0 .. columns)
  {
    auto textureRect = new SDL_Rect;
    textureRect.x = location.x + (columnWidth * col);
    textureRect.y = location.y;
    textureRect.w = columnWidth;
    textureRect.h = location.h;

    textureEntry.states[col] = textureRect;
  }

  return textureEntry;
}
