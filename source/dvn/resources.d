/**
* Copyright (c) 2025 Project DVN
*/
module dvn.resources;

import std.file : dirEntries, SpanMode;
import std.path : baseName, CaseSensitive;

import dvn.meta;
import dvn.json;

/// 
mixin CreateCustomException!"ResourceException";

/// 
public final class Resource
{
  public:
  final:
/// 
  this() {}
/// 
  string path;
/// 
  string[] randomPath;
/// 
  ResourceSize size;
/// 
  int columns;
/// 
  ResourceEntry[] entries;
/// 
  string[] directions;
/// 
  @JsonIgnore ubyte[] buffer;
}

/// 
public final class ResourceSize
{
  public:
  final:
/// 
  this() {}
/// 
  int width;
/// 
  int height;
}

/// 
public final class ResourceEntry
{
  public:
  final:
/// 
  this() {}
/// 
  string name;
/// 
  int row;
/// 
  int col;
}

private Resource[string] _resources;

/// 
Resource[string] getResources()
{
  return _resources;
}

/// 
void appendResources(Resource[string] originalResources, string path)
{
  import std.file : readText;
  import dvn.json;

  string text = readText(path);
  string[] errorMessages;
  Resource[string] resources;
  if (!deserializeJsonSafe!(Resource[string])(text, resources, errorMessages))
  {
    throw new ResourceException(errorMessages[0]);
  }

  foreach (k,v; resources)
  {
    originalResources[k] = v;
  }
}

/// 
Resource[string] loadResources(string path = "", bool forceLoadResource = false)
{
  if ((!forceLoadResource && _resources) || !path || !path.length)
  {
    return _resources;
  }

  import std.file : readText;
  import dvn.json;

  string text = readText(path);
  string[] errorMessages;
  Resource[string] resources;
  if (!deserializeJsonSafe!(Resource[string])(text, resources, errorMessages))
  {
    throw new ResourceException(errorMessages[0]);
  }

  if (!forceLoadResource) _resources = resources;
  return resources;
}

/// 
string[] addResourcesFromFolder(Resource[string] resources, string path, string prefix, int width, int height)
{
  string[] resourceNames = [];

  auto resourceFiles1 = dirEntries(path,"*.{png}",SpanMode.depth);
  auto resourceFiles2 = dirEntries(path,"*.{jpg}",SpanMode.depth);

  foreach (resourceFile; resourceFiles1)
  {
    auto resourceFileName = baseName!(CaseSensitive.no)(resourceFile, ".png");

    auto resource = new Resource;
    resource.path = resourceFile;
    resource.size = new ResourceSize;
    resource.size.width = width;
    resource.size.height = height;
    resource.columns = 1;
    resource.entries = new ResourceEntry[1];
    resource.entries[0] = new ResourceEntry;
    resource.entries[0].name = prefix ~ resourceFileName;
    resource.entries[0].row = 0;
    resource.entries[0].col = 0;

    resources[resource.entries[0].name] = resource;

    resourceNames ~= resource.entries[0].name;
  }
  
  foreach (resourceFile; resourceFiles2)
  {
    auto resourceFileName = baseName!(CaseSensitive.no)(resourceFile, ".jpg");

    auto resource = new Resource;
    resource.path = resourceFile;
    resource.size = new ResourceSize;
    resource.size.width = width;
    resource.size.height = height;
    resource.columns = 1;
    resource.entries = new ResourceEntry[1];
    resource.entries[0] = new ResourceEntry;
    resource.entries[0].name = prefix ~ resourceFileName;
    resource.entries[0].row = 0;
    resource.entries[0].col = 0;

    resources[resource.entries[0].name] = resource;

    resourceNames ~= resource.entries[0].name;
  }

  return resourceNames;
}
