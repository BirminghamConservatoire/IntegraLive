#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class DryWetBalanceController    : public Slider
{
public:
    //==========================================================================
    DryWetBalanceController ();
    ~DryWetBalanceController ();

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (DryWetBalanceController)
};
