function fluid_floodup(cell)
	local lx,ly,lz
	lx,ly,lz = minecraft.getmapdims()
	if cell.y < ly then
		hook_puttile(cell.x,cell.y,cell.z,cell.player,cell.t,-1)
		addfluid(cell.x,cell.y+1,cell.z,cell.t,cell.tickmax,fluid_floodup,cell.player)
		print(string.format("flood y = %i",cell.y+1))
	end
end

print("finding lowest points")
lx,ly,lz = minecraft.getmapdims()
lpts = {length = 0}

for y=0,ly-1 do
	for x=0,lx-1 do
		for z=0,lz-1 do
			t = minecraft.gettile(x,y,z)
			if t == tile.AIR then
				lpts[lpts.length] = {x=x,y=y,z=z}
				lpts.length = lpts.length + 1
			end
		end
	end
	if lpts.length > 0 then break end
end

print(string.format("picking a random point out of %i", lpts.length))

i = math.random(0,lpts.length-1)
addfluid(lpts[i].x,lpts[i].y,lpts[i].z,tile.LAVA,300,fluid_floodup,"")

print("lavaflood.lua initialised.")

