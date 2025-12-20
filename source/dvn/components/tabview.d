/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.tabview;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;
import dvn.events;
import dvn.components.panel;
import dvn.components.tabpage;
import dvn.components.button;
import dvn.layout;

public final class TabView : Component
{
    private:
    Panel _buttonsPanel;
    Panel _viewPanel;
    TabPage[] _pages;
    GridLayout _buttonLayout;

    public:
    final:
    this(Window window)
    {
        super(window, true);
    }

    @property
    {
        Panel buttonsPanel() { return _buttonsPanel; }
        Panel viewPanel() { return _viewPanel; }
        TabPage[] pages() { return _pages; }
    }

    TabPage addPage(dstring name, string buttonFont)
    {
        if (!_buttonsPanel)
        {
            _buttonsPanel = new Panel(super.window);
		    _buttonsPanel.borderColor = "000".getColorByHex;
            if (super.parent) super.parent.addComponent(_buttonsPanel);
            else if (super.view) super.view.addComponent(_buttonsPanel);
            else if (super.window) super.window.addComponent(_buttonsPanel);
        }

        if (!_viewPanel)
        {
            _viewPanel = new Panel(super.window);
            if (super.parent) super.parent.addComponent(_viewPanel);
            else if (super.view) super.view.addComponent(_viewPanel);
            else if (super.window) super.window.addComponent(_viewPanel);
        }

        auto button = new Button(window);
        _buttonsPanel.addComponent(button);
        button.size = IntVector(
            _buttonsPanel.width / (cast(int)_buttonsPanel.componentsLength + 1),
            _buttonsPanel.height);
        button.position = IntVector(0,0);
        button.fontName = buttonFont;
        button.fontSize = 18;
        button.textColor = "000".getColorByHex;
        button.text = name;
        button.fitToSize = false;
        button.show();

        auto page = new TabPage(window, this, button);
        page.position = IntVector(0, 0);
        _viewPanel.addComponent(page);
        _pages ~= page;

        button.onButtonClick(new MouseButtonEventHandler((b,p)
        {
            page.show();
        }));

        if (_viewPanel.componentsLength == 1)
        {
            page.show();
        }
        else
        {
            page.hide();
        }

        updateRect(false);

        return page;
    }

    override void repaint()
    {
        auto rect = super.clientRect;

        if (_buttonsPanel && _viewPanel)
        {
            _buttonsPanel.size = IntVector(super.width, (super.height / 100) * 8);
            _buttonsPanel.position = IntVector(rect.x, rect.y);

            _buttonLayout = new GridLayout(_buttonsPanel, 0, GridSizeMode.autoMode, GridSizeMode.fixed, 0, _buttonsPanel.height);

            auto buttonRow = _buttonLayout.addRow();
            
            foreach (c; _buttonsPanel.children)
            {
                auto b = cast(Button)c;
                if (b)
                {
                    b.size = IntVector(
                        _buttonsPanel.width / (cast(int)_buttonsPanel.componentsLength + 1),
                        _buttonsPanel.height);
                    buttonRow.add(b);
                }
            }

            _buttonLayout.update(false);

            _viewPanel.size = IntVector(super.width, (super.height / 100) * 92);
            _viewPanel.position = IntVector(rect.x, rect.y + _buttonsPanel.height);

            foreach (page; _pages)
            {
                page.size = _viewPanel.size;
            }
        }
    }

/// 
    override void renderNativeComponent()
    {
        renderChildren();
    }
}