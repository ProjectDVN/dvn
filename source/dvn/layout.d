/**
* Copyright (c) 2025 Project DVN
*/
module dvn.layout;

import dvn.ui;

public interface ILayout
{
    @property
    {
        int width();
        int height();
        IntVector size();

        int x();
        int y();
        IntVector position();
    }
}

public final class GridRow
{
    private:
    Component[] _children;

    public:
    final:
    this()
    {
        _children = [];
    }

    @property
    {
        package(dvn) Component[] children() { return _children; }
    }

    void add(Component component)
    {
        _children ~= component;
    }
}

public enum GridSizeMode
{
    autoMode,
    fixed
}

public final class GridLayout
{
    private:
    ILayout _parent;
    int _spacing;
    GridSizeMode _columnMode;
    GridSizeMode _rowMode;
    int _columnWidth;
    int _rowHeight;
    GridRow[] _rows;

    public:
    final:
    this(ILayout parent,
        int spacing,
        GridSizeMode columnMode = GridSizeMode.autoMode,
        GridSizeMode rowMode    = GridSizeMode.autoMode,
        int columnWidth = 0,
        int rowHeight = 0)
    {
        _parent = parent;
        _spacing = spacing;
        _columnWidth = columnWidth;
        _rowHeight = rowHeight;
        _rows = [];
    }

    GridRow addRow()
    {
        auto row = new GridRow;
        _rows ~= row;
        return row;
    }

    void update()
    {
        import std.algorithm : max;

        if (!_rows.length)
        {
            return;
        }

        size_t maxCols;
        foreach (row; _rows)
        {
            if (row.children.length > maxCols)
            {
                maxCols = row.children.length;
            }
        }

        if (maxCols == 0)
            return;

        auto colWidths   = new int[maxCols];
        auto rowHeights  = new int[_rows.length];

        foreach (ri, row; _rows)
        {
            foreach (ci, child; row.children)
            {
                if (_columnMode == GridSizeMode.autoMode)
                {
                    colWidths[ci] = max(colWidths[ci], child.width);
                }

                if (_rowMode == GridSizeMode.autoMode)
                {
                    rowHeights[ri] = max(rowHeights[ri], child.height);
                }
            }
        }

        if (_columnMode == GridSizeMode.fixed)
        {
            foreach (ref w; colWidths)
            {
                w = _columnWidth;
            }
        }

        if (_rowMode == GridSizeMode.fixed)
        {
            foreach (ref h; rowHeights)
            {
                h = _rowHeight;
            }
        }

        int startX = _parent.x;
        int startY = _parent.y;

        int y = startY;

        foreach (ri, row; _rows)
        {
            int x = startX;

            foreach (ci, child; row.children)
            {
                child.position = IntVector(x, y);
                
                x += colWidths[ci] + _spacing;
            }

            y += rowHeights[ri] + _spacing;
        }
    }
}

public enum Anchor
{
    topLeft,
    top,
    topRight,
    left,
    center,
    right,
    bottomLeft,
    bottom,
    bottomRight
}