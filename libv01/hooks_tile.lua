function hptdirtgrass(x,y,z,player,bidx,midx)
	if isclear[minecraft.gettile(midx,x,y+1,z)] then
		minecraft.settile_announce(midx,x,y,z,tile.GRASS)
	else
		minecraft.settile_announce(midx,x,y,z,tile.DIRT)
	end
	return 1
end

hook_pertile_add(tile.DIRT, hptdirtgrass)
hook_pertile_add(tile.GRASS, hptdirtgrass)
hook_forall_add(function (x,y,z,player,bidx,midx)
	if isclear[bidx] then
		if minecraft.gettile(midx,x,y-1,z) == tile.DIRT then
			minecraft.settile_announce(midx,x,y-1,z,tile.GRASS)
		end
	else
		if minecraft.gettile(midx,x,y-1,z) == tile.GRASS then
			minecraft.settile_announce(midx,x,y-1,z,tile.DIRT)
		end
	end
	return 0
end)
hook_pertile_add(tile.BLOCKH, function (x,y,z,player,bidx,midx)
	if minecraft.gettile(midx,x,y-1,z) == tile.BLOCKH then
		minecraft.settile_announce(midx,x,y,z,tile.AIR)
		minecraft.settile_announce(midx,x,y-1,z,tile.BLOCKF)
		return 1
	end
	return 0
end)

print("hooks_tile.lua initialised")

