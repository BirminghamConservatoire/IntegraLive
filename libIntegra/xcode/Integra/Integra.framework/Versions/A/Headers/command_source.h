/* libIntegra modular audio framework
 *
 * Copyright (C) 2007 Birmingham City University
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

/** \file command_source.h
 *  \brief defines class CCommandSource
 */

#ifndef INTEGRA_COMMAND_SOURCE
#define INTEGRA_COMMAND_SOURCE

#include "common_typedefs.h"

namespace integra_api
{
	/** \class CCommandSource command_source.h "api/command_source.h"
	 *  \brief Represents an enumeration of command sources
	 * 
	 * Command Sources represent the different places from which a command can originate.
	 * They are passed to integraLive api users via INotificationSink and CPollingNotificationSink.
	 * The enumeration is implemented as a class to allow inline stringification where needed
	 */
	class INTEGRA_API CCommandSource
	{
		public:

			/** Command Source enumeration values */
			enum source 
			{
				NONE = -1,

				/**Used for initialization of stateful node endpoints */
				INITIALIZATION,				

				/**Used during execution of a ILoadCommand for creation of nodes and setting values for stateful node endpoints */
				LOAD,						

				/**Used for all business logic not explicitly covered by any other command source */
				SYSTEM,						

				/**Used by business logic for connections */
				CONNECTION,					

				/**Used by business logic for scripts */
				SCRIPT,						

				/**Used when control endpoints are accessed by dsp module implementations (eg vu meters, analysis modules etc) */
				MODULE_IMPLEMENTATION,		

				/**Used when libIntegra's state is altered through libIntegra's api */
				PUBLIC_API					
			}; 

			CCommandSource();

			/** \brief create a CCommandSource from an enumeration constant
			 */
			CCommandSource( source command_source );

			/** \brief casting operator, allows direct comparison of CCommandSource and enumeration constants
			 */
			operator source() const;

			/** \conversion to string
			 * \return a string representation of the command source 
			 */
			string get_text() const;

		private:

			source m_command_source;
	};
}



#endif /*INTEGRA_COMMAND_SOURCE*/