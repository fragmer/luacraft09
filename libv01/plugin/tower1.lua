
local dx,dz
dx,dz = 1,0

local tx,ty,tz
tx,ty,tz = 32,32,32
local x,y,z,i,j

function putrot(tx,y,tz,dx,dz,x,z,bidx)
	minecraft.settile_announce(tx+dx*x+dz*z,y,tz+dz*x-dx*z,bidx,-1)
end

for y=0,23 do
	for i=0,3 do
		minecraft.settile_announce(tx-2,ty+y,tz+i-2,tile.BRICK,-1)
		minecraft.settile_announce(tx+2,ty+y,tz+2-i,tile.BRICK,-1)
		minecraft.settile_announce(tx+2-i,ty+y,tz-2,tile.BRICK,-1)
		minecraft.settile_announce(tx+i-2,ty+y,tz+2,tile.BRICK,-1)
	end
	minecraft.settile_announce(tx,ty+y,tz,tile.BRICK,-1)
end
for y=0,23 do
	putrot(tx,y+ty,tz,dx,dz,1,0,tile.BLOCKF)
	putrot(tx,y+ty,tz,dx,dz,1,1,tile.BLOCKH)
	for i=-2,2 do
		for j=-2,2 do
			putrot(tx,y+ty+1-2,tz,dx,dz,i,4+j,tile.BRICK)
			putrot(tx,y+ty+1+2,tz,dx,dz,i,4+j,tile.BRICK)
			putrot(tx,y+ty+1+i,tz,dx,dz,-2,4+j,tile.BRICK)
			putrot(tx,y+ty+1+i,tz,dx,dz,2,4+j,tile.BRICK)
			putrot(tx,y+ty+1+j,tz,dx,dz,i,4-2,tile.BRICK)
			putrot(tx,y+ty+1+j,tz,dx,dz,i,4+2,tile.BRICK)
		end
	end
	putrot(tx,y+ty,tz,dx,dz,0,2,tile.AIR)
	putrot(tx,y+ty+1,tz,dx,dz,0,2,tile.AIR)
	dx,dz = -dz,dx
end

dx,dz=1,0
putrot(tx,ty,tz,dx,dz,-2,0,tile.AIR)
putrot(tx,ty+1,tz,dx,dz,-2,0,tile.AIR)

