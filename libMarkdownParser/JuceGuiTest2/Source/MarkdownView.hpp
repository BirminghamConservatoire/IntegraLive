//
//  MarkdownView.hpp
//  JuceGuiTest2 - App
//
//  Created by Shane Dunne on 2018-07-04.
//
//  Class MarkdownView is a juce::Component for displaying Markdown text.
//  It derives from juce::TextEditor and gains much of its functionality that way,
//  in particular the ability to handle an arbitrary mix of fonts and text colours,
//  and to resolve a mouse-click XY position to a character index.
//
//  Basic Markdown parsing is handled by the libMarkDownParser library
//  (see https://github.com/apiaryio/markdown-parser), which itself is based on
//  sundown (see https://github.com/apiaryio/sundown). Unfortunately, this parser
//  doesn't handle "inline" syntax elements such as *italic*, **bold**, etc.,
//  so I had to add some rather tricky regex-based code to do that.
//
//  I also had to add code to handle ordinal list numbering, and to handle embedded
//  web links. The latter is done by creating a list (actually a juce::OwnedArray)
//  of WebLink objects, each of which contains a URL and starting/ending character
//  indices for the corresponding clickable link text.
//
//  NOTE I have NOT attempted to handle every aspect of Markdown syntax. The idea
//  is simply to provide a usable subset, including the most common items, which
//  should suffice for Integra module descriptions. Hopefully, this code should be
//  suffficiently transparent to allow additional items to be added, following the
//  basic code structure used here.

#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "MarkdownParser.h"

struct WebLink
{
    std::string url;
    int start, end;

    WebLink(const std::string& urlText, int startIndex, int endIndex)
    : url(urlText), start(startIndex), end(endIndex) {}
};


class MarkdownView : public TextEditor
{
public:
    MarkdownView();
    ~MarkdownView();

    void setMarkdownText(const std::string text);

protected:
    void mouseDown(const MouseEvent& evt) override;

private:
    // TODO: Make these static.
    // I tried making these static, but the result was a memory leak in juce::TextEditor,
    // so I'm keeping the as ordinary members for now.
    Font plain, underlined, bold, italic, boldItalic, fixedWidth;
    Font heading[6];
    Colour linkColour;

    // List of Web links found in the Markdown text
    OwnedArray<WebLink> links;

    // Counters for numbering ordered lists up to 10 levels deep
    int listCounters[10];

    mdp::MarkdownParser parser;
    void interpretMarkdownNode(mdp::MarkdownNode& node, bool separateParagraphs=true, int level=0);
    void interpretParagraphText(bool separateParagraphs, const std::string &text);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MarkdownView)
};
