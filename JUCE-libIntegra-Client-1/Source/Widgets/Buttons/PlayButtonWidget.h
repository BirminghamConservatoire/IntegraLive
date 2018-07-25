#pragma once

#include "JuceHeader.h"

#include "../Widget.h"

//==============================================================================
/*
*/
class PlayButtonWidget : public Widget
{
public:
    //==========================================================================
    PlayButtonWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~PlayButtonWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    const Colour baseColour = Colours::green;

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

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (PlayButtonWidget)
};
