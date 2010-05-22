-- This format should be a tad nicer.

dofile("libv02/base.lua")

settings = {
	server_owner = "GreaseMonkey",
	server_name = "LuaCraft server (coded in C)",
	server_message = "Y'know, the actual LuaCraft, not the one people care about",
	map_default = "start",
	maps = {
		start = {
			midx = map_make_blank(64,64,64),
			spawn = {x = 32*32+16, y = 32*32+20, z = 32*32+16, yo = 0, xo = 0},
			portals = {
				{
					x1 = 0  , y1 = 0  , z1 = 0  ,
					x2 = 63 , y2 = 2  , z2 = 63 ,
					target = "main",
					spawn = {x = 32*32+16, y = 33*32+20, z = 32*32+16, yo = 0, xo = 0},
					scale = 0,
					message = "OK, now onto the actual map",
				},
			},
		},
		main = {
			midx = map_make_flatgrass(64,64,64,32),
			spawn = {x = 32*32+16, y = 33*32+20, z = 32*32+16, yo = 0, xo = 0},
		}
	},
	map_lookup = {}
}

settings.map_lookup[settings.maps.start.midx] = "start"
settings.map_lookup[settings.maps.main.midx] = "main"

hooks_add("puttile", "map_start_preserve", function (x,y,z,player,bidx,midx)
	if midx == settings.maps.start.midx then
		local idx = minecraft.getidxbynick(player)
		if bidx == tile.AIR then
			minecraft.faketile(x-1,y,z,tile.AIR,idx)
			minecraft.faketile(x,y+1,z,tile.AIR,idx)
			minecraft.faketile(x,y,z+1,tile.AIR,idx)
			minecraft.faketile(x+1,y,z,tile.AIR,idx)
			minecraft.faketile(x,y-1,z,tile.AIR,idx)
			minecraft.faketile(x,y,z-1,tile.AIR,idx)
		end
		return true
	end
	return false
end)

hooks_add("chat", "/first", function (idx,pid,msg)
	if msg == "/first" then
		local map = settings.maps.start
		local midx = map.midx
		local x = map.spawn.x
		local y = map.spawn.y
		local z = map.spawn.z
		local yo = map.spawn.yo
		local xo = map.spawn.xo
		
		minecraft.setmap(idx,settings.server_name,"Welcome home!",midx,x,y,z,xo,yo)
		
		return true
	end
	
	return false
end)


do
	local lx,ly,lz
	local cx,cy,cz
	local tx,ty,tz
	
	midx = settings.maps.start.midx
	lx,ly,lz = minecraft.getmapdims(midx)
	
	cx,cy,cz = lx/2,ly/2,lz/2
	
	--build_cube(minecraft.settile,midx,0,0,0,lx-1,ly/2,lz-1,nil,tile.LAVASTILL,tile.LAVASTILL,tile.LAVASTILL)
	--build_cube(minecraft.settile,midx,1,1,1,lx-2,ly/2,lz-2,tile.AIR,tile.AIR,tile.AIR,tile.AIR)
	local kr = math.min(math.min(lx,ly),lz)/2-1
	for x=0,lx-1 do
		for y=0,ly-1 do
			for z=0,lz-1 do
				tx,ty,tz = x-cx,y-cy,z-cz
				local r = math.sqrt(tx*tx + ty*ty + tz*tz)
				if r >= kr then
					minecraft.settile(midx,x,y,z,tile.LAVASTILL)
				end
			end
		end
	end
	
	build_cube(minecraft.settile,midx,cx-7,0,cz-7,cx+7,cy+7,cz+7,tile.VERYBLACK,tile.VERYBLACK,tile.VERYBLACK,tile.VERYBLACK)
	build_cube(minecraft.settile,midx,cx-4,cy-4,cz-4,cx+4,cy+4,cz+4,tile.AIR,tile.WOOD,tile.WOOD,nil)
	build_cube(minecraft.settile,midx,cx-3,cy-3,cz-3,cx+3,cy+3,cz+3,nil,nil,tile.TRUNK,tile.TRUNK)
	build_cube(minecraft.settile,midx,0,0,0,lx-1,2,lz-1,tile.LAVASTILL,tile.LAVASTILL,tile.LAVASTILL,tile.LAVASTILL)
end

