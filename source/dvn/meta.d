module dvn.meta;

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

mixin CreateCustomException!"ArgumentException";
