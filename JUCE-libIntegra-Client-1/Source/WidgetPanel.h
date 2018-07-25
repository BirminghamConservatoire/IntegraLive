#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "IntegraServer.h"
#include "Widgets/WidgetBuilder.h"

class WidgetPanel   : public AnimatedAppComponent
{
public:
    WidgetPanel(IntegraServer& server);
    ~WidgetPanel();

    void paint (Graphics&) override;
    void resized() override;
    void update() override;

    void clear();
    void populate(CPath activeNodePath);

private:
    IntegraServer& integra;
    CPath nodePath;
    std::unordered_map<std::string, Widget*> widgetMap;
    WidgetBuilder widgetBuilder;
    
    //======================================================================
    template <class Type>
    void setIntegraValue (integra_api::CPath path, Type value);
    
    //======================================================================
    template <class Type>
    void changeValueType (Type value);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (WidgetPanel)
};
