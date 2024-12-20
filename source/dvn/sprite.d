// module dvn.sprite;
//
// import std.string : format;
//
// import dvn.external;
// import dvn.window;
//
// private alias SHEETRENDER_PTR = EXT_SheetRender*;
//
// public enum Direction
// {
//   north,
//   northEast,
//   east,
//   southEast,
//   south,
//   southWest,
//   west,
//   northWest
// }
//
// public final class Sprite
// {
//   private:
//   Surface[] _models;
//   Surface[] _modelsNorth;
//   Direction _direction;
//   IntVector _size;
//   bool _moveState;
//
//   public:
//   this(Surface[] models, Surface[] modelsNorth)
//   {
//     if (!models || !models.length)
//     {
//       throw new Exception("Missing models.");
//     }
//
//     if (models.length != modelsNorth.length)
//     {
//       throw new Exception("The north model doesn't match the regular model.");
//     }
//
//     _direction = Direction.south;
//     _models = models;
//     _modelsNorth = modelsNorth;
//
//     foreach (model; models)
//     {
//       if (model.defaultAsset)
//       {
//         _size = IntVector(model.defaultAsset.entry.rect.w, model.defaultAsset.entry.rect.h);
//         break;
//       }
//     }
//
//     _moveState = false;
//   }
//
//   @property
//   {
//     IntVector size() { return _size; }
//   }
//
//   void resetState()
//   {
//     _moveState = false;
//
//     foreach (model; _models)
//     {
//       model.resetState();
//     }
//   }
//
//   void moveState()
//   {
//     _moveState = !_moveState;
//     if (!_moveState) return;
//
//     foreach (model; _models)
//     {
//       model.moveState();
//     }
//   }
//
//   void setSize(IntVector size)
//   {
//     foreach (model; _models)
//     {
//       model.setSize(size);
//     }
//   }
//
//   void setPosition(IntVector position)
//   {
//     foreach (model; _models)
//     {
//       model.setPosition(position);
//     }
//   }
//
//   void setDirection(Direction direction)
//   {
//     _direction = direction;
//
//     foreach (model; _models)
//     {
//       model.setDirection(direction);
//     }
//   }
//
//   void render(EXT_Window window, EXT_Screen screen)
//   {
//     if (_direction == Direction.north)
//     {
//       foreach (model; _modelsNorth)
//       {
//         model.render(window, screen);
//       }
//     }
//     else
//     {
//       foreach (model; _models)
//       {
//         model.render(window, screen);
//       }
//     }
//   }
// }
//
// public final class Model
// {
//   private:
//   SHEETRENDER_PTR[] _assetsNorth;
//   SHEETRENDER_PTR[] _assetsEast;
//   SHEETRENDER_PTR[] _assetsSouth;
//   SHEETRENDER_PTR[] _assetsWest;
//
//   SHEETRENDER_PTR[] _activeAsset;
//   SHEETRENDER_PTR _sheetRender;
//   size_t _assetIndex;
//   SHEETRENDER_PTR _defaultAsset;
//   Direction _direction;
//
//   public:
//   final:
//   this(Window window, string name)
//   {
//     _assetIndex = 0;
//     _assetsNorth = [];
//     _assetsEast = [];
//     _assetsSouth = [];
//     _assetsWest = [];
//
//     foreach (i; 0 .. 4)
//     {
//       EXT_SheetRender* asset;
//       window.getSheetEntry(format("%s_%s_%s", name, "north", i), asset);
//
//       if (asset)
//       {
//         _assetsNorth ~= asset;
//         if (!_defaultAsset) _defaultAsset = asset;
//       }
//     }
//
//     foreach (i; 0 .. 4)
//     {
//       EXT_SheetRender* asset;
//       window.getSheetEntry(format("%s_%s_%s", name, "east", i), asset);
//
//       if (asset)
//       {
//         _assetsEast ~= asset;
//         if (!_defaultAsset) _defaultAsset = asset;
//       }
//     }
//
//     foreach (i; 0 .. 4)
//     {
//       EXT_SheetRender* asset;
//       window.getSheetEntry(format("%s_%s_%s", name, "south", i), asset);
//
//       if (asset)
//       {
//         _assetsSouth ~= asset;
//         if (!_defaultAsset) _defaultAsset = asset;
//       }
//     }
//
//     foreach (i; 0 .. 4)
//     {
//       EXT_SheetRender* asset;
//       window.getSheetEntry(format("%s_%s_%s", name, "west", i), asset);
//
//       if (asset)
//       {
//         _assetsWest ~= asset;
//         if (!_defaultAsset) _defaultAsset = asset;
//       }
//     }
//   }
//
//   @property
//   {
//     private SHEETRENDER_PTR defaultAsset() { return _defaultAsset; }
//   }
//
//   void setSize(IntVector size)
//   {
//     foreach (asset; _assetsNorth)
//     {
//       asset.entry.rect.w = size.x;
//       asset.entry.rect.h = size.y;
//     }
//
//     foreach (asset; _assetsEast)
//     {
//       asset.entry.rect.w = size.x;
//       asset.entry.rect.h = size.y;
//     }
//
//     foreach (asset; _assetsSouth)
//     {
//       asset.entry.rect.w = size.x;
//       asset.entry.rect.h = size.y;
//     }
//
//     foreach (asset; _assetsWest)
//     {
//       asset.entry.rect.w = size.x;
//       asset.entry.rect.h = size.y;
//     }
//   }
//
//   void setPosition(IntVector position)
//   {
//     foreach (asset; _assetsNorth)
//     {
//       asset.entry.rect.x = position.x;
//       asset.entry.rect.y = position.y;
//     }
//
//     foreach (asset; _assetsEast)
//     {
//       asset.entry.rect.x = position.x;
//       asset.entry.rect.y = position.y;
//     }
//
//     foreach (asset; _assetsSouth)
//     {
//       asset.entry.rect.x = position.x;
//       asset.entry.rect.y = position.y;
//     }
//
//     foreach (asset; _assetsWest)
//     {
//       asset.entry.rect.x = position.x;
//       asset.entry.rect.y = position.y;
//     }
//   }
//
//   void setDirection(Direction direction)
//   {
//     if (_direction == direction) return;
//
//     _direction = direction;
//
//     final switch (_direction)
//     {
//       case Direction.north:
//         _activeAsset = _assetsNorth;
//         break;
//       case Direction.northEast:
//       case Direction.east:
//       case Direction.southEast:
//         _activeAsset = _assetsEast;
//         break;
//       case Direction.south:
//         _activeAsset = _assetsSouth;
//         break;
//       case Direction.southWest:
//       case Direction.west:
//       case Direction.northWest:
//         _activeAsset = _assetsWest;
//         break;
//     }
//
//     resetState();
//   }
//
//   void resetState()
//   {
//     if (!_activeAsset || !_activeAsset.length)
//     {
//       _sheetRender = null;
//       return;
//     }
//
//     _assetIndex = 0;
//
//     _sheetRender = _activeAsset[_assetIndex];
//   }
//
//   void moveState()
//   {
//     if (!_activeAsset || !_activeAsset.length)
//     {
//       _sheetRender = null;
//       return;
//     }
//
//     _assetIndex++;
//
//     if (_assetIndex >= _activeAsset.length)
//     {
//       _assetIndex = 0;
//     }
//
//     _sheetRender = _activeAsset[_assetIndex];
//   }
//
//   void render(EXT_Window window, EXT_Screen screen)
//   {
//     if (!_sheetRender) return;
//
//     EXT_RenderCopy(screen, _sheetRender.texture, _sheetRender.entry.textureRect, _sheetRender.entry.rect);
//   }
// }
