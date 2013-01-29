dnl Check for Lua 5.1 Libraries
dnl CHECK_LUA(ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND])
dnl Sets:
dnl  LUA_CFLAGS
dnl  LUA_LIBS
AC_DEFUN([CHECK_LUA],
[dnl

AC_ARG_WITH(
    lua,
    [AC_HELP_STRING([--with-lua=PATH],[Path to the Lua 5.1 prefix])],
    lua_path="$withval",
    :)

dnl # Determine lua lib directory
if test -z $lua_path; then
    test_paths="/usr/local /usr"
else
    test_paths="${lua_path}"
fi

for x in $test_paths ; do
    AC_MSG_CHECKING([for lua.h in ${x}/include/lua5.1])
    if test -f ${x}/include/lua5.1/lua.h; then
        AC_MSG_RESULT([yes])
        save_CFLAGS=$CFLAGS
        save_LDFLAGS=$LDFLAGS
        CFLAGS="$CFLAGS"
        LDFLAGS="-L$x/lib $LDFLAGS"
        AC_CHECK_LIB(lua5.1, luaL_newstate,
            [
            LUA_LIBS="-L$x/lib -llua5.1"
            LUA_CFLAGS="-I$x/include/lua5.1"
            ])
        CFLAGS=$save_CFLAGS
        LDFLAGS=$save_LDFLAGS
        break
    else
        AC_MSG_RESULT([no])
    fi
    AC_MSG_CHECKING([for lua.h in ${x}/include])
    if test -f ${x}/include/lua.h; then
        AC_MSG_RESULT([yes])
        save_CFLAGS=$CFLAGS
        save_LDFLAGS=$LDFLAGS
        CFLAGS="$CFLAGS"
        LDFLAGS="-L$x/lib $LDFLAGS"
        AC_CHECK_LIB(lua, luaL_newstate,
            [
            LUA_LIBS="-L$x/lib -llua"
            LUA_CFLAGS="-I$x/include"
            ])
        CFLAGS=$save_CFLAGS
        LDFLAGS=$save_LDFLAGS
        break
    else
        AC_MSG_RESULT([no])
    fi
done

AC_SUBST(LUA_LIBS)
AC_SUBST(LUA_CFLAGS)

if test -z "${LUA_LIBS}"; then
  AC_MSG_NOTICE([*** Lua 5.1 library not found.])
  ifelse([$2], , AC_MSG_ERROR([Lua 5.1 library is required]), $2)
else
  AC_MSG_NOTICE([using '${LUA_LIBS}' for Lua Library])
  ifelse([$1], , , $1) 
fi 
])
