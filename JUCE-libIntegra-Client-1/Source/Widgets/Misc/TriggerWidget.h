#pragma once

#include "JuceHeader.h"
#include "../Widget.h"
#include "Controllers/TriggerController.h"

//==============================================================================
/*
*/
class TriggerWidget : public Widget
{
public:
    //==========================================================================
    TriggerWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~TriggerWidget () override;
    
    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    TriggerController button;
    
    //==========================================================================
    void buttonAction ();
    
    //==========================================================================
    var getValue() override;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TriggerWidget)
};
