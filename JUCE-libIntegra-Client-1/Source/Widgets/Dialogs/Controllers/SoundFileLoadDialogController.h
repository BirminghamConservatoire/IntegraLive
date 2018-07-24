#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class SoundFileLoadDialogController : public Button
{
public:
    //==========================================================================
    SoundFileLoadDialogController ();
    ~SoundFileLoadDialogController () override;

    //==========================================================================
    void paintButton (Graphics& g, bool isMouseOverButton, bool isButtonDown) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SoundFileLoadDialogController)
};
