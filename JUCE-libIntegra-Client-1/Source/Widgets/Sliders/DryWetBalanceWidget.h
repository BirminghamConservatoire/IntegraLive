#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/DryWetBalanceController.h"

//==============================================================================
/*
*/
class DryWetBalanceWidget : public Widget
{
public:
    //==========================================================================
    DryWetBalanceWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~DryWetBalanceWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    DryWetBalanceController slider;

    //==========================================================================
    void sliderMoved ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (DryWetBalanceWidget)

};
