#pragma once

#include "JuceHeader.h"

//==============================================================================
/*
*/
class XyPan : public Component
{
public:
    //==========================================================================
    XyPan ();
    ~XyPan () override;

    //==========================================================================
    void paint (Graphics&) override;
    void resized () override;

    //==========================================================================
    void setXValue (double newValue, NotificationType notification);
    void setYValue (double newValue, NotificationType notification);

    //==========================================================================
    void setXRange (double newMin, double newMax, double newInt);
    void setYRange (double newMin, double newMax, double newInt);

private:
    //==========================================================================
    double xValue, yValue;
    Value currentXValue;
    Value currentYValue;
    void updateValues (double xValue, double yValue, NotificationType notification);

    //==========================================================================
    NormalisableRange<double> xRange;
    NormalisableRange<double> yRange;
    void updateRange (NormalisableRange<double>& rangeToUpdate);

    //==========================================================================
    int numberOfDecimalPlaces = 3;

    //==========================================================================
    Colour padBackgroundColour = Colour::fromRGB (24, 30, 35);
    Colour thumbColour = Colour::fromRGB (252, 199, 7);

    //==========================================================================
    Rectangle<float> padBounds;
    Rectangle<float> xDisplayBounds;
    Rectangle<float> yDisplayBounds;
    Rectangle<float> thumbBounds;

    //==========================================================================
    int padRoundness = 5;
    int thumbThickness = 5;
    int thumbSize = 20;

    //==========================================================================
    bool dragging = false;
    void mouseDown (const MouseEvent& e) override;
    void mouseDrag (const MouseEvent& e) override;
    void mouseUp (const MouseEvent& e) override;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (XyPan)
};
