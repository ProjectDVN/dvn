/**
* Copyright (c) 2025 Project DVN
*/
module dvn.json.parser;

import std.traits : isSomeString, isScalarType;
import std.range : zip, sequence, stride, ElementType;
import std.string : format;
import std.uni : isWhite;
import std.utf : encode;
import std.conv : to;
import std.array : appender;

import dvn.json.conv;

import dvn.json.jsonobject;
import dvn.json.jsonobjectmember;
import dvn.json.jsontype;

Json!S parseJson(S = string)(S jsonString)
if (isSomeString!S)
{
  Json!S json;
  S[] errorMessages;

  if (parseJsonSafe(jsonString, json, errorMessages))
  {
    return json;
  }

  return null;
}

bool parseJsonSafe(S = string)(S jsonString, out Json!S json, out S[] errorMessages)
if (isSomeString!S)
{
  json = null;
  errorMessages = [];

  S[] tokens;
  if (!parseJsonTokens(jsonString, tokens, errorMessages))
  {
    return false;
  }

  auto parsedJson = new Json!S;
  auto scanner = new JsonTokenScanner!S;
  scanner.tokens = tokens;
  errorMessages = [];

  if (!recursiveScanning(scanner, parsedJson, errorMessages))
  {
    return false;
  }

  json = parsedJson;
  return true;
}

private:
bool recursiveScanning(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
if (isSomeString!S)
{
  if (!scanner.has)
  {
    errorMessages ~= "Partial json parsed. (L: %d, I: %d)".format(scanner.length, scanner.index);
    return false;
  }

  switch (scanner.current)
  {
    case "null":
      json.jsonType = JsonType.jsonNull;
      return true;
    case "{":
      return scanObject(scanner, json, errorMessages);
    case "[":
      return scanArray(scanner, json, errorMessages);
    case "true":
    case "false":
      return scanBoolean(scanner, json, errorMessages);
    default:
      if (scanner.current.length >= 2 && scanner.current[0] == '"' && scanner.current[$-1] == '"')
      {
        return scanString(scanner, json, errorMessages);
      }
      else if (scanner.current.canParseNumeric)
      {
        return scanNumber(scanner, json, errorMessages);
      }
      else
      {
        errorMessages ~= "Unexpected token: %s (%d)".format(scanner.current, scanner.index);
        return false;
      }
  }
}

bool scanArray(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
{
  scanner.moveNext();

  if (scanner.current == "]")
  {
    json.jsonType = JsonType.jsonArray;
  }
  else
  {
    while (scanner.current != "]")
    {
      auto valueJson = new Json!S;

      if (!recursiveScanning(scanner, valueJson, errorMessages))
      {
        return false;
      }

      json.addItem(valueJson);

      scanner.moveNext();

      if (scanner.current == ",")
      {
        scanner.moveNext();
        continue;
      }
      else if (scanner.current == "]")
      {
        break;
      }
      else
      {
        errorMessages ~= "Unexpected token: %s (%d)".format(scanner.current, scanner.index);
        return false;
      }
    }
  }

  return json.jsonType == JsonType.jsonArray;
}

bool scanNumber(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
{
  double number;
  if (!tryParse(scanner.current, number))
  {
    errorMessages ~= "Failed to convert token ('%s') to numeric value. (%d)".format(scanner.current, scanner.index);
    return false;
  }

  json.setNumber(number);

  return true;
}

bool scanString(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
{
  if (scanner.current.length == 2)
  {
    json.setText("");
  }
  else
  {
    json.setText(scanner.current[1 .. $-1]);
  }

  return true;
}

bool scanObject(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
{
  scanner.moveNext();

  if (scanner.current == "}")
  {
    json.jsonType = JsonType.jsonObject;
    return true;
  }

  if (scanner.current.length < 3 && scanner.current[0] != '"' && scanner.current[$-1] != '"')
  {
    errorMessages ~= "Invalid key found for object. '%s' (%d)".format(scanner.current, scanner.index);
    return false;
  }

  while (scanner.has)
  {
    auto key = scanner.current[1 .. $-1];

    if (scanner.moveNext() != ":")
    {
      errorMessages ~= "Expected '%s' but found '%s' (%d)".format(":", scanner.current, scanner.index);
      return false;
    }

    auto entryJson = new Json!S;

    scanner.moveNext();
    if (!recursiveScanning(scanner, entryJson, errorMessages))
    {
      return false;
    }

    json.addMember(key, entryJson);

    scanner.moveNext();

    if (scanner.current == ",")
    {
      scanner.moveNext();
      continue;
    }
    else if (scanner.current == "}")
    {
      break;
    }
    else
    {
      errorMessages ~= "Unexpected token: %s (%d)".format(scanner.current, scanner.index);
      return false;
    }
  }

  return true;
}

bool scanBoolean(S = string)(JsonTokenScanner!S scanner, Json!S json, ref S[] errorMessages)
{
  bool booleanValue;
  if (!tryParse(scanner.current, booleanValue))
  {
    errorMessages ~= "Failed to convert token ('%s') to boolean value. (%d)".format(scanner.current, scanner.index);
    return false;
  }

  json.setBoolean(booleanValue);

  return true;
}

final class JsonTokenScanner(S = string)
if (isSomeString!S)
{
  S[] tokens;
  ptrdiff_t index;
  S _current;

  @property size_t length()
  {
    if (!tokens || !tokens.length)
    {
      return 0;
    }

    auto remaining = cast(ptrdiff_t)tokens.length - index;

    return remaining > 0 ? remaining : 0;
  }

  @property S current()
  {
    if (!_current)
    {
      if (index >= tokens.length)
      {
        return null;
      }

      _current = tokens[index];
    }

    return _current;
  }

  @property bool has()
  {
    return current !is null;
  }

  bool peekIs(bool delegate(S) fun)
  {
    return fun(peek());
  }

  bool peekIs(bool function(S) fun)
  {
    return fun(peek());
  }

  S peek()
  {
    if (index >= (tokens.length - 1))
    {
      return null;
    }

    return tokens[index + 1];
  }

  S moveNext()
  {
    index++;

    _current = null;

    return current;
  }

  S moveBack()
  {
    index--;

    if (index < 0)
    {
      index = 0;
    }

    _current = null;
    return current;
  }
}

bool parseJsonTokens(S = string)(S text, out S[] tokens, out S[] errorMessages)
if (isSomeString!S)
{
  tokens = [];
  errorMessages = [];

  bool escapeNext;
  bool inString;

  S currentToken;

  int skip;

  foreach (i, c; zip(sequence!"n", text.stride(1)))
  {
    if (skip) 
    {
      skip--;
      continue;
    }
    if (escapeNext && inString)
    {
      switch (c)
      {
        case '"':
        case '\\':
          currentToken ~= c;
          break;

        case 'b': currentToken ~= '\b'; break;
        case 'f': currentToken ~= '\f'; break;
        case 'n': currentToken ~= '\n'; break;
        case 'r': currentToken ~= '\r'; break;
        case 't': currentToken ~= '\t'; break;
        case 'u':
          skip = 4;
          auto digits = text[i .. i+4].to!int(16);
          dchar codePoint = cast(dchar)digits;

          static if (is(S == dstring))
          {
              dchar[1] buf;
              auto len = encode(buf, codePoint);
              currentToken ~= buf[0 .. len];
          }
          else static if (is(S == wstring))
          {
              wchar[2] buf;
              auto len = encode(buf, codePoint);
              currentToken ~= buf[0 .. len];
          }
          else static if (is(S == string))
          {
              char[4] buf;
              auto len = encode(buf, codePoint);
              currentToken ~= buf[0 .. len];
          }
          break;

        default:
          errorMessages ~= "Expected escape character but found '%s'. (%d)".format(c, i);
          return false;
      }

      escapeNext = false;
    }
    else if (inString)
    {
      if (c == '\\')
      {
        escapeNext = true;
      }
      else if (c == '"')
      {
        currentToken ~= c;
        inString = false;

        if (currentToken && currentToken.length)
        {
          tokens ~= currentToken;
          currentToken = null;
        }
      }
      else if (c == '\n' || c == '\r')
      {
        errorMessages ~= "Unexpected newline or carrot return. (%d)".format(i);
        return false;
      }
      else
      {
        currentToken ~= c;
      }
    }
    else if (c == '"')
    {
      if (currentToken && currentToken.length)
      {
        tokens ~= currentToken;
        currentToken = null;
      }

      inString = true;
      currentToken ~= c;
    }
    else if (c == '{' || c == '}' || c == '[' || c == ']' || c == ',' || c == ':')
    {
      if (currentToken && currentToken.length)
      {
        tokens ~= currentToken;
        currentToken = null;
      }

      currentToken ~= c;
      tokens ~= currentToken;
      currentToken = null;
    }
    else
    {
      if (!c.isWhite)
      {
        currentToken ~= c;
      }
      else
      {
        if (currentToken && currentToken.length)
        {
          tokens ~= currentToken;
          currentToken = null;
        }
      }
    }
  }

  if (currentToken && currentToken.length)
  {
    tokens ~= currentToken;
  }

  return true;
}
