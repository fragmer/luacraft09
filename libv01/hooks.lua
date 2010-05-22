hook_pertile = {}

playerlist = {length = 0, obj = {}, lastid = 0}

function player_find(player)
	local pobj = playerlist.obj[player]
	if pobj == nil then
		return -1
	else
		return pobj.idx
	end
end

function player_add(player)
	local pidx = player_find(player)
	if pidx < 0 then
		pidx = playerlist.length
		playerlist[playerlist.length] = player
		playerlist.length = playerlist.length + 1
	end
	if playerlist.obj[player] == nil then
		playerlist.lastid = playerlist.lastid + 1
		playerlist.obj[player] = {
			active = true,
			nick = player,
			x = 0, y = 0, z = 0,
			xo = 0, yo = 0,
			id = playerlist.lastid,
			idx = pidx,
			temp = {}
		}
	end
	playerlist.obj[player].active = true
end

function player_rm(player)
	local pidx = player_find(player)
	if pidx >= 0 then
		playerlist.length = playerlist.length - 1
		playerlist[pidx] = playerlist[playerlist.length]
		playerlist.obj[playerlist[playerlist.length]].idx = pidx
		playerlist.obj[playerlist[playerlist.length]].active = false
	end
end

function hook_pertile_add(bidx,fn)
	if hook_pertile[bidx] == nil then
		hook_pertile[bidx] = {length = 0}
	end
	local hpt = hook_pertile[bidx]
	hpt[hpt.length] = fn
	hpt.length = hpt.length + 1
end

hook_forall = {length = 0}

function hook_forall_add(fn)
	hook_forall[hook_forall.length] = fn
	hook_forall.length = hook_forall.length + 1
end

hook_tick = {length = 0}

function hook_tick_add(fn)
	hook_tick[hook_tick.length] = fn
	hook_tick.length = hook_tick.length + 1
end

hook_chats = {length = 0}

function hook_chats_add(fn)
	hook_chats[hook_chats.length] = fn
	hook_chats.length = hook_chats.length + 1
end

hook_joins = {length = 0}

function hook_joins_add(fn)
	hook_joins[hook_joins.length] = fn
	hook_joins.length = hook_joins.length + 1
end

hook_parts = {length = 0}

function hook_parts_add(fn)
	hook_parts[hook_parts.length] = fn
	hook_parts.length = hook_parts.length + 1
end

function hook_puttile(x,y,z,player,bidx,midx)
	if player ~= nil and player ~= "" then
		-- nothing!
	end
	
	local lx,ly,lz
	lx,ly,lz = minecraft.getmapdims(midx)
	if x == 0 or z == 0 or x == lx-1 or z == lz-1 then
		if y <= (ly/2)-1 then
			minecraft.settile_announce(midx,x,y,z,tile.BLACKROCK)
			return
		end
	end

	local bsend = true
	local i
	for i=hook_forall.length-1,0,-1 do
		if hook_forall[i](x,y,z,player,bidx,midx) > 0 then
			bsend = false
			break
		end
	end
	
	if bsend then
		if hook_pertile[bidx] ~= nil then
			for i=hook_pertile[bidx].length-1,0,-1 do
				if hook_pertile[bidx][i](x,y,z,player,bidx,midx) > 0 then
					bsend = false
					break
				end
			end
		end
	end
	
	-- we announce back to avoid a race condition
	if bsend then
		minecraft.settile_announce(midx,x,y,z,bidx)
	end
end

function hook_dotick()
	for i=0,playerlist.length-1 do
		local pobj = playerlist.obj[playerlist[i]]
		pobj.x, pobj.y, pobj.z, pobj.xo, pobj.yo = minecraft.gp_pos(minecraft.getidxbynick(playerlist[i]))
	end
	
	for i=hook_tick.length-1,0,-1 do
		hook_tick[i]()
	end
end

function hook_chat(idx,pid,msg)
	local nick = minecraft.gp_nick(idx)
	
	local feed = true
	
	for i=0,hook_chats.length-1 do
		if hook_chats[i](nick,idx,pid,msg) then
			feed = false
			break
		end
	end
	
	if feed then
		if string.sub(msg,1,1) == "/" then
			minecraft.chatmsg(idx, 0xFF, "Unknown command.")
		else
			local fnick = minecraft.gp_fnick(idx)
			minecraft.chatmsg_all(pid, fnick.."&f: "..msg)
		end
	end
end


function hook_join(pid,nick,idx,midx)
	player_add(nick)
	for i=0,hook_joins.length-1 do
		hook_joins[i](pid,nick,idx,midx)
	end
	minecraft.chatmsg_map(pid, "* "..nick.." has joined world #"..midx)
end

function hook_part(pid,nick,midx)
	for i=0,hook_parts.length-1 do
		hook_parts[i](pid,nick,midx)
	end
	player_rm(nick)
	minecraft.chatmsg_map(pid, "* "..nick.." has left world #"..midx)
end

function hook_disconnect(pidx,nick)
	minecraft.chatmsg_all(pid, "* "..nick.." has quit")
end

minecraft.sethook_puttile("hook_puttile")
minecraft.sethook_dotick("hook_dotick")
minecraft.sethook_chat("hook_chat")
minecraft.sethook_join("hook_join")
minecraft.sethook_part("hook_part")
minecraft.sethook_disconnect("hook_disconnect")

print("administering adminium to stop water")
x,y,z = minecraft.getmapdims(root_midx)
for i=0,(y/2)-1 do
	for j=0,(x-1) do
		minecraft.settile(midx,j,i,0,tile.BLACKROCK)
		minecraft.settile(midx,j,i,z-1,tile.BLACKROCK)
	end
	for j=0,(z-1) do
		minecraft.settile(midx,0,i,j,tile.BLACKROCK)
		minecraft.settile(midx,x-1,i,j,tile.BLACKROCK)
	end
end

print("hooks.lua initialised")

