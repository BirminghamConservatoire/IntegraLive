package components.model
{
	import components.model.interfaceDefinitions.InterfaceDefinition;
	import components.model.userData.BlockUserData;
	import components.model.userData.UserData;
	import components.utils.Trace;
	
	import flexunit.framework.Assert;
	
	public class IntegraContainer extends IntegraDataObject
	{
		public function IntegraContainer()
		{
			super();
			
			_info.canEdit = true;
		}
		
		public function get zIndex():int { return _zIndex; }
		public function get children():Object { return _children; }
		public function get scripts():Object { return _scripts; }
		public function get connections():Object { return _connections; }
		public function get scalers():Object { return _scalers; }
		public function get midi():Midi { return _midi; }
		public function get info():Info { return _info; }

		public function get userData():UserData { return internalUserData; }

		
		public function set zIndex( zIndex:int ):void { _zIndex = zIndex; }
		public function set children( children:Object ):void { _children = children; }
		
		public function copyContainerProperties( toCopy:IntegraContainer ):void
		{
			copyDataObjectProperties( toCopy );
			
			_info = toCopy.info;
			
			zIndex = toCopy.zIndex;
		}
		
		
		public function childrenChanged():void 
		{
			_connections = new Object;
			_scripts = new Object;
			_scalers = new Object;
			_midi = null;
			
			for each( var child:IntegraDataObject in children )
			{
				if( child is Connection )
				{
					_connections[ child.id ] = child;
				}

				if( child is Script )
				{
					_scripts[ child.id ] = child;
				}
				
				if( child is Scaler )
				{
					_scalers[ child.id ] = child;
				}

				if( child is Midi )
				{
					if( _midi )
					{
						Trace.error( "container has more than one midi object" );
					}
					else
					{
						_midi = child as Midi;
					}
				}
			} 
		}
		
		
		public function getNewChildName( prefix:String, moduleGuid:String ):String
		{
			var existingNameMap:Object = new Object;
			var existingChildrenOfSameType:int = 0;
			
			for each( var child:IntegraDataObject in _children )
			{
				existingNameMap[ child.name ] = 1;
				
				if( child.interfaceDefinition.moduleGuid == moduleGuid )
				{
					existingChildrenOfSameType++;
				}
			} 
			
			for( var number:int = existingChildrenOfSameType + 1; ; number++ )
			{
				var candidateName:String = prefix + String( number );
				if( existingNameMap.hasOwnProperty( candidateName ) )
				{
					continue;
				}
				
				return candidateName;
			}
			
			Assert.assertTrue( false );
			return null;  
		}
		
		
		override public function setAttributeFromServer( attributeName:String, value:Object, model:IntegraModel ):Boolean
		{
			if( super.setAttributeFromServer( attributeName, value, model ) )
			{
				return true;
			}
			
			switch( attributeName )
			{
				case "userData":
					Assert.assertNotNull( userData );
					Assert.assertTrue( value is String );
					userDataString = String( value );
					userData.load( userDataString, model, id );
					return true;
				
				case "zIndex":
					Assert.assertTrue( value is int );
					_zIndex = int( value );
					return true;
					
				case "info":
					_info.markdown = String( value );
					return true;					
								
				default:
					Assert.assertTrue( false );
					return false;
			}
		}
	
		
		override public function set id( id:int ):void 
		{ 	
			super.id = id;
			_info.ownerID = id;		
		}				
		
		override public function set name( name:String ):void 
		{ 	
			super.name = name;
			_info.title = name;		
		}		
		
		
		override public function getAllModuleGuidsInTree( results:Object ):void
		{
			super.getAllModuleGuidsInTree( results );
			
			for each( var descendant:IntegraDataObject in children )
			{
				descendant.getAllModuleGuidsInTree( results );
			}
		}		
		
		
		
		
		override public function get serverInterfaceName():String { return _serverInterfaceName; }
		public static const _serverInterfaceName:String = "Container";

		private var _zIndex:int = -1;
		private var _children:Object = new Object;
		
		private var _connections:Object = new Object;
		private var _scripts:Object = new Object;
		private var _scalers:Object = new Object;
		private var _midi:Midi = null;
		private var _info:Info = new Info; 
	}
}