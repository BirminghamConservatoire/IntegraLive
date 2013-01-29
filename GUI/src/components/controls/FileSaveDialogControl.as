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

package components.controls
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.filesystem.File;
	import components.controlSDK.core.*;
	import components.controls.FileLoadDialogControl;

	public class FileSaveDialogControl extends FileLoadDialogControl
	{
		public function FileSaveDialogControl( controlManager:ControlManager )
		{
			super( controlManager );

			fileLoadDialogName = "Save file...";
			buttonLabelText = "SAVE FILE";

		}        
		
		override public function onMouseDown( event:MouseEvent ):void
		{
			var fileReference:File = new File();
			fileReference.addEventListener( Event.SELECT, onFileSelected );
			fileReference.browseForSave( fileLoadDialogName );
		}
	}
}

