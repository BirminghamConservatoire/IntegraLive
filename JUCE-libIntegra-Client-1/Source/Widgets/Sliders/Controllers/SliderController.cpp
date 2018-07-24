#include "JuceHeader.h"
#include "SliderController.h"

//==============================================================================
SliderController::SliderController () = default;

SliderController::~SliderController () = default;

//==============================================================================
void SliderController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    if (getSliderStyle () == SliderStyle::LinearVertical)
    {
        g.fillRect (Rectangle<float> (area.getTopLeft ().x, getPositionOfValue (getValue ()),
                                      area.getWidth (), area.getBottom ()));
    }
    else if (getSliderStyle () == SliderStyle::LinearHorizontal)
    {
        g.fillRect (Rectangle<float> (area.getTopLeft ().x, area.getTopLeft ().y,
                                      getPositionOfValue (getValue ()), getHeight ()));
    }
}
