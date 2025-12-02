/**
* Copyright (c) 2025 Project DVN
*/
module dvn.dom.domdocument;

import dvn.dom.domnode;
import dvn.dom.domparsersettings;

/// A dom document.
public abstract class DomDocument
{
  private:
  /// The settings used for parsing the document.
  DomParserSettings _parserSettings;

  protected:
  /**
  * Creates a new dom document.
  * Params:
  *   parserSettings = The settings used for parsing the document.
  */
  this(DomParserSettings parserSettings) @safe
  {
    import dvn.dom.domexception;

    enforce(parserSettings !is null, "The parser settings cannot be null.");

    _parserSettings = parserSettings;
  }

  public:
  /**
  * Parses the elements from the dom to the document.
  * Params:
  *   elements = The parsed dom elements.
  */
  abstract void parseElements(DomNode[] elements) @safe;

  /// Repairs the document if possible.
  abstract void repairDocument() @safe;

  final:
  @property
  {
    /// Gets the settings used for parsing the document.
    DomParserSettings parserSettings() @safe { return _parserSettings; }
  }
}
