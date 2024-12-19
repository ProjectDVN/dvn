module zid.components.video;

import std.variant : Variant;

import zid.component;
import zid.external;
import zid.window;
import zid.events;
import zid.colors;
import zid.painting;
import zid.components.label;
import zid.components.panel;
import zid.components.scrollbar;

public final class Video : Component
{
    private:
    string[] _frames;
    size_t _frameIndex;
    uint _lastMS;
    uint _delay;

    public:
    final:
    this(Window window, string framesFolder)
    {
        import std.file : dirEntries, SpanMode;
        import std.array : array;
        import std.conv : to;
        import std.path : stripExtension, baseName;
        import std.algorithm : sort;

        super(window, false);

        _delay = 42;

        auto files = dirEntries(framesFolder, SpanMode.shallow).array();
        sort!((a, b) => baseName(stripExtension(a.name)).to!int < baseName(stripExtension(b.name)).to!int)(files);

        foreach (string name; files)
        {
            _frames ~= name;
        }
    }

    override void repaint()
    {

    }

    override void renderNativeComponent()
    {
        import std.string : toStringz;

        auto ms = EXT_GetTicks();

        if (_lastMS == 0 || (ms - _lastMS) > _delay)
        {
            _lastMS = ms;

            _frameIndex++;
        }

        if (_frameIndex >= _frames.length)
        {
            return;
        }

        auto path = _frames[_frameIndex];

        auto temp = EXT_IMG_Load(path.toStringz);
        auto texture = EXT_CreateTextureFromSurface(window.nativeScreen, temp);

        auto rect1 = new EXT_RectangleNative;
        rect1.x = 0;
        rect1.y = 0;
        rect1.w = width;
        rect1.h = height;

        auto rect2 = new EXT_RectangleNative;
        rect2.x = x;
        rect2.y = y;
        rect2.w = width;
        rect2.h = height;
        
        EXT_RenderCopy(window.nativeScreen, texture, rect1, rect2);

        EXT_DestroyTexture(texture);
        EXT_FreeSurface(temp);
    }
}