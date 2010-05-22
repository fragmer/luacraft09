arealist = {length = 0, lastid = 0}

function area_make(x1,y1,z1,x2,y2,z2,player,data)
	arealist.lastid = arealist.lastid + 1
	return {
		x1 = x1, y1 = y1, z1 = z1,
		x2 = x2, y2 = y2, z2 = z2,
		hook_block = function (area,x,y,z,player,bidx,sockfd) return 0 end,
		hook_tick = function (area) end,
		hook_playerin = function(area,x,y,z,player) end,
		hook_playerout = function(area,x,y,z,player) end,
		hook_cleanup = function (area) end,
		playerin = {},
		playerincount = 0,
		player = player,
		id = arealist.lastid,
		data = data
	}
end

function area_find_byid(id)
	local i
	for i=0,arealist.length-1 do
		if id == arealist[i].id then
			return i
		end
	end
	return -1
end

function area_add(area)
	if area_find_byid(area.id) < 0 then
		arealist[arealist.length] = area
		arealist.length = arealist.length + 1
	end
end

function area_rm(area)
	local idx = area_find_byid(area.id)
	if idx >= 0 then
		arealist.length = arealist.length - 1
		arealist[idx] = area[arealist.length]
	end
end

function area_tick(area)
	local i
	for i=0,playerlist.length-1 do
		local pobj = playerlist.obj[playerlist[i]]
		local x = pobj.x/32
		local y = (pobj.y-16)/32 --get feet position, roughly
		local z = pobj.z/32
		--print(pobj.nick..": "..x..","..y..","..z)
		local pi = x >= area.x1 and y >= area.y1 and z >= area.z1
		pi = pi and x < area.x2+1 and y < area.y2+1 and z < area.z2+1
		if area.playerin[playerlist[i]] ~= true and pi then
			area.playerincount = area.playerincount + 1
			area.hook_playerin(area,x,y,z,playerlist[i])
		elseif area.playerin[playerlist[i]] == true and not pi then
			area.playerincount = area.playerincount - 1
			area.hook_playerout(area,x,y,z,playerlist[i])
		end
		area.playerin[playerlist[i]] = pi
	end
	area.hook_tick(area)
end

hook_forall_add(function (x,y,z,player,bidx,sockfd)
	local ret = 0
	local tr, i
	
	for i=0,arealist.length-1 do
		local area = arealist[i]
		if x >= area.x1 and y >= area.y1 and z >= area.z1 then
			if x <= area.x2 and y <= area.y2 and z <= area.z2 then
				tr = area.hook_block(area,x,y,z,player,bidx,sockfd)
				if tr > ret then
					ret = tr
				end
			end
		end
	end
	
	return ret
end)

hook_tick_add(function ()
	local i
	
	for i=0,arealist.length-1 do
		area_tick(arealist[i])
	end
	
	return ret
end)

