module dvn.uigenerator;

import dvn.css;
import dvn.dom;
import dvn.ui;

import std.array : join, split;
import std.conv : to;
import std.string : strip;
import std.file : exists;

void generateHtmlUI(string language, string html, string css, Window window, View view, void delegate(Component,HtmlNode) initializer)
{
    auto doc = parseDom!HtmlDocument(html, new HtmlParserSettings);
    auto rules = parseCss(css, window.width, window.height);

    foreach (rule; rules)
    {
        foreach (selector; rule.selectors)
        {
            auto nodes = doc.body.querySelectorAll(selector);

            foreach (node; nodes)
            {
                foreach (property,values; rule.properties)
                {
                    node.addAttribute(new DomAttribute("ui-" ~ property, values.join(" ")));
                }
            }
        }
    }

    foreach (child; doc.body.children)
    {
        generateHtmlUIComponent(language, window, view, child, initializer); // recursive call from panels + sections
    }
}

private:
Component generateHtmlUIComponent(string language, Window window, View view, HtmlNode node, void delegate(Component,HtmlNode) initializer,  Component parent = null, Component sectionComponent = null)
{
    auto attributes = node.getAttributes();

    Component component;
    Panel panel;
    ScrollBar scrollbar;
    DropDown dropdown;

    void addComponent(Component c)
    {
        if (parent) parent.addComponent(c);
        else if (view) view.addComponent(c);
        else window.addComponent(c);
    }

    switch (node.name)
    {
        case "img":
            auto imageSource = node.getAttribute("src").value;
            auto isAnimation = node.hasAttribute("animation");

            if (isAnimation)
            {
                auto animation = new Animation(window, imageSource, node.hasAttribute("repeat"));
                addComponent(animation);
                component = animation;
            }
            else
            {
                auto image = new Image(window, imageSource, exists(imageSource));
                addComponent(image);
                component = image;
            }
            break;

        case "section":
            Component lastComponent = null;
            foreach (child; node.children)
            {
                lastComponent = generateHtmlUIComponent(language, window, view, child, initializer, parent, lastComponent);
            }
            break;

        case "div":
            panel = new Panel(window);
            addComponent(panel);
            component = panel;
            break;

        case "span":
            auto label = new Label(window);
            addComponent(label);
            label.text = parseLocalizedString(language, node.text.strip).to!dstring;
            foreach (attribute; attributes)
            {
                switch (attribute.name)
                {
                    case "ui-font-family":
                        label.fontName = attribute.value;
                        break;

                    case "ui-font-size":
                        label.fontSize = to!int(attribute.value);
                        break;

                    case "ui-font-style":
                        foreach (value; attribute.value.split(" "))
                        {
                            switch (value)
                            {
                                case "link":
                                    label.isLink = true;
                                    break;

                                case "shadow":
                                    label.shadow = true;
                                    break;

                                default: break;
                            }
                        }
                        break;

                    case "ui-color":
                        auto colorValues = attribute.value.split(" ");
                        label.color = colorValues[0].getColorByHex;
                        if (colorValues.length > 1)
                        {
                            label.color = label.color.changeAlpha(to!int(colorValues[1]));
                        }
                        break;

                    default: break;
                }
            }

            label.updateRect();
            
            component = label;
            break;

        case "video":
            auto video = new Video(window, node.getAttribute("src").value, node.hasAttribute("repeat"));
            addComponent(video);
            component = video;
            break;
            
        case "button":
            auto button = new Button(window);
            addComponent(button);
            button.text = parseLocalizedString(language, node.text.strip).to!dstring;

            foreach (attribute; attributes)
            {
                switch (attribute.name)
                {
                    case "ui-font-family":
                        button.fontName = attribute.value;
                        break;

                    case "ui-font-size":
                        button.fontSize = to!int(attribute.value);
                        break;

                    case "ui-color":
                        auto colorValues = attribute.value.split(" ");
                        button.textColor = colorValues[0].getColorByHex;
                        if (colorValues.length > 1)
                        {
                            button.textColor = button.textColor.changeAlpha(to!int(colorValues[1]));
                        }
                        break;

                    default: break;
                }
            }

            button.fitToSize = false;
            component = button;
            break;

        case "input":
            switch (node.getAttribute("type").value)
            {
                case "text":
                    auto textbox = new TextBox(window);
                    addComponent(textbox);

                    foreach (attribute; attributes)
                    {
                        switch (attribute.name)
                        {
                            case "ui-font-family":
                                textbox.fontName = attribute.value;
                                break;

                            case "ui-font-size":
                                textbox.fontSize = to!int(attribute.value);
                                break;

                            case "ui-color":
                                auto colorValues = attribute.value.split(" ");
                                textbox.textColor = colorValues[0].getColorByHex;
                                if (colorValues.length > 1)
                                {
                                    textbox.textColor = textbox.textColor.changeAlpha(to!int(colorValues[1]));
                                }
                                break;

                            default: break;
                        }
                    }

                    auto maxCharacters = node.getAttribute("maxlength");
                    if (maxCharacters && maxCharacters.value && maxCharacters.value.length)
                    {
                        textbox.maxCharacters = to!int(maxCharacters.value);
                    }

                    auto textPadding = node.getAttribute("padding");
                    if (textPadding && textPadding.value && textPadding.value.length)
                    {
                        textbox.textPadding = to!int(textPadding.value);
                    }

                    auto hideCharacter = node.getAttribute("hidechar");
                    if (hideCharacter && hideCharacter.value && hideCharacter.value.length)
                    {
                        textbox.hideCharacter = hideCharacter.value[0].to!dchar;
                    }

                    textbox.restyle();

                    component = textbox;
                    break;

                default: break;
            }
            break;

        case "select":
            dropdown = new DropDown(window);
            addComponent(dropdown);

            foreach (attribute; attributes)
            {
                switch (attribute.name)
                {
                    case "ui-font-family":
                        dropdown.fontName = attribute.value;
                        break;

                    case "ui-font-size":
                        dropdown.fontSize = to!int(attribute.value);
                        break;

                    case "ui-color":
                        auto colorValues = attribute.value.split(" ");
                        dropdown.textColor = colorValues[0].getColorByHex;
                        if (colorValues.length > 1)
                        {
                            dropdown.textColor = dropdown.textColor.changeAlpha(to!int(colorValues[1]));
                        }
                        break;

                    default: break;
                }
            }

            component = dropdown;
            break;

        default: return null;
    }

    auto width = node.getAttribute("width");
    auto height = node.getAttribute("height");

    if (width && width.value && width.value.length &&
        height && height.value && height.value.length)
    {
        component.size = IntVector(to!int(width.value), to!int(height.value));
    }

    if (dropdown)
    {   
        dropdown.restyle();

        dstring selected;

        foreach (child; node.children)
        {
            if (child.name != "option")
            {
                continue;
            }

            auto valueAttribute = child.getAttribute("value");
            string value;
            if (valueAttribute && valueAttribute.value && valueAttribute.value.length)
            {
                value = valueAttribute.value;
            }
            else
            {
                value = child.text;
            }

            if (value && value.length && child.hasAttribute("selected"))
            {
                selected = value.to!dstring;
            }

            dropdown.addItem(child.text.to!dstring, value);
        }

        if (selected && selected.length)
        {
            dropdown.setItem(selected);
        }

        dropdown.restyle();
    }

    if (component)
    {
        if (sectionComponent)
        {
            component.moveBelow(sectionComponent, 0, node.hasAttribute("ui-position", "center"));
        }

        foreach (attribute; attributes)
        {
            switch (attribute.name)
            {
                case "ui-position":
                    if (!sectionComponent)
                    {
                        auto values = attribute.value.split(" ");
                        if (values.length == 2)
                        {
                            component.position = IntVector(to!int(values[0]), to!int(values[1]));
                        }
                        else
                        {
                            switch (attribute.value)
                            {
                                case "center":
                                    if (parent)
                                    {
                                        component.position = IntVector(
                                            (parent.width / 2) - (component.width / 2),
                                            (parent.height / 2) - (component.height / 2)
                                        );
                                    }
                                    else
                                    {
                                        component.position = IntVector(
                                            (window.width / 2) - (component.width / 2),
                                            (window.height / 2) - (component.height / 2)
                                        );
                                    }
                                    break;

                                case "top-center":
                                    component.anchor = Anchor.top;
                                    break;

                                default: break;
                            }
                        }
                    }
                    break;

                case "ui-margin-top":
                    auto marginValue = to!int(attribute.value);
                    component.position = IntVector(component.x, component.y + marginValue);
                    break;

                case "ui-background-color":
                    auto colorValues = attribute.value.split(" ");
                    component.fillColor = colorValues[0].getColorByHex;
                    if (colorValues.length > 1)
                    {
                        component.fillColor = component.fillColor.changeAlpha(to!int(colorValues[1]));
                    }
                    break;

                case "ui-border-color":
                    auto colorValues = attribute.value.split(" ");
                    component.borderColor = colorValues[0].getColorByHex;
                    if (colorValues.length > 1)
                    {
                        component.borderColor = component.borderColor.changeAlpha(to!int(colorValues[1]));
                    }
                    break;

                case "ui-size":
                    auto sizeValues = attribute.value.split(" ");
                    component.size = IntVector(to!int(sizeValues[0]), to!int(sizeValues[1]));
                    break;

                default: break;
            }
        }

        auto label = cast(Label)component;
        if (label)
        {
            label.updateRect();
        }

        if (panel)
        {
            if (node.hasAttribute("scrollable"))
            {
                scrollbar = new ScrollBar(window, panel);
                addComponent(scrollbar);
                scrollbar.isVertical = true;
                
                auto bgAttribute = node.getAttribute("scrollbar-background-color");
                auto bgColorValues = bgAttribute ? bgAttribute.value.split(" ") : ["#000", "150"];
                scrollbar.fillColor = bgColorValues[0].getColorByHex;
                if (bgColorValues.length > 1)
                {
                    scrollbar.fillColor = scrollbar.fillColor.changeAlpha(to!int(bgColorValues[1]));
                }

                auto borderAttribute = node.getAttribute("scrollbar-border-color");
                auto borderColorValues = borderAttribute ? borderAttribute.value.split(" ") : ["#000", "150"];
                scrollbar.borderColor = borderColorValues[0].getColorByHex;
                if (borderColorValues.length > 1)
                {
                    scrollbar.borderColor = scrollbar.borderColor.changeAlpha(to!int(borderColorValues[1]));
                }
                
                panel.scrollMargin = IntVector(0,cast(int)((cast(double)panel.height / 3.5) / 2));
                scrollbar.position = IntVector(panel.x + panel.width, panel.y);
                scrollbar.buttonScrollAmount = cast(int)((cast(double)panel.height / 3.5) / 2);
                scrollbar.fontName = "Calibri";
                scrollbar.fontSize = 8;

                auto buttonAttribute = node.getAttribute("scrollbar-button-color");
                auto buttonColorValues = buttonAttribute ? buttonAttribute.value.split(" ") : ["#fff"];
                scrollbar.buttonTextColor = buttonColorValues[0].getColorByHex;
                if (buttonColorValues.length > 1)
                {
                    scrollbar.buttonTextColor = scrollbar.buttonTextColor.changeAlpha(to!int(buttonColorValues[1]));
                }

                scrollbar.createDecrementButton("▲", "◀");
                scrollbar.createIncrementButton("▼", "▶");
                scrollbar.size = IntVector(16, panel.height);
                scrollbar.restyle();
                scrollbar.updateRect(false);
            }

            // We do this here because we want panel styling first ...
            Component lastComponent = null;
            foreach (child; node.children)
            {
                lastComponent = generateHtmlUIComponent(language, window, view, child, initializer, panel, lastComponent);
            }
        }
    }

    if (panel && scrollbar)
    {
        scrollbar.restyle();
        scrollbar.updateRect(false);
        panel.makeScrollableWithWheel();
    }
    
    if (component && initializer)
    {
        initializer(component, node);
    }

    return component;
}