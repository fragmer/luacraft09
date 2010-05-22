-- Currently only gunzipped server_level.dat files are supported.
--     -GM

function map_load_vanilla(fn)
	local jdata = java_loadserial(fn)
	local map = jdata[0]
	local mapfields = map.fields
	local lx = mapfields.obj.width.ival
	local ly = mapfields.obj.depth.ival
	local lz = mapfields.obj.height.ival
	print("xlen: "..lx)
	print("ylen: "..ly)
	print("zlen: "..lz)
	local mapdata = mapfields.obj.blocks.oval
	print("This is the longest thing you will experience in your life.")
	lx = lx-1
	ly = ly-1
	lz = lz-1
	local i = 0
	for y=0,ly do
		for z=0,lz do
			for x=0,lx do
				minecraft.settile(midx,x,y,z,string.byte(mapdata.adata,i))
				i = i + 1
			end
		end
	end
	print("Done. By the way, you missed two birthdays.")
	-- Took about 6 seconds for a 256x128x256 on this lappy. -GM
	return mapfields.obj.xSpawn.ival, mapfields.obj.ySpawn.ival, mapfields.obj.zSpawn.ival
end

function pack32(v)
	local s = string.char(v % 256)
	v = (v - (v % 256)) / 256
	s = string.char(v % 256) .. s
	v = (v - (v % 256)) / 256
	s = string.char(v % 256) .. s
	v = (v - (v % 256)) / 256
	return string.char(v % 256) .. s
end

function map_get_rle(x,y,z,lx)
	local t = minecraft.gettile(midx,x,y,z)
	if x == lx-1 then return 1 end
	if x >= lx then -- this should never happen!
		error("attempted to RLE scan past x row")
	end
	
	for i=x+1,lx-1 do
		if minecraft.gettile(midx,i,y,z) ~= t then
			return i-x
		end
	end
	
	return lx-x
end

function map_get_fromz(x,y,z,lx)
	for i=x,lx-1 do
		if minecraft.gettile(midx,i,y,z) ~= minecraft.gettile(midx,i,y,z-1) then
			return i-x
		end
	end
	
	return lx-x
end

function map_get_fromy(x,y,z,lx)
	for i=x,lx-1 do
		if minecraft.gettile(midx,i,y,z) ~= minecraft.gettile(midx,i,y-1,z) then
			return i-x
		end
	end
	
	return lx-x
end

function map_get_row(x,y,z,lx)
	local s = ""
	while x < lx do
		local sel = 1
		local l = map_get_rle(x,y,z,lx)
	
		if z > 0 then
			local al = map_get_fromz(x,y,z,lx)
			if al > l then
				l = al
				sel = 2
			end
		end
	
		if y > 0 then
			local al = map_get_fromy(x,y,z,lx)
			if al > l then
				l = al
				sel = 3
			end
		end
		
		if l == 1 then
			s = s .. string.char(minecraft.gettile(midx,x,y,z))
		elseif sel == 1 then
			if l > 0xFF then l = 0xFF end
			s = s .. string.char(minecraft.gettile(midx,x,y,z) + 0x80)
			s = s .. string.char(l)
		elseif sel == 2 then
			if l > 0x7F then l = 0x7F end
			s = s .. string.char(0xFF)
			s = s .. string.char(l)
		elseif sel == 3 then
			if l > 0x7F then l = 0x7F end
			s = s .. string.char(0xFF)
			s = s .. string.char(l+0x80)
		else
			error("lolwut?")
		end
		x = x + l
	end
	return s
end

function map_save_mcta(fn,sx,sy,sz)
	local fp = io.open(fn,"wb")
	
	local lx,ly,lz
	lx,ly,lz = minecraft.getmapdims()
	
	fp:write("MCTA"..pack32(lx)..pack32(ly)..pack32(lz))
	fp:write(pack32(sx)..pack32(sy)..pack32(sz))
	
	-- Note: this compressor is quite far from optimal as it only goes per-row.
	-- It also doesn't scan from 
	-- If you can improve it, then please do!
	-- Just remember to inform us so we can make this thing better.
	--     -GM
	
	for y=0,ly-1 do
		print("y "..(y+1).."/"..ly)
		for z=0,lz-1 do
			fp:write(map_get_row(0,y,z,lx))
		end
	end
	
	fp:close()
end


function map_load_mcta(fn)
	local fp = io.open(fn,"rb")
	
	local magic = fp:read(4)
	if magic ~= "MCTA" then
		error("map format not recognised - invalid magic (M,C, T,A)")
	end
	
	local lx,ly,lz
	lx = get32(fp)
	ly = get32(fp)
	lz = get32(fp)
	local sx,sy,sz
	sx = get32(fp)
	sy = get32(fp)
	sz = get32(fp)
	
	print("Map dimensions: "..lx.."x"..ly.."x"..lz)
	
	local x,y,z
	local msel = 0
	local mctr = 0
	for y=0,ly-1 do
		print("y "..(y+1).."/"..ly)
		for z=0,lz-1 do
			for x=0,lx-1 do
				if mctr <= 0 then
					local t = string.byte(fp:read(1))
					if t < 0x80 then
						msel = t
					elseif t == 0xFF then
						mctr = string.byte(fp:read(1))
						if mctr > 0x80 then
							mctr = mctr - 0x80
							msel = -2
						else
							msel = -1
						end
					else
						msel = t - 0x80
						mctr = string.byte(fp:read(1))
					end
				end
				if msel == -1 then
					minecraft.settile(midx,x,y,z,minecraft.gettile(x,y,z-1))
				elseif msel == -2 then
					minecraft.settile(midx,x,y,z,minecraft.gettile(x,y-1,z))
				else
					minecraft.settile(midx,x,y,z,msel)
				end
				mctr = mctr - 1
			end	
		end
	end
	fp:close()
	return sx,sy,sz
end

print("mapimport.lua initialised")

