function map_make_blank(lx,ly,lz)
	return minecraft.addmap(lx,ly,lz)
end

function map_make_flatgrass(lx,ly,lz,height)
	local midx = minecraft.addmap(lx,ly,lz)
	
	build_cube(minecraft.settile,midx,0,0,0,lx-1,height-2,lz-1,tile.DIRT,tile.DIRT,tile.DIRT,tile.DIRT)
	build_cube(minecraft.settile,midx,0,height-1,0,lx-1,height-1,lz-1,tile.GRASS,tile.GRASS,tile.GRASS,tile.GRASS)
	
	return midx
end

