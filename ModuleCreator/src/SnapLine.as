package
{
	public class SnapLine
	{
		public function SnapLine( v1:Number, width:Number = 0 )
		{
			this.v1 = v1;
			this.v2 = v1 + width;
			
			if( Math.abs( v1 - v2 ) < _minSnaplineWidth )
			{
				var average:Number = ( v1 + v2 ) / 2;
				v1 = average - _minSnaplineWidth / 2;
				v2 = average + _minSnaplineWidth / 2;
			}
		}
		
		public var v1:Number;
		public var v2:Number;
		
		private static const _minSnaplineWidth:int = 4;
	}
}