#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class PanoramaBalanceController    : public Slider
{
public:
    //==========================================================================
    PanoramaBalanceController ();
    ~PanoramaBalanceController ();

    //==========================================================================
    void paint (Graphics&) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (PanoramaBalanceController)
};
