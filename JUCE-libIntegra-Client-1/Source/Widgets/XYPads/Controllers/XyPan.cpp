#include "JuceHeader.h"

#include "XyPan.h"

//==============================================================================
XyPan::XyPan ()
{
}

XyPan::~XyPan () = default;

//==============================================================================
void XyPan::setXValue (double newValue, NotificationType notification)
{

}

void XyPan::setYValue (double newValue, NotificationType notification)
{

}

void XyPan::updateValues (double xValue, double yValue, NotificationType notification)
{

}

//==========================================================================
void XyPan::setXRange (double newMin, double newMax, double newInt)
{
    xRange = { newMin, newMax, newInt,
               xRange.skew, xRange.symmetricSkew };
    updateRange (xRange);
}

void XyPan::setYRange (double newMin, double newMax, double newInt)
{
    yRange = { newMin, newMax, newInt,
               yRange.skew, yRange.symmetricSkew };
    updateRange (yRange);
}

void XyPan::updateRange (NormalisableRange<double>& range)
{
    numberOfDecimalPlaces = 3;

    if (range.interval != 0.0)
    {
        int v = std::abs (roundToInt (range.interval * 10000000));

        while ((v % 10) == 0 && numberOfDecimalPlaces > 0)
        {
            -- numberOfDecimalPlaces;
            v /= 10;
        }
    }

    //TODO: Create XyPad::setValue (T value)
//    setValue (getValue (), dontSendNotification);

    //TODO: Create XyPad::updateDisplay();
//    updateText ();
}

//==============================================================================
void XyPan::paint (Graphics& g)
{
    g.setColour (padBackgroundColour);
    g.fillRoundedRectangle (padBounds, padRoundness);

    auto mousePos = getMouseXYRelative ().toFloat ();
    thumbBounds = { mousePos,
                    { mousePos.getX () + thumbSize,
                      mousePos.getY () + thumbSize } };

    g.setColour (thumbColour);

    if (dragging)
        g.fillEllipse (thumbBounds);
    else
    {
        g.drawEllipse (thumbBounds.reduced (thumbThickness / 2), thumbThickness);
    }
}


void XyPan::resized ()
{
    padRoundness = std::min (proportionOfHeight (0.05), proportionOfWidth (0.05));
    thumbThickness = std::min (proportionOfHeight (0.03), proportionOfWidth (0.03));
    thumbSize = std::min (proportionOfHeight (0.2), proportionOfWidth (0.2));

    const auto spacing = std::min (proportionOfHeight (0.02), proportionOfWidth (0.02));
    const auto padSize = proportionOfHeight (0.8);
    const auto displayHeight = proportionOfHeight (0.8);
    const auto displayWidth = proportionOfWidth (0.4);

    auto area = getLocalBounds ().reduced (spacing).toFloat ();

    padBounds = area.removeFromTop (padSize);

    auto displayBounds = area.removeFromBottom (displayHeight);
    xDisplayBounds = displayBounds.removeFromLeft (displayWidth);
    yDisplayBounds = displayBounds.removeFromRight (displayWidth);

    thumbBounds = Rectangle<float> (0, padBounds.getBottomLeft ().getY () - thumbSize,
                                    thumbSize, thumbSize);
}

//==============================================================================
void XyPan::mouseDown (const MouseEvent& e)
{
//    mouseDragStartPosition = e.position;

    setMouseCursor (MouseCursor (MouseCursor::StandardCursorType::NoCursor));

    repaint ();
    mouseDrag (e);
}

void XyPan::mouseDrag (const MouseEvent& e)
{
    setMouseCursor (MouseCursor (MouseCursor::StandardCursorType::NoCursor));
    dragging = true;
    repaint ();
}

void XyPan::mouseUp (const MouseEvent& e)
{
    setMouseCursor (MouseCursor (MouseCursor::StandardCursorType::NormalCursor));
    dragging = false;
    repaint ();
}
