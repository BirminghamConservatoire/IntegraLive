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
    SliderWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~SliderWidget () override;
    
    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

    //==========================================================================
    void sliderMoved ();

private:
    //==========================================================================
    SliderController slider;
    
    //==========================================================================
    void setValue (var value) override;
    
    //==========================================================================
    var getValue() override;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SliderWidget)
};
