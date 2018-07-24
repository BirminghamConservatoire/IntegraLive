#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/EarlyLateBalanceController.h"

//==============================================================================
/*
*/
class EarlyLateBalanceWidget : public Widget
{
public:
    //==========================================================================
    EarlyLateBalanceWidget ();

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    EarlyLateBalanceController slider;

    //==========================================================================
    void sliderMoved ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (EarlyLateBalanceWidget)
};
