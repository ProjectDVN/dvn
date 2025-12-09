/**
* Copyright (c) 2025 Project DVN
*/
module dvn.dom.svg.svgdocument;

import dvn.dom.svg.svgexception;
import dvn.dom.domdocument;
import dvn.dom.domnode;
import dvn.dom.domparsersettings;
import dvn.dom.svg.svgnode;

/// An SVG document.
final class SvgDocument : DomDocument
{
  private:
  /// The version of the svg document.
  string _svgVersion;
  /// The encoding of the svg document.
  string _encoding;
  /// The root node of the document.
  SvgNode _root;

  public:
  final:
  /**
  * Creates a new svg document.
  * Params:
  *   parserSettings = The settings used for parsing the document.
  */
  this(DomParserSettings parserSettings) @safe
  {
    super(parserSettings);
  }

  /**
  * Parses the elements from the dom to the document.
  * Params:
  *   elements = The parsed dom elements.
  */
  override void parseElements(DomNode[] elements) @safe
  {
    if (!elements || !elements.length)
    {
      throw new SvgException("No root element found.");
    }
    
    _root = elements[0];
  }

  @property
  {
    /// Gets the root of the svg document.
    SvgNode root() @safe { return _root; }

    /// Sets the root node of the svg document.
    void root(SvgNode newRoot) @safe
    {
      _root = newRoot;
    }
  }

  /// SVG documents cannot be repaired.
  override void repairDocument() @safe
  {
    throw new SvgException("Cannot repair SVG documents.");
  }

  /**
  * Converts the svg document to a properly formatted svg document-string.
  * Returns:
  *   A string equivalent to the properly formatted svg document-string.
  */
  override string toString() @safe
  {
    import std.string : format;

    return root ? _root.toString() : "";
  }
}
