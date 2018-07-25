#pragma once

#include "JuceHeader.h"
#include "../Widget.h"
#include "Controllers/SoundFileLoadDialogController.h"

//==============================================================================
/*
*/
class SoundFileLoadDialogWidget : public Widget
{
public:
    //==========================================================================
    SoundFileLoadDialogWidget (integra_api::IWidgetDefinition& widgetDefinition);
    ~SoundFileLoadDialogWidget () override;

    //==========================================================================
    void paint (Graphics& g) override;
    void resized () override;

private:
    //==========================================================================
    SoundFileLoadDialogController button;

    //==========================================================================
    void displayFileDialog (StringRef extensionsToSearchFor);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (SoundFileLoadDialogWidget)
};
