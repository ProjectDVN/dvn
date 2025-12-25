/**
* Copyright (c) 2025 Project DVN
*/
module dvn.dom;

public
{
  import dvn.dom.domdocument;
  import dvn.dom.domnode;
  import dvn.dom.domattribute;
  import dvn.dom.domexception;
  import dvn.dom.domparser;
  import dvn.dom.domparsersettings;
  import dvn.dom.html;
  import dvn.dom.xhtml;
  import dvn.dom.xml;
  import dvn.dom.svg;
}

unittest
{
  HtmlDocument parseHtmlBody(string html)
  {
    auto doc = parseDom!HtmlDocument(`<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
  </head>
  <body>`~html~`</body>
</html>`, new HtmlParserSettings);
    return doc;
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <p>2</p>
      `)
      .body
      .querySelectorAll("*");

    assert(selection.length == 2);
    assert(selection[0].name == "h1" && selection[0].text == "1");
    assert(selection[1].name == "p" && selection[1].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <p>2</p>
        <p>3</p>
      `)
      .body
      .querySelectorAll(`p`);

    assert(selection.length == 2);
    assert(selection[0].name == "p" && selection[0].text == "2");
    assert(selection[1].name == "p" && selection[1].text == "3");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <p class="taketwo">2</p>
      `)
      .body
      .querySelectorAll("p.taketwo");

    assert(selection.length == 1);
    assert(selection[0].name == "p" && selection[0].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <p attr="taketwo">2</p>
      `)
      .body
      .querySelectorAll(`p[attr="taketwo"]`);

    assert(selection.length == 1);
    assert(selection[0].name == "p" && selection[0].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <div>
          <p>2</p>
          <p>3</p>
        </div>
      `)
      .body
      .querySelectorAll(`div > p`);
    
    assert(selection.length == 2);
    assert(selection[0].name == "p" && selection[0].text == "2");
    assert(selection[1].name == "p" && selection[1].text == "3");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <div>
          <p>2</p>
          <p>3</p>
        </div>
        <p>4</p>
      `)
      .body
      .querySelectorAll(`div + p`);
    
    assert(selection.length == 1);
    assert(selection[0].name == "p" && selection[0].text == "4");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <div>
          <p>2</p>
          <p>3</p>
        </div>
        <p>4</p>
        <p>5</p>
      `)
      .body
      .querySelectorAll(`div ~ p`);
    
    assert(selection.length == 2);
    assert(selection[0].name == "p" && selection[0].text == "4");
    assert(selection[1].name == "p" && selection[1].text == "5");
  }

  {
    auto selection =
      parseHtmlBody(`
        <div>
          <section>
            <p>1</p>
          </section>
        </div>
      `)
      .body
      .querySelectorAll(`div p`);

    assert(selection.length == 1);
    assert(selection[0].name == "p" && selection[0].text == "1");
  }

  {
    auto selection =
      parseHtmlBody(`
        <div>
          <p class="a">1</p>
          <p>2</p>
        </div>
      `)
      .body
      .querySelectorAll(`div > p.a`);

    assert(selection.length == 1);
    assert(selection[0].text == "1");
  }

  {
    auto selection =
      parseHtmlBody(`
        <p class="a b c">1</p>
        <p class="a c">2</p>
        <p class="b c">3</p>
      `)
      .body
      .querySelectorAll(`p.a.c`);

    assert(selection.length == 2);
    assert(selection[0].text == "1");
    assert(selection[1].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <p class="a b c">1</p>
        <p class="a c">2</p>
        <p class="b c">3</p>
      `)
      .body
      .querySelectorAll(`.a`);

    assert(selection.length == 2);
    assert(selection[0].text == "1");
    assert(selection[1].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <p data-id="user-123">1</p>
        <p data-id="admin-1">2</p>
      `)
      .body
      .querySelectorAll(`p[data-id^="user"]`);

    assert(selection.length == 1);
    assert(selection[0].text == "1");
  }

  {
    auto selection =
      parseHtmlBody(`
        <p data-id="user-123">1</p>
        <p data-id="user-999">2</p>
      `)
      .body
      .querySelectorAll(`p[data-id$="999"]`);

    assert(selection.length == 1);
    assert(selection[0].text == "2");
  }

  {
    auto selection =
      parseHtmlBody(`
        <p data-id="abc123">1</p>
        <p data-id="xyz">2</p>
      `)
      .body
      .querySelectorAll(`p[data-id*="123"]`);

    assert(selection.length == 1);
    assert(selection[0].text == "1");
  }

  {
    auto selection =
      parseHtmlBody(`
        <h1>1</h1>
        <p>2</p>
        <span>3</span>
      `)
      .body
      .querySelectorAll(`h1, span`);

    assert(selection.length == 2);
    assert(selection[0].name == "h1");
    assert(selection[1].name == "span");
  }

  {
    auto selection =
      parseHtmlBody(`
        <div></div>
        <p>1</p>
        <p>2</p>
        <p>3</p>
      `)
      .body
      .querySelectorAll(`div ~ p`);

    assert(selection.length == 3);
    assert(selection[0].text == "1");
    assert(selection[1].text == "2");
    assert(selection[2].text == "3");
  }

  {
    auto selection =
      parseHtmlBody(`
        <div>
          <p>1</p>
        </div>
      `)
      .body
      .querySelectorAll(`* > p`);

    assert(selection.length == 1);
    assert(selection[0].text == "1");
  }

  {
    auto selection =
        parseHtmlBody(`
            <p data-id="user-123">1</p>
            <p>2</p>
            <p data-id="admin-1">3</p>
        `)
        .body
        .querySelectorAll(`p[data-id]`);

    assert(selection.length == 2);
    assert(selection[0].text == "1");
    assert(selection[1].text == "3");
  }
}