function cube_make(area)
	area.f_soakify = function (area,bidx)
		minecraft.settile_announce(area.x1,area.y1,area.z1,bidx,-1)
		minecraft.settile_announce(area.x1,area.y1,area.z2,bidx,-1)
		minecraft.settile_announce(area.x1,area.y2,area.z1,bidx,-1)
		minecraft.settile_announce(area.x1,area.y2,area.z2,bidx,-1)
		minecraft.settile_announce(area.x2,area.y1,area.z1,bidx,-1)
		minecraft.settile_announce(area.x2,area.y1,area.z2,bidx,-1)
		minecraft.settile_announce(area.x2,area.y2,area.z1,bidx,-1)
		minecraft.settile_announce(area.x2,area.y2,area.z2,bidx,-1)
	end
	area.f_savematrix = function (area,matname)
		local x,y,z
		area.data[matname] = {}
		for x=area.x1,area.x2 do
			area.data[matname][x] = {}
			for y=area.y1,area.y2 do
				area.data[matname][x][y] = {}
				for z=area.z1,area.z2 do
					area.data[matname][x][y][z] = minecraft.gettile(x,y,z)
				end
			end
		end
	end
	area.f_loadmatrix = function (area,matname)
		local x,y,z
		for x=area.x1,area.x2 do
			for y=area.y1,area.y2 do
				for z=area.z1,area.z2 do
					local forbid = (x == area.x1 or x == area.x2)
					forbid = forbid and (y == area.y1 or y == area.y2)
					forbid = forbid and (z == area.z1 or z == area.z2)
					if not forbid then
						local t = area.data[matname][x][y][z]
						if t ~= minecraft.gettile(x,y,z) then
							minecraft.settile_announce(x,y,z,t,-1)
						end
					end
				end
			end
		end
	end

	area.hook_playerin = function (area,x,y,z,player)
		minecraft.chatmsg_all(0xFF, "* "..player.." has joined #cube")
		if area.playerincount == 1 then
			area.f_loadmatrix(area,"openmat")
			area.f_soakify(area,tile.RED)
		end
	end
	area.hook_playerout = function (area,x,y,z,player)
		minecraft.chatmsg_all(0xFF, "* "..player.." has left #cube")
		if area.playerincount == 0 then
			area.f_savematrix(area,"openmat")
			area.f_loadmatrix(area,"closemat")
			area.f_soakify(area,tile.GREEN)
		end
	end
	area.f_savematrix(area,"closemat")
	area.f_savematrix(area,"openmat")
	area.f_soakify(area,tile.GREEN)
end

