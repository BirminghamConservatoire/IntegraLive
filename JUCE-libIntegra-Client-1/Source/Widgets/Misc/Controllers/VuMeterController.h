#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class VuMeterController : public Slider
{
public:
    //==========================================================================
    VuMeterController ();
    ~VuMeterController () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

    //==========================================================================
    void setValue (float value);

private:
    //==========================================================================
    Range<int> range;

    //==========================================================================
    int height = -1;
    float currentVolumeHeight = 0;
    float peakVolumeHeight = 0;
    Line<float> peakVolumeLine;

    //==========================================================================
    void mouseDown (const MouseEvent& event) override;

    //==========================================================================
    static constexpr int peakLineThickness = 4;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (VuMeterController)
};
