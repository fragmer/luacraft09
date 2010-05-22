serverowner = "GreaseMonkey"
server_name = "It's the AWESOME server!"
server_msg = "It's, like, totally awesome"
root_midx = minecraft.addmap(64,64,64)
second_midx = minecraft.addmap(64,64,64)
dofile("libv01/base.lua")
dofile("libv01/plugin/zombies.lua")

spawnx,spawny,spawnz = minecraft.getmapdims(root_midx)
spawnx,spawny,spawnz = spawnx/2,spawny/2,spawnz/2

spawnx2,spawny2,spawnz2 = minecraft.getmapdims(second_midx)
spawnx2,spawny2,spawnz2 = spawnx2/2,spawny2/2,spawnz2/2

function hook_connect(pid,nick,idx)
	minecraft.setmap(idx,server_name,server_msg,root_midx,spawnx*32+16,spawny*32+32,spawnz*32+16,32,32)
	minecraft.chatmsg_all(pid, "* "..nick.." has connected")
	return true
end

hook_chats_add(function (nick,idx,pid,msg)
	if msg == "/first" then
		minecraft.setmap(idx,server_name,"Entering first area",root_midx,spawnx*32+16,spawny*32+32,spawnz*32+16,32,32)
	elseif msg == "/second" then
		minecraft.setmap(idx,server_name,"Entering second area",second_midx,spawnx2*32+16,spawny2*32+32,spawnz2*32+16,32,32)
	else
		return false
	end
	return true
end)

minecraft.sethook_connect("hook_connect")

--spawnx,spawny,spawnz = map_load_vanilla("svlev.ungz")
--map_save_mcta("test.mcta",spawnx,spawny,spawnz)

-- Old, pre-multiworld code.
--[[
local lx,ly,lz = minecraft.getmapdims()
if lx == 256 and ly == 128 and lz == 256 then
	spawnx,spawny,spawnz = map_load_mcta("test.mcta")
else
	print("To run the test map, run as:\n./gmc 256 128 256\nas these are the map dimensions.")
end
]]

