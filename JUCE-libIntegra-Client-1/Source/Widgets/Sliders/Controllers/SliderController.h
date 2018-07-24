#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class SliderController    : public Slider
{
public:
    //==========================================================================
    SliderController ();
    ~SliderController ();

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SliderController)
};
