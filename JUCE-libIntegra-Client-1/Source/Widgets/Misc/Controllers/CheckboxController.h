#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class CheckboxController : public ToggleButton
{
public:
    //==========================================================================
    CheckboxController ();
    ~CheckboxController () override;

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (CheckboxController)
};
