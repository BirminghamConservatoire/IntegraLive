#pragma once

#include "JuceHeader.h"

#include "../Widget.h"

//==============================================================================
/*
*/
class RecordButtonWidget : public Widget
{
public:
    //==========================================================================
    RecordButtonWidget ();
    ~RecordButtonWidget ();

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
        Down,
        NormalOn,
        OverOn,
        DownOn,
    };
    const DrawablePath createIcon (const IconStyle style) const;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (RecordButtonWidget)
};
