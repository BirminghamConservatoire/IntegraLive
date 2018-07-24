#pragma once

#include "JuceHeader.h"
#include "MidiLearnButton.h"

//==============================================================================
/*
*/
class Widget    : public Component
{
public:
    //==========================================================================
    Widget();
    ~Widget() override;
    
    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;
    
    //==========================================================================
    void setWidgetLabel (const String&);
    
protected:
    //==========================================================================
    Rectangle<int> controllerBounds = {};

private:
    //==========================================================================
    String primaryEndpointPath = {};
    
    //==========================================================================
    Label widgetLabel;
    ToggleButton showInPerformanceToggle;
    MidiLearnButton midiLearnButton;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (Widget)
    
};
