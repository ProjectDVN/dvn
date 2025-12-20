/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.tabpage;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;
import dvn.events;
import dvn.components.panel;
import dvn.components.tabview;
import dvn.components.button;

public final class TabPage : Panel
{
    private:
    TabView _tabView;
    Button _tabButton;

    public:
    final:
    this(Window window, TabView tabView, Button tabButton)
    {
        super(window);

        _tabView = tabView;
        _tabButton = tabButton;
    }

    @property
    {
        TabView tabView() { return _tabView; }

        Button tabButton() { return _tabButton; }
    }

    override void show()
    {
        foreach (page; _tabView.pages)
        {
            if (page.id != super.id)
            {
                page.hide();
            }
        }

        super.show();
    }
}