pdata = {}

tile = {
	AIR = 0,
	ROCK = 1,
	GRASS = 2,
	DIRT = 3,
	STONE = 4,
	WOOD = 5,
	SHRUB = 6,
	BLACKROCK = 7,
	WATER = 8,
	WATERSTILL = 9,
	LAVA = 10,
	LAVASTILL = 11,
	SAND = 12,
	GRAVEL = 13,
	GOLD = 14,
	IRON = 15,
	COAL = 16,
	TRUNK = 17,
	LEAF = 18,
	SPONGE = 19,
	GLASS = 20,
	RED = 21,
	ORANGE = 22,
	YELLOW = 23,
	LIGHTGREEN = 24,
	GREEN = 25,
	AQUAGREEN = 26,
	CYAN = 27,
	BLUE = 28,
	PURPLE = 29,
	INDIGO = 30,
	VIOLET = 31,
	MAGENTA = 32,
	PINK = 33,
	DARKGREY = 34,
	LIGHTGREY = 35,
	WHITE = 36,
	YELLOWFLOWER = 37,
	REDFLOWER = 38,
	MUSHROOM = 39,
	REDMUSHROOM = 40,
	SOLIDGOLD = 41,
	IRON = 42,
	BLOCKF = 43,
	BLOCKH = 44,
	BRICK = 45,
	TNT = 46,
	BOOKCASE = 47,
	MOSSY = 48,
	VERYBLACK = 49
}

lavacanflood = {}
lavacanflood[tile.AIR] = true
lavacanflood[tile.SHRUB] = true

lavacanclimb = {}
lavacanclimb[tile.SHRUB] = true

watercanflood = {}
watercanflood[tile.AIR] = true

isclear = {}
isclear[tile.AIR] = true
isclear[tile.WATER] = true
isclear[tile.WATERSTILL] = true
isclear[tile.LEAF] = true
isclear[tile.GLASS] = true
isclear[tile.SHRUB] = true
isclear[tile.YELLOWFLOWER] = true
isclear[tile.REDFLOWER] = true
isclear[tile.MUSHROOM] = true
isclear[tile.REDMUSHROOM] = true

fluids = {length = 0}

function fluid_lava(cell)
	local function floodstep(x,y,z)
		if lavacanflood[minecraft.gettile(x,y,z)] then
			hook_puttile(x,y,z,cell.player,tile.LAVA,-1)
		end
	end
	
	if minecraft.gettile(cell.x,cell.y,cell.z) == cell.t then
		floodstep(cell.x-1,cell.y,cell.z)
		floodstep(cell.x+1,cell.y,cell.z)
		floodstep(cell.x,cell.y-1,cell.z)
		floodstep(cell.x,cell.y,cell.z-1)
		floodstep(cell.x,cell.y,cell.z+1)
		if lavacanclimb[minecraft.gettile(cell.x,cell.y+1,cell.z)] then
			hook_puttile(cell.x,cell.y+1,cell.z,cell.player,tile.LAVA,-1)
		end
	end
end

function fluid_water(cell)
	local function floodstep(x,y,z)
		if watercanflood[minecraft.gettile(x,y,z)] then
			hook_puttile(x,y,z,cell.player,tile.WATER,-1)
		end
	end
	
	if minecraft.gettile(cell.x,cell.y,cell.z) == cell.t then
		floodstep(cell.x-1,cell.y,cell.z)
		floodstep(cell.x+1,cell.y,cell.z)
		floodstep(cell.x,cell.y-1,cell.z)
		floodstep(cell.x,cell.y,cell.z-1)
		floodstep(cell.x,cell.y,cell.z+1)
	end
end

function hasu(x,y,z,t)
	if minecraft.gettile(x-1,y,z) == t then return true end
	if minecraft.gettile(x+1,y,z) == t then return true end
	if minecraft.gettile(x,y+1,z) == t then return true end
	if minecraft.gettile(x,y,z-1) == t then return true end
	if minecraft.gettile(x,y,z+1) == t then return true end
	
	return false
end

function hasd(x,y,z,t)
	if minecraft.gettile(x-1,y,z) == t then return true end
	if minecraft.gettile(x+1,y,z) == t then return true end
	if minecraft.gettile(x,y-1,z) == t then return true end
	if minecraft.gettile(x,y,z-1) == t then return true end
	if minecraft.gettile(x,y,z+1) == t then return true end
	
	return false
end

function marktile(player,x,y,z,t)
	if pdata[player] == nil then
		pdata[player] = {temp = {}, undo = {length = 0}}
	end
	if pdata[player].undo == nil then
		pdata[player].undo = {length = 0}
	end
	pdata[player].undo[pdata[player].undo.length] = {
		x = x,
		y = y,
		z = z,
		pt = minecraft.gettile(x,y,z),
		t = t
	}
	local q = pdata[player].undo[pdata[player].undo.length]
	--print(string.format("[%i,%i,%i]: %i->%i", q.x, q.y, q.z, q.pt, q.t))
	pdata[player].undo.length = pdata[player].undo.length + 1
end

function mark_undo_bytype(player,t)
	if pdata[player] == nil then return end
	if pdata[player].undo == nil then return end
	local i
	local c = 0
	local l = {length = 0}
	for i = 0,pdata[player].undo.length-1 do
		if pdata[player].undo[i].t == t then
			local q = pdata[player].undo[i]
			local ct = minecraft.gettile(q.x,q.y,q.z)
			if ct == q.t then
				minecraft.settile_announce(q.x,q.y,q.z,q.pt,-1)
				c = c + 1
			end
		else
			l[l.length] = pdata[player].undo[i]
			l.length = l.length + 1
		end
	end
	pdata[player].undo = l
	minecraft.chatmsg_all(0xFF, string.format("Undid %i actions by %s",c,player))
end

function mark_undo_full(player)
	if pdata[player] == nil then return end
	if pdata[player].undo == nil then return end
	local i
	local c = 0
	for i = 0,pdata[player].undo.length-1 do
		local q = pdata[player].undo[i]
		local ct = minecraft.gettile(q.x,q.y,q.z)
		if ct == q.t then
			minecraft.settile_announce(q.x,q.y,q.z,q.pt,-1)
			c = c + 1
		end
	end
	pdata[player].undo = {length = 0}
	minecraft.chatmsg_all(0xFF, string.format("Undid all %i actions by %s",c,player))
end

function addfluid(x,y,z,t,time,cbf,player)
	fluids[fluids.length] = {}
	fluids[fluids.length]["x"] = x
	fluids[fluids.length]["y"] = y
	fluids[fluids.length]["z"] = z
	fluids[fluids.length]["t"] = t
	fluids[fluids.length]["tick"] = time
	fluids[fluids.length]["tickmax"] = time
	fluids[fluids.length]["cbf"] = cbf
	fluids[fluids.length]["player"] = player
	fluids.length = fluids.length + 1
end

-- Note to the WoM guys:
--
-- Release the WoM client sources and credit CPColin,
-- and I'll make this mod a little more... original.
-- The WoM client violates the GPL, and is therefore *illegal*.
--
-- I really couldn't care less about the WoM server sources.
-- They are probably your own.

authlev = {
	SPECTATOR = -1,
	GUEST = 0,
	PROBATION = 2,
	MEMBER = 5,
	BUILDER = 10,
	OPERATOR = 20,
	ADMIN = 30,
	OWNER = 100,
	SYSTEM = 100
}

guestarea = {x1 = -1, y1 = -1, z1 = -1, x2 = -1, y2 = -1, z2 = -1}

authname = {}
authname[authlev.SPECTATOR] = "spectator"
authname[authlev.GUEST] = "guest"
authname[authlev.PROBATION] = "probation"
authname[authlev.MEMBER] = "member"
authname[authlev.BUILDER] = "builder"
authname[authlev.OPERATOR] = "operator"
authname[authlev.ADMIN] = "admin"
authname[authlev.OWNER] = "owner"

doors = {length = 0}

function door_create(x,y,z,player,bidx)
	dobj = {
		x = x,
		y = y,
		z = z,
		t = y,
		b = y,
		player = player,
		bidx = bidx,
		state = 0,
		delay = 0
	}
	doors[doors.length] = dobj
	doors.length = doors.length + 1
	for i=y+1,y+8 do
		if minecraft.gettile(x,i,z) == tile.AIR then
			minecraft.settile_announce(x,i,z,bidx,-1)
			dobj.t = i
		else
			break
		end
	end
	print(dobj.y)
	print(dobj.t)
	print(dobj.b)
end

function door_update(dobj)
	dobj.delay = dobj.delay - 1
	if dobj.delay <= 0 then
		dobj.delay = 0
		if dobj.state == 1 then
			minecraft.settile_announce(dobj.x,dobj.y,dobj.z,tile.AIR,-1)
			dobj.y = dobj.y + 1
			if dobj.y > dobj.t then
				dobj.y = dobj.t
				dobj.state = 2
				dobj.delay = 50
			else
				dobj.delay = 4
			end
		elseif dobj.state == 2 then
			dobj.state = 3
		elseif dobj.state == 3 then
			minecraft.settile_announce(dobj.x,dobj.y,dobj.z,dobj.bidx,-1)
			dobj.y = dobj.y - 1
			if dobj.y < dobj.b then
				dobj.y = dobj.b
				dobj.state = 0
			else
				dobj.delay = 4
			end
		else
			dobj.state = 0
		end
	end
end

function door_trigger(dobj)
	if dobj.state == 0 then
		dobj.state = 1
	end
end

function door_find_index(x,y,z)
	for i=0,doors.length-1 do
		if doors[i].x == x and doors[i].z == z then
			if y <= doors[i].t and y >= doors[i].b then
				return i;
			end
		end
	end
	return -1
end

function door_find(x,y,z)
	local idx = door_find_index(x,y,z)
	if idx == -1 then
		return nil
	else
		return doors[idx]
	end
end

glbclock = 0

function auth_getlevel(nick)
	return authlev.ADMIN
	--[[
	if nick == nil then return 0 end
	if pdata[nick] == nil then
		pdata[nick] = {temp = {}}
	end
	if pdata[nick].level == nil then
		pdata[nick].level = 0
	end
	
	return pdata[nick].level
	]]
end

function auth_setlevel(nick,lvl)
	if nick == nil then return end
	if pdata[nick] == nil then
		pdata[nick] = {temp = {}}
	end
	pdata[nick].level = lvl
end

function naguser(nick,timeout,msg)
	if nick == nil then return end
	local idx = minecraft.getidxbynick(nick)
	if pdata[nick] == nil then
		pdata[nick] = {temp = {}}
	end
	if pdata[nick].temp == nil then
		pdata[nick].temp = {}
	end
	if pdata[nick].temp.nag == nil then
		pdata[nick].temp.nag = {}
	end
	if pdata[nick].temp.nag[msg] == nil then
		pdata[nick].temp.nag[msg] = 0
	end
	if pdata[nick].temp.nag[msg] <= glbclock then
		minecraft.chatmsg(idx, 0xFF, msg)
		pdata[nick].temp.nag[msg] = glbclock + timeout
	end
end

auth_setlevel("GreaseMonkey", authlev.OWNER)

function hook_puttile(x,y,z,player,bidx,sockfd)
	local lvl
	if player == "" then
		lvl = authlev.SYSTEM
	else
		lvl = auth_getlevel(player)
	end
	
	if lvl <= authlev.SPECTATOR then
		local ct = minecraft.gettile(x,y,z)
		if bidx ~= ct then
			minecraft.settile_announce(x,y,z,ct,-1)
			naguser(player,50,"Denied - spectators cannot build")
		end
		return
	end
	
	if lvl < authlev.MEMBER then
		if x <= guestarea.x1 or y <= guestarea.y1 or z <= guestarea.z1 or x >= guestarea.x2 or y >= guestarea.y2 or z >= guestarea.z2 then
			local ct = minecraft.gettile(x,y,z)
			if bidx ~= ct then
				minecraft.settile_announce(x,y,z,ct,-1)
				naguser(player,50,"Denied - you may only build in the guest area")
			end
			return
		end
	end

	if lvl < authlev.ADMIN then
		if x >= guestarea.x1 and y >= guestarea.y1 and z >= guestarea.z1 and x <= guestarea.x2 and y <= guestarea.y2 and z <= guestarea.z2 then
			if x == guestarea.x1 or y == guestarea.y1 or z == guestarea.z1 or x == guestarea.x2 or y == guestarea.y2 or z == guestarea.z2 then
				local ct = minecraft.gettile(x,y,z)
				if bidx ~= ct then
					minecraft.settile_announce(x,y,z,ct,-1)
					naguser(player,50,"Denied - cannot edit guest boundaries")
				end
				return
			end
		end
		if bidx == tile.LAVA or bidx == tile.WATER then
			local ct = minecraft.gettile(x,y,z)
			if bidx ~= ct then
				minecraft.settile_announce(x,y,z,ct,-1)
				naguser(player,50,"Denied - cannot place real fluids")
			end
			return
		end
	end
	
	if player ~= nil and player ~= "" then
		if pdata[player] == nil then
			print("BUG: we should not have to allocate pdata at this point for this player")
			pdata[player] = {temp = {}}
		
		end
		local idx = minecraft.getidxbynick(player)
		if pdata[player].temp.tmptile ~= nil and bidx ~= tile.AIR then
			bidx = pdata[player].temp.tmptile
			--pdata[player].temp.tmptile = nil
		end
		if pdata[player].temp.builddoor == 1 then
			if bidx == tile.AIR then
				minecraft.chatmsg(idx, 0xFF, "Build, don't mine")
				minecraft.settile_announce(x,y,z,minecraft.gettile(x,y,z),-1)
			elseif minecraft.gettile(x,y-1,z) == tile.AIR then
				minecraft.chatmsg(idx, 0xFF, "Door must be built onto floor")
				minecraft.settile_announce(x,y,z,tile.AIR,-1)
			elseif door_find(x,y,z) then
				minecraft.chatmsg(idx, 0xFF, "Already a door there")
				minecraft.settile_announce(x,y,z,tile.AIR,-1)
			else
				door_create(x,y,z,player,bidx)
				minecraft.chatmsg(idx, 0xFF, "Door successfully built")
			end
			pdata[player].temp.builddoor = 0
			return
		end
		local cdoor = door_find(x,y,z)
		if cdoor then
			door_trigger(cdoor)
			minecraft.settile_announce(x,y,z,minecraft.gettile(x,y,z),-1)
			return
		end
		if pdata[player].temp.buildga == 1 then
			minecraft.chatmsg(idx, 0xFF, "Now mark second corner")
			pdata[player].temp.buildgac = {x = x, y = y, z = z}
			pdata[player].temp.buildga = 2
			minecraft.settile_announce(x,y,z,tile.RED,-1)
			return
		elseif pdata[player].temp.buildga == 2 then
			local q = pdata[player].temp.buildgac
			if q.x < x then
				guestarea.x1 = q.x
				guestarea.x2 = x
			else
				guestarea.x1 = x
				guestarea.x2 = q.x
			end
			if q.y < y then
				guestarea.y1 = q.y
				guestarea.y2 = y
			else
				guestarea.y1 = y
				guestarea.y2 = q.y
			end
			if q.z < z then
				guestarea.z1 = q.z
				guestarea.z2 = z
			else
				guestarea.z1 = z
				guestarea.z2 = q.z
			end
			
			minecraft.chatmsg(idx, 0xFF, "Guest area successfully marked")
			pdata[player].temp.buildgac = nil
			pdata[player].temp.buildga = nil
			for i=guestarea.x1,guestarea.x2 do
				minecraft.settile_announce(i,guestarea.y1,guestarea.z1,tile.RED,-1)
				minecraft.settile_announce(i,guestarea.y2,guestarea.z1,tile.RED,-1)
				minecraft.settile_announce(i,guestarea.y1,guestarea.z2,tile.RED,-1)
				minecraft.settile_announce(i,guestarea.y2,guestarea.z2,tile.RED,-1)
			end
			for i=guestarea.y1,guestarea.y2 do
				minecraft.settile_announce(guestarea.x1,i,guestarea.z1,tile.RED,-1)
				minecraft.settile_announce(guestarea.x2,i,guestarea.z1,tile.RED,-1)
				minecraft.settile_announce(guestarea.x1,i,guestarea.z2,tile.RED,-1)
				minecraft.settile_announce(guestarea.x2,i,guestarea.z2,tile.RED,-1)
			end
			for i=guestarea.z1,guestarea.z2 do
				minecraft.settile_announce(guestarea.x1,guestarea.y1,i,tile.RED,-1)
				minecraft.settile_announce(guestarea.x2,guestarea.y1,i,tile.RED,-1)
				minecraft.settile_announce(guestarea.x1,guestarea.y2,i,tile.RED,-1)
				minecraft.settile_announce(guestarea.x2,guestarea.y2,i,tile.RED,-1)
			end
			for px=guestarea.x1+1,guestarea.x2-1 do
				for py=guestarea.y1+1,guestarea.y2-1 do
					for pz=guestarea.z1+1,guestarea.z2-1 do
						minecraft.settile_announce(px,py,pz,tile.AIR,-1)
					end
				end
			end
			for px=guestarea.x1+1,guestarea.x2-1 do
				for pz=guestarea.z1+1,guestarea.z2-1 do
					minecraft.settile_announce(px,guestarea.y1,pz,tile.RED,-1)
				end
			end
			local ct = minecraft.gettile(x,y,z)
			if bidx ~= ct then
				minecraft.settile_announce(x,y,z,ct,-1)
			end
			return
		end
	end
	local lx,ly,lz
	lx,ly,lz = minecraft.getmapdims()
	if x == 0 or z == 0 or x == lx-1 or z == lz-1 then
		if y <= (ly/2)-1 then
			minecraft.settile_announce(x,y,z,tile.BLACKROCK,-1)
			return
		end
	end
	local function testfluid(x,y,z,t)
		local rt = minecraft.gettile(x,y,z)
		if rt == tile.LAVA then
			if lavacanflood[t] then
				addfluid(x,y,z,tile.LAVA,7,fluid_lava,player)
			end
		elseif rt == tile.WATER then
			if watercanflood[t] then
				addfluid(x,y,z,tile.WATER,2,fluid_water,player)
			end
		end
	end

	local function testfluid_up(x,y,z,t)
		local rt = minecraft.gettile(x,y,z)
		if rt == tile.LAVA then
			if lavacanclimb[t] then
				addfluid(x,y,z,tile.LAVA,7,fluid_lava,player)
			end
		end
	end
	
	local bsend = true
	if bidx == tile.DIRT or bidx == tile.GRASS then
		q = minecraft.gettile(x,y+1,z)
		if isclear[q] then
			marktile(player,x,y,z,tile.GRASS)
			minecraft.settile_announce(x,y,z,tile.GRASS,-1)
		else
			marktile(player,x,y,z,tile.DIRT)
			minecraft.settile_announce(x,y,z,tile.DIRT,-1)
		end
		bsend = false
	elseif bidx == tile.WATER then
		addfluid(x,y,z,tile.WATER,2,fluid_water,player)
	elseif bidx == tile.LAVA then
		addfluid(x,y,z,tile.LAVA,7,fluid_lava,player)
	elseif bidx == tile.BLOCKH then
		if minecraft.gettile(x,y-1,z) == tile.BLOCKH then
			minecraft.settile_announce(x,y-1,z,tile.BLOCKF,-1)
			minecraft.settile_announce(x,y,z,tile.AIR,-1)
			bsend = false
		end
	end
	
	testfluid(x-1,y,z,bidx)
	testfluid(x+1,y,z,bidx)
	testfluid(x,y+1,z,bidx)
	testfluid_up(x,y-1,z,bidx)
	testfluid(x,y,z-1,bidx)
	testfluid(x,y,z+1,bidx)
	
	local st = minecraft.gettile(x,y-1,z)
	if isclear[bidx] then
		if st == tile.DIRT then
			marktile(player,x,y-1,z,tile.GRASS)
			minecraft.settile_announce(x,y-1,z,tile.GRASS,-1)
		end
	else
		if st == tile.GRASS then
			marktile(player,x,y-1,z,tile.DIRT)
			minecraft.settile_announce(x,y-1,z,tile.DIRT,-1)
		end
	end
	
	local ct = minecraft.gettile(x,y,z)
	
	if ct == tile.BLOCKF and bidx == tile.AIR then
		minecraft.settile_announce(x,y,z,tile.BLOCKH,-1)
		bsend = false
	end
	
	-- we announce back to avoid a race condition
	if bsend then
		marktile(player,x,y,z,bidx)
		minecraft.settile_announce(x,y,z,bidx,-1)
	end
end

function hook_dotick()
	local ofluids = fluids
	local i
	
	glbclock = glbclock + 1
	
	for i=0,doors.length-1 do
		door_update(doors[i])
	end
	fluids = {length=0}
	for i=0,ofluids.length-1 do
		fl = ofluids[i]
		fl.tick = fl.tick - 1
		if fl.tick <= 0 then
			s1,m = pcall(fl.cbf, fl)
			if s1 == false then
				print("ERR in fluid:"..m)
			end
		else
			fluids[fluids.length] = fl
			fluids.length = fluids.length + 1
		end
	end
end

function hook_chat(idx,pid,msg)
	local function settmptile(player,idx,bidx,msg)
		if pdata[player].temp.tmptile == bidx then
			pdata[player].temp.tmptile = nil
			minecraft.chatmsg(idx, 0xFF, "Now placing ordinary tiles")
		else
			pdata[player].temp.tmptile = bidx
			minecraft.chatmsg(idx, 0xFF, msg)
		end
	end
	
	local function setlevel(idx,ilev,lvl,tlvl,onick,msg)
		if lvl < ilev then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		--local odx = minecraft.getidxbynick(onick)
		--if odx < 0 then
		if pdata[onick] == nil then
			minecraft.chatmsg(idx, 0xFF, "Player \""..onick.."\" not found.")
		else
			local olvl = auth_getlevel(onick)
			if olvl >= lvl and (lvl ~= authlev.OWNER or olvl == authlev.OWNER) then
				minecraft.chatmsg(idx, 0xFF, "Cannot edit a superiors' level.")
				return
			end
			auth_setlevel(onick,tlvl)
			minecraft.chatmsg_all(0xFF, "Player \""..onick.."\" is now "..msg..".")
		end
	end
	
	local nick = minecraft.gp_nick(idx)
	local lvl = auth_getlevel(nick)
	
	--print("chat:",sockfd,idx,pid,msg)
	if msg == "/ghah" then
		minecraft.chatmsg(idx, 0x7F, "&00&11&22&33&44&55&66&77&88&99&aa&bb&cc&dd&ee&ff")
	elseif msg == "/lavaflood" then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		minecraft.chatmsg_all(0xFF, "We regret to announce that, due to the actions of "..nick..",")
		minecraft.chatmsg_all(0x7F, "&cWE'RE ALL GONNA DIE <:O")
		local x,y,z = minecraft.getmapdims()
		
		hook_puttile(0,y-1,0,nick,tile.LAVA,-1)
		hook_puttile(x-1,y-1,0,nick,tile.LAVA,-1)
		hook_puttile(0,y-1,z-1,nick,tile.LAVA,-1)
		hook_puttile(x-1,y-1,z-1,nick,tile.LAVA,-1)
	elseif msg == "/level" then
		local q = authname[lvl]
		if q == nil then
			q = "???"
		end
		minecraft.chatmsg(idx, 0xFF, string.format("Your level is %i (%s)", lvl, q))
	elseif msg == "/solid" then
		settmptile(nick,idx,tile.BLACKROCK,"Now placing \"unbreakable\" stone - remaps EVERYTHING o_O")
	elseif msg == "/rlava" then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		settmptile(nick,idx,tile.LAVA,"Now placing REAL LAVA O_O")
	elseif msg == "/rwater" then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		settmptile(nick,idx,tile.WATER,"Now placing REAL WATER")
	elseif msg == "/lava" then
		settmptile(nick,idx,tile.LAVASTILL,"Now placing lava")
	elseif msg == "/water" then
		settmptile(nick,idx,tile.WATERSTILL,"Now placing water")
	elseif msg == "/defloodlava" then
		mark_undo_bytype(nick, tile.LAVA)
	elseif msg == "/defloodwater" then
		mark_undo_bytype(nick, tile.WATER)
	elseif msg == "/buildga" then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		pdata[nick].temp.buildga = 1
		minecraft.chatmsg(idx, 0xFF, "Mark the first corner")
	elseif msg == "/builddoor" then
		pdata[nick].temp.builddoor = 1
		minecraft.chatmsg(idx, 0xFF, "Place a block on the ground")
	elseif string.sub(msg,1,4) == "/tp " then
		local onick = string.sub(msg,5)
		local odx = minecraft.getidxbynick(onick)
		if odx < 0 then
			minecraft.chatmsg(idx, 0xFF, "Player \""..onick.."\" not found.")
		else
			x,y,z,xo,yo = minecraft.gp_pos(odx)
			minecraft.sp_pos(idx,x,y,z,xo,yo)
		end
	elseif string.sub(msg,1,6) == "/nick " then
		local nnick = string.sub(msg,7)
		if nnick ~= "" then
			if minecraft.getidxbynick(nnick) >= 0 then
				minecraft.chatmsg(idx, 0xFF, "Someone already has that nick.")
			else
				minecraft.sp_nick(idx, nnick)
				minecraft.chatmsg_all(0xFF, "* "..nick.." digivolve to "..nnick)
			end
		end
	elseif string.sub(msg,1,7) == "/fetch " then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		local onick = string.sub(msg,8)
		local odx = minecraft.getidxbynick(onick)
		if odx < 0 then
			minecraft.chatmsg(idx, 0xFF, "Player \""..onick.."\" not found.")
		else
			x,y,z,xo,yo = minecraft.gp_pos(idx)
			minecraft.sp_pos(odx,x,y,z,xo,yo)
		end
	elseif string.sub(msg,1,6) == "/addu " then
		if lvl < authlev.ADMIN then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		local onick = string.sub(msg,7)
		if pdata[onick] == nil then
			pdata[onick] = {temp = {}}
			minecraft.chatmsg_all(0xFF, "Player \""..onick.."\" added to user list.")
		else
			minecraft.chatmsg(idx, 0xFF, "Player \""..onick.."\" already exists.")
		end
	elseif string.sub(msg,1,6) == "/undo " then
		if lvl < authlev.OPERATOR then
			minecraft.chatmsg(idx, 0xFF, "Permission denied.")
			return
		end
		local onick = string.sub(msg,7)
		mark_undo_full(onick)
	elseif string.sub(msg,1,7) == "/guest " then
		setlevel(idx,authlev.ADMIN,lvl,authlev.GUEST,string.sub(msg,8),"a GUEST")
	elseif string.sub(msg,1,6) == "/spec " then
		setlevel(idx,authlev.ADMIN,lvl,authlev.SPECTATOR,string.sub(msg,7),"a SPECTATOR O_O")
	elseif string.sub(msg,1,8) == "/member " then
		setlevel(idx,authlev.ADMIN,lvl,authlev.MEMBER,string.sub(msg,9),"a MEMBER")
	elseif string.sub(msg,1,7) == "/admin " then
		setlevel(idx,authlev.OWNER,lvl,authlev.ADMIN,string.sub(msg,8),"an ADMIN")
	elseif string.sub(msg,1,1) == "/" then
		minecraft.chatmsg(idx, 0xFF, "Oops, not a command!")
	else
		minecraft.chatmsg_all(pid, nick..": "..msg)
	end
end

function hook_join(pid,nick,idx)
	if pdata[nick] == nil then
		pdata[nick] = {temp = {}}
	end
	pdata[nick].temp = {}
	minecraft.chatmsg_all(pid, "* "..nick.." has joined the server")
end

function hook_part(pid,nick)
	minecraft.chatmsg_all(pid, "* "..nick.." has left the server")
end


minecraft.sethook_puttile("hook_puttile")
minecraft.sethook_dotick("hook_dotick")
minecraft.sethook_chat("hook_chat")
minecraft.sethook_join("hook_join")
minecraft.sethook_part("hook_part")

print("administering adminium to stop water")
x,y,z = minecraft.getmapdims()
for i=0,(y/2)-1 do
	for j=0,(x-1) do
		minecraft.settile(j,i,0,tile.BLACKROCK)
		minecraft.settile(j,i,z-1,tile.BLACKROCK)
	end
	for j=0,(z-1) do
		minecraft.settile(0,i,j,tile.BLACKROCK)
		minecraft.settile(x-1,i,j,tile.BLACKROCK)
	end
end

print("base.lua initialised")

