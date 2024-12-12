module zid.json.serialization;

import std.traits : hasUDA, FieldNameTuple, getUDAs, moduleName, isSomeString, isScalarType, isArray, isAssociativeArray;
import std.string : format;
import std.algorithm : map;
import std.array : join, array;

import zid.json.parser;
import zid.json.jsonobject;
import zid.json.jsontype;
import zid.json.meta;

struct JsonIgnore {}

struct JsonRequired {}

struct JsonField { string fieldName; }

struct JsonRead { string handler; }

struct JsonWrite { string handler; }

T deserializeJson(T,S = string)(S jsonString)
if (isSomeString!S)
{
  T value;
  S[] errorMessages;

  if (deserializeJsonSafe(jsonString, value, errorMessages))
  {
    return value;
  }

  return T.init;
}

bool deserializeJsonSafe(T,S = string)(S jsonString, out T value, out S[] errorMessages)
if (isSomeString!S)
{
  Json!S json;

  if (!parseJsonSafe(jsonString, json, errorMessages))
  {
    value = T.init;
    return false;
  }

  return deserializeJsonObjectSafe(json, value, errorMessages);
}

T deserializeJsonObject(T,S = string)(Json!S json)
{
  T value;
  S[] errorMessages;

  if (deserializeJsonObjectSafe(json, value, errorMessages))
  {
    return value;
  }

  return T.init;
}

bool deserializeJsonObjectSafe(T,S = string)(Json!S json, out T value, out S[] errorMessages)
{
  static if (is(T == class) || is(T == struct))
  {
    if (json.jsonType == JsonType.jsonNull)
    {
      value = T.init;
    }
    else if (json.jsonType != JsonType.jsonObject)
    {
      errorMessages ~= "Value is not an object.";
      return false;
    }
    else
    {
      static if (is(T == class))
      {
        value = new T;
      }
      else
      {
        value = T.init;
      }

      mixin("import " ~ moduleName!T ~ ";");

      const memberFormat = q{
        {
          %s
        }
      };

      mixin HandleFields!(T, q{{
        enum hasJsonIgnore = hasUDA!({{fullName}}, JsonIgnore);

        static if (!hasJsonIgnore)
        {
          enum hasJsonRequired = hasUDA!({{fullName}}, JsonRequired);

          {
            enum hasJsonField = hasUDA!({{fullName}}, JsonField);

            static if (hasJsonField)
            {
              mixin("enum rawJsonFieldAttribute = getUDAs!(%s, JsonField)[0];".format("{{fullName}}"));

              const S rawFieldName = rawJsonFieldAttribute.fieldName;
            }
            else
            {
              const S rawFieldName = "{{fieldName}}";
            }

            Json!S rawMember;
            if (json.getMember(rawFieldName, rawMember))
            {
              enum hasJsonRead = hasUDA!({{fullName}}, JsonRead);

              static if (hasJsonRead)
              {
                mixin("enum rawJsonReadAttribute = getUDAs!(%s, JsonRead)[0];".format("{{fullName}}"));

                mixin("value." ~ rawJsonReadAttribute.handler ~ "(rawMember);");
              }
              else
              {
                typeof({{fullName}}) rawValue;
                if (deserializeJsonObjectSafe!(typeof(rawValue))(rawMember, rawValue, errorMessages))
                {
                  value.{{fieldName}} = rawValue;
                }
                else if (hasJsonRequired)
                {
                  errorMessages ~= "Requried field from json has invalid type or value: %s".format("{{fieldName}}");
                }
              }
            }
            else if (hasJsonRequired)
            {
              errorMessages ~= "Requried field missing from json: %s".format("{{fieldName}}");
            }
          }
        }
      }});

      mixin(memberFormat.format(handleThem()));
    }

    return !errorMessages || !errorMessages.length;
  }
  else static if (isSomeString!T)
  {
    static if (is(T == S))
    {
      if (!json.getText(value))
      {
        errorMessages ~= "Value is not a string of type %s.".format(S.stringof);
        return false;
      }

      return !errorMessages || !errorMessages.length;
    }
    else
    {
      errorMessages ~= "Value is not a string of type %s.".format(S.stringof);
      return false;
    }
  }
  else static if (isArray!T)
  {
    if (json.jsonType == JsonType.jsonNull)
    {
      value = T.init;
    }
    else
    {
      Json!S[] items;
      if (!json.getItems(items))
      {
        errorMessages ~= "Missing items from json object.";
        return false;
      }

      foreach (item; items)
      {
        import std.range.primitives : ElementType;

        ElementType!T itemValue;
        if (deserializeJsonObjectSafe!(typeof(itemValue))(item, itemValue, errorMessages))
        {
          value ~= itemValue;
        }
      }
    }

    return !errorMessages || !errorMessages.length;
  }
  else static if (isAssociativeArray!T)
  {
    static if (!is(ArrayElementType!(typeof(T.init.keys)) == S))
    {
      errorMessages ~= "Associative Array key is not a string of type %s.".format(S.stringof);
      return false;
    }
    else static if (isSomeString!(ArrayElementType!(typeof(T.init.values))) && !is(ArrayElementType!(typeof(T.init.values)) == S))
    {
      errorMessages ~= "Associative Array value is not a string of type %s.".format(S.stringof);
      return false;
    }
    else
    {
      if (json.jsonType == JsonType.jsonNull)
      {
        value = T.init;
      }
      else
      {
        Json!S[S] members;
        if (!json.getMembers(members))
        {
          errorMessages ~= "Missing members from json object.";
          return false;
        }

        foreach (key,member; members)
        {
          ArrayElementType!(typeof(T.init.values)) memberValue;
          if (deserializeJsonObjectSafe!(typeof(memberValue))(member, memberValue, errorMessages))
          {
            value[key] = memberValue;
          }
        }
      }

      return !errorMessages || !errorMessages.length;
    }
  }
  else static if (is(T == bool))
  {
    if (!json.getBoolean(value))
    {
      errorMessages ~= "Value is not a boolean.";
      return false;
    }

    return !errorMessages || !errorMessages.length;
  }
  else static if (isScalarType!T)
  {
    if (!json.getNumber(value))
    {
      errorMessages ~= "Value is not a number.";
      return false;
    }

    return !errorMessages || !errorMessages.length;
  }
  else
  {
    errorMessages ~= "Undefined value.";
    return false;
  }
}

S serializeJson(T,S = string)(T value, bool pretty = false)
{
  S jsonString;
  if (serializeJsonSafe(value, jsonString, pretty))
  {
    return jsonString;
  }

  return null;
}

bool serializeJsonSafe(T,S = string)(T value, out S jsonString, bool pretty = false)
{
  Json!S json;
  if (!serializeJsonObjectSafe(value, json))
  {
    jsonString = null;
    return false;
  }

  if (pretty)
  {
    jsonString = json.toPrettyString;
  }
  else
  {
    jsonString = json.toString;
  }

  return true;
}

Json!S serializeJsonObject(T,S = string)(T value)
{
  Json!S json;
  if (serializeJsonObjectSafe(value, json))
  {
    return json;
  }

  return null;
}

bool serializeJsonObjectSafe(T,S = string)(T value, out Json!S json)
{
  json = new Json!S;

  static if (is(T == class) || is(T == struct))
  {
    static if (is(T == class))
    {
      if (value is null)
      {
        json.jsonType = JsonType.jsonNull;
        return true;
      }
    }

    mixin("import " ~ moduleName!T ~ ";");

    const memberFormat = q{
      {
        %s
      }
    };

    mixin HandleFields!(T, q{{
      enum hasJsonIgnore = hasUDA!({{fullName}}, JsonIgnore);

      static if (!hasJsonIgnore)
      {
        {
          enum hasJsonField = hasUDA!({{fullName}}, JsonField);

          static if (hasJsonField)
          {
            mixin("enum rawJsonFieldAttribute = getUDAs!(%s, JsonField)[0];".format("{{fullName}}"));

            const S rawFieldName = rawJsonFieldAttribute.fieldName;
          }
          else
          {
            const S rawFieldName = "{{fieldName}}";
          }

          enum hasJsonWrite = hasUDA!({{fullName}}, JsonWrite);

          static if (hasJsonWrite)
          {
            mixin("enum rawJsonWriteAttribute = getUDAs!(%s, JsonWrite)[0];".format("{{fullName}}"));

            mixin("Json!S memberJson = value." ~ rawJsonWriteAttribute.handler ~ "(new Json!S);");

            if (memberJson)
            {
              json.addMember(rawFieldName, memberJson);
            }
          }
          else
          {
            Json!S memberJson;
            if (serializeJsonObjectSafe(value.{{fieldName}}, memberJson))
            {
              json.addMember(rawFieldName, memberJson);
            }
          }
        }
      }
    }});

    mixin(memberFormat.format(handleThem()));

    return true;
  }
  else static if (isSomeString!T)
  {
    static if (is(T == S))
    {
      json.setText(value);
      return true;
    }
    else
    {
      return false;
    }
  }
  else static if (isArray!T)
  {
    if (!value || !value.length)
    {
      json.jsonType = JsonType.jsonArray;
    }
    else
    {
      foreach (item; value)
      {
        Json!S itemJson;
        if (serializeJsonObjectSafe(item, itemJson))
        {
          json.addItem(itemJson);
        }
      }
    }

    return true;
  }
  else static if (isAssociativeArray!T)
  {
    static if (!is(ArrayElementType!(typeof(T.init.keys)) == S))
    {
      return false;
    }
    else static if (isSomeString!(ArrayElementType!(typeof(T.init.values))) && !is(ArrayElementType!(typeof(T.init.values)) == S))
    {
      return false;
    }
    else
    {
      if (!value)
      {
        json.jsonType = JsonType.jsonNull;
      }
      else
      {
        foreach (key,member; value)
        {
          Json!S memberJson;
          if (serializeJsonObjectSafe(member, memberJson))
          {
            json.addMember(key, memberJson);
          }
        }
      }

      return true;
    }
  }
  else static if (is(T == bool))
  {
    json.setBoolean(value);
    return true;
  }
  else static if (isScalarType!T)
  {
    json.setNumber(value);
    return true;
  }
  else
  {
    return false;
  }
}
