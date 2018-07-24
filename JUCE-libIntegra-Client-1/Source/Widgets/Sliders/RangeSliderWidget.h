#pragma once

#include "JuceHeader.h"
#include "../Widget.h"
#include "Controllers/RangeSliderController.h"

//==============================================================================
/*
*/
class RangeSliderWidget : public Widget
{
public:
    //==========================================================================
    RangeSliderWidget ();
    ~RangeSliderWidget ();

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    RangeSliderController slider;

    //==========================================================================
    void sliderMoved ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (RangeSliderWidget)
};
