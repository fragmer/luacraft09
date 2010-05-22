nodes = {}
for x=0,21 do
	nodes[x] = {}
	for y=0,21 do
		nodes[x][y] = {}
		for z=0,21 do
			nodes[x][y][z] = 0
		end
	end
end
for x=1,20 do
	for y=1,20 do
		for z=1,20 do
			funct_fillarea_complex((x-1)*4+1,(y-1)*4+1,(z-1)*4+1,(x-1)*4+1+4,(y-1)*4+1+4,(z-1)*4+1+4,tile.BRICK,tile.BRICK,tile.BRICK,tile.AIR)
		end
	end
end

for i=0,21 do
	for j=0,21 do
		nodes[i][j][0] = 3
		nodes[i][j][21] = 3
		nodes[0][i][j] = 3
		nodes[21][i][j] = 3
		nodes[i][0][j] = 3
		nodes[i][21][j] = 3
	end
end

nodeones = {length = 0}
function maze_makenodeone(x,y,z)
	local nobj = {x=x,y=y,z=z}
	nodes[x][y][z] = 1
	nodeones[nodeones.length] = nobj
	nodeones.length = nodeones.length + 1
end

function maze_knockwall(tx,ty,tz,dx,dy,dz)
	local x = (tx-1)*4+2
	local y = (ty-1)*4+2
	local z = (tz-1)*4+2
	
	if dy == 0 then
		minecraft.settile_announce(x+1+dx*2,y+1,z+1+dz*2,tile.AIR,-1)
		minecraft.settile_announce(x+1+dx*2,y+1-1,z+1+dz*2,tile.AIR,-1)
	else
		minecraft.settile_announce(x+1+dx*2,y+1+dy*2,z+1+dz*2,tile.WATER,-1)
		minecraft.settile_announce(x+1+dx*2,y+1-1+dy*2,z+1+dz*2,tile.WATER,-1)
	end
end

function maze_firenodeone(nobj,nidx)
	local scramble = {
		{nobj.x-1,nobj.y,nobj.z},
		{nobj.x+1,nobj.y,nobj.z},
		{nobj.x,nobj.y-1,nobj.z},
		{nobj.x,nobj.y+1,nobj.z},
		{nobj.x,nobj.y,nobj.z-1},
		{nobj.x,nobj.y,nobj.z+1}
	}
	local x,y,z
	nodes[nobj.x][nobj.y][nobj.z] = 2
	local sidx = math.random(0,5)
	for i=0,5 do
		local idx = ((i+sidx)%6)+1
		x = scramble[idx][1]
		y = scramble[idx][2]
		z = scramble[idx][3]
		if nodes[x][y][z] == 2 then
			maze_knockwall(nobj.x,nobj.y,nobj.z,x-nobj.x,y-nobj.y,z-nobj.z)
			break
		end
	end
	for i=1,6 do
		x = scramble[i][1]
		y = scramble[i][2]
		z = scramble[i][3]
		if nodes[x][y][z] == 0 then
			maze_makenodeone(x,y,z)
		end
	end
	nodeones.length = nodeones.length - 1
	nodeones[nidx] = nodeones[nodeones.length]
end
maze_makenodeone(math.random(1,20),math.random(1,20),math.random(1,20))

while nodeones.length > 0 do
	local idx = math.random(0,nodeones.length-1)
	maze_firenodeone(nodeones[idx],idx)
end

--[[
for y=0,21 do
	for z=0,21 do
		s = ""
		for x=0,21 do
			s = s .. nodes[x][y][z] .. " "
		end
		print(s)
	end
	print("-")
end
]]

hook_joins_add(function (pid,nick,idx)
	local x,y,z
	x = math.random(0,19)*4+2+1
	y = math.random(0,19)*4+2+1
	z = math.random(0,19)*4+2+1
	minecraft.sp_pos(idx,x*32+16,y*32+16,z*32+16,0,0)
end)

