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

#ifndef COMMAND_API_H
#define COMMAND_API_H

#include "common_typedefs.h"
#include "error.h"


namespace ntg_internal
{
	class CServer;
}


namespace ntg_api
{
	class CPath;
	class CValue;
	class CCommandResult;
	class CCommandSource;
	
	class LIBINTEGRA_API CCommandApi
	{
		protected:

			CCommandApi() {}

		public:

			virtual ~CCommandApi() {};

			virtual CError execute( ntg_internal::CServer &server, CCommandSource source, CCommandResult *result ) = 0;
	};


	class LIBINTEGRA_API CNewCommandApi : public CCommandApi
	{
		public:
			static CNewCommandApi *create( const GUID &module_id, const string &node_name, const CPath &parent_path );
	};


	class LIBINTEGRA_API CDeleteCommandApi : public CCommandApi
	{
		public:
			static CDeleteCommandApi *create( const CPath &path );
	};


	class LIBINTEGRA_API CSetCommandApi : public CCommandApi
	{
		public:
			static CSetCommandApi *create( const CPath &endpoint_path, const CValue *value );
	};


	class LIBINTEGRA_API CRenameCommandApi : public CCommandApi
	{
		public:
			static CRenameCommandApi *create( const CPath &path, const string &new_name );
	};


	class LIBINTEGRA_API CMoveCommandApi : public CCommandApi
	{
		public:
			static CMoveCommandApi *create( const CPath &node_path, const CPath &new_parent_path );
	};


	class LIBINTEGRA_API CLoadCommandApi : public CCommandApi
	{
		public:
			static CLoadCommandApi *create( const string &file_path, const CPath &parent_path );
	};


	class LIBINTEGRA_API CSaveCommandApi : public CCommandApi
	{
		public:
			static CSaveCommandApi *create( const string &file_path, const CPath &node_path );
	};
}


#endif 