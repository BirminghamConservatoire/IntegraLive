#include "JuceHeader.h"
#include "DryWetBalanceController.h"

//==============================================================================
DryWetBalanceController::DryWetBalanceController () = default;

DryWetBalanceController::~DryWetBalanceController () = default;

//==============================================================================
void DryWetBalanceController::paint (Graphics& g)
{
    auto area = getLocalBounds ();

    g.fillRect (Rectangle<float> (area.getTopLeft().x, area.getTopLeft().y,
                                  getPositionOfValue (getValue()), getHeight()));
}
