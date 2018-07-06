#include "MainComponent.h"

MainComponent::MainComponent()
{
    menuBar.reset (new MenuBarComponent (this));
    addAndMakeVisible (menuBar.get());
    setApplicationCommandManagerToWatch (&commandManager);
    commandManager.registerAllCommandsForTarget (this);
    addKeyListener (commandManager.getKeyMappings());

#if JUCE_MAC
    MenuBarModel::setMacMainMenu(this);
#else
    menuBar->setVisible(true);
#endif
    menuItemsChanged();

    setSize (600, 400);

    this->addAndMakeVisible(&markdownView);
}

MainComponent::~MainComponent()
{
#if JUCE_MAC
    MenuBarModel::setMacMainMenu (nullptr);
#endif
}

void MainComponent::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    auto b = getLocalBounds();
#if !JUCE_MAC
    menuBar->setBounds (b.removeFromTop (LookAndFeel::getDefaultLookAndFeel()
                                         .getDefaultMenuBarHeight()));
#endif
    markdownView.setBounds(b);
}

//==============================================================================
StringArray MainComponent::getMenuBarNames()
{
    return { "File" };
}

PopupMenu MainComponent::getMenuForIndex (int topLevelMenuIndex,
                                          const String& menuName)
{
    PopupMenu menu;

    if (topLevelMenuIndex == 0)
    {
        menu.addCommandItem (&commandManager, CommandIDs::openFile);
    }

    return menu;
}

void MainComponent::menuItemSelected (int menuItemID,
                                      int topLevelMenuIndex)
{
    // nothing to do here
}

//==============================================================================
ApplicationCommandTarget* MainComponent::getNextCommandTarget()
{
    return this;
}

void MainComponent::getAllCommands (Array<CommandID>& commands)
{
    commands.add(CommandIDs::openFile);
}

void MainComponent::getCommandInfo (CommandID commandID,
                                    ApplicationCommandInfo& result)
{
    switch (commandID)
    {
        case CommandIDs::openFile:
            result.setInfo ("Open File", "Select a file for opening", "Menu", 0);
            result.addDefaultKeypress ('o', ModifierKeys::commandModifier);
            break;
        default:
            break;
    }
}

bool MainComponent::perform (const InvocationInfo& info)
{
    switch (info.commandID)
    {
        case CommandIDs::openFile:
        {
            FileChooser chooser("Choose a .md file");
            if (chooser.browseForFileToOpen())
            {
                File mdfile = chooser.getResult();
                String mdtext = mdfile.loadFileAsString();
                markdownView.setMarkdownText(mdtext.toStdString());
            }
        }
            break;
        default:
            return false;
    }

    return true;
}
