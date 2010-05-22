# MCTA v2 repacker
# by Ben "GreaseMonkey" Russell, 2010.
# Public domain.
#
# From LuaCraft '09 (the C LuaCraft) README file:
#
# Idea for map file format:
# (section written by GreaseMonkey)
# 
# To keep in step with Minecraft's formats, these will use big-endian numbers.
# 
# First up, the header:
#   char magic[4];
#   // "MCTA" for v1 - MineCraft/Team-AScii
#   // "MC2A" for v2
#   uint32_t xlen;
#   uint32_t ylen;
#   uint32_t zlen;
#   uint32_t xspawn;
#   uint32_t yspawn;
#   uint32_t zspawn;
# 
# Then, the data. Stop once you hit the end.
#   read byte
#   if byte == 0xFF:
#     read repcount
#     if top bit of repcount set:
#       repcount &= 0x7F
#       if version_2 and repcount & 0x40 is set:
#         repcount = ((repcount & 0x3F) << 8) | read a byte
#       copy from repcount along last y axis
#     else:
#       if version_2 and repcount & 0x40 is set:
#         repcount = ((repcount & 0x3F) << 8) | read a byte
#       copy from repcount along last z axis
#   elif top bit of byte set:
#     read repcount
#     if version_2 and repcount & 0x80 is set:
#       repcount = ((repcount & 0x7F) << 8) | read a byte
#     write (byte & 0x7F) repcount times
#   else:
#     write byte as-is
# 
# Quite simple really... at least from a decompressor point of view.
# 
# Note: You must NOT attempt to access rows which don't exist.
# As it stands, this will make them adminium blocks but you MUST NOT rely on
# this behaviour.
# 
# @Notch: If there's anything in this format which takes your fancy, feel free to
# take it for your next map format. -GM

import sys, struct

fp = open(sys.argv[1],"rb")
magic, lx, ly, lz, sx, sy, sz = struct.unpack(">4sIIIIII", fp.read(28))

data = [0 for i in xrange(lx*ly*lz)]

ver = 0

if magic == "MCTA":
	print "MCTA v1 map detected"
	ver = 1
elif magic == "MC2A":
	print "MCTA v2 map detected"
	ver = 2
else:
	raise Exception("Incorrect file format magic")

rep_count = 0
rep_tile = 0 # negative indicates relative position instead

# loading MCTA v1/2 file
for pc in xrange(lx*ly*lz):
	try:
		c = 0
	
		if rep_count <= 0:
			rep_tile = ord(fp.read(1))
			if rep_tile == 0xFF:
				rep_count = ord(fp.read(1))
				rep_tile = -lx
				if rep_count & 0x80:
					rep_tile *= ly
			
				rep_count &= 0x7F
			
				if ver == 2:
					if rep_count & 0x40:
						rep_count = ((rep_count & 0x3F)<<8)|ord(fp.read(1))
				
			elif rep_tile & 0x80:
				rep_tile &= 0x7F
				rep_count = ord(fp.read(1))
				if ver == 2:
					if rep_count & 0x80:
						rep_count = ((rep_count & 0x7F)<<8)|ord(fp.read(1))
			else:
				rep_count = 1
	
		if rep_tile < 0:
			c = data[pc+rep_tile]
		else:
			c = rep_tile
	
		rep_count -= 1
	
		data[pc] = c
	except Exception:
		print "exception at", pc
		raise

fp.close()

print "Map loaded successfully, now repacking for v2"

def calc_best_run(data, pc):
	global lx,ly,lz
	
	rlelen = 1
	c = data[pc]
	while rlelen+pc < len(data) and data[rlelen+pc] == c and rlelen < 0x7FFF:
		rlelen += 1
	
	lzzlen = 0
	if pc > lx:
		pca = pc-lx
		while lzzlen+pc < len(data) and data[lzzlen+pc] == data[lzzlen+pca] and lzzlen < 0x3FFF:
			lzzlen += 1
	
	lzylen = 0
	if pc > lx*ly:
		pca = pc-lx*ly
		while lzylen+pc < len(data) and data[lzylen+pc] == data[lzylen+pca] and lzylen < 0x3FFF:
			lzylen += 1
	
	if rlelen+1 > lzzlen:
		if rlelen+1 > lzylen:
			if rlelen > 2:
				return 1, rlelen
		elif lzylen > 3:
			return 3, lzylen
	elif lzzlen > lzylen:
		if lzzlen > 3:
			return 2, lzzlen
	elif lzylen > 3:
		return 3, lzylen
	
	return 0, 1

# saving MCTA v2 file
fp = open(sys.argv[2],"wb")
fp.write(struct.pack(">4sIIIIII","MC2A",lx,ly,lz,sx,sy,sz))

pc = 0
dlen = len(data)
while pc < dlen:
	t, l = calc_best_run(data,pc)
	
	if t == 0:
		fp.write(chr(data[pc] & 0x7F))
	elif t == 1:
		fp.write(chr(data[pc] | 0x80))
		if l >= 0x80:
			fp.write(chr((l>>8)|0x80) + chr(l & 0xFF))
		else:
			fp.write(chr(l))
	elif t == 2:
		fp.write(chr(0xFF))
		if l >= 0x40:
			fp.write(chr((l>>8)|0x40) + chr(l & 0xFF))
		else:
			fp.write(chr(l))
	elif t == 3:
		fp.write(chr(0xFF))
		if l >= 0x40:
			fp.write(chr((l>>8)|0xC0) + chr(l & 0xFF))
		else:
			fp.write(chr(l|0x80))
	else:
		raise Exception("invalid type %i in compressor" % t)
	
	pc += l

if pc != dlen:
	print "INTEGRITY ERROR: pointer overshoot (%i over)" % (pc-dlen)

fp.close()

