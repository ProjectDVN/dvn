/**
* Copyright (c) 2025 Project DVN
*/
module dvn.components.video;

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

/// 
public final class Video : Component
{
    private:
    string[] _frames;
    size_t _frameIndex;
    uint _lastMS;
    uint _delay;
    alias EVENT = void delegate();
    EVENT[] _onFinishedEvents;
    bool _finished;
    bool _repeat;
    size_t _frameCount;

    public:
    final:
/// 
    this(Window window, string framesFolder, bool repeat = false)
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

        _frames = [];

        foreach (string name; files)
        {
            _frames ~= name;
        }

        _repeat = repeat;
        _frameCount = _frames.length;
    }
    
    @property
    {
/// 
        bool finished() { return _finished; }

/// 
        bool repeat() { return _repeat; }

/// 
        size_t frameIndex() { return _frameIndex; }
/// 
        void frameIndex(size_t frameIndexStart)
        {
            _frameIndex = frameIndexStart;
        }

/// 
        size_t frameCount() { return _frameCount; }
/// 
        void frameCount(size_t newFrameCount)
        {
            _frameCount = newFrameCount;
        }
    }

/// 
    void onFinishedVideo(EVENT event)
    {
        _onFinishedEvents ~= event;
    }

/// 
    void fireFinishedVideo()
    {
        if (!_onFinishedEvents)
        {
            return;
        }

        foreach (event; _onFinishedEvents)
        {
            event();
        }
    }

/// 
    override void repaint()
    {

    }

/// 
    override void renderNativeComponent()
    {
        if (_finished)
        {
            return;
        }

        import std.string : toStringz;

        auto ms = EXT_GetTicks();

        if (_lastMS == 0 || (ms - _lastMS) > _delay)
        {
            _lastMS = ms;

            _frameIndex++;
        }

        if (_frameIndex >= _frameCount)
        {
            _finished = true;
            fireFinishedVideo();

            if (_repeat && _frameCount)
            {
                _finished = false;
                _frameIndex = 0;
            }
            else
            {
                return;
            }
        }

        auto path = _frames[_frameIndex];

        auto temp = EXT_IMG_Load(path.toStringz);
        auto texture = EXT_CreateTextureFromSurface(window.nativeScreen, temp);

        auto rect1 = new EXT_RectangleNative;
        rect1.x = 0;
        rect1.y = 0;
        rect1.w = 1280;
        rect1.h = 720;

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