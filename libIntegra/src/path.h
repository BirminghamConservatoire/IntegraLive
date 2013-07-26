/* libIntegra multimedia module interface
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


#ifndef INTEGRA_PATH_H
#define INTEGRA_PATH_H

#include "api/common_typedefs.h"


namespace ntg_api
{
	class LIBINTEGRA_API CPath
	{
		public:

			CPath();
			CPath( const string &path_string );
			CPath( const CPath &to_copy );
			~CPath();

			const CPath &operator=( const CPath &to_copy );

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
