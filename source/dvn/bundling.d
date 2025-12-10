/**
* Copyright (c) 2025 Project DVN
*/
module dvn.bundling;

import std.file : write,read,dirEntries,SpanMode,exists,remove,readText,append;
import std.stdio : File;
import std.string : representation;
import std.path : baseName;

import dvn.events;
import dvn.resources;

private string _script;

/// 
string getBundleScript()
{
  return _script ? _script : "";
}

/// 
bool hasScriptBundle()
{
  return exists("data/scripts.dvn");
}

/// 
void readBundleScript()
{
  if (!hasScriptBundle) return;

  ubyte[] data = cast(ubyte[])read("data/scripts.dvn");

  data = DvnEvents.getEvents().scriptBundleRead(data.dup).dup;

  _script = cast(string)data;
}

/// 
bool writeBundleScript()
{
  if (!exists("bundle.txt"))
  {
    return false;
  }

  auto scriptFiles = dirEntries("data/game/scripts","*.{vns}",SpanMode.depth);

  foreach (scriptFile; scriptFiles)
  {
    import std.array : replace, split;
    
    auto scriptText = readText(scriptFile);
    auto scriptBaseName = baseName(scriptFile).split(".")[0];

    _script ~= scriptText
      .replace("[*", "[" ~ scriptBaseName)
      .replace(":*", ":" ~ scriptBaseName)
       ~ "\r\n";
  }

  auto buffer = representation(_script);

  buffer = DvnEvents.getEvents().scriptBundleWrite(buffer.dup).dup;

  write("data/scripts.dvn", buffer);

  return true;
}

/// 
bool hasImageBundle()
{
  return exists("data/images.dvn");
}

/// 
bool streamBundleImages(void delegate(string name, ubyte[] buffer) handler)
{
  if (!hasImageBundle)
  {
    return false;
  }

  File file = File("data/images.dvn", "rb");
  scope(exit) file.close();

  auto cursor = 0UL;
  auto length = file.size;

  file.rawRead(new ubyte[4]);
  cursor += 4;
  file.seek(cursor);
  file.rawRead(new ubyte[4]);
  cursor += 4;
  file.seek(cursor);

  T read(T)()
  {
    T value;
    file.rawRead((&value)[0 .. 1]);
    cursor += T.sizeof;
    return value;
  }

  while (file.isOpen && cursor < length)
  {
    auto nameLength = read!uint;
    if (nameLength == 0 || cursor + nameLength > length)
    {
        break;
    }
    auto nameBuffer = new ubyte[nameLength];
    nameBuffer = file.rawRead(nameBuffer[]);
    nameBuffer = DvnEvents.getEvents().imageBundleRead(nameBuffer.dup, true).dup;
    auto name = cast(string)nameBuffer;
    cursor += nameLength;
    file.seek(cursor);
    auto dataLength = read!uint;
    if (dataLength == 0 || cursor + dataLength > length)
    {
        break;
    }
    auto buffer = new ubyte[dataLength];
    buffer = file.rawRead(buffer[]);
    buffer = DvnEvents.getEvents().imageBundleRead(buffer.dup, false).dup;
    cursor += dataLength;
    file.seek(cursor);

    handler(name, buffer);  
  }

  return true;
}

/// 
bool writeBundleImages(Resource[string] resources)
{
    if (!exists("bundle.txt"))
    {
        return false;
    }

    string bundlePath = "data/images.dvn";

    File f = File(bundlePath, "wb");
    scope(exit) f.close();

    ubyte[4] magic = ['D', 'V', 'N', 'B'];
    f.rawWrite(magic[]);

    uint versionValue = 1;
    f.rawWrite((&versionValue)[0 .. 1]);

    foreach (name, resource; resources)
    {
        if (resource.columns > 0)                              continue;
        if (resource.randomPath && resource.randomPath.length) continue;
        if (resource.directions && resource.directions.length) continue;
        if (resource.entries && resource.entries.length)       continue;

        string imagePath = resource.path;

        if (!exists(imagePath))
            continue;

        ubyte[] nameBuffer = cast(ubyte[]) name;
        nameBuffer = DvnEvents.getEvents().imageBundleWrite(nameBuffer.dup, true).dup;
        uint nameLen = cast(uint) nameBuffer.length;

        ubyte[] data = cast(ubyte[])read(imagePath);
        data = DvnEvents.getEvents().imageBundleWrite(data.dup, false).dup;
        uint dataLen = cast(uint) data.length;

        f.rawWrite((&nameLen)[0 .. 1]);
        f.rawWrite(nameBuffer[]);

        f.rawWrite((&dataLen)[0 .. 1]);
        f.rawWrite(data[]);
    }

    return true;
}

/// 
void clearBundling()
{
  if (exists("bundle.txt"))
  {
    remove("bundle.txt");
  }
}