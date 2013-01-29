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
	import flexunit.framework.Assert;
	import mx.core.UIComponent;
	
	
	public final class FontSize
	{
	    public static const LARGEST:Number = 20;
	    public static const LARGE:Number = 15;
	    public static const NORMAL:Number = 11;
	    public static const SMALL:Number = 9;
	    public static const SMALLEST:Number = 7;
	    
	    public static const STYLENAME:String = "fontSize";

		public static function getTextRowHeight( component:UIComponent ):Number
		{
			return component.getStyle( STYLENAME ) * 2.2;
		}


		public static function getButtonSize( component:UIComponent ):Number
		{
			return component.getStyle( STYLENAME ) * 1.5;
		}
	    
	    
	    public static function getLargerSize( fontSize:Number ):Number
	    {
	    	switch( fontSize )
	    	{
	    		case SMALLEST:	return SMALL;
	    		case SMALL:		return NORMAL;
	    		case NORMAL:	return LARGE;
	    		case LARGE:		return LARGEST;
	    		
	    		case LARGEST:	
	    		default:
	    			Assert.assertTrue( false );
	    			return NORMAL;		
	    	}
	    }


	    public static function getSmallerSize( fontSize:Number ):Number
	    {
	    	switch( fontSize )
	    	{
	    		case LARGEST:	return LARGE;
	    		case LARGE:		return NORMAL;
	    		case NORMAL:	return SMALL;
	    		case SMALL:		return SMALLEST;
	    		
	    		case SMALLEST:
	    		default:
	    			Assert.assertTrue( false );
	    			return NORMAL;		
	    	}
	    }
	}
}