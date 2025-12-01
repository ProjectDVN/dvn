/**
* Copyright (c) 2025 Project DVN
*/
module dvn.json.jsonobject;

import std.traits : isSomeString, isScalarType;
import std.string : format, strip;
import std.array : replace, join, array;
import std.conv : to;
import std.algorithm : map, sort, group;

import dvn.json.conv;

import dvn.json.jsonobjectmember;
import dvn.json.jsontype;

final class Json(S)
if (isSomeString!S)
{
  private:
  alias JsonObject = Json!S;
  alias JsonMapMember = JsonObjectMember!S;

  JsonMapMember[S] _members;
  JsonObject[] _items;
  S _text;
  double _number;
  bool _booleanValue;
  JsonType _jsonType;

  S escapeJsonString(S text)
  {
    return text
      .replace("\\", "\\\\")
      .replace("\t", "\\t")
      .replace("\b", "\\b")
      .replace("\r", "\\r")
      .replace("\n", "\\n")
      .replace("\f", "\\f")
      .replace("\"", "\\\"");
  }

  public:
  this()
  {
    _jsonType = JsonType.jsonNull;
  }

  bool addMember(S key, JsonObject member)
  {
    auto obj = new JsonMapMember(key, _members ? _members.length : 0, member);
    _members[key] = obj;
    _jsonType = JsonType.jsonObject;
    return true;
  }

  bool getMember(S key, out JsonObject member)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      member = null;
      return false;
    }

    if (_jsonType != JsonType.jsonObject)
    {
      member = null;
      return false;
    }

    if (!_members)
    {
      member = null;
      return false;
    }

    auto entry = _members.get(key, null);

    if (entry)
    {
      member = cast(JsonObject)entry.obj;
    }
    else
    {
      member = null;
    }

    return member !is null;
  }

  bool getMembers(out JsonObject[S] members)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      members = typeof(members).init;
      return false;
    }

    if (_jsonType != JsonType.jsonObject)
    {
      members = typeof(members).init;
      return false;
    }

    foreach (k,v; _members)
    {
      members[k] = v.obj;
    }

    return true;
  }

  bool addItem(JsonObject item)
  {
    _items ~= item;
    _jsonType = JsonType.jsonArray;
    return true;
  }

  bool getItem(size_t index, out JsonObject item)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      item = null;
      return false;
    }

    if (_jsonType != JsonType.jsonArray)
    {
      item = null;
      return false;
    }

    if (!_items || _items.length <= index)
    {
      item = null;
      return false;
    }

    item = _items[index];

    return item !is null;
  }

  bool getItems(out JsonObject[] items)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      items = null;
      return false;
    }

    if (_jsonType != JsonType.jsonArray)
    {
      items = null;
      return false;
    }

    items = _items ? _items : [];
    return true;
  }

  bool setText(S text)
  {
    _text = text;
    _jsonType = JsonType.jsonString;
    return true;
  }

  bool getText(out S text)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      text = null;
      return false;
    }

    if (_jsonType != JsonType.jsonString)
    {
      text = null;
      return false;
    }

    text = _text;
    return true;
  }

  bool setNumber(T)(T number)
  if (isScalarType!T)
  {
    double numberValue;
    if (!tryParse(number, numberValue))
    {
      return false;
    }

    _number = numberValue;
    _jsonType = JsonType.jsonNumber;
    return true;
  }

  bool getNumber(T = double)(out T number)
  if (isScalarType!T)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      number = T.init;
      return false;
    }

    if (_jsonType != JsonType.jsonNumber)
    {
      number = T.init;
      return false;
    }

    static if (is(T == double))
    {
      number = _number;
      return true;
    }
    else
    {
      return tryParse(_number, number);
    }
  }

  bool setBoolean(bool booleanValue)
  {
    _booleanValue = booleanValue;
    _jsonType = JsonType.jsonBoolean;
    return true;
  }

  bool getBoolean(out bool value)
  {
    if (_jsonType == JsonType.jsonNull)
    {
      value = false;
      return false;
    }

    if (_jsonType != JsonType.jsonBoolean)
    {
      value = false;
      return false;
    }

    value = _booleanValue;

    return true;
  }

  @property
  {
    JsonType jsonType() { return _jsonType; }

    void jsonType(JsonType newJsonType)
    {
      _jsonType = newJsonType;
    }
  }

  JsonObject opIndex(S key)
  {
    JsonObject obj;
    if (getMember(key, obj))
    {
      return obj;
    }

    return null;
  }

  JsonObject opIndex(size_t index)
  {
    JsonObject obj;
    if (getItem(index, obj))
    {
      return obj;
    }

    return null;
  }

  S toPrettyString(size_t tabCount = 0, bool initTab = true)
  {
    S tabs = "";
    foreach (_; 0 .. tabCount)
    {
      tabs ~= "\t";
    }

    S memberTabs = "";
    foreach (_; 0 .. tabCount + 1)
    {
      memberTabs ~= "\t";
    }

    switch (jsonType)
    {
      case JsonType.jsonNull: return "null";

      case JsonType.jsonBoolean: return _booleanValue.to!S;

      case JsonType.jsonNumber:
        import std.format : format;
        return format!"%.17g"(_number);

      case jsonType.jsonString: return "\"%s\"".format(escapeJsonString(_text)); // TODO: Escape newlines etc.

      case JsonType.jsonObject:
        S obj = (initTab ? tabs : "") ~ "{";
        bool hasMembers = false;

        if (_members)
        {
          auto sortedMembers = _members ? _members.values.sort.group.map!(g => g[0]).array : [];

          S memberStr = join(sortedMembers.map!(m => memberTabs ~ `"%s": %s`.format(m.key, m.obj.toPrettyString(tabCount + 1, false))).array, ",\r\n");

          hasMembers = memberStr.strip.length > 0;

          if (hasMembers)
          {
            obj ~= "\r\n";
            obj ~= memberStr;
            obj ~= "\r\n";
          }
        }

        return obj ~ (hasMembers ? tabs : "") ~ "}";

      case JsonType.jsonArray:
        S arr = (initTab ? tabs : "") ~ "[";
        bool hasItems = false;

        if (_items)
        {
          S itemStr = join(_items.map!(i => memberTabs ~ i.toPrettyString(tabCount + 1, false)).array, ",\r\n");

          hasItems = itemStr.strip.length > 0;

          if (hasItems)
          {
            arr ~= "\r\n";
            arr ~= itemStr;
            arr ~= "\r\n";
          }
        }

        return arr ~ (hasItems ? tabs : "") ~ "]";

      default: return "undefined";
    }
  }

  private
  {
    S toStringImpl()
    {
      switch (jsonType)
      {
        case JsonType.jsonNull: return "null";

        case JsonType.jsonBoolean: return _booleanValue.to!S;

        case JsonType.jsonNumber:
          import std.format : format;
          return format!"%.17g"(_number);

        case jsonType.jsonString: return "\"%s\"".format(escapeJsonString(_text)); // TODO: Escape newlines etc.

        case JsonType.jsonObject:
          S obj = "{";

          if (_members)
          {
            auto sortedMembers = _members ? _members.values.sort.group.map!(g => g[0]).array : [];

            obj ~= join(sortedMembers.map!(m => `"%s":%s`.format(m.key, m.obj.toString())).array, ",");
          }

          return obj ~ "}";

        case JsonType.jsonArray:
          S arr = "[";

          if (_items)
          {
            arr ~= join(_items.map!(i => i.toString).array, ",");
          }

          return arr ~ "]";

        default: return "undefined";
      }
    }
  }

  override string toString()
  {
    return toStringImpl.to!string;
  }
}
