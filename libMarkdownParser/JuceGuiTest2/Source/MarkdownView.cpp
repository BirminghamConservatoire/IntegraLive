//
//  MarkdownView.cpp
//  JuceGuiTest2 - App
//
//  Created by Shane Dunne on 2018-07-04.
//

#include "MarkdownView.hpp"
using namespace mdp;
#include <regex>

MarkdownView::MarkdownView()
    : plain(14, Font::plain)
    , underlined(14, Font::underlined)
    , bold(14, Font::bold)
    , italic(14, Font::italic)
    , boldItalic(14, Font::italic | Font::bold | Font::underlined)
    , fixedWidth(Font::getDefaultMonospacedFontName(), 14, Font::plain)
    , defaultColour(Colours::white)
    , linkColour(Colours::cornflowerblue)
{
    setMultiLine(true);
    setReadOnly(true);
    heading[0] = Font(20, Font::bold);
    heading[1] = Font(18, Font::bold);
    heading[2] = Font(16, Font::bold);
    heading[3] = boldItalic;
    heading[4] = bold;
    heading[5] = italic;
    setFont(plain);
    //setLineSpacing(1.25);
}

MarkdownView::~MarkdownView()
{
}

void MarkdownView::mouseDown(const MouseEvent& evt)
{
    TextEditor::mouseDown(evt);
    int idx = getTextIndexAt(evt.getMouseDownX(), evt.getMouseDownY());
    //DBG("MouseDown at index " + std::to_string(idx));

    for (WebLink* link : links)
    {
        if (idx >= link->start && idx < link->end)
        {
            DBG("Open URL " + link->url);
            break;
        }
    }
}

void MarkdownView::setMarkdownText(const std::string text)
{
    clear();
    listCounters[0] = 1;
    mdp::MarkdownNode root;
    parser.parse(text, root);
    interpretMarkdownNode(root);
}

void MarkdownView::interpretMarkdownNode(mdp::MarkdownNode& node, bool separateParagraphs, int level)
{
    MarkdownNodes& children = node.children();
    for (MarkdownNodeIterator it = children.begin(); it != children.end(); ++it)
    {
        int nodeData = it->data;
        switch (it->type)
        {
            case RootMarkdownNodeType:
                interpretMarkdownNode(*it, separateParagraphs, level + 1);
                break;
            case CodeMarkdownNodeType:
                if (separateParagraphs) insertTextAtCaret("\n");
                setFont(fixedWidth);
                insertTextAtCaret("   " + it->text + "\n");
                setFont(plain);
                break;
            case QuoteMarkdownNodeType:
                break;
            case HTMLMarkdownNodeType:
                break;
            case HeaderMarkdownNodeType:
            {
                int headingLevel = nodeData - 1;
                if (headingLevel > 5) headingLevel = 5;
                if (headingLevel < 0) headingLevel = 0;
                setFont(heading[headingLevel]);
                insertTextAtCaret(it->text + "\n");
                setFont(plain);
                if (nodeData == 1) insertTextAtCaret("\n");
            }
                break;
            case HRuleMarkdownNodeType:
                break;
            case ListItemMarkdownNodeType:
                for (int i=0; i < level; i++) insertTextAtCaret("  ");
                if (nodeData & MKD_LIST_ORDERED)
                {
                    if (level < 10)
                    {
                        listCounters[level + 1] = 1;
                        insertTextAtCaret(" " + std::to_string(listCounters[level]++) + ". ");
                    }
                    else
                    {
                        // if user goes beyond 10 levels of numbered list, just put ">>"
                        insertTextAtCaret(" >> ");
                    }
                }
                else
                {
                    // list is unordered
                    if (level < 1)
                    {
                        // Unicode for solid bullet - will be available in most fonts
                        insertTextAtCaret(String::fromUTF8(" \u2022 "));
                    }
                    else
                    {
                        // Unicode for open bullet - may not be available in some fonts
                        insertTextAtCaret(String::fromUTF8(" \u25e6 "));
                    }
                }
                interpretMarkdownNode(*it, false, level + 1);
                break;
            case ParagraphMarkdownNodeType:
                interpretParagraphText(separateParagraphs, it->text);
                break;
            case TableMarkdownNodeType:
                break;
            case TableRowMarkdownNodeType:
                break;
            case TableCellMarkdownNodeType:
                break;
            case UndefinedMarkdownNodeType:
                break;
        }
    }
}

void MarkdownView::interpretParagraphText(bool separateParagraphs, const std::string &text)
{
    // Stage 1: replace emphasis strings with single characters
    std::string text1 = std::regex_replace(text, std::regex("[_\\*]{3}([^_\\*]*)[_\\*]{3}"), "\x03$1\x03");
    std::string text2 = std::regex_replace(text1, std::regex("[_\\*]{2}([^_\\*]*)[_\\*]{2}"), "\x02$1\x02");
    std::string text3 = std::regex_replace(text2, std::regex("[_\\*]([^_\\*]*)[_\\*]"), "\x01$1\x01");
    std::string text4 = std::regex_replace(text3, std::regex("\\[(.*)\\]\\((.*)\\)"), "\x04$1\x04\x05$2\x05");

    // Stage 2: scan modified string, stuffing text to TextEditor and building links[] array
    std::string urlText;
    int linkStart, linkEnd;

    bool strongEmphasis = false;
    bool emphasis = false;
    bool strong = false;
    bool linkUrl = false;
    bool linkText = false;
    bool code = false;

    if (separateParagraphs) insertTextAtCaret("\n");
    for (const char &c : text4)
    {
        if (c == '\x01')
        {
            if (!emphasis) setFont(italic);
            else setFont(plain);
            emphasis = !emphasis;
        }
        else if (c == '\x02')
        {
            if (!strong) setFont(bold);
            else setFont(plain);
            strong = !strong;
        }
        else if (c == '\x03')
        {
            if (!strongEmphasis) setFont(boldItalic);
            else setFont(plain);
            strongEmphasis = !strongEmphasis;
        }
        else if (c == '\x04')
        {
            if (!linkText) setColour(TextEditor::textColourId, linkColour);
            else setColour(TextEditor::textColourId, defaultColour);
            linkText = !linkText;
            if (linkText) linkStart = getCaretPosition();
            else linkEnd = getCaretPosition();
        }
        else if (c == '\x05')
        {
            if (linkUrl)
            {
                links.add(new WebLink(urlText, linkStart, linkEnd));
                urlText.clear();
            }
            linkUrl = !linkUrl;
        }
        else if (c == '`')
        {
            if (!code) setFont(fixedWidth);
            else setFont(plain);
            code = !code;
        }

        else if (linkUrl)
        {
            // stash the link URL
            urlText += c;
        }
        else
        {
            String oneChar;
            oneChar += c;
            insertTextAtCaret(oneChar);
        }
    }

    insertTextAtCaret("\n");
}
