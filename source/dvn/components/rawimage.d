module dvn.components.rawimage;

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

public final class RawImage : Component
{
    private:
    EXT_Surface _temp;
    EXT_Texture _texture;
    bool _cleaned;
    EXT_RectangleNative* _rect1;
    EXT_RectangleNative* _rect2;

    public:
    final:
    this(Window window, string path, IntVector originalSize)
    {
        import std.string : toStringz;

        super(window, false);
        
        _temp = EXT_IMG_Load(path.toStringz);
        _texture = EXT_CreateTextureFromSurface(window.nativeScreen, _temp);

        _rect1 = new EXT_RectangleNative;
        _rect1.x = 0;
        _rect1.y = 0;
        _rect1.w = originalSize.x;
        _rect1.h = originalSize.y;
    }

    override void repaint()
    {
        _rect2 = new EXT_RectangleNative;
        _rect2.x = super.x;
        _rect2.y = super.y;
        _rect2.w = super.width;
        _rect2.h = super.height;
    }

    override void clean()
    {
        EXT_DestroyTexture(_texture);
        EXT_FreeSurface(_temp);

        _cleaned = true;

        super.clean();
    }

    override void renderNativeComponent()
    {
        if (!_texture || _cleaned)
        {
            return;
        }

        EXT_RenderCopy(window.nativeScreen, _texture, _rect1, _rect2);
    }
}