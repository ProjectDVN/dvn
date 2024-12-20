module dvn.external.core;

/// A 2d float vector.
struct FloatVector
{
  /// The x value.
  float x;
  /// The y value.
  float y;
}

/// A 2d 32 bit uint vector.
struct UintVector
{
  /// The x value.
  uint x;
  /// The y value.
  uint y;
}

/// A 2d 32 bit int vector.
struct IntVector
{
  /// The x value.
  int x;
  /// The y value.
  int y;
}

struct Rectangle
{
  // The x value.
  int x;
  // The y value.
  int y;
  /// The width.
  int w;
  /// The height.
  int h;
}

Rectangle minimumSize(Rectangle rect)
{
  return Rectangle(rect.x, rect.y, rect.w <= 0 ? 1 : rect.w, rect.h <= 0 ? 1 : rect.h);
}

Rectangle intersectRectangle(Rectangle a, Rectangle b)
{
  import std.math : fmin,fmax;

  int min(int x, int y) { return cast(int)fmin(cast(float)x,cast(float)y);}
  int max(int x, int y) { return cast(int)fmax(cast(float)x,cast(float)y);}

  int x1 = max(a.x, b.x);
  int x2 = min(a.x + a.w, b.x + b.w);
  int y1 = max(a.y, b.y);
  int y2 = min(a.y + a.h, b.y + b.h);

  if (x2 >= x1
      && y2 >= y1) {

      return Rectangle(x1, y1, x2 - x1, y2 - y1);
  }
  return Rectangle(0,0,0,0);
}

/// Enumeration of keyboard keys.
enum KeyboardKey
{
  /// Unhandled key
  unknown = -1,
  /// The A key
  a = 0,
  /// The B key
  b,
  /// The C key
  c,
  /// The D key
  d,
  /// The E key
  e,
  /// The F key
  f,
  /// The G key
  g,
  /// The H key
  h,
  /// The I key
  i,
  /// The J key
  j,
  /// The K key
  k,
  /// The L key
  l,
  /// The M key
  m,
  /// The N key
  n,
  /// The O key
  o,
  /// The P key
  p,
  /// The Q key
  q,
  /// The R key
  r,
  /// The S key
  s,
  /// The T key
  t,
  /// The U key
  u,
  /// The V key
  v,
  /// The W key
  w,
  /// The X key
  x,
  /// The Y key
  y,
  /// The Z key
  z,
  /// The 0 key
  num0,
  /// The 1 key
  num1,
  /// The 2 key
  num2,
  /// The 3 key
  num3,
  /// The 4 key
  num4,
  /// The 5 key
  num5,
  /// The 6 key
  num6,
  /// The 7 key
  num7,
  /// The 8 key
  num8,
  /// The 9 key
  num9,
  /// The Escape key
  escape,
  /// The left Control key
  LControl,
  /// The left Shift key
  LShift,
  /// The left Alt key
  LAlt,
  /// The left OS specific key: window (Windows and Linux), apple (MacOS X), ...
  LSystem,
  /// The right Control key
  RControl,
  /// The right Shift key
  RShift,
  /// The right Alt key
  RAlt,
  /// The right OS specific key: window (Windows and Linux), apple (MacOS X), ...
  RSystem,
  /// The Menu key
  menu,
  /// The [ key
  LBracket,
  /// The ] key
  RBracket,
  /// The ; key
  semiColon,
  /// The , key
  comma,
  /// The . key
  period,
  /// The ' key
  quote,
  /// The / key
  slash,
  /// The \ key
  backSlash,
  /// The ~ key
  tilde,
  /// The = key
  equal,
  /// The - key
  dash,
  /// The Space key
  space,
  /// The Return key
  returnKey,
  /// The Backspace key
  backSpace,
  /// The Tabulation key
  tab,
  /// The Page up key
  pageUp,
  /// The Page down key
  pageDown,
  /// The End key
  end,
  /// The Home key
  home,
  /// The Insert key
  insert,
  /// The Delete key
  deleteKey,
  /// The + key
  add,
  /// The - key
  subtract,
  /// The * key
  multiply,
  /// The / key
  divide,
  /// Left arrow
  left,
  /// Right arrow
  right,
  /// Up arrow
  up,
  /// Down arrow
  down,
  /// The numpad 0 key
  numpad0,
  /// The numpad 1 key
  numpad1,
  /// The numpad 2 key
  numpad2,
  /// The numpad 3 key
  numpad3,
  /// The numpad 4 key
  numpad4,
  /// The numpad 5 key
  numpad5,
  /// The numpad 6 key
  numpad6,
  /// The numpad 7 key
  numpad7,
  /// The numpad 8 key
  numpad8,
  /// The numpad 9 key
  numpad9,
  /// The F1 key
  f1,
  /// The F2 key
  f2,
  /// The F3 key
  f3,
  /// The F4 key
  f4,
  /// The F5 key
  f5,
  /// The F6 key
  f6,
  /// The F7 key
  f7,
  /// The F8 key
  f8,
  /// The F9 key
  f9,
  /// The F10 key
  f10,
  /// The F11 key
  f11,
  /// The F12 key
  f12,
  /// The F13 key
  f13,
  /// The F14 key
  f14,
  /// The F15 key
  f15,
  /// The Pause key
  pause
}

/// Enumeration of mouse buttons.
enum MouseButton
{
  /// The left mouse button
  left,
  /// The right mouse button
  right,
  /// The middle (wheel) mouse button
  middle,
  /// The first extra mouse button
  extraButton1,
  /// The second extra mouse button
  extraButton2,
}
