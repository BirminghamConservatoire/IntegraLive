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
 * 
 * Some of the code in this file was copied from the file "AsyncInPlace.mxml" written by Anirudh Sasikumar
 * The following text is the license originally distributed with that file: 
 *
 * Author: Anirudh Sasikumar (http://anirudhs.chaosnet.org/)
 * Copryright (C) 2009 Anirudh Sasikumar
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/	
 
 
 
package components.views.ArrangeViewProperties
{
	import com.anirudh.as3syntaxhighlight.CodePrettyPrint;
	import com.anirudh.as3syntaxhighlight.PseudoThread;
	
	import components.model.userData.ColorScheme;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.text.StyleSheet;
	import flash.ui.Keyboard;
	import flash.utils.Timer;
	
	import flexunit.framework.Assert;
	
	import mx.controls.TextArea;
	import mx.controls.textClasses.TextRange;

	public class ScriptingViewTextArea extends TextArea
	{
		public function ScriptingViewTextArea()
		{
			super();

			addEventListener( Event.CHANGE, onTextChange );
			addEventListener( KeyboardEvent.KEY_DOWN, onKeyDown );
			
			setStyle( "fontFamily", "Courier" );
			
			_tabString = String.fromCharCode( Keyboard.TAB );
			
			_lightCodeStyle = new StyleSheet();
			_lightCodeStyle.parseCSS( _lightCSSString );

			_darkCodeStyle = new StyleSheet();
			_darkCodeStyle.parseCSS( makeInvertedCSSString( _lightCSSString ) );

			_codePrettyPrint = new CodePrettyPrint();
			
			restrict="A-Z a-z 0-9 !\"£$%^&*()-=_+[]{};'#:@~,./<>?\\|";
		}
		
		
		public function updateCodeHighlight():void
		{
			startCodeTimer();
		}
		

		override public function styleChanged( style:String ):void
		{
			if( !style || style == ColorScheme.STYLENAME )
			{
				switch( getStyle( ColorScheme.STYLENAME ) )
				{
					default:
					case ColorScheme.LIGHT:
						_activeCodeStyle = _lightCodeStyle;
						break;
						
					case ColorScheme.DARK:
						_activeCodeStyle = _darkCodeStyle;
						break;
				}

				startCodeTimer();
			}
		}
		
		
		private function onKeyDown( event:KeyboardEvent ):void
		{
			//handle tabs
			if( event.charCode == Keyboard.TAB )
			{
				callLater( reclaimFocus );
				
				var caretIndex:int = textField.caretIndex;
				if( caretIndex >= 0 )
				{
					var caretPos:TextRange = new TextRange( this, false, caretIndex, caretIndex );
					caretPos.text = String.fromCharCode( Keyboard.TAB );
					caretIndex += _tabString.length;
					textField.setSelection( caretIndex, caretIndex );
				}
			}
		}
		
		
		private function reclaimFocus():void
		{
			focusManager.setFocus( this );
		}
		
		
		private function onTextChange( event:Event ):void
		{
			startCodeTimer();
		}
	

		private function startCodeTimer():void
		{
		    if ( !_codeTimer )
		    {
		        _codeTimer = new Timer( 200,1 );
		        _codeTimer.addEventListener( TimerEvent.TIMER, onCodeTimer );
		    }	
		    
		    if ( _codeTimer.running )
		    {
		        _codeTimer.stop();
		    }
		    _codeTimer.reset();
		    // wait for some time to see if we need to highlight or not
		    _codeTimer.start();
		}		
		
		
		private function onCodeTimer( event:TimerEvent ):void
		{
			doPrettyPrint();
		}
		
		
		private function doPrettyPrint():void
		{
			/*
			 pretty printing is temporarily disabled, because the as3syntaxhighlight library doesn't 
			support lua-style comments (issue #659).    
		   */
			return;		
			
		    if ( _codePrettyPrint.asyncRunning )
		    {
		        _codePrettyPrint.prettyPrintStopAsyc = true;
		        callLater( doPrettyPrint );
		        return;
		    }
		    
		    if ( pfasyncrunning )
		    {
		        pfasyncstop = true;
		        callLater( doPrettyPrint );
		        return;
		    }	
		    
		    codeHighlightInPlace();
		}
		
		
		private function pfinit(startIdx:int, endIdx:int):void
		{
		    codeStylePF = _activeCodeStyle;
		    srclenPF = endIdx - startIdx;
		    arrPF = _codePrettyPrint.mainDecorations;
		    lenPF = arrPF.length;
		    desclenPF = text.length;
		    firstNodePF = false;
		    firstIndexPF = 0;
		    pfasyncrunning = false;
		    pfasyncstop = false;	
		}		


		private function processFormattedCodeAsync( startIdx:int, endIdx:int, completeFn:Function, optIdx:int=0 ):Boolean
		{			
		    if ( pfasyncstop )
		    {
		        pfasyncrunning = false;
		        pfasyncstop = false;
		        return false;
		    }
		    pfasyncrunning = true;
		    if ( arrPF == null || srclenPF < 1 ) 
		    {
		    	pfasyncrunning = false;
		        return false;
		    }
		    var tr:TextRange;
		    var thecolor:Object;
		    var i:int = optIdx;
		    if ( i > 0 && i % 5 == 0 )
		    {
		    	//asyncCodeState = "Coloring (" + int((i / lenPF) * 100) + "%)...";
		    }
		    if ( i < lenPF )
		    {
		        /* find first node */
		        if ( arrPF[i] == 0 && firstNodePF == false )
		        {        
		        	firstNodePF = true;					
		            return true;
		        }
		        else if ( arrPF[i] == 0 && firstNodePF == true )
		        {
		            firstNodePF = false;
		            firstIndexPF = i;
		            
		        } 
		        if ( i - 2 > 0 )
		        {
		            if ( arrPF[i-2]  != arrPF[i] && arrPF[i] < text.length )
		            {
		            	tr = new TextRange(this, false, arrPF[i-2] + startIdx, arrPF[i] + startIdx);
		            	thecolor = codeStylePF.getStyle("." + arrPF[i-1]).color;
		            	tr.color = thecolor;
		            }
		            
		        }
		        return true;
		        
		        
		    }
		    if ( i > 0 )
		    {
		        i -= 2;
		        if ( arrPF[i] + startIdx < endIdx )
		        {
		            tr = new TextRange(this, false, arrPF[i] + startIdx, endIdx);
		            thecolor = codeStylePF.getStyle("." + arrPF[i+1]).color;            
		            var totlen:int = text.length;
		            if ( totlen >= endIdx )
		            	tr.color = thecolor;
		            
		        }
		    }
		    if ( completeFn != null )
		    	completeFn();
		    pfasyncrunning = false;
		    return false;
		}
		
		private function codePFComplete():void
		{
			//asyncCodeState = "";
		}
		
		private function codeInPlaceComplete():void
		{	
		    //asyncCodeState = "Coloring...";
		    if ( pfasyncrunning )
		    {
		        pfasyncstop = true;
		        callLater(codeInPlaceComplete);
		        return;
		    }
		    asyncRunning = false;
		    
		    pfinit(0, text.length );
		    colorThread = new PseudoThread(this.systemManager, processFormattedCodeAsync, this, [0, text.length, codePFComplete, 0], 3, 2);
		}
		
		private function lexInt(idx:int, total:int):void
		{
			if ( idx > 0 && idx % 5 == 0 )
			{
				//asyncCodeState = "Lexing (" + int((idx / total) * 100) + "%)...";
			}
		}
		
		private function codeHighlightInPlace():void
		{
		    asyncRunning = true;
		    //asyncCodeState = "Lexing...";
		    _codePrettyPrint.prettyPrintAsync(text, null, codeInPlaceComplete, lexInt, this.systemManager);
		    
		}
				
		
		private function makeInvertedCSSString( cssString:String ):String
		{
			var invertedString:String = cssString;
			
			var indexOfPreviousHash:int = cssString.indexOf( "#" );
			while( indexOfPreviousHash >= 0 )
			{
				var red:uint = uint( "0x" + cssString.substr( indexOfPreviousHash + 1, 2 ) );
				var green:uint = uint( "0x" + cssString.substr( indexOfPreviousHash + 3, 2 ) );
				var blue:uint = uint( "0x" + cssString.substr( indexOfPreviousHash + 5, 2 ) );
				
				var invertedRed:uint = Math.max( 0, Math.min( 255, 255 - ( green + blue ) / 2 ) );
				var invertedGreen:uint = Math.max( 0, Math.min( 255 - ( red + blue ) / 2 ) );
				var invertedBlue:uint = Math.max( 0, Math.min( 255 - ( red + green ) / 2 ) );
				
				var invertedRedString:String = invertedRed.toString( 16 );
				var invertedGreenString:String = invertedGreen.toString( 16 );
				var invertedBlueString:String = invertedBlue.toString( 16 );
				
				var invertedColor:String = invertedRedString + invertedGreenString + invertedBlueString;
				Assert.assertTrue( invertedColor.length == 6 );
				
				invertedString = invertedString.substr( 0, indexOfPreviousHash + 1 ) + invertedColor + invertedString.substr( indexOfPreviousHash + 7 ) 
								
				indexOfPreviousHash = cssString.indexOf( "#", indexOfPreviousHash + 1 );
			}
			
			return invertedString;
		}

		
		private var _codeTimer:Timer = null;

		private var _lightCodeStyle:StyleSheet = null;
		private var _darkCodeStyle:StyleSheet = null;
		private var _activeCodeStyle:StyleSheet = null;
		
		private var _codePrettyPrint:CodePrettyPrint = null;
		
		private var asyncStop:Boolean;
		private var asyncRunning:Boolean;
		private var codeStylePF:StyleSheet;
		private var srclenPF:int;
		private var arrPF:Array;
		private var lenPF:int;
		private var firstNodePF:Boolean;
		private var firstIndexPF:int;
		private var pfasyncrunning:Boolean;
		private var pfasyncstop:Boolean;
		private var desclenPF:int;
		private var colorThread:PseudoThread;

		private var _tabString:String;

		private const _lightCSSString:String =".spl { color: #4f94cd;} .str { color: #880000; } .kwd { color: #000088; } .com { color: #008800; } .typ { color: #0068CF; } .lit { color: #006666; } .pun { color: #666600; } .pln { color: #222222; } .tag { color: #000088; } .atn { color: #660066; } .atv { color: #880000; } .dec { color: #660066; } ";
	}
}