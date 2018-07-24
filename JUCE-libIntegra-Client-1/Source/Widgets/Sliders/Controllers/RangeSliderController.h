#pragma once

#include "JuceHeader.h"


//==============================================================================
/*
*/
class RangeSliderController    : public Slider
{
public:
    //==========================================================================
    RangeSliderController ();
    ~RangeSliderController ();

    //==========================================================================
    void paint (Graphics&) override;

    //==========================================================================
    bool isVertical = false;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (RangeSliderController)
};
