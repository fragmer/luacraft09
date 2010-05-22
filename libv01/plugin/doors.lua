-- Not finished enough yet -GM

--[[
door_info = {}
door_pdata = {}
trigger_pdata = {}

function door_tick()
	
end

hook_parts_add(function (pid,nick)
	door_pdata[nick] = nil
end)

hook_tick_add(function ()
	for 
end)

hook_forall_add(function (x,y,z,player,bidx,sockfd)
	if door_pdata[player] ~= nil then
		local dobj = door_pdata[player]
		if bidx == tile.AIR then return 0 end
		if dobj.tile == nil then
			dobj.x1 = x
			dobj.y1 = y
			dobj.z1 = z
			dobj.tile = bidx
			dobj.otile = minecraft.gettile(x,y,z)
			minecraft.settile_announce(x,y,z,bidx,-1)
			minecraft.chatmsg(idx,0xFF,"Now place the other corner")
			return 1
		end
		
		if dobj.x2 == nil then
			if dobj.tile ~= bidx then return 0 end
		
			local ox,oy,oz
			ox,oy,oz = dobj.x1,dobj.y1,dobj.z1
			
			dobj.x2 = x
			dobj.y2 = y
			dobj.z2 = z
			
			if dobj.x1 > dobj.x2 then dobj.x1, dobj.x2 = dobj.x2, dobj.x1 end
			if dobj.y1 > dobj.y2 then dobj.y1, dobj.y2 = dobj.y2, dobj.y1 end
			if dobj.z1 > dobj.z2 then dobj.z1, dobj.z2 = dobj.z2, dobj.z1 end
			
			local bcount = (dobj.x2-dobj.x1+1)*(dobj.y2-dobj.y1+1)*(dobj.z2-dobj.z1+1)
			if bcount > 64 then
				minecraft.chatmsg(idx,0xFF,"Area too large ("..bcount..") - cancelled")
				minecraft.settile_announce(x,y,z,minecraft.gettile(x,y,z),-1)
				minecraft.settile_announce(ox,oy,oz,dobj.otile,-1)
				door_pdata[player] = nil
			else
				minecraft.chatmsg(idx,0xFF,"Building door ("..bcount..")...")
				for x=dobj.x1,dobj.x2 do
					for y=dobj.y1,dobj.y2 do
						for z=dobj.z1,dobj.z2 do
							minecraft.settile_announce(x,y,z,dobj.tile,-1)
						end
					end
				end
				minecraft.chatmsg(idx,0xFF,"Door \""..dobj.name.."\" created.")
				dobj.ypos = dobj.y1
				dobj.stage = 0
				dobj.delay = 0
				door_info[dobj.name] = dobj
				door_pdata[player] = nil
			end
			return 1
		end
		
		return 1
	end
	return 0	
end)

hook_chats_add(function (nick,idx,pid,msg)
	if string.sub(msg,1,8) == "/mkdoor " then
		local dname = string.sub(msg,9)
		if dname == "" then
			minecraft.chatmsg(idx,0xFF,"Your door needs a name.")
		elseif door_pdata[nick] == nil then
			door_pdata[nick] = {name = dname}
			minecraft.chatmsg(idx,0xFF,"Place one corner - you may have up to 64 blocks")
		else
			minecraft.chatmsg(idx,0xFF,"Finish building this door, or type /mkdoor w/o params to cancel")
		end
		return 1
	elseif msg == "/mkdoor" then
		if door_pdata[nick] ~= nil then
			local dobj = door_pdata[nick]
			
			if dobj.otile ~= nil then
				minecraft.settile_announce(dobj.x1,dobj.y1,dobj.z1,dobj.otile,-1)
			end
			
			door_pdata[nick] = nil
			minecraft.chatmsg(idx,0xFF,"Door construction cancelled")
		end
	elseif msg == "/colours" then
		minecraft.chatmsg(idx,0x7F,"&00&11&22&33&44&55&66&77&88&99&aa&bb&cc&dd&ee&ff")
		return 1
	end
	return 0
end)
]]

