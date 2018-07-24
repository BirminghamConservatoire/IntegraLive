#pragma once

#include "JuceHeader.h"
#include "Widget.h"
#include "interface_definition.h"

//==============================================================================
class WidgetBuilder
{
public:
    //==========================================================================
    WidgetBuilder (Component& view);
    ~WidgetBuilder();
    
    //==========================================================================
    void buildWidget (integra_api::IWidgetDefinition& widgetDefinition);
    
private:
    //==========================================================================
    Component& view;
    
    //==========================================================================
    void setupWidget (Widget& widget, integra_api::IWidgetDefinition& widgetDefinition);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (WidgetBuilder)
};
