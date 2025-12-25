module dvn.css.css3selectorparser;

import std.uni : isWhite, isAlphaNum;
import std.string : strip;

enum CssNodeType
{
    Unknown,
    Tag,
    Class,
    Id,
    Attribute,
    Pseudo,
    Combinator,
    Universal
}

struct CssNode
{
    CssNodeType type;
    string value;
    string extra;
    string operator;
    this(CssNodeType type, string value, string extra)
    {
        this.type = type;
        this.value = value;
        this.extra = extra;
    }
    this(CssNodeType type, string value, string operator, string extra)
    {
        this.type = type;
        this.value = value;
        this.operator = operator;
        this.extra = extra;
    }
}

struct Css3QueryParser
{
    CssNode[] nodes;
    size_t pos = 0;

    bool isEOF()
    {
        return pos >= nodes.length;
    }

    CssNode peekLast()
    {
        auto lastPos = pos - 1;
        if (lastPos < 0 || lastPos >= nodes.length) return CssNode(CssNodeType.Unknown, "", "");
        return nodes[lastPos];
    }

    CssNode peek(size_t amount = 0)
    {
        size_t ahead = pos + amount;
        if (ahead >= nodes.length) return CssNode(CssNodeType.Unknown, "", "");
        return nodes[ahead];
    }

    CssNode next()
    {
        if (pos >= nodes.length) return CssNode(CssNodeType.Unknown, "", "");
        return nodes[pos++];
    }
}

Css3QueryParser parseSelection(string selection)
{
    Css3QueryParser parser;
    size_t i = 0;

    bool isIdentChar(char c)
    {
        return c.isAlphaNum || c == '-' || c == '_';
    }

    string readIdent()
    {
        size_t start = i;
        while (i < selection.length && isIdentChar(selection[i]))
            i++;
        return selection[start .. i];
    }

    void skipWhitespace()
    {
        while (i < selection.length && selection[i].isWhite)
            i++;
    }

    while (i < selection.length)
    {
        skipWhitespace();
        if (i >= selection.length)
            break;

        char c = selection[i];

        if (c == '>' || c == '+' || c == '~')
        {
            parser.nodes ~= CssNode(
                CssNodeType.Combinator,
                selection[i .. i + 1],
                ""
            );
            i++;
            continue;
        }

        if (c.isWhite)
        {
            skipWhitespace();
            parser.nodes ~= CssNode(
                CssNodeType.Combinator,
                " ",
                ""
            );
            continue;
        }

        if (c == '*')
        {
            parser.nodes ~= CssNode(
                CssNodeType.Universal,
                "*",
                ""
            );
            i++;
            continue;
        }

        if (c == '.')
        {
            i++;
            parser.nodes ~= CssNode(
                CssNodeType.Class,
                readIdent(),
                ""
            );
            continue;
        }

        if (c == '#')
        {
            i++;
            parser.nodes ~= CssNode(
                CssNodeType.Id,
                readIdent(),
                ""
            );
            continue;
        }

        if (c == '[')
        {
            i++;
            skipWhitespace();
            string name = readIdent();
            skipWhitespace();

            string op;
            string val;

            if (i < selection.length && selection[i] != ']')
            {
                size_t opStart = i;
                while (i < selection.length && selection[i] != '=' && selection[i] != ']')
                    i++;
                if (i < selection.length && selection[i] == '=')
                {
                    i++;
                    op = selection[opStart .. i];
                    skipWhitespace();

                    if (selection[i] == '"' || selection[i] == '\'')
                    {
                        char quote = selection[i++];
                        size_t vStart = i;
                        while (i < selection.length && selection[i] != quote)
                            i++;
                        val = selection[vStart .. i];
                        i++;
                    }
                    else
                    {
                        size_t vStart = i;
                        while (i < selection.length && selection[i] != ']')
                            i++;
                        val = selection[vStart .. i].strip;
                    }
                }
            }

            if (i < selection.length && selection[i] == ']')
                i++;

            parser.nodes ~= CssNode(
                CssNodeType.Attribute,
                name,
                op,
                val
            );
            continue;
        }

        if (c == ':')
        {
            i++;
            string pseudo = readIdent();
            string args;

            if (i < selection.length && selection[i] == '(')
            {
                i++;
                size_t start = i;
                int depth = 1;
                while (i < selection.length && depth > 0)
                {
                    if (selection[i] == '(') depth++;
                    else if (selection[i] == ')') depth--;
                    i++;
                }
                args = selection[start .. i - 1];
            }

            parser.nodes ~= CssNode(
                CssNodeType.Pseudo,
                pseudo,
                args
            );
            continue;
        }

        if (isIdentChar(c))
        {
            parser.nodes ~= CssNode(
                CssNodeType.Tag,
                readIdent(),
                ""
            );
            continue;
        }

        i++;
    }

    return parser;
}

unittest
{
    {
        auto parser = parseSelection("p[data-id]");
        
        assert(parser.nodes && parser.nodes.length == 2);
        assert(parser.nodes[0].type == CssNodeType.Tag &&
            parser.nodes[0].value == "p");
        assert(parser.nodes[1].type == CssNodeType.Attribute &&
            parser.nodes[1].value == "data-id");
    }
    {
        auto parser = parseSelection("div > p.class#id[attr=value]:hover");

        assert(parser.nodes && parser.nodes.length == 7);
        assert(parser.nodes[0].type == CssNodeType.Tag &&
            parser.nodes[0].value == "div");
        assert(parser.nodes[1].type == CssNodeType.Combinator &&
            parser.nodes[1].value == ">");
        assert(parser.nodes[2].type == CssNodeType.Tag &&
            parser.nodes[2].value == "p");
        assert(parser.nodes[3].type == CssNodeType.Class &&
            parser.nodes[3].value == "class");
        assert(parser.nodes[4].type == CssNodeType.Id &&
            parser.nodes[4].value == "id");
        assert(parser.nodes[5].type == CssNodeType.Attribute &&
            parser.nodes[5].value == "attr" &&
            parser.nodes[5].operator == "=" &&
            parser.nodes[5].extra == "value");
        assert(parser.nodes[6].type == CssNodeType.Pseudo &&
            parser.nodes[6].value == "hover");
    }
}