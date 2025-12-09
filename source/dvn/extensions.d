/**
* Copyright (c) 2025 Project DVN
*/
module dvn.extensions;

import dvn.events;

static if (__traits(compiles, { auto e = import("extensions.txt"); }))
{
    import std.string : strip;
    import std.array : split, replace;

    enum extensionsConfig = import("extensions.txt");

    private string generateExtensions()
    {
        string s = "";

        static foreach (extension; extensionsConfig
            .replace("\r", "")
            .split("\n"))
        {{
            static if (extension && extension.strip.length)
            {
                static if (__traits(compiles, { enum e = import(extension.strip); }))
                {
                    enum extensionModule = import(extension.strip);

                    s ~= extensionModule ~ "\r\n";
                }
            }
        }}

        return s;
    }

    mixin(generateExtensions);

    DvnEvents[] buildExtensionEvents()
    {
        DvnEvents[] result;

        static foreach (memberName; __traits(allMembers, dvn.extensions))
        {
            static if (__traits(compiles, {
                    alias T = mixin(memberName);
                    static if (is(T == class) && is(T : DvnEvents)) {}
                }))
            {{
                alias T = mixin(memberName);
                
                static if (is(T == class) && is(T : DvnEvents))
                {{
                    result ~= new T();
                }}
            }}
        }

        return result;
    }


    void registerExtensionEvents()
    {
        foreach (ev; buildExtensionEvents())
        {
            DvnEvents.setEvents(ev);
        }
    }
}
else
{
    DvnEvents[] buildExtensionEvents()
    {
        return [];
    }

    void registerExtensionEvents()
    {

    }
}