package components.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import mx.controls.Image;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.ISystemManager;
	
	import flexunit.framework.Assert;

	public class DragImage
	{
		static public function addDragImage( dragObject:UIComponent, edgeMargin:int = 0 ):void
		{
			Assert.assertNull( _dragImage );
			
			_stage = dragObject.stage;
			_systemManager = dragObject.systemManager;

			_dragImage = getDragImage( dragObject, edgeMargin );
			_dragOffset = new Point( dragObject.mouseX + edgeMargin, dragObject.mouseY + edgeMargin );
			dragObject.systemManager.popUpChildren.addChild( _dragImage );
			dragObject.stage.addEventListener( DragEvent.DRAG_OVER, onDragOver );
			
		}

		
		static public function removeDragImage():void
		{
			Assert.assertNotNull( _dragImage );
			
			_systemManager.popUpChildren.removeChild( _dragImage );
			_stage.removeEventListener( DragEvent.DRAG_OVER, onDragOver );
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
				_dragImage.x = _stage.mouseX - _dragOffset.x;
				_dragImage.y = _stage.mouseY - _dragOffset.y;
				
				if( !_dragImage.visible ) _dragImage.visible = true;
			}
		}
		
		
		static private function getDragImage( dragObject:DisplayObject, edgeMargin:int ):DisplayObject
		{
			var bitmapData:BitmapData = new BitmapData( dragObject.width + edgeMargin * 2, dragObject.height + edgeMargin * 2, true, 0 );
			
			var matrix:Matrix = new Matrix();
			matrix.translate( edgeMargin, edgeMargin );
			
			bitmapData.draw( dragObject, matrix );
			
			var image:Image = new Image();
			image.source = new Bitmap( bitmapData );
			image.mouseEnabled = false;
			return image;
		}
		
		
		static private var _dragImage:DisplayObject = null;
		static private var _dragOffset:Point = null;
		
		static private var _dragImageSupressed:Boolean = false;

		static private var _stage:Stage = null;
		static private var _systemManager:ISystemManager = null;
	}
}