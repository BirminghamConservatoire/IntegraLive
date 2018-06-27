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

    getNodesBtn.onClick = [this] { integra.dump_nodes_details(); };
    getNodesBtn.setButtonText ("Dump node details");
    addAndMakeVisible(getNodesBtn);

    dumpStateBtn.onClick = [this] { integra.dump_state(); };
    dumpStateBtn.setButtonText ("Dump state");
    addAndMakeVisible(dumpStateBtn);

    loadFileBtn.onClick = [this] { integra.open_file("/Users/shane/Desktop/Integra Live/SimpleDelay.integra"); };
    loadFileBtn.setButtonText ("Load SimpleDelay.integra");
    addAndMakeVisible(loadFileBtn);

    loadFile2Btn.onClick = [this] { integra.open_file("/Users/shane/Desktop/Integra Live/StereoChorus.integra"); };
    loadFile2Btn.setButtonText ("Load StereoChorus.integra");
    addAndMakeVisible(loadFile2Btn);

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
    int numberOfBtns = 7;
    getModulesBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    getNodesBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    dumpStateBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    loadFileBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    loadFile2Btn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    updateParamBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
    saveFileBtn.setBounds (area.removeFromTop (proportionOfHeight (1.0/numberOfBtns)));
}
