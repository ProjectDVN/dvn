module dvn.components.checkbox;

import std.variant : Variant;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.events;
import dvn.colors;
import dvn.painting;
import dvn.components.label;
import dvn.components.panel;
import dvn.components.scrollbar;

public final class CheckBox : Component
{
    private:
    bool _isChecked;
    Panel _checkMark;
    Color _checkColor;
    void delegate() _onChanged;

    public:
    final:
    this(Window window)
    {
        super(window, false);

        _onChanged = {};

        onMouseButtonUp(new MouseButtonEventHandler((b,p) {
            toggleCheck();
            return false;
        }));
    }

    @property
    {
        bool checked() { return _isChecked; }
        void checked(bool isChecked)
        {
            _isChecked = isChecked;
            if (_isChecked && _checkMark)
            {
                _checkMark.show();
            }
            else if (_checkMark)
            {
                _checkMark.hide();
            }

            _onChanged();
            updateRect(true);
        }

        Color checkColor() { return _checkColor; }
        void checkColor(Color newColor)
        {
            _checkColor = newColor;
            if (_checkMark)
            {
                _checkMark.fillColor = _checkColor;
                _checkMark.repaint();
                if (_isChecked)
                {
                    _checkMark.show();
                }
                else
                {
                    _checkMark.hide();
                }
            }
            
            updateRect(true);
        }
    }

    void initialize()
    {
        _checkMark = new Panel(window);
        super.addComponent(_checkMark, true);
        _checkMark.size = IntVector(
            width / 2,
            height / 2
        );
        _checkMark.position = IntVector(
            (width / 2) - (_checkMark.width / 2),
            (height / 2) - (_checkMark.height / 2)
        );
        _checkColor = "85c1e9".getColorByHex;
        _checkMark.fillColor = _checkColor;
        _checkMark.hide();
    }

    override void repaint()
    {
        auto rect = super.clientRect;

        if (_checkMark)
        {
           int centerX = (rect.w / 2) - ((_checkMark.width) / 2);
           int centerY = (rect.h / 2) - ((_checkMark.height) / 2);

           _checkMark.position = IntVector(centerX, centerY);
        }
    }

    override void renderNativeComponent()
    {
        renderChildren();
    }

    void onChanged(void delegate() handler)
    {
        if (!handler)
        {
            return;
        }

        _onChanged = handler;
    }

    void toggleCheck()
    {
        checked = !_isChecked;
    }
}