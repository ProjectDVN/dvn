/**
* Copyright (c) 2025 Project DVN
*/
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