module dvn.dom.domexception;

final class DomException : Exception
{
  public:
  /**
  * Creates a new dom exception.
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

/**
* Enforces the value of an input to be defined.
* Params:
*   value =    The value of an input.
*   message =  A given message when the value is undefined.
* Returns:
*   The value of the input.
*/
T enforceInput(T)(T value, lazy string message = null) @trusted
if (is(typeof({ if (!value) {} })))
{
  if (!value)
  {
    throw new Exception(message ? message : "Enforcement failed.");
  }

  return value;
}

/**
* Enforces a value to be defined.
* Params:
*   value =    The value.
*   message =  A given message when the value is undefined.
*/
void enforce(T)(T value, lazy string message = null) @trusted
if (is(typeof({ if (!value) {} })))
{
  if (!value)
  {
    throw new Exception(message ? message : "Enforcement failed.");
  }
}