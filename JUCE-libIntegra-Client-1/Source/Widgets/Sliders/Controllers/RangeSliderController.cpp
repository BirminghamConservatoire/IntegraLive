#include "JuceHeader.h"
#include "RangeSliderController.h"

//==============================================================================
RangeSliderController::RangeSliderController () = default;

RangeSliderController::~RangeSliderController () = default;

//==============================================================================
void RangeSliderController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    if (getSliderStyle () == SliderStyle::LinearVertical)
    {
        g.fillRect (Rectangle<float> (area.getTopLeft ().x, area.getTopLeft ().y,
                                      getPositionOfValue (getValue ()), getHeight ()));
    }
    if (getSliderStyle () == SliderStyle::LinearHorizontal)
    {
        g.fillRect (Rectangle<float> (area.getTopLeft ().x, getPositionOfValue (getValue ()),
                                      area.getWidth (), area.getBottom ()));
    }
}
