#pragma once

#include "../JuceLibraryCode/JuceHeader.h"
#include "IntegraServer.h"

using namespace integra_api;

class MainComponent   : public Component
{
public:
    MainComponent();
    ~MainComponent();

    void paint (Graphics&) override;
    void resized() override;

private:
    IntegraServer integra;

    TextButton startBtn, dumpStateBtn, loadFileBtn, updateParamBtn, saveFileBtn, stopBtn;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
