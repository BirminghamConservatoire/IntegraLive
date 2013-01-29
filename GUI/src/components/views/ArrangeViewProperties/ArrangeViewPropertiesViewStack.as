package components.views.ArrangeViewProperties
{
	import components.model.userData.ColorScheme;

	import mx.containers.ViewStack;
	
	import flash.display.GradientType;
	import flash.geom.Matrix;

	public class ArrangeViewPropertiesViewStack extends ViewStack
	{
		public function ArrangeViewPropertiesViewStack()
		{
			super();
		}


		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_leftColor = 0xBEBEBE;
						_rightColor = 0xD3D3D3;
						break;
						
					case ColorScheme.DARK:
						_leftColor = 0x424242;
						_rightColor = 0x2D2D2D;
						break;
				}
				
				invalidateDisplayList();
			}
		}


		override protected function updateDisplayList( width:Number, height:Number ):void
		{
			super.updateDisplayList( width, height );
			
			graphics.clear();

			var matrix:Matrix = new Matrix();
  			matrix.createGradientBox( width, height, 0 );

			const alphas:Array = [ 1, 1 ];
			const ratios:Array = [0x00, 0xFF];

			var colors:Array = [ _leftColor, _rightColor ];

			graphics.beginGradientFill( GradientType.LINEAR, colors, alphas, ratios, matrix );
        	graphics.drawRect( 0, 0, width, height );
	    	graphics.endFill();
		}


		private var _leftColor:uint;
		private var _rightColor:uint;
	}
}