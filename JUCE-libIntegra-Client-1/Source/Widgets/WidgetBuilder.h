#pragma once

#include "JuceHeader.h"
#include "Widget.h"
#include "interface_definition.h"

//==============================================================================
class WidgetBuilder
{
public:
    //==========================================================================
    explicit WidgetBuilder (Component& ownerView);
    ~WidgetBuilder();
    
    //==========================================================================
    Widget* createWidget (integra_api::IWidgetDefinition& widgetDefinition);
    
private:
    //==========================================================================
    Component& ownerView;
    
    //==========================================================================
    void addWidgetToView (Widget& widget, integra_api::IWidgetDefinition& widgetDefinition);
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (WidgetBuilder)
};
