players = {obj = {}, store = {}}

function player_add(nick)
	players[#players+1] = nick
	players.obj[nick] = {
		li = #players,
		usable = false,
		midx = nil,
	}
end

function player_rm(nick)
	local li = players.obj[nick].li
	
	players.obj[players[#players]].li = li
	players[li] = players[#players]
	players.obj[nick] = nil
	players[#players] = nil
end

