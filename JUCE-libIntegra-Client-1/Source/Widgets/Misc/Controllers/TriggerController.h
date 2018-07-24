#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class TriggerController : public Button
{
public:
    //==========================================================================
    TriggerController ();
    ~TriggerController () override;

    //==========================================================================
    void paintButton (Graphics& g, bool isMouseOverButton, bool isButtonDown) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TriggerController)
};
