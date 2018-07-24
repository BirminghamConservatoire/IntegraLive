#include "JuceHeader.h"
#include "TriggerController.h"

//==============================================================================
TriggerController::TriggerController ()
: Button ("Trigger")
{
}

TriggerController::~TriggerController () = default;

//==============================================================================
void TriggerController::paintButton (Graphics& g, bool isMouseOverButton, bool isButtonDown)
{
    const auto boundsSize = std::min (getWidth (), getHeight ());
    const auto area = getLocalBounds ().withSizeKeepingCentre (boundsSize, boundsSize).toFloat ();

    Colour baseColour = Colours::aquamarine.contrasting (0.2f);

    if (isButtonDown || isMouseOverButton)
        baseColour = baseColour.contrasting (isButtonDown ? 0.5f : 0.2f);

    g.setColour (baseColour);
    g.fillEllipse (area);

    g.setColour (Colours::white);
    g.drawText ("BANG", area, Justification::centred, true);
}

