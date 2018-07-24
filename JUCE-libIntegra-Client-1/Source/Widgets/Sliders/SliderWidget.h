#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/SliderController.h"

//==============================================================================
/*
*/
class SliderWidget : public Widget
{
public:
    //==========================================================================
    SliderWidget ();

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

    //==========================================================================
    void sliderMoved ();

private:
    //==========================================================================
    SliderController slider;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SliderWidget)
};
