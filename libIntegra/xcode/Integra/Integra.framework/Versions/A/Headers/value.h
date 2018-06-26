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

/** \file value.h
 *  \brief Base class and type-specific subclasses to represent values
 */


#ifndef INTEGRA_VALUE_PRIVATE_H
#define INTEGRA_VALUE_PRIVATE_H

#include <unordered_map>

#include "common_typedefs.h"


namespace integra_api
{
	/** \class CValue value.h "api/value.h"
	 *  \brief Base class for the concrete value classes CIntegerValue, CFloatValue and CStringValue
	 *
	 * Value classes are used to represent values of stateful node endpoints.
	 * The common base class CValue allows their generic (type-agnostic) manipulation and storage wherever possible
	 */	
	class INTEGRA_API CValue
	{
		protected:
			CValue();

		public:

			virtual ~CValue();

			/** enumeration of value types */
			enum type
			{
				/** Integers are signed 32 bit values */
				INTEGER,

				/** Floats are single-precision */
				FLOAT,

				/** Strings are ANSI */
				STRING
			};

			/** \brief Get this value's type (see #type) */
			virtual type get_type() const = 0;

			/** \brief Cast to an integer
			 *
			 * These cast operations are provided in CValue to minimise clutter in the calling code by removing the need 
			 * for dynamic downcasting to query the value of subclasses.  However, it is the caller's responsibilty to 
			 * ensure that only the right downcast operator is used.  For example, the caller ,ust only ever cast a CFloatValue
			 * to float, and so on.  Type-incorrect casting will cause libIntegra to trace an error and throw an assertion failure.
			 */
			virtual operator int() const;

			/** \brief Cast to a float
			 *
			 * See #operator int() for further discussion of CValue's casting operators
			 */
			virtual operator float() const;

			/** \brief Cast to a string
			 *
			 * See #operator int() for further discussion of CValue's casting operators
			 */
			virtual operator const string &() const;

			/** \brief Creates copy of value
			 * 
			 * Creates a CValue of same type and value, allocated on the heap with new
			 */
			virtual CValue *clone() const = 0;

			/** \brief Converts value into another type
			 * 
			 * Copies value into conversion_target, retaining as much information as possible when types differ
			 */
			virtual void convert( CValue &conversion_target ) const = 0;

			/** \brief Compares values
			 * 
			 * \param other Value to compare
			 * \return true if values are of same type and equal value, otherwise false
			 */
			virtual bool is_equal( const CValue &other ) const = 0;

			/** \brief Obtain an arbitrary measure of magnitude of different between values
			 * 
			 * Expects types to be the same.  
			 * For numeric types, distance is actually abs( difference )
			 * For strings, distance is taken as the levenshtein_distance (http://en.wikipedia.org/wiki/Levenshtein_distance
			 *
			 * \param other Value to compare
			 * \return a distance value if values are of same type, or -1 if types differ
			 */
			virtual float get_distance( const CValue &other ) const = 0;

			/** \brief Convert value to string
			 */
			virtual string get_as_string() const = 0;

			/** \brief Set value from string.  
			 * \note when setting a numerical value, if conversion is not possible, the value is set to 0
			 */
			virtual void set_from_string( const string &source ) = 0;

			/** \brief Copy into new value of different type
			 * 
			 * Creates new value of specified type, and store type-converted current value in new value, 
			 * retaining as much information as possible when types differ.
			 * The new value is allocated on the heap
			 */
			CValue *transmogrify( type new_type ) const;

			/** \brief Create new CValue of specified type
			 * 
			 * New value is created with default state (zero or empty string)
			 * The new value is allocated on the heap
			 */
			static CValue *factory( type new_type ); 

			/** \brief Get string representation of value type
			 */
			static const char *get_type_name( type value_type ); 

			/** \brief convert value type to ixd code
			 *
			 * ixd codes are numerical representations of value types used in ixd files.  
			 * Used for saving .integra files.
			 */
			static int type_to_ixd_code( type value_type );

			/** \brief convert ixd code to value type
			 *
			 * ixd codes are numerical representations of value types used in ixd files.  
			 * Used for loading .integra files.
			 */
			static type ixd_code_to_type( int ixd_code );

		private:

			void handle_incorrect_cast( type cast_target ) const;
	};


	/** \class CIntegerValue value.h "api/value.h"
	 *  \brief Represents an integer value
	 */	
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
			float get_distance( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			int m_value;
	};


	/** \class CFloatValue value.h "api/value.h"
	 *  \brief Represents a float value
	 */		
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
			float get_distance( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			float m_value;
	};


	/** \class CStringValue value.h "api/value.h"
	 *  \brief Represents a string value
	 */		
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
			float get_distance( const CValue &other ) const;

			string get_as_string() const;
			void set_from_string( const string &source );

		private:

			/* calculate levenshtein distance between two strings.  */
			static int levenshtein_distance( const char *string1, const char *string2 );

			string m_value;
	};

	
	/** Map string to value */
	typedef std::unordered_map<string, CValue *> value_map;

	/** Set of values */
	typedef std::unordered_set<CValue *> value_set;
}


#endif
