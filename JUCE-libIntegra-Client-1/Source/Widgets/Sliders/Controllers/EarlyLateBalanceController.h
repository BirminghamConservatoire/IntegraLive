#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class EarlyLateBalanceController    : public Slider
{
public:
    //==========================================================================
    EarlyLateBalanceController ();
    ~EarlyLateBalanceController ();

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (EarlyLateBalanceController)
};
