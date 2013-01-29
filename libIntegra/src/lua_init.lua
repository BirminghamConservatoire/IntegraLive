--/* libIntegra lua init script
-- *  
-- * Copyright (C) 2009 Kjetil Matheussen
-- *
-- * This program is free software; you can redistribute it and/or modify
-- * it under the terms of the GNU General Public License as published by
-- * the Free Software Foundation; either version 2 of the License, or
-- * (at your option) any later version.
-- *
-- * This program is distributed in the hope that it will be useful,
-- * but WITHOUT ANY WARRANTY; without even the implied warranty of
-- * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- * GNU General Public License for more details.
-- *
-- * You should have received a copy of the GNU General Public License
-- * along with this program; if not, write to the Free Software
-- * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, 
-- * USA.
-- */


-------------------------------------------------------------------------------------
-- First store old symbols in case any of them exists and needs to be accessed later.
--------------------------------------------------------------------------------------
global_set = set
global_get = get

------------------------------------------------------------------
-- Then pollute the global namespace with the integra functions
-- (some of these are (yet another time) redefined below though)
------------------------------------------------------------------

-- set_current_path = integra.set_current_path
-- set = integra.set
-- get = integra.get


-- Makes it possible to use integra node names as normal variables. (at least as long as
-- there isn't a lua variable with the same name but with a different value.)
-- Example:
--   new("Delay")
--   new("Flanger")
--   Delay1.in1=Flanger3.out1
setmetatable(_G,
{
    __index    = function(_,node_name)
        local ret = {};
        setmetatable(ret,
        {
            __newindex    = function(node,attribute_name,value)
                integra.set(node_name,attribute_name,value)
            end,
            __index    = function(node,attribute_name)
                return integra.get(node_name,attribute_name)
            end
        })
        return ret;
    end
})
