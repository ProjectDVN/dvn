/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.progressbar;

import dvn.component;
import dvn.external;
import dvn.window;
import dvn.colors;
import dvn.events;
import dvn.components.panel;
import dvn.layout;

public final class ProgressBar : Component
{
    private:
    int _barPadding;
    Panel _barPanel;
    size_t _value;
    size_t _upperValue;
    Color _barFillColor;
    Color _barBorderColor;

    public:
    final:
    this(Window window, int barPadding = 8)
    {
        super(window, true);

        _barPadding = barPadding;
        _barFillColor = "2ECC71".getColorByHex;
        _barBorderColor = "239B56".getColorByHex;
    }

    @property
    {
        Color barFillColor() { return _barFillColor; }
        void barFillColor(Color color)
        {
            _barFillColor = color;
        }
        Color barBorderColor() { return _barBorderColor; }
        void barBorderColor(Color color)
        {
            _barBorderColor = color;
        }
        size_t upperValue() { return _upperValue; }
        void upperValue(size_t v)
        {
            _upperValue = v;

            updateBarPanel();
        }

        size_t value() { return _value; }
        void value(size_t v)
        {
            _value = v;

            updateBarPanel();
        }
    }

    void updateBarPanel()
    {
        if (!_barPanel)
        {
            _barPanel = new Panel(super.window);
            super.addComponent(_barPanel);
        }

        _barPanel.fillColor = _barFillColor;
        _barPanel.borderColor = _barBorderColor;

        auto progressValue = _value > 0 ? cast(uint)((cast(real)_value / cast(real)_upperValue) * cast(real)100) : 0;
        auto width = cast(int)((cast(double)super.width / cast(double)100) * cast(double)progressValue);

        _barPanel.size = IntVector(
            width - (_barPadding * 2),
            super.height - (_barPadding * 2));
        _barPanel.position = IntVector(_barPadding, _barPadding);
    }

/// 
  override void repaint()
  {
  }

  protected override void renderNativeComponent()
  {
    renderChildren();
  }
}