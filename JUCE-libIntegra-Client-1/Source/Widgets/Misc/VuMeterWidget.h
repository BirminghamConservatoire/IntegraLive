#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/VuMeterController.h"

//==============================================================================
/*
*/
class VuMeterWidget    : public Widget
{
public:
    //==========================================================================
    VuMeterWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~VuMeterWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    VuMeterController meter;

    //==========================================================================
    void setValue (var value) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (VuMeterWidget)
};
