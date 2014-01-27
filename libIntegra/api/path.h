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

/** \file path.h
 *  \brief defines class CPath
 */


#ifndef INTEGRA_PATH_H
#define INTEGRA_PATH_H

#include "common_typedefs.h"

#include <list>

namespace integra_api
{
	/** \class CPath path.h "api/path.h"
	 *  \brief Represents the address of a node endpoint, absolutely or relatively
	 * 
	 * libIntegra uses paths to identify node enpoints.  
	 * For example, a node called 'AudioIn' within a node called 'Project' might have an endpoint called 'inLevel'.
	 * In this case, the endpoint could be addressed (from the top level) as 'Project.AudioIn.inLevel'.
	 * Or, the same endpoint could be addressed (from the 'Project' node) as 'AudioIn.inLevel'.
	 * Or, the same endpoint could be addressed (from the 'AudioIn' node) as 'inLevel'.
	 *
	 * \note: paths can only traverse down the node hierarchy.  They cannot use '..' or similar to access parent nodes.
	 * this ensures that all the functionality in each branch of the node tree is self-contained.
	 */

	class INTEGRA_API CPath
	{
		public:

			CPath();
			CPath( const string &path_string );
			CPath( const CPath &to_copy );
			~CPath();

			const CPath &operator=( const CPath &to_copy );
			bool operator==( const CPath &to_compare ) const;

			int get_number_of_elements() const;			
			const string &operator[]( int index ) const;

			const string &get_string() const;
			operator const string &() const;

			string pop_element();
			void append_element( const string &element );

		private:

			void copy_from( const CPath &to_copy );

			void rebuild_string();

			string_vector m_elements;
			
			string m_string;
			bool m_string_is_valid;
	};


	typedef std::list<CPath> path_list;
}



#endif
