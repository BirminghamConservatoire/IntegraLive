#pragma once

#include "JuceHeader.h"

#include "../Widget.h"

//==============================================================================
/*
*/
class NumberBoxWidget    : public Widget
{
public:
    //==========================================================================
    NumberBoxWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~NumberBoxWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NumberBoxWidget)
};
