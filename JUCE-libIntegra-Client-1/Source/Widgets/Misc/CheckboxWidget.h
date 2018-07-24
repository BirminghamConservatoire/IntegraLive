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
    CheckboxWidget ();
    ~CheckboxWidget () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

private:
    //==========================================================================
    CheckboxController toggle;

    //==========================================================================
    void toggleAction ();

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (CheckboxWidget)
};
