$(function(){
	// detects whether a legend element has fieldset siblings, indicating content that could be collapsed/expanded
	function hasContent() { return $(this).siblings("fieldset").length; }

	// toggles the 'collapsed' class on a legend, and the visibility of its fieldset siblings
	function toggle() { $(this).toggleClass("collapsed").siblings("fieldset").toggle(); }

	// apply collapsibility logic and UI elements to all legends with fieldset sibling content
	$("legend").filter(hasContent).each(toggle).click(toggle)
				.prepend("<i class='glyphicon glyphicon-minus'/>")
				.prepend("<i class='glyphicon glyphicon-plus'/>");
});

$(function(){
  // toggles the visibility of elements marked with the 'noref' class
	function toggleNoRefModules() { $(".noref").toggle(); }

	// apply noref toggle (to ensure that UI conforms to the initial unchecked 
	// state of cbToggleUnreferencedModules) and register as click handler
	$("#cbToggleUnreferencedModules").each(toggleNoRefModules).click(toggleNoRefModules);
});

$(function(){
  // toggles the display mode for XML attributes  
	function changeAttributeDisplayMode() { 
		var fs = $(this).parent().next("fieldset");
		fs.removeClass("att-none att-generic att-custom");
		fs.addClass("att-"+$(this).val())
	}

	// apply noref toggle (to ensure that UI conforms to the initial unchecked 
	// state of cbToggleUnreferencedModules) and register as change handler
	$("#selAttributeDisplayMode").each(changeAttributeDisplayMode).change(changeAttributeDisplayMode);
});

$(function() {
	function formatXml() {
		var html = $(this).html();
		html = html.replace(/&gt; /g,"&gt;<br/> ");
		html = html.replace(/&gt;&lt;/g,"&gt;<br/>&lt;");
		$(this).html(html);
	}
	$('li.userData span.value, p.text').each(formatXml);
});

$(function(){
	function formatModuleLegendText()
	{	
		var $this = $(this);
		var legend = $this.find("legend").first();
		var att = $this.children(".attributes");
		var id = att.find(".id").remove().find(".value").text() || "undefined";
		var name = att.find(".name").remove().find(".value").text() || "undefined";
		var type = att.find(".type").remove().find(".value").text() || "undefined";
		legend.html(legend.html()+" <small>("+type+":"+id+")</small>");
		if(att.children().length==0) att.remove();
	}

	$("fieldset.module").each(formatModuleLegendText);
});

$(function(){
	function formatEndpointLegendText()
	{	
		var $this = $(this);
		var legend = $this.find("legend").first();
		var att = $this.children(".attributes");
		var name = att.find(".name").remove().find(".value").text() || "undefined";
		var label = att.find(".label").remove().find(".value").text() || "undefined";
		var description = att.find(".description").remove().find(".value").text() || "undefined";
		var type = att.find(".type").remove().find(".value").text() || "undefined";
		legend.attr("title",type+":"+label+"\r\n\r\n"+description);
		if(att.children().length==0) att.remove();
	}

	$("fieldset.endpoints > .element").each(formatEndpointLegendText);
});

$(function(){
	$("li.error").append("<i class='glyphicon glyphicon-remove-circle'></i>");
	$("li.valid").append("<i class='glyphicon glyphicon-ok-circle'></i>");
});

