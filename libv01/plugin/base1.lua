dofile("libv01/plugin/miscarea.lua")

lx,ly,lz = minecraft.getmapdims()
hx = lx/2
hz = lz/2

local x1,y1,z1,x2,y2,z2,xc,zc
x1,y1,z1 = hx-11,0,hz-11
x2,y2,z2 = hx+11,6,hz+11
xc,zc = hx,hz

asmap = {
	"#####################",
	"#                   #",
	"#                   #",
	"#                   #",
	"#                   #",
	"#                   #",
	"#   #############   #",
	"#   #          d#   #",
	"#   ##$##WWW#####   #",
	"#   ## ##   #lll#   #",
	"#   ##  I F DlLl#   #",
	"#   ## ##   #lll#   #",
	"#   ##-##########   #",
	"#   #   #   #RRR#   #",
	"#   #   |   #r!R#   #",
	"#   #   #   #rRr#   #",
	"#   #####   #####   #",
	"#       # t #       #",
	"#       #tTt#       #",
	"#       # t #       #",
	"#####################"
}

astiles = {}
astiles[" "] = {tile.AIR,tile.AIR,tile.AIR}
astiles["#"] = {tile.VERYBLACK,tile.VERYBLACK,tile.VERYBLACK}
astiles["-"] = {tile.IRON,tile.IRON,tile.VERYBLACK}
astiles["$"] = {tile.SOLIDGOLD,tile.SOLIDGOLD,tile.VERYBLACK}
astiles["|"] = {tile.IRON,tile.IRON,tile.VERYBLACK}
astiles["I"] = {tile.IRON,tile.IRON,tile.VERYBLACK}
astiles["f"] = {tile.IRON,tile.IRON,tile.VERYBLACK}
astiles["d"] = {tile.BLOCKH,tile.AIR,tile.AIR}
astiles["D"] = {tile.IRON,tile.IRON,tile.VERYBLACK}
astiles["W"] = {tile.VERYBLACK,tile.GLASS,tile.GLASS}
astiles["t"] = {tile.BLOCKH,tile.AIR,tile.AIR}
astiles["T"] = {tile.BLOCKF,tile.AIR,tile.AIR}
astiles["l"] = {tile.LAVA,tile.LAVA,tile.LAVA}
astiles["L"] = {tile.LAVA,tile.LAVA,tile.LAVA}
astiles["R"] = {tile.AIR,tile.AIR,tile.WHITE}
astiles["r"] = {tile.AIR,tile.AIR,tile.RED}
astiles["!"] = {tile.AIR,tile.AIR,tile.RED}
astiles["F"] = {tile.AIR,tile.AIR,tile.AIR}

area_start = area_make(x1,y1,z1,x2,y2,z2,serverowner,{})
area_start.data.users = {}
area_start.data.admins = {}
funct_fillarea_complex(x1,y1,z1,x2,y2,z2,tile.VERYBLACK,tile.VERYBLACK,tile.VERYBLACK,tile.AIR)
funct_fillarea_complex(x1,y1+1,z1,x2,y2-1,z2,tile.VERYBLACK,tile.VERYBLACK,tile.VERYBLACK,tile.AIR)

for x=0,20 do
	for z=0,20 do
		c = string.sub(asmap[z+1], x+1,x+1)
		local tx = x1+x
		local tz = z1+z
		
		if astiles[c] ~= nil then
			minecraft.settile_announce(tx,2,tz,astiles[c][1],-1)
			minecraft.settile_announce(tx,3,tz,astiles[c][2],-1)
			minecraft.settile_announce(tx,4,tz,astiles[c][3],-1)
		end
		if c == "-" or c == "|" or c == "I" or c == "$" then
			local area
			if c == "-" or c == "$" then
				area = area_make(tx,2,tz-1,tx,3,tz+1,area_start.player,{})
			else
				area = area_make(tx-1,2,tz,tx+1,3,tz,area_start.player,{})
			end
			area.data.stage = 0
			area.data.delay = 0
			area.data.doorx = tx
			area.data.doorz = tz
			area.data.locked = false
			if c == "$" then
				area.data.tile = tile.SOLIDGOLD
				area.data.adminonly = true
			else
				area.data.tile = tile.IRON
				area.data.adminonly = false
			end
			area.hook_playerin = function (area,x,y,z,player)
				if area.data.stage == 0 and not area.data.locked then
					local cond = (area_start.data.users[player] ~= nil and not area.data.adminonly)
					cond = cond or area_start.data.admins[player] ~= nil
					cond = cond or player == area.player
					if cond then
						area.data.stage = 1
						area.data.delay = 4
					end
				end
			end
			area.hook_playerout = function (area,x,y,z,player)
				if area.data.stage == 3 and area.playerincount == 0 then
					area.data.stage = 4
					area.data.delay = 4
				end
			end
			area.hook_tick = function (area)
				area.data.delay = area.data.delay - 1
				if area.data.delay <= 0 then
					area.data.delay = 0
					if area.data.stage == 1 then
						minecraft.settile_announce(area.data.doorx,area.y1,area.data.doorz,tile.AIR,-1)
						area.data.stage = 2
						area.data.delay = 4
					elseif area.data.stage == 2 then
						minecraft.settile_announce(area.data.doorx,area.y2,area.data.doorz,tile.AIR,-1)
						area.data.stage = 3
						area.data.delay = 30
					elseif area.data.stage == 3 then
						area.data.stage = 4
						area.data.delay = 4
					elseif area.data.stage == 4 then
						if area.playerincount <= 0 then
							minecraft.settile_announce(area.data.doorx,area.y2,area.data.doorz,area.data.tile,-1)
							area.data.stage = 5
							area.data.delay = 4
						end
					elseif area.data.stage == 5 then
						minecraft.settile_announce(area.data.doorx,area.y1,area.data.doorz,area.data.tile,-1)
						area.data.stage = 0
					end
				end
			end
			area_add(area)
			if c == "I" then
				area_start.data.lavalock = area
			end
		elseif c == "D" then
			local area
			area = area_make(tx,2,tz,tx,3,tz,area_start.player,{})
			area.data.stage = 0
			area.data.delay = 0
			area.data.doorx = tx
			area.data.doorz = tz
			area.hook_tick = function (area)
				area.data.delay = area.data.delay - 1
				if area.data.delay <= 0 then
					area.data.delay = 0
					if area.data.stage <= 0 then
						-- nothing
					elseif area.data.stage == 1 then
						minecraft.settile_announce(area.data.doorx,area.y1,area.data.doorz,tile.LAVA,-1)
						area.data.stage = 1.5
						area.data.delay = 4
					elseif area.data.stage == 1.5 then
						minecraft.settile_announce(area.data.doorx,area.y2,area.data.doorz,tile.LAVA,-1)
						area.data.stage = 2
						area.data.delay = 10
					elseif area.data.stage == 2 then
						area_start.data.lavaflood.data.f_flood(area_start.data.lavaflood,2)
						area.data.stage = 2.5
						area.data.delay = 10
					elseif area.data.stage == 2.5 then
						area_start.data.lavaflood.data.f_flood(area_start.data.lavaflood,3)
						area.data.stage = 3
						area.data.delay = 10
					elseif area.data.stage == 3 then
						area.data.stage = 4
						area_start.data.lavaflood.data.f_flood(area_start.data.lavaflood,4)
						area.data.delay = 100
					elseif area.data.stage == 4 then
						local i
						local lfd = area_start.data.lavaflood.data
						local lfpl = lfd.playerlist
						for i=0,lfpl.length-1 do
							local idx = minecraft.getidxbynick(lfpl[i])
							minecraft.sp_pos(idx,area_start.data.deadx*32,3*32,area_start.data.deadz*32,0,0)
							minecraft.chatmsg_all(0x7F,"* "..lfpl[i].." was executed.")
						end
						minecraft.settile_announce(area.data.doorx,area.y2,area.data.doorz,tile.IRON,-1)
						area.data.stage = 5
						area.data.delay = 4
					elseif area.data.stage == 5 then
						minecraft.settile_announce(area.data.doorx,area.y1,area.data.doorz,tile.IRON,-1)
						area.data.stage = 6
						area.data.delay = 4
					elseif area.data.stage <= 8 then
						area_start.data.lavaflood.data.f_deflood(area_start.data.lavaflood,4-(area.data.stage-6))
						area.data.stage = area.data.stage + 1
						area.data.delay = 8
					elseif area.data.stage == 9 then
						area_start.data.lavalock.data.locked = false
						area.data.stage = 0
					end
				end
			end
			area_add(area)
			area_start.data.lavadoor = area
		elseif c == "d" then
			local area
			area = area_make(tx,2,tz,tx,3,tz,area_start.player,{})
			area.hook_playerin = function (area,x,y,z,player)
				if area_start.data.admins[player] ~= nil or player == area.player then
					if area_start.data.lavadoor.data.stage == 0 then
						area_start.data.lavadoor.data.stage = 1
						area_start.data.lavadoor.data.delay = 20
						area_start.data.lavalock.data.locked = true
					end
					minecraft.settile_announce(area.x1,area.y1,area.z1,tile.AIR,-1)
				end
			end
			area.hook_playerout = function (area,x,y,z,player)
				if area_start.data.admins[player] ~= nil or player == area.player then
					minecraft.settile_announce(area.x1,area.y1,area.z1,tile.BLOCKH,-1)
				end
			end
			area_add(area)
			area_start.data.lavatrig = area
		elseif c == "F" then
			local area
			area = area_make(tx-1,2,tz-1,tx+1,4,tz+1,area_start.player,{})
			area.data.f_flood = function (area,y)
				local x,z
				for x=area.x1,area.x2 do
					for z=area.z1,area.z2 do
						minecraft.settile_announce(x,y,z,tile.LAVA,-1)
					end
				end
			end
			area.data.f_deflood = function (area,y)
				local x,z
				for x=area.x1,area.x2 do
					for z=area.z1,area.z2 do
						minecraft.settile_announce(x,y,z,tile.AIR,-1)
					end
				end
			end
			area.data.playerlist = {length = 0, obj = {}}
			area.hook_playerin = function (area,x,y,z,player)
				area.data.playerlist[area.data.playerlist.length] = player
				area.data.playerlist.obj[player] = area.data.playerlist.length
				area.data.playerlist.length = area.data.playerlist.length + 1
			end
			area.hook_playerout = function (area,x,y,z,player)
				local idx = area.data.playerlist.obj[player]
				area.data.playerlist.length = area.data.playerlist.length - 1
				area.data.playerlist[idx] = area.data.playerlist[area.data.playerlist.length]
				area.data.playerlist.obj[area.data.playerlist[idx]] = idx
				area.data.playerlist.obj[player] = nil
			end
			area_add(area)
			area_start.data.lavaflood = area
		elseif c == "T" then
			local area
			local y
			area = area_make(tx,2,tz,tx+1,4,tz,area_start.player,{})
			for y=7,256 do
				if minecraft.gettile(tx,y,tz) == tile.AIR then
					local xarea = area_make(tx-1,y,tz-1,tx+1,y,tz+1,area_start.player,{})
					miscarea_writeprotect_make(xarea)
					area_add(xarea)
					minecraft.settile_announce(tx-1,y,tz,tile.BLOCKH,-1)
					minecraft.settile_announce(tx,y,tz-1,tile.BLOCKH,-1)
					minecraft.settile_announce(tx+1,y,tz,tile.BLOCKH,-1)
					minecraft.settile_announce(tx,y,tz+1,tile.BLOCKH,-1)
					minecraft.settile_announce(tx,y,tz,tile.BLOCKF,-1)
					area.data.tpy = y+2
					break
				end
			end
			area.hook_playerin = function (area,x,y,z,player)
				local pid,x,y,z,xo,yo
				pid = minecraft.getidxbynick(player)
				x,y,z,xo,yo = minecraft.gp_pos(pid)
				minecraft.sp_pos(pid,x,area.data.tpy*32,z,xo,yo)
			end
			area_add(area)
			area_start.data.teleport = area
		elseif c == "!" then
			area_start.data.deadx = tx
			area_start.data.deadz = tz
		end
	end
end

miscarea_writeprotect_make(area_start)
area_add(area_start)

hook_chats_add(function (nick,idx,pid,msg)
	local x,y,z,xo,yo
	x,y,z,xo,yo = minecraft.gp_pos(idx)
	if string.sub(msg,1,5) == "/itg " then
		if area_start.data.admins[nick] == nil and nick ~= area_start.player then
			minecraft.chatmsg(idx,0xFF,"Permission denied.")
		else
			local onick = string.sub(msg,6)
			local oidx = minecraft.getidxbynick(onick)
			if oidx >= 0 then
				minecraft.sp_pos(idx,hx*32,3*32,(hz-3)*32,xo,yo)
				minecraft.sp_pos(oidx,hx*32,3*32,hz*32,xo,yo)
				minecraft.chatmsg(idx,0x7F,"* Interviewing "..onick)
				minecraft.chatmsg(oidx,0x7F,"* "..nick.." wants an interview.")
			else
				minecraft.chatmsg(idx,0xFF,"Could not find "..onick)
			end
		end
		return true
	elseif string.sub(msg,1,7) == "/admin " then
		if area_start.data.admins[nick] == nil and nick ~= area_start.player then
			minecraft.chatmsg(idx,0xFF,"Permission denied.")
		else
			local onick = string.sub(msg,8)
			local oidx = minecraft.getidxbynick(onick)
			if oidx >= 0 then
				if area_start.data.users[onick] == nil then
					area_start.data.users[onick] = {}
				end
				if area_start.data.admins[onick] == nil then
					area_start.data.admins[onick] = {}
					minecraft.chatmsg_all(0x7F,"* "..onick.." is now an admin!")
				end
			else
				minecraft.chatmsg(idx,0xFF,"Could not find "..onick)
			end
		end
		return true
	elseif string.sub(msg,1,6) == "/user " then
		if area_start.data.admins[nick] == nil and nick ~= area_start.player then
			minecraft.chatmsg(idx,0xFF,"Permission denied.")
		else
			local onick = string.sub(msg,7)
			local oidx = minecraft.getidxbynick(onick)
			if oidx >= 0 then
				area_start.data.admins[onick] = nil
				if area_start.data.users[onick] == nil then
					area_start.data.users[onick] = {}
				end
				minecraft.chatmsg_all(0x7F,"* "..onick.." is now a user.")
			else
				minecraft.chatmsg(idx,0xFF,"Could not find "..onick)
			end
		end
		return true
	elseif string.sub(msg,1,7) == "/guest " then
		if area_start.data.admins[nick] == nil and nick ~= area_start.player then
			minecraft.chatmsg(idx,0xFF,"Permission denied.")
		else
			local onick = string.sub(msg,8)
			local oidx = minecraft.getidxbynick(onick)
			if oidx >= 0 then
				area_start.data.admins[onick] = nil
				area_start.data.users[onick] = nil
				minecraft.chatmsg_all(0x7F,"* "..onick.." is now a guest. Oh dear.")
			else
				minecraft.chatmsg(idx,0xFF,"Could not find "..onick)
			end
		end
		return true
	end
	return false
end)

hook_joins_add(function (pid,nick,idx)
	minecraft.sp_pos(idx,hx*32,3*32,hz*32,xo,yo)
	return true
end)

