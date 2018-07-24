#include "WidgetBuilder.h"
#include "JuceHeader.h"
#include "Widgets.h"
#include "interface_definition.h"

//==============================================================================
WidgetBuilder::WidgetBuilder (Component& v)
:   view (v)
{
}

WidgetBuilder::~WidgetBuilder() = default;

//==============================================================================
void WidgetBuilder::buildWidget (integra_api::IWidgetDefinition& widgetDefinition)
{
    auto widgetType = widgetDefinition.get_type();
    Widget* widget;
    
    if (widgetType == "Checkbox")                   widget = new CheckboxWidget ();
    else if (widgetType == "DryWetBalance")         widget = new DryWetBalanceWidget ();
    else if (widgetType == "EarlyLateBalance")      widget = new EarlyLateBalanceWidget ();
    else if (widgetType == "FileSaveDialog")        widget = new FileSaveDialogWidget ();
    else if (widgetType == "Knob")                  widget = new KnobWidget ();
    else if (widgetType == "NumberBox")             widget = new NumberBoxWidget ();
    else if (widgetType == "PanoramaBalance")       widget = new PanoramaBalanceWidget ();
    else if (widgetType == "PlayButton")            widget = new PlayButtonWidget ();
    else if (widgetType == "RadioGroup")            widget = new RadioGroupWidget ();
    else if (widgetType == "RangeSlider")           widget = new RangeSliderWidget ();
    else if (widgetType == "RecButton")             widget = new RecordButtonWidget ();
    else if (widgetType == "Slider")                widget = new SliderWidget ();
    else if (widgetType == "SoundFileLoadDialog")   widget = new SoundFileLoadDialogWidget ();
    else if (widgetType == "StopButton")            widget = new StopButtonWidget ();
    else if (widgetType == "Trigger")               widget = new TriggerWidget ();
    else if (widgetType == "VuMeter")               widget = new VuMeterWidget ();
    else if (widgetType == "XYPanPad")              widget = new XyPanPadWidget ();
    else if (widgetType == "XYScratchPad")          widget = new XyScratchPadWidget ();
    else
        // This should be a valid widget
        jassertfalse;
    
    setupWidget (*widget, widgetDefinition);
}

//==============================================================================
void WidgetBuilder::setupWidget (Widget& widget, integra_api::IWidgetDefinition& widgetDefinition)
{
    view.addAndMakeVisible (widget);
    
    Rectangle<int> bounds (widgetDefinition.get_position ().get_x (),
                           widgetDefinition.get_position ().get_y (),
                           widgetDefinition.get_position ().get_width (),
                           widgetDefinition.get_position ().get_height ());
    
    widget.setBounds (bounds);
}
