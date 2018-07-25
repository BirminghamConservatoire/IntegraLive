#pragma once

#include "JuceHeader.h"
#include "../Widget.h"

//==============================================================================
/*
*/
class XyScratchPadWidget    : public Widget
{
public:
    //==========================================================================
    XyScratchPadWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~XyScratchPadWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (XyScratchPadWidget)
};
