#include "JuceHeader.h"
#include "FileSaveDialogWidget.h"

//==============================================================================
FileSaveDialogWidget::FileSaveDialogWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Save File");

    button.setButtonText ("SAVE");
    button.onClick = [this] { displayFileDialog ("*.wav,*.mp3"); };

    addAndMakeVisible (button);
}

FileSaveDialogWidget::~FileSaveDialogWidget () = default;

//==============================================================================
void FileSaveDialogWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void FileSaveDialogWidget::resized ()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void FileSaveDialogWidget::displayFileDialog (StringRef extensionForFileToSave)
{
    loadedFile = File();
    
    FileChooser chooser ("Select A Sound File",
                         File::getSpecialLocation (File::userHomeDirectory),
                         extensionForFileToSave);

    if (chooser.browseForFileToSave (true))
    {
        auto file = chooser.getResult ();
        loadedFile = file;
    }

}

var FileSaveDialogWidget::getValue()
{
    return loadedFile.getFullPathName();
}
