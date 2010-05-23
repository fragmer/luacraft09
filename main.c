/*
Luacraft - A minecraft v7 C + Lua server
Mostly coded by GreaseMonkey

Copyright (c) 2009, 2010, Team ASCII
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Team ASCII nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY TEAM ASCII ''AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL TEAM ASCII BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <errno.h>

#include <signal.h>

// Choose your colour.
#include <sys/time.h>
#include <sys/select.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <fcntl.h>

#include <zlib.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define MAX_CONN 256

#undef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#undef MAX
#define MAX(a,b) ((a) > (b) ? (a) : (b))

struct map
{
	uint16_t midx;
	char *mapdata;
	int maplx;
	int maply;
	int maplz;
	int mapzstep;
	
	struct map *p,*n;
};

struct map *maplist = NULL, *maplistend = NULL;
int midx_base = 1;

char *mapgz;

int sfd_base = -1;

struct player
{
	char *name;
	char *oname;
	char *loginid;
	int sockfd;
	int adminium;
	struct map *m;
	uint16_t midx;
	struct sockaddr_in sckad;
	uint8_t tmpdrop;
	uint8_t id;
	uint8_t pingupd;
	int16_t px,py,pz;
	int8_t pxo,pyo;
	int16_t x,y,z;
	int8_t xo,yo;
	int throttle;
	uint8_t ldbuf[0x1000];
	int ldbsize;
	int ldbstart,ldbend;
	struct wpacket {
		char *buf;
		int len;
		struct wpacket *n;
	} *wps,*wpe;
} player[MAX_CONN];

int player_l = 0;

fd_set readfds,writefds,exceptfds;
int rfdi[256]; int rfdi_l = 0; int rfdi_u = 0;
int wfdi[256]; int wfdi_l = 0; int wfdi_u = 0;
int xfdi[256]; int xfdi_l = 0; int xfdi_u = 0;
char *server_name = NULL;
char *server_msg = NULL;
struct timeval tvtb;

int ticker_ping = 0;

lua_State *Lg;

char *chat_hook = NULL;
char *puttile_hook = NULL;
char *dotick_hook = NULL;
char *join_hook = NULL;
char *part_hook = NULL;
char *connect_hook = NULL;
char *disconnect_hook = NULL;
/*
WoM tilenames:

$tiles{0} = "air";
$tiles{1} = "rock";
$tiles{2} = "grass";
$tiles{3} = "dirt";
$tiles{4} = "stone";
$tiles{5} = "wood";
$tiles{6} = "shrub";
$tiles{7} = "blackrock";
$tiles{8} = "water";
$tiles{9} = "waterstill";
$tiles{10} = "lava";
$tiles{11} = "lavastill";
$tiles{12} = "sand";
$tiles{13} = "gravel";
$tiles{14} = "gold";
$tiles{15} = "iron";
$tiles{16} = "coal";
$tiles{17} = "trunk";
$tiles{18} = "leaf";
$tiles{19} = "sponge";
$tiles{20} = "glass";
$tiles{21} = "red";
$tiles{22} = "orange";
$tiles{23} = "yellow";
$tiles{24} = "lightgreen";
$tiles{25} = "green";
$tiles{26} = "aquagreen";
$tiles{27} = "cyan";
$tiles{28} = "blue";
$tiles{29} = "purple";
$tiles{30} = "indigo";
$tiles{31} = "violet";
$tiles{32} = "magenta";
$tiles{33} = "pink";
$tiles{34} = "darkgrey";
$tiles{35} = "lightgrey";
$tiles{36} = "white";
$tiles{37} = "yellowflower";
$tiles{38} = "redflower";
$tiles{39} = "mushroom";
$tiles{40} = "redmushroom";
$tiles{41} = "solidgold";

(20:14:50) Adrian Siekierka: 42 to 49
(20:15:08) Adrian Siekierka: from 42
(20:15:10) Adrian Siekierka: IN ORDER
(20:15:24) Adrian Siekierka: Iron, Fullblock, Halfblock, Brick, TNT, Bookcase, Mossy Cobblestone, Obsidian
*/

/*
int iscleary[256] = {
	1,0,0,0,0,0,1,0,
	1,1,0,0,0,0,0,0,
	0,0,1,0,1,0,0,0,
	0,0,0,0,0,0,0,0,
	0,0,0,0,0,1,1,1,
	1,0,0,0,0,0,0,0,
	0,
};*/

int randbase = 12345;

int getrand(void)
{
	randbase = rand();
	srand(randbase);
	return randbase>>8;
	// Windows users: you should remove the >>8 part
	// Linux/BSD users: leave the >>8 in
	// You SHOULD check your OS's/libc's implementation of rand()
	// as some do an LCG without shifting the lower bits down
}

void bumptick(void)
{
	tvtb.tv_usec += 100000;
	while(tvtb.tv_usec > 1000000)
	{
		tvtb.tv_usec -= 1000000;
		tvtb.tv_sec++;
	}
}

void calcfdtop(int *fdi, int *fdi_l, int *fdi_u)
{
	int i;
	*fdi_u = 0;
	for(i = 0; i < *fdi_l; i++)
	{
		if(*fdi_u < fdi[i])
			*fdi_u = fdi[i];
	}
}

void addfd(fd_set *fds, int *fdi, int *fdi_l, int *fdi_u, int sockfd)
{
	printf("fd %i %i %i\n", *fdi_l, *fdi_u, sockfd);
	fdi[(*fdi_l)++] = sockfd;
	if(*fdi_u < sockfd)
		*fdi_u = sockfd;
	printf("fd %i %i %i\n", *fdi_l, *fdi_u, sockfd);
	
	FD_SET(sockfd, fds);
}

void rmfd(fd_set *fds, int *fdi, int *fdi_l, int *fdi_u, int sockfd)
{
	FD_CLR(sockfd, fds);
	
	if(sockfd > *fdi_u)
		return;
	
	int i;
	for(i = 0; i < *fdi_l; i++)
	{
		if(fdi[i] == sockfd)
		{
			fdi[i] = fdi[--*fdi_l];
	
			if(sockfd == *fdi_u)
				calcfdtop(fdi,fdi_l,fdi_u);
			
			return;
		}
	}
}

void ack_client(void)
{
	int sa_sz = sizeof(struct sockaddr_in);
	int accret = accept(sfd_base, (struct sockaddr *)&(player[player_l].sckad), &sa_sz);
	if(accret == -1)
	{
		if(errno == EAGAIN)
			return;
		printf("Failed to accept client: %i = %s\n", errno, strerror(errno));
	} else {
		printf("Accept client: %08X:%04X\n"
			,ntohl(player[player_l].sckad.sin_addr.s_addr)
			,ntohs(player[player_l].sckad.sin_port)
		);
		player[player_l].name = NULL;
		player[player_l].oname = NULL;
		player[player_l].m = NULL;
		player[player_l].midx = 0;
		player[player_l].x = 0;
		player[player_l].y = 0;
		player[player_l].z = 0;
		player[player_l].yo = 0;
		player[player_l].xo = 0;
		player[player_l].adminium = 0;
		player[player_l].loginid = NULL;
		player[player_l].sockfd = accret;
		player[player_l].ldbstart = 0;
		player[player_l].ldbend = 0;
		player[player_l].ldbsize = 0;
		player[player_l].id = 0;
		player[player_l].tmpdrop = 0x00;
		player[player_l].wps = NULL;
		player[player_l].wpe = NULL;
		player[player_l].throttle = 102400;
		int i;
		for(i = 0; i < player_l; i++)
		{
			if(player[i].id == player[player_l].id)
			{
				player[player_l].id++;
				i = -1;
				continue;
			}
		}
		player_l++;
		
		int fcr = fcntl(accret, F_GETFL, 0);
		if(fcr == -1)
			printf("Could not get fd flags: %i = %s\n", errno, strerror(errno));
		else if(fcntl(accret, F_SETFL, fcr | O_NONBLOCK))
			printf("Could not set fd flags: %i = %s\n", errno, strerror(errno));
		
		addfd(&readfds,&rfdi[0],&rfdi_l,&rfdi_u,accret);
		addfd(&writefds,&wfdi[0],&wfdi_l,&wfdi_u,accret);
	}
}

char *pkt_str(char *p)
{
	char *op = malloc(65);
	memcpy(op, p, 64);
	op[64] = '\0';
	char *v = &(op[63]);
	while(*v == ' ' && v >= op)
		*(v--) = '\0';
	
	return op;
}

int sendall_part(int fd, char *buf, int len)
{
	while(len > 0)
	{
		int ret = send(fd, buf, len, O_NONBLOCK);
		if(ret == -1)
		{
			if(errno == EAGAIN)
			{
				return len;
			}
			printf("error in sendall_part(): %i = %s\n", errno, strerror(errno));
			return -1;
		}
		len -= ret;
		buf += ret;
	}
	return 0;
}

void sendall(int idx, char *buf, int len)
{
	int ltrk;
	
	struct wpacket *w;
	
	if(player[idx].sockfd < 0)
		return;
	
	if(buf != NULL && len > 0)
	{
		w = malloc(sizeof(struct wpacket));
		// Hopefully this'll NEVER happen.
		// If it does... TURN YOUR SWAP ON NEXT TIME!
		// (I have suffered from out-of-memory issues before.)
		if(w == NULL)
		{
			printf("##*!* COULD NOT ALLOCATE w\n");
			return;
		}
		
		w->buf = malloc(len);
		if(w->buf == NULL)
		{
			printf("##*!* COULD NOT ALLOCATE w->buf\n");
			free(w);
			return;
		}
		
		memcpy(w->buf, buf, len);
		w->n = NULL;
		w->len = len;
		
		if(player[idx].wpe == NULL)
		{
			player[idx].wpe = player[idx].wps = w;
		} else {
			player[idx].wpe->n = w;
			player[idx].wpe = player[idx].wpe->n;
		}
	}
	
	if(player[idx].throttle <= 0)
		return;
	
	while(player[idx].wps != NULL)
	{
		w = player[idx].wps;
		
		ltrk = sendall_part(player[idx].sockfd, w->buf, w->len);
		if(ltrk == -1)
		{
			printf("Cutting client.\n");
			while(player[idx].wps != NULL)
			{
				w = player[idx].wps;
				player[idx].wps = player[idx].wps->n;
				free(w->buf);
				free(w);
			}
			
			player[idx].sockfd = -2;
			player[idx].wpe = NULL;
			return;
		}
		
		player[idx].throttle -= ltrk+30;
		
		if(ltrk > 0)
		{
			if(ltrk == w->len)
				return;
			
			bcopy(&(w->buf[w->len-ltrk]), w->buf, ltrk);
			printf("*** w: %i => %i\n", w->len, ltrk);
			w->len = ltrk;
			return;
		}
		
		player[idx].wps = player[idx].wps->n;
		free(w->buf);
		free(w);
		
		if(player[idx].throttle <= 0 && w != player[idx].wpe)
		{
			return;
		}
	}
	
	player[idx].wpe = NULL;
	
}

void cli_clean(void)
{
	int i;
	for(i = 0; i < player_l; i++)
		if(player[i].sockfd >= 0)
			close(player[i].sockfd);
}

int gettile(struct map *m, int x, int y, int z)
{
	if(x < m->maplx && y < m->maplz && z < m->maply && x >= 0 && y >= 0 && z >= 0)
		return m->mapdata[4+x+(z*m->maplx)+(y*m->mapzstep)];
	
	return 7;
}

void settile(struct map *m, int x, int y, int z, int t)
{
	if(x < m->maplx && y < m->maplz && z < m->maply && x >= 0 && y >= 0 && z >= 0)
		m->mapdata[4+x+(z*m->maplx)+(y*m->mapzstep)] = t;
}

int tilein(struct map *m, int x1,int y1,int z1, int x2,int y2,int z2, int t)
{
	int dx,dy,dz;
	for(dx = x1;dx <= x2; dx++)
		for(dy = y1;dy <= y2; dy++)
			for(dz = z1;dz <= z2; dz++)
				if(gettile(m,dx,dy,dz) == t)
					return 1;
	
	return 0;
}

struct map *getmapbyidx(uint16_t midx)
{
	struct map *m;
	
	for(m = maplist; m != NULL; m = m->n)
	{
		if(m->midx == midx)
			return m;
	}
	
	return NULL;
}

void pkt_announce(int sockfd, char *pkt, int len)
{
	int i;
	
	for(i = 0; i < player_l; i++)
		if(player[i].sockfd != sockfd)
			sendall(i, pkt, len);
}

void pkt_announce_map(int idx, char *pkt, int len)
{
	int i;
	int midx = (idx < 0 ? -idx : player[idx].midx);
	
	for(i = 0; i < player_l; i++)
		if(player[i].midx == midx && i != idx)
			sendall(i, pkt, len);
}

void rmplayer(int idx, char *msg)
{
	char pkt[2];
	
	pkt[0] = '\x0C';
	pkt[1] = player[idx].id;
	
	pkt_announce_map(idx, &pkt[0], 2);
	
	if(player[idx].oname != NULL)
	{
		if(player[idx].m != NULL && part_hook != NULL)
		{
			lua_getglobal(Lg, part_hook);
			lua_pushinteger(Lg, player[idx].id);
			lua_pushstring(Lg, player[idx].oname);
			lua_pushinteger(Lg, idx);
			lua_pushinteger(Lg, player[idx].midx);
			int err = lua_pcall(Lg, 4, 0, 0);
			if(err)
			{
				printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
				lua_pop(Lg, 1);
			}
		}

		if(disconnect_hook != NULL)
		{
			lua_getglobal(Lg, disconnect_hook);
			lua_pushinteger(Lg, player[idx].id);
			lua_pushstring(Lg, player[idx].oname);
			lua_pushinteger(Lg, idx);
			int err = lua_pcall(Lg, 3, 0, 0);
			if(err)
			{
				printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
				lua_pop(Lg, 1);
			}
		}
		free(player[idx].oname);
	}
	
	if(player[idx].name != NULL)
	{
		free(player[idx].name);
	}
	
	if(player[idx].sockfd >= 0)
	{
		if(msg != NULL)
		{
			// TODO make sure this actually goes through in all cases
			char kpkt[65];
			kpkt[0] = '\x0E';
			memset(&kpkt[1], ' ', 64);
			strcpy(&kpkt[1], msg);
			sendall(idx, &kpkt[0], 65);
		}
		close(player[idx].sockfd);
		rmfd(&readfds, &rfdi[0], &rfdi_l, &rfdi_u, player[idx].sockfd);
		rmfd(&writefds, &wfdi[0], &wfdi_l, &wfdi_u, player[idx].sockfd);
	}
	
	player[idx] = player[player_l--];
}

void settile_announce(struct map *m, int x,int y,int z, int t)
{
	char pkt[8];
	
	settile(m,x,y,z,t);
	
	pkt[0] = '\x06';
	pkt[1] = x>>8;
	pkt[2] = x;
	pkt[3] = y>>8;
	pkt[4] = y;
	pkt[5] = z>>8;
	pkt[6] = z;
	pkt[7] = t;
	
	pkt_announce_map(-m->midx, &pkt[0], 8);
}

void settile_specific(int x,int y,int z,int t,int idx)
{
	char pkt[8];
	
	pkt[0] = '\x06';
	pkt[1] = x>>8;
	pkt[2] = x;
	pkt[3] = y>>8;
	pkt[4] = y;
	pkt[5] = z>>8;
	pkt[6] = z;
	pkt[7] = t;
	sendall(idx, &pkt[0], 8);
}

void puttile(struct map *m, int x, int y, int z, int idx, int bidx)
{
	int bsend = 1;
	
	if(puttile_hook != NULL)
	{
		lua_getglobal(Lg, puttile_hook);
		lua_pushinteger(Lg, x);
		lua_pushinteger(Lg, y);
		lua_pushinteger(Lg, z);
		lua_pushstring(Lg, player[idx].name);
		lua_pushinteger(Lg, bidx);
		lua_pushinteger(Lg, player[idx].midx);
		int err = lua_pcall(Lg, 6, 0, 0);
		if(err)
		{
			printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
			lua_pop(Lg, 1);
		}
		return;
	}
	
	// Make sure you set a hook as this sucks and
	// would be dangerous if it didn't suck this much
	printf("TODO for mod author: use minecraft.sethook_puttile()!\n");
	
	// we announce back to avoid a race condition
	if(bsend)
		settile_announce(m,x,y,z,bidx);//(idx == -1 ? -1 : player[idx].sockfd));
}

int cli_setmap(int idx, struct map *m, int sx, int sy, int sz, int syo, int sxo)
{
	// This is where we send the big beast.
	
	uint8_t *buildbuf;
	int bbp = 0;
	int i;
	
	// Remove player from map if necessary.
	if(player[idx].m != NULL)
	{
		if(part_hook != NULL)
		{
			lua_getglobal(Lg, part_hook);
			lua_pushinteger(Lg, player[idx].id);
			lua_pushstring(Lg, player[idx].oname);
			lua_pushinteger(Lg, idx);
			lua_pushinteger(Lg, player[idx].midx);
			int err = lua_pcall(Lg, 4, 0, 0);
			if(err)
			{
				printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
				lua_pop(Lg, 1);
			}
		}
		
		char pkt[2];
		
		pkt[0] = '\x0C';
		pkt[1] = player[idx].id;
	
		pkt_announce_map(idx, &pkt[0], 2);
		
		player[idx].m = NULL;
		player[idx].midx = 0;
	}
	
	// 00: Hello, my name is Server.
	// Believe it or not, the 00 packet is purely optional.
	printf("message 00/02\n");
	buildbuf = malloc(1+1+64+64+1+1); // also has 02 packet
	buildbuf[bbp++] = '\x00';
	buildbuf[bbp++] = '\x07'; // Proto version.
	memset(&buildbuf[bbp], ' ', 64);
	strncpy(&buildbuf[bbp], server_name, 64);
	bbp += 64;
	memset(&buildbuf[bbp], ' ', 64);
	strncpy(&buildbuf[bbp], server_msg, 64);
	bbp += 64;
	buildbuf[bbp++] = player[idx].adminium;
	// 02: We have a new map.
	buildbuf[bbp++] = '\x02';
	
	// send both 00 and 02
	sendall(idx, buildbuf,1+1+64+64+1+1);
	
	free(buildbuf);
	
	// QUICKLY set position to (0,0,0).
	// This is the default position and is technically unreachable.
	player[idx].x = player[idx].y = player[idx].z = 0;
	
	// Yay, we have to use zlib.
	printf("GZip time.\n");
	
	errno = 0;
	gzFile gzfp = gzopen("tmpmap.gz","wb");
	if(gzfp == NULL)
	{
		printf("error opening tmpmap.gz: %i = %s\n", errno, strerror(errno));
		return 0;
	}
	
	int zlen = m->maplx*m->maply*m->maplz+4;
	gzwrite(gzfp, m->mapdata, zlen);
	gzclose(gzfp);
	
	printf("Reloading gzip data.");
	FILE *fp = fopen("tmpmap.gz","rb");
	
	zlen += (zlen>>6)+128;
	mapgz = malloc(zlen);
	int q = 0;
	for(;;)
	{
		int r = fread(&mapgz[q],1,1024,fp);
		if(r == 0)
			break;
		if(r == -1)
		{
			printf("error reading gzip: %i = %s\n", errno, strerror(errno));
			break;
		}
		q += r;
	}
	zlen = q;
	fclose(fp);
	printf("gzipped successfully, size = %i bytes\n", zlen);
	
	// 03: We're sending map data.
	printf("message 03\n");
	buildbuf = malloc(1+2+1024+1);
	int zpos = 0;
	while(zpos < zlen)
	{
		buildbuf[0] = '\x03';
		int plen = MIN(zlen - zpos, 1024);
		buildbuf[1] = plen >> 8;
		buildbuf[2] = plen;
		memcpy(&buildbuf[3], &mapgz[zpos], plen);
		
		zpos += plen;
		
		if(zpos >= plen)
			buildbuf[1027] = 100;
		else
			buildbuf[1027] = (zpos*100)/plen;
		
		sendall(idx, buildbuf, 1+2+1024+1);
	}
	free(buildbuf);
	free(mapgz);
	
	// 04: This is your map size.
	printf("message 04\n");
	buildbuf = malloc(1+2+2+2);
	buildbuf[0] = '\x04';
	buildbuf[1] = m->maplx >> 8;
	buildbuf[2] = m->maplx;
	buildbuf[3] = m->maplz >> 8;
	buildbuf[4] = m->maplz;
	buildbuf[5] = m->maply >> 8;
	buildbuf[6] = m->maply;
	sendall(idx, buildbuf, 1+2+2+2);
	free(buildbuf);
	
	// 07: This is you.
	printf("message 07\n");
	buildbuf = malloc(1+1+64+2+2+2+1+1);
	buildbuf[0] = '\x07';
	buildbuf[1] = '\xFF';
	memset(&buildbuf[2], ' ', 64);
	strcpy(&buildbuf[2], player[idx].name);
	player[player_l].x = player[player_l].px = sx;
	player[player_l].y = player[player_l].py = sy;
	player[player_l].z = player[player_l].pz = sz;
	player[player_l].yo = player[player_l].pyo = syo;
	player[player_l].xo = player[player_l].pxo = sxo;
	buildbuf[66] = sx>>8;
	buildbuf[67] = sx;
	buildbuf[68] = sy>>8;
	buildbuf[69] = sy;
	buildbuf[70] = sz>>8;
	buildbuf[71] = sz;
	buildbuf[72] = syo;
	buildbuf[73] = sxo;
	sendall(idx, buildbuf, 1+1+64+2+2+2+1+1);
	// Now to relay this to everyone else.
	buildbuf[1] = player[idx].id;
	player[idx].m = m;
	player[idx].midx = m->midx;
	pkt_announce_map(idx, buildbuf, 1+1+64+2+2+2+1+1);
	// OK, relay all the other players to you.
	for(i = 0; i < player_l; i++)
	{
		if(i != idx)
		{
			buildbuf[1] = player[i].id;
			memset(&buildbuf[2], ' ', 64);
			strcpy(&buildbuf[2], player[i].name);
			buildbuf[66] = player[i].x>>8;
			buildbuf[67] = player[i].x;
			buildbuf[68] = player[i].y>>8;
			buildbuf[69] = player[i].y;
			buildbuf[70] = player[i].z>>8;
			buildbuf[71] = player[i].z;
			buildbuf[72] = player[i].yo;
			buildbuf[73] = player[i].xo;
			sendall(idx, buildbuf, 1+1+64+2+2+2+1+1);
		}
	}
	free(buildbuf);
	
	// Scrub that.
	/*
	// 0D: Hello and welcome to the server.
	printf("message 0D\n");
	buildbuf = malloc(1+1+64);
	buildbuf[0] = '\x0D';
	buildbuf[1] = '\xFF';
	memset(&buildbuf[2], ' ', 64);
	strcpy(&buildbuf[2], "Hello this is a custom server LOL");
	sendall(idx, buildbuf, 1+1+64);
	free(buildbuf);
	*/
	
	// Finally, the lua hook.
	if(join_hook != NULL)
	{
		lua_getglobal(Lg, join_hook);
		lua_pushinteger(Lg, player[idx].id);
		lua_pushstring(Lg, player[idx].name);
		lua_pushinteger(Lg, idx);
		lua_pushinteger(Lg, player[idx].midx);
		int err = lua_pcall(Lg, 4, 0, 0);
		if(err)
		{
			printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
			lua_pop(Lg, 1);
		}
	}
	
	printf("all done\n");
}

void cli_read(int idx)
{
	int i,j;
	
	if(player[idx].sockfd < 0)
		return;
	
	struct map *m = player[idx].m;
	
	int len = recv(player[idx].sockfd, &(player[idx].ldbuf[player[idx].ldbend]), 512, O_NONBLOCK); // Be explicit
	if(len == -1)
	{
		if(errno != EAGAIN)
		{
			printf("Error on %04X: %i = %s\n", ntohs(player[idx].sckad.sin_port), errno, strerror(errno));
			close(player[idx].sockfd);
			player[idx].sockfd = -2;
			return;
		}
	} else if(len != 0) {
		int oend = player[idx].ldbend;
		int nend = oend + len;
		player[idx].ldbsize += len;
		if(nend > 0x0800)
		{
			memcpy(&(player[idx].ldbuf[oend+0x0800]),&(player[idx].ldbuf[oend]),0x0800-oend);
			memcpy(&(player[idx].ldbuf[0x0000]),&(player[idx].ldbuf[0x0800]),nend-0x0800);
		} else {
			memcpy(&(player[idx].ldbuf[oend+0x0800]),&(player[idx].ldbuf[oend]),len);
		}
		
		player[idx].ldbend = nend & 0x07FF;
		
		int qpos = player[idx].ldbstart & 0x7FF;
		
		//printf("Packet [%03X:%03X:%03X:%03X] %i bytes\n", player[idx].sockfd, qpos, oend, nend, len);
		
		//player[idx].ldbstart = nend & 0x07FF;
		
		int qlen = player[idx].ldbsize;
		
		int allgood;
		do {	
			if(qpos == nend)
				break;
			
			// Check the packet type.
			uint8_t type = player[idx].ldbuf[qpos];
			char *buildbuf = NULL;
			//if(type != 0x08)
			//	printf("Got packet of type: %02X\n", type);
			
			allgood = 0;
			switch(type)
			{
				case '\x00':
					if(qlen < 1+1+64+64+1)
						break;
					qlen -= 1+1+64+64+1;
					allgood = 1;
					qpos++;
				
					printf("Protocol version %02X\n", player[idx].ldbuf[qpos]);
					qpos++;
					player[idx].name = pkt_str(&(player[idx].ldbuf[qpos]));
					player[idx].oname = strdup(player[idx].name);
					printf("Player name: %s\n", player[idx].name);
					qpos += 64;
					player[idx].loginid = pkt_str(&(player[idx].ldbuf[qpos]));
					printf("Player mppass: %s\n", player[idx].loginid);
					qpos += 64;
					printf("Padding byte (Notch byte?): %02X\n", player[idx].ldbuf[qpos]);
					qpos++;
					
					{
						if(connect_hook != NULL)
						{
							lua_getglobal(Lg, connect_hook);
							lua_pushinteger(Lg, player[idx].id);
							lua_pushstring(Lg, player[idx].name);
							lua_pushinteger(Lg, idx);
							int err = lua_pcall(Lg, 3, 1, 0);
							if(err)
							{
								printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
								lua_pop(Lg, 1);
								printf("script failed\n");
								rmplayer(idx,"script made a doodoo");
								break;
							} else {
								printf("return value...\n");
								if(lua_toboolean(Lg, -1))
								{
									printf("connected\n");
									lua_pop(Lg, 1);
								} else {
									printf("disconnected\n");
									lua_pop(Lg, 1);
									break;
								}
							}
						}
					}
					break;
				
				case '\x05':
					if(qlen < 1+2+2+2+1+1)
						break;
					qlen -= 1+2+2+2+1+1;
					allgood = 1;
					
					if(m == NULL)
						break;
					
					{
						qpos++;
						int x,y,z;
						x = player[idx].ldbuf[qpos++]<<8;
						x |= player[idx].ldbuf[qpos++];
						y = player[idx].ldbuf[qpos++]<<8;
						y |= player[idx].ldbuf[qpos++];
						z = player[idx].ldbuf[qpos++]<<8;
						z |= player[idx].ldbuf[qpos++];
					
						int bcmd = player[idx].ldbuf[qpos++];
						int bidx = player[idx].ldbuf[qpos++];
						printf("block cmd %02X type %02X at: %i,%i,%i\n"
							,bcmd,bidx,x,y,z);
						
						if(x < m->maplx && y < m->maplz && z < m->maply)
						{
							if(player[idx].tmpdrop)
							{
								puttile(m,x,y,z,idx,player[idx].tmpdrop);
								player[idx].tmpdrop = 0x00;
							} else if(bcmd == 0x01)
								puttile(m,x,y,z,idx,bidx);
							else if(bcmd == 0x00)
								puttile(m,x,y,z,idx,0x00);
						}
					}
					break;
				
				case '\x08':
					if(qlen < 1+1+2+2+2+1+1)
						break;
					qlen -= 1+1+2+2+2+1+1;
					allgood = 1;
					
					// Let's update the player info!
					//printf("player position packet\n");
					j = qpos;
					qpos++;
					//printf("given player ID: %02X\n", player[idx].ldbuf[qpos]);
					qpos++;
					player[idx].x = player[idx].ldbuf[qpos++]<<8;
					player[idx].x |= player[idx].ldbuf[qpos++];
					player[idx].y = player[idx].ldbuf[qpos++]<<8;
					player[idx].y |= player[idx].ldbuf[qpos++];
					player[idx].z = player[idx].ldbuf[qpos++]<<8;
					player[idx].z |= player[idx].ldbuf[qpos++];
					
					player[idx].yo = player[idx].ldbuf[qpos++];
					player[idx].xo = player[idx].ldbuf[qpos++];
					
					player[idx].ldbuf[j+1] = player[idx].id;
					pkt_announce_map(idx, &(player[idx].ldbuf[j]), 1+1+2+2+2+1+1);
					/*printf("coords: %i.%X,%i.%X,%i.%X (%i,%i)\n"
						,player[idx].x>>4
						,player[idx].x&15
						,player[idx].y>>4
						,player[idx].y&15
						,player[idx].z>>5
						,player[idx].z&15
						,player[idx].yo
						,player[idx].xo);*/
					break;
				
				case '\x0D':
					if(qlen < 1+1+64)
						break;
					qlen -= 1+1+64;
					allgood = 1;
					
					j = qpos;
					qpos++;
					printf("Chat: %02X ", player[idx].ldbuf[qpos]);
					qpos++;
					j = qpos;
					for(i = 0; i < 64; i++)
						printf("%c",player[idx].ldbuf[qpos+i]);
					printf("\n");
					qpos += 64;
					if(chat_hook != NULL)
					{
						char *msg = pkt_str(&(player[idx].ldbuf[j]));
						lua_getglobal(Lg, chat_hook);
						lua_pushinteger(Lg, idx);
						lua_pushinteger(Lg, player[idx].id);
						lua_pushstring(Lg, msg);
						int err = lua_pcall(Lg, 3, 0, 0);
						if(err)
						{
							printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
							lua_pop(Lg, 1);
						}
						free(msg);
					} else {
						// Command?
						if(player[idx].ldbuf[j+2] == '/') // Yep.
						{
							if(!memcmp(&(player[idx].ldbuf[j+2]),"/rlava",6))
							{
								player[idx].tmpdrop = 10;
								memset(&(player[idx].ldbuf[j+2]), ' ', 64);
								strcpy(&(player[idx].ldbuf[j+2]), "Placing real lava");
							} else if(!memcmp(&(player[idx].ldbuf[j+2]),"/rwater",7)) {
								player[idx].tmpdrop = 8;
								memset(&(player[idx].ldbuf[j+2]), ' ', 64);
								strcpy(&(player[idx].ldbuf[j+2]), "Placing real water");
							} else {
								memset(&(player[idx].ldbuf[j+2]), ' ', 64);
								strcpy(&(player[idx].ldbuf[j+2]), "Unknown command");
							}
							sendall(idx, &player[idx].ldbuf[j], 1+1+64);
						} else { // Nope.
							// Relay.
							sendall(idx, &player[idx].ldbuf[j], 1+1+64);
							player[idx].ldbuf[j+1] = player[idx].id;
							pkt_announce(player[idx].sockfd, &player[idx].ldbuf[j], 1+1+64);
						}
					}
					break;
				default:
					printf("Unknown packet type: %02X\n", type);
					printf("Packet [%03X:%03X:%03X] %i bytes:\n", qpos, oend, nend, len);
					for(i = oend, j = 0; i < nend; i++,j++)
					{
						if(j >= 16)
						{
							printf("\n");
							j -= 16;
						}
						printf(" %02X", player[idx].ldbuf[i]);
					}
					printf("\n");
					qpos = nend;
					qlen = 0;
					break;
					
			}
		} while(allgood);
		
		player[idx].ldbstart = qpos & 0x07FF;
		player[idx].ldbsize = qlen;
		//
	}
}

void dotick(void)
{
	//printf("Tick %i.%06i\n", (int)tvtb.tv_sec,(int)tvtb.tv_usec);
	ticker_ping--;
	if(ticker_ping <= 0)
	{
		ticker_ping = 5;
		char pingpkt[1] = "\x01";
		printf("T: Ping\n");
		pkt_announce(-1, &pingpkt[0], 1);
	}
	
	int idx;
	for(idx = 0; idx < player_l; idx++)
	{
		player[idx].throttle += 10240;
		if(player[idx].throttle > 102400)
			player[idx].throttle = 102400;
	}
	
	if(dotick_hook != NULL)
	{
		lua_getglobal(Lg, dotick_hook);
		int err = lua_pcall(Lg, 0, 0, 0);
		if(err)
		{
			printf("lua error of %i: %s\n", err, lua_tostring(Lg, -1));
			lua_pop(Lg, 1);
		}
	}
}

// this was for a landscape generator, it now just does a simple flatgrass
void lsr_mkpillar(struct map *m, int x, int y, int h)
{
	uint8_t *mapdata = m->mapdata;
	if(mapdata[4+x+(y*m->maplx)])
		return;
	
	//printf("pillar %i,%i,%i\n", x,y,h);
	
	if(h < 1)
		h = 1;
	if(h >= m->maplz)
		h = m->maplz-1;
	
	int i, j=x+(y*m->maplx);
	for(i = 0; i < h-1; i++)
	{
		mapdata[4+j] = 3;
		j += m->mapzstep;
	}
	mapdata[4+j] = 2;
	
	//lsr_prog_cur++;
}

int buildmap(struct map *m)
{
	char *mapdata = m->mapdata;
	
	printf("Generating map\n");
	
	int mdlen = m->maplx*m->maply*m->maplz;
	m->mapdata = mapdata = malloc(mdlen+4);
	
	if(mapdata == NULL)
		return 1;
	// Big endian makes the world go "ARGH CRAP I'M USING AN INTEL CHIP >_>".
	mapdata[0] = mdlen>>24;
	mapdata[1] = mdlen>>16;
	mapdata[2] = mdlen>>8;
	mapdata[3] = mdlen;
	
	/*int x,y;
	for(x = 0; x < m->maplx; x++)
		for(y = 0; y < m->maply; y++)
			lsr_mkpillar(m,x,y,m->maplz>>1);
	*/
	
	return 0;
}

struct map *addmap(int lx, int ly, int lz)
{
	if(lx < 8 || ly < 8 || lz < 8)
	{
		printf("error: invalid map dimensions: %ix%ix%i\n",lx,ly,lz);
		return NULL;
	}
	
	struct map *m = malloc(sizeof(struct map));
	
	if(m == NULL)
	{
		printf("ERROR: COULD NOT CREATE %ix%ix%i MAP - THIS CASE IS REALLY SILLY\n",lx,ly,lz);
		return NULL;
	}
		
	m->maplx = lx;
	m->maply = lz;
	m->maplz = ly;
	m->mapzstep = lx*lz;
	
	if(buildmap(m))
	{
		printf("ERROR: COULD NOT CREATE %ix%ix%i MAP\n",lx,ly,lz);
		free(m);
		return NULL;
	}
	
	m->midx = midx_base++;
	
	m->p = maplistend;
	m->n = NULL;
	if(maplistend == NULL)
	{
		maplistend = maplist = m;
	} else {
		maplistend->n = m;
		maplistend = m;
	}
	
	return m;
}

void rmmap(struct map *m)
{
	// this is so we can cut down on code
	if(m == NULL)
		return;
	
	if(m->p != NULL)
		m->p->n = m->n;
	if(m->n != NULL)
		m->n->p = m->p;
	if(m == maplist)
		maplist = m->n;
	if(m == maplistend)
		maplistend = m->p;
	
	free(m->mapdata);
	free(m);
}

void mainloop(void)
{
	printf("Server initiated.\n");
	
	// Load lua.
	printf("running config.lua\n");
	luaL_loadfile(Lg, "config.lua");
	lua_call(Lg, 0, 0);
	printf("config.lua returned\n");
	
	
	fd_set rfds,wfds,xfds;
	struct timeval tvs;
	struct timeval tvt;
	int tdel;
	int i;
	
	gettimeofday(&tvtb,NULL);
	bumptick();
	
	for(;;)
	{	
		gettimeofday(&tvt,NULL);
		tvs.tv_sec = tvtb.tv_sec-tvt.tv_sec;
		tvs.tv_usec = tvtb.tv_usec-tvt.tv_usec;
		while(tvs.tv_usec < 0)
		{
			tvs.tv_usec += 1000000;
			tvs.tv_sec--;
		}
		if(tvs.tv_sec >= 0)
		{
			// This is where we call select().
			FD_ZERO(&rfds);
			FD_ZERO(&wfds);
			FD_ZERO(&xfds);
			for(i = 0; i < rfdi_l; i++)
				FD_SET(rfdi[i], &rfds);
			for(i = 0; i < wfdi_l; i++)
				FD_SET(wfdi[i], &wfds);
			for(i = 0; i < xfdi_l; i++)
				FD_SET(xfdi[i], &xfds);
			int top = MAX(MAX(rfdi_u,wfdi_u),xfdi_u)+1;
			int selfdct = select(top, &rfds, &wfds, &xfds, &tvs);
			
			//printf("Ret %i [%i,%i,%i]\n", selfdct, rfdi_u,FD_ISSET(sfd_base,&rfds),top);
			if(FD_ISSET(sfd_base, &rfds))
				ack_client();
			
			for(i = 0; i < player_l; i++)
				if(player[i].sockfd >= 0)
					if(FD_ISSET(player[i].sockfd, &rfds))
						cli_read(i);
			
			for(i = 0; i < player_l; i++)
				if(player[i].sockfd >= 0)
					if(FD_ISSET(player[i].sockfd, &wfds))
						sendall(i,NULL,0);
			
			for(i = 0; i < player_l; i++)
				if(player[i].sockfd < 0)
				{
					rmplayer(i, NULL);
					i--;
				}
			
			usleep(1000);
		} else {
			dotick();
			bumptick();
		}
	}
	
	while(maplist != NULL)
	{
		struct map *m = maplist->n;
		rmmap(maplist);
		maplist = m;
	}
	
	if(server_name != NULL)
		free(server_name);
	if(server_msg != NULL)
		free(server_msg);
	
	cli_cleanup();
}

static int lf_gettile(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 4)
		return 0;
	
	int midx = lua_tointeger(L, 1);
	int x = lua_tointeger(L, 2);
	int y = lua_tointeger(L, 3);
	int z = lua_tointeger(L, 4);
	
	struct map *m = getmapbyidx(midx);
	
	if(m == NULL)
		return 0;
	
	lua_pushinteger(L, gettile(m,x,y,z));
	
	return 1;
}

static int lf_settile(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 5)
		return 0;
	
	int midx = lua_tointeger(L, 1);
	int x = lua_tointeger(L, 2);
	int y = lua_tointeger(L, 3);
	int z = lua_tointeger(L, 4);
	int t = lua_tointeger(L, 5);
		
	struct map *m = getmapbyidx(midx);
	
	if(m == NULL)
		return 0;

	settile(m,x,y,z,t);
	
	return 0;
}

static int lf_settile_announce(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 5)
		return 0;
	
	int midx = lua_tointeger(L, 1);
	int x = lua_tointeger(L, 2);
	int y = lua_tointeger(L, 3);
	int z = lua_tointeger(L, 4);
	int t = lua_tointeger(L, 5);
	
	struct map *m = getmapbyidx(midx);
	
	if(m == NULL)
		return 0;
	
	settile_announce(m,x,y,z,t);
	
	return 0;
}

static int lf_faketile(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 5)
		return 0;
	
	int x = lua_tointeger(L, 1);
	int y = lua_tointeger(L, 2);
	int z = lua_tointeger(L, 3);
	int t = lua_tointeger(L, 4);
	int idx = lua_tointeger(L, 5);
	
	settile_specific(x,y,z,t,idx);
	
	return 0;
}

static int lf_addmap(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 3)
		return 0;
	
	int lx = lua_tointeger(L, 1);
	int ly = lua_tointeger(L, 2);
	int lz = lua_tointeger(L, 3);
	
	int midx = 0;
	
	struct map *m = addmap(lx,ly,lz);
	if(m == NULL)
		return 0;
	
	lua_pushinteger(L, m->midx);
	
	return 1;
}

static int lf_rmmap(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int midx = lua_tointeger(L, 1);
	
	rmmap(getmapbyidx(midx));
	
	return 0;
}

static int lf_sethook_puttile(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	char *oldh = puttile_hook;
	
	if(lua_isnil(L, 1))
		puttile_hook = NULL;
	else if(lua_isstring(L, 1))
		puttile_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_dotick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	char *oldh = dotick_hook;
	
	if(lua_isnil(L, 1))
		dotick_hook = NULL;
	else if(lua_isstring(L, 1))
		dotick_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_chat(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	char *oldh = chat_hook;
	
	if(lua_isnil(L, 1))
		chat_hook = NULL;
	else if(lua_isstring(L, 1))
		chat_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_join(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	char *oldh = join_hook;
	
	if(lua_isnil(L, 1))
		join_hook = NULL;
	else if(lua_isstring(L, 1))
		join_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_part(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	char *oldh = part_hook;
	
	if(lua_isnil(L, 1))
		part_hook = NULL;
	else if(lua_isstring(L, 1))
		part_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_connect(lua_State *L)
{
	int n = lua_gettop(L);
	
	if(n < 1)
		return 0;
	
	char *oldh = connect_hook;
	
	if(lua_isnil(L, 1))
		connect_hook = NULL;
	else if(lua_isstring(L, 1))
		connect_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_sethook_disconnect(lua_State *L)
{
	int n = lua_gettop(L);
	
	if(n < 1)
		return 0;
	
	char *oldh = disconnect_hook;
	
	if(lua_isnil(L, 1))
		disconnect_hook = NULL;
	else if(lua_isstring(L, 1))
		disconnect_hook = strdup(lua_tostring(L, 1));
	else
		return 0;
	
	if(oldh != NULL)
		free(oldh);
	
	return 0;
}

static int lf_chatmsg(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 3)
		return 0;
	
	char pkt[66];
	int sockfd = lua_tointeger(L, 1);
	pkt[0] = '\x0D';
	pkt[1] = lua_tointeger(L, 2);
	const char *msg = lua_tostring(L, 3);
	if(msg == NULL)
	{
		printf("error: null message o_O\n");
		return 0;
	}
	char *v = (char *)msg;
	
	while(strlen(v) > 64)
	{
		memcpy(&pkt[2], v, 64);
		v += 64;
		sendall(sockfd, &pkt[0], 66);
	}
	if(strlen(v) > 0)
	{
		memset(&pkt[2], ' ', 64);
		strcpy(&pkt[2], msg);
		sendall(sockfd, &pkt[0], 66);
	}
	
	return 0;
}

static int lf_chatmsg_all(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 2)
		return 0;
	
	int i;
	char pkt[66];
	pkt[0] = '\x0D';
	pkt[1] = lua_tointeger(L, 1);
	const char *msg = lua_tostring(L, 2);
	if(msg == NULL)
	{
		printf("error: null message o_O\n");
		return 0;
	}
	
	char *v = (char *)msg;
	while(strlen(v) > 64)
	{
		memcpy(&pkt[2], v, 64);
		v += 64;
		pkt_announce(-1, &pkt[0], 66);
	}
	if(strlen(msg) > 0)
	{
		memset(&pkt[2], ' ', 64);
		strcpy(&pkt[2], v);
		pkt_announce(-1, &pkt[0], 66);
	}
	
	return 0;
}

static int lf_chatmsg_map(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 3)
		return 0;
	
	char pkt[66];
	int midx = lua_tointeger(L, 1);
	pkt[0] = '\x0D';
	pkt[1] = lua_tointeger(L, 2);
	const char *msg = lua_tostring(L, 3);
	if(msg == NULL)
	{
		printf("error: null message o_O\n");
		return 0;
	}
	
	char *v = (char *)msg;
	while(strlen(v) > 64)
	{
		memcpy(&pkt[2], v, 64);
		v += 64;
		pkt_announce_map(-midx, &pkt[0], 66);
	}
	if(strlen(msg) > 0)
	{
		memset(&pkt[2], ' ', 64);
		strcpy(&pkt[2], v);
		pkt_announce_map(-midx, &pkt[0], 66);
	}
	
	return 0;
}

static int lf_gp_nick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	lua_pushstring(L, player[idx].oname);
	
	return 1;
}

static int lf_gp_fnick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	lua_pushstring(L, player[idx].name);
	
	return 1;
}

static int lf_getidxbynick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	const char *nick = lua_tostring(L, 1);
	if(nick == NULL)
		return 0;
	
	int i;
	for(i = 0; i < player_l; i++)
		// prevent a SIGSEGV by checking if oname is set
		if(player[i].oname != NULL && !strcmp(player[i].oname, nick))
		{
			lua_pushinteger(L, i);
			return 1;
		}
	
	lua_pushinteger(L, -1);
	
	return 1;
}

static int lf_getidxbyfnick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	const char *nick = lua_tostring(L, 1);
	if(nick == NULL)
		return 0;
	
	int i;
	for(i = 0; i < player_l; i++)
		if(!strcmp(player[i].name, nick))
		{
			lua_pushinteger(L, i);
			return 1;
		}
	
	lua_pushinteger(L, -1);
	
	return 1;
}

static int lf_getidxbyid(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int id = lua_tointeger(L, 1);
	
	int i;
	for(i = 0; i < player_l; i++)
		if(player[i].id == id)
		{
			lua_pushinteger(L, i);
			return 1;
		}
	
	lua_pushinteger(L, -1);
	
	return 1;
}

static int lf_gp_id(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	lua_pushinteger(L, player[idx].id);
	
	return 1;
}

static int lf_gp_midx(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	if(player[idx].m == NULL)
		lua_pushnil(L);
	else
		lua_pushinteger(L, player[idx].midx);
	
	return 1;
}

static int lf_gp_pos(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	lua_pushinteger(L, player[idx].x);
	lua_pushinteger(L, player[idx].y);
	lua_pushinteger(L, player[idx].z);
	lua_pushinteger(L, player[idx].xo);
	lua_pushinteger(L, player[idx].yo);
	
	return 5;
}

static int lf_sp_pos(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 6)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	int x = player[idx].x = lua_tointeger(L, 2);
	int y = player[idx].y = lua_tointeger(L, 3);
	int z = player[idx].z = lua_tointeger(L, 4);
	int xo = player[idx].xo = lua_tointeger(L, 5);
	int yo = player[idx].yo = lua_tointeger(L, 6);
	
	char pkt[10];
	
	pkt[0] = '\x08';
	pkt[1] = '\xFF';
	pkt[2] = x>>8;
	pkt[3] = x;
	pkt[4] = y>>8;
	pkt[5] = y;
	pkt[6] = z>>8;
	pkt[7] = z;
	pkt[8] = yo;
	pkt[9] = xo;
	
	sendall(idx, &pkt[0], 10);
	pkt[1] = player[idx].id;
	pkt_announce_map(idx, &pkt[0], 10);
	
	return 0;
}

static int lf_kickplayer(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 2)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	if(idx < 0 || idx >= player_l)
		return 0;
	
	const char *msg = lua_tostring(L, 2);
	char pkt[65];
	
	pkt[0] = '\x0E';
	memset(&pkt[1], ' ', 64);
	strncpy(&pkt[1], msg, 64);
	sendall(idx, &pkt[0], 76);
	
	return 0;
}

static int lf_partplayer(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	rmplayer(idx, NULL);
	
	return 0;
}

// This is really the only way to do it and it sucks
static int lf_sp_nick(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 2)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	char *nick = strdup(lua_tostring(L, 2));
	
	if(strlen(nick) > 64)
		nick[64] = '\0';
	
	player[idx].name = nick;
	
	char pkt[76];
	
	pkt[0] = '\x0C';
	pkt[1] = player[idx].id;
	pkt[2] = '\x07';
	pkt[3] = player[idx].id;
	memset(&pkt[4], ' ', 64);
	strncpy(&pkt[4], player[idx].name, 64);
	pkt[68] = player[idx].x>>8;
	pkt[69] = player[idx].x;
	pkt[70] = player[idx].y>>8;
	pkt[71] = player[idx].y;
	pkt[72] = player[idx].z>>8;
	pkt[73] = player[idx].z;
	pkt[74] = player[idx].yo;
	pkt[75] = player[idx].xo;
	pkt_announce_map(idx, &pkt[0], 76);
	
	return 0;
}


static int lf_getmapdims(lua_State *L)
{
	int n = lua_gettop(L);
	
	if(n < 1)
		return 0;
	
	int midx = lua_tointeger(L, 1);
	
	struct map *m = getmapbyidx(midx);
	
	if(m == NULL)
		return 0;
	
	lua_pushinteger(L, m->maplx);
	lua_pushinteger(L, m->maplz);
	lua_pushinteger(L, m->maply);
	
	return 3;
}

static int lf_setmap(lua_State *L)
{
	int n = lua_gettop(L);
	if(n < 9)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	const char *svname = lua_tostring(L, 2);
	const char *svmsg = lua_tostring(L, 3);
	int midx = lua_tointeger(L, 4);
	int sx = lua_tointeger(L, 5);
	int sy = lua_tointeger(L, 6);
	int sz = lua_tointeger(L, 7);
	int syo = lua_tointeger(L, 8);
	int sxo = lua_tointeger(L, 9);
	
	struct map *m = getmapbyidx(midx);
	if(m == NULL)
		return 0;
	
	if(svname != NULL)
	{
		if(server_name != NULL)
			free(server_name);
		server_name = strdup(svname);
	}
	
	if(svmsg != NULL)
	{
		if(server_msg != NULL)
			free(server_msg);
		server_msg = strdup(svmsg);
	}
	
	cli_setmap(idx, m, sx, sy, sz, syo, sxo);
	
	return 0;
}

static int lf_getadminium(lua_State *L)
{
	int n = lua_gettop(L);
	
	if(n < 1)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	
	lua_pushinteger(L, player[idx].adminium);
	
	return 1;
}

static int lf_setadminium(lua_State *L)
{
	int n = lua_gettop(L);
	
	if(n < 3)
		return 0;
	
	int idx = lua_tointeger(L, 1);
	int adm = player[idx].adminium = lua_tointeger(L, 2);
	
	if(lua_toboolean(L, 3))
	{
		char pkt[2];
	
		pkt[0] = '\x0F';
		pkt[1] = adm;
	
		sendall(idx, &pkt[0], 2);
	}
	
	return 0;
}
void addluafunct(char *n, lua_CFunction f)
{
	lua_getglobal(Lg, "minecraft");
	lua_pushcfunction(Lg, f);
	lua_setfield(Lg, -2, n);
	lua_pop(Lg, 1);
}

int main(int argc, char *argv[])
{
	// I haven't got a CLUE why this defaults to "OH NOES CRASH ME BUHUHUH"
	// So, uh, let's ignore SIGPIPE!
	signal(SIGPIPE, SIG_IGN);
	
	randbase = time(NULL);
	
	Lg = luaL_newstate();
	luaL_openlibs(Lg);
	// Prep our tables.
	lua_newtable(Lg);
	lua_setglobal(Lg, "minecraft");
	lua_newtable(Lg);
	lua_setglobal(Lg, "g");
	// Add some functions.
	addluafunct("gettile", lf_gettile);
	addluafunct("settile", lf_settile);
	addluafunct("settile_announce", lf_settile_announce);
	addluafunct("faketile", lf_faketile);
	addluafunct("addmap", lf_addmap);
	addluafunct("rmmap", lf_rmmap);
	addluafunct("sethook_puttile", lf_sethook_puttile);
	addluafunct("sethook_dotick", lf_sethook_dotick);
	addluafunct("sethook_chat", lf_sethook_chat);
	addluafunct("sethook_join", lf_sethook_join);
	addluafunct("sethook_part", lf_sethook_part);
	addluafunct("sethook_connect", lf_sethook_connect);
	addluafunct("sethook_disconnect", lf_sethook_disconnect);
	addluafunct("setmap", lf_setmap);
	addluafunct("getadminium", lf_getadminium);
	addluafunct("setadminium", lf_setadminium);
	addluafunct("chatmsg", lf_chatmsg);
	addluafunct("chatmsg_all", lf_chatmsg_all);
	addluafunct("chatmsg_map", lf_chatmsg_map);
	addluafunct("gp_nick", lf_gp_nick);
	addluafunct("gp_fnick", lf_gp_fnick);
	addluafunct("sp_nick", lf_sp_nick);
	addluafunct("gp_midx", lf_gp_midx);
	addluafunct("gp_id", lf_gp_id);
	addluafunct("gp_pos", lf_gp_pos);
	addluafunct("sp_pos", lf_sp_pos);
	addluafunct("getidxbynick", lf_getidxbynick);
	addluafunct("getidxbyfnick", lf_getidxbyfnick);
	addluafunct("getidxbyid", lf_getidxbyid);
	addluafunct("getmapdims", lf_getmapdims);
	addluafunct("kickplayer", lf_kickplayer);
	addluafunct("partplayer", lf_partplayer);
	
	// Init the server.
	sfd_base = socket(AF_INET, SOCK_STREAM, 0);
	if(sfd_base == -1)
	{
		printf("error opening server socket: %i = %s\n", errno, strerror(errno));
		return 102;
	}
	
	struct sockaddr_in addr;
	
	addr.sin_family = AF_INET;
	addr.sin_port = htons(25565);
	addr.sin_addr.s_addr = htonl(0x00000000);
	
	if(bind(sfd_base, (const struct sockaddr *)&addr, sizeof(struct sockaddr_in)) == -1)
	{
		printf("error binding server socket: %i = %s\n", errno, strerror(errno));
		close(sfd_base);
		
		return 103;
	}
	
	// Let's edit the server socket.
	int fcv = fcntl(sfd_base, F_GETFL, 0);
	if(fcv == -1)
	{
		printf("error unflagging server socket: %i = %s\n", errno, strerror(errno));
		shutdown(sfd_base, SHUT_RDWR);
		close(sfd_base);
		
		return 104;
	}
	if(fcntl(sfd_base, F_SETFL, fcv | O_NONBLOCK) == -1)
	{
		printf("error reflagging server socket: %i = %s\n", errno, strerror(errno));
		shutdown(sfd_base, SHUT_RDWR);
		close(sfd_base);
		
		return 105;
	}
	if(listen(sfd_base, 2) == -1)
	{
		printf("error listening server socket: %i = %s\n", errno, strerror(errno));
		shutdown(sfd_base, SHUT_RDWR);
		close(sfd_base);
		return 106;
	}
	
	// Prepare for some select()ness.
	FD_ZERO(&readfds);
	FD_ZERO(&writefds);
	FD_ZERO(&exceptfds);
	
	addfd(&readfds,&rfdi[0],&rfdi_l,&rfdi_u,sfd_base);
	
	server_name = strdup("This LuaCraft server is not named!");
	server_msg = strdup("The server owner will be eaten by wild hampsters");
	mainloop();
	
	shutdown(sfd_base, SHUT_RDWR);
	close(sfd_base);
	return 0;
}

