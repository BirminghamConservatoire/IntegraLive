#include "JuceHeader.h"
#include "SoundFileLoadDialogController.h"

//==============================================================================
SoundFileLoadDialogController::SoundFileLoadDialogController ()
: Button ("SoundFileLoadDialogController")
{
}

SoundFileLoadDialogController::~SoundFileLoadDialogController () = default;

//==============================================================================
void SoundFileLoadDialogController::paintButton (Graphics& g, bool isMouseOverButton, bool isButtonDown)
{
    const auto boundsSize = std::min (getWidth (), getHeight ());
    const auto area = getLocalBounds ().withSizeKeepingCentre (boundsSize, boundsSize).toFloat ();

    Colour baseColour = Colours::aquamarine.contrasting (0.2f);

    if (isButtonDown || isMouseOverButton)
        baseColour = baseColour.contrasting (isButtonDown ? 0.5f : 0.2f);

    g.setColour (baseColour);
    g.fillEllipse (area);

    g.setColour (Colours::white);
    g.drawText ("Load Sound", area, Justification::centred, true);
}

