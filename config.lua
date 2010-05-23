-- This format should be a tad nicer.

print("base.lua")
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
			adminium = 0,
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
			adminium = 100,
		},
		spleef = {
			midx = map_make_flatgrass(64,64,64,32),
			spawn = {x = 32*32+16, y = 33*32+20, z = 32*32+16, yo = 0, xo = 0},
			adminium = 0,
			portals = {
				{
					x1 = 0  , y1 = 0  , z1 = 0  ,
					x2 = 63 , y2 = 4  , z2 = 63 ,
					target = nil,
					spawn = {x = 32*32+16, y = 33*32+20, z = 32*32+16, yo = 0, xo = 0},
					scale = 0,
					fn_trigger = function (idx,midx,x,y,z,xo,yo)
						local nick = minecraft.gp_nick(idx)
						
						for qz=1,2 do
							for qx=1,2 do
								local quad = settings.maps.spleef.custom.quads[qz][qx]
								
								local li = nil
								
								for i,lnick in ipairs(quad.players) do
									if nick == lnick then
										li = i
									end
								end
								
								if li then
									quad.players[li] = quad.players[#quad.players]
									quad.players[#quad.players] = nil
									minecraft.chatmsg_map(midx,0xFF,quad.name..": "..nick.." has fallen.")
								end
							end
						end
					end
				},
			},
			custom = {
				quads = {
					{
						{
							name = "NW",
							cx = 16, cz = 16,
							playing = false, starting = false, stopping = false,
							phase = 0, tickdown = 0, delay = 0,
							players = {},
						},{
							name = "NE",
							cx = 48, cz = 16,
							playing = false, starting = false, stopping = false,
							phase = 0, tickdown = 0, delay = 0,
							players = {},
						}
					},{
						{
							name = "SW",
							cx = 16, cz = 48,
							playing = false, starting = false, stopping = false,
							phase = 0, tickdown = 0, delay = 0,
							players = {},
						},{
							name = "SE",
							cx = 48, cz = 48,
							playing = false, starting = false, stopping = false,
							phase = 0, tickdown = 0, delay = 0,
							players = {},
						}
					}
				}
			},
		}
	},
	map_lookup = {}
}

settings.map_lookup[settings.maps.start.midx] = "start"
settings.map_lookup[settings.maps.main.midx] = "main"
settings.map_lookup[settings.maps.spleef.midx] = "spleef"

-- start
do
	local lx,ly,lz
	local cx,cy,cz
	local tx,ty,tz
	
	local midx = settings.maps.start.midx
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

-- spleef
function custom_spleef_rebuild(fn,cx,cz)
	local tileset = {tile.GREEN,tile.YELLOW,tile.ORANGE,tile.RED}
	local midx = settings.maps.spleef.midx
	for y=0,3 do
		local t
		local tb = tileset[y+1]
		local ty = 31-y*5
		local sx = false
		local sz = false
		
		for x=cx-3-y*3,cx+2+y*3 do
			for z=cz-3-y*3,cz+2+y*3 do
				t = tb
				if sx == sz then t = tile.WHITE end
				fn(midx,x,ty,z,t)
				sz = not sz
			end
			sx = not sx
		end
		
		t = tile.BLACKROCK
		
		for i=3,13 do
			fn(midx,cx+i,32,cz,t)
			fn(midx,cx+i,32,cz-1,t)
			fn(midx,cx-i-1,32,cz,t)
			fn(midx,cx-i-1,32,cz-1,t)
			fn(midx,cx,32,cz+i,t)
			fn(midx,cx-1,32,cz+i,t)
			fn(midx,cx,32,cz-i-1,t)
			fn(midx,cx-1,32,cz-i-1,t)
		end
		
		for i=-3,3 do
			fn(midx,cx+i,32,cz-4,t)
			fn(midx,cx-i-1,32,cz+3,t)
			fn(midx,cx-4,32,cz-i-1,t)
			fn(midx,cx+3,32,cz+i,t)
		end
	end
end

do
	local lx,ly,lz
	local cx,cy,cz
	local midx = settings.maps.spleef.midx
	lx,ly,lz = minecraft.getmapdims(midx)
	cx,cy,cz = lx/2,ly/2,lz/2
	
	build_cube(minecraft.settile,midx,2,0,2,cx-3,cy,cz-3,tile.AIR,tile.BLACKROCK,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,2,cy,2,cx-3,cy,cz-3,tile.AIR,tile.AIR,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,2,0,cz+2,cx-3,cy,lz-3,tile.AIR,tile.BLACKROCK,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,2,cy,cz+2,cx-3,cy,lz-3,tile.AIR,tile.AIR,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,cx+2,0,cz+2,lx-3,cy,lz-3,tile.AIR,tile.BLACKROCK,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,cx+2,cy,cz+2,lx-3,cy,lz-3,tile.AIR,tile.AIR,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,cx+2,0,2,lx-3,cy,cz-3,tile.AIR,tile.BLACKROCK,tile.BLACKROCK,tile.BLACKROCK)
	build_cube(minecraft.settile,midx,cx+2,cy,2,lx-3,cy,cz-3,tile.AIR,tile.AIR,tile.BLACKROCK,tile.BLACKROCK)
	
	custom_spleef_rebuild(minecraft.settile,16,16)
	custom_spleef_rebuild(minecraft.settile,48,16)
	custom_spleef_rebuild(minecraft.settile,48,48)
	custom_spleef_rebuild(minecraft.settile,16,48)
end

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

hooks_add("puttile", "map_spleef_spleeferate", function (x,y,z,player,bidx,midx)
	if midx == settings.maps.spleef.midx then
		local map = settings.maps.spleef
		local idx = minecraft.getidxbynick(player)
		local pt = minecraft.gettile(midx,x,y,z)
		local cl = {x,z}
		local bad = false
		
		-- protect the non-spleef areas
		for i,v in ipairs(cl) do
			if v <= 2 or v >= 61 then bad = true end
			if v >= 29 and v <= 35 then bad = true end
		end
		
		-- protect the bottom
		if y < 4 then bad = true end
		
		-- protect adminium
		if pt == tile.BLACKROCK then bad = true end
		
		-- can only destroy
		if bidx ~= tile.AIR then bad = true end
		
		-- ok, find quadrant
		local qx = math.floor(x/32)
		local qz = math.floor(z/32)
		local quad = map.custom.quads[qz+1][qx+1]
		
		-- check if playing
		if not quad.playing then bad = true end
		
		if bad then
			minecraft.faketile(x,y,z,pt,player)
			return true
		end
	end
	
	return false
end)

hooks_add("dotick","map_spleef_play", function ()
	local map = settings.maps.spleef
	local midx = map.midx
	
	for qz=1,2 do
		for qx=1,2 do
			local quad = map.custom.quads[qz][qx]
			local cx = qx*32-16
			local cz = qz*32-16
			
			if quad.delay > 0 then
				quad.delay = quad.delay - 1
			elseif quad.starting then
				if quad.phase == 0 or quad.phase == 2 or quad.phase == 3 then
					local i = quad.tickdown
					local t = tile.AIR
					local ty = 33
					if quad.phase == 0 then t = tile.GLASS end
					if quad.phase == 3 then ty = 32 end
					
					minecraft.settile_announce(midx,cx+i,ty,cz-4,t)
					minecraft.settile_announce(midx,cx-i-1,ty,cz+3,t)
					minecraft.settile_announce(midx,cx-4,ty,cz-i-1,t)
					minecraft.settile_announce(midx,cx+3,ty,cz+i,t)
					
					quad.tickdown = quad.tickdown - 1
					if quad.tickdown < -3 then
						if quad.phase == 0 then
							local x,y,z,xo,yo
							
							quad.players = {}
							
							for i,nick in ipairs(players) do
								local idx = minecraft.getidxbynick(nick)
								x,y,z,xo,yo = minecraft.gp_pos(idx)
								local rx = math.floor(x/32)-cx
								local rz = math.floor(z/32)-cz
								if rx >= -3 and rx <= 2 and rz >= -3 and rz <= 2 then
									quad.players[#quad.players+1] = nick
									minecraft.chatmsg_map(midx,0x7F,quad.name..": "..nick.." is in.")
								end
							end
						end
						
						quad.phase = quad.phase + 1
						
						if quad.phase == 1 then quad.tickdown = 12 end
						if quad.phase == 3 then quad.tickdown = 3 end
					end
					
					quad.delay = 3
				elseif quad.phase == 1 then
					local i = quad.tickdown
					local t = tile.AIR
					
					minecraft.settile_announce(midx,cx+i,32,cz,t)
					minecraft.settile_announce(midx,cx+i,32,cz-1,t)
					minecraft.settile_announce(midx,cx-i-1,32,cz,t)
					minecraft.settile_announce(midx,cx-i-1,32,cz-1,t)
					minecraft.settile_announce(midx,cx,32,cz+i,t)
					minecraft.settile_announce(midx,cx-1,32,cz+i,t)
					minecraft.settile_announce(midx,cx,32,cz-i-1,t)
					minecraft.settile_announce(midx,cx-1,32,cz-i-1,t)
					
					quad.tickdown = quad.tickdown - 1
					
					if quad.tickdown < 4 then
						quad.phase = 2
						quad.tickdown = 3
					end
					
					quad.delay = 3
				else
					quad.starting = false
					quad.playing = true
					minecraft.chatmsg_map(midx,0x7F,quad.name..": Spleef starts &4NOW&f! &cGO GO GO&f!")
				end
			elseif quad.playing then
				if #quad.players == 0 then
					quad.blkq = {}
					quad.playing = false
					quad.stopping = true
					quad.phase = 0
					quad.tickdown = 0
					
					-- Yay for closures with upvals. In this case, quad is an upval.
					-- Yes, I made a Lua 5.1 VM in Java. I kinda know what I'm talking about.
					custom_spleef_rebuild(function (midx,x,y,z,bidx)
						if minecraft.gettile(midx,x,y,z) ~= bidx then
							quad.blkq[#quad.blkq+1] = {midx,x,y,z,bidx}
						end
					end, quad.cx, quad.cz)
					
					minecraft.chatmsg_map(midx,0x7F,quad.name..": Spleef is &8OVER&f.")
				end
			elseif quad.stopping then
				for i=1,3 do
					if #quad.blkq == 0 then
						quad.stopping = false
						minecraft.chatmsg_map(midx,0x7F,quad.name..": &9Spleef reset&f.")
					else
						local midx,x,y,z,bidx
						local l = quad.blkq[#quad.blkq]
						midx = l[1]
						x = l[2]
						y = l[3]
						z = l[4]
						bidx = l[5]
						quad.blkq[#quad.blkq] = nil
						minecraft.settile_announce(midx,x,y,z,bidx)
					end
				end
			end
		end
	end
end)

hooks_add("chat", "cmd_spleef", function (idx,pid,msg)
	if msg == "/spleef" then
		local map = settings.maps.spleef
		local midx = map.midx
		
		if minecraft.gp_midx(idx) ~= midx then
			minecraft.chatmsg(idx,0xFF,"Wrong map - type /map spleef")
			return true
		end
		
		local x,y,z,xo,yo
		x,y,z,xo,yo = minecraft.gp_pos(idx)
		
		local qx = math.floor(x/(32*32))
		local qz = math.floor(z/(32*32))
		local quad = map.custom.quads[qz+1][qx+1]
		
		local tx = 16+32*qx
		local tz = 16+32*qz
		
		local rx = math.floor(x/32)-tx
		local rz = math.floor(z/32)-tz
		
		if rx >= -3 and rx <= 2 and rz >= -3 and rz <= 2 then
			if map.custom.playing then
				minecraft.chatmsg(idx,0xFF,"Spleef currently playing.")
			elseif map.custom.starting then
				minecraft.chatmsg(idx,0xFF,"Spleef currently starting.")
			elseif map.custom.stopping then
				minecraft.chatmsg(idx,0xFF,"Spleef currently stopping.")
			else
				quad.phase = 0
				quad.tickdown = 3
				quad.delay = 0
				quad.starting = true
				minecraft.chatmsg_map(midx,0x7F,minecraft.gp_nick(idx).." started &9spleef&f in "..quad.name)
			end
		else
			minecraft.chatmsg(idx,0xFF,"Oi, get in a quadrant.")
		end
		
		return true
	end
	
	return false
end)

hooks_add("chat", "cmd_map", function (idx,pid,msg)
	if string.sub(msg,1,5) == "/map " then
		local mapname = string.sub(msg,6)
		local map = settings.maps[mapname]
		
		if not map then
			minecraft.chatmsg(idx,0xFF,"* Invalid map.")
			return true
		end
		
		local midx = map.midx
		local x = map.spawn.x
		local y = map.spawn.y
		local z = map.spawn.z
		local yo = map.spawn.yo
		local xo = map.spawn.xo
		
		minecraft.setmap(idx,settings.server_name,"Get psyched!",midx,x,y,z,xo,yo)
		
		return true
	end
	
	return false
end)

