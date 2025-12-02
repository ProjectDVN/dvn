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
    
    data ~= ColorData(240,248,255,"f0f8ff","aliceblue");
    data ~= ColorData(250,235,215,"faebd7","antiquewhite");
    data ~= ColorData(127,255,212,"7fffd4","aquamarine");
    data ~= ColorData(240,255,255,"f0ffff","azure");
    data ~= ColorData(245,245,220,"f5f5dc","beige");
    data ~= ColorData(255,228,196,"ffe4c4","bisque");
    data ~= ColorData(0,0,0,"000000","black");
    data ~= ColorData(255,235,205,"ffebcd","blanchedalmond");
    data ~= ColorData(0,0,255,"0000ff","blue");
    data ~= ColorData(138,43,226,"8a2be2","blueviolet");
    data ~= ColorData(165,42,42,"a52a2a","brown");
    data ~= ColorData(222,184,135,"deb887","burlywood");
    data ~= ColorData(95,158,160,"5f9ea0","cadetblue");
    data ~= ColorData(127,255,0,"7fff00","chartreuse");
    data ~= ColorData(210,105,30,"d2691e","chocolate");
    data ~= ColorData(255,127,80,"ff7f50","coral");
    data ~= ColorData(100,149,237,"6495ed","cornflowerblue");
    data ~= ColorData(255,248,220,"fff8dc","cornsilk");
    data ~= ColorData(220,20,60,"dc143c","crimson");
    data ~= ColorData(0,255,255,"00ffff","cyan");
    data ~= ColorData(0,0,139,"00008b","darkblue");
    data ~= ColorData(0,139,139,"008b8b","darkcyan");
    data ~= ColorData(184,134,11,"b8860b","darkgoldenrod");
    data ~= ColorData(169,169,169,"a9a9a9","darkgray");
    data ~= ColorData(0,100,0,"006400","darkgreen");
    data ~= ColorData(189,183,107,"bdb76b","darkkhaki");
    data ~= ColorData(139,0,139,"8b008b","darkmagenta");
    data ~= ColorData(85,107,47,"556b2f","darkolivegreen");
    data ~= ColorData(255,140,0,"ff8c00","darkorange");
    data ~= ColorData(153,50,204,"9932cc","darkorchid");
    data ~= ColorData(139,0,0,"8b0000","darkred");
    data ~= ColorData(233,150,122,"e9967a","darksalmon");
    data ~= ColorData(143,188,143,"8fbc8f","darkseagreen");
    data ~= ColorData(72,61,139,"483d8b","darkslateblue");
    data ~= ColorData(47,79,79,"2f4f4f","darkslategray");
    data ~= ColorData(0,206,209,"00ced1","darkturquoise");
    data ~= ColorData(148,0,211,"9400d3","darkviolet");
    data ~= ColorData(255,20,147,"ff1493","deeppink");
    data ~= ColorData(0,191,255,"00bfff","deepskyblue");
    data ~= ColorData(105,105,105,"696969","dimgray");
    data ~= ColorData(30,144,255,"1e90ff","dodgerblue");
    data ~= ColorData(178,34,34,"b22222","firebrick");
    data ~= ColorData(255,250,240,"fffaf0","floralwhite");
    data ~= ColorData(34,139,34,"228b22","forestgreen");
    data ~= ColorData(220,220,220,"dcdcdc","gainsboro");
    data ~= ColorData(248,248,255,"f8f8ff","ghostwhite");
    data ~= ColorData(255,215,0,"ffd700","gold");
    data ~= ColorData(218,165,32,"daa520","goldenrod");
    data ~= ColorData(128,128,128,"808080","gray");
    data ~= ColorData(0,128,0,"008000","green");
    data ~= ColorData(173,255,47,"adff2f","greenyellow");
    data ~= ColorData(240,255,240,"f0fff0","honeydew");
    data ~= ColorData(255,105,180,"ff69b4","hotpink");
    data ~= ColorData(205,92,92,"cd5c5c","indianred");
    data ~= ColorData(75,0,130,"4b0082","indigo");
    data ~= ColorData(255,255,240,"fffff0","ivory");
    data ~= ColorData(240,230,140,"f0e68c","khaki");
    data ~= ColorData(230,230,250,"e6e6fa","lavender");
    data ~= ColorData(255,240,245,"fff0f5","lavenderblush");
    data ~= ColorData(124,252,0,"7cfc00","lawngreen");
    data ~= ColorData(255,250,205,"fffacd","lemonchiffon");
    data ~= ColorData(173,216,230,"add8e6","lightblue");
    data ~= ColorData(240,128,128,"f08080","lightcoral");
    data ~= ColorData(224,255,255,"e0ffff","lightcyan");
    data ~= ColorData(250,250,210,"fafad2","lightgoldenrodyellow");
    data ~= ColorData(211,211,211,"d3d3d3","lightgray");
    data ~= ColorData(144,238,144,"90ee90","lightgreen");
    data ~= ColorData(255,182,193,"ffb6c1","lightpink");
    data ~= ColorData(255,160,122,"ffa07a","lightsalmon");
    data ~= ColorData(32,178,170,"20b2aa","lightseagreen");
    data ~= ColorData(135,206,250,"87cefa","lightskyblue");
    data ~= ColorData(119,136,153,"778899","lightslategray");
    data ~= ColorData(176,196,222,"b0c4de","lightsteelblue");
    data ~= ColorData(255,255,224,"ffffe0","lightyellow");
    data ~= ColorData(0,255,0,"00ff00","lime");
    data ~= ColorData(50,205,50,"32cd32","limegreen");
    data ~= ColorData(250,240,230,"faf0e6","linen");
    data ~= ColorData(255,0,255,"ff00ff","magenta");
    data ~= ColorData(128,0,0,"800000","maroon");
    data ~= ColorData(102,205,170,"66cdaa","mediumaquamarine");
    data ~= ColorData(0,0,205,"0000cd","mediumblue");
    data ~= ColorData(186,85,211,"ba55d3","mediumorchid");
    data ~= ColorData(147,112,219,"9370db","mediumpurple");
    data ~= ColorData(60,179,113,"3cb371","mediumseagreen");
    data ~= ColorData(123,104,238,"7b68ee","mediumslateblue");
    data ~= ColorData(0,250,154,"00fa9a","mediumspringgreen");
    data ~= ColorData(72,209,204,"48d1cc","mediumturquoise");
    data ~= ColorData(199,21,133,"c71585","mediumvioletred");
    data ~= ColorData(25,25,112,"191970","midnightblue");
    data ~= ColorData(245,255,250,"f5fffa","mintcream");
    data ~= ColorData(255,228,225,"ffe4e1","mistyrose");
    data ~= ColorData(255,228,181,"ffe4b5","moccasin");
    data ~= ColorData(255,222,173,"ffdead","navajowhite");
    data ~= ColorData(0,0,128,"000080","navy");
    data ~= ColorData(253,245,230,"fdf5e6","oldlace");
    data ~= ColorData(128,128,0,"808000","olive");
    data ~= ColorData(107,142,35,"6b8e23","olivedrab");
    data ~= ColorData(255,165,0,"ffa500","orange");
    data ~= ColorData(255,69,0,"ff4500","orangered");
    data ~= ColorData(218,112,214,"da70d6","orchid");
    data ~= ColorData(238,232,170,"eee8aa","palegoldenrod");
    data ~= ColorData(152,251,152,"98fb98","palegreen");
    data ~= ColorData(175,238,238,"afeeee","paleturquoise");
    data ~= ColorData(219,112,147,"db7093","palevioletred");
    data ~= ColorData(255,239,213,"ffefd5","papayawhip");
    data ~= ColorData(255,218,185,"ffdab9","peachpuff");
    data ~= ColorData(205,133,63,"cd853f","peru");
    data ~= ColorData(255,192,203,"ffc0cb","pink");
    data ~= ColorData(221,160,221,"dda0dd","plum");
    data ~= ColorData(176,224,230,"b0e0e6","powderblue");
    data ~= ColorData(128,0,128,"800080","purple");
    data ~= ColorData(255,0,0,"ff0000","red");
    data ~= ColorData(188,143,143,"bc8f8f","rosybrown");
    data ~= ColorData(65,105,225,"4169e1","royalblue");
    data ~= ColorData(139,69,19,"8b4513","saddlebrown");
    data ~= ColorData(250,128,114,"fa8072","salmon");
    data ~= ColorData(244,164,96,"f4a460","sandybrown");
    data ~= ColorData(46,139,87,"2e8b57","seagreen");
    data ~= ColorData(255,245,238,"fff5ee","seashell");
    data ~= ColorData(160,82,45,"a0522d","sienna");
    data ~= ColorData(192,192,192,"c0c0c0","silver");
    data ~= ColorData(135,206,235,"87ceeb","skyblue");
    data ~= ColorData(106,90,205,"6a5acd","slateblue");
    data ~= ColorData(112,128,144,"708090","slategray");
    data ~= ColorData(255,250,250,"fffafa","snow");
    data ~= ColorData(0,255,127,"00ff7f","springgreen");
    data ~= ColorData(70,130,180,"4682b4","steelblue");
    data ~= ColorData(210,180,140,"d2b48c","tan");
    data ~= ColorData(0,128,128,"008080","teal");
    data ~= ColorData(216,191,216,"d8bfd8","thistle");
    data ~= ColorData(255,99,71,"ff6347","tomato");
    data ~= ColorData(64,224,208,"40e0d0","turquoise");
    data ~= ColorData(238,130,238,"ee82ee","violet");
    data ~= ColorData(245,222,179,"f5deb3","wheat");
    data ~= ColorData(255,255,255,"ffffff","white");
    data ~= ColorData(245,245,245,"f5f5f5","whitesmoke");
    data ~= ColorData(255,255,0,"ffff00","yellow");
    data ~= ColorData(154,205,50,"9acd32","yellowgreen");

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