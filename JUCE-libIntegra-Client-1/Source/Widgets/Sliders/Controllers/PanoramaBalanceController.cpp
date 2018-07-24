#include "JuceHeader.h"
#include "PanoramaBalanceController.h"

//==============================================================================
PanoramaBalanceController::PanoramaBalanceController () = default;

PanoramaBalanceController::~PanoramaBalanceController () = default;

//==============================================================================
void PanoramaBalanceController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    g.fillRect (Rectangle<float> (area.getTopLeft().x, area.getTopLeft().y,
                                  getPositionOfValue (getValue()), getHeight()));
}
