/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.listpanel;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;
import dvn.events;
import dvn.components.panel;

public final class ListPanel : Panel
{
    private:
    int _listPadding;
    bool _center;
    Component _lastComponent;

    public:
    final:
    this(Window window, int listPadding = 0, bool center = false)
    {
        super(window);

        _listPadding = listPadding;
        _center = center;
    }

    override void addComponent(Component component)
    {
        if (_lastComponent)
        {
            component.moveBelow(_lastComponent, _listPadding, _center);
        }
        else
        {
            if (_center)
            {
                component.position = IntVector(
                    ((super.width / 2) - (component.width / 2)),
                    _listPadding
                );
            }
            else
            {
                component.position = IntVector(_listPadding, _listPadding);
            }
        }

        _lastComponent = component;

        super.addComponent(component);
    }
}