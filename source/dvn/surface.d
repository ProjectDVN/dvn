/**
* Copyright (c) 2025 Project DVN
*/
module dvn.surface;

import dvn.external;
import dvn.atlas;

/// 
public enum Direction : int
{
/// 
  north,
/// 
  northEast,
/// 
  east,
/// 
  southEast,
/// 
  south,
/// 
  southWest,
/// 
  west,
/// 
  northWest
}

/// 
public final class Model
{
  private:
  Surface[] _surfaces;
  Surface[] _surfacesNorth;
  Surface[] _activeSurfaces;
  EXT_Rectangle _rect;
  EXT_Rectangle _renderRect;
  Direction _currentDirection;
  string _currentAction;
  IntVector _size;
  IntVector _originalSize;
  IntVector _renderSize;
  IntVector _position;
  double _scale;
  bool _hasOffset;

  public:
  final:
/// 
  this(IntVector size, Surface[] surfaces, Surface[] surfacesNorth)
  {
    _surfaces = surfaces;
    _surfacesNorth = surfacesNorth;
    _activeSurfaces = _surfaces;
    _size = size;
    _originalSize = size;
    _renderSize = size;
    _rect = EXT_CreateRectangle(Rectangle(0,0,_size.x,_size.y));
    _renderRect = EXT_CreateRectangle(Rectangle(0,0,_size.x,_size.y));
    _position = IntVector(0,0);
    _scale = 1;
  }

  @property
  {
/// 
    bool hasOffset() { return _hasOffset; }
/// 
    void hasOffset(bool setHasOffset)
    {
      _hasOffset = setHasOffset;
    }

/// 
    IntVector size() { return _size; }
/// 
    void size(IntVector newSize)
    {
      _size = newSize;

      _rect.w = _size.x;
      _rect.h = _size.y;
    }

/// 
    IntVector position() { return _position; }
/// 
    void position(IntVector newPosition)
    {
      _position = newPosition;

      _rect.x = _position.x;
      _rect.y = _position.y;

      if (_hasOffset)
      {
        _renderRect.x = _rect.x - 48;
        _renderRect.y = _rect.y - (48 + 32);
      }
      else
      {
        _renderRect.x = _rect.x;
        _renderRect.y = _rect.y;
      }
    }

/// 
    double scale() { return _scale; }
/// 
    void scale(double newScale)
    {
      if (_hasOffset)
      {
        _renderSize = IntVector(cast(int)(_originalSize.x * newScale), cast(int)(_originalSize.y * newScale));
        _renderRect = EXT_CreateRectangle(Rectangle(_rect.x - 48, _rect.y - (48 + 32), _renderSize.x, _renderSize.y));
      }
      else
      {
        size = IntVector(cast(int)(_originalSize.x * newScale), cast(int)(_originalSize.y * newScale));
      }
    }

/// 
    string currentAction() { return _currentAction; }

/// 
    Direction currentDirection() { return _currentDirection; }
  }

/// 
  void removeSurface(size_t index, size_t indexNorth)
  {
    _surfaces[index] = null;
    _surfacesNorth[indexNorth] = null;

    setAction(_currentAction, _currentDirection, true, true);
  }

/// 
  void changeStaticSurfaceAll(size_t index, size_t indexNorth, string atlas, string name)
  {
    changeSurface(index, indexNorth, atlas, name, ["default"], [Direction.north, Direction.northEast, Direction.northWest, Direction.east, Direction.south, Direction.southEast, Direction.southWest, Direction.west]);
  }

/// 
  void changeStaticSurfaceStandard(size_t index, size_t indexNorth, string atlas, string name)
  {
    changeSurface(index, indexNorth, atlas, name, ["default"], [Direction.north, Direction.east, Direction.south, Direction.west]);
  }

/// 
  void changeSurfaceAll(size_t index, size_t indexNorth, string atlas, string name, string[] actions)
  {
    changeSurface(index, indexNorth, atlas, name, actions, [Direction.north, Direction.northEast, Direction.northWest, Direction.east, Direction.south, Direction.southEast, Direction.southWest, Direction.west]);
  }

/// 
  void changeSurfaceStandard(size_t index, size_t indexNorth, string atlas, string name, string[] actions)
  {
    changeSurface(index, indexNorth, atlas, name, actions, [Direction.north, Direction.east, Direction.south, Direction.west]);
  }

/// 
  void changeSurface(size_t index, size_t indexNorth, string atlasName, string name, string[] actions, Direction[] directions)
  {
    auto atlas = getAtlas(atlasName);

    if (!atlas)
    {
      return;
    }

    auto surface = atlas.createSurface(name, actions, directions);

    changeSurface(index, indexNorth, surface);
  }

/// 
  void changeSurface(size_t index, size_t indexNorth, Surface surface)
  {
    _surfaces[index] = surface;
    _surfacesNorth[indexNorth] = surface;
  }

/// 
  void setDirection(Direction direction, bool force = false)
  {
    setAction(_currentAction, direction, force);
  }

/// 
  void setAction(string name, Direction direction, bool force = false, bool forceActiveLoad = false)
  {
    if (_currentDirection != direction || !_activeSurfaces || forceActiveLoad)
    {
      _currentDirection = direction;

      if (direction == Direction.north || direction == Direction.northWest || direction == Direction.northEast)
      {
        _activeSurfaces = _surfacesNorth;
      }
      else
      {
        _activeSurfaces = _surfaces;
      }
    }

    if (!_activeSurfaces) return;

    _currentAction = name;

    foreach (activeSurface; _activeSurfaces)
    {
      if (!activeSurface) continue;

      activeSurface.setAction(_currentAction, direction, force);
    }
  }

/// 
  void moveState()
  {
    if (!_activeSurfaces) return;

    foreach (activeSurface; _activeSurfaces)
    {
      if (!activeSurface) continue;

      activeSurface.moveState();
    }
  }

/// 
  void resetState()
  {
    if (!_activeSurfaces) return;

    foreach (activeSurface; _activeSurfaces)
    {
      if (!activeSurface) continue;

      activeSurface.resetState();
    }
  }

/// 
  void render(EXT_Window window, EXT_Screen screen)
  {
    if (!_activeSurfaces) return;

    if (_hasOffset)
    {
      foreach (activeSurface; _activeSurfaces)
      {
        if (!activeSurface) continue;

        activeSurface.render(window, screen, _renderRect);
      }
    }
    else
    {
      foreach (activeSurface; _activeSurfaces)
      {
        if (!activeSurface) continue;

        activeSurface.render(window, screen, _rect);
      }
    }
  }
}

/// 
public final class Surface
{
  private:
  Asset[string] _assets; // key: action
  Asset _defaultAsset; // If action is not found

  Direction _currentDirection;
  string _currentActionName;
  Asset _currentAsset;
  EXT_TextureAsset* _currentAssetEntry;
  size_t _currentAssetEntryState;
  EXT_Rectangle _currentAssetState;

  public:
  final:
/// 
  this()
  {
  }

/// 
  void render(EXT_Window window, EXT_Screen screen, EXT_Rectangle rect)
  {
    if (!_currentAssetEntry) return;
    auto assetEntry = _currentAssetEntry;

    EXT_RenderCopy(screen, assetEntry.texture, _currentAssetState, rect);
  }

/// 
  void resetState()
  {
    if (!_currentAssetEntry) return;

    _currentAssetEntryState = 0;
    _currentAssetState = _currentAssetEntry.states[_currentAssetEntryState];
  }

/// 
  void moveState()
  {
    if (!_currentAssetEntry) return;

    _currentAssetState = _currentAssetEntry.states[_currentAssetEntryState];

    _currentAssetEntryState++;

    if (_currentAssetEntryState >= _currentAssetEntry.states.length)
    {
      _currentAssetEntryState = 0;
    }
  }
  
/// 
  void setAction(string name, Direction direction, bool force = false)
  {
    if (_currentActionName != name || force)
    {
      _currentAsset = _assets.get(name, _defaultAsset);

      if (_currentAsset)
      {
        _currentAssetEntry = _currentAsset.getAssetByDirection(direction);
        _currentAssetEntryState = 0;
        _currentActionName = name;
        _currentDirection = direction;
        _currentAssetState = _currentAssetEntry.states[_currentAssetEntryState];
      }
    }
    else if (_currentAsset && _currentDirection != direction)
    {
      _currentAssetEntry = _currentAsset.getAssetByDirection(direction);
      _currentAssetEntryState = 0;
      _currentDirection = direction;
      _currentAssetState = _currentAssetEntry.states[_currentAssetEntryState];
    }
  }

/// 
  void createAsset(string action)
  {
    _assets[action] = new Asset;
  }

/// 
  void setAsset(EXT_TextureAsset* asset, Direction direction, string action)
  {
    auto assetAction = _assets.get(action, null);

    if (!assetAction) return;

    assetAction.setAsset(asset, direction);
  }

/// 
  void setDefaultAsset(string action)
  {
    _defaultAsset = _assets.get(action, null);
  }
}

/// 
public final class Asset
{
  private:
  EXT_TextureAsset* _assetNorth;
  EXT_TextureAsset* _assetNorthEast;
  EXT_TextureAsset* _assetEast;
  EXT_TextureAsset* _assetSouthEast;
  EXT_TextureAsset* _assetSouth;
  EXT_TextureAsset* _assetSouthWest;
  EXT_TextureAsset* _assetWest;
  EXT_TextureAsset* _assetNorthWest;

  public:
  final:
/// 
  this()
  {

  }

/// 
  void setAsset(EXT_TextureAsset* asset, Direction direction)
  {
    final switch (direction)
    {
      case Direction.north: _assetNorth = asset; break;
      case Direction.northWest: _assetWest = asset; break;
      case Direction.northEast: _assetNorthEast = asset; break;
      case Direction.south: _assetSouth = asset; break;
      case Direction.southWest: _assetSouthWest = asset; break;
      case Direction.southEast: _assetSouth = asset; break;
      case Direction.east: _assetEast = asset; break;
      case Direction.west: _assetWest = asset; break;
    }
  }

/// 
  EXT_TextureAsset* getAssetByDirection(Direction direction)
  {
    final switch (direction)
    {
      case Direction.north: return _assetNorth;
      case Direction.northWest:
        if (!_assetNorthWest) return _assetNorth;
        return _assetNorthWest;
      case Direction.northEast:
        if (!_assetNorthEast) return _assetNorth;
        return _assetNorthEast;

      case Direction.south: return _assetSouth;
      case Direction.southWest:
        if (!_assetSouthWest) return _assetSouth;
        return _assetSouthWest;
      case Direction.southEast:
        if (!_assetSouthEast) return _assetSouth;
        return _assetSouthEast;

      case Direction.east: return _assetEast;
      case Direction.west: return _assetWest;
    }
  }
}
