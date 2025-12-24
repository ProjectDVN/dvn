/**
* Copyright (c) 2025 Project DVN
*/
module dvn.json;

public
{
  import dvn.json.jsonobject;
  import dvn.json.jsonobjectmember;
  import dvn.json.jsontype;
  import dvn.json.parser;
  import dvn.json.serialization;
}

version(unittest)
{
  public class TestJson
  {
    int a;
    string b;
  }
}

unittest
{
  {
    string json;
    assert(serializeJsonSafe(100, json, false));
    assert(json == "100");
  }

  {
    string json;
    assert(serializeJsonSafe("Hello, World!", json, false));
    assert(json == `"Hello, World!"`);
  }

  {
    string json;
    assert(serializeJsonSafe(`Line\nBreak`, json, false));
    assert(json == `"Line\\nBreak"`); // escape checked
  }

  {
    string json;
    assert(serializeJsonSafe(-1.23e4, json, false));
    assert(json == "-12300");
  }

  {
    string json;
    int[] arr = [1,2,3];
    assert(serializeJsonSafe(arr, json, false));
    assert(json == "[1,2,3]");
  }

  {
    string json;
    string[string] obj = ["a":"hello","b":"world"];
    assert(serializeJsonSafe(obj, json, false));

    assert(json == `{"a":"hello","b":"world"}` ||
           json == `{"b":"world","a":"hello"}`);
  }

  {
    string json;
    string[string] inner = ["a":"1", "b":"2"];
    string[string][string] nested;
    nested["group1"] = inner;
    assert(serializeJsonSafe(nested, json, false));
    import std.stdio : writeln;
    assert(json == `{"group1":{"a":"1","b":"2"}}` ||
           json == `{"group1":{"b":"2","a":"1"}}`);
  }

  {
    string json;
    int[][] nested = [[1,2],[3,4]];
    assert(serializeJsonSafe(nested, json, false));
    assert(json == "[[1,2],[3,4]]");
  }

  {
    string json;
    assert(serializeJsonSafe(true, json, false));
    assert(json == "true");

    assert(serializeJsonSafe(false, json, false));
    assert(json == "false");
  }

  {
    string json;
    int[] emptyArr;
    assert(serializeJsonSafe(emptyArr, json, false));
    assert(json == "[]");
  }

  {
    string json;
    string[string] emptyObj;
    assert(serializeJsonSafe(emptyObj, json, false));
    assert(json == "null");
  }

  {
    string json;
    string[string][] arrOfObj = [
        ["a":"1","b":"2"],
        ["x":"hello","y":"world"]
    ];
    assert(serializeJsonSafe(arrOfObj, json, false));

    // Accept either key order for each object
    import std.algorithm : any;
    bool valid =
        (json == `[{"a":"1","b":"2"},{"x":"hello","y":"world"}]`) ||
        (json == `[{"b":"2","a":"1"},{"x":"hello","y":"world"}]`) ||
        (json == `[{"a":"1","b":"2"},{"y":"world","x":"hello"}]`) ||
        (json == `[{"b":"2","a":"1"},{"y":"world","x":"hello"}]`);

    assert(valid);
  }

  {
    string json;
    string[string][][] nestedArrObj = [
        [ ["a":"1"], ["b":"2"] ],
        [ ["x":"X"] ]
    ];
    assert(serializeJsonSafe(nestedArrObj, json, false));
    assert(json == `[[{"a":"1"},{"b":"2"}],[{"x":"X"}]]`);
  }
  {
    string json;
    auto test = new TestJson;
    test.a = 100;
    test.b = "Hello, World!";
    assert(serializeJsonSafe(test, json, false));
    assert(json == `{"a":100,"b":"Hello, World!"}`);
  }

  string[] errorMessages;

  {
    int value;
    string json = `100`;
    assert(deserializeJsonSafe!int(json, value, errorMessages));
    assert(value == 100);
  }

  {
    string json = `"Hello, World!"`;
    string str;
    assert(deserializeJsonSafe!string(json, str, errorMessages));
    assert(str == "Hello, World!");
  }

  {
    string json = `[1,2,3]`;
    int[] arr;
    assert(deserializeJsonSafe!(int[])(json, arr, errorMessages));
    assert(arr == [1,2,3]);
  }

  {
    string json = `{"a":100,"b":"Hello, World!"}`;
    auto obj = new TestJson;
    assert(deserializeJsonSafe!TestJson(json, obj, errorMessages));
    assert(obj.a == 100);
    assert(obj.b == "Hello, World!");
  }
}