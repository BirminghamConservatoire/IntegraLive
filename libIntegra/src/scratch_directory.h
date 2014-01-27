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


#ifndef INTEGRA_SCRATCH_DIRECTORY_H
#define INTEGRA_SCRATCH_DIRECTORY_H

#include "api/common_typedefs.h"


using namespace integra_api;



namespace integra_internal
{
	class CScratchDirectory
	{
		public:

			CScratchDirectory();
			~CScratchDirectory();

			const string &get_scratch_directory() { return m_scratch_directory; }

		private:

			string m_scratch_directory;

			static const string scratch_directory_root_name;
	};
}




#endif /* INTEGRA_SCRATCH_DIRECTORY_H */
