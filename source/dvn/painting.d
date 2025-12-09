/**
* Copyright (c) 2025 Project DVN
*/
module dvn.painting;

import dvn.external;
import dvn.component;
public import dvn.colors;

/// 
public final class Paint
{
  package(dvn)
  {
    Color color;
    FloatVector position;
    FloatVector size;
    EXT_Rectangle rect;
  }

  private:
  final:
  this(Color color, FloatVector position, FloatVector size)
  {
    this.color = color;
    this.position = position;
    this.size = size;
  }
}

/// 
public final class Painting
{
  private:
  Paint[] _bottomPaintings;
  Paint[] _topPaintings;
  string _name;
  Component _component;

  public:
  final:
  package(dvn) this(string name, Component component)
  {
    _name = name;
    _component = component;

    clearBackgroundPaint();
    clearForegroundPaint();
  }

  @property
  {
/// 
    string name() { return _name; }
    
/// 
    Paint[] bottomPaintings() { return _bottomPaintings; }
/// 
    Paint[] topPaintings() { return _topPaintings; }
  }

/// 
  void clearBackgroundPaint()
  {
    _bottomPaintings = [];
  }

/// 
  void clearForegroundPaint()
  {
    _topPaintings = [];
  }

/// 
  void paintBackground(Color color, FloatVector position, FloatVector size)
  {
    _bottomPaintings ~= new Paint(color, position, size);
  }

/// 
  void paintForeground(Color color, FloatVector position, FloatVector size)
  {
    _topPaintings ~= new Paint(color, position, size);
  }

/// 
  void apply()
  {
    if (_component)
    {
      _component.setActivePainting(_name);
    }
  }
}
