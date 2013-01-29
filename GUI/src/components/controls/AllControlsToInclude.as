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


//this file lists all the control classes that should be built into the application.
//since these classes are instantiated dynamically, they need to be explicitly listed here to ensure their 
//inclusion by the compiler.

package components.controls
{
	CheckboxControl;
	DryWetBalanceControl;
	EarlyLateBalanceControl;
	ExampleBalanceControl;
	ExampleFileLoadDialogControl;
	FileLoadDialogControl;
	FileSaveDialogControl;
	KnobControl;
	LocateFolderDialogControl;
	NumberBoxControl;
	PanoramaBalanceControl;
	PlayButtonControl;
	RadioGroupControl;
	RangeSliderControl;
	RecButtonControl;
	SliderControl;
	SoundFileLoadDialogControl;
	StopButtonControl;
	TriggerControl;
	VuMeterControl;
	XYPanPadControl;
	XYScratchPadControl;
	
	
	public class AllControlsToInclude		//dummy empty class
	{
	}
}
