/**
* Copyright (c) 2025 Project DVN
*/
module dvn.bundling;

import std.file : write,read,dirEntries,SpanMode,exists,remove,readText;
import std.string : representation;

import dvn.events;

private string _script;

string getBundleScript()
{
  return _script ? _script : "";
}

bool hasScriptBundle()
{
  return exists("data/scripts.dat");
}

void readBundleScript()
{
  if (!hasScriptBundle) return;

  ubyte[] data = cast(ubyte[])read("data/scripts.dat");

  data = DvnEvents.getEvents().scriptBundleRead(data.dup).dup;

  _script = cast(string)data;
}

void writeBundleScript()
{
  if (!exists("bundle.txt"))
  {
    return;
  }

  auto scriptFiles = dirEntries("data/game/scripts","*.{vns}",SpanMode.depth);

  foreach (scriptFile; scriptFiles)
  {
    auto scriptText = readText(scriptFile);

    _script ~= scriptText ~ "\r\n";
  }

  auto buffer = representation(_script);

  buffer = DvnEvents.getEvents().scriptBundleWrite(buffer.dup).dup;

  write("data/scripts.dat", buffer);
  
  remove("bundle.txt");
}