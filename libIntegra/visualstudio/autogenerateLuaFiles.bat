set olddirectory=%CD%
 
cd ..
cd src

python gen_lua_init.py lua_init.lua >lua_init.c
python gen_lua_init.py lua_functions.lua >lua_functions.c

cd %olddirectory%
