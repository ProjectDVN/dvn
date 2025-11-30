module dvn.dom.xml.xmlparsersettings;

import dvn.dom.domparsersettings;

/// Wrapper around xml parser settings.
final class XmlParserSettings : DomParserSettings
{
  public:
  final:
  /// Creates a new xml parser settings.
  this() @safe
  {
    // Xml is strict, has no flexible tags, allows no self-closing tags, has no standard tags and cannot be repaired.
    super(true, null, false, null, null, null, null);
  }
}
