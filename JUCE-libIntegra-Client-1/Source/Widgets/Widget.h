#pragma once

#include "JuceHeader.h"
#include "MidiLearnButton.h"
#include "interface_definition.h"
#include "path.h"

//==============================================================================
/*
*/
class Widget    : public Component
{
public:
    //==========================================================================
    explicit Widget (integra_api::IWidgetDefinition& widgetDefinition);
    ~Widget () override;
    
    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;
    
    //==========================================================================
    void setWidgetLabel (const String&);
    
    //==========================================================================
    virtual void setValue (var value);
    
    //==========================================================================
    Rectangle<int> getWidgetBounds () noexcept;
    
protected:
    //==========================================================================
    Rectangle<int> controllerBounds = {};

private:
    //==========================================================================
    integra_api::IWidgetDefinition& widgetDefinition;
    Rectangle<float> bounds;
    
    //==========================================================================
    Label widgetLabel;
    ToggleButton showInPerformanceToggle;
    MidiLearnButton midiLearnButton;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (Widget)
};
