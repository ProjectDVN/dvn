/**
* Copyright (c) 2025 Project DVN
*/
module dvn.json.jsonobjectmember;

import dvn.json.jsonobject;

/// 
final class JsonObjectMember(S)
{
  private:
  alias JsonObject = Json!S;

  size_t _index;
  JsonObject _object;
  S _key;

  public:
/// 
  this(S key, size_t index, JsonObject obj)
  {
    _key = key;
    _index = index;
    _object = obj;
  }

  @property
  {
/// 
    S key() { return _key; }

/// 
    size_t index() { return _index; }

/// 
    JsonObject obj() { return _object; }
  }

/// 
  override int opCmp(Object o)
  {
    auto obj = cast(JsonObjectMember!S)o;

    if (!obj)
    {
      return -1;
    }

    if (_index > obj._index)
    {
      return 1;
    }

    if (_index < obj._index)
    {
      return -1;
    }

    return 0;
  }

  /// Operator overload.
  override bool opEquals(Object o)
  {
    return opCmp(o) == 0;
  }
}
