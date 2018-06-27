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

    TextButton getModulesBtn, getNodesBtn, dumpStateBtn;
    TextButton loadFileBtn, updateParamBtn, saveFileBtn;
    TextButton loadFile2Btn;
    
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (MainComponent)
};
