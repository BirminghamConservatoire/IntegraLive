#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class KnobController : public Slider
{
public:
    //==========================================================================
    KnobController ();
    ~KnobController () override;

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (KnobController)
};
