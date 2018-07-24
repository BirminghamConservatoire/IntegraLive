#include "JuceHeader.h"
#include "CheckboxController.h"

//==============================================================================
CheckboxController::CheckboxController () = default;

CheckboxController::~CheckboxController () = default;

//==============================================================================
void CheckboxController::paint (Graphics& g)
{
    const auto boundsSize = std::min (getWidth (), getHeight ());
    const auto circleSpacing = std::min (proportionOfWidth (0.05), proportionOfHeight (0.05));
    const auto outerCircleWidth = std::min (proportionOfHeight (0.03), proportionOfWidth (0.03));

    auto area = getLocalBounds ().withSizeKeepingCentre (boundsSize, boundsSize).toFloat ();

    Path outerCircle;
    outerCircle.addEllipse (area.reduced (outerCircleWidth));
    g.setColour (Colours::limegreen);
    g.strokePath (outerCircle, PathStrokeType (outerCircleWidth));

    area.reduced (circleSpacing);

    Path innerCircle;
    innerCircle.addEllipse (area.reduced (circleSpacing + outerCircleWidth));
    g.setColour (Colours::lightgrey);
    g.fillPath (innerCircle);

    String text (getToggleState () ? "On" : "Off");
    g.setColour (Colours::black);
    g.drawText (text, area, Justification::centred, true);
}

