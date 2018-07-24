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
    FileSaveDialogWidget ();
    ~FileSaveDialogWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override ;

private:
    //==========================================================================
    FileSaveDialogController button;

    //==========================================================================
    void displayFileDialog (StringRef extensionForFileToSave);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (FileSaveDialogWidget)
};
