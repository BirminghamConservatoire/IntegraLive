#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/KnobController.h"

//==============================================================================
/*
*/
class KnobWidget : public Widget
{
public:
    //==========================================================================
    KnobWidget ();
    ~KnobWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    KnobController slider;

    //==========================================================================
    void sliderAction ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (KnobWidget)
};
