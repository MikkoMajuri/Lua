--[[

 Source2 RCON in Lua by mikma, 2016 - http://www.kinky.fi - mikko.majuri@gmail.com

 https://developer.valvesoftware.com/wiki/Source_RCON_Protocol
 
 Requires:
   Step 1) Lua 5.3 - https://www.lua.org/download.html - Lower versions won't work because 'string.pack' is a Lua 5.3 function.
   Step 2) LuaRocks - https://luarocks.org/#quick-start - We use this to download and compile next requirement.
   Step 3) LuaSocket 3.0-rc1 - Comes with LuaRocks and gets compiled to work with Lua 5.3. Lower precompiled version won't work.
   Step 4) Create config.lua and add+edit the following: config = { password = 'myrconpassword', host = '127.0.0.1', port = '27015', }

]]

-- Step 1) Lua version check, string.pack is a Lua 5.3 function
if _VERSION:sub(5) < "5.3" then
	io.write("Lua 5.3 required!\n")
	os.exit()
end

-- Step 2) local variables
local arg1,arg2,arg3 = ...
local PACKET_ID = 69 -- mikma-twist
local SERVERDATA_AUTH = 3
local SERVERDATA_EXECCOMMAND = 2
local ERROR = "\n.------------------------------.\n| ERROR! PACKET WAS CORRUPTED! |\n'------------------------------'\n\n"
local BINARYLENGTH = 4 -- 4 is the amount of 12+2 hex in binaries

-- Step 3) load settings
local f=assert(io.open("config.lua", "r")) -- Check for config.lua
io.close(f) -- exists, let's continue
dofile("config.lua") -- load config.lua
local host = arg1 and arg1 or config.host
local port = arg2 and arg2 or config.port
local password = arg3 and arg3 or config.password

-- Step 4) Set up and Open connection
local socket = assert(require("socket")) -- load LuaSocket
local rcon = assert(socket.tcp()) -- create new TCP socket
rcon:settimeout(0.1) -- timeout, print happens after this
rcon:connect(host, port) -- connect to RCON

-- Step 5) Combine RCON SERVERDATA_AUTH packet, send, and receive answer (which we ignore)
local auth1 = string.pack("<i4i4", PACKET_ID, SERVERDATA_AUTH) .. password .. string.pack("xx", " ", " ")
local auth2 = string.len(auth1)
local auth3 = string.pack("<i4", auth2) .. auth1
rcon:send(auth3)
rcon:receive('*a')

-- Step 6) Ask RCON command, combine RCON SERVERDATA_EXECCOMMAND packet, send, receive answer, modify and print
io.write("Enter RCON command for " .. host .. ":" .. port .. " - ")
local status = io.read() -- read input
-- string.pack -> "<" = Little-endian, "i4" = 32-bit Signed Integer, "x" = Null-terminated ASCII String
local stat1 = string.pack("<i4i4", PACKET_ID, SERVERDATA_EXECCOMMAND) .. status .. string.pack("xx", " ", " ")
local stat2 = string.len(stat1)
local stat3 = string.pack("<i4", stat2) .. stat1
rcon:send(stat3)
local foo,bar,text,_ = rcon:receive('*a')
local packetlen,packetid = string.unpack("<i4i4",text,1,2)
if packetid == PACKET_ID then
	if (string.len(text) - BINARYLENGTH) == packetlen then
		ERROR = "" -- Everything was ok, clear the error message
	end

	-- :sub(13) = strip 12 binaries from the start, :sub(1,-3) = strip 2 nulls from the end                                
	io.write(text:sub(13):sub(1, -3) .. ERROR)
end

rcon:close() -- we are done.
