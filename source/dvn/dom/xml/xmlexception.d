module dvn.dom.xml.xmlexception;

final class XmlException : Exception
{
  public:
  /**
  * Creates a new html exception.
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