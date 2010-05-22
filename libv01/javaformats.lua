-- Note: This file contains comments taken from this document:
--   http://java.sun.com/javase/6/docs/platform/serialization/spec/protocol.html
--
-- The document is (C) 2005 Sun Microsystems, all rights reserved.
-- I am only using it for reference.
-- Removal of the comments should not affect functionality.
--
-- This code is a hackjob. It will not load every class you throw at it.
-- I can almost guarantee that, actually - as far as Java compatibility goes,
-- this sucks!
--     -GM

function to32(s,o)
	return (string.byte(s,1+o) *256*256*256)+(string.byte(s,2+o) *256*256)+(string.byte(s,3+o) * 256)+string.byte(s,4+o)
end

function get64(fp)
	local s = fp:read(8)
	return (to32(s,4)*256*256*256*256)+to32(s,0)
end

function get32(fp)
	local s = fp:read(4)
	return (string.byte(s,1) *256*256*256)+(string.byte(s,2) *256*256)+(string.byte(s,3) * 256)+string.byte(s,4)
end

function get16(fp)
	local s = fp:read(2)
	return (string.byte(s,1) * 256)+string.byte(s,2)
end

function get8(fp)
	local s = fp:read(1)
	return string.byte(s,1)
end

function getasciiz(fp)
	local s = ""
	while true do
		local c = fp:read(1)
		if c == "\000" then
			break
		end
		s = s..c
	end
	return s
end

function getpascal(fp)
	return fp:read(get8(fp))
end

function getpascal2(fp)
	return fp:read(get16(fp))
end

function getpascal4(fp)
	return fp:read(get32(fp))
end

jserhandles = { start = 0x7E0000, pos = 0x7E0000 }

function java_serial_magic(fp)
	if get16(fp) ~= 0xACED then
		error("magic number failed")
	end
end

function java_serial_version(fp)
	local ver = get16(fp)
	print("Serial version: "..ver)
end

function java_serial_newhandle()
	local hdl = {
		id = jserhandles.pos
	}
	jserhandles[jserhandles.pos] = hdl
	jserhandles.pos = jserhandles.pos + 1
	print(string.format("Handle %06X created", hdl.id))
	return hdl
end

function java_serial_classdescflags(fp)
	-- classDescFlags:
	--   (byte)                  // Defined in Terminal Symbols and
	--                           // Constants
	return get8(fp)
end

function java_serial_fields(fp)
	-- fields:
	--   (short)<count>  fieldDesc[count]
	
	local fcount = get16(fp)
	local farray = { length = fcount, obj = {} }
	print("Field count: "..fcount)
	for i=1,fcount do
		local ftype = fp:read(1)
		local fname = getpascal2(fp)
		print("Field "..i.."/"..fcount.." "..ftype..": "..fname)
		
		-- fieldDesc:
		--   primitiveDesc
		--   objectDesc
		-- primitiveDesc:
		--   prim_typecode fieldName
		-- objectDesc:
		--   obj_typecode fieldName className1
		-- prim_typecode:
		--   `B'	// byte
		--   `C'	// char
		--   `D'	// double
		--   `F'	// float
		--   `I'	// integer
		--   `J'	// long
		--   `S'	// short
		--   `Z'	// boolean
		-- obj_typecode:
		--   `[`	// array
		--   `L'	// object
		-- className1:
		--   (String)object             // String containing the field's type,
		--                              // in field descriptor format
		
		local fstype = nil
		if ftype == "[" or ftype == "L" then
			-- Oh boy.
			fstype = get8(fp)
			fstype = java_serial_content(fp,fstype).sval
			print("object string: "..fstype)
		end
		
		farray[i] = {
			ftype = ftype,
			fstype = fstype,
			fname = fname
		}
		farray.obj[fname] = farray[i]
	end
	
	return farray
end

function java_serial_newstring(fp)
	-- newString:
	--   TC_STRING newHandle (utf)
	
	local hdl = java_serial_newhandle()
	hdl.sval = getpascal2(fp)
	return hdl
end

function java_serial_newlongstring(fp)
	-- newString:
	--   TC_LONGSTRING newHandle (long-utf)
	
	local hdl = java_serial_newhandle()
	hdl.sval = getpascal4(fp)
	return hdl
end

function java_serial_prevobject(fp)
	-- prevObject
	--   TC_REFERENCE (int)handle
	
	return jserhandles[get32(fp)]
end

function java_serial_classannotation(fp) 
	-- classAnnotation:
	--   endBlockData
	--   contents endBlockData      // contents written by annotateClass
	return java_serial_contents(fp)
end

function java_serial_superclassdesc(fp)
	-- superClassDesc:
	--   classDesc
	return java_serial_classdesc(fp)
end

function java_serial_classdescinfo(fp)
	-- classDescInfo:
	--   classDescFlags fields classAnnotation superClassDesc 
	
	local cdflags = java_serial_classdescflags(fp)
	local cfields = java_serial_fields(fp)
	local cannot = java_serial_classannotation(fp)
	local csuper = java_serial_superclassdesc(fp)
	
	print(string.format("### FLAGS: %02X",cdflags))
	
	return {
		cdflags = cdflags,
		cfields = cfields,
		cannot = cannot,
		csuper = csuper
	}
end

function java_serial_newclassdesc(fp)
	-- TC_CLASSDESC className serialVersionUID newHandle classDescInfo
	-- className:
	--   (utf)
	-- serialVersionUID:
	--   (long)
	
	local chdl = java_serial_newhandle()
	
	chdl.htype = 0x72
	chdl.cname = getpascal2(fp)
	chdl.cuid = get64(fp)
	chdl.cdinfo = java_serial_classdescinfo(fp)
	
	print("classdesc name: "..chdl.cname)
	
	return chdl
end

function java_serial_classdesc(fp)
	-- classDesc:
	--   newClassDesc
	--   nullReference
	--   (ClassDesc)prevObject    // an object required to be of type
	--                            // ClassDesc
	
	local id = get8(fp)
	local desc = nil
	
	if id == 0x70 then
		desc = {}
	elseif id == 0x72 then
		desc = java_serial_newclassdesc(fp)
	else
		error(string.format("block type not supported: %02X",id))
	end
	
	return desc
end

function java_serial_newobject(fp)
	-- newObject:
	--   TC_OBJECT classDesc newHandle classdata[]  // data for each class
	-- classdata:
	--   nowrclass                 // SC_SERIALIZABLE & classDescFlag &&
	--                             // !(SC_WRITE_METHOD & classDescFlags)
	--   wrclass objectAnnotation  // SC_SERIALIZABLE & classDescFlag &&
	--                             // SC_WRITE_METHOD & classDescFlags
	--   externalContents          // SC_EXTERNALIZABLE & classDescFlag &&
	--                             // !(SC_BLOCKDATA  & classDescFlags
	--   objectAnnotation          // SC_EXTERNALIZABLE & classDescFlag&& 
	--                             // SC_BLOCKDATA & classDescFlags
	-- nowrclass:
	--   values                    // fields in order of class descriptor
	-- wrclass:
	--   nowrclass
	-- objectAnnotation:
	--   endBlockData
	--   contents endBlockData     // contents written by writeObject
	--                             // or writeExternal PROTOCOL_VERSION_2.
	-- externalContent:          // Only parseable by readExternal
	--   ( bytes)                // primitive data
	--     object
	-- externalContents:         // externalContent written by 
	--   externalContent         // writeExternal in PROTOCOL_VERSION_1.
	--   externalContents externalContent

	local cdesc = java_serial_classdesc(fp)
	local chdl = java_serial_newhandle()
	
	local fields = cdesc.cdinfo.cfields
	
	for i=1,fields.length do
		local fobj = fields[i]
		print("Field "..i.."/"..fields.length..": "..fobj.ftype)
		if fobj.ftype == "B" then
			fobj.ival = get8(fp)
			if fobj.ival >= 0x80 then
				fobj.ival = fobj.ival - 0x100
			end
			print("Integer: "..fobj.ival)
		elseif fobj.ftype == "S" then
			fobj.ival = get16(fp)
			if fobj.ival >= 0x8000 then
				fobj.ival = fobj.ival - 0x10000
			end
			print("Integer: "..fobj.ival)
		elseif fobj.ftype == "I" then
			fobj.ival = get32(fp)
			if fobj.ival >= 0x80000000 then
				fobj.ival = fobj.ival - 0x100000000
			end
			print("Integer: "..fobj.ival)
		elseif fobj.ftype == "J" then
			fobj.ival = get64(fp)
			-- I'm not even going to attempt to signify this...
			print("Integer: "..fobj.ival)
		elseif fobj.ftype == "Z" then
			fobj.bval = get8(fp) ~= 0
			if fobj.bval then
				print("Boolean: true")
			else
				print("Boolean: false")
			end
		elseif fobj.ftype == "F" then
			-- Blatantly ignoring this.
			fobj.fval = get32(fp)
			print("Float: "..fobj.fval)
		elseif fobj.ftype == "D" then
			-- Blatantly ignoring this, too!
			fobj.fval = get64(fp)
			print("Float: "..fobj.fval)
		elseif fobj.ftype == "[" or fobj.ftype == "L" then
			fobj.oval = java_serial_content(fp, get8(fp))
			
			print(fobj.fstype)
			if fobj.fstype == "Ljava/lang/String;" then
				print("hai guise i has a string")
				fobj.sval = fobj.oval.sval
				if fobj.oval.bdata == nil then
					print("String: "..fobj.sval)
				else
					print("Rather not-nice string")
				end
			else
				print("Object containing data")
			end
		else
			error("unsupported block type: "..fobj.ftype)
		end
	end
	
	chdl.cdesc = cdesc
	chdl.fields = fields
	if ((cdesc.cdinfo.cdflags % 2) - (cdesc.cdinfo.cdflags % 1)) ~= 0 then
		chdl.weirdblock = java_serial_content(fp,get8(fp))
	end
	
	
	
	return chdl
	--error("notdone")
end

function java_serial_newarray(fp)
	-- newArray:
	--   TC_ARRAY classDesc newHandle (int)<size> values[size]
	
	local cdesc = java_serial_classdesc(fp)
	local ahdl = java_serial_newhandle()
	local asize = get32(fp)
	print("array size: "..asize)
	print("array type: "..cdesc.cname)
	local adata = nil
	
	if cdesc.cname == "[B" then
		-- LUA WILL HATE MY GUTS
		print("Loading! This'll take far too long!")
		adata = fp:read(asize)
		print("Done! You can wake up now!")
		-- actually, it didn't when i tested an 8MB map.
		-- it took less than a second on this lappy.
		--     -GM
	else
		error("array type not supported: "..cdesc.cname)
	end
	
	ahdl.cdesc = cdesc
	ahdl.asize = asize
	ahdl.adata = adata
	
	return ahdl
end

function java_serial_blockdatashort(fp)
	-- blockdatashort:
	--   TC_BLOCKDATA (unsigned byte)<size> (byte)[size]
	
	local bsize = get8(fp)
	
	local rval = {
		bsize = bsize,
		bdata = fp:read(bsize)
	}
	
	rval.sval = rval.bdata
	
	local btest = get8(fp)
	if btest ~= 0x78 then
		error("expected block end")
	end
	
	return rval
end

function java_serial_content(fp,id)
	-- content:
	--   object
	--   blockdata
	-- object:
	--   newObject
	--   newClass
	--   newArray
	--   newString
	--   newEnum
	--   newClassDesc
	--   prevObject
	--   nullReference
	--   exception
	--   TC_RESET
	-- blockdata:
	--   blockdatashort
	--   blockdatalong

	local rdata = nil
	
	if id == 0x70 then
		rdata = {}
	elseif id == 0x71 then
		rdata = java_serial_prevobject(fp)
	elseif id == 0x73 then
		rdata = java_serial_newobject(fp)
	elseif id == 0x74 then
		rdata = java_serial_newstring(fp)
	elseif id == 0x75 then
		rdata = java_serial_newarray(fp)
	elseif id == 0x77 then
		rdata = java_serial_blockdatashort(fp)
	else
		error(string.format("block type not supported: %02X",id))
	end
	
	return rdata
end

function java_serial_contents(fp, jdata)
	local id = fp:read(1)
	
	if id == nil or id == "x" then return jdata end
	
	local jdbase = java_serial_content(fp,string.byte(id))
	jdata[jdata.length] = jdbase
	jdata.length = jdata.length + 1
	
	return java_serial_contents(fp, jdata)
end

function java_loadserial(fn)
	fp = io.open(fn,"rb")
	-- We ditch the first 5 bytes.
	fp:read(5)
	-- stream:
	--   magic version contents
	java_serial_magic(fp)
	java_serial_version(fp)
	local jdata = java_serial_contents(fp,{length = 0})
	
	return jdata
end

function java_loadserial_safe(fn)
	-- TODO change this to a pcall
	java_loadserial(fn)
end

print("javaformats.lua initialised")
