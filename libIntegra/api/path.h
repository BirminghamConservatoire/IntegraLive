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
 *  \brief Defines class CPath
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

			/** \brief Construct an empty path */
			CPath();

			/** \brief Construct a path from a dot-separated string eg "OuterContainer.InnerContainer.ModuleName" */
			CPath( const string &path_string );

			/** \brief Copy contructor */
			CPath( const CPath &to_copy );
			~CPath();

			/** \brief Assignment operator */
			const CPath &operator=( const CPath &to_copy );
			
			/** \brief Equality operator*/
			bool operator==( const CPath &to_compare ) const;

			/** \return Number of elements in the path*/
			int get_number_of_elements() const;			

			/** \brief array access operator.  
			 * This operator allows you to access path elements in array syntax eg path[ 0 ]
			 * \note will return an empty string for out-of-range index
			 */
			const string &operator[]( int index ) const;

			/** \return A dot-separated representation of the path as a single string eg "OuterContainer.InnerContainer.ModuleName" */
			const string &get_string() const;

			/** \brief Casting operator, synonym for get_string() */
			operator const string &() const;

			/** \brief Pop last element from path
			 * Reduces number of elements in path by 1
			 * \return the last element, or an empty string if the path was already empty
			 */
			string pop_element();

			/** \brief append element to path
			 * \param element The element to append
			 */
			void append_element( const string &element );

		private:

			void copy_from( const CPath &to_copy );

			void rebuild_string();

			string_vector m_elements;
			
			string m_string;
			bool m_string_is_valid;
	};


	/** List of paths */
	typedef std::list<CPath> path_list;
}



#endif
