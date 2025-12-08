module dvn.views.emptyview;

import dvn.ui;

public final class EmptyView : View
{
	public:
	final:
	this(Window window)
	{
		super(window);
	}

	protected override void onInitialize(bool useCache)
	{
		EXT_DisableKeyboardState();
    }
}