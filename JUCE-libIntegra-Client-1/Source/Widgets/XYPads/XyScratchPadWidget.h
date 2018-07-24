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
    XyScratchPadWidget();
    ~XyScratchPadWidget();

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (XyScratchPadWidget)
};
