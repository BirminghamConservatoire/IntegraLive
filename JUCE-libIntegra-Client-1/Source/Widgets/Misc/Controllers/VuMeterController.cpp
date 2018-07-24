#include "JuceHeader.h"
#include "VuMeterController.h"

//==============================================================================
VuMeterController::VuMeterController ()
: range (- 120, 0)
{
    setSliderStyle (LinearBarVertical);
    setTextBoxStyle (Slider::NoTextBox, false, 0, 0);
}

VuMeterController::~VuMeterController () = default;

//==============================================================================
void VuMeterController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    auto fillArea = Rectangle<float> (area.getTopLeft ().x, height - currentVolumeHeight,
                                      area.getWidth (), area.getBottom ());

    g.fillRect (fillArea);

    peakVolumeLine.setStart (0, height - peakVolumeHeight);
    peakVolumeLine.setEnd (getWidth (), height - peakVolumeHeight);

    g.setColour (Colours::red);
    g.drawLine (peakVolumeLine, peakLineThickness);
}

void VuMeterController::resized ()
{
    height = getHeight ();
}

//==============================================================================
void VuMeterController::setValue (float value)
{
    auto normalisedValue = (value - range.getStart ()) / (range.getEnd () - range.getStart ());

    currentVolumeHeight = normalisedValue * height;

    if (currentVolumeHeight > peakVolumeHeight)
        peakVolumeHeight = currentVolumeHeight;

    repaint ();
}

void VuMeterController::mouseDown (const MouseEvent& event)
{
    currentVolumeHeight = 0;
    peakVolumeHeight = 0;
}
