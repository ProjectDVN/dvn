/**
* Copyright (c) 2025 Project DVN
*/
module dvn.atlas;

import dvn.external;
import dvn.meta;
import dvn.surface;

mixin CreateCustomException!"AtlasException";

public final class AtlasInformation
{
  public:
  final:
  this() {}
  size_t pages;
  size_t textureCount;
}

public final class AtlasTextureCollection
{
  public:
  final:
  this() {}
  string name;
  AtlasTexture[] textures;
}

public final class AtlasTexture
{
  public:
  final:
  this() {}
  string name;
  Rectangle rect;
  size_t columns;
}

public final class AtlasTextureEntry
{
  private:
  string _atlasName;
  size_t _page;
  AtlasTexture _texture;

  public:
  final:
  this(string atlasName, size_t page, AtlasTexture texture)
  {
    _atlasName = atlasName;
    _page = page;
    _texture = texture;
  }

  EXT_TextureAsset* createAsset()
  {
    return EXT_GetTextureAsset(_atlasName, cast(int)_page, _texture.rect, cast(int)_texture.columns);
  }
}

public final class AtlasSurfaceCollection
{
  private:
  AtlasTextureEntry[string] _entries;

  public:
  final:
  void addEntry(string name, AtlasTextureEntry entry)
  {
    _entries[name] = entry;
  }

  private EXT_TextureAsset* createAsset(string name, string action, Direction direction)
  {
    import std.conv : to;

    return createAsset(format("%s_%s_%s", name, action, direction.to!string));
  }

  private EXT_TextureAsset* createAsset(string name)
  {
    auto asset = _entries.get(name, null);

    if (!asset) return null;

    return asset.createAsset();
  }

  Surface createStaticSurface(string name)
  {
    auto surface = new Surface;

    surface.createAsset(name);

    auto asset = createAsset(name);

    surface.setAsset(asset, Direction.south, "default");

    return surface;
  }

  Surface createSurface(string name, string[] actions, Direction[] directions)
  {
    auto surface = new Surface;

    foreach (action; actions)
    {
      surface.createAsset(action);

      foreach (direction; directions)
      {
        auto asset = createAsset(name, action, direction);

        surface.setAsset(asset, direction, action);
      }
    }

    return surface;
  }
}

private AtlasSurfaceCollection[string] _atlases;

AtlasSurfaceCollection getAtlas(string name)
{
  return _atlases.get(name, null);
}

AtlasSurfaceCollection loadImage(EXT_Screen screen, string path, IntVector size)
{
  EXT_InitializeTextureAtlas(path, 1);

  auto collection = new AtlasSurfaceCollection;

  EXT_AddTextureAtlasPage(screen, path, path, 0);

  auto texture = new AtlasTexture;
  texture.name = path;
  texture.rect = Rectangle(0,0,size.x,size.y);
  texture.columns = 1;

  collection.addEntry(texture.name, new AtlasTextureEntry(path, 0, texture));

  _atlases[path] = collection;

  return collection;
}

Surface getImage(EXT_Screen screen, string path, IntVector size)
{
  auto atlas = _atlases.get(path, null);

  if (!atlas)
  {
    atlas = loadImage(screen, path, size);
  }

  if (!atlas)
  {
    return null;
  }

  auto surface = atlas.createStaticSurface(path);

  surface.setAction("default", Direction.south, true);

  return surface;
}

void loadAtlas(EXT_Screen screen, string path, string name)
{
  if (!path || !path.length || !name || !name.length)
  {
    return;
  }

  import std.file : readText;
  import dvn.json;

  string text = readText(format("%s/%s.json", path, name));
  string[] errorMessages;
  AtlasInformation atlasInformation;
  if (!deserializeJsonSafe!(AtlasInformation)(text, atlasInformation, errorMessages))
  {
    throw new AtlasException(errorMessages[0]);
  }

  if (!atlasInformation)
  {
    return;
  }

  EXT_InitializeTextureAtlas(name, cast(int)atlasInformation.pages);

  auto collection = new AtlasSurfaceCollection;

  foreach (page; 0 .. atlasInformation.pages)
  {
    text = readText(format("%s/%s_%s.json", path, name, page+1));

    AtlasTextureCollection atlasPage;
    if (!deserializeJsonSafe!(AtlasTextureCollection)(text, atlasPage, errorMessages))
    {
      throw new AtlasException(errorMessages[0]);
    }

    EXT_AddTextureAtlasPage(screen, name, format("%s/%s_%s.png", path, name, page+1), cast(int)page);

    foreach (texture; atlasPage.textures)
    {
      collection.addEntry(texture.name, new AtlasTextureEntry(name, page, texture));
    }
  }

  _atlases[name] = collection;
}
