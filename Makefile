# NOTE: you might want -I/usr/local/include/lua5.1 -L/usr/local/lib instead.

all:
	gcc -o mcserver main.c -I/usr/include/lua5.1 -lz -llua5.1 

zip:
	zip luacraft-`date +%Y%m%d`.zip -r config.lua main.c libv01 libv02 notes old01 README Makefile test.mcta NotchToMCTA.java NotchToMCTA.class

