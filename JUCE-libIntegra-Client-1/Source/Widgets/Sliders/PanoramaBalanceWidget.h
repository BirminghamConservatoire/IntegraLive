#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/PanoramaBalanceController.h"

//==============================================================================
/*
*/
class PanoramaBalanceWidget : public Widget
{
public:
    //==========================================================================
    PanoramaBalanceWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~PanoramaBalanceWidget () override;
    
    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    PanoramaBalanceController slider;

    //==========================================================================
    void sliderMoved ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (PanoramaBalanceWidget)
};
