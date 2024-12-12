module zid.generator;

import zid.meta;
import zid.window;
import zid.view;
import zid.component;
import zid.components;
import zid.colors;
import zid.events;
import zid.painting;
import zid.external;
import zid.i18n;

mixin CreateCustomException!"GeneratorException";

public final class UITheme
{
  public:
  final:
  this() {}
  UIColors colors;
  string defaultFont;
  string defaultFontSize;
}

public final class UIColor
{
  public:
  final:
  this() {}
  string hex;
  string name;
  int alpha;
  int[] rgba;

  import zid.colors;

  Color getColor()
  {
    if (hex && hex.length)
    {
      auto color = getColorByHex(hex);

      if (alpha > 0)
      {
        color.a = cast(ubyte)alpha;
      }

      return color;
    }
    else if (name && name.length)
    {
      if (alpha > 0)
      {
        return getColorByName(name);
      }
      else
      {
        return getColorByName(name, alpha);
      }
    }
    else if (rgba && rgba.length >= 3)
    {
      if (alpha > 0)
      {
        return getColorByRGB(rgba[0], rgba[1], rgba[2], alpha);
      }
      else if (rgba.length == 4)
      {
        return getColorByRGB(rgba[0], rgba[1], rgba[2], rgba[3]);
      }
      else
      {
        return getColorByRGB(rgba[0], rgba[1], rgba[2]);
      }
    }

    return getColorByName("transparent");
  }
}

public final class UIColors
{
  public:
  final:
  this() {}
  UIColor text;
  UIColorCollection defaultColors;
  UIColorCollection activeColors;
}

public final class UIColorCollection
{
  public:
  final:
  this() {}
  UIColor background;
  UIColor backgroundBottom;
  UIColor border;
  UIColor shadow;
}

private alias UIItem = UIItemEntry[string];

public final class UIGenerator
{
  public:
  final:
  this() {}
  string themeName;
  UITheme theme;
  UIItem[] items;
}

public final class UIItemEntry
{
  // shared
  int[] position;
  string location;
  string[string] visibleWhen;
  int[] margin;
  int[] size;
  string name;
  string relativeX;
  string relativeY;
  string relativeW;
  string relativeH;
  string[] events;
  int addIndex;
  string fontName;
  size_t fontSize;

  // image
  string source;

  // label
  string text;
  bool shadow;
  bool link;

  // panel
  bool hasDisplay;
  UIItem[] items;

  // textbox
  int maxCharacters;
  int textPadding;
  string hideCharacter;

  // button
  bool fitToSize;
}

private UIGenerator[string] _generators;
private UITheme[string] _themes;
private UITheme _defaultTheme;

void loadGenerator(string path, string name)
{
  if (!path || !path.length || !name || !name.length)
  {
    return;
  }

  import std.file : readText;
  import zid.json;

  string text = readText(path);
  string[] errorMessages;
  UIGenerator uiGenerator;
  if (!deserializeJsonSafe!(UIGenerator)(text, uiGenerator, errorMessages))
  {
    throw new GeneratorException(errorMessages[0]);
  }

  if (!uiGenerator)
  {
    return;
  }

  _generators[name] = uiGenerator;
}

void loadTheme(string path, string name, bool isDefault = false)
{
  if (!path || !path.length || !name || !name.length)
  {
    return;
  }

  import std.file : readText;
  import zid.json;

  string text = readText(path);
  string[] errorMessages;
  UITheme uiTheme;
  if (!deserializeJsonSafe!(UITheme)(text, uiTheme, errorMessages))
  {
    throw new GeneratorException(errorMessages[0]);
  }

  if (!uiTheme)
  {
    return;
  }

  _themes[name] = uiTheme;

  if (isDefault)
  {
    _defaultTheme = uiTheme;
  }
}

bool tryGetGenerator(string name, out UIGenerator generator)
{
  generator = null;

  if (!_generators || !_generators.length)
  {
    return false;
  }

  generator = _generators.get(name, null);

  if (generator)
  {
    if (generator.themeName && generator.themeName.length && _themes)
    {
      generator.theme = _themes.get(generator.themeName, null);
    }

    if (!generator.theme)
    {
      generator.theme = _defaultTheme;
    }
  }

  return generator !is null;
}

void generateUI(string language, Window window, UIGenerator generator, void delegate(Component,string,string) eventHandler)
{
  generateUI(language, window, null, generator, eventHandler);
}

void generateUI(string language, Window window, View view, UIGenerator generator, void delegate(Component,string,string) eventHandler)
{
  if (!window) return;

  if (!generator || !generator.theme || !generator.theme.colors || !generator.theme.colors.defaultColors || !generator.theme.colors.activeColors)
  {
    return;
  }

  auto items = generator.items;

  if (!items || !items.length)
  {
    return;
  }

  int[string] relativeValues;

  relativeValues["lastX"] = 0;
  relativeValues["lastY"] = 0;
  relativeValues["lastWidth"] = 0;
  relativeValues["lastHeight"] = 0;

  parseGUIItems(language, window, view, generator, items, null, eventHandler, relativeValues);
}

private void parseGUIItems(string language, Window window, View view, UIGenerator generator, UIItem[] items, Panel parentPanel, void delegate(Component,string,string) eventHandler, int[string] relativeValues)
{
  import std.string : strip;
  import std.conv : to;
  import std.array : split;

  auto colors = generator.theme.colors;

  void addComponent(Component component)
  {
    if (parentPanel)
    {
      parentPanel.addComponent(component);
    }
    else if (view)
    {
      view.addComponent(component);
    }
    else
    {
      window.addComponent(component);
    }
  }
  alias COMPONENT_ARRAY = Component[];

  COMPONENT_ARRAY[] addComponents = new COMPONENT_ARRAY[10];

  string fontName = parseLocalizedString(language, generator.theme.defaultFont);
  size_t fontSize = parseLocalizedString(language, generator.theme.defaultFontSize).to!size_t;

  if (parentPanel)
  {
    relativeValues["parentX"] = parentPanel.x;
    relativeValues["parentY"] = parentPanel.y;
    relativeValues["parentWidth"] = parentPanel.width;
    relativeValues["parentHeight"] = parentPanel.height;
  }

  foreach (itemEntry; items)
  {
    foreach (itemType,item; itemEntry)
    {
      if (item.visibleWhen && item.visibleWhen.length)
      {
        bool isVisible = true;

        foreach (k,v; item.visibleWhen)
        {
          auto result = parseLocalizedString(language, k);

          switch (v)
          {
            case "notEmptyOrWhiteSpace":
              if (!result || !result.strip.length)
              {
                isVisible = false;
              }
              break;

            default: break;
          }

          if (!isVisible) break;
        }

        if (!isVisible)
        {
          continue;
        }
      }

      Component component = null;
      Panel panel = null;

      switch (itemType)
      {
        case "image":
          auto image = new Image(window, item.source);
          component = image;
          image.show();
          break;

        case "label":
          auto label = new Label(window);
          component = label;
          label.color = colors.text.getColor;
          label.fontName = fontName;
          label.fontSize = fontSize;
          if (item.fontName && item.fontName.length) label.fontName = item.fontName;
          if (item.fontSize > 0) label.fontSize = item.fontSize;
          label.text = parseLocalizedString(language, item.text).to!dstring;
          if (item.shadow) label.shadow = true;
          if (item.link) label.isLink = true;
          break;

        case "panel":
          panel = new Panel(window);
          component = panel;

          if (item.hasDisplay)
          {
            panel.fillColor = colors.defaultColors.background.getColor;
            panel.borderColor = colors.defaultColors.border.getColor;
          }
          break;

        case "textbox":
          auto textbox = new TextBox(window);
          component = textbox;
          textbox.fontName = fontName;
          textbox.fontSize = fontSize;
          if (item.fontName && item.fontName.length) textbox.fontName = item.fontName;
          if (item.fontSize > 0) textbox.fontSize = item.fontSize;
          textbox.textColor = colors.text.getColor;
          textbox.maxCharacters = item.maxCharacters;
          textbox.textPadding = item.textPadding;

          if (item.hideCharacter && item.hideCharacter.length == 1)
          {
            textbox.hideCharacter = item.hideCharacter[0].to!dchar;
          }

          textbox.defaultPaint.backgroundColor = colors.defaultColors.background.getColor;
          textbox.defaultPaint.borderColor = colors.defaultColors.border.getColor;
          textbox.defaultPaint.shadowColor = colors.defaultColors.shadow.getColor;

          textbox.hoverPaint.backgroundColor = colors.activeColors.background.getColor;
          textbox.hoverPaint.borderColor = colors.activeColors.border.getColor;
          textbox.hoverPaint.shadowColor = colors.activeColors.shadow.getColor;

          textbox.focusPaint.backgroundColor = colors.activeColors.background.getColor;
          textbox.focusPaint.borderColor = colors.activeColors.border.getColor;
          textbox.focusPaint.shadowColor = colors.activeColors.shadow.getColor;

          textbox.restyle();

          textbox.show();
          break;

        case "dropdown":
          auto dropdown = new DropDown(window);
          component = dropdown;
          dropdown.fontName = fontName;
          dropdown.fontSize = fontSize;
          dropdown.textColor = colors.text.getColor;
          if (item.fontName && item.fontName.length) dropdown.fontName = item.fontName;
          if (item.fontSize > 0) dropdown.fontSize = item.fontSize;
          dropdown.defaultPaint.backgroundColor = colors.defaultColors.background.getColor;
          dropdown.defaultPaint.backgroundBottomColor = colors.defaultColors.backgroundBottom.getColor;
          dropdown.defaultPaint.borderColor = colors.defaultColors.border.getColor;
          dropdown.defaultPaint.shadowColor = colors.defaultColors.shadow.getColor;

          dropdown.hoverPaint.backgroundColor = colors.activeColors.background.getColor;
          dropdown.hoverPaint.backgroundBottomColor = colors.activeColors.backgroundBottom.getColor;
          dropdown.hoverPaint.borderColor = colors.activeColors.border.getColor;
          dropdown.hoverPaint.shadowColor = colors.activeColors.shadow.getColor;

          dropdown.restyle();
          break;

        case "button":
          auto button = new Button(window);
          component = button;
          button.fontName = fontName;
          button.fontSize = fontSize;
          button.textColor = colors.text.getColor;
          if (item.fontName && item.fontName.length) button.fontName = item.fontName;
          if (item.fontSize > 0) button.fontSize = item.fontSize;
          button.text = parseLocalizedString(language, item.text).to!dstring;
          button.fitToSize = item.fitToSize;

          button.defaultPaint.backgroundColor = colors.defaultColors.background.getColor;
          button.defaultPaint.backgroundBottomColor = colors.defaultColors.backgroundBottom.getColor;
          button.defaultPaint.borderColor = colors.defaultColors.border.getColor;
          button.defaultPaint.shadowColor = colors.defaultColors.shadow.getColor;

          button.hoverPaint.backgroundColor = colors.activeColors.background.getColor;
          button.hoverPaint.backgroundBottomColor = colors.activeColors.backgroundBottom.getColor;
          button.hoverPaint.borderColor = colors.activeColors.border.getColor;
          button.hoverPaint.shadowColor = colors.activeColors.shadow.getColor;

          button.clickPaint.backgroundColor = colors.activeColors.background.getColor;
          button.clickPaint.backgroundBottomColor = colors.activeColors.backgroundBottom.getColor;
          button.clickPaint.borderColor = colors.activeColors.border.getColor;
          button.clickPaint.shadowColor = colors.activeColors.shadow.getColor;
          break;

          default: break;
      }

      if (!component) continue;

      if (item.size && item.size.length == 2)
      {
        component.size = IntVector(item.size[0], item.size[1]);
      }

      switch (item.location)
      {
        case "center":
          component.position = IntVector((window.width / 2) - (component.width / 2), (window.height / 2) - (component.height / 2));
          break;

        case "topLeft":
          component.position = IntVector(0,0);
          break;

        case "topCenter":
          component.position = IntVector((window.width / 2) - (component.width / 2), 0);
          break;
          
        case "topRight":
          component.position = IntVector((window.width - (component.width + 6)), 0);
          break;

        case "bottomRight":
          component.position = IntVector((window.width - (component.width + 6)), (window.height - (component.height + 6)));
          break;
        default:
          if (item.position && item.position.length == 2)
          {
            component.position = IntVector(item.position[0], item.position[1]);
          }
          break;
      }

      int calculateRelativeEntries(string[] relativeEntries)
      {
        int lastTotalValue = 0;

        foreach (e; relativeEntries)
        {
          auto entry = e.strip;

          bool subtractLast = false;
          bool divisionlast = false;

          if (entry[0] == '-')
          {
            subtractLast = true;
            entry = entry[1 .. $].strip;
          }
          else if (entry[0] == '/')
          {
            divisionlast = true;
            entry = entry[1 .. $].strip;
          }

          auto calculation = entry.split("+");
          bool isAddition = true;

          if (calculation.length == 1)
          {
            calculation = entry.split("-");
            isAddition = false;
          }

          int lastValue = 0;
          bool isFirst = true;

          foreach (calcEntry; calculation)
          {
            auto calc = calcEntry.strip;
            auto relativeValue = relativeValues.get(calc, -9999);

            if (relativeValue == -9999)
            {
              switch (calc)
              {
                case "width": relativeValue = component.width; break;
                case "height": relativeValue = component.height; break;
                case "x": relativeValue = component.x; break;
                case "y": relativeValue = component.y; break;

                default: relativeValue = calc.to!int; break;
              }
            }

            if (isAddition || isFirst)
            {
              lastValue += relativeValue;
            }
            else
            {
              lastValue -= relativeValue;
            }

            isFirst = false;
          }
          if (subtractLast)
          {
            lastTotalValue -= lastValue;
          }
          else if (divisionlast)
          {
            lastTotalValue /= lastValue;
          }
          else
          {
            lastTotalValue += lastValue;
          }
        }

        return lastTotalValue;
      }

      if (item.relativeW && item.relativeW.length)
      {
        auto relativeEntries = item.relativeW.split("->");
        int value = calculateRelativeEntries(relativeEntries);

        if (item.size && item.size.length == 2 && item.size[0] == 0)
        {
          component.size = IntVector(value, component.size.y);
        }
        else
        {
          component.size = IntVector(component.size.x + value, component.size.y);
        }
      }

      if (item.relativeH && item.relativeH.length)
      {
        auto relativeEntries = item.relativeH.split("->");
        int value = calculateRelativeEntries(relativeEntries);

        if (item.size && item.size.length == 2 && item.size[1] == 0)
        {
          component.size = IntVector(component.size.x, value);
        }
        else
        {
          component.size = IntVector(component.size.x, component.size.y + value);
        }
      }

      if (item.relativeX && item.relativeX.length)
      {
        auto relativeEntries = item.relativeX.split("->");
        int value = calculateRelativeEntries(relativeEntries);

        if (item.position && item.position.length == 2 && item.position[0] == 0)
        {
          component.position = IntVector(value, component.position.y);
        }
        else
        {
          component.position = IntVector(component.position.x + value, component.position.y);
        }
      }

      if (item.relativeY && item.relativeY.length)
      {
        auto relativeEntries = item.relativeY.split("->");
        int value = calculateRelativeEntries(relativeEntries);

        if (item.position && item.position.length == 2 && item.position[1] == 0)
        {
          component.position = IntVector(component.position.x, value);
        }
        else
        {
          component.position = IntVector(component.position.x, component.position.y + value);
        }
      }

      if (item.margin && item.margin.length == 2)
      {
        component.position = IntVector(component.position.x + item.margin[0], component.position.y + item.margin[1]);
      }

      if (item.name && item.name.length)
      {
        relativeValues[item.name~"Width"] = component.width;
        relativeValues[item.name~"Height"] = component.height;
        relativeValues[item.name~"X"] = component.x;
        relativeValues[item.name~"Y"] = component.y;
      }

      relativeValues["lastX"] = component.y;
      relativeValues["lastY"] = component.y;
      relativeValues["lastWidth"] = component.width;
      relativeValues["lastHeight"] = component.height;

      if (item.events && eventHandler)
      {
        foreach (event; item.events)
        {
          eventHandler(component, event, item.name);
        }
      }

      if (item.addIndex < 10)
      {
        addComponents[item.addIndex] ~= component;
      }
      else
      {
        addComponents[0] ~= component;
      }

      if (item.items && item.items.length)
      {
        parseGUIItems(language, window, view, generator, item.items, panel, eventHandler, relativeValues);
      }

      break;
    }
  }

  foreach (componentEntries; addComponents)
  {
    foreach (component; componentEntries)
    {
      addComponent(component);
    }
  }
}
