module dvn.css.css3parser;

struct CssRule
{
    string[] selectors;
    string[][string] properties;
}

bool empty(string s)
{
    return !s || !s.length;
}

CssRule[] parseCss(string css, int width = 0, int height = 0)
{
    import std.array : split, array;
    import std.string : indexOf, strip, stripRight;
    import std.algorithm : map, filter, startsWith, endsWith;
    import std.conv : to;

    CssRule[] rules;

    size_t pos = 0;
    while ((pos = css.indexOf("/*", pos)) != -1)
    {
        auto end = css.indexOf("*/", pos + 2);
        if (end == -1) break;
        css = css[0 .. pos] ~ css[end+2 .. $];
    }

    auto blocks = css.split("}");

    foreach(block; blocks)
    {
        string selectorText;
        string bodyText;
        bool skipRule = false;

        auto mediaPos = block.indexOf("@media");
        if(mediaPos != -1)
        {
            auto mediaEnd = block.indexOf("{", mediaPos);
            if(mediaEnd == -1) continue;

            auto condition = block[mediaPos + 6 .. mediaEnd].strip;

            bool ok = true;
            if(condition.startsWith("screen"))
            {
                auto parts = condition.split("and").map!(s => s.strip).array;
                foreach(part; parts[1..$])
                {
                    if(part.startsWith("(min-width"))
                    {
                        auto val = part.split(":")[1].strip.stripRight(")").strip;
                        if(val.endsWith("px"))
                            val = val[0..$-2];
                        if(width < to!int(val)) ok = false;
                    }
                    else if(part.startsWith("(max-width"))
                    {
                        auto val = part.split(":")[1].strip.stripRight(")").strip;
                        if(val.endsWith("px"))
                            val = val[0..$-2];
                        if(width > to!int(val)) ok = false;
                    }
                    else if(part.startsWith("(min-height"))
                    {
                        auto val = part.split(":")[1].strip.stripRight(")").strip;
                        if(val.endsWith("px"))
                            val = val[0..$-2];
                        if(height < to!int(val)) ok = false;
                    }
                    else if(part.startsWith("(max-height"))
                    {
                        auto val = part.split(":")[1].strip.stripRight(")").strip;
                        if(val.endsWith("px"))
                            val = val[0..$-2];
                        if(height > to!int(val)) ok = false;
                    }
                }

                if(!ok) { skipRule = true; }
            }

            block = block[mediaEnd+1 .. $].strip;
        }

        auto parts = block.split("{");
        if(parts.length != 2) continue;

        selectorText = parts[0].strip;
        bodyText = parts[1].strip;

        if(selectorText.empty || bodyText.empty) continue;
        if(skipRule) continue;

        string[] selectors = selectorText.split(",").map!(s => s.strip).array;

        string[][string] properties;
        auto lines = bodyText.split(";").map!(l => l.strip).filter!(l => !l.empty).array;

        foreach(line; lines)
        {
            auto kv = line.split(":");
            if(kv.length != 2) continue;

            string key = kv[0].strip;
            string valueText = kv[1].strip;

            string[] values;
            size_t i = 0;
            while(i < valueText.length)
            {
                if(valueText[i] == '"')
                {
                    auto end = valueText.indexOf('"', i+1);
                    if(end == -1) end = valueText.length - 1;
                    values ~= valueText[i+1 .. end];
                    i = end + 1;
                }
                else
                {
                    auto nextSpace = valueText.indexOf(' ', i);
                    if(nextSpace == -1) nextSpace = valueText.length;
                    auto val = valueText[i .. nextSpace].strip;
                    if(!val.empty)
                        values ~= val;
                    i = nextSpace + 1;
                }
                while(i < valueText.length && valueText[i] == ' ') i++;
            }

            properties[key] = values;
        }

        rules ~= CssRule(selectors, properties);
    }

    return rules;
}


unittest
{
    {
        auto rules = parseCss(`
            .myclass {
                margin: 10px 20px;
                font-family: calibri;
            }
        `);

        assert(rules && rules.length == 1);
        assert(rules[0].selectors && rules[0].selectors.length == 1);
        assert(rules[0].properties && rules[0].properties.length == 2);
        assert("margin" in rules[0].properties);
        assert(rules[0].properties["margin"] == ["10px", "20px"]);
        assert("font-family" in rules[0].properties);
        assert(rules[0].properties["font-family"] == ["calibri"]);
    }

    {
        auto rules = parseCss(`
            .myclass, div p {
                margin: 10px 20px;
                font-family: calibri;
            }
        `);

        assert(rules && rules.length == 1);
        assert(rules[0].selectors && rules[0].selectors.length == 2);
        assert(rules[0].selectors[0] == ".myclass");
        assert(rules[0].selectors[1] == "div p");
        assert(rules[0].properties && rules[0].properties.length == 2);
        assert("margin" in rules[0].properties);
        assert(rules[0].properties["margin"] == ["10px", "20px"]);
        assert("font-family" in rules[0].properties);
        assert(rules[0].properties["font-family"] == ["calibri"]);
    }

    {
        string css = `
            /* Regular rule always applies */
            p { color: red; }

            /* Media query for screens wider than 500px */
            @media screen and (min-width: 500px) {
                p { color: blue; font-size: 16px; }
            }

            /* Media query for screens smaller than 300px */
            @media screen and (max-width: 300px) {
                p { color: green; }
            }
        `;

        auto rules = parseCss(css, 600, 800);

        assert(rules.length == 2);

        assert("color" in rules[0].properties);
        assert(rules[0].properties["color"][0] == "red");

        assert("color" in rules[1].properties);
        assert(rules[1].properties["color"][0] == "blue");
        assert("font-size" in rules[1].properties);
        assert(rules[1].properties["font-size"][0] == "16px");

        auto rulesSmall = parseCss(css, 200, 800);

        assert(rulesSmall.length == 2);
        assert(rulesSmall[1].properties["color"][0] == "green");
    }

    {
        auto rules = parseCss(`
            p {
                font-family: "Times New Roman" Arial, sans-serif;
            }
        `);

        assert(rules.length == 1);
        assert(rules[0].properties["font-family"].length == 3);
        assert(rules[0].properties["font-family"][0] == "Times New Roman");
        assert(rules[0].properties["font-family"][1] == "Arial,");
        assert(rules[0].properties["font-family"][2] == "sans-serif");
    }

    {
        string css = `
            @media screen and (min-width: 400px) {
                h1, h2, .title {
                    color: purple;
                    margin: 0;
                }
            }
        `;
        auto rules = parseCss(css, 500, 800);

        assert(rules.length == 1);
        assert(rules[0].selectors.length == 3);
        assert(rules[0].selectors[0] == "h1");
        assert(rules[0].selectors[1] == "h2");
        assert(rules[0].selectors[2] == ".title");
        assert(rules[0].properties["color"][0] == "purple");
        assert(rules[0].properties["margin"][0] == "0");
    }

    {
        string css = `
            @media screen and (max-width: 300px) {
                p { font-size: 12px; }
            }
            @media screen and (min-width: 500px) {
                p { font-size: 16px; }
            }
        `;

        auto rules = parseCss(css, 600, 800);
        assert(rules.length == 1);
        assert(rules[0].properties["font-size"][0] == "16px");

        auto rulesSmall = parseCss(css, 200, 800);
        assert(rulesSmall.length == 1);
        assert(rulesSmall[0].properties["font-size"][0] == "12px");
    }

    {
        string css = `
            @media screen and (min-width: 400px) {
                /* This is a comment */
                div { display: block; }
            }
        `;

        auto rules = parseCss(css, 500, 800);
        assert(rules.length == 1);
        assert(rules[0].selectors[0] == "div");
        assert(rules[0].properties["display"][0] == "block");
    }

    {
        auto rules = parseCss(`
            p {

                color: red;;

                font-size: 14px;
            }
        `);

        assert(rules.length == 1);
        assert(rules[0].properties["color"][0] == "red");
        assert(rules[0].properties["font-size"][0] == "14px");
    }

    {
        auto rules = parseCss(`
            .myclass[myattribute] {
                margin: 10px 20px;
                font-family: calibri;
            }
        `);

        assert(rules && rules.length == 1);
        assert(rules[0].selectors && rules[0].selectors.length == 1);
        assert(rules[0].selectors[0] == ".myclass[myattribute]");
        assert(rules[0].properties && rules[0].properties.length == 2);
        assert("margin" in rules[0].properties);
        assert(rules[0].properties["margin"] == ["10px", "20px"]);
        assert("font-family" in rules[0].properties);
        assert(rules[0].properties["font-family"] == ["calibri"]);
    }
}