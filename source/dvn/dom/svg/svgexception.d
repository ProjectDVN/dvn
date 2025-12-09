/**
* Copyright (c) 2025 Project DVN
*/
module dvn.dom.svg.svgexception;

final class SvgException : Exception
{
  public:
  /**
  * Creates a new svg exception.
  * Params:
  *   message =   The message.
  *   fn =        The file.
  *   ln =        The line.
  */
  this(string message, string fn = __FILE__, size_t ln = __LINE__) @safe
  {
    super(message, fn, ln);
  }
}