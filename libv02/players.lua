players = {obj = {}, store = {}}

function player_add(nick)
	if players.obj[nick] then
		players.obj[nick].usable = false
		players.obj[nick].midx = nil
	else
		players[#players+1] = nick
		players.obj[nick] = {
			li = #players,
			usable = false,
			midx = nil,
		}
	end
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

