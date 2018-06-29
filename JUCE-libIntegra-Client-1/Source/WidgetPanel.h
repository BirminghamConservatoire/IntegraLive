#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "IntegraServer.h"

struct Widget
{
    Slider* slider;
    bool isInteger;

    Widget(Slider* sli, bool isi) : slider(sli), isInteger(isi) {}
    ~Widget() { delete slider; }
};

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
    std::unordered_map< std::string, Widget* > widget_map;

    void make_label(IWidgetDefinition* widget, const IWidgetPosition& pos);
    void make_checkbox(IWidgetDefinition* widget, const INode* node);
    void make_slider(IWidgetDefinition* widget, const INode* node);
    void make_knob(IWidgetDefinition* widget, const INode* node);
    void make_drywet(IWidgetDefinition* widget, const INode* node);
    void make_vumeter(IWidgetDefinition* widget, const INode* node);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (WidgetPanel)
};
