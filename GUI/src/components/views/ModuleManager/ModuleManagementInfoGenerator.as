package components.views.ModuleManager
{
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import components.model.IntegraContainer;
	import components.model.IntegraDataObject;
	import components.model.IntegraModel;
	import components.model.interfaceDefinitions.ControlInfo;
	import components.model.interfaceDefinitions.EndpointDefinition;
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.utils.Utilities;
	
	import flexunit.framework.Assert;

	public class ModuleManagementInfoGenerator
	{
		public function ModuleManagementInfoGenerator()
		{
			_model = IntegraModel.singleInstance;
		}
		
		
		public function getInstanceNames( interfaceDefinition:InterfaceDefinition ):String
		{
			return getInstanceNamesRecursive( _model.project, interfaceDefinition );
		}

		
		public function getModuleDifferenceSummary( versionsInUse:Vector.<InterfaceDefinition>, targetVersion:InterfaceDefinition, targetVersionLabel:String ):String
		{
			var output:String = "";

			var allComparatives:Vector.<InterfaceDefinition> = versionsInUse.concat();
			allComparatives.push( targetVersion );
			
			output += "###Module source\n\n";
			output += "* " + targetVersionLabel + ": " + targetVersion.moduleSourceLabel + "\n"; 
			
			for each( var versionInUse:InterfaceDefinition in versionsInUse )
			{
				output += "* " + getVersionInUseLabel( versionInUse, versionsInUse ) + ": " + versionInUse.moduleSourceLabel + "\n"; 
			}
			
			output += "\n\n###Last modified\n\n";
			output += "* " + targetVersionLabel + ": " + targetVersion.interfaceInfo.modifiedDateLabel + "\n"; 
			
			for each( versionInUse in versionsInUse )
			{
				output += "* " + getVersionInUseLabel( versionInUse, versionsInUse ) + ": " + versionInUse.interfaceInfo.modifiedDateLabel + "\n"; 
			}

			
			if( anyDifferences( allComparatives, "interfaceInfo.authorLabel" ) )
			{
				output += "\n\n###Author\n\n";
				output += "* " + targetVersionLabel + ": " + targetVersion.interfaceInfo.authorLabel + "\n"; 
				
				for each( versionInUse in versionsInUse )
				{
					output += "* " + getVersionInUseLabel( versionInUse, versionsInUse ) + ": " + versionInUse.interfaceInfo.authorLabel + "\n"; 
				}
			}

			for each( versionInUse in versionsInUse )
			{
				if( versionsInUse.length > 1 )
				{
					output += "\n\n### " + getVersionInUseLabel( versionInUse, versionsInUse ) + " -> " + targetVersionLabel;
				}
				else
				{
					output += "\n\n###Changes:";
				}

				
				output += getDifferences( versionInUse, targetVersion );
			}
			
			
			return output;
		}
		
		
		private function getDifferences( fromVersion:InterfaceDefinition, toVersion:InterfaceDefinition ):String
		{
			var output:String = "";
			
			if( fromVersion.interfaceInfo.label != toVersion.interfaceInfo.label ) 
			{
				output += "\n* Label changed";
			}

			if( fromVersion.interfaceInfo.description != toVersion.interfaceInfo.description ) 
			{
				output += "\n* Description changed";
			}
			
			if( !areArraysEqual( fromVersion.interfaceInfo.tags, toVersion.interfaceInfo.tags ) ) 
			{
				output += "\n* Tags changed";
			}
			
			output += getEndpointListDifferences( fromVersion.endpoints, toVersion.endpoints );
			
			if( !areArraysEqual( fromVersion.widgets, toVersion.widgets ) )
			{
				output += "\n* Widget layout changed";
			}
			
			if( fromVersion.implementationChecksum != toVersion.implementationChecksum )
			{
				output += "\n* Implementation changed";
			}
			
			return output;
			
		}
		
		
		private function getEndpointListDifferences( fromEndpoints:Vector.<EndpointDefinition>, endpointList2:Vector.<EndpointDefinition> ):String
		{
			var output:String = "";
			var fromEndpointSet:Object = new Object;
			var toEndpointSet:Object = new Object;
			var endpoint:EndpointDefinition;
			for each( endpoint in fromEndpoints ) fromEndpointSet[ endpoint.name ] = endpoint;
			for each( endpoint in endpointList2 ) toEndpointSet[ endpoint.name ] = endpoint;

			for each( endpoint in toEndpointSet )
			{
				if( !fromEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += "\n* Added endpoint " + getBriefEndpointDescription( endpoint );
				}
			}
			
			for each( endpoint in fromEndpointSet )
			{
				if( !toEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += "\n* Removed endpoint " + getBriefEndpointDescription( endpoint );
				}
			}

			for each( endpoint in toEndpointSet )
			{
				if( fromEndpointSet.hasOwnProperty( endpoint.name ) )
				{
					output += getEndpointDifferences( fromEndpointSet[ endpoint.name ], toEndpointSet[ endpoint.name ] );
				}
			}
			
			return output;
		}
		
		
		private function getEndpointDifferences( fromEndpoint:EndpointDefinition, toEndpoint:EndpointDefinition ):String
		{
			var differences:String = getDeepObjectDifferences( fromEndpoint, toEndpoint );
			if( differences.length == 0 )
			{
				return "";
			}
			
			return "\n* Endpoint '" + fromEndpoint.name + "' changed (" + differences + ")";
		}
		
		
		private function getBriefEndpointDescription( endpoint:EndpointDefinition ):String
		{
			var output:String = "'" + endpoint.name + "' (";
			
			switch( endpoint.type )
			{
				case EndpointDefinition.CONTROL:
					switch( endpoint.controlInfo.type )
					{
						case ControlInfo.BANG:
							output += ControlInfo.BANG;
							break;
						
						case ControlInfo.STATE:
							output += endpoint.controlInfo.stateInfo.type;
							break;
						
						default:
							Assert.assertTrue( false );
					}
					break;
					
				case EndpointDefinition.STREAM:
					output += endpoint.streamInfo.streamType + " " + endpoint.streamInfo.streamDirection;
					break;
				
				default:
					Assert.assertTrue( false );
					break;
					
			}
			
			output += ")";
			return output;
		}
		
		
		private function getDeepObjectDifferences( object1:Object, object2:Object, differencesAlreadyFound:Object = null ):String
		{
			var className:String = Utilities.getClassNameFromObject( object1 );
			Assert.assertTrue( className == Utilities.getClassNameFromObject( object2 ) );
			
			if( !differencesAlreadyFound ) 
			{
				differencesAlreadyFound = new Object;
			}
			
			var output:String = "";
			
			//just looks at getter methods for now			
			var commandAccessors:XMLList = describeType( object1 )..accessor;
			
			for each( var accessor:XML in commandAccessors )
			{
				if( accessor.@access == "writeonly" )
				{
					continue;	//skip if no getter is defined
				}
				
				var getterName:String = accessor.@name;
				
				var value1:Object = object1[ getterName ];
				var value2:Object = object2[ getterName ];
				
				var foundDifference:Boolean = false;
				
				if( !value1 || !value2 )
				{
					foundDifference = !( !value1 && !value2 );
				}					
				else
				{
					var className1:String = Utilities.getClassNameFromObject( value1 );
					var className2:String = Utilities.getClassNameFromObject( value2 );
					if( className1 != className2 )
					{
						foundDifference = true;
					}
					else
					{
						if( value1 is Number || value1 is String || value1 is Boolean )
						{
							foundDifference = ( value1 != value2 );
						}
						else
						{
							if( isArrayOrVector( value1 ) )
							{
								foundDifference = !areArraysEqual( value1, value2 );
							}
							else
							{
								if( className1 == Utilities.getClassNameFromClass( Object ) )
								{
									foundDifference = !areMapsEqual( value1, value2 );
								}
								else
								{
									var childDifferences:String = getDeepObjectDifferences( value1, value2, differencesAlreadyFound );
									if( childDifferences.length > 0 )
									{
										if( output.length > 0 ) output += ", ";
										output += childDifferences;
									}
								}
							}
						}
					}
				}

				
				if( foundDifference )
				{
					if( !differencesAlreadyFound.hasOwnProperty( getterName ) )
					{
						differencesAlreadyFound[ getterName ] = 1;
						if( output.length > 0 ) output += ", ";
						output += getterName;
					}
				}
			}
			
			return output;
		}
		
		
		private function getInstanceNamesRecursive( dataObject:IntegraDataObject, interfaceDefinition:InterfaceDefinition ):String
		{
			var output:String = "";
			
			if( dataObject.interfaceDefinition == interfaceDefinition )
			{
				output += "* " + _model.getPathStringFromID( dataObject.id ) + "\n";
			}
			
			if( dataObject is IntegraContainer )
			{
				var container:IntegraContainer = dataObject as IntegraContainer;
				for each( var child:IntegraDataObject in container.children )
				{
					output += getInstanceNamesRecursive( child, interfaceDefinition );
				}
			}
			
			return output;
		}
		
		
		private function getVersionInUseLabel( version:InterfaceDefinition, versions:Vector.<InterfaceDefinition> ):String
		{
			if( versions.length == 1 ) 
			{
				Assert.assertTrue( version == versions[ 0 ] );
				return "Version in use"; 
			}
			else
			{
				var index:int = versions.indexOf( version );
				Assert.assertTrue( index >= 0 );
				return "Version in use " + String( index + 1 );
			}
		}
		
		
		private function anyDifferences( toCompare:Vector.<InterfaceDefinition>, compareProperty:String ):Boolean
		{
			Assert.assertTrue( toCompare.length >= 1 );
			
			var value:Object = getDeepProperty( toCompare[ 0 ], compareProperty ); 
			for( var i:int = 1; i < toCompare.length; i++ )
			{
				if( value != getDeepProperty( toCompare[ i ], compareProperty ) ) return true;
			}

			return false;			
		}
		
		
		private function getDeepProperty( object:Object, deepProperty:String ):Object
		{
			var indexOfFirstDot:int = deepProperty.indexOf( "." );
			if( indexOfFirstDot < 0 )
			{
				if( !object.hasOwnProperty( deepProperty ) ) 
				{
					return null;
				}

				return object[ deepProperty ];
			}

			var subObject:String = deepProperty.substring( 0, indexOfFirstDot );
			if( !object.hasOwnProperty( subObject ) )
			{
				return null;
			}

			var subProperty:String = deepProperty.substring( indexOfFirstDot + 1 );
			return getDeepProperty( object[ subObject ], subProperty );
		}
		
		
		private function areDeepObjectsEqual( object1:Object, object2:Object ):Boolean
		{
			if( !object1 || !object2 )
			{
				return ( !object1 && !object2 );
			}
			
			var className1:String = Utilities.getClassNameFromObject( object1 );
			var className2:String = Utilities.getClassNameFromObject( object2 );
			
			if( className1 != className2 ) return false;
			
			if( object1 is String || object1 is Number )
			{
				return ( object1 == object2 );
			}
			
			if( isArrayOrVector( object1 ) )
			{
				return areArraysEqual( object1, object2 );
			}
			
			if( className1 == Utilities.getClassNameFromClass( Object ) )
			{
				return areMapsEqual( object1, object2 );
			}

			return areGettersEqual( object1, object2 );
		}
		
		
		private function areMapsEqual( map1:Object, map2:Object ):Boolean
		{
			for( var key:String in map1 )
			{
				if( !map2.hasOwnProperty( key ) ) return false;
				if( !areDeepObjectsEqual( map1[ key ], map2[ key ] ) ) return false; 
			}
			
			for( key in map2 )
			{
				if( !map1.hasOwnProperty( key ) ) return false;
			}

			return true;
		}

		
		private function areGettersEqual( object1:Object, object2:Object ):Boolean
		{
			Assert.assertNotNull( object1 );
			Assert.assertNotNull( object2 );
			var className:String = Utilities.getClassNameFromObject( object1 );
			Assert.assertTrue( className == Utilities.getClassNameFromObject( object2 ) );
			
			var commandAccessors:XMLList = describeType( object1 )..accessor;
			
			for each( var accessor:XML in commandAccessors )
			{
				if( accessor.@access == "writeonly" )
				{
					continue;	//skip if no getter is defined
				}
				
				var getterName:String = accessor.@name;

				if( !areDeepObjectsEqual( object1[ getterName ], object2[ getterName ] ) ) 
				{
					return false;
				}
			}
			
			return true;
		}
		
		
		//declared as objects so that we can use typed vectors
		private function areArraysEqual( array1:Object, array2:Object ):Boolean
		{
			if( array1.length != array2.length ) return false;
			
			for( var i:int = 0; i < array1.length; i++ )
			{
				if( !areDeepObjectsEqual( array1[ i ], array2[ i ] ) )  return false;
			}
			
			return true;
		}
		
		
		private function isArrayOrVector( object:Object ):Boolean
		{
			if( object is Array ) return true;
			
			const vectorFinder:String = "__AS3__.vec::Vector.<";
			var qualifiedClassName:String = getQualifiedClassName( object );
			
			return( qualifiedClassName.substr( 0, vectorFinder.length ) == vectorFinder );			
		}
		
		
		private var _model:IntegraModel;
	}
}