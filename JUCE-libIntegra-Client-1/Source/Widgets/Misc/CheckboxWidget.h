#pragma once

#include "JuceHeader.h"
#include "../Widget.h"
#include "Controllers/CheckboxController.h"

//==============================================================================
/*
*/
class CheckboxWidget : public Widget
{
public:
    //==========================================================================
    CheckboxWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~CheckboxWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    CheckboxController toggle;

    //==========================================================================
    void toggleAction ();
    
    //==========================================================================
    var getValue() override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (CheckboxWidget)
};
