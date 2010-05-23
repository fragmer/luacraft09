function build_cube(fn,midx,x1,y1,z1,x2,y2,z2,t0,t1,t2,t3)
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end
	if z1 > z2 then z1, z2 = z2, z1 end
	
	tl = {t0,t1,t2,t3}
	
	for x=x1,x2 do
		for y=y1,y2 do
			for z=z1,z2 do
				ts = 1
				if x == x1 or x == x2 then ts = ts + 1 end
				if y == y1 or y == y2 then ts = ts + 1 end
				if z == z1 or z == z2 then ts = ts + 1 end
				--print(midx..","..x..","..y..","..z..","..ts)
				--print(tl[ts])
				if tl[ts] ~= nil then fn(midx,x,y,z,tl[ts]) end
			end
		end
	end
end

