#include "platform_specifics.h"

#include <assert.h>
#include <string.h>

#include "hashtable.h"
#include "memory.h"
#include "path.h"
#include "trace.h"



#define NTG_HASH_SEED 53
#define NTG_HASHTABLE_SIZE  98321


typedef struct ntg_hash_node_
{
	void *key;
	int key_length;
    const void *value;

	struct ntg_hash_node_ *next;
} ntg_hash_node;



unsigned int MurmurHash2(const void * key, int len, unsigned int seed);


unsigned int ntg_hashtable_do_hash( const unsigned char *key, unsigned int key_length )
{
    unsigned int hash;

    assert( key );

    hash = MurmurHash2( key, key_length, NTG_HASH_SEED );
    hash %= NTG_HASHTABLE_SIZE;

    return hash;

}

NTG_HASHTABLE *ntg_hashtable_new()
{
    NTG_HASHTABLE *hashtable;

    hashtable = new ntg_hash_node *[ NTG_HASHTABLE_SIZE ];
	memset( hashtable, 0, NTG_HASHTABLE_SIZE * sizeof(ntg_hash_node *) );

    return hashtable;
}


void ntg_hashtable_free(NTG_HASHTABLE *hashtable)
{
	int i;
	ntg_hash_node *next;

	for( i = 0; i < NTG_HASHTABLE_SIZE; i++ )
	{
		while( hashtable[ i ] )
		{
			next = hashtable[ i ]->next;

			delete[] hashtable[ i ]->key;
			delete hashtable[ i ];

			hashtable[ i ] = next;
		}
	}

	delete[] hashtable;
}


const void *ntg_hashtable_lookup( NTG_HASHTABLE *hashtable, const unsigned char *key, int key_length )
{
    unsigned int hash;
	ntg_hash_node *iterator;

    hash = ntg_hashtable_do_hash( key, key_length );

	for( iterator = hashtable[ hash ]; iterator; iterator = iterator->next )
	{
		if( key_length == iterator->key_length && memcmp( key, iterator->key, key_length ) == 0 )
		{
			return iterator->value;
		}
	}

	return NULL;
}


void ntg_hashtable_add_key( NTG_HASHTABLE *hashtable, const unsigned char *key, int key_length, const void *value )
{
    unsigned int hash;
	ntg_hash_node *node;

	assert( !ntg_hashtable_lookup( hashtable, key, key_length ) );

    hash = ntg_hashtable_do_hash( key, key_length );
	
	node = new ntg_hash_node;
	node->key = new unsigned char[ key_length ];
	memcpy( node->key, key, key_length );
	node->key_length = key_length;
	node->value = value;

	node->next = hashtable[ hash ];
	hashtable[ hash ] = node;
}


void ntg_hashtable_remove_key( NTG_HASHTABLE *hashtable, const unsigned char *key, int key_length )
{
    unsigned int hash;
	ntg_hash_node **owner;
	ntg_hash_node *iterator;

    hash = ntg_hashtable_do_hash( key, key_length );

	owner = &( hashtable[ hash ] );
	iterator = *owner;

	while( iterator )
	{
		if( iterator->key_length == key_length && memcmp( iterator->key, key, key_length ) == 0 )
		{
			*owner = iterator->next;

			delete[] iterator->key;
			delete iterator;
			return;
		}

		owner = &iterator->next;
		iterator = iterator->next;
	}

	NTG_TRACE_ERROR( "couldn't remove key" );
}


void ntg_hashtable_add_string_key( NTG_HASHTABLE *hashtable, const char *key, const void *value )
{
	if( ntg_hashtable_lookup_string( hashtable, key ) )
	{
		NTG_TRACE_ERROR_WITH_STRING( "attempt to add key which already exists", key );
		return;
	}

	ntg_hashtable_add_key( hashtable, ( const unsigned char * ) key, strlen( key ), value );
}


void ntg_hashtable_add_guid_key( NTG_HASHTABLE *hashtable, const GUID *key, const void *value )
{
	if( ntg_hashtable_lookup_guid( hashtable, key ) )
	{
		NTG_TRACE_ERROR( "attempt to add guid which already exists" );
		return;
	}

	ntg_hashtable_add_key( hashtable, ( const unsigned char * ) key, sizeof( GUID ), value );
}


void ntg_hashtable_remove_string_key( NTG_HASHTABLE *hashtable, const char *key )
{
	ntg_hashtable_remove_key( hashtable, ( const unsigned char * ) key, strlen( key ) );
}


void ntg_hashtable_remove_guid_key( NTG_HASHTABLE *hashtable, const GUID *key )
{
	ntg_hashtable_remove_key( hashtable, ( const unsigned char * ) key, sizeof( GUID ) );
}



const void *ntg_hashtable_lookup_string( NTG_HASHTABLE *hashtable, const char *key )
{
	return ntg_hashtable_lookup( hashtable, ( const unsigned char * ) key, strlen( key ) );
}


const void *ntg_hashtable_lookup_guid( NTG_HASHTABLE *hashtable, const GUID *key )
{
	return ntg_hashtable_lookup( hashtable, ( const unsigned char * ) key, sizeof( GUID ) );
}
