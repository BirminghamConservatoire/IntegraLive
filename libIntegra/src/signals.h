/** libIntegra multimedia module interface
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

#ifndef _WINDOWS

/*\brief block a set of signals 
 * \param *sigset pointer to an empty sigset_t */
void ntg_sig_block(sigset_t *sigset);

/*\brief unblock a set of signals 
 * \param *sigset pointer to a sigset_t previously used by ntg_sig_block() */
void ntg_sig_unblock(sigset_t *sigset);

/* \brief handle various signals */
void ntg_sig_handler(int signum);
/* \brief assign signal handlers for various signals */
void ntg_sig_setup(void);

void *ntg_sighandler_thread(void *);

#endif /*_WINDOWS*/
