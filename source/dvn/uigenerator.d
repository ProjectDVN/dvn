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

    if (_componentMap)
    {
        _componentMap.clear();
    }

    foreach (child; doc.body.children)
    {
        generateHtmlUIComponent(language, window, view, child, initializer); // recursive call from panels + sections
    }
}

private:
Component[string] _componentMap;

Component generateHtmlUIComponent(string language, Window window, View view, HtmlNode node, void delegate(Component,HtmlNode) initializer,  Component parent = null, Component sectionComponent = null, bool layoutHorizontal = false, int gap = 0)
{
    auto attributes = node.getAttributes();

    Component component;
    Panel panel;
    ScrollBar scrollbar;
    DropDown dropdown;
    Button button;
    TextBox textbox;
    CheckBox checkbox;
    ProgressBar progress;

    void addComponent(Component c)
    {
        if (parent) parent.addComponent(c);
        else if (view) view.addComponent(c);
        else window.addComponent(c);
    }

    void applyColorAttribute(void delegate(Color) colorApply, DomAttribute attribute)
    {
        auto colorValues = attribute.value.split(" ");
        auto color = colorValues[0].getColorByHex;
        if (colorValues.length > 1)
        {
            color = color.changeAlpha(to!int(colorValues[1]));
        }
        colorApply(color);
    }

    void restyleComponents()
    {
        if (button)
        {
            button.restyle();
        }

        if (textbox)
        {
            textbox.restyle();
        }

        if (dropdown)
        {
            dropdown.restyle();   
        }

        if (checkbox)
        {
            checkbox.updateRect();
        }

        if (progress)
        {
            progress.updateBarPanel();
        }
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
            auto sectionGap = 0;
            auto sectionGapAttribute = node.getAttribute("gap");
            if (sectionGapAttribute && sectionGapAttribute.value && sectionGapAttribute.value.length)
            {
                sectionGap = to!int(sectionGapAttribute.value);
            }
            Component lastComponent = null;
            foreach (child; node.children)
            {
                lastComponent = generateHtmlUIComponent(language, window, view, child, initializer, parent, lastComponent, node.hasAttribute("layout", "horizontal"), sectionGap);
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
            button = new Button(window);
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
                        applyColorAttribute((c) { button.textColor = c; }, attribute);
                        break;

                    case "ui-background-color-default":
                        applyColorAttribute((c) { button.defaultPaint.backgroundColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-bottom":
                        applyColorAttribute((c) { button.defaultPaint.backgroundBottomColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-border":
                        applyColorAttribute((c) { button.defaultPaint.borderColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-shadow":
                        applyColorAttribute((c) { button.defaultPaint.shadowColor = c; }, attribute);
                        break;
                        
                    case "ui-background-color-hover":
                        applyColorAttribute((c) { button.hoverPaint.backgroundColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-bottom":
                        applyColorAttribute((c) { button.hoverPaint.backgroundBottomColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-border":
                        applyColorAttribute((c) { button.hoverPaint.borderColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-shadow":
                        applyColorAttribute((c) { button.hoverPaint.shadowColor = c; }, attribute);
                        break;

                    case "ui-background-color-click":
                        applyColorAttribute((c) { button.clickPaint.backgroundColor = c; }, attribute);
                        break;
                    case "ui-background-color-click-bottom":
                        applyColorAttribute((c) { button.clickPaint.backgroundBottomColor = c; }, attribute);
                        break;
                    case "ui-background-color-click-border":
                        applyColorAttribute((c) { button.clickPaint.borderColor = c; }, attribute);
                        break;
                    case "ui-background-color-click-shadow":
                        applyColorAttribute((c) { button.clickPaint.shadowColor = c; }, attribute);
                        break;

                    default: break;
                }
            }

            button.fitToSize = false;

            component = button;
            break;

        case "progress":
            auto barPadding = 0;
            auto barPaddingAttribute = node.getAttribute("padding");
            if (barPaddingAttribute && barPaddingAttribute.value && barPaddingAttribute.value.length)
            {
                barPadding = to!int(barPaddingAttribute.value);
            }
            progress = new ProgressBar(window, barPadding);
            addComponent(progress);

            foreach (attribute; attributes)
            {
                switch (attribute.name)
                {
                    case "ui-background-color-bar":
                        applyColorAttribute((c) { progress.barFillColor = c; }, attribute);
                        break;
                    case "ui-border-color-bar":
                        applyColorAttribute((c) { progress.barBorderColor = c; }, attribute);
                        break;

                    default: break;
                }
            }

            size_t value = 0;
            auto valueAttribute = node.getAttribute("value");
            if (valueAttribute && valueAttribute.value && valueAttribute.value.length)
            {
                value = to!size_t(valueAttribute.value);
            }
            size_t upperValue = 100;
            auto upperValueAttribute = node.getAttribute("max");
            if (upperValueAttribute && upperValueAttribute.value && upperValueAttribute.value.length)
            {
                upperValue = to!size_t(upperValueAttribute.value);
            }

            progress.upperValue = upperValue;
            progress.value = value;

            component = progress;
            break;

        case "input":
            switch (node.getAttribute("type").value)
            {
                case "checkbox":
                    checkbox = new CheckBox(window);
                    addComponent(checkbox);

                    component = checkbox;
                    break;
                case "text":
                    textbox = new TextBox(window);
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

                            case "ui-background-color-default":
                                applyColorAttribute((c) { textbox.defaultPaint.backgroundColor = c; }, attribute);
                                break;
                            case "ui-background-color-default-border":
                                applyColorAttribute((c) { textbox.defaultPaint.borderColor = c; }, attribute);
                                break;
                            case "ui-background-color-default-shadow":
                                applyColorAttribute((c) { textbox.defaultPaint.shadowColor = c; }, attribute);
                                break;
                                
                            case "ui-background-color-hover":
                                applyColorAttribute((c) { textbox.hoverPaint.backgroundColor = c; }, attribute);
                                break;
                            case "ui-background-color-hover-border":
                                applyColorAttribute((c) { textbox.hoverPaint.borderColor = c; }, attribute);
                                break;
                            case "ui-background-color-hover-shadow":
                                applyColorAttribute((c) { textbox.hoverPaint.shadowColor = c; }, attribute);
                                break;

                            case "ui-background-color-focus":
                                applyColorAttribute((c) { textbox.focusPaint.backgroundColor = c; }, attribute);
                                break;
                            case "ui-background-color-focus-border":
                                applyColorAttribute((c) { textbox.focusPaint.borderColor = c; }, attribute);
                                break;
                            case "ui-background-color-focus-shadow":
                                applyColorAttribute((c) { textbox.focusPaint.shadowColor = c; }, attribute);
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

                    case "ui-background-color-default":
                        applyColorAttribute((c) { dropdown.defaultPaint.backgroundColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-bottom":
                        applyColorAttribute((c) { dropdown.defaultPaint.backgroundBottomColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-border":
                        applyColorAttribute((c) { dropdown.defaultPaint.borderColor = c; }, attribute);
                        break;
                    case "ui-background-color-default-shadow":
                        applyColorAttribute((c) { dropdown.defaultPaint.shadowColor = c; }, attribute);
                        break;
                        
                    case "ui-background-color-hover":
                        applyColorAttribute((c) { dropdown.hoverPaint.backgroundColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-bottom":
                        applyColorAttribute((c) { dropdown.hoverPaint.backgroundBottomColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-border":
                        applyColorAttribute((c) { dropdown.hoverPaint.borderColor = c; }, attribute);
                        break;
                    case "ui-background-color-hover-shadow":
                        applyColorAttribute((c) { dropdown.hoverPaint.shadowColor = c; }, attribute);
                        break;

                    default: break;
                }
            }

            component = dropdown;
            break;

        default: return null;
    }

    auto idAttribute = node.getAttribute("id");

    if (idAttribute && idAttribute.value && idAttribute.value.length)
    {
        _componentMap[idAttribute.value] = component;
    }

    auto width = node.getAttribute("width");
    auto height = node.getAttribute("height");

    if (width && width.value && width.value.length &&
        height && height.value && height.value.length)
    {
        component.size = IntVector(to!int(width.value), to!int(height.value));
    }

    if (checkbox)
    {
        checkbox.initialize();

        foreach (attribute; attributes)
        {
            switch (attribute.name)
            {
                case "ui-color":
                    applyColorAttribute((c) { checkbox.checkColor = c; }, attribute);
                    break;

                default: break;
            }
        }

        checkbox.updateRect();
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

    restyleComponents();

    if (component)
    {
        if (sectionComponent)
        {
            if (layoutHorizontal)
            {
                component.moveRightOf(sectionComponent, gap, node.hasAttribute("ui-position", "center"));
            }
            else
            {
                component.moveBelow(sectionComponent, gap, node.hasAttribute("ui-position", "center"));
            }
        }

        auto forAttribute = node.getAttribute("for");
        if (forAttribute && forAttribute.value && forAttribute.value.length && _componentMap)
        {
            auto forComponent = _componentMap.get(forAttribute.value, null);

            if (forComponent)
            {
                auto moveAttribute = node.getAttribute("move");

                if (moveAttribute && moveAttribute.value && moveAttribute.value.length)
                {
                    auto forGap = 0;

                    auto forGapAttribute = node.getAttribute("gap");
                    if (forGapAttribute && forGapAttribute.value && forGapAttribute.value.length)
                    {
                        forGap = to!int(forGapAttribute.value);
                    }

                    auto shouldCenter = node.hasAttribute("ui-position", "center");

                    switch (moveAttribute.value)
                    {
                        case "below":
                            component.moveBelow(forComponent, forGap, shouldCenter);
                            break;
                        case "right":
                            component.moveRightOf(forComponent, forGap, shouldCenter);
                            break;
                        case "left":
                            component.moveLeftOf(forComponent, forGap, shouldCenter);
                            break;
                        case "above":
                            component.moveAbove(forComponent, forGap, shouldCenter);
                            break;
                        default: break;
                    }
                }
            }
        }

        foreach (attribute; attributes)
        {
            switch (attribute.name)
            {
                case "ui-position":
                    if (!sectionComponent && !forAttribute)
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
                                case "center-y":
                                    if (parent)
                                    {
                                        component.position = IntVector(
                                            component.x,
                                            (parent.height / 2) - (component.height / 2)
                                        );
                                    }
                                    else
                                    {
                                        component.position = IntVector(
                                            component.x,
                                            (window.height / 2) - (component.height / 2)
                                        );
                                    }
                                    break;

                                case "center-x":
                                    if (parent)
                                    {
                                        component.position = IntVector(
                                            (parent.width / 2) - (component.width / 2),
                                            component.y
                                        );
                                    }
                                    else
                                    {
                                        component.position = IntVector(
                                            (window.width / 2) - (component.width / 2),
                                            component.y
                                        );
                                    }
                                    break;
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

                case "ui-margin-left":
                    auto marginValue = to!int(attribute.value);
                    component.position = IntVector(component.x + marginValue, component.y);
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
            auto scrollable = node.getAttribute("scrollable");
            if (scrollable)
            {
                scrollbar = new ScrollBar(window, panel);
                addComponent(scrollbar);
                
                scrollbar.isVertical = !scrollable.value || !scrollable.value.length || scrollable.value != "horizontal";
                
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
                
                if (scrollbar.isVertical)
                {
                    panel.scrollMargin = IntVector(0,cast(int)((cast(double)panel.height / 3.5) / 2));
                    scrollbar.position = IntVector(panel.x + panel.width, panel.y);
                }
                else
                {
                    panel.scrollMargin = IntVector(cast(int)((cast(double)panel.width / 3.5) / 2),0);
                    scrollbar.position = IntVector(panel.x, panel.y + panel.height);
                }
                
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

                if (scrollbar.isVertical)
                {
                    scrollbar.size = IntVector(16, panel.height);
                }
                else
                {
                    scrollbar.size = IntVector(panel.width, 16);
                }

                scrollbar.restyle();
                scrollbar.updateRect(false);
            }

            auto panelGap = 0;
            auto panelGapAttribute = node.getAttribute("gap");
            if (panelGapAttribute && panelGapAttribute.value && panelGapAttribute.value.length)
            {
                panelGap = to!int(panelGapAttribute.value);
            }

            // We do this here because we want panel styling first ...
            Component lastComponent = null;
            foreach (child; node.children)
            {
                lastComponent = generateHtmlUIComponent(language, window, view, child, initializer, panel, lastComponent, node.hasAttribute("layout", "horizontal"), panelGap);
            }
        }
    }

    restyleComponents();

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