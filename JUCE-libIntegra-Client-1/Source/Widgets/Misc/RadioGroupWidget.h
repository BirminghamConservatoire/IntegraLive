#pragma once

#include "JuceHeader.h"
#include "../Widget.h"

//==============================================================================
/*
*/
class RadioGroupWidget : public Widget
{
public:
    //==========================================================================
    RadioGroupWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~RadioGroupWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (RadioGroupWidget)
};
