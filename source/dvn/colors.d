/**
* Copyright (c) 2025 Project DVN
*/
module dvn.colors;

public import dvn.external : Color;
import dvn.meta;

mixin CreateCustomException!"ColorException";

private
{
  struct ColorData
  {
    int r;
    int g;
    int b;
    string hex;
    string name;
  }

  ColorData[] getColorData()
  {
    ColorData[] data = [];

    data ~= ColorData
    (
      0xff, 0xff, 0xff,
      "ffffff","white"
    );

    data ~= ColorData
    (
      0x00, 0x00, 0x00,
      "000000","black"
    );

    data ~= ColorData
    (
      0xff, 0x00, 0x00,
      "ff0000","red"
    );

    data ~= ColorData
    (
      0xff, 0x66, 0x66,
      "ff6666","redlight"
    );

    data ~= ColorData
    (
      0x00, 0xff, 0x00,
      "00ff00","green"
    );

    data ~= ColorData
    (
      0x00, 0x00, 0xff,
      "0000ff","blue"
    );

    data ~= ColorData
    (
      0x66, 0x66, 0xff,
      "6666ff","bluelight"
    );

    return data;
  }
}

Color getColorByHex(string hex)
{
  import std.conv : to;

  if (!hex || !hex.length)
  {
    throw new ColorException("Missing hex input.");
  }

  string hexR = "";
  string hexG = "";
  string hexB = "";
  string hexA = "";
  if (hex.length == 1)
  {
    hexR = hex[0].to!string ~ hex[0].to!string;
    hexG = hex[0].to!string ~ hex[0].to!string;
    hexB = hex[0].to!string ~ hex[0].to!string;
    hexA = "ff";
  }
  else if (hex.length == 2)
  {
    hexR = hex[0].to!string ~ hex[0].to!string;
    hexG = hex[0].to!string ~ hex[0].to!string;
    hexB = hex[0].to!string ~ hex[0].to!string;
    hexA = hex[1].to!string ~ hex[1].to!string;
  }
  else if (hex.length == 3)
  {
    hexR = hex[0].to!string ~ hex[0].to!string;
    hexG = hex[1].to!string ~ hex[1].to!string;
    hexB = hex[2].to!string ~ hex[2].to!string;
    hexA = "ff";
  }
  else if (hex.length == 4)
  {
    hexR = hex[0].to!string ~ hex[0].to!string;
    hexG = hex[1].to!string ~ hex[1].to!string;
    hexB = hex[2].to!string ~ hex[2].to!string;
    hexA = hex[3].to!string ~ hex[3].to!string;
  }
  else if (hex.length == 6)
  {
    hexR = hex[0].to!string ~ hex[1].to!string;
    hexG = hex[2].to!string ~ hex[3].to!string;
    hexB = hex[4].to!string ~ hex[5].to!string;
    hexA = "ff";
  }
  else if (hex.length == 8)
  {
    hexR = hex[0].to!string ~ hex[1].to!string;
    hexG = hex[2].to!string ~ hex[3].to!string;
    hexB = hex[4].to!string ~ hex[5].to!string;
    hexA = hex[6].to!string ~ hex[7].to!string;
  }

  if (hexR == "" || hexG == "" || hexB == "" || hexA == "")
  {
    throw new ColorException("Missing hex value(s).");
  }

  ubyte r = to!ubyte(hexR, 16);
  ubyte g = to!ubyte(hexG, 16);
  ubyte b = to!ubyte(hexB, 16);
  ubyte a = to!ubyte(hexA, 16);

  return getColorByRGB(r,g,b,a);
}

Color getColorByInteger(uint integer)
{
  return Color(
    cast(ubyte)(integer >> 24),
    cast(ubyte)(integer >> 16),
    cast(ubyte)(integer >> 8),
    cast(ubyte)integer);
}

uint getIntegerByColor(Color color)
{
    int ret = 0;

    ret <<= 8;
    ret |= cast(int)color.r & 0xFF;

    ret <<= 8;
    ret |= cast(int)color.g & 0xFF;

    ret <<= 8;
    ret |= cast(int)color.b & 0xFF;

    ret <<= 8;
    ret |= cast(int)color.a & 0xFF;

    return cast(uint)ret;
}

string getHexByColor(Color color)
{
  import std.string : format;

  auto hex = format("%.8x", color.getIntegerByColor);

  return hex;
}

string getNameByColor(Color color)
{
  import std.string : format;

  if (color.a == 0x00)
  {
    return "transparent";
  }

  auto colorCombination = color.getHexByColor[0 .. $-2];

  switch (colorCombination)
  {
    static foreach (data; getColorData)
    {
      mixin(format(`case "%s": return "%s";`, data.hex, data.name));
    }

    default: return "N/A";
  }
}

Color getColorByName(string name, int alpha = 0xff)
{
  Color transparent() { return getColorByRGB(0x00, 0x00, 0x00, 0x00); }

	if (!name || !name.length)
	{
		return transparent();
	}

	import std.string : strip,toLower;

	switch (name.strip.toLower)
	{
    static foreach (data; getColorData)
    {
      mixin(format(`case "%s": return getColorByRGB(%s, %s, %s, alpha);`, data.name, data.r, data.g, data.b));
    }

		case "transparent":
		default:
      return transparent();
	}
}

Color getColorByRGB(int r, int g, int b, int a = 0xff)
{
	return Color(cast(ubyte)r,cast(ubyte)g,cast(ubyte)b,cast(ubyte)a);
}

Color changeAlpha(Color color, int a)
{
  return Color(color.r, color.g, color.b, cast(ubyte)a);
}