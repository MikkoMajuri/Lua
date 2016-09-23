--[[

TheKinkyBot in Telegram - by mikma 2016, http://www.kinky.fi, mikko.majuri@gmail.com

What config.lua must contain:
config = {
        admins = {
                [123456789] = "Adminname", -- Can also be 'true', just to keep track of names
        },
        groups = {
                [-234567891] = "Group nr. 1", -- Can also be 'true', just to keep track of names
                [-345678912] = "Group nr. 2", -- Can also be 'true', just to keep track of names
        },
        commands = {
                ["figlet"] = true,
                ["uptime"] = true,
        },
        token = "456789123:ABCdefgHIjKlmn_aBcD1_e2Fgh3iJ45KlMN",
}

]]

-- file check
local md5 = require("md5")
-- debug purposes - https://github.com/kikito/inspect.lua.git
local inspect = require('inspect')
-- table in file load and save handled
local JSON = require('JSON')

dofile("persistence.lua") -- lua table handle, save & load

dofile("config.lua")

local admins = config.admins
local groups = config.groups
local commands = config.commands
local token = config.token

local emojitable = { "\xF0\x9F\x98\x81", "\xF0\x9F\x98\x82", "\xF0\x9F\x98\x83", "\xF0\x9F\x98\x8B", "\xF0\x9F\x98\x8D", "\xF0\x9F\x98\x9C", "\xF0\x9F\x98\x9D", "\xF0\x9F\x98\xA8", "\xF0\x9F\x98\xAD", "\xF0\x9F\x98\xB7", }

-- create and configure new bot with set token
local bot, extension = require("lua-bot-api").configure(token)

-- 'a+' Append mode with read mode enabled that opens an existing file or creates a new file.
--local log = io.open("log.txt","a+") -- open log.txt

-- Log print with file
local function logprint(name,msg,id)
	local admin = " "
	if admins[id] then
		admin = " Admin "
	end
	local logtext = os.date("%d/%m/%Y %X") .. admin .. name .. ": " .. msg .."\n"
	io.write(logtext) -- print in console
	local log = io.open("log.txt","a+") -- open log.txt
	log:write(logtext) -- write in log.txt
	log:close()
end

local function getName(username,first_name,id)
	local from
	if username then -- user has username set?
		from = username -- Yes, use it.
	elseif not username then -- User does NOT have username?
		from = first_name -- Use first name.
	elseif not first_name then -- User does NOT have first name?
		from = id -- Use his ID.
	end
	return from
end

local function md5_file(filename)
	local f = io.open(filename)
	if f then
		local txt = f:read('*all')
		f:close()
		return md5.sumhexa(txt)
	end
end

-- A random number, guaranteed! ... return 7.
local function random(min,max)
	math.randomseed( os.time() )
	return math.random(min,max)
end

-- Load some data in a global table for the bot to use.
Kinky = {}
Kinky.users = persistence.load("users.lua")
if not Kinky.users then
	Kinky.users = {}
end
Kinky.pictures = persistence.load("picturecache.lua")
if not Kinky.pictures then
	Kinky.pictures = {}
end

Kinky.cachetime = os.time()
local delay = 0

print("TheKinkyBot by mikma - Started at "..os.date())

-- override onMessageReceive function
extension.onTextReceive = function(msg)
	if msg.text == "/start" then
 		bot.sendMessage(msg.from.id, "Hello there 👋\nMy name is " .. bot.first_name)
	elseif msg.text == "ping" then
		bot.sendMessage(msg.from.id, "pong!")
	else
		if admins[msg.from.id] then
			local command = msg.text:match("!(%S*)") -- check text after '!"
			if commands[command] then -- is 'command' in the allowed list ?
				local n = os.tmpname() -- get a temporary file name
				os.execute (msg.text:sub(2) .. " > ".. n) -- remove ! from msg.text, execute a command
				local temptext = ""
				logprint(msg.from.username,msg.text,msg.from.id)
				for line in io.lines(n) do -- display output
					temptext = temptext .. line .. "\n" -- concat lines in temptext
				end
				bot.sendMessage(msg.chat.id, "`"..temptext.."`", "Markdown") -- Send as Markdown
				os.remove (n) -- remove temporary file
			else
				--print("Wrong command")
			end
		end
	end
	if string.match(msg.text,"[Hh]eimopäällik") or string.match(msg.text,"[Kk]uppikunt") then
		if os.time() >= Kinky.cachetime+delay then
			delay = random(1800,7200)
			logprint("Kinky","TRIGGERED! Delay set to "..os.date("!%X",delay))
			bot.sendPhoto(msg.chat.id, "triggered.jpg","TRIGGERED!")
			Kinky.cachetime = os.time()
		end
	end
	-- predefined group goodness goes here
	if groups[msg.chat.id] then
		-- Nothing to see here now
	end
	
	local newperson = true
	for k,v in pairs(Kinky.users) do
		if k == msg.from.id then
			newperson = false
		end
	end
	if newperson then
		local from = getName(msg.from.username,msg.from.first_name,msg.from.id)
		logprint(from,"Added to users.lua")
		Kinky.users[msg.from.id] = msg.from
		persistence.store("users.lua",Kinky.users)
	end
end

-- override onPhotoReceive as well
extension.onPhotoReceive = function (msg)
	-- The following script will check sent pictures, does a random 1-10, if 5 = prints a random emoji from table.
	if not admins[msg.from.id] then
		math.randomseed(os.time()) -- new random seed every time
		local random = math.random(1,10)
		if random == 5 then -- random 5 from 1-10
			local from = getName(msg.from.username,msg.from.first_name,msg.from.id)
			math.randomseed(os.time())
                        local randomemoji = math.random(1,#emojitable)
                        bot.sendMessage(msg.chat.id, emojitable[randomemoji])
                        logprint(from,"<- Random emoji replied to picture") -- Log into console with time
		end
	end
	
	local tempdate = os.date("%d/%m/%Y klo %X") -- "dd/mm/yy klo xx.zz"
	local tempseen = os.time() -- we use this to eliminate old, OLD pictures (set the time to a month or so?)
	local temp_id = msg.photo[#msg.photo].file_id -- last picture is always the largest
	local tempfile = bot.downloadFile(temp_id,"downloads/") -- download the image
	local _,b = tempfile.file.file_path:match("([^,]+)/([^,]+)") -- chop the filename from "photo/xxx.yyy" into "xxx.yyy"
	local md5 = md5_file("downloads/"..b) -- get hex32 checksum of the file
	local edit = false
	if Kinky.pictures[md5] then
		local v = Kinky.pictures[md5]
		local from = getName(msg.from.username,msg.from.first_name,msg.from.id)
		local prevdate = v.last -- get the previous date before we overwrite it
		logprint(from,"EDIT! " .. md5 .. " | last: " .. prevdate .." | count: ".. v.count+1)
		v.last = tempdate -- now we can write the new date down
		v.seen = tempseen
		v.count = v.count+1
		edit = true -- skip the first time creation
		if v.count >= 3 then -- seen more than 3 times? Announce.
			bot.sendMessage(msg.chat.id, "Nähty jo " .. v.count .." kertaa.\nViimeksi: " .. prevdate, "Markdown")
		end
	end
	if not edit then -- New photo, check the checksum and write it down in table
		local from = getName(msg.from.username,msg.from.first_name,msg.from.id)
		logprint(from,"New photo " .. md5)
		Kinky.pictures[md5] = {["md5"] = md5, ["last"] = tempdate, ["seen"] = tempseen, ["count"] = 1,}
	end
	
	persistence.store("picturecache.lua",Kinky.pictures) -- save table to picturecache.lua
	os.remove("downloads/"..b) -- remove the downloaded file
		
end

extension.onStickerReceive = function (msg)
	-- We use this script to write Sticker ID's into a file.
	--[[
	if msg.chat.id == -115663576 then
		local f = io.open("stickers.txt","a+")
		local content = f:read("*all")
		if not string.match(content, msg.sticker.file_id) then
			f:write(msg.sticker.file_id.."\n")
		end
		f:close()
		bot.sendMessage(msg.chat.id, "Saved sticker "..msg.sticker.file_id)
	end
	]]
end


-- This runs the internal update and callback handler
-- you can even override run()
extension.run()