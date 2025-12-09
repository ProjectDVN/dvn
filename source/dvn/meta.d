/**
* Copyright (c) 2025 Project DVN
*/
module dvn.meta;

/// 
mixin template CreateCustomException(string name)
{
  import std.format : format;

  mixin(format(q{public final class %s : Exception
  {
    public:
    final:
    this(string message, string fn = __FILE__, size_t ln = __LINE__) @safe
    {
      super(message, fn, ln);
    }
  }}, name));
}

/// 
mixin CreateCustomException!"ArgumentException";

/// 
template EnforceEventOverrides(Base, Derived)
{
    bool EnforceEventOverrides()
    {
      static foreach (name; __traits(allMembers, Base))
      {{
          static if (__traits(compiles, __traits(getVirtualMethods, Base, name)))
          {{
              alias baseFns = __traits(getVirtualMethods, Base, name);

              static if (
                name != "toString" &&
                name != "toHash" &&
                name != "opCmp" &&
                name != "opEquals" &&
                baseFns.length)
              {{
                  alias derivedFns = __traits(getVirtualMethods, Derived, name);

                  static assert(derivedFns.length,
                      Derived.stringof ~ " is missing virtual method `" ~ name ~ "` from " ~ Base.stringof);

                  static assert(!__traits(isSame, baseFns[0], derivedFns[0]),
                      Derived.stringof ~ " must override `" ~ name ~ "` from " ~ Base.stringof);
              }}
          }}
      }}

      return true;
    }
}