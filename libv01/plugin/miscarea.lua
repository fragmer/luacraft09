function miscarea_gohome_make(area)
	area.hook_playerout = function (area,x,y,z,player)
		local pid = minecraft.getidxbynick(player)
		minecraft.chatmsg(pid,0x7F,"* Go home, "..player)
		minecraft.sp_pos(pid,32*32,32*32,32*32,0,0)
	end
end

function miscarea_writeprotect_make(area)
	area.hook_block = function (area,x,y,z,player,bidx,sockfd)
		local t = minecraft.gettile(x,y,z)
		--print("block "..x..","..y..","..z..": "..t.." vs "..bidx)
		if t ~= bidx and player ~= area.player then
			minecraft.settile_announce(x,y,z,t,-1)
		end
		return 1
	end
end

