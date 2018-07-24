#pragma once

#include "JuceHeader.h"

#include "../Widget.h"
#include "Controllers/VuMeterController.h"

//==============================================================================
/*
*/
class VuMeterWidget    : public Widget
{
public:
    //==========================================================================
    VuMeterWidget();
    ~VuMeterWidget();

    //==========================================================================
    void paint (Graphics&) override;
    void resized() override;

private:
    //==========================================================================
    VuMeterController meter;

    //==========================================================================
    void setValue (double value);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (VuMeterWidget)
};
