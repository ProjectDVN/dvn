module zid.json.meta;

/// Mixin template to handle fields of a type.
mixin template HandleFields(T, string handler)
{
  string handleThem()
  {
    mixin HandleField!(T, [FieldNameTuple!T], handler);

    return handle();
  }
}

/// Mixin template to handle a specific field of a fieldname collection.
mixin template HandleField
(
  T,
  string[] fieldNames,
  string handler
)
{
  import std.array : replace;

  string handle()
  {
    string s = "";

    foreach (fieldName; fieldNames)
    {
      s ~= "{" ~
        handler
          .replace("{{fieldName}}", fieldName)
          .replace("{{fullName}}", T.stringof ~ "." ~ fieldName)
        ~ "}";
    }

    return s;
  }
}

template ArrayElementType(T : T[])
{
  alias T ArrayElementType;
}
