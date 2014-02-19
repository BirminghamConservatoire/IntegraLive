/* Integra Live graphical user interface
*
* Copyright (C) 2009 Birmingham City University
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA   02110-1301,
* USA.
*/


package components.utils
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import components.model.Info;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.Constraint;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.interfaceDefinitions.InterfaceInfo;
	import components.model.interfaceDefinitions.StateInfo;
	import components.model.interfaceDefinitions.StreamInfo;
	import components.model.interfaceDefinitions.ValueRange;
	
	import flexunit.framework.Assert;

	public class ModuleDocumentationWriter
	{
		public function ModuleDocumentationWriter( model:IntegraModel )
		{
			_model = model;
		}
		
		
		public function writeModuleDocumentation():void
		{
			var markdown:String = "#Integra Module Documentation\n\n";
			
			var interfacesToDocument:Vector.<InterfaceDefinition> = new Vector.<InterfaceDefinition>;
	
			for each( var moduleGuid:String in _model.interfaceList )
			{
				var interfaceDefinition:InterfaceDefinition = _model.getInterfaceDefinitionByModuleGuid( moduleGuid );
				Assert.assertNotNull( interfaceDefinition );
				
				interfacesToDocument.push( interfaceDefinition );
			}
			
			interfacesToDocument.sort( 
				function(x:InterfaceDefinition, y:InterfaceDefinition):Number 
				{ return ( x.interfaceInfo.label < y.interfaceInfo.label ) ? -1 : 1 } 
			);

			markdown += "##Contents:\n";
			markdown += "<div id='TOC'><ul>";
			for each( interfaceDefinition in interfacesToDocument )
			{
				markdown += "<li><a href='#" + getAnchorID( interfaceDefinition ) + "'>" + interfaceDefinition.interfaceInfo.label + "</a></li>";
			}
			markdown += "</ul></div>";
			markdown += "---\n\n";
			
			for each( interfaceDefinition in interfacesToDocument )
			{
				var interfaceInfo:InterfaceInfo = interfaceDefinition.interfaceInfo;
				markdown += "<h2 id='" + getAnchorID( interfaceDefinition ) + "'><a href='#TOC'>" + interfaceInfo.label + "</a></h2>\n\n";
				
				markdown += interfaceInfo.description + "\n\n";
				
				markdown += "<table>\n";
				markdown += "<tr><th>Endpoint</th><th>Type</th><th>Constraint</th><th>Description</th></tr>\n";
				for each( var endpoint:EndpointDefinition in interfaceDefinition.endpoints )
				{
					markdown += "<tr>\n";
					markdown += "<td><strong>" + endpoint.label + "</strong></td>\n";
					
					markdown += "<td>" + makeShortDescription( endpoint ) + "</td>\n";
					
					markdown += "<td>" + getConstraintDescription( endpoint ) + "</td>\n";

					markdown += "<td>" + getHtmlDocumentation( endpoint ) + "</td>\n";

					markdown += "</tr>\n";
				}
				markdown += "</table>\n\n"
	
				markdown += "_Source: " + interfaceDefinition.moduleSourceLabel + "_\n\n";
					
				if( interfaceInfo.author && interfaceInfo.author.length > 0 )
				{
					markdown += "_Author: " + interfaceInfo.author + "_\n\n";
				}
				
				markdown += "_Modified: " + interfaceInfo.modifiedDateLabel + "_\n\n";
					
				markdown += "---\n\n";
			}

			var cssFile:File = File.applicationDirectory.resolvePath( cssPath );
			if( cssFile.exists )
			{
				markdown += "<link rel='stylesheet' type='text/css' href='" + cssFile.nativePath + "'/>";
			}
			else
			{
				Trace.error( "Can't find css file", cssFile.nativePath );
			}

			var info:Info = new Info;
			info.markdown = markdown;
			var html:String = info.html;

			var outputFile:File = File.applicationStorageDirectory.resolvePath( moduleDocumentationFilename );
			
			var outputStream:FileStream = new FileStream();
			outputStream.open( outputFile, FileMode.WRITE );
			outputStream.writeUTFBytes( html );
			outputStream.close();
			
			navigateToURL( new URLRequest( "file://" + outputFile.nativePath ), "_blank" );
		}
		
		
		private function getAnchorID( interfaceDefinition:InterfaceDefinition ):String
		{
			return "id-" + interfaceDefinition.moduleGuid;
		}
		
		
		private function makeShortDescription( endpoint:EndpointDefinition ):String
		{
			var streamInfo:StreamInfo = endpoint.streamInfo;
			if( streamInfo )
			{
				return streamInfo.streamType + " " + streamInfo.streamDirection; 
			}
			
			var controlInfo:ControlInfo = endpoint.controlInfo;
			Assert.assertNotNull( controlInfo );
			
			if( controlInfo.type == ControlInfo.BANG )
			{
				return controlInfo.type;
			}
			
			var stateInfo:StateInfo = controlInfo.stateInfo;
			Assert.assertNotNull( controlInfo );
			
			return stateInfo.type;
		}
		
		
		private function getConstraintDescription( endpoint:EndpointDefinition ):String
		{
			if( !endpoint.isStateful ) return "";
			
			var constraint:Constraint = endpoint.controlInfo.stateInfo.constraint;
			
			var range:ValueRange = constraint.range; 
			if( range )
			{
				return "min " + formatValue( range.minimum ) + ", max " + formatValue( range.maximum );
			}
			
			var allowedValues:Vector.<Object> = constraint.allowedValues;
			Assert.assertNotNull( allowedValues );
			
			var description:String = "allowed values: [";
			var first:Boolean = true;
			for each( var allowedValue:Object in allowedValues )
			{
				if( first )
				{
					first = false;
				}
				else
				{
					description += ", ";
				}
				description += formatValue( allowedValue );
			}
			
			description += "]";
			
			return description;
		}

		
		private function formatValue( value:Object ):String
		{
			if( value is Number && !( value is int ) )
			{
				var decimalPlaces:int = 4;
				var multiplier:int = Math.pow( 10, decimalPlaces );
				return ( Math.round( Number( value ) * multiplier ) / multiplier ).toString(); 
			}
			else
			{
				return value.toString();
			}
		}
		
		
		private function getHtmlDocumentation( endpoint:EndpointDefinition ):String
		{
			var descriptionInfo:Info = new Info;
			descriptionInfo.markdown = endpoint.description;
			var descriptionHtml:String = descriptionInfo.html;
			descriptionHtml = descriptionHtml.replace( "<html>", "" );
			descriptionHtml = descriptionHtml.replace( "</html>", "" );
			
			return descriptionHtml;
		}

		
		private var _model:IntegraModel = null;
		
		private const cssPath:String = "assets/module_documentation_styles.css";
		private const moduleDocumentationFilename:String = "Module Documentation.htm";
	}
}