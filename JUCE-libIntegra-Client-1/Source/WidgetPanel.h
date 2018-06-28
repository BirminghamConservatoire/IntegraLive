#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "IntegraServer.h"

class WidgetPanel   : public Component
{
public:
    WidgetPanel(IntegraServer& server);
    ~WidgetPanel();

    void paint (Graphics&) override;
    void resized() override;

    void clear();
    void populate(CPath activeNodePath);

private:
    IntegraServer& integra;
    CPath nodePath;

    void make_label(IWidgetDefinition* widget, const IWidgetPosition& pos);
    void make_checkbox(IWidgetDefinition* widget, const INode* node);
    void make_slider(IWidgetDefinition* widget, const INode* node);
    void make_knob(IWidgetDefinition* widget, const INode* node);
    void make_drywet(IWidgetDefinition* widget, const INode* node);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (WidgetPanel)
};
