/*
  ==============================================================================

    This file was auto-generated!

  ==============================================================================
*/

#include "MainComponent.h"

//==============================================================================

std::string MainComponent::mdString1 =
    "# Header 1\n## Header 2\n"
    "This is a **script**. "
    "You can *write lua code here* in order to ***programatically get and set module endpoints***.\n"
    "\nFor documentation of the lua language [click here](http://www.lua.org/docs.html).\n"
    "\nScripts can be executed in the following ways:\n\n"
    "1. manually, by context-clicking the script's name and choosing 'Execute'.\n"
    "1. automatically, by adding a routing item and setting the target to the script's 'trigger' endpoint (the script will execute when the routing item's source endpoint is set).\n"
    "  * el barfo\n"
    "1. ethereally, through interpretive dance.\n"
    "\nScripts can access module endpoints via their paths, for example:\n"
    "\n    Player1.tick = Track1.Block1.AudioIn1.vu1 + 60"
    "\nAnother way: `Player1.tick = Track1.Block1.AudioIn1.vu1 + 60`";

MainComponent::MainComponent()
{
    setSize (600, 400);
    this->addAndMakeVisible(&markdownView);
    //markdownView.setMarkdownText(mdString1);

    FileChooser chooser("Choose a .md file");
    if (chooser.browseForFileToOpen())
    {
        File mdfile = chooser.getResult();
        String mdtext = mdfile.loadFileAsString();
        markdownView.setMarkdownText(mdtext.toStdString());
    }
}

MainComponent::~MainComponent()
{
}

//==============================================================================
void MainComponent::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    // This is called when the MainComponent is resized.
    markdownView.setBounds(this->getBounds());
}
