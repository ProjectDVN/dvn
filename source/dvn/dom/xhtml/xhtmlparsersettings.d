module dvn.dom.xhtml.xhtmlparsersettings;

import dvn.dom.domparsersettings;

/// Wrapper around xhtml parser settings.
final class XHtmlParserSettings : DomParserSettings
{
  public:
  final:
  /// Creates a new xhtml parser settings:
  this() @safe
  {
    super
    (
      false, // XHtml is not strict
      // Tags that can contain flexible content.
      ["script", "pre", "code", "style"],
      // XHtml does not allow self-closing tags.
      false,
      // XHtml has no self-closing tags.
      null,
      // Standard tags are not relevant without self-closing tags.
      null,
      // XHtml documents cannot be repaired.
      null, null
    );
  }
}
