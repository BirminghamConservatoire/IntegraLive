/** libIntegra multimedia module interface
 *
 * Copyright (C) 2012 Birmingham City University
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
 * USA.
 */


#include "platform_specifics.h"

#include "midi_engine.h"
#include "portmidi_engine.h"


namespace integra_internal
{
	IMidiEngine *IMidiEngine::create_midi_engine()
	{
		/*
		 at such a time as we implement other midi engines (eg for iOS), we'd use 
		 preprocessor switches to instantiate the required engine implementation here
		*/

		#if 1
			IMidiEngine *engine = new CPortMidiEngine;
		#else
			IMidiEngine *engine = new CSomeOtherAudioEngine;
		#endif

		return engine;
	}
}

