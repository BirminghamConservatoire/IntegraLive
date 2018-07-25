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
    RangeSliderWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~RangeSliderWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    RangeSliderController slider;

    //==========================================================================
    void sliderMoved ();
    
    //==========================================================================
    var getValue() override;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (RangeSliderWidget)
};
