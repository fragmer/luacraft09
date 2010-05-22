iszombie = {}
zpdamage = {}
zisadmin = {}
ztickdown = 1

function zombify_player(player)
	if iszombie[player] then return end
	local pidx = minecraft.getidxbynick(player)
	if pidx < 0 then return end
	iszombie[player] = true
	print("zombifying "..player.." "..pidx)
	minecraft.sp_nick(pidx, "&4"..minecraft.gp_nick(pidx))
	print("zombified")
	minecraft.chatmsg_all(0x7F,"* "..player.." is now a &4zombie&f!")
	print("buh")
end

function dezombify_player(player)
	if not iszombie[player] then return end
	local pidx = minecraft.getidxbynick(player)
	if pidx == -1 then return end
	iszombie[player] = false
	minecraft.sp_nick(pidx, minecraft.gp_nick(pidx))
end

function damage_player(player)
	if zpdamage[player] == nil then
		zpdamage[player] = 0
	end

	if zpdamage[player] <= 0 then
		minecraft.chatmsg(minecraft.getidxbynick(player),0x7F,"* You are under attack!")
	end
	zpdamage[player] = zpdamage[player] + 1
	if zpdamage[player] >= 25 then
		zombify_player(player)
	end
end

hook_forall_add(function (x,y,z,player,bidx,sockfd)
	if iszombie[player] then
		minecraft.faketile(x,y,z,minecraft.gettile(x,y,z))
		return 1
	end
	return 0
end)

zombie_radius = 3.0
zombie_radius = zombie_radius * 32
zombie_radius = zombie_radius * zombie_radius

hook_tick_add(function ()
	ztickdown = ztickdown - 1
	if ztickdown == 0 then
		ztickdown = 4
		for i=0,playerlist.length-1 do
			if zpdamage[playerlist[i]] == nil then zpdamage[playerlist[i]] = 0 end
			if zpdamage[playerlist[i]] > 0 then
				zpdamage[playerlist[i]] = zpdamage[playerlist[i]] - 1
				if zpdamage[playerlist[i]] <= 0 then
					minecraft.chatmsg(minecraft.getidxbynick(playerlist[i]),0x7F,"* Your health has been restored.")
				end
			end
		end
	end
	for i=0,playerlist.length-1 do
		local pi = playerlist[i]
		if iszombie[pi] then
			local pio = playerlist.obj[pi]
			for j=0,playerlist.length-1 do
				if i ~= j then
					local pj = playerlist[j]
					local pjo = playerlist.obj[pj]
					if not iszombie[pj] then
						local dx = (pio.x-pjo.x)
						local dy = (pio.y-pjo.y)
						local dz = (pio.z-pjo.z)
						local d = dx*dx+dy*dy+dz*dz
						if d < zombie_radius then
							damage_player(pj)
						end
					end
				end
			end
		end
	end
end)

hook_chats_add(function (nick,idx,pid,msg)
	zisadmin[serverowner] = true
	if zisadmin[nick] then
		if string.sub(msg,1,10) == "/tozombie " then
			zombify_player(string.sub(msg,11))
			return true
		elseif msg == "/reset" then
			for i=0,playerlist.length do
				dezombify_player(playerlist[i])
			end
			minecraft.chatmsg_all(0x7F,"* Game reset. You're no longer undead now.")
			return true
		end
	end
	return false
end)

