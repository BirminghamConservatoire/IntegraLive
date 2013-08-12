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

#ifndef INTEGRA_VALUE_PRIVATE_H
#define INTEGRA_VALUE_PRIVATE_H

#include <unordered_map>

#include "api/common_typedefs.h"


namespace integra_api
{
	class INTEGRA_API CValue
	{
		public:

			CValue();
			virtual ~CValue();

			typedef enum type 
			{
				INTEGER,
				FLOAT,
				STRING,
			};

			virtual type get_type() const = 0;

			virtual operator int() const;
			virtual operator float() const;
			virtual operator const string &() const;

			virtual CValue *clone() const = 0;
			virtual void convert( CValue &conversion_target ) const = 0;

			virtual bool is_equal( const CValue &other ) const = 0;
			virtual float get_difference( const CValue &other ) const = 0;

			virtual string get_as_string() const = 0;
			virtual void set_from_string( const string &source ) = 0;

			CValue *transmogrify( type new_type ) const;

			static CValue *factory( type new_type ); 
			static const char *get_type_name( type value_type ); 

			static int type_to_ixd_code( type value_type );
			static type ixd_code_to_type( int ixd_code );

		private:

			void handle_incorrect_cast( type cast_target ) const;
	};


	class INTEGRA_API CIntegerValue : public CValue
	{
		public:

			CIntegerValue();
			CIntegerValue( int value );
			~CIntegerValue();

			type get_type() const;

			operator int() const;
			const CIntegerValue &operator= ( const CIntegerValue &to_copy );

			CValue *clone() const;
			void convert( CValue &conversion_target ) const;

			bool is_equal( const CValue &other )  const;
			float get_difference( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			int m_value;
	};


	class INTEGRA_API CFloatValue : public CValue
	{
		public:

			CFloatValue();
			CFloatValue( float value );
			~CFloatValue();

			type get_type() const;

			operator float() const;
			const CFloatValue &operator= ( const CFloatValue &to_copy );

			CValue *clone() const;
			void convert( CValue &conversion_target ) const;

			bool is_equal( const CValue &other )  const;
			float get_difference( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			float m_value;
	};


	class INTEGRA_API CStringValue : public CValue
	{
		public:

			CStringValue();
			CStringValue( const string &value );
			~CStringValue();

			type get_type() const;

			operator const string &() const;
			const CStringValue &operator= ( const CStringValue &to_copy );

			CValue *clone() const;
			void convert( CValue &conversion_target ) const;

			bool is_equal( const CValue &other )  const;
			float get_difference( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			/* calculate levenshtein distance between two strings.  */
			static int levenshtein_distance( const char *string1, const char *string2 );

			string m_value;
	};


	typedef std::unordered_map<string, CValue *> value_map;
	typedef std::unordered_set<CValue *> value_set;
}


#endif
