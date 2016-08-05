--[[ TheKinkyBot in Telegram - by mikma 2016, http://www.kinky.fi, mikko.majuri@gmail.com ]]

-- debug purposes - https://github.com/kikito/inspect.lua.git
local inspect = require('inspect')

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
	local logtext = os.date("%x %X") .. admin .. name .. ": " .. msg .."\n"
	io.write(logtext) -- print in console
	local log = io.open("log.txt","a+") -- open log.txt
	log:write(logtext) -- write in log.txt
	log:close()
end

-- override onMessageReceive function
extension.onTextReceive = function (msg)
	local log = false
	if msg.text == "/start" then
 		bot.sendMessage(msg.from.id, "Hello there 👋\nMy name is " .. bot.first_name)
	elseif msg.text == "ping" then
		bot.sendMessage(msg.chat.id, "pong!")
	else
		if admins[msg.from.id] then
			local command = msg.text:match("!(%S*)") -- check text after '!"
			if commands[command] then -- is 'command' in the allwed list ?
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

	-- predefined group goodness goes here
	if groups[msg.chat.id] then
		-- Nothing to see here now
	end		
end

-- override onPhotoReceive as well
extension.onPhotoReceive = function (msg)
	-- The following script will check pictures from two id's, does a random 1-10, if 5 = prints a random emoji from table.
	if msg.from.id == 205271900 or msg.from.id == 241962837 then
		math.randomseed( os.time() )
		local random = math.random(1,7)
		if random == 5 then -- random 5 from 1-10
			local from
			if msg.from.username then -- user has username set?
				from = msg.from.username -- Yes, use it.
			elseif not msg.from.username then -- User does NOT have username?
				from = msg.from.first_name -- Use first name.
			elseif not msg.from.first_name then -- User does NOT have first name?
				from = msg.from.id -- Use his ID.
			end
			--print(msg.chat.id .." <- Random emoji replied to picture")
                        local randomemoji = math.random(1,#emojitable)
                        bot.sendMessage(msg.chat.id, emojitable[randomemoji])
                        logprint(from," <- Random emoji replied to picture") -- Log into console with time
		end
	end
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
