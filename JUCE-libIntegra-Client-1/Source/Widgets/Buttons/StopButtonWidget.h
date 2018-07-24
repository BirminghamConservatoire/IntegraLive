#pragma once

#include "JuceHeader.h"

#include "../Widget.h"

//==============================================================================
/*
*/
class StopButtonWidget : public Widget
{
public:
    //==========================================================================
    StopButtonWidget ();
    ~StopButtonWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    const Colour baseColour = Colours::red;

    //==========================================================================
    DrawableButton button;

    //==========================================================================
    void buttonClicked ();

    //==========================================================================
    enum IconStyle
    {
        Normal = 0,
        Over,
        Down
    };
    const DrawablePath createIcon (const IconStyle style) const;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (StopButtonWidget)
};
