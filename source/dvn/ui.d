/**
* Copyright (c) 2025 Project DVN
*/
module dvn.ui;

public
{
    import dvn.application;
    import dvn.atlas;
    import dvn.colors;
    import dvn.component;
    import dvn.delayedtask;
    import dvn.events;
    import dvn.fonts;
    import dvn.generator;
    import dvn.i18n;
    import dvn.meta;
    import dvn.painting;
    import dvn.sheetcollection;
    import dvn.surface;
    import dvn.texttools;
    import dvn.tools;
    import dvn.view;
    import dvn.unorderedlist;
    import dvn.window;
    import dvn.layout;
    
    import dvn.components;
    import dvn.external;
    import dvn.uigenerator;
}

public:
/// 
void takeScreenshot(Window window, string path)
{
    import std.string : toStringz;

    auto sshot = EXT_CreateRGBSurface(0, window.width, window.height, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
    EXT_RenderReadPixels(window.nativeScreen, null, EXT_PIXELFORMAT_ARGB8888, sshot.pixels, sshot.pitch);
    EXT_IMG_SavePNG(sshot, path.toStringz);
    EXT_FreeSurface(sshot);
}