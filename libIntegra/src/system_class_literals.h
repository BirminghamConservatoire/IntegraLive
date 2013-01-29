/* libIntegra multimedia module interface
 *  
 * Copyright (C) 2012 Birmingham City University
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

/*
This header defines names of system classes, their attributes, and enumeration strings used by system classes

These definitions should be the only place in libIntegra where names of system classes and their attributes are defined.

This header should only be included by .c files which implement functionality of system classes

This will ensure that all class-specific implementation is encapsulated within these source files
*/


#ifndef INTEGRA_SYSTEM_CLASS_LITERALS
#define INTEGRA_SYSTEM_CLASS_LITERALS

#ifdef __cplusplus
extern "C" {
#endif


#define NTG_CLASS_CONTAINER "Container"
#define NTG_CLASS_SCRIPT "Script"
#define NTG_CLASS_SCALER "Scaler"
#define NTG_CLASS_CONTROL_POINT "ControlPoint"
#define NTG_CLASS_ENVELOPE "Envelope"
#define NTG_CLASS_PLAYER "Player"
#define NTG_CLASS_SCENE "Scene"
#define NTG_CLASS_CONNECTION  "Connection"

#define NTG_ATTRIBUTE_ACTIVE "active"
#define NTG_ATTRIBUTE_TRIGGER "trigger"
#define NTG_ATTRIBUTE_TEXT "text"
#define NTG_ATTRIBUTE_IN_VALUE "inValue"
#define NTG_ATTRIBUTE_OUT_VALUE "outValue"
#define NTG_ATTRIBUTE_IN_RANGE_MIN "inRangeMin"
#define NTG_ATTRIBUTE_IN_RANGE_MAX "inRangeMax"
#define NTG_ATTRIBUTE_OUT_RANGE_MIN "outRangeMin"
#define NTG_ATTRIBUTE_OUT_RANGE_MAX "outRangeMax"
#define NTG_ATTRIBUTE_TICK "tick"
#define NTG_ATTRIBUTE_RATE "rate"
#define NTG_ATTRIBUTE_LOOP "loop"
#define NTG_ATTRIBUTE_START "start"
#define NTG_ATTRIBUTE_END "end"
#define NTG_ATTRIBUTE_VALUE "value"
#define NTG_ATTRIBUTE_CURVATURE "curvature"
#define NTG_ATTRIBUTE_START_TICK "startTick"
#define NTG_ATTRIBUTE_CURRENT_TICK "currentTick"
#define NTG_ATTRIBUTE_CURRENT_VALUE "currentValue"
#define NTG_ATTRIBUTE_PLAY "play"
#define NTG_ATTRIBUTE_SCENE "scene"
#define NTG_ATTRIBUTE_NEXT "next"
#define NTG_ATTRIBUTE_PREV "prev"
#define NTG_ATTRIBUTE_LENGTH "length"
#define NTG_ATTRIBUTE_ACTIVATE "activate"
#define NTG_ATTRIBUTE_MODE "mode"
#define NTG_ATTRIBUTE_INFO "info"
#define NTG_ATTRIBUTE_SOURCE_PATH "sourcePath"
#define NTG_ATTRIBUTE_TARGET_PATH "targetPath"
#define NTG_ATTRIBUTE_USER_DATA "userData"
#define NTG_ATTRIBUTE_DATA_DIRECTORY "dataDirectory"

#define NTG_SCENE_MODE_HOLD "hold"
#define NTG_SCENE_MODE_PLAY "play"
#define NTG_SCENE_MODE_LOOP "loop"
	



#ifdef __cplusplus
}
#endif

#endif /*INTEGRA_SYSTEM_CLASS_LITERALS*/
