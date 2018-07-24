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
    TriggerWidget ();
    ~TriggerWidget () override;
    
    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    TriggerController button;
    
    //==========================================================================
    void buttonAction ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TriggerWidget)
};
