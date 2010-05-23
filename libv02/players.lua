players = {obj = {}, store = {}}

function player_add(nick)
	if not players.obj[nick] then
		players[#players+1] = nick
		players.obj[nick] = {li = #players}
	end
	
	players.obj[nick].midx = nil
	players.obj[nick].usable = false
	players.obj[nick].port_cooloff = 0
end

function player_rm(nick)
	if players.obj[nick] then
		local li = players.obj[nick].li
	
		players.obj[players[#players]].li = li
		players[li] = players[#players]
		players.obj[nick] = nil
		players[#players] = nil
	end
end


