function funct_fillarea_complex(x1,y1,z1,x2,y2,z2,corner,line,face,centre)
	local x,y,z
	
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end
	if z1 > z2 then z1, z2 = z2, z1 end
	
	for y=y1,y2 do
		for x=x1,x2 do
			for z=z1,z2 do
				local isx = x == x1 or x == x2
				local isy = y == y1 or y == y2
				local isz = z == z1 or z == z2
				local iscorner = isx and isy and isz
				local isface = isx or isy or isz
				local isline = (isx and isy) or (isy and isz) or (isx and isz)
				
				local t
				if iscorner then
					t = corner
				elseif isline then
					t = line
				elseif isface then
					t = face
				else
					t = centre
				end
				
				if t >= 0 then
					if t ~= minecraft.gettile(midx,x,y,z) then
						minecraft.settile_announce(midx,x,y,z,t,-1)
					end
				end
			end
		end
	end
end

function funct_fillarea_solid(x1,y1,z1,x2,y2,z2,t)
	local x,y,z
	
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end
	if z1 > z2 then z1, z2 = z2, z1 end
	
	for y=y1,y2 do
		for x=x1,x2 do
			for z=z1,z2 do
				local isx = x == x1 or x == x2
				local isy = y == y1 or y == y2
				local isz = z == z1 or z == z2
				local iscorner = isx and isy and isz
				local isface = isx or isy or isz
				local isline = (isx and isy) or (isy and isz) or (isx and isz)
				
				if t ~= minecraft.gettile(midx,x,y,z) then
					minecraft.settile_announce(midx,x,y,z,t,-1)
				end
			end
		end
	end
end

