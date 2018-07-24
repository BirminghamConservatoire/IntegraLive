#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class FileSaveDialogController : public Button
{
public:
    //==========================================================================
    FileSaveDialogController ();
    ~FileSaveDialogController () override;

    //==========================================================================
    void paintButton (Graphics& g, bool isMouseOverButton, bool isButtonDown) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (FileSaveDialogController)
};
