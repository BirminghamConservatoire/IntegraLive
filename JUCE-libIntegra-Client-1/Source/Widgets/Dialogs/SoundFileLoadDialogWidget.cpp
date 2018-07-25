#include "JuceHeader.h"
#include "SoundFileLoadDialogWidget.h"

//==============================================================================
SoundFileLoadDialogWidget::SoundFileLoadDialogWidget (integra_api::IWidgetDefinition& widgetDefinition)
:   Widget (widgetDefinition)
{
    Widget::setWidgetLabel ("Sound File Load");

    button.setButtonText ("LOAD");
    button.onClick = [this] { displayFileDialog ("*.wav,*.mp3"); };

    addAndMakeVisible (button);
}

SoundFileLoadDialogWidget::~SoundFileLoadDialogWidget () = default;

//==============================================================================
void SoundFileLoadDialogWidget::paint (Graphics& g)
{
    Widget::paint (g);
}

void SoundFileLoadDialogWidget::resized ()
{
    Widget::resized ();
    button.setBounds (controllerBounds);
}

//==============================================================================
void SoundFileLoadDialogWidget::displayFileDialog (StringRef extensionsToSearchFor)
{
    FileChooser chooser ("Select A Sound File",
                         File::getSpecialLocation (File::userHomeDirectory),
                         extensionsToSearchFor);

    if (chooser.browseForFileToOpen ())
    {
        auto file = chooser.getResult ();
        std::cout << file.getFullPathName () << std::endl;
    }
}
