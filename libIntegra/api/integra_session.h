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

/** \file integra_session.h
 *  \brief defines class CIntegraSession
 */

#ifndef INTEGRA_SESSION_H
#define INTEGRA_SESSION_H

#include "common_typedefs.h"
#include "error.h"
#include "server_lock.h"


namespace integra_api
{
	class CServerStartupInfo;
	class IServer;

	/** \class CIntegraSession integra_session.h "api/integra_session.h"
	 *  \brief Top-level entry point for libIntegraApi.  
	 * 
	 *  Users of the libIntegra api must create an CIntegraSession instance in order to use
	 *	libIntegra.
	 *
	 *	\note There's nothing in libIntegra to prevent you from simultaneously creating more than one
	 *	CIntegraSession instance.  However, some of the audio SDKs supported by portaudio (such as ASIO)
	 *	cannot be used by more than one client at a time.  
	 */
	class INTEGRA_API CIntegraSession
	{
		public:
			CIntegraSession();
			~CIntegraSession();

			/** \brief start an integra session
			*
			* Creates all data structures and internal state, audio, midi and dsp engine etc for an integra session.  
			*
			* \param startup_info a structure containing some configuration info for the integra session
			* \return success if session started ok, an error code if the session is already started or configuration info is missing
			*/
			CError start_session( const CServerStartupInfo &startup_info );

			/** \brief end an integra session
			*
			* Stops processing audio, frees all system resources
			*
			* \return error is session not started
			*/
			CError end_session();

			/** \brief obtain a server lock in order to interact with the server
			*
			* Blocks the calling thread until no instances of CServerLock exist, then locks the server and returns 
			* an instance of CServer lock.  The server will remain locked until the CServerLock instance falls out of scope.
			* This method is thread-safe - it can be called from many different threads simultaneously.
			* However it mustn't be called by the same thread which has already locked the server, or else deadlock will occur.  
			* In particular, during callbacks via INotificationSink, the server is already locked, so implementations of INotificationSink::on_set_command must not attempt to lock the server again.
			* Additionally, it is the callers responsibility to ensure that this method is only used when a session is running, ie after a successful call to CIntegraSession::start_session and before a call to CIntegraSession::end_session
			*
			* \return a CServerLock instance with which to interact with the server
			*/
			CServerLock get_server();

		private:	

			IServer *m_server;
	};
}



#endif 