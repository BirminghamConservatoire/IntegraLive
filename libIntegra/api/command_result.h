/* libIntegra multimedia module info interface
 *
 * Copyright (C) 2007 Jamie Bullock, Henrik Frisk
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

#ifndef COMMAND_RESULT_API_H
#define COMMAND_RESULT_API_H

#include "guid_helper.h"

namespace ntg_internal
{
	//todo - use CNodeApi when it's been created!
	class CNode;
}


namespace ntg_api
{
	class LIBINTEGRA_API CCommandResult
	{
		protected:
			CCommandResult() {};

		public:
			virtual ~CCommandResult() {};
	};


	class LIBINTEGRA_API CNewCommandResult : public CCommandResult
	{
		public:
			CNewCommandResult() { m_created_node = NULL; }
			~CNewCommandResult() {};

			const ntg_internal::CNode *get_created_node() const { return m_created_node; }
			void set_created_node( const ntg_internal::CNode *created_node ) { m_created_node = created_node; }

		private:
			const ntg_internal::CNode *m_created_node;
	};



	class LIBINTEGRA_API CLoadCommandResult : public CCommandResult
	{
		public:
			CLoadCommandResult() {};
			~CLoadCommandResult() {};

			const guid_set &get_new_embedded_module_ids() const { return m_new_embedded_module_ids; }
			void set_new_embedded_module_ids( const guid_set &ids ) { m_new_embedded_module_ids = ids; }

		private:
			guid_set m_new_embedded_module_ids;

	};
}




#endif 