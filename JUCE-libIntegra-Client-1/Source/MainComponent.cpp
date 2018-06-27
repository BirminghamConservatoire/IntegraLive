#include "MainComponent.h"
#include "server_startup_info.h"
#include "integra_session.h"
#include "interface_definition.h"
#include "error.h"
#include "server.h"
#include "server_lock.h"
#include "command.h"
#include "path.h"

MainComponent::MainComponent()
: integra("/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/modules",
          "/Users/shane/Documents/GitHub/IntegraLive/IntegraLive/third_party_modules")
{
    setSize (600, 400);

    getModulesBtn.onClick = [this] { integra.dump_modules_details(); };
    getModulesBtn.setButtonText ("Dump module details");
    addAndMakeVisible(getModulesBtn);

    dumpStateBtn.onClick = [this] { integra.dump_state(); };
    dumpStateBtn.setButtonText ("Dump state");
    addAndMakeVisible(dumpStateBtn);

    loadFileBtn.onClick = [this] { integra.open_file("/Users/shane/Desktop/Integra Live/SimpleDelay.integra"); };
    loadFileBtn.setButtonText ("Load .integra file");
    addAndMakeVisible(loadFileBtn);

    updateParamBtn.onClick = [this] { integra.update_param("SimpleDelay.Track1.Block1.Delay1.delayTime", 1.0f); };
    updateParamBtn.setButtonText ("Update delay time");
    addAndMakeVisible(updateParamBtn);

    saveFileBtn.onClick = [this] { integra.save_file("/Users/shane/Desktop/test.integra"); };
    saveFileBtn.setButtonText ("Save file");
    addAndMakeVisible(saveFileBtn);

    integra.start();
}

MainComponent::~MainComponent()
{
    integra.stop();
}

void MainComponent::paint (Graphics& g)
{
    // (Our component is opaque, so we must completely fill the background with a solid colour)
    g.fillAll (getLookAndFeel().findColour (ResizableWindow::backgroundColourId));
}

void MainComponent::resized()
{
    auto area = getLocalBounds();
    getModulesBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/5)));
    dumpStateBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/5)));
    loadFileBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/5)));
    updateParamBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/5)));
    saveFileBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/5)));
}
