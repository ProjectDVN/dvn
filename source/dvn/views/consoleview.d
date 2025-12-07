/**
* Copyright (c) 2025 Project DVN
*/
module dvn.views.consoleview;

import std.conv : to;

import dvn.resources;
import dvn.gamesettings;
import dvn.views.gameview;
import dvn.events;
import dvn.music;

import dvn.ui;

public final class ConsoleView : View
{
	public:
	final:
	this(Window window)
	{
		super(window);

        _index = 0;
        _labels = new Label[window.height / 14];
	}

    private size_t _index;
    private Label[] _labels;

	protected override void onInitialize(bool useCache)
	{
		EXT_DisableKeyboardState();

		if (useCache) return;
		auto window = super.window;
		auto settings = getGlobalSettings();

        int y = 0;

        foreach (i; 0 .. _labels.length)
        {
            auto label = new Label(window);
            addComponent(label);
            label.fontName = settings.defaultFont;
            label.fontSize = 14;
            label.color = "fff".getColorByHex;
            label.text = " ";
            label.shadow = false;
            label.isLink = false;
            label.position = IntVector(14, y);
            label.updateRect();
            label.show();

            _labels[i] = label;

            y += 14;
        }
    }

    void clearAll()
    {
        _index = 0;

        foreach (label; _labels)
        {
            label.text = " ";
            label.updateRect();
            label.show();
        }
    }

    void printLine(string msg, string color = "fff")
    {
        if (_index >= _labels.length)
        {
            clearAll();
        }

        auto label = _labels[_index];
        import std.datetime : Clock;
        import std.string : format;
        auto time = Clock.currTime();
        label.text = ("[" ~ format("%s-%s-%s %s:%s.%s", time.year, time.month, time.day, time.hour, time.minute, time.second) ~ "] " ~ msg).to!dstring;
        label.color = color.getColorByHex;
        label.updateRect();
        label.show();

        _index++;
    }
}

void logInfo(string msg)      { printLineToConsole(msg, "0cf"); }
void logWarning(string msg)   { printLineToConsole(msg, "f80"); }
void logError(string msg)     { printLineToConsole(msg, "f00"); }
void logDialogue(string msg)  { printLineToConsole(msg, "fcf"); }
void logNetwork(string msg)   { printLineToConsole(msg, "ff0"); }

void logInfo(Char, Args...)(in Char[] fmt, Args args)      { import std.string : format; printLineToConsole(format(fmt, args), "0cf"); }
void logWarning(Char, Args...)(in Char[] fmt, Args args)   { import std.string : format; printLineToConsole(format(fmt, args), "f80"); }
void logError(Char, Args...)(in Char[] fmt, Args args)     { import std.string : format; printLineToConsole(format(fmt, args), "f00"); }
void logDialogue(Char, Args...)(in Char[] fmt, Args args)  { import std.string : format; printLineToConsole(format(fmt, args), "fcf"); }
void logNetwork(Char, Args...)(in Char[] fmt, Args args)   { import std.string : format; printLineToConsole(format(fmt, args), "ff0"); }

void printLineToConsoleColor(Char, Args...)(in Char[] fmt, string color, Args args)
{
    import std.string : format; 
    printLineToConsole(format(fmt, args), color);
}
void printLineToConsole(Char, Args...)(in Char[] fmt, Args args)
{
    import std.string : format; 
    printLineToConsole(format(fmt, args));
}
void printLineToConsole(string msg, string color = "fff")
{
    auto app = getApplication();
    if (!app.isDebugMode) return;
    auto windows = app.windows;

    foreach (window; windows)
    {
        auto view = window.getActiveView!ConsoleView("ConsoleView");

        if (view)
        {
            view.printLine(msg, color);
        }
    }

    import std.stdio : writeln;
    writeln(msg);
}