package components.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import flexunit.framework.Assert;

	public class DragImage
	{
		static public function addDragImage( dragObject:UIComponent ):void
		{
			Assert.assertNull( _dragImage );
			
			_dragObject = dragObject;
			_dragImage = getDragImage( dragObject );
			_dragOffset = new Point( dragObject.mouseX, dragObject.mouseY );
			dragObject.systemManager.popUpChildren.addChild( _dragImage );
			dragObject.stage.addEventListener( DragEvent.DRAG_OVER, onDragOver );
			
		}

		
		static public function removeDragImage():void
		{
			Assert.assertNotNull( _dragImage );
			
			_dragObject.systemManager.popUpChildren.removeChild( _dragImage );
			_dragObject.stage.removeEventListener( DragEvent.DRAG_OVER, onDragOver );
			_dragImage = null;
		}
		
		
		static public function suppressDragImage():void
		{
			_dragImageSupressed = true;
			_dragImage.visible = false;
		}

		
		static private function onDragOver( event:DragEvent ):void
		{
			Assert.assertNotNull( _dragImage );
			
			if( _dragImageSupressed )
			{
				_dragImageSupressed = false;
			}
			else
			{
				_dragImage.x = _dragObject.stage.mouseX - _dragOffset.x;
				_dragImage.y = _dragObject.stage.mouseY - _dragOffset.y;
				_dragImage.visible = true;
			}
		}
		
		
		static private function getDragImage( dragObject:DisplayObject ):DisplayObject
		{
			var bitmapData:BitmapData = new BitmapData( dragObject.width, dragObject.height );
			var m:Matrix = new Matrix();
			bitmapData.draw( dragObject, m );
			
			var image:Image = new Image();
			image.source = new Bitmap( bitmapData );
			image.mouseEnabled = false;
			return image;
		}
		
		
		
		
		static private var _dragObject:UIComponent = null;
		static private var _dragImage:DisplayObject = null;
		static private var _dragOffset:Point = null;
		
		static private var _dragImageSupressed:Boolean = false;
	}
}