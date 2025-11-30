module dvn.dom.svg.svgparsersettings;

import dvn.dom.domparsersettings;

/// Wrapper around svg parser settings.
final class SvgParserSettings : DomParserSettings
{
  public:
  final:
  /// Creates a new svg parser settings.
  this() @safe
  {
    super(
        true,                     // strict, like XML
        ["script", "style", "foreignObject"],  // optional flexible tags
        false,                    // no void elements
        null,                     // no self-closing tag list
        null,                     // no standard tags
        null, null                // no repair rules
    );
  }
}
