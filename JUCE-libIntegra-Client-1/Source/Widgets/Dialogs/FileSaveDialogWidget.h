#pragma once

#include "JuceHeader.h"
#include "../Widget.h"
#include "Controllers/FileSaveDialogController.h"

//==============================================================================
/*
*/
class FileSaveDialogWidget : public Widget
{
public:
    //==========================================================================
    FileSaveDialogWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~FileSaveDialogWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override ;

private:
    //==========================================================================
    FileSaveDialogController button;
    File loadedFile;

    //==========================================================================
    void displayFileDialog (StringRef extensionForFileToSave);
    
    //==========================================================================
    var getValue() override;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (FileSaveDialogWidget)
};
