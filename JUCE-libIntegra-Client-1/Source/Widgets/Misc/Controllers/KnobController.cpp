#include "JuceHeader.h"
#include "KnobController.h"

//==============================================================================
KnobController::KnobController ()
{
    setSliderStyle (SliderStyle::RotaryVerticalDrag);
    
    // TODO: setRange function for slider/ knob types
    setRange (0, 16, 1);
}

KnobController::~KnobController () = default;

//==============================================================================
void KnobController::paint (Graphics& g)
{
    const auto width = getWidth ();
    const auto height = getHeight ();
    const auto sliderPos = (float) valueToProportionOfLength (getValue ());
    const auto rotaryStartAngle = getRotaryParameters ().startAngleRadians;
    const auto rotaryEndAngle = getRotaryParameters ().endAngleRadians;
    auto radius = jmin (getWidth () / 2, getHeight () / 2) - 2.0f;
    auto centreX = getLocalBounds ().getCentre ().getX ();
    auto centreY = getLocalBounds ().getCentre ().getY ();
    auto rx = centreX - radius;
    auto ry = centreY - radius;
    auto rw = radius * 2.0f;
    auto angle = rotaryStartAngle + sliderPos * (rotaryEndAngle - rotaryStartAngle);
    auto isMouseOver = isMouseOverOrDragging () && isEnabled ();

    g.setColour (findColour (Slider::rotarySliderFillColourId).withAlpha (isMouseOver ? 1.0f : 0.7f));

    {
        Path filledArc;
        filledArc.addPieSegment (rx, ry, rw, rw, rotaryStartAngle, angle, 0.0);
        g.fillPath (filledArc);
    }

    {
        auto lineThickness = jmin (15.0f, jmin (width, height) * 0.45f) * 0.1f;
        Path outlineArc;
        outlineArc.addPieSegment (rx, ry, rw, rw, rotaryStartAngle, rotaryEndAngle, 0.0);
        g.strokePath (outlineArc, PathStrokeType (lineThickness));
    }
}
