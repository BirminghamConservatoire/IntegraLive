/*
  ==============================================================================

    This file was auto-generated!

  ==============================================================================
*/

#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "MarkdownView.hpp"

//==============================================================================
/*
    This component lives inside our window, and this is where you should put all
    your controls and content.
*/
class MainComponent : public Component
                    , public MenuBarModel
                    , public ApplicationCommandTarget
{
public:
    //==============================================================================
    MainComponent();
    ~MainComponent();

    // Component
    void paint (Graphics&) override;
    void resized() override;

    // MenuBarModel
    StringArray getMenuBarNames() override;
    PopupMenu getMenuForIndex (int topLevelMenuIndex,
                               const String& menuName) override;
    void menuItemSelected (int menuItemID,
                           int topLevelMenuIndex) override;

    // ApplicationCommandTarget
    enum CommandIDs
    {
        openFile = 1,
    };

    ApplicationCommandTarget* getNextCommandTarget() override;
    void getAllCommands (Array<CommandID>& commands) override;
    void getCommandInfo (CommandID commandID,
                         ApplicationCommandInfo& result) override;
    bool perform (const InvocationInfo& info) override;

private:
    //==============================================================================
    // Your private member variables go here...
    MarkdownView markdownView;
    std::unique_ptr<MenuBarComponent> menuBar;
    ApplicationCommandManager commandManager;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
